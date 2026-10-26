import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/connection_health_monitor.dart';
import 'package:nai_launcher/core/database/connection_lease.dart';
import 'package:nai_launcher/core/database/connection_pool.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_logger_test_isolation.dart';

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
  Database? held;
  ConnectionHealthMonitor? monitor;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('connection_timeout_');
    pool = await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'old.db'),
      maxConnections: 1,
    );
    held = null;
    monitor = null;
  });
  tearDown(() async {
    monitor?.dispose();
    if (held != null && pool.inUseCount > 0) await pool.release(held!);
    await ConnectionPoolHolder.dispose();
    await pool.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'a timed-out health acquisition returns a late connection to its owner',
    () async {
      held = await pool.acquire();
      monitor = ConnectionHealthMonitor(
        config: HealthCheckConfig(
          connectionAcquireTimeoutThreshold: const Duration(milliseconds: 5),
        ),
      );
      final result = await monitor!.check();
      expect(result.validationError, 'Connection acquisition timeout');
      await pool.release(held!);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(pool.inUseCount, 0);
      expect(pool.availableCount, 1);
      final next = await pool.acquire();
      await pool.release(next);
    },
  );

  test(
    'warmup acquisition timeout cannot consume the returned connection',
    () async {
      held = await pool.acquire();
      final result = await ConnectionPoolHolder.warmup(
        connections: 2,
        timeout: const Duration(milliseconds: 10),
      );
      expect(result.validatedConnections, 0);
      expect(result.error, 'Connection acquisition timeout');
      await pool.release(held!);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(pool.inUseCount, 0);
      expect(pool.availableCount, 1);
    },
  );

  test(
    'stopping a monitor prevents a pending check from publishing later',
    () async {
      held = await pool.acquire();
      var publications = 0;
      monitor = ConnectionHealthMonitor(
        config: HealthCheckConfig(
          connectionAcquireTimeoutThreshold: const Duration(milliseconds: 30),
        ),
        onStatusChange: (_, _, _) => publications++,
      );
      final checking = monitor!.check();
      await Future<void>.delayed(Duration.zero);
      monitor!.stop();
      await checking;
      await pool.release(held!);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(publications, 0);
      expect(monitor!.lastResult, isNull);
      expect(pool.inUseCount, 0);
    },
  );

  test(
    'holder reset does not publish an old check or release into the new pool',
    () async {
      held = await pool.acquire();
      final oldVersion = ConnectionPoolHolder.version;
      var publications = 0;
      monitor = ConnectionHealthMonitor(
        config: HealthCheckConfig(
          connectionAcquireTimeoutThreshold: const Duration(milliseconds: 30),
        ),
        onStatusChange: (_, _, _) => publications++,
      );
      final checking = monitor!.check();
      await Future<void>.delayed(Duration.zero);
      final next = await ConnectionPoolHolder.reset(
        dbPath: p.join(directory.path, 'new.db'),
        maxConnections: 1,
      );
      final result = await checking;
      await pool.release(held!);
      expect(result.poolVersion, oldVersion);
      expect(publications, 0);
      expect(monitor!.lastResult, isNull);
      expect(next.inUseCount, 0);
      expect(next.availableCount, 1);
    },
  );

  test('ordinary health validation returns its connection', () async {
    monitor = ConnectionHealthMonitor();
    final result = await monitor!.check();
    expect(result.validationQuerySuccess, isTrue);
    expect(result.validationError, isNull);
    expect(pool.inUseCount, 0);
    expect(pool.availableCount, 1);
  });

  test('a timed-out waiter is drained when its pool is disposed', () async {
    held = await pool.acquire();
    await expectLater(
      pool.acquire(timeout: const Duration(milliseconds: 5)),
      throwsA(isA<TimeoutException>()),
    );
    await pool.dispose();
    await pool.release(held!);
    await Future<void>.delayed(Duration.zero);
    expect(pool.inUseCount, 0);
    expect(pool.availableCount, 0);
  });

  test('a connection lease honors its acquire budget', () async {
    held = await pool.acquire();
    final released = Completer<void>();
    final timer = Timer(const Duration(milliseconds: 30), () async {
      await pool.release(held!);
      released.complete();
    });
    addTearDown(timer.cancel);
    final acquiring = acquireLease(timeout: const Duration(milliseconds: 5))
        .then((lease) async {
          await lease.dispose();
          return lease;
        });
    await expectLater(acquiring, throwsA(isA<TimeoutException>()));
    await released.future;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(pool.inUseCount, 0);
    expect(pool.availableCount, 1);
  });

  for (final expires in [true, false]) {
    test(
      'slow replacement connection keeps its owner; expires=$expires',
      () async {
        var created = 0;
        final started = Completer<void>();
        final replacement = Completer<Database>();
        final dbPath = p.join(directory.path, 'slow.db');
        final local = ConnectionPool(
          dbPath: dbPath,
          maxConnections: 1,
          connectionFactory: () async {
            if (++created == 1) {
              return databaseFactoryFfi.openDatabase(
                dbPath,
                options: OpenDatabaseOptions(singleInstance: false),
              );
            }
            started.complete();
            return replacement.future;
          },
        );
        addTearDown(local.dispose);
        await local.initialize();
        final first = await local.acquire();
        await local.release(first);
        await first.close();
        final acquiring = local.acquire(
          timeout: expires
              ? const Duration(milliseconds: 5)
              : const Duration(seconds: 1),
        );
        final failure = expires
            ? expectLater(acquiring, throwsA(isA<TimeoutException>()))
            : null;
        await started.future;
        if (failure != null) await failure;
        final db = await databaseFactoryFfi.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(singleInstance: false),
        );
        replacement.complete(db);
        if (!expires) await local.release(await acquiring);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(local.inUseCount, 0);
        expect(local.availableCount, 1);
      },
    );
  }
}
