import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/danbooru_tag_data_source.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_platform.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Settings extends RagSettingsController {
  _Settings(this.settings);
  final RagSettings settings;
  @override
  RagSettings build() => settings;
}

/// RAG on, with [source] and [also] as its only sources.
RagSettings _only(RagSource source, {Set<RagSource> also = const {}}) {
  bool on(RagSource s) => s == source || also.contains(s);
  return RagSettings(
    enabled: true,
    tagsEnabled: on(RagSource.tags),
    wikiEnabled: on(RagSource.wiki),
    blocksEnabled: on(RagSource.blocks),
    galleryEnabled: on(RagSource.gallery),
    embedding: 'embedding',
    reranker: 'reranker',
  );
}

typedef _Respond =
    Map<String, dynamic>? Function(
      _Worker worker,
      String op,
      Map<String, dynamic> params,
    );

/// A worker process speaking the JSONL protocol; no Python involved.
class _Worker implements Process {
  _Worker(this.respond) {
    _send({'event': 'ready', 'protocol': 1});
    _input.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final request = (jsonDecode(line) as Map).cast<String, dynamic>();
          final op = request['op'] as String;
          ops.add(op);
          if (op == 'shutdown') return _exit();
          if (op == 'cancel') return;
          final params =
              (request['params'] as Map?)?.cast<String, dynamic>() ?? const {};
          requests.add((op: op, params: params));
          final result = respond(this, op, params);
          if (result != null) _send({'id': request['id'], 'result': result});
        }, onDone: _exit);
  }
  final _Respond respond;
  final ops = <String>[];

  /// Every request but shutdown and cancel, with its parameters.
  final requests = <({String op, Map<String, dynamic> params})>[];
  final _input = StreamController<List<int>>();
  final _output = StreamController<List<int>>();
  final _exitCode = Completer<int>();
  late final IOSink _stdin = IOSink(_input.sink);

  bool get exited => _exitCode.isCompleted;
  void event(Map<String, dynamic> value) => _send(value);
  void _send(Map<String, dynamic> value) {
    if (!_exitCode.isCompleted) {
      _output.add(utf8.encode('${jsonEncode(value)}\n'));
    }
  }

  void _exit() {
    if (_exitCode.isCompleted) return;
    _exitCode.complete(0);
    unawaited(_output.close());
  }

  @override
  IOSink get stdin => _stdin;
  @override
  Stream<List<int>> get stdout => _output.stream;
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode => _exitCode.future;
  @override
  int get pid => 9;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    _exit();
    return true;
  }
}

Map<String, dynamic> _index({
  bool complete = true,
  bool autoUpdate = true,
  bool building = false,
}) => {
  'indexed': 3,
  'total': 3,
  'complete': complete,
  'auto_update_allowed': autoUpdate,
  'building': building,
  'checking': false,
  'paused': false,
};

/// [also]: other enabled sources, up to date.
Map<String, dynamic> _status(
  RagSource source, {
  bool complete = true,
  bool autoUpdate = true,
  Set<RagSource> also = const {},
}) => {
  'sources': {
    for (final other in also) other.name: _index(autoUpdate: autoUpdate),
    source.name: _index(complete: complete, autoUpdate: autoUpdate),
  },
  'jobs': [],
  'suspended': false,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  setUpAll(sqfliteFfiInit);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  late Directory hive;
  late PromptBlockStorage blocks;
  setUpAll(() async {
    hive = await Directory.systemTemp.createTemp('rag-idle-blocks-');
    Hive.init(hive.path);
    blocks = PromptBlockStorage();
    await blocks.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await hive.delete(recursive: true);
  });

  const idle = Duration(milliseconds: 400);
  const heartbeat = Duration(milliseconds: 60);

  Future<void> waitFor(bool Function() ready, String what) async {
    for (var i = 0; i < 500; i++) {
      if (ready()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('timed out waiting for: $what');
  }

  for (final platform in [RagPlatform.windows, RagPlatform.macOSArm64]) {
    group(platform.name, () {
      late Directory root;
      late File runtime, wiki, translations;
      late List<_Worker> workers;
      late ProviderContainer container;
      late _Respond respond;
      // The only enabled source; a test picks it before the first read.
      late RagSource source;
      // Other enabled sources, up to date (none unless a test picks some).
      late Set<RagSource> also;
      // The worker finds the index behind; an update brings it up to date
      // (updatesWhenBehind).
      late bool behind;

      setUp(() async {
        root = await Directory.systemTemp.createTemp('rag-idle-');
        File(platform.managedPython(root.path)).createSync(recursive: true);
        File database(String name) =>
            File(p.join(root.path, name))..writeAsStringSync(name);
        // danbooru.db holds both the runtime tag table and the local gallery:
        // every saved image writes it.
        runtime = database('danbooru.db');
        final catalog = database('tag_catalog.db');
        wiki = database('tag_wiki.db');
        translations = database('visible_tag_translations.db');
        final semantics = database('tag_semantics.db');
        final supplements = database('tag_supplements.db');
        source = RagSource.wiki;
        also = {};
        behind = false;
        workers = [];
        respond = (worker, op, params) => switch (op) {
          'text_search' => {'items': []},
          _ => _status(source, also: also),
        };
        await blocks.clear();
        container = ProviderContainer(
          overrides: [
            ragPlatformProvider.overrideWithValue(platform),
            ragSettingsProvider.overrideWith(
              () => _Settings(_only(source, also: also)),
            ),
            ragDirectoryProvider.overrideWithValue(() async => root),
            ragSourcePathsProvider.overrideWithValue(
              () async => (
                catalog: catalog.path,
                runtime: runtime.path,
                wiki: wiki.path,
              ),
            ),
            ragWikiTranslationsPathProvider.overrideWithValue(
              () async => translations.path,
            ),
            ragTagSemanticsPathsProvider.overrideWithValue(
              () async => (base: semantics.path, supplements: supplements.path),
            ),
            ragGalleryRootsProvider.overrideWithValue(() async => [root.path]),
            promptBlockStorageProvider.overrideWithValue(blocks),
            ragIdleShutdownProvider.overrideWithValue(idle),
            ragHeartbeatIntervalProvider.overrideWithValue(heartbeat),
            ragClientStarterProvider.overrideWithValue(({
              required python,
              required directory,
            }) async {
              final worker = _Worker((w, op, params) => respond(w, op, params));
              workers.add(worker);
              return RagClient(
                worker,
                shutdownTimeout: const Duration(seconds: 5),
              );
            }),
          ],
        );
      });

      tearDown(() async {
        container.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await root.delete(recursive: true);
      });

      RagController controller() =>
          container.read(ragControllerProvider.notifier);
      RagStatus status() =>
          container.read(ragControllerProvider).forSource(source);

      Future<void> open() async {
        container.read(ragControllerProvider);
        await waitFor(
          () => workers.length == 1 && status().phase == 'ready',
          'the first worker',
        );
      }

      Future<void> openAndIdle() async {
        await open();
        await waitFor(() => workers.single.exited, 'the idle close');
      }

      /// Starts an update of [source] that completes 20 ms later.
      Map<String, dynamic> update(_Worker worker) {
        Timer(const Duration(milliseconds: 20), () {
          worker.event({
            'event': 'index',
            'source': source.name,
            'job_id': 'job',
            'phase': 'complete',
            ..._index(),
          });
        });
        return {'job_id': 'job'};
      }

      /// A reopened worker finds the index behind and updates it.
      void behindAfterReopen() {
        respond = (worker, op, params) => switch (op) {
          'preview' => {'plan_id': 'plan'},
          'start' => update(worker),
          _ => _status(source, complete: workers.length == 1, also: also),
        };
      }

      /// The worker reports the index behind while [behind] holds, as the
      /// worker's own signature finds it, until an update.
      void updatesWhenBehind() {
        respond = (worker, op, params) {
          switch (op) {
            case 'preview':
              return {'plan_id': 'plan'};
            case 'start':
              behind = false;
              return update(worker);
            default:
              return _status(source, complete: !behind, also: also);
          }
        };
      }

      Future<void> expectReopenedForUpdate() async {
        await waitFor(() => workers.length == 2, 'the reopen');
        await waitFor(
          () => workers.last.ops.contains('start'),
          'the automatic update',
        );
        expect(
          workers.last.ops,
          containsAllInOrder(['configure', 'preview', 'start']),
        );
      }

      Future<void> expectStaysClosed(String reason) async {
        await Future<void>.delayed(heartbeat * 6);
        expect(workers, hasLength(1), reason: reason);
      }

      /// danbooru.db as SQLite writes it (WAL), with the gallery tables and
      /// the runtime tag table, written through the app's data sources.
      Future<(GalleryDataSource, DanbooruTagDataSource)> realDatabase() async {
        await runtime.delete();
        await ConnectionPoolHolder.initialize(
          dbPath: runtime.path,
          maxConnections: 2,
        );
        final gallery = GalleryDataSource();
        final tags = DanbooruTagDataSource();
        addTearDown(() async {
          await tags.dispose();
          await gallery.dispose();
          await ConnectionPoolHolder.dispose();
        });
        await gallery.initialize();
        await tags.initialize();
        return (gallery, tags);
      }

      Future<int> saveImage(GalleryDataSource gallery, String name) =>
          gallery.upsertImage(
            filePath: p.join(root.path, name),
            fileName: name,
            fileSize: 1,
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          );

      /// Size and time of danbooru.db and its WAL.
      String stamp() => [
        for (final file in [runtime, File('${runtime.path}-wal')])
          if (file.existsSync())
            '${file.lengthSync()} '
                '${file.lastModifiedSync().microsecondsSinceEpoch}',
      ].join(', ');

      test('an unused worker closes; heartbeats do not keep it', () async {
        await openAndIdle();
        final first = workers.single;
        expect(first.ops.where((op) => op == 'status'), isNotEmpty);
        expect(first.ops.last, 'shutdown', reason: 'a graceful shutdown');
        // The last known index stays on screen; nothing reports an error.
        expect(status().indexed, 3);
        expect(status().available, isTrue);
        expect(status().error, isNull);
        // No heartbeat and no new worker while nobody uses it.
        await Future<void>.delayed(heartbeat * 5);
        expect(workers, hasLength(1));
      });

      test('the next search reopens the worker by itself', () async {
        await openAndIdle();
        final hits = await controller().searchText(
          RagTextQuery(source: RagSource.wiki, query: 'rain'),
          cancellation: RagCancellation(),
        );
        expect(hits, isEmpty);
        expect(workers, hasLength(2));
        expect(
          workers.last.ops,
          containsAllInOrder(['configure', 'text_search']),
        );
        expect(status().error, isNull);
        expect(status().phase, 'ready');
      });

      test('use keeps the worker open', () async {
        await open();
        for (var i = 0; i < 4; i++) {
          await Future<void>.delayed(idle ~/ 2);
          await controller().searchText(
            RagTextQuery(source: RagSource.wiki, query: 'rain'),
            cancellation: RagCancellation(),
          );
        }
        expect(workers.single.exited, isFalse);
        expect(workers, hasLength(1));
      });

      test('a running index build is never closed mid-way', () async {
        respond = (worker, op, params) {
          switch (op) {
            case 'preview':
              return {'plan_id': 'plan'};
            case 'start':
              var step = 0;
              Timer.periodic(const Duration(milliseconds: 100), (timer) {
                step++;
                if (step < 10) {
                  worker.event({
                    'event': 'index',
                    'source': 'wiki',
                    'job_id': 'job',
                    'phase': 'building',
                    'processed': step,
                    'total': 10,
                    ..._index(building: true),
                  });
                } else {
                  timer.cancel();
                  worker.event({
                    'event': 'index',
                    'source': 'wiki',
                    'job_id': 'job',
                    'phase': 'complete',
                    ..._index(),
                  });
                }
              });
              return {'job_id': 'job'};
            default:
              return _status(source);
          }
        };
        await open();
        final plan = await controller().preview(source: RagSource.wiki);
        await controller().start(
          plan['plan_id'] as String,
          source: RagSource.wiki,
        );
        // The build takes 1 s, more than twice the idle time.
        await Future<void>.delayed(const Duration(milliseconds: 900));
        expect(workers.single.exited, isFalse);
        await waitFor(
          () => status().jobId == null && !status().busy,
          'the build',
        );
        await waitFor(() => workers.single.exited, 'the close after the build');
        expect(workers, hasLength(1));
      });

      test('a favourite, a collection or a tag leaves a closed gallery index '
          'closed; a saved image wakes it for its update', () async {
        // The gallery index reads only the picture rows of danbooru.db
        // (gallery.py GallerySources signs them); favourites, collections
        // and tags are in that file too.
        source = RagSource.gallery;
        behindAfterReopen();
        final (gallery, _) = await realDatabase();
        final image = await saveImage(gallery, 'first.png');
        await openAndIdle();
        final before = stamp();
        final collection = await gallery.createCollection('Picks');
        final unrelated = <(String, Future<void> Function())>[
          ('favourite', () => gallery.toggleFavorite(image)),
          (
            'add to a collection',
            () => gallery.addImageToCollection(collection, image),
          ),
          ('tag', () => gallery.addTag(image, 'rain')),
        ];
        for (final (change, apply) in unrelated) {
          await apply();
          await Future<void>.delayed(heartbeat * 3);
          expect(workers, hasLength(1), reason: change);
        }
        expect(stamp(), isNot(before), reason: 'they are in the file');
        await saveImage(gallery, 'new.png');
        await expectReopenedForUpdate();
      });

      test(
        'a saved image does not wake the tag index; a tag sync does',
        () async {
          // danbooru.db as SQLite writes it (WAL), with the gallery tables and
          // the runtime tag table. The tag index reads only the tag rows
          // (engine.py Sources signs them); a saved image writes the gallery.
          source = RagSource.tags;
          behindAfterReopen();
          final (gallery, tags) = await realDatabase();
          await openAndIdle();
          final before = stamp();
          await saveImage(gallery, 'new.png');
          expect(stamp(), isNot(before), reason: 'the image is in the file');
          await expectStaysClosed('a saved image leaves the tag rows');
          await tags.upsertBatch([
            const DanbooruTagRecord(
              tag: 'rain',
              category: 0,
              postCount: 1200,
              lastUpdated: 0,
            ),
          ]);
          await expectReopenedForUpdate();
        },
      );

      test('with the tag index on as well, a new image still wakes it '
          'for the gallery', () async {
        // Both read danbooru.db; a saved image writes the picture rows the
        // gallery index reads.
        source = RagSource.gallery;
        also = {RagSource.tags};
        behindAfterReopen();
        final (gallery, _) = await realDatabase();
        await openAndIdle();
        await saveImage(gallery, 'new.png');
        await expectReopenedForUpdate();
      });

      test('the gallery index too: a saved image an open worker has seen '
          'does not wake it once closed', () async {
        // While it runs, the worker signs the picture rows itself (gallery.py
        // GallerySources) and the heartbeat updates what it finds behind.
        source = RagSource.gallery;
        updatesWhenBehind();
        final (gallery, _) = await realDatabase();
        await open();
        await saveImage(gallery, 'new.png');
        behind = true;
        await waitFor(
          () => workers.single.ops.contains('start'),
          'the update on a heartbeat',
        );
        await waitFor(() => workers.single.exited, 'the idle close');
        await expectStaysClosed('its last status came after the save');
      });

      test('an open worker goes by its own status; '
          'a sync it has seen does not wake it once closed', () async {
        // While it runs, the worker signs the tag rows itself (engine.py
        // Sources) and the heartbeat updates what it finds behind.
        source = RagSource.tags;
        updatesWhenBehind();
        await open();
        runtime.writeAsStringSync('gallery + one new image');
        DanbooruTagDataSource.markTableChanged();
        behind = true;
        await waitFor(
          () => workers.single.ops.contains('start'),
          'the update on a heartbeat',
        );
        await waitFor(() => workers.single.exited, 'the idle close');
        await expectStaysClosed('its last status came after the sync');
      });

      test('a worker that starts finds by itself what changed while the app '
          'was closed', () async {
        // Nothing in this run wrote the tag table: the worker's signature
        // finds the change, as before.
        source = RagSource.tags;
        final revision = DanbooruTagDataSource.tableRevision;
        behind = true;
        updatesWhenBehind();
        container.read(ragControllerProvider);
        await waitFor(
          () => workers.length == 1 && workers.single.ops.contains('start'),
          'the update after the start',
        );
        expect(DanbooruTagDataSource.tableRevision, revision);
      });

      test('the app\'s own gallery update is no check of every picture; '
          'a check asked for says so', () async {
        // The worker reads every picture for a check someone asked for (the
        // settings' build button: verify), only the changed ones otherwise.
        source = RagSource.gallery;
        behind = true;
        updatesWhenBehind();
        container.read(ragControllerProvider);
        await waitFor(
          () => workers.length == 1 && workers.single.ops.contains('start'),
          'the update after the start',
        );
        Map<String, dynamic> previewed() => workers.single.requests
            .lastWhere((request) => request.op == 'preview')
            .params;
        expect(previewed(), {'source': 'gallery'});
        await waitFor(
          () => status().jobId == null && !status().busy,
          'the end of the update',
        );
        await controller().preview(source: RagSource.gallery, verify: true);
        expect(previewed(), {'source': 'gallery', 'verify': true});
      });

      test(
        'the wiki wakes for a saved translation, not for a new image',
        () async {
          // documents.py WikiSources reads the wiki, the catalog and the saved
          // translations, never danbooru.db.
          behindAfterReopen();
          final (gallery, _) = await realDatabase();
          await openAndIdle();
          await saveImage(gallery, 'new.png');
          DanbooruTagDataSource.markTableChanged();
          await expectStaysClosed('the wiki does not read danbooru.db');
          translations.writeAsStringSync('translations + one more');
          await expectReopenedForUpdate();
        },
      );

      test(
        'with only the block library, images and translations never wake it',
        () async {
          source = RagSource.blocks;
          final library = container.read(
            promptBlockLibraryNotifierProvider.notifier,
          );
          final block = await library.createBlock(
            title: 'Storm',
            content: 'rain',
          );
          await openAndIdle();
          runtime.writeAsStringSync('gallery + one new image');
          DanbooruTagDataSource.markTableChanged();
          translations.writeAsStringSync('translations + one more');
          wiki.writeAsStringSync('wiki + one more page');
          await expectStaysClosed('the block library reads none of them');
          // It is still watched: its own change reopens it.
          await library.updateBlock(block.copyWith(content: 'rain at night'));
          await waitFor(() => workers.length == 2, 'the reopen');
        },
      );

      test('using, favouriting or filing a block does not wake it; '
          'editing its text does', () async {
        source = RagSource.blocks;
        behindAfterReopen();
        final library = container.read(
          promptBlockLibraryNotifierProvider.notifier,
        );
        final block = await library.createBlock(
          title: 'Storm',
          content: 'rain',
        );
        await library.createBlock(title: 'Snow', content: 'snow');
        final folder = await library.createFolder(name: 'Weather');
        await openAndIdle();
        // Each replaces the library's block list; none changes its snapshot.
        final unrelated = <(String, Future<void> Function())>[
          ('insert into a prompt', () => library.incrementUseCount(block.id)),
          ('favourite', () => library.toggleFavorite(block.id)),
          ('move to a folder', () => library.moveBlock(block.id, folder.id)),
          (
            'add to a collection',
            () async {
              final picks = await library.createCollection(name: 'Picks');
              await library.toggleBlockInCollection(picks.id, block.id);
            },
          ),
        ];
        for (final (change, apply) in unrelated) {
          await apply();
          await Future<void>.delayed(heartbeat * 3);
          expect(workers, hasLength(1), reason: change);
        }
        final current = (await container.read(
          promptBlockLibraryNotifierProvider.future,
        )).blockById(block.id)!;
        expect(current.useCount, 1);
        expect(current.folderId, folder.id);
        await library.updateBlock(current.copyWith(content: 'rain at night'));
        await expectReopenedForUpdate();
        final snapshot = File(p.join(root.path, 'sources', 'blocks.json'));
        expect(await snapshot.readAsString(), contains('rain at night'));
      });

      test('without automatic updates a closed worker stays closed', () async {
        source = RagSource.gallery;
        respond = (worker, op, params) => _status(source, autoUpdate: false);
        final (gallery, _) = await realDatabase();
        await openAndIdle();
        await saveImage(gallery, 'new.png');
        await expectStaysClosed('no source updates itself');
      });
    });
  }
}
