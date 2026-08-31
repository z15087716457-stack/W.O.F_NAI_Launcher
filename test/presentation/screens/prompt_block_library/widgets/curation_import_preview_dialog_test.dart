import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_block_exchange.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/curation_import_preview_dialog.dart';

PromptBlockExchangeItem itemOf(
  String path,
  String content,
  PromptBlockExchangeAction action, {
  PromptBlock? existing,
  bool localModified = false,
}) {
  return PromptBlockExchangeItem(
    file: PromptBlockExchangeFile(path: path, content: content),
    action: action,
    folderChain: const ['策展'],
    existingBlock: existing,
    localModified: localModified,
  );
}

/// 打开对话框;关闭时对话框返回值被追加进 [sink]。
Future<void> pumpDialog(
  WidgetTester tester,
  PromptBlockExchangePlan plan,
  List<CurationImportDecision?> sink,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Center(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final decision = await CurationImportPreviewDialog.show(
                context: context,
                rootPath: r'D:\策展正本',
                plan: plan,
              );
              sink.add(decision);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows three-way summary and returns decision only after explicit '
    'confirmation',
    (tester) async {
      final plan = PromptBlockExchangePlan(
        items: [
          itemOf(r'D:\a.txt', 'a', PromptBlockExchangeAction.create),
          itemOf(
            r'D:\b.txt',
            'b',
            PromptBlockExchangeAction.skipUnchanged,
            existing: PromptBlock.create(id: 'b', title: 'b', content: 'b'),
          ),
          itemOf(
            r'D:\c.txt',
            'c2',
            PromptBlockExchangeAction.update,
            existing: PromptBlock.create(id: 'c', title: 'c', content: 'c1'),
            localModified: true,
          ),
        ],
      );
      final sink = <CurationImportDecision?>[];
      await pumpDialog(tester, plan, sink);

      expect(find.text('从文件夹导入'), findsOneWidget);
      expect(
        find.textContaining('共 3 个 TXT：新增 1 · 未变更 1 · 已变更 1'),
        findsOneWidget,
      );
      expect(find.text('新增'), findsWidgets);
      expect(find.text('未变更'), findsOneWidget);
      expect(find.text('本地已修改'), findsOneWidget);
      expect(find.textContaining('手动修改过'), findsOneWidget);

      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsOneWidget);
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(sink, hasLength(1));
      expect(sink.single!.updateChanged, isTrue);
    },
  );

  testWidgets('hides update switch when nothing changed', (tester) async {
    final plan = PromptBlockExchangePlan(
      items: [
        itemOf(r'D:\a.txt', 'a', PromptBlockExchangeAction.create),
        itemOf(
          r'D:\b.txt',
          'b',
          PromptBlockExchangeAction.skipUnchanged,
          existing: PromptBlock.create(id: 'b', title: 'b', content: 'b'),
        ),
      ],
    );
    final sink = <CurationImportDecision?>[];
    await pumpDialog(tester, plan, sink);

    expect(find.byType(SwitchListTile), findsNothing);

    await tester.tap(find.text('导入'));
    await tester.pumpAndSettle();
    expect(sink, hasLength(1));
    expect(sink.single!.updateChanged, isFalse);
  });
}
