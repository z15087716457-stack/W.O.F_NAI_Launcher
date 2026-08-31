import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/prompt_block_library_screen.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_folder_delete_dialog.dart';

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
}

void main() {
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

  testWidgets('editing a block preserves content whitespace', (tester) async {
    final block = makeBlock('edit', '待编辑', 'before');
    final notifier = _FakePromptBlockLibraryNotifier(
      initialState: PromptBlockLibraryState(blocks: [block], folders: const []),
    );

    await pumpScreen(tester, buildScreen(notifier: notifier));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(2), '  first line\nsecond line  ');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));

    expect(
      notifier.state.valueOrNull?.blockById(block.id)?.content,
      '  first line\nsecond line  ',
    );
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
