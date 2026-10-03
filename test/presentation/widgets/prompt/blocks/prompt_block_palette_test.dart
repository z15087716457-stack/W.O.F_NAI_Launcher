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
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/fixed_tag_migration_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_palette_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
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

    test('removeBlocks and clear update state and persist', () async {
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
      for (final id in ids) {
        await notifier.addBlock(id);
      }

      // 批量移除两个。
      await notifier.removeBlocks({ids[0], ids[2]});
      var palette = await container.read(
        promptBlockPaletteNotifierProvider.future,
      );
      expect(palette.blocks.map((b) => b.id), [ids[1]]);
      expect(await storage.getPaletteBlockIds(), [ids[1]]);

      // 不存在的 id 批量移除 = 空操作。
      await notifier.removeBlocks({'ghost'});
      palette = await container.read(promptBlockPaletteNotifierProvider.future);
      expect(palette.blocks.map((b) => b.id), [ids[1]]);

      // 清空。
      await notifier.clear();
      palette = await container.read(promptBlockPaletteNotifierProvider.future);
      expect(palette.blocks, isEmpty);
      expect(await storage.getPaletteBlockIds(), isEmpty);

      // 空板上 clear = 空操作，不炸。
      await notifier.clear();
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
    Widget buildApp(ProviderContainer container, {bool reducedMotion = false}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reducedMotion),
            child: child!,
          ),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: PromptBlockPaletteButton(),
              ),
            ),
          ),
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
        expect(
          find.descendant(
            of: find.byKey(const Key('prompt-block-palette-toggle')),
            matching: find.byIcon(StudioIcons.promptBlockPalette),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('prompt-block-palette-toggle')));
        await tester.pump(const Duration(milliseconds: 120));
        expect(
          find.descendant(
            of: find.byKey(const Key('prompt-block-palette-toggle')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint && widget.painter is StudioIconPainter,
            ),
          ),
          findsOneWidget,
        );
        await tester.pump(); // palette provider 的异步 build 落地

        // 悬浮窗出现：空态提示 + X 常驻钮。
        expect(find.byKey(const Key('prompt-block-palette-close')), findsOne);
        expect(find.textContaining('拖进来收纳'), findsOne);
        await tester.pumpAndSettle();

        // X 关闭。
        await tester.tap(find.byKey(const Key('prompt-block-palette-close')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('prompt-block-palette-close')),
          findsNothing,
        );

        // 再开 → 点窗外（左上角屏障）关闭。
        await tester.tap(find.byKey(const Key('prompt-block-palette-toggle')));
        await tester.pump();
        expect(find.byKey(const Key('prompt-block-palette-close')), findsOne);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('prompt-block-palette-close')),
          findsNothing,
        );
      },
    );

    ProviderContainer emptyPalette() {
      final container = ProviderContainer(
        overrides: [
          promptBlockPaletteNotifierProvider.overrideWith(
            () => _FakePaletteNotifier(const []),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find.byKey(const Key('prompt-block-palette-fade')),
        )
        .opacity
        .value;

    final toggle = find.byKey(const Key('prompt-block-palette-toggle'));
    final close = find.byKey(const Key('prompt-block-palette-close'));
    final card = find.byKey(const Key('prompt-block-palette-card'));

    for (final method in ['X', 'outside', 'toolbar']) {
      testWidgets('closing via $method fades, shrinks and animates the icon', (
        tester,
      ) async {
        await tester.pumpWidget(buildApp(emptyPalette()));
        await tester.pump();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        final icon = find.descendant(
          of: toggle,
          matching: find.byType(StudioAnimatedIcon),
        );
        final trigger = tester.widget<StudioAnimatedIcon>(icon).trigger;
        final opened = tester.getRect(card);
        expect(opacity(tester), 1);
        switch (method) {
          case 'X':
            await tester.tap(close);
          case 'outside':
            await tester.tapAt(const Offset(10, 10));
          case 'toolbar':
            await tester.tap(toggle);
        }
        await tester.pump();
        expect(card, findsOneWidget);
        expect(tester.widget<StudioAnimatedIcon>(icon).trigger, trigger + 1);
        await tester.pump(const Duration(milliseconds: 60));
        expect(opacity(tester), inExclusiveRange(0, 1));
        expect(tester.getRect(card).width, lessThan(opened.width));
        expect(tester.getRect(card).topLeft, opened.topLeft);
        expect(
          find.descendant(
            of: icon,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint && widget.painter is StudioIconPainter,
            ),
          ),
          findsOneWidget,
        );
        await tester.pumpAndSettle();
        expect(card, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'reopening during close preserves one window and dragged position',
      (tester) async {
        await tester.pumpWidget(buildApp(emptyPalette()));
        await tester.pump();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        await tester.drag(find.text('积木').last, const Offset(-60, -30));
        await tester.pumpAndSettle();
        final opened = tester.getRect(card);
        await tester.tap(close);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final closingOpacity = opacity(tester);
        await tester.tap(toggle);
        await tester.pump();
        expect(opacity(tester), closeTo(closingOpacity, .001));
        await tester.pumpAndSettle();
        expect(card, findsOneWidget);
        expect(opacity(tester), 1);
        expect(tester.getRect(card), opened);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(card, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'disposing the toolbar while closing leaves no overlay or ticker',
      (tester) async {
        await tester.pumpWidget(buildApp(emptyPalette()));
        await tester.pump();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        await tester.tap(close);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await tester.pumpAndSettle();
        expect(card, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    for (final duringClose in [false, true]) {
      testWidgets(
        'reduced motion removes immediately duringClose=$duringClose',
        (tester) async {
          final container = emptyPalette();
          await tester.pumpWidget(
            buildApp(container, reducedMotion: !duringClose),
          );
          await tester.pump();
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(opacity(tester), 1);
          await tester.tap(close);
          await tester.pump();
          if (duringClose) {
            await tester.pump(const Duration(milliseconds: 60));
            await tester.pumpWidget(buildApp(container, reducedMotion: true));
            await tester.pump();
          }
          expect(card, findsNothing);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

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

    testWidgets('a two-sided block inserts into positive and negative lanes', (
      tester,
    ) async {
      final block = PromptBlock.create(
        id: 'b-paired',
        title: 'Paired',
        content: 'bright colors',
        negativeContent: 'muted colors',
      );
      final library = _SingleBlockLibraryNotifier(block);
      final container = ProviderContainer(
        overrides: [
          promptBlockPaletteNotifierProvider.overrideWith(
            () => _FakePaletteNotifier([block]),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(() => library),
          generationParamsNotifierProvider.overrideWith(
            _FakeGenerationParamsNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(promptBlockLibraryNotifierProvider.future);
      await tester.pumpWidget(buildApp(container));
      await tester.pump();
      await tester.tap(find.byKey(const Key('prompt-block-palette-toggle')));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Paired').first);
      await tester.pump();

      final positive = container.read(pillWorkspaceProvider(PillScopes.main));
      final negative = container.read(
        pillWorkspaceProvider(PillScopes.negative),
      );
      expect(positive.projection, 'bright colors');
      expect(negative.projection, 'muted colors');
      expect(
        negative.document.instances.values.single.useNegativeContent,
        isTrue,
      );
      final posInstance = positive.document.instances.values.single;
      final negInstance = negative.document.instances.values.single;
      expect(posInstance.bundleId, isNotNull);
      expect(negInstance.bundleId, posInstance.bundleId);
      expect(posInstance.rollScopeMask, 1);
      expect(negInstance.rollScopeMask, 1);

      // 块库编辑时负面编辑器未挂载，生成参数仍须收到新投影。
      library.publish(block.copyWith(negativeContent: 'new negative'));
      await tester.pump();
      await tester.pump();
      expect(
        container.read(pillWorkspaceProvider(PillScopes.negative)).projection,
        'new negative',
      );
      expect(
        container.read(generationParamsNotifierProvider).negativePrompt,
        'new negative',
      );
    });

    testWidgets('chips flow-wrap: short chips share a row', (tester) async {
      final blocks = [
        PromptBlock.create(id: 'b-1', title: 'A', content: 'a'),
        PromptBlock.create(id: 'b-2', title: 'B', content: 'b'),
      ];
      final container = ProviderContainer(
        overrides: [
          promptBlockPaletteNotifierProvider.overrideWith(
            () => _FakePaletteNotifier(blocks),
          ),
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

      // 两个窄芯片并排同一行（A 的右边挨着 B 的左边，顶部对齐）。
      await tester.pumpAndSettle();
      final a = tester.getRect(find.text('A').first);
      final b = tester.getRect(find.text('B').first);
      final card = tester.getRect(
        find.byKey(const Key('prompt-block-palette-card')),
      );
      final firstChip = tester.getRect(
        find.byKey(const ValueKey('prompt-block-pill-body-b-1')),
      );
      expect(a.top, closeTo(b.top, 1));
      expect(b.left, greaterThan(a.left));
      expect(firstChip.left - card.left, inInclusiveRange(8, 16));
    });

    testWidgets('multi-select mode picks chips and removes selection', (
      tester,
    ) async {
      final blocks = [
        PromptBlock.create(id: 'b-1', title: 'One', content: 'one'),
        PromptBlock.create(id: 'b-2', title: 'Two', content: 'two'),
      ];
      final container = ProviderContainer(
        overrides: [
          promptBlockPaletteNotifierProvider.overrideWith(
            () => _FakePaletteNotifier(blocks),
          ),
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

      // 进入多选：操作条出现、计数 0。
      await tester.tap(
        find.byKey(const Key('prompt-block-palette-multi-select')),
      );
      await tester.pump();
      expect(find.textContaining('已选 0 项'), findsOne);

      // 点芯片 = 切换选中（不是插入提示词）。
      await tester.tap(find.text('One').first);
      await tester.pump();
      expect(find.textContaining('已选 1 项'), findsOne);
      final lane = container.read(pillWorkspaceProvider(PillScopes.main));
      expect(
        lane.document.instances.values.any((i) => i.blockId == 'b-1'),
        isFalse,
      );

      // 移除选中 → 板上只剩 Two。
      await tester.tap(
        find.byKey(const Key('prompt-block-palette-remove-selected')),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsWidgets);

      // 退出多选 → 操作条消失。
      await tester.tap(
        find.byKey(const Key('prompt-block-palette-multi-select')),
      );
      await tester.pump();
      expect(find.textContaining('已选'), findsNothing);
    });

    testWidgets('clear-all needs a confirming second tap', (tester) async {
      final fake = _FakePaletteNotifier([
        PromptBlock.create(id: 'b-1', title: 'One', content: 'one'),
      ]);
      final container = ProviderContainer(
        overrides: [
          promptBlockPaletteNotifierProvider.overrideWith(() => fake),
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
      expect(find.text('One'), findsWidgets);

      // 第一击 = armed，不删。
      await tester.tap(find.byKey(const Key('prompt-block-palette-clear')));
      await tester.pump();
      expect(find.text('One'), findsWidgets);
      expect(fake.state.valueOrNull?.blocks, hasLength(1));

      // 第二击 = 确认清空。
      await tester.tap(find.byKey(const Key('prompt-block-palette-clear')));
      await tester.pump();
      await tester.pump();
      expect(find.text('One'), findsNothing);
      expect(fake.state.valueOrNull?.blocks, isEmpty);
    });

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

class _SingleBlockLibraryNotifier extends _NoopLibraryNotifier {
  _SingleBlockLibraryNotifier(this.block);

  final PromptBlock block;

  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [block], folders: const []);

  void publish(PromptBlock updated) {
    state = AsyncData(
      PromptBlockLibraryState(blocks: [updated], folders: const []),
    );
  }
}

class _FakeGenerationParamsNotifier extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();

  @override
  void updatePrompt(String prompt) {
    state = state.copyWith(prompt: prompt);
  }

  @override
  void updateNegativePrompt(String negativePrompt) {
    state = state.copyWith(negativePrompt: negativePrompt);
  }

  @override
  void updatePromptFromPill(String prompt) => updatePrompt(prompt);

  @override
  void updateNegativePromptFromPill(String negativePrompt) =>
      updateNegativePrompt(negativePrompt);
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
  Future<void> removeBlocks(Set<String> blockIds) async {
    _blocks.removeWhere((b) => blockIds.contains(b.id));
    _emit();
  }

  @override
  Future<void> clear() async {
    _blocks.clear();
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
