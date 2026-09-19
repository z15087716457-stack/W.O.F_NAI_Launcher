import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/fixed_tag_migration_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_palette_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late PromptBlockStorage storage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'prompt_block_palette_test_',
    );
    Hive.init(hiveDirectory.path);
    storage = PromptBlockStorage();
    await storage.init();
  });

  setUp(() async {
    await storage.clear();
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      await Hive.box(StorageKeys.settingsBox).clear();
    } else {
      await Hive.openBox(StorageKeys.settingsBox);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<PromptBlockLibraryNotifier> seedLibrary(
    ProviderContainer container,
    List<({String title, String content})> seeds,
  ) async {
    final notifier = container.read(
      promptBlockLibraryNotifierProvider.notifier,
    );
    for (final seed in seeds) {
      await notifier.createBlock(title: seed.title, content: seed.content);
    }
    await container.read(promptBlockLibraryNotifierProvider.future);
    return notifier;
  }

  group('PromptBlockStorage palette ids', () {
    test('palette id list round-trips and survives empty write', () async {
      expect(await storage.getPaletteBlockIds(), isEmpty);

      await storage.putPaletteBlockIds(['b-2', 'b-1', 'b-3']);
      expect(await storage.getPaletteBlockIds(), ['b-2', 'b-1', 'b-3']);

      await storage.putPaletteBlockIds(const []);
      expect(await storage.getPaletteBlockIds(), isEmpty);
    });

    test('meta flag round-trips independently of palette ids', () async {
      expect(await storage.getMeta('flagX'), isNull);
      await storage.putMeta('flagX', '1');
      await storage.putPaletteBlockIds(['b-1']);
      expect(await storage.getMeta('flagX'), '1');
      expect(await storage.getPaletteBlockIds(), ['b-1']);
    });
  });

  group('PromptBlockPaletteNotifier', () {
    test('add/insert/remove/move update state and persist order', () async {
      final container = makeContainer();
      final library = await seedLibrary(container, [
        (title: 'A', content: 'a'),
        (title: 'B', content: 'b'),
        (title: 'C', content: 'c'),
      ]);
      final ids = library.state.value!.blocks.map((b) => b.id).toList();
      final notifier = container.read(
        promptBlockPaletteNotifierProvider.notifier,
      );

      await notifier.addBlock(ids[0]);
      await notifier.addBlock(ids[2]);
      // 重复收纳是幂等空操作。
      await notifier.addBlock(ids[0]);

      var palette = await container.read(
        promptBlockPaletteNotifierProvider.future,
      );
      expect(palette.blocks.map((b) => b.id), [ids[0], ids[2]]);

      // 收纳到指定下标。
      await notifier.insertBlock(ids[1], 1);
      palette = await container.read(promptBlockPaletteNotifierProvider.future);
      expect(palette.blocks.map((b) => b.id), [ids[0], ids[1], ids[2]]);

      // 板内移动（ReorderableListView 语义：newIndex 已是移除后坐标）。
      await notifier.move(0, 2);
      palette = await container.read(promptBlockPaletteNotifierProvider.future);
      expect(palette.blocks.map((b) => b.id), [ids[1], ids[2], ids[0]]);

      // 移除。
      await notifier.removeBlock(ids[1]);
      palette = await container.read(promptBlockPaletteNotifierProvider.future);
      expect(palette.blocks.map((b) => b.id), [ids[2], ids[0]]);

      // 顺序已落盘：冷启动按持久化 id 表重建。
      expect(await storage.getPaletteBlockIds(), [ids[2], ids[0]]);
    });

    test(
      'palette resolves live block data and prunes deleted blocks',
      () async {
        final container = makeContainer();
        final library = await seedLibrary(container, [
          (title: 'A', content: 'a'),
          (title: 'B', content: 'b'),
        ]);
        final ids = library.state.value!.blocks.map((b) => b.id).toList();
        final notifier = container.read(
          promptBlockPaletteNotifierProvider.notifier,
        );
        await notifier.addBlock(ids[0]);
        await notifier.addBlock(ids[1]);

        // 库内改块标题 → 板上引用自动跟随（按 id 解析，不拷内容）。
        final blockA = library.state.value!.blockById(ids[0])!;
        await library.updateBlock(blockA.copyWith(title: 'A2'));
        var palette = await container.read(
          promptBlockPaletteNotifierProvider.future,
        );
        expect(palette.blocks.first.title, 'A2');

        // 库删块 → 板引用被修剪并回写 id 表。
        await library.deleteBlock(ids[1]);
        palette = await container.read(
          promptBlockPaletteNotifierProvider.future,
        );
        expect(palette.blocks.map((b) => b.id), [ids[0]]);
        expect(await storage.getPaletteBlockIds(), [ids[0]]);
      },
    );
  });

  group('FixedTagMigrationService', () {
    Future<void> writeLegacyEntries(List<Map<String, dynamic>> entries) async {
      await Hive.box(
        StorageKeys.settingsBox,
      ).put('fixed_tags_data', jsonEncode(entries));
      await Hive.box(
        StorageKeys.settingsBox,
      ).put('fixed_tags_sidebar_expanded', true);
    }

    Future<FixedTagMigrationService> makeService() async {
      return FixedTagMigrationService(
        blockStorage: storage,
        localStorage: LocalStorageService(),
      );
    }

    test(
      'migrates entries to blocks, pins enabled ones, cleans keys',
      () async {
        await writeLegacyEntries([
          {
            'id': 'ft-1',
            'name': '质量前缀',
            'content': 'masterpiece',
            'weight': 1.0,
            'position': 'prefix',
            'enabled': true,
            'promptType': 'positive',
            'sortOrder': 0,
          },
          {
            'id': 'ft-2',
            'name': '弱化尾巴',
            'content': 'extra',
            'weight': 1.1025,
            'position': 'suffix',
            'enabled': true,
            'promptType': 'positive',
            'sortOrder': 1,
          },
          {
            'id': 'ft-3',
            'name': '禁用项',
            'content': 'disabled content',
            'weight': 1.0,
            'enabled': false,
            'sortOrder': 2,
          },
        ]);

        await (await makeService()).run();

        final data = await PromptBlockRepository(storage).load();
        expect(data.blocks, hasLength(3));
        expect(
          data.blocks.firstWhere((b) => b.title == '质量前缀').content,
          'masterpiece',
        );
        // weight 1.1025 → round(log(1.1025)/log(1.05)) = 2 层 {} 包裹。
        expect(
          data.blocks.firstWhere((b) => b.title == '弱化尾巴').content,
          '{{extra}}',
        );

        // 仅启用的两条按 sortOrder 上板。
        final paletteIds = await storage.getPaletteBlockIds();
        expect(paletteIds, hasLength(2));
        final byId = {for (final b in data.blocks) b.id: b};
        expect(byId[paletteIds[0]]?.title, '质量前缀');
        expect(byId[paletteIds[1]]?.title, '弱化尾巴');

        // 旧键清除 + 旗标落盘。
        expect(
          Hive.box(StorageKeys.settingsBox).get('fixed_tags_data'),
          isNull,
        );
        expect(
          Hive.box(StorageKeys.settingsBox).get('fixed_tags_sidebar_expanded'),
          isNull,
        );
        expect(await storage.getMeta('fixedTagMigrationDone'), '1');
      },
    );

    test('is idempotent and reuses blocks with identical content', () async {
      await writeLegacyEntries([
        {'id': 'ft-1', 'name': 'n', 'content': 'dup', 'enabled': true},
      ]);
      await (await makeService()).run();
      final first = await PromptBlockRepository(storage).load();
      expect(first.blocks, hasLength(1));

      // 二次执行被旗标短路，不重复建块。
      await writeLegacyEntries([
        {'id': 'ft-2', 'name': 'n2', 'content': 'dup', 'enabled': true},
      ]);
      await (await makeService()).run();
      final second = await PromptBlockRepository(storage).load();
      expect(second.blocks, hasLength(1));
    });

    test('no legacy data still clears keys and sets the flag', () async {
      await Hive.box(
        StorageKeys.settingsBox,
      ).put('fixed_tags_sidebar_width', 300.0);
      await (await makeService()).run();

      expect(
        await PromptBlockRepository(storage).load().then((d) => d.blocks),
        isEmpty,
      );
      expect(await storage.getPaletteBlockIds(), isEmpty);
      expect(
        Hive.box(StorageKeys.settingsBox).get('fixed_tags_sidebar_width'),
        isNull,
      );
      expect(await storage.getMeta('fixedTagMigrationDone'), '1');
    });
  });

  group('PromptBlockPaletteButton overlay', () {
    Widget buildApp(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: PromptBlockPaletteButton())),
        ),
      );
    }

    testWidgets(
      'opens on tap, shows empty hint, closes via X and outside tap',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            promptBlockPaletteNotifierProvider.overrideWith(
              () => _FakePaletteNotifier(const []),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(buildApp(container));
        await tester.pump();

        await tester.tap(find.byKey(const Key('prompt-block-palette-toggle')));
        await tester.pump();
        await tester.pump(); // palette provider 的异步 build 落地

        // 悬浮窗出现：空态提示 + X 常驻钮。
        expect(find.byKey(const Key('prompt-block-palette-close')), findsOne);
        expect(find.textContaining('拖进来收纳'), findsOne);

        // X 关闭。
        await tester.tap(find.byKey(const Key('prompt-block-palette-close')));
        await tester.pump();
        expect(
          find.byKey(const Key('prompt-block-palette-close')),
          findsNothing,
        );

        // 再开 → 点窗外（左上角屏障）关闭。
        await tester.tap(find.byKey(const Key('prompt-block-palette-toggle')));
        await tester.pump();
        expect(find.byKey(const Key('prompt-block-palette-close')), findsOne);
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        expect(
          find.byKey(const Key('prompt-block-palette-close')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'palette chips hide the empty hint and insert at caret on tap',
      (tester) async {
        final block = PromptBlock.create(
          id: 'b-glow',
          title: 'Glow',
          content: 'glowing',
        );
        final container = ProviderContainer(
          overrides: [
            promptBlockPaletteNotifierProvider.overrideWith(
              () => _FakePaletteNotifier([block]),
            ),
            // 点击插入会 fire-and-forget 调 incrementUseCount 写真 Hive；
            // fake-zone 里 I/O 锁会让 tearDownAll 的 Hive.close() 死等，
            // 这里换 no-op fake 彻底绕开。
            promptBlockLibraryNotifierProvider.overrideWith(
              _NoopLibraryNotifier.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(buildApp(container));
        await tester.pump();
        await tester.tap(find.byKey(const Key('prompt-block-palette-toggle')));
        await tester.pump();
        await tester.pump();

        // 有块时空态提示消失。
        expect(find.text('Glow'), findsWidgets);
        expect(find.textContaining('拖进来收纳'), findsNothing);

        // 点击芯片 → 主提示词 lane 插入该块实例。
        await tester.tap(find.text('Glow').first);
        await tester.pump();

        final lane = container.read(pillWorkspaceProvider(PillScopes.main));
        expect(
          lane.document.instances.values.any((i) => i.blockId == 'b-glow'),
          isTrue,
        );
      },
    );

    testWidgets('dragging a library block onto the button adds it to palette', (
      tester,
    ) async {
      final fake = _FakePaletteNotifier(const []);
      final container = ProviderContainer(
        overrides: [
          promptBlockPaletteNotifierProvider.overrideWith(() => fake),
          promptBlockLibraryNotifierProvider.overrideWith(
            _NoopLibraryNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  Draggable<PromptBlockDragData>(
                    data: PromptBlockDragData(blockId: 'b-x'),
                    feedback: SizedBox(width: 10, height: 10),
                    child: ColoredBox(
                      key: Key('palette-test-drag-source'),
                      color: Colors.red,
                      child: SizedBox(width: 40, height: 40),
                    ),
                  ),
                  PromptBlockPaletteButton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // 先让 provider 完成初始 build——fake 的 addBlock 直接写 state，
      // 若与 build 竞态会被 build 结果覆盖（生产代码已在 _update 内 await）。
      await container.read(promptBlockPaletteNotifierProvider.future);

      final source = tester.getCenter(
        find.byKey(const Key('palette-test-drag-source')),
      );
      final button = tester.getCenter(
        find.byKey(const Key('prompt-block-palette-toggle')),
      );
      await tester.drag(
        find.byKey(const Key('palette-test-drag-source')),
        button - source,
      );
      await tester.pump();

      expect(fake.state.valueOrNull?.blocks.map((b) => b.id), ['b-x']);
    });
  });
}

/// 不碰 Hive 的块库 notifier：widget 测试里吃掉 incrementUseCount。
class _NoopLibraryNotifier extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);

  @override
  Future<void> incrementUseCount(String blockId) async {}
}

/// 测试用积木 notifier：内存态，跳过 Hive。
class _FakePaletteNotifier extends PromptBlockPaletteNotifier {
  _FakePaletteNotifier(List<PromptBlock> blocks) : _blocks = List.of(blocks);

  final List<PromptBlock> _blocks;

  @override
  Future<PromptBlockPaletteState> build() async =>
      PromptBlockPaletteState(blocks: _blocks);

  void _emit() {
    state = AsyncData(PromptBlockPaletteState(blocks: _blocks));
  }

  PromptBlock _fakeBlock(String id) =>
      PromptBlock.create(id: id, title: id, content: id);

  @override
  Future<void> addBlock(String blockId) async {
    if (_blocks.any((b) => b.id == blockId)) return;
    _blocks.add(_fakeBlock(blockId));
    _emit();
  }

  @override
  Future<void> insertBlock(String blockId, int index) async {
    _blocks.removeWhere((b) => b.id == blockId);
    _blocks.insert(index.clamp(0, _blocks.length), _fakeBlock(blockId));
    _emit();
  }

  @override
  Future<void> removeBlock(String blockId) async {
    _blocks.removeWhere((b) => b.id == blockId);
    _emit();
  }

  @override
  Future<void> move(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _blocks.length) return;
    if (newIndex < 0 || newIndex >= _blocks.length) return;
    _blocks.insert(newIndex, _blocks.removeAt(oldIndex));
    _emit();
  }
}
