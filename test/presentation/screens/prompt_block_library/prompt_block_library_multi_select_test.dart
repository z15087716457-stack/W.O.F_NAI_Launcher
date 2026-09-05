import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/prompt_block_library_screen.dart';

/// 记录批量调用并同步内存状态的 fake notifier（真实 provider 会开 Hive box）。
class _RecordingFakeNotifier extends PromptBlockLibraryNotifier {
  _RecordingFakeNotifier({required this.initialState});

  final PromptBlockLibraryState initialState;
  final deletedBatches = <List<String>>[];
  final movedBatches = <(List<String>, String?)>[];
  final favoriteBatches = <(List<String>, bool)>[];

  @override
  Future<PromptBlockLibraryState> build() async => initialState;

  @override
  Future<void> deleteBlocks(List<String> blockIds) async {
    deletedBatches.add(List.of(blockIds));
    final current = state.valueOrNull ?? initialState;
    final removed = blockIds.toSet();
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: current.blocks
            .where((item) => !removed.contains(item.id))
            .toList(),
        folders: current.folders,
      ),
    );
  }

  @override
  Future<void> moveBlocks(List<String> blockIds, String? folderId) async {
    movedBatches.add((List.of(blockIds), folderId));
    final current = state.valueOrNull ?? initialState;
    final moved = blockIds.toSet();
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: current.blocks
            .map(
              (item) => moved.contains(item.id)
                  ? item.copyWith(folderId: folderId)
                  : item,
            )
            .toList(),
        folders: current.folders,
      ),
    );
  }

  @override
  Future<void> setFavorite(List<String> blockIds, bool favorite) async {
    favoriteBatches.add((List.of(blockIds), favorite));
    final current = state.valueOrNull ?? initialState;
    final changed = blockIds.toSet();
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: current.blocks
            .map(
              (item) => changed.contains(item.id)
                  ? item.copyWith(isFavorite: favorite)
                  : item,
            )
            .toList(),
        folders: current.folders,
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
    _RecordingFakeNotifier? notifier,
  }) {
    final effectiveNotifier =
        notifier ??
        _RecordingFakeNotifier(
          initialState: PromptBlockLibraryState(
            blocks: blocks,
            folders: folders,
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
    // 画布拉高：右键菜单 8 项 + 确认对话框需要纵向空间，600 高默认画布放不下。
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> ctrlTap(WidgetTester tester, Finder finder) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(finder, warnIfMissed: false);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  Future<void> shiftTap(WidgetTester tester, Finder finder) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(finder, warnIfMissed: false);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
  }

  Future<void> rightClick(WidgetTester tester, Finder finder) async {
    final gesture = await tester.startGesture(
      tester.getCenter(finder),
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('ctrl+click enters multi-select and toggles membership', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('a', '块A', 'content a'),
          makeBlock('b', '块B', 'content b'),
        ],
      ),
    );

    expect(
      find.byKey(const Key('prompt-block-multi-select-actions')),
      findsNothing,
    );

    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-a')),
    );
    expect(
      find.byKey(const Key('prompt-block-multi-select-actions')),
      findsOneWidget,
    );
    expect(find.text('已选 1 项'), findsOneWidget);

    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-b')),
    );
    expect(find.text('已选 2 项'), findsOneWidget);

    // 再 Ctrl+点击已选中的块 = 取消选择。
    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-b')),
    );
    expect(find.text('已选 1 项'), findsOneWidget);
  });

  testWidgets('secondary tap on a card opens the context menu', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('a', '块A', 'content a')]),
    );

    await rightClick(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-a')),
    );

    expect(find.text('多选'), findsOneWidget);
    expect(find.text('移动到…'), findsOneWidget);
    expect(find.text('导出为 TXT'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    // 菜单项「多选」进入多选模式并选中该块。
    await tester.tap(find.text('多选'));
    await tester.pump();
    expect(find.text('已选 1 项'), findsOneWidget);
  });

  testWidgets('shift+click extends the selection over visible order', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('a', '块A', 'content a'),
          makeBlock('b', '块B', 'content b'),
          makeBlock('c', '块C', 'content c'),
        ],
      ),
    );

    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-a')),
    );
    expect(find.text('已选 1 项'), findsOneWidget);

    await shiftTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-c')),
    );
    expect(find.text('已选 3 项'), findsOneWidget);
  });

  testWidgets('batch delete asks for confirmation and calls deleteBlocks', (
    tester,
  ) async {
    final notifier = _RecordingFakeNotifier(
      initialState: PromptBlockLibraryState(
        blocks: [
          makeBlock('a', '块A', 'content a'),
          makeBlock('b', '块B', 'content b'),
        ],
        folders: const [],
      ),
    );
    await pumpScreen(tester, buildScreen(notifier: notifier));

    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-a')),
    );
    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-b')),
    );

    await tester.tap(find.byKey(const Key('prompt-block-multi-select-delete')));
    await tester.pumpAndSettle();

    expect(find.text('确定要删除选中的 2 个块吗？此操作无法撤销。'), findsOneWidget);
    expect(notifier.deletedBatches, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    // 推过 toast 的 3 秒自动消失 timer，避免测试结束时 Timer pending。
    await tester.pump(const Duration(seconds: 4));

    expect(notifier.deletedBatches.length, 1);
    expect(notifier.deletedBatches.first.toSet(), {'a', 'b'});
    expect(find.text('块A'), findsNothing);
    expect(find.text('块B'), findsNothing);
    // 删除后仍在多选模式但选择集被清空。
    expect(find.text('已选 0 项'), findsOneWidget);
  });

  testWidgets('batch move from context menu routes through moveBlocks', (
    tester,
  ) async {
    final folder = PromptBlockFolder.create(id: 'f1', name: '目标夹');
    final notifier = _RecordingFakeNotifier(
      initialState: PromptBlockLibraryState(
        blocks: [
          makeBlock('a', '块A', 'content a'),
          makeBlock('b', '块B', 'content b'),
        ],
        folders: [folder],
      ),
    );
    await pumpScreen(tester, buildScreen(notifier: notifier));

    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-a')),
    );
    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-b')),
    );

    // 右键落在选中集合内出批量菜单。
    await rightClick(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-a')),
    );
    expect(find.text('移动 2 个块到…'), findsOneWidget);
    expect(find.text('多选'), findsNothing);

    await tester.tap(find.text('移动 2 个块到…'));
    await tester.pumpAndSettle();

    expect(find.text('移动到文件夹'), findsOneWidget);
    await tester.tap(find.byKey(const Key('prompt-block-move-folder-root')));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    // 推过 toast 的 3 秒自动消失 timer，避免测试结束时 Timer pending。
    await tester.pump(const Duration(seconds: 4));

    expect(notifier.movedBatches.length, 1);
    expect(notifier.movedBatches.first.$1.toSet(), {'a', 'b'});
    expect(notifier.movedBatches.first.$2, isNull);
  });

  testWidgets('multi-select mode disables list reorder handles', (
    tester,
  ) async {
    // 窄画布走紧凑布局也可，这里用默认 800x600：侧栏可见。
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('a', '块A', 'content a'),
          makeBlock('b', '块B', 'content b'),
        ],
      ),
    );

    // 切到具体文件夹（根目录）以满足 reorderable 条件，再切列表视图。
    await tester.tap(find.text('根目录 / 未分类'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.view_agenda_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

    await ctrlTap(tester, find.text('块A'));
    expect(find.byIcon(Icons.drag_handle), findsNothing);

    // 退出多选恢复把手。
    await tester.tap(find.byKey(const Key('prompt-block-multi-select-exit')));
    await tester.pump();
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
  });

  testWidgets('escape exits multi-select mode', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('a', '块A', 'content a')]),
    );

    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-a')),
    );
    expect(
      find.byKey(const Key('prompt-block-multi-select-actions')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(
      find.byKey(const Key('prompt-block-multi-select-actions')),
      findsNothing,
    );
  });

  testWidgets('toolbar multi-select toggle enters the mode with empty set', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('a', '块A', 'content a')]),
    );

    expect(
      find.byKey(const Key('prompt-block-multi-select-actions')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('prompt-block-multi-select-toggle')));
    await tester.pump();

    expect(
      find.byKey(const Key('prompt-block-multi-select-actions')),
      findsOneWidget,
    );
    expect(find.text('已选 0 项'), findsOneWidget);

    // 空选集状态下点击块 = 选择该块。
    await tester.tap(find.byKey(const ValueKey('prompt-block-card-body-a')));
    await tester.pump();
    expect(find.text('已选 1 项'), findsOneWidget);
  });

  testWidgets('quick rail keeps only the collapse button after rework', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('a', '块A', 'content a')]),
    );

    // 展开态编辑面板:close 按钮已移除,collapse 保留。
    await tester.tap(find.byKey(const ValueKey('prompt-block-card-body-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const Key('prompt-block-quick-settings-close')),
      findsNothing,
    );
    final collapse = find.byKey(
      const Key('prompt-block-quick-settings-collapse'),
    );
    expect(collapse, findsOneWidget);

    await tester.tap(collapse);
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const Key('prompt-block-quick-settings-collapsed')),
      findsOneWidget,
    );
  });

  testWidgets('quick rail shows selection count while multi-selecting', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [
          makeBlock('a', '块A', 'content a'),
          makeBlock('b', '块B', 'content b'),
        ],
      ),
    );

    // 先普通点选打开右栏，再 Ctrl+点击进入多选：右栏切「已选 N 项」占位。
    await tester.tap(find.byKey(const ValueKey('prompt-block-card-body-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await ctrlTap(
      tester,
      find.byKey(const ValueKey('prompt-block-card-body-b')),
    );
    expect(find.text('已选 1 项'), findsNWidgets(2));
  });
}
