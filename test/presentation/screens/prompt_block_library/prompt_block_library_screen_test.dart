import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_collection.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/prompt_block_library_screen.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_card.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_folder_delete_dialog.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_detail.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_edit_dialog.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_icons.dart';

class _FakePromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakePromptBlockLibraryNotifier({required this.initialState});

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;

  @override
  Future<PromptBlock> updateBlock(PromptBlock block) async {
    final current = state.valueOrNull ?? initialState;
    final updatedBlocks = current.blocks
        .map((item) => item.id == block.id ? block : item)
        .toList();
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: updatedBlocks,
        folders: current.folders,
        collections: current.collections,
      ),
    );
    return block;
  }

  @override
  Future<PromptBlock> toggleFavorite(String blockId) async {
    final current = state.valueOrNull ?? initialState;
    final block = current.blockById(blockId);
    if (block == null) {
      throw StateError('Prompt block does not exist: $blockId');
    }
    final updated = block.copyWith(isFavorite: !block.isFavorite);
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: [
          for (final item in current.blocks)
            item.id == blockId ? updated : item,
        ],
        folders: current.folders,
        collections: current.collections,
      ),
    );
    return updated;
  }

  @override
  Future<bool> toggleBlockInCollection(
    String collectionId,
    String blockId,
  ) async {
    final current = state.valueOrNull ?? initialState;
    final target = current.collectionById(collectionId);
    if (target == null || target.isFolder) {
      throw StateError('Prompt block collection does not exist: $collectionId');
    }
    final members = [...target.blockIds];
    final nowMember = !members.remove(blockId);
    if (nowMember) members.add(blockId);
    final block = current.blockById(blockId);
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: [
          for (final item in current.blocks)
            item.id == blockId && nowMember && !(block?.isFavorite ?? true)
                ? item.copyWith(isFavorite: true)
                : item,
        ],
        folders: current.folders,
        collections: [
          for (final node in current.collections)
            node.id == collectionId ? node.copyWith(blockIds: members) : node,
        ],
      ),
    );
    return nowMember;
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    final current = state.valueOrNull ?? initialState;
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: current.blocks.where((item) => item.id != blockId).toList(),
        folders: current.folders,
        collections: current.collections,
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PromptBlock makeBlock(String id, String title, String content) {
    return PromptBlock.create(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  Widget buildScreen({
    List<PromptBlock> blocks = const [],
    List<PromptBlockFolder> folders = const [],
    List<PromptBlockCollection> collections = const [],
    _FakePromptBlockLibraryNotifier? notifier,
  }) {
    final effectiveNotifier =
        notifier ??
        _FakePromptBlockLibraryNotifier(
          initialState: PromptBlockLibraryState(
            blocks: blocks,
            folders: folders,
            collections: collections,
          ),
        );
    return ProviderScope(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => effectiveNotifier,
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PromptBlockLibraryScreen(),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('card hover 180ms shows pure preview; tap opens detail panel', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('hover', '悬停块', 'hover content')]),
    );

    final card = find.byKey(const ValueKey('prompt-block-card-body-hover'));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(card));
    // 未到 180ms 不出预览
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('prompt-block-preview-overlay')), findsNothing);
    await tester.pump(const Duration(milliseconds: 90));
    expect(
      find.byKey(const Key('prompt-block-preview-overlay')),
      findsOneWidget,
    );
    // 预览四段齐全、无操作按钮
    expect(find.text('悬停块'), findsWidgets);
    expect(find.text('使用 0 次'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('prompt-block-preview-overlay')),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
    );

    // 移开即收
    await gesture.moveTo(const Offset(4, 4));
    await tester.pump();
    expect(find.byKey(const Key('prompt-block-preview-overlay')), findsNothing);

    // 点击开详情面板
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(PromptBlockDetailPanel), findsOneWidget);
    expect(
      find.byKey(const Key('prompt-block-detail-action-edit')),
      findsOneWidget,
    );
    await gesture.removePointer();
  });

  testWidgets('detail tag filters blocks and can be cleared', (tester) async {
    final blue = makeBlock('blue', '冷色块', 'blue').copyWith(
      tags: const [PromptBlockTag(name: '冷色', color: '#FF268BEA')],
    );
    final red = makeBlock('red', '暖色块', 'red');
    await pumpScreen(tester, buildScreen(blocks: [blue, red]));
    await tester.tap(find.byKey(const ValueKey('prompt-block-card-body-blue')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('冷色').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('prompt-block-active-tag-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prompt-block-card-body-blue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prompt-block-card-body-red')),
      findsNothing,
    );
    tester
        .widget<InputChip>(
          find.byKey(const Key('prompt-block-active-tag-filter')),
        )
        .onDeleted!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('prompt-block-card-body-red')),
      findsOneWidget,
    );
  });

  testWidgets('top search finds blocks by tag name', (tester) async {
    final tagged = makeBlock('tagged', '画风块', 'soft light').copyWith(
      tags: const [PromptBlockTag(name: '冷色构图', color: '#FF268BEA')],
    );
    final other = makeBlock('other', '人物块', 'portrait');
    await pumpScreen(tester, buildScreen(blocks: [tagged, other]));

    await tester.enterText(
      find.byKey(const Key('prompt-block-library-search')),
      '冷色',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('prompt-block-card-body-tagged')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prompt-block-card-body-other')),
      findsNothing,
    );
  });

  testWidgets('waterfall view: switch renders masonry, tap opens detail', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [makeBlock('w1', '瀑布块一', 'a'), makeBlock('w2', '瀑布块二', 'b')],
      ),
    );

    // 切到瀑布流（ToggleButtons 第三位）
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('prompt-block-view-mode')),
        matching: find.byIcon(Icons.view_quilt_outlined),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(MasonryGridView), findsOneWidget);
    expect(find.text('瀑布块一'), findsOneWidget);
    expect(find.text('瀑布块二'), findsOneWidget);
    // 无图块 = 老样子长条
    expect(
      find.byKey(const Key('prompt-block-waterfall-plain-w1')),
      findsOneWidget,
    );

    // 点击开详情面板
    await tester.tap(find.byKey(const Key('prompt-block-waterfall-body-w1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(PromptBlockDetailPanel), findsOneWidget);

    // 视图持久化
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(StorageKeys.promptBlockLibraryViewMode),
      'waterfall',
    );
  });

  testWidgets('waterfall view restores from stored preference', (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.promptBlockLibraryViewMode: 'waterfall',
    });
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('w1', '瀑布块', 'a')]),
    );

    expect(find.byType(MasonryGridView), findsOneWidget);
    expect(
      find.byKey(const Key('prompt-block-waterfall-plain-w1')),
      findsOneWidget,
    );
  });

  testWidgets('switching view mode dismisses an open hover preview', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('v1', '切换块', 'a')]),
    );

    // 悬停出预览
    final card = find.byKey(const ValueKey('prompt-block-card-body-v1'));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 900));
    expect(
      find.byKey(const Key('prompt-block-preview-overlay')),
      findsOneWidget,
    );

    // 切视图 → 旧 hover state 销毁，预览随之移除
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('prompt-block-view-mode')),
        matching: find.byIcon(Icons.view_quilt_outlined),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('prompt-block-preview-overlay')), findsNothing);
    expect(find.byType(MasonryGridView), findsOneWidget);
    await gesture.removePointer();
  });

  testWidgets('loads blocks and searches by title or content', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('style', '风格块', 'soft lighting'),
          makeBlock('character', '角色块', 'red eyes'),
        ],
      ),
    );

    expect(find.text('风格块'), findsOneWidget);
    expect(find.text('角色块'), findsOneWidget);

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'lighting');
    await tester.pump();

    expect(find.text('风格块'), findsOneWidget);
    expect(find.text('角色块'), findsNothing);
    expect(find.text('没有匹配的块'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('角色块'), findsOneWidget);
  });

  testWidgets('defaults to grid and switches to list mode', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('first', '第一个', 'one'),
          makeBlock('second', '第二个', 'two'),
        ],
      ),
    );

    expect(find.byKey(const Key('prompt-block-grid')), findsOneWidget);
    expect(find.byKey(const Key('prompt-block-list')), findsNothing);

    await tester.tap(find.byIcon(Icons.view_agenda_outlined));
    await tester.pump();
    expect(find.byKey(const Key('prompt-block-list')), findsOneWidget);
    expect(find.byKey(const Key('prompt-block-grid')), findsNothing);

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pump();
    expect(find.byKey(const Key('prompt-block-grid')), findsOneWidget);
  });

  testWidgets(
    'clicking cards selects blocks and controls the quick settings rail',
    (tester) async {
      final first = makeBlock('first', '第一个', 'one');
      final second = makeBlock('second', '第二个', 'two');
      await pumpScreen(tester, buildScreen(blocks: [first, second]));

      await tester.tap(
        find.byKey(const ValueKey('prompt-block-card-body-first')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(PromptBlockDetailPanel), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const Key('prompt-block-detail-header')))
            .height,
        64,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('prompt-block-detail-header')),
          matching: find.text('详情'),
        ),
        findsOneWidget,
      );
      var panel = tester.widget<PromptBlockDetailPanel>(
        find.byType(PromptBlockDetailPanel),
      );
      expect(panel.block.id, 'first');

      await tester.tap(
        find.byKey(const ValueKey('prompt-block-card-body-second')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      panel = tester.widget<PromptBlockDetailPanel>(
        find.byType(PromptBlockDetailPanel),
      );
      expect(panel.block.id, 'second');

      await tester.tap(find.byKey(const Key('prompt-block-detail-collapse')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const Key('prompt-block-detail-collapsed')),
        findsOneWidget,
      );
      expect(find.byType(PromptBlockDetailPanel), findsNothing);

      await tester.tap(find.byKey(const Key('prompt-block-detail-collapsed')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(PromptBlockDetailPanel), findsOneWidget);
    },
  );

  testWidgets(
    'quick settings rail starts collapsed and expands to empty state without selection',
    (tester) async {
      await pumpScreen(
        tester,
        buildScreen(blocks: [makeBlock('first', '第一个', 'one')]),
      );

      // 初始未选块:右栏常驻为折叠细条。
      expect(find.byKey(const Key('prompt-block-detail-rail')), findsOneWidget);
      expect(
        find.byKey(const Key('prompt-block-detail-collapsed')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const Key('prompt-block-detail-rail'))).width,
        40,
      );

      // 手动点细条展开:显示"未选择块"空状态。
      await tester.tap(find.byKey(const Key('prompt-block-detail-collapsed')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const Key('prompt-block-detail-empty')),
        findsOneWidget,
      );
      expect(find.text('未选择块'), findsOneWidget);
      expect(find.byType(PromptBlockDetailPanel), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('prompt-block-detail-rail'))).width,
        320,
      );
    },
  );

  testWidgets(
    'deleting the selected block keeps the rail expanded with empty state',
    (tester) async {
      await pumpScreen(
        tester,
        buildScreen(blocks: [makeBlock('first', '第一个', 'one')]),
      );

      await tester.tap(
        find.byKey(const ValueKey('prompt-block-card-body-first')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(PromptBlockDetailPanel), findsOneWidget);

      final deleteButton = find.descendant(
        of: find.byType(PromptBlockDetailPanel),
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.ensureVisible(deleteButton);
      await tester.pump();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('prompt-block-detail-rail')), findsOneWidget);
      expect(
        find.byKey(const Key('prompt-block-detail-empty')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const Key('prompt-block-detail-rail'))).width,
        320,
      );
      expect(find.byType(PromptBlockDetailPanel), findsNothing);
      expect(
        find.byKey(const Key('prompt-block-detail-collapsed')),
        findsNothing,
      );

      // 消化删除成功 toast 的自动关闭定时器,避免测试结束时 timersPending。
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('card size slider updates immediately and persists on release', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('slider', '滑块', 'content')]),
    );

    final sliderFinder = find.byKey(const Key('prompt-block-card-size-slider'));
    expect(sliderFinder, findsOneWidget);
    expect(tester.widget<Slider>(sliderFinder).value, 220);

    tester.widget<Slider>(sliderFinder).onChanged?.call(260);
    await tester.pump();
    expect(tester.widget<Slider>(sliderFinder).value, 260);

    tester.widget<Slider>(sliderFinder).onChangeEnd?.call(260);
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(StorageKeys.promptBlockLibraryCardWidth), 260);
  });

  testWidgets('minimum card size uses wrapping pills without card actions', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('pill-one', '第一个 Pill', 'hidden one'),
          makeBlock('pill-two', '第二个 Pill', 'hidden two'),
          makeBlock('pill-three', '第三个 Pill', 'hidden three'),
        ],
      ),
    );

    final sliderFinder = find.byKey(const Key('prompt-block-card-size-slider'));
    final gridStackFinder = find.byKey(const Key('prompt-block-grid-stack'));
    final gridRightInset =
        tester.getBottomRight(gridStackFinder).dx -
        tester.getBottomRight(sliderFinder).dx;
    final gridBottomInset =
        tester.getBottomRight(gridStackFinder).dy -
        tester.getBottomRight(sliderFinder).dy;

    tester.widget<Slider>(sliderFinder).onChanged?.call(100);
    await tester.pump();

    expect(find.byType(PromptBlockCard), findsNothing);
    expect(find.byType(PromptBlockPill), findsNWidgets(3));
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('hidden one'), findsNothing);

    final scrollFinder = find.byKey(const Key('prompt-block-pill-grid-scroll'));
    final pillTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('prompt-block-pill-body-pill-one')),
    );
    final scrollTopLeft = tester.getTopLeft(scrollFinder);
    expect(pillTopLeft.dx, closeTo(scrollTopLeft.dx + 16, 1));
    expect(pillTopLeft.dy, closeTo(scrollTopLeft.dy + 16, 1));

    final pillRightInset =
        tester.getBottomRight(gridStackFinder).dx -
        tester.getBottomRight(sliderFinder).dx;
    final pillBottomInset =
        tester.getBottomRight(gridStackFinder).dy -
        tester.getBottomRight(sliderFinder).dy;
    expect(pillRightInset, closeTo(gridRightInset, 1));
    expect(pillBottomInset, closeTo(gridBottomInset, 1));

    await tester.tap(
      find.byKey(const ValueKey('prompt-block-pill-body-pill-one')),
    );
    await tester.pump();
    expect(find.byType(PromptBlockDetailPanel), findsOneWidget);
  });

  testWidgets('quick settings stays within a narrow layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('narrow', '窄窗口', 'content')]),
    );
    await tester.tap(
      find.byKey(const ValueKey('prompt-block-card-body-narrow')),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(PromptBlockDetailPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing via detail panel dialog saves and keeps the rail', (
    tester,
  ) async {
    final block = makeBlock('edit', '待编辑', 'before');
    final notifier = _FakePromptBlockLibraryNotifier(
      initialState: PromptBlockLibraryState(blocks: [block], folders: const []),
    );

    await pumpScreen(tester, buildScreen(notifier: notifier));
    await tester.tap(find.byKey(const ValueKey('prompt-block-card-body-edit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(PromptBlockDetailPanel), findsOneWidget);

    // 详情面板只读；「编辑」进完整编辑弹窗。
    await tester.ensureVisible(
      find.byKey(const Key('prompt-block-detail-action-edit')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prompt-block-detail-action-edit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PromptBlockEditDialog), findsOneWidget);

    final fields = find.descendant(
      of: find.byType(PromptBlockEditDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, '已编辑');

    // FEAT-79：正文是单文本流原子编辑器——整段换成多行文本，
    // 换行把每行切成原子，末行留原文（保存口径照样取出）。
    await tester.enterText(
      find.byKey(const Key('atom-editor-field')),
      'first line\nsecond line',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 3));

    final saved = notifier.state.valueOrNull?.blockById(block.id);
    expect(saved?.title, '已编辑');
    expect(saved?.atoms, ['first line', 'second line']);
    expect(saved?.content, 'first line, second line');
    expect(find.byType(PromptBlockEditDialog), findsNothing);
    expect(find.byType(PromptBlockDetailPanel), findsOneWidget);
  });

  testWidgets('edit dialog cancel persists nothing', (tester) async {
    final block = makeBlock('cancel-edit', '取消编辑', 'before');
    final notifier = _FakePromptBlockLibraryNotifier(
      initialState: PromptBlockLibraryState(blocks: [block], folders: const []),
    );

    await pumpScreen(tester, buildScreen(notifier: notifier));
    await tester.tap(
      find.byKey(const ValueKey('prompt-block-card-body-cancel-edit')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.ensureVisible(
      find.byKey(const Key('prompt-block-detail-action-edit')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prompt-block-detail-action-edit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final fields = find.descendant(
      of: find.byType(PromptBlockEditDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, '不应保存');
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PromptBlockEditDialog), findsNothing);
    expect(notifier.state.valueOrNull?.blockById(block.id)?.title, '取消编辑');
  });

  testWidgets('wide toolbar uses the shared header height', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('wide', '宽屏', 'content')]),
    );

    expect(
      tester.getSize(find.byKey(const Key('prompt-block-toolbar'))).height,
      64,
    );
  });

  testWidgets('color and icon pickers use compact auto-closing menus', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('picker', '选择器', 'content')]),
    );
    await tester.tap(
      find.byKey(const ValueKey('prompt-block-card-body-picker')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // 选择器收在详情面板的「编辑」弹窗里。
    await tester.ensureVisible(
      find.byKey(const Key('prompt-block-detail-action-edit')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prompt-block-detail-action-edit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final dialog = find.byType(PromptBlockEditDialog);
    expect(dialog, findsOneWidget);

    final colorOption = find.byKey(
      const ValueKey('prompt-block-color-option-#FFE53935'),
    );
    await tester.ensureVisible(
      find.byKey(const Key('prompt-block-color-trigger')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prompt-block-color-trigger')));
    await tester.pump();
    expect(colorOption, findsOneWidget);
    await tester.tap(colorOption);
    await tester.pump();
    expect(colorOption, findsNothing);

    final iconPicker = find.byType(PromptBlockIconPicker);
    final iconOption = find.byKey(
      const ValueKey('prompt-block-icon-option-palette'),
    );
    await tester.ensureVisible(
      find.byKey(const Key('prompt-block-icon-trigger')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prompt-block-icon-trigger')));
    await tester.pump();
    expect(iconOption, findsOneWidget);
    await tester.tap(iconOption);
    await tester.pump();
    expect(iconOption, findsNothing);
    expect(
      tester.widget<PromptBlockIconPicker>(iconPicker).selected,
      'palette',
    );

    await tester.tap(find.byKey(const Key('prompt-block-icon-trigger')));
    await tester.pump();
    await tester.tap(iconOption);
    await tester.pump();
    expect(tester.widget<PromptBlockIconPicker>(iconPicker).selected, isNull);
  });

  testWidgets('empty library shows the create action', (tester) async {
    await pumpScreen(tester, buildScreen());

    expect(find.text('还没有提示词块'), findsOneWidget);
    expect(find.text('新建块'), findsWidgets);
  });

  testWidgets('folder deletion dialog returns the selected mode', (
    tester,
  ) async {
    final folder = PromptBlockFolder.create(name: '旧文件夹');
    Future<PromptBlockFolderDeleteDecision?>? decisionFuture;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  decisionFuture = PromptBlockFolderDeleteDialog.show(
                    context: context,
                    folder: folder,
                    destinationFolders: const [],
                  );
                },
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('删除内容'));
    await tester.tap(find.text('删除').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(await decisionFuture, isNotNull);
    expect(
      (await decisionFuture)?.mode,
      PromptBlockFolderDeleteMode.deleteContents,
    );
  });

  testWidgets('toolbar exposes import and export actions', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('b1', '导入块', '内容')]),
    );

    await tester.tap(find.byIcon(Icons.import_export));
    await tester.pumpAndSettle();

    expect(find.text('导入 TXT 文件'), findsOneWidget);
    expect(find.text('从文件夹导入…'), findsOneWidget);
    expect(find.text('导出库备份…'), findsOneWidget);
    expect(find.text('导入库备份…'), findsOneWidget);

    // 只验证菜单项存在;不选中(会拉起原生文件对话框)。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // 单块分类入口保留在卡片操作栏，库备份导出仍在顶部菜单。
    expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
  });

  PromptBlockFolder makeFolder(
    String id,
    String name, {
    String? parentId,
    int sortOrder = 0,
  }) {
    return PromptBlockFolder.create(
      id: id,
      name: name,
      parentId: parentId,
      sortOrder: sortOrder,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  PromptBlockCollection makeCollection(
    String id,
    String name, {
    String? parentId,
    bool isFolder = false,
    List<String> blockIds = const [],
  }) {
    return PromptBlockCollection.create(
      id: id,
      name: name,
      parentId: parentId,
      isFolder: isFolder,
      blockIds: blockIds,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  PromptBlock blockIn(String id, String title, String? folderId) {
    return PromptBlock.create(
      id: id,
      title: title,
      content: 'c-$id',
      folderId: folderId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  testWidgets('favorites row filters main area to favorite blocks', (
    tester,
  ) async {
    final fav = PromptBlock.create(
      id: 'fav',
      title: '已收藏',
      content: 'c',
      isFavorite: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await pumpScreen(
      tester,
      buildScreen(blocks: [fav, makeBlock('plain', '未收藏', 'c')]),
    );

    await tester.tap(find.text('收藏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('已收藏'), findsWidgets);
    expect(find.text('未收藏'), findsNothing);
  });

  testWidgets('collection row filters main area to member blocks', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('member', '成员块', 'c'),
          makeBlock('other', '路人块', 'c'),
        ],
        collections: [
          makeCollection('col1', '画师集', blockIds: ['member']),
        ],
      ),
    );

    await tester.tap(find.text('画师集'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('成员块'), findsOneWidget);
    expect(find.text('路人块'), findsNothing);
  });

  testWidgets('folder scope groups blocks under sticky folder headers', (
    tester,
  ) async {
    final folders = [
      makeFolder('p', '功能'),
      makeFolder('c', '子层', parentId: 'p'),
    ];
    final blocks = [
      blockIn('b1', '父直块', 'p'),
      blockIn('b2', '子层块', 'c'),
      blockIn('b3', '库外块', null),
    ];
    await pumpScreen(tester, buildScreen(blocks: blocks, folders: folders));

    // 选中父文件夹 → 分段视图
    await tester.tap(find.text('功能'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const Key('prompt-block-grouped-scroll')),
      findsOneWidget,
    );
    // 两个分段标题：选中文件夹自身 + 子层（带路径）
    expect(find.text('功能'), findsWidgets);
    expect(find.text('功能 / 子层'), findsOneWidget);
    expect(find.text('父直块'), findsOneWidget);
    expect(find.text('子层块'), findsOneWidget);
    // 库外（未分类）块不属于该范围
    expect(find.text('库外块'), findsNothing);
  });

  testWidgets('root scope groups unclassified + per-folder sections', (
    tester,
  ) async {
    // 三段全部进视口，否则 sliver 懒构建不生成第三段标题
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final folders = [
      makeFolder('p', '功能'),
      makeFolder('c', '子层', parentId: 'p'),
    ];
    final blocks = [
      blockIn('b1', '父直块', 'p'),
      blockIn('b2', '子层块', 'c'),
      blockIn('b3', '未分类块', null),
    ];
    await pumpScreen(tester, buildScreen(blocks: blocks, folders: folders));

    await tester.tap(find.text('根目录 / 未分类'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const Key('prompt-block-grouped-scroll')),
      findsOneWidget,
    );
    expect(find.text('未分类'), findsWidgets);
    expect(find.text('功能 / 子层'), findsOneWidget);
    expect(find.text('未分类块'), findsOneWidget);
    expect(find.text('子层块'), findsOneWidget);
  });

  testWidgets('waterfall grouped view keeps scroll offset at the end', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.promptBlockLibraryViewMode: 'waterfall',
    });
    final folders = [
      makeFolder('p', '功能'),
      makeFolder('c', '子层', parentId: 'p'),
    ];
    final blocks = [
      for (var i = 0; i < 6; i++) blockIn('p$i', '父直块$i', 'p'),
      for (var i = 0; i < 30; i++) blockIn('c$i', '子层块$i', 'c'),
    ];
    await pumpScreen(tester, buildScreen(blocks: blocks, folders: folders));

    // 选中父文件夹 → 分段瀑布流（功能 + 功能/子层 两段）
    await tester.tap(find.text('功能'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final groupedScroll = find.byKey(const Key('prompt-block-grouped-scroll'));
    // 键打在 CustomScrollView（Stateless）上，ScrollableState 在其内部第一个
    // Scrollable 子孙处；段体内的嵌套滚动组件排在其后。
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(of: groupedScroll, matching: find.byType(Scrollable))
          .first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    // 弹回发生在随后若干帧的 scrollOffsetCorrection，多 pump 几帧放大差异
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      scrollable.position.pixels,
      moreOrLessEquals(scrollable.position.maxScrollExtent, epsilon: 1),
    );
    expect(find.text('功能 / 子层'), findsOneWidget);
  });

  testWidgets('grid grouped view pushes first header out when scrolled', (
    tester,
  ) async {
    final folders = [
      makeFolder('p', '功能'),
      makeFolder('c', '子层', parentId: 'p'),
    ];
    final blocks = [
      for (var i = 0; i < 6; i++) blockIn('p$i', '父直块$i', 'p'),
      for (var i = 0; i < 30; i++) blockIn('c$i', '子层块$i', 'c'),
    ];
    await pumpScreen(tester, buildScreen(blocks: blocks, folders: folders));

    await tester.tap(find.text('功能'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final groupedScroll = find.byKey(const Key('prompt-block-grouped-scroll'));
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(of: groupedScroll, matching: find.byType(Scrollable))
          .first,
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();

    // 首段 pinned 头应被顶出视口（侧栏同名文件夹行需限定在滚动子树内排除）
    expect(
      find.descendant(of: groupedScroll, matching: find.text('功能')),
      findsNothing,
    );
  });

  testWidgets('detail panel expansion keeps the top card anchored', (
    tester,
  ) async {
    final blocks = [for (var i = 0; i < 60; i++) blockIn('b$i', '块$i', null)];
    await pumpScreen(tester, buildScreen(blocks: blocks));

    // 平铺 grid（默认「全部块」范围）滚到中部
    final grid = find.byKey(const Key('prompt-block-grid'));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: grid, matching: find.byType(Scrollable)).first,
    );
    scrollable.position.jumpTo(1200);
    await tester.pump();

    // 视口内最靠上的可见卡（卡片都带 ValueKey('card-<id>')）
    final cardFinder = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('card-'),
    );
    String? anchorKey;
    var anchorDy = double.infinity;
    for (final element in cardFinder.evaluate()) {
      final dy = tester.getTopLeft(find.byKey(element.widget.key!)).dy;
      // 60 = 工具栏以下才算视口内
      if (dy > 60 && dy < anchorDy) {
        anchorDy = dy;
        anchorKey = (element.widget.key! as ValueKey<String>).value;
      }
    }
    expect(anchorKey, isNotNull);

    // 展开详情栏：宽度动画把主区压窄重排，锚卡应被钉回原位置
    await tester.tap(find.byKey(const Key('prompt-block-detail-collapsed')));
    await tester.pumpAndSettle();

    expect(find.text('详情'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(ValueKey(anchorKey!))).dy,
      moreOrLessEquals(anchorDy, epsilon: 40),
    );
  });

  testWidgets('star button on card opens the favorite menu', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [makeBlock('star', '星标块', 'c')],
        collections: [makeCollection('col1', '画师集')],
      ),
    );

    // 卡片操作行 ★ 钮（宽卡才有独立按钮行；侧栏「收藏」行也是星图标，限定在卡片子树内找）
    await tester.tap(
      find.descendant(
        of: find.byType(PromptBlockCard),
        matching: find.byIcon(Icons.star_border),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final menu = find.byKey(const Key('prompt-block-organizer-popover'));
    // 菜单含收藏开关行 + 收藏集勾选行（侧栏同名行需排除）
    expect(
      find.descendant(of: menu, matching: find.text('收藏')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: menu, matching: find.text('画师集')),
      findsOneWidget,
    );

    // 勾选收藏集 → 成员关系落库（fake notifier 同步 state）
    await tester.tap(find.descendant(of: menu, matching: find.text('画师集')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });
}
