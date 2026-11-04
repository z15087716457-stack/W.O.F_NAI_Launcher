import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_platform.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:path/path.dart' as p;

import '../../helpers/app_logger_test_isolation.dart';

class _Settings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(
    enabled: true,
    tagsEnabled: false,
    wikiEnabled: false,
    blocksEnabled: true,
    embedding: 'embedding',
    reranker: 'reranker',
  );
}

/// Counts every full pass over the library, which is what encoding it costs.
class _CountingBlocks extends ListBase<PromptBlock> {
  _CountingBlocks(this._blocks);
  final List<PromptBlock> _blocks;
  int passes = 0;
  @override
  int get length => _blocks.length;
  @override
  set length(int value) => throw UnsupportedError('read-only');
  @override
  PromptBlock operator [](int index) => _blocks[index];
  @override
  void operator []=(int index, PromptBlock value) =>
      throw UnsupportedError('read-only');
  @override
  Iterator<PromptBlock> get iterator {
    passes++;
    return _blocks.iterator;
  }
}

/// Counts every read of a block's tags. Encoding the library reads the tags
/// of every block; comparing two lists skips a block that is the same object.
class _CountingTags extends ListBase<PromptBlockTag> {
  _CountingTags(this._tags);
  final List<PromptBlockTag> _tags;
  int reads = 0;
  @override
  int get length => _tags.length;
  @override
  set length(int value) => throw UnsupportedError('read-only');
  @override
  PromptBlockTag operator [](int index) {
    reads++;
    return _tags[index];
  }

  @override
  void operator []=(int index, PromptBlockTag value) =>
      throw UnsupportedError('read-only');
}

class _Library extends PromptBlockLibraryState {
  _Library(this._blocks) : super(blocks: const [], folders: const []);
  final _CountingBlocks _blocks;
  @override
  List<PromptBlock> get blocks => _blocks;
}

class _Blocks extends PromptBlockLibraryNotifier {
  _Blocks(this.library);
  final _Library library;
  @override
  Future<PromptBlockLibraryState> build() async => library;
}

/// Answers configure and status; records every status heartbeat and search.
class _Worker implements Process {
  _Worker() {
    _send({'event': 'ready', 'protocol': 1});
    _input.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final request = (jsonDecode(line) as Map).cast<String, dynamic>();
          if (request['op'] == 'shutdown') return _exit();
          if (request['op'] == 'status') statuses++;
          if (request['op'] == 'text_search') searches++;
          _send({
            'id': request['id'],
            'result': {
              'sources': {
                'blocks': {'indexed': 1, 'total': 1, 'complete': true},
              },
              'jobs': [],
            },
          });
        }, onDone: _exit);
  }
  int statuses = 0;
  int searches = 0;
  final _input = StreamController<List<int>>();
  final _output = StreamController<List<int>>();
  final _exitCode = Completer<int>();
  late final IOSink _stdin = IOSink(_input.sink);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  Future<void> waitFor(bool Function() ready, String what) async {
    for (var i = 0; i < 500; i++) {
      if (ready()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('timed out waiting for: $what');
  }

  _CountingBlocks library(String content) => _CountingBlocks([
    PromptBlock.create(id: 'storm', title: 'Storm', content: content),
  ]);

  for (final platform in [RagPlatform.windows, RagPlatform.macOSArm64]) {
    test('${platform.name}: the heartbeat encodes the block library only '
        'after it changed', () async {
      final root = await Directory.systemTemp.createTemp('rag-blocks-');
      addTearDown(() => root.delete(recursive: true));
      File(platform.managedPython(root.path)).createSync(recursive: true);
      final worker = _Worker();
      final first = library('rain');
      final container = ProviderContainer(
        overrides: [
          ragPlatformProvider.overrideWithValue(platform),
          ragSettingsProvider.overrideWith(_Settings.new),
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _Blocks(_Library(first)),
          ),
          ragDirectoryProvider.overrideWithValue(() async => root),
          ragSourcePathsProvider.overrideWithValue(
            () async => (catalog: '', runtime: '', wiki: ''),
          ),
          ragWikiTranslationsPathProvider.overrideWithValue(() async => ''),
          ragHeartbeatIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 20),
          ),
          ragClientStarterProvider.overrideWithValue(
            ({required python, required directory}) async =>
                RagClient(worker, shutdownTimeout: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(ragControllerProvider);
      await waitFor(() => worker.statuses >= 10, 'ten heartbeats');
      // Opening wrote the snapshot once; ten heartbeats added nothing.
      // Before: one full encode on the UI thread per heartbeat.
      expect(first.passes, 1);
      final snapshot = File(p.join(root.path, 'sources', 'blocks.json'));
      expect(await snapshot.readAsString(), contains('rain'));

      final changed = library('snow');
      container.read(promptBlockLibraryNotifierProvider.notifier).state =
          AsyncData(_Library(changed));
      final seen = worker.statuses;
      await waitFor(() => worker.statuses >= seen + 5, 'five more heartbeats');
      expect(changed.passes, 1);
      expect(await snapshot.readAsString(), contains('snow'));
    });

    test('${platform.name}: a block search tells library changes apart '
        'without encoding the library', () async {
      final root = await Directory.systemTemp.createTemp('rag-block-search-');
      addTearDown(() => root.delete(recursive: true));
      File(platform.managedPython(root.path)).createSync(recursive: true);
      final worker = _Worker();
      final tags = [
        for (var i = 0; i < 20; i++)
          _CountingTags([PromptBlockTag(name: 'tag $i')]),
      ];
      final blocks = [
        for (var i = 0; i < tags.length; i++)
          PromptBlock.create(
            id: 'block $i',
            title: 'Block $i',
            content: 'rain $i',
            tags: tags[i],
          ),
      ];
      int reads() => tags.fold(0, (sum, t) => sum + t.reads);
      final container = ProviderContainer(
        overrides: [
          ragPlatformProvider.overrideWithValue(platform),
          ragSettingsProvider.overrideWith(_Settings.new),
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _Blocks(_Library(_CountingBlocks(blocks))),
          ),
          ragDirectoryProvider.overrideWithValue(() async => root),
          ragSourcePathsProvider.overrideWithValue(
            () async => (catalog: '', runtime: '', wiki: ''),
          ),
          ragWikiTranslationsPathProvider.overrideWithValue(() async => ''),
          ragClientStarterProvider.overrideWithValue(
            ({required python, required directory}) async =>
                RagClient(worker, shutdownTimeout: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
      void emit(List<PromptBlock> next) =>
          container.read(promptBlockLibraryNotifierProvider.notifier).state =
              AsyncData(_Library(_CountingBlocks(next)));
      var query = RagTextQuery(source: RagSource.blocks, query: 'rain');
      ProviderSubscription<AsyncValue<List<RagSearchHit>>> listen() =>
          container.listen(ragTextSearchProvider(query), (_, _) {});
      // Until a search the change started, if any, has its answer: the
      // provider rebuilds on the next event, then waits out its debounce.
      Future<void> settle() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await waitFor(
          () => !container.read(ragTextSearchProvider(query)).isLoading,
          'the search',
        );
      }

      final searches = <String, int>{};
      final tagReads = <String, int>{};
      Future<void> step(String change, void Function() apply) async {
        final (searched, read) = (worker.searches, reads());
        apply();
        await settle();
        searches[change] = worker.searches - searched;
        tagReads[change] = reads() - read;
      }

      var search = listen();
      await waitFor(() => worker.searches > 0, 'the first search');
      await settle();
      // A new query searches the list whose snapshot is already on disk.
      await step('typing', () {
        search.close();
        query = RagTextQuery(source: RagSource.blocks, query: 'rain at');
        search = listen();
      });
      await step('the same blocks in a new list', () => emit([...blocks]));
      await step(
        'a use count and a favourite',
        () => emit([
          blocks.first.copyWith(useCount: 3, isFavorite: true),
          ...blocks.skip(1),
        ]),
      );
      final reloaded = [
        for (final b in blocks) PromptBlock.fromJson(b.toJson()),
      ];
      await step('a reload with the same text', () => emit(reloaded));
      await step(
        'an edited text',
        () => emit([blocks.first.copyWith(content: 'snow'), ...blocks.skip(1)]),
      );

      expect(searches, {
        'typing': 1,
        'the same blocks in a new list': 0,
        'a use count and a favourite': 0,
        'a reload with the same text': 0,
        'an edited text': 1,
      });
      final snapshot = File(p.join(root.path, 'sources', 'blocks.json'));
      expect(await snapshot.readAsString(), contains('snow'));
      // Encoding reads every block's tags (20 reads). Comparing reads only
      // those of a block that is a new object, once for each copy. (A reload
      // and an edit make new blocks whose reads this list cannot count.)
      expect(
        {
          for (final change in [
            'typing',
            'the same blocks in a new list',
            'a use count and a favourite',
          ])
            change: tagReads[change],
        },
        {
          'typing': 0,
          'the same blocks in a new list': 0,
          'a use count and a favourite': 2,
        },
      );
    });
  }
}
