import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/base_data_source.dart';
import 'package:nai_launcher/core/database/connection_lease.dart';
import 'package:nai_launcher/core/database/connection_pool.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/lease_extensions.dart';
import 'package:nai_launcher/core/database/data_source.dart' as ds;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Source extends EnhancedBaseDataSource {
  @override
  String get name => 'timeout-test';
  @override
  ds.DataSourceType get type => ds.DataSourceType.settings;
  @override
  Set<String> get dependencies => {};
  @override
  Future<void> doInitialize() async {}
  @override
  Future<void> doClear() async {}
  @override
  Future<void> doRestore() async {}
  @override
  Future<void> doDispose() async {}
  @override
  Future<ds.DataSourceHealth> doCheckHealth() async => ds.DataSourceHealth(
    status: ds.HealthStatus.healthy,
    message: 'fixture',
    timestamp: DateTime.now(),
  );
}

class _LeaseSource extends LeaseBasedDataSource {
  @override
  String get name => 'lease-timeout-test';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AppLoggerTestIsolation.setUp();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  late ConnectionPool pool;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('data_source_timeout_');
    pool = await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'counter.db'),
      maxConnections: 1,
    );
    final db = await pool.acquire();
    await db.execute('CREATE TABLE counter(value INTEGER NOT NULL)');
    await db.rawInsert('INSERT INTO counter VALUES (0)');
    await pool.release(db);
  });
  tearDown(() async {
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  Future<int> readCounter() async {
    final db = await pool.acquire();
    try {
      return (await db.rawQuery('SELECT value FROM counter')).single['value']
          as int;
    } finally {
      await pool.release(db);
    }
  }

  test('a timed-out mutation commits once and is not replayed', () async {
    var calls = 0;
    final completed = Completer<void>();
    await expectLater(
      _Source().execute(
        'increment',
        (db) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          final result = await db.rawUpdate('UPDATE counter SET value=value+1');
          if (!completed.isCompleted) completed.complete();
          return result;
        },
        timeout: const Duration(milliseconds: 5),
        maxRetries: 2,
      ),
      throwsA(isA<DataSourceOperationException>()),
    );
    await completed.future;
    expect(await readCounter(), 1);
    expect(calls, 1);
    expect(pool.inUseCount, 0);
  });

  for (final kind in ['enhanced', 'withLease', 'leaseSource', 'simple']) {
    test(
      'timeout retains the connection until the mutation ends; $kind',
      () async {
        final started = Completer<void>();
        final release = Completer<void>();
        final completed = Completer<void>();
        Future<int> operation(Database db) async {
          started.complete();
          await release.future;
          try {
            return await db.rawUpdate('UPDATE counter SET value=value+1');
          } finally {
            completed.complete();
          }
        }

        final task = switch (kind) {
          'withLease' => withLease(
            operation,
            operationTimeout: const Duration(milliseconds: 5),
          ),
          'leaseSource' => _LeaseSource().withLease(
            'gated increment',
            operation,
            timeout: const Duration(milliseconds: 5),
            maxRetries: 1,
          ),
          'simple' => SimpleLeaseHelper('simple-timeout-test').execute(
            'gated increment',
            operation,
            timeout: const Duration(milliseconds: 5),
            maxRetries: 1,
          ),
          _ => _Source().execute(
            'gated increment',
            operation,
            timeout: const Duration(milliseconds: 5),
            maxRetries: 1,
          ),
        };
        final failure = expectLater(
          task,
          throwsA(
            kind == 'enhanced'
                ? isA<DataSourceOperationException>()
                : isA<TimeoutException>(),
          ),
        );
        Future<Database>? waiting;
        var anotherAcquired = false;
        try {
          await started.future;
          await failure;
          expect(pool.inUseCount, 1);
          waiting = pool.acquire().then((db) {
            anotherAcquired = true;
            return db;
          });
          await Future<void>.delayed(Duration.zero);
          expect(anotherAcquired, isFalse);
        } finally {
          release.complete();
          await completed.future;
          if (waiting != null) await pool.release(await waiting);
        }
        expect(await readCounter(), 1);
        expect(pool.inUseCount, 0);
      },
    );
  }

  test(
    'a timed-out transaction commits once and releases only after completion',
    () async {
      var calls = 0;
      final completed = Completer<void>();
      await expectLater(
        _Source().executeTransaction('increment transaction', (txn) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          final changed = await txn.rawUpdate(
            'UPDATE counter SET value=value+1',
          );
          if (!completed.isCompleted) completed.complete();
          return changed;
        }, timeout: const Duration(milliseconds: 5)),
        throwsA(isA<DataSourceOperationException>()),
      );
      await completed.future;
      expect(await readCounter(), 1);
      expect(calls, 1);
      expect(pool.inUseCount, 0);
    },
  );

  final failures = <Object>[
    StateError('after commit'),
    ConnectionInvalidException(),
    ConnectionVersionMismatchException(expectedVersion: 1, actualVersion: 2),
  ];
  for (final kind in ['enhanced', 'leaseSource', 'simple']) {
    for (final error in failures) {
      test(
        'a callback failure after a write is not replayed: $kind ${error.runtimeType}',
        () async {
          var calls = 0;
          Future<void> operation(Database db) async {
            calls++;
            await db.rawUpdate('UPDATE counter SET value=value+1');
            throw error;
          }

          final task = switch (kind) {
            'leaseSource' => _LeaseSource().withLease(
              'write then fail',
              operation,
              maxRetries: 2,
            ),
            'simple' => SimpleLeaseHelper(
              'simple-timeout-test',
            ).execute('write then fail', operation, maxRetries: 2),
            _ => _Source().execute('write then fail', operation, maxRetries: 2),
          };
          await expectLater(
            task,
            throwsA(
              kind == 'enhanced'
                  ? isA<DataSourceOperationException>()
                  : same(error),
            ),
          );
          expect(calls, 1);
          expect(await readCounter(), 1);
          expect(pool.inUseCount, 0);
        },
      );
    }
  }
}
