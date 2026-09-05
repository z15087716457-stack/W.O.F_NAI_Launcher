import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/prompt_block_library_screen.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_card.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_folder_delete_dialog.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_quick_settings_panel.dart';
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
      PromptBlockLibraryState(blocks: updatedBlocks, folders: current.folders),
    );
    return block;
  }

  @override
  Future<void> deleteBlock(String blockId) async {
    final current = state.valueOrNull ?? initialState;
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: current.blocks.where((item) => item.id != blockId).toList(),
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
    _FakePromptBlockLibraryNotifier? notifier,
  }) {
    final effectiveNotifier =
        notifier ??
        _FakePromptBlockLibraryNotifier(
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
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

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
      expect(find.byType(PromptBlockQuickSettingsPanel), findsOneWidget);
      expect(
        tester
            .getSize(
              find.byKey(const Key('prompt-block-quick-settings-header')),
            )
            .height,
        64,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('prompt-block-quick-settings-header')),
          matching: find.text('编辑'),
        ),
        findsOneWidget,
      );
      var panel = tester.widget<PromptBlockQuickSettingsPanel>(
        find.byType(PromptBlockQuickSettingsPanel),
      );
      expect(panel.block.id, 'first');

      await tester.tap(
        find.byKey(const ValueKey('prompt-block-card-body-second')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      panel = tester.widget<PromptBlockQuickSettingsPanel>(
        find.byType(PromptBlockQuickSettingsPanel),
      );
      expect(panel.block.id, 'second');

      await tester.tap(
        find.byKey(const Key('prompt-block-quick-settings-collapse')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const Key('prompt-block-quick-settings-collapsed')),
        findsOneWidget,
      );
      expect(find.byType(PromptBlockQuickSettingsPanel), findsNothing);

      await tester.tap(
        find.byKey(const Key('prompt-block-quick-settings-collapsed')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(PromptBlockQuickSettingsPanel), findsOneWidget);
    },
  );

  testWidgets('quick settings rail starts collapsed and expands to empty state without selection', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(blocks: [makeBlock('first', '第一个', 'one')]),
    );

    // 初始未选块:右栏常驻为折叠细条。
    expect(
      find.byKey(const Key('prompt-block-quick-settings-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prompt-block-quick-settings-collapsed')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('prompt-block-quick-settings-rail')))
          .width,
      40,
    );

    // 手动点细条展开:显示"未选择块"空状态。
    await tester.tap(
      find.byKey(const Key('prompt-block-quick-settings-collapsed')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const Key('prompt-block-quick-settings-empty')),
      findsOneWidget,
    );
    expect(find.text('未选择块'), findsOneWidget);
    expect(find.byType(PromptBlockQuickSettingsPanel), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('prompt-block-quick-settings-rail')))
          .width,
      320,
    );
  });

  testWidgets('deleting the selected block keeps the rail expanded with empty state', (tester) async {
    await pumpScreen(
      tester,
      buildScreen(
        blocks: [makeBlock('first', '第一个', 'one')],
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('prompt-block-card-body-first')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(PromptBlockQuickSettingsPanel), findsOneWidget);

    final deleteButton = find.descendant(
      of: find.byType(PromptBlockQuickSettingsPanel),
      matching: find.byIcon(Icons.delete_outline),
    );
    await tester.ensureVisible(deleteButton);
    await tester.pump();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const Key('prompt-block-quick-settings-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prompt-block-quick-settings-empty')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('prompt-block-quick-settings-rail')))
          .width,
      320,
    );
    expect(find.byType(PromptBlockQuickSettingsPanel), findsNothing);
    expect(
      find.byKey(const Key('prompt-block-quick-settings-collapsed')),
      findsNothing,
    );

    // 消化删除成功 toast 的自动关闭定时器,避免测试结束时 timersPending。
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

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
    expect(find.byType(PromptBlockQuickSettingsPanel), findsOneWidget);
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

    expect(find.byType(PromptBlockQuickSettingsPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct editing saves and keeps the block in the quick rail', (
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

    final titleField = find.descendant(
      of: find.byKey(const Key('prompt-block-quick-title')),
      matching: find.byType(TextField),
    );
    final contentField = find.descendant(
      of: find.byKey(const Key('prompt-block-quick-content')),
      matching: find.byType(TextField),
    );
    expect(titleField, findsOneWidget);
    expect(contentField, findsOneWidget);

    await tester.enterText(titleField, '已编辑');
    await tester.enterText(contentField, '  first line\nsecond line  ');
    await tester.tap(find.byKey(const Key('prompt-block-quick-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));

    final saved = notifier.state.valueOrNull?.blockById(block.id);
    expect(saved?.title, '已编辑');
    expect(saved?.content, '  first line\nsecond line  ');
    expect(find.byType(PromptBlockQuickSettingsPanel), findsOneWidget);
    expect(tester.widget<TextField>(titleField).controller?.text, '已编辑');
  });

  testWidgets(
    'content expand editor saves or cancels without early persistence',
    (tester) async {
      final block = makeBlock('content-dialog', '正文编辑', 'before');
      final notifier = _FakePromptBlockLibraryNotifier(
        initialState: PromptBlockLibraryState(
          blocks: [block],
          folders: const [],
        ),
      );

      await pumpScreen(tester, buildScreen(notifier: notifier));
      await tester.tap(
        find.byKey(const ValueKey('prompt-block-card-body-content-dialog')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final contentField = find.descendant(
        of: find.byKey(const Key('prompt-block-quick-content')),
        matching: find.byType(TextField),
      );
      final expandButton = find.byKey(
        const Key('prompt-block-quick-content-expand'),
      );
      await tester.ensureVisible(expandButton);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      final dialog = find.byKey(const Key('prompt-block-quick-content-dialog'));
      final dialogField = find.byKey(
        const Key('prompt-block-quick-content-dialog-field'),
      );
      expect(dialog, findsOneWidget);
      expect(dialogField, findsOneWidget);
      await tester.enterText(
        find.descendant(of: dialogField, matching: find.byType(TextField)),
        '  cancelled line\nkeep original  ',
      );
      await tester.tap(
        find.byKey(const Key('prompt-block-quick-content-dialog-cancel')),
      );
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(tester.widget<TextField>(contentField).controller?.text, 'before');
      expect(
        notifier.state.valueOrNull?.blockById(block.id)?.content,
        'before',
      );

      await tester.ensureVisible(expandButton);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: dialogField, matching: find.byType(TextField)),
        '  expanded line\nkeep spaces  ',
      );
      await tester.tap(
        find.byKey(const Key('prompt-block-quick-content-dialog-save')),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(contentField).controller?.text,
        '  expanded line\nkeep spaces  ',
      );
      expect(
        notifier.state.valueOrNull?.blockById(block.id)?.content,
        'before',
      );

      await tester.tap(find.byKey(const Key('prompt-block-quick-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 3));
      expect(
        notifier.state.valueOrNull?.blockById(block.id)?.content,
        '  expanded line\nkeep spaces  ',
      );
    },
  );

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

    // 单块导出按钮随列表项渲染(点击会拉起原生保存对话框,测试只验存在)。
    expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
  });
}
