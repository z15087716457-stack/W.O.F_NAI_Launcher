import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_palette_provider.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      for (final id in ['A', 'B', 'C'])
        PromptBlock(
          id: id,
          title: id,
          content: id,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
    ],
    folders: [],
  );
}

class _ControlledStorage extends PromptBlockStorage {
  Completer<void>? writeStarted;
  Completer<void>? releaseWrite;
  bool failNextWrite = false;

  @override
  Future<void> putPaletteBlockIds(List<String> ids) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('write failed');
    }
    final started = writeStarted;
    if (started != null) {
      writeStarted = null;
      started.complete();
      await releaseWrite!.future;
    }
    await super.putPaletteBlockIds(ids);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  late Directory directory;
  late _ControlledStorage storage;
  late ProviderContainer container;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('palette_concurrency_');
    Hive.init(directory.path);
    storage = _ControlledStorage();
    await storage.init();
    container = ProviderContainer(
      overrides: [
        promptBlockStorageProvider.overrideWithValue(storage),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  PromptBlockPaletteNotifier palette() =>
      container.read(promptBlockPaletteNotifierProvider.notifier);

  Future<void> expectOrder(List<String> expected) async {
    expect(await storage.getPaletteBlockIds(), expected);
    final palette = await container.read(
      promptBlockPaletteNotifierProvider.future,
    );
    expect(palette.blocks.map((block) => block.id), expected);
  }

  test('concurrent additions retain both blocks', () async {
    await container.read(promptBlockPaletteNotifierProvider.future);
    await Future.wait([palette().addBlock('A'), palette().addBlock('B')]);
    await expectOrder(['A', 'B']);
  });

  test('remove and add both apply to the latest order', () async {
    await storage.putPaletteBlockIds(['A', 'B']);
    await container.read(promptBlockPaletteNotifierProvider.future);
    await Future.wait([palette().removeBlock('A'), palette().addBlock('C')]);
    await expectOrder(['B', 'C']);
  });

  test('move and insert both apply to the latest order', () async {
    await storage.putPaletteBlockIds(['A', 'B']);
    await container.read(promptBlockPaletteNotifierProvider.future);
    await Future.wait([palette().move(0, 1), palette().insertBlock('C', 0)]);
    await expectOrder(['C', 'B', 'A']);
  });

  test('startup pruning cannot overwrite an addition', () async {
    await storage.putPaletteBlockIds(['A', 'missing']);
    final started = Completer<void>();
    final release = Completer<void>();
    storage
      ..writeStarted = started
      ..releaseWrite = release;
    final loading = container.read(promptBlockPaletteNotifierProvider.future);
    await started.future;
    final adding = palette().addBlock('B');
    await Future<void>.delayed(Duration.zero);
    release.complete();
    await loading;
    await adding;
    await expectOrder(['A', 'B']);
  });

  test(
    'a failed write reports its error and releases the next operation',
    () async {
      await container.read(promptBlockPaletteNotifierProvider.future);
      storage.failNextWrite = true;
      final first = expectLater(palette().addBlock('A'), throwsStateError);
      final second = palette().addBlock('B');
      await first;
      await second;
      await expectOrder(['B']);
    },
  );
}
