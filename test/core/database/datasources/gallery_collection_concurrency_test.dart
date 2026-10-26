import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/base_data_source.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/app_logger_test_isolation.dart';

Future<void> _readCorruptTree(List<Object> args) async {
  final reply = args[0] as SendPort;
  await AppLogger.initialize(enableFileLogging: false);
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  await ConnectionPoolHolder.initialize(dbPath: args[1] as String);
  final source = GalleryDataSource();
  await source.initialize();
  final a = await source.createCollection('A', isFolder: true);
  final b = await source.createCollection('B', parentId: a, isFolder: true);
  final outside = await source.createCollection('outside', isFolder: true);
  final db = await ConnectionPoolHolder.instance.acquire();
  await db.update(
    'gallery_collections',
    {'parent_id': b},
    where: 'id = ?',
    whereArgs: [a],
  );
  await ConnectionPoolHolder.instance.release(db);
  final results = <String>[];
  for (final read in <Future<Object> Function()>[
    source.listCollectionsWithCounts,
    () => source.getCollectionImageIds(a),
  ]) {
    try {
      await read();
      results.add('unexpected success');
    } on DataSourceOperationException catch (error) {
      if (error.originalError is! StateError) rethrow;
      results.add('cycle reported');
    }
  }
  results.add('move accepted: ${await source.moveCollection(outside, a)}');
  await source.dispose();
  await ConnectionPoolHolder.dispose();
  reply.send(results);
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
  late GalleryDataSource source;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'collection_concurrency_',
    );
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'gallery.db'),
      maxConnections: 3,
    );
    source = GalleryDataSource();
    await source.initialize();
  });
  tearDown(() async {
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });

  Future<List<Map<String, Object?>>> rows() async {
    final pool = ConnectionPoolHolder.instance;
    final db = await pool.acquire();
    try {
      return await db.query('gallery_collections');
    } finally {
      await pool.release(db);
    }
  }

  Future<void> expectValidTree() async {
    final byId = {for (final row in await rows()) row['id'] as String: row};
    for (final root in byId.keys) {
      String? current = root;
      final seen = <String>{};
      while (current != null) {
        expect(seen.add(current), isTrue, reason: 'cycle reachable from $root');
        expect(byId, contains(current));
        final parent = byId[current]!['parent_id'] as String?;
        if (parent != null) expect(byId[parent]!['is_folder'], 1);
        current = parent;
      }
    }
  }

  test(
    'opposite concurrent moves accept one and leave an acyclic tree',
    () async {
      final a = await source.createCollection('A', isFolder: true);
      final b = await source.createCollection('B', isFolder: true);
      final accepted = await Future.wait([
        source.moveCollection(a, b),
        source.moveCollection(b, a),
      ]);
      expect(accepted.where((value) => value), hasLength(1));
      await expectValidTree();
    },
  );

  test('three concurrent moves cannot close a cycle', () async {
    final a = await source.createCollection('A', isFolder: true);
    final b = await source.createCollection('B', isFolder: true);
    final c = await source.createCollection('C', isFolder: true);
    final accepted = await Future.wait([
      source.moveCollection(a, b),
      source.moveCollection(b, c),
      source.moveCollection(c, a),
    ]);
    expect(accepted.where((value) => value), hasLength(2));
    await expectValidTree();
  });

  test('reordering cannot move an ancestor into its descendant', () async {
    final a = await source.createCollection('A', isFolder: true);
    final b = await source.createCollection('B', parentId: a, isFolder: true);
    expect(await source.reorderCollections([a], parentId: b), isFalse);
    await expectValidTree();
  });

  test('move and reorder share the same tree mutation boundary', () async {
    final a = await source.createCollection('A', isFolder: true);
    final b = await source.createCollection('B', isFolder: true);
    final accepted = await Future.wait([
      source.moveCollection(a, b),
      source.reorderCollections([b], parentId: a),
    ]);
    expect(accepted.where((value) => value), hasLength(1));
    await expectValidTree();
  });

  test('concurrent creates reserve distinct sibling positions', () async {
    final parent = await source.createCollection('parent', isFolder: true);
    await Future.wait([
      source.createCollection('A', parentId: parent),
      source.createCollection('B', parentId: parent),
    ]);
    final orders =
        (await rows())
            .where((row) => row['parent_id'] == parent)
            .map((row) => row['sort_order'] as int)
            .toList()
          ..sort();
    expect(orders, [0, 1]);
    await expectValidTree();
  });

  test('reordering rejects a leaf or missing parent', () async {
    final a = await source.createCollection('A', isFolder: true);
    final leaf = await source.createCollection('leaf');
    expect(await source.reorderCollections([a], parentId: leaf), isFalse);
    expect(await source.reorderCollections([a], parentId: 'missing'), isFalse);
    await expectValidTree();
  });

  test(
    'an existing cycle reports errors without unbounded traversal',
    () async {
      final replies = ReceivePort();
      final isolate = await Isolate.spawn(_readCorruptTree, <Object>[
        replies.sendPort,
        p.join(directory.path, 'corrupt.db'),
      ], onError: replies.sendPort);
      try {
        expect(await replies.first.timeout(const Duration(seconds: 3)), [
          'cycle reported',
          'cycle reported',
          'move accepted: false',
        ]);
      } finally {
        isolate.kill(priority: Isolate.immediate);
        replies.close();
      }
    },
  );
}
