import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/atom_list_editor.dart';

void main() {
  Widget wrap(AtomListEditorController controller) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: AtomListEditor(controller: controller)),
      ),
    );
  }

  testWidgets('empty start shows a single trailing input row', (tester) async {
    final controller = AtomListEditorController(const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const Key('atom-editor-raw-0')), findsOneWidget);
    expect(find.byKey(const Key('atom-editor-atom-0')), findsNothing);
  });

  testWidgets('Enter commits the whole raw segment into one atom row', (
    tester,
  ) async {
    final controller = AtomListEditorController(const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    await tester.enterText(
      find.byKey(const Key('atom-editor-raw-0')),
      '0.5::artist:a, 1girl::, cinematic',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // 整段成一个原子（逗号/权重段不切），尾部自动补新输入行。
    expect(find.byKey(const Key('atom-editor-atom-0')), findsOneWidget);
    expect(controller.segmentTexts, [
      '0.5::artist:a, 1girl::, cinematic',
      '',
    ]);
    // 回车不得落成换行——新输入行仍为空。
    expect(find.byKey(const Key('atom-editor-raw-1')), findsOneWidget);
    expect(controller.atoms, ['0.5::artist:a, 1girl::, cinematic']);
  });

  testWidgets('tapping an atom restores it as editable text in place', (
    tester,
  ) async {
    final controller = AtomListEditorController(const ['alpha', 'beta']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    expect(controller.segmentTexts, ['alpha', 'beta', '']);

    await tester.tap(find.byKey(const Key('atom-editor-atom-0')));
    await tester.pump();

    // 原位还原成文本行，顺序不变。
    expect(controller.segmentTexts, ['alpha', 'beta', '']);
    expect(find.byKey(const Key('atom-editor-raw-0')), findsOneWidget);
    expect(find.byKey(const Key('atom-editor-atom-0')), findsNothing);

    // 再敲回车还原回原子。
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.segmentTexts, ['alpha', 'beta', '']);
    expect(find.byKey(const Key('atom-editor-atom-0')), findsOneWidget);
  });

  testWidgets('pasted newlines split into atoms; tail stays editable', (
    tester,
  ) async {
    final controller = AtomListEditorController(const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    await tester.enterText(
      find.byKey(const Key('atom-editor-raw-0')),
      'scene one, with commas\nscene two\nleft over, tail',
    );
    await tester.pump();

    // 前两行各成一个原子，末行留作文本行继续输入。
    expect(controller.segmentTexts, [
      'scene one, with commas',
      'scene two',
      'left over, tail',
    ]);
    expect(find.byKey(const Key('atom-editor-atom-0')), findsOneWidget);
    expect(find.byKey(const Key('atom-editor-atom-1')), findsOneWidget);
    expect(find.byKey(const Key('atom-editor-raw-2')), findsOneWidget);
  });

  testWidgets('save atoms commits leftover raw rows in order, drops blanks', (
    tester,
  ) async {
    final controller = AtomListEditorController(const ['first']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    // 解开中间原子再在它后面留一段未提交文本。
    await tester.tap(find.byKey(const Key('atom-editor-atom-0')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('atom-editor-raw-1')),
      '  second atom, raw  ',
    );
    await tester.pump();

    expect(controller.atoms, ['first', 'second atom, raw']);
  });

  testWidgets('Enter on an empty middle raw row removes it', (tester) async {
    final controller = AtomListEditorController(const ['a', 'b']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    // 解开第二个原子 → 清空 → 回车 = 删除该行（原子也随之移除）。
    await tester.tap(find.byKey(const Key('atom-editor-atom-1')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('atom-editor-raw-1')), '');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.segmentTexts, ['a', '']);
    expect(controller.atoms, ['a']);
  });
}
