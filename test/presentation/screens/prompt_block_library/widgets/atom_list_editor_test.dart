import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/atom_list_editor.dart';

void main() {
  // 私用区标记字符（与 kPillMarkerBase 对齐）
  const markerA = '\uE000';
  const markerB = '\uE001';

  Widget wrap(AtomListEditorController controller, {double width = 600}) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: AtomListEditor(controller: controller),
          ),
        ),
      ),
    );
  }

  testWidgets('empty start renders a single text field with no atoms', (
    tester,
  ) async {
    final controller = AtomListEditorController(const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    expect(find.byKey(const Key('atom-editor-field')), findsOneWidget);
    expect(controller.documentText, isEmpty);
    expect(controller.atoms, isEmpty);
  });

  testWidgets('separate wrapped atoms keep space between their frames', (
    tester,
  ) async {
    final controller = AtomListEditorController(const [
      'already dripping wet:',
      'second atom that needs its own line and wraps across this narrow editor',
      'third atom',
    ]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller, width: 320));

    final chips = find.byType(AtomChip);
    expect(chips, findsNWidgets(3));
    for (var i = 1; i < 3; i++) {
      final previousBottom = tester.getBottomLeft(chips.at(i - 1)).dy;
      final nextTop = tester.getTopLeft(chips.at(i)).dy;
      expect(nextTop - previousBottom, greaterThanOrEqualTo(4.5));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter commits text before caret, text after caret stays', (
    tester,
  ) async {
    final controller = AtomListEditorController(const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    await tester.enterText(
      find.byKey(const Key('atom-editor-field')),
      '0.5::artist:a, 1girl::, cinematic and more',
    );
    // 光标放 'cinematic' 之后（offset 33）。
    controller.field.selection = const TextSelection.collapsed(offset: 33);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // 光标前整段成一个原子（逗号/权重段不切），光标后留原文。
    expect(controller.documentText, '$markerA and more');
    expect(controller.atoms, ['0.5::artist:a, 1girl::, cinematic', 'and more']);
  });

  testWidgets('tapping an atom chip restores its text in place', (
    tester,
  ) async {
    final controller = AtomListEditorController(const ['alpha', 'beta']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    expect(controller.documentText, '$markerA $markerB');

    await tester.tap(find.byKey(const Key('atom-editor-atom-57344-0')));
    await tester.pump();

    // 标记原位换回原文；保存口径仍按序取回两个原子。
    expect(controller.documentText, 'alpha $markerB');
    expect(controller.atoms, ['alpha', 'beta']);
  });

  testWidgets('tapping a chip then Enter re-atomizes the restored text', (
    tester,
  ) async {
    final controller = AtomListEditorController(const ['alpha']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    await tester.tap(find.byKey(const Key('atom-editor-atom-57344-0')));
    await tester.pump();
    expect(controller.documentText, 'alpha');

    // 点击 chip 后焦点不在字段：重新聚焦并把光标放文末。
    await tester.tap(find.byKey(const Key('atom-editor-field')));
    controller.field.selection = const TextSelection.collapsed(offset: 5);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // 重新成块：原子原文不变，键位对应新的标记字符。
    expect(controller.documentText, markerA);
    expect(controller.atoms, ['alpha']);
    expect(find.byKey(const Key('atom-editor-atom-57344-0')), findsOneWidget);
  });

  testWidgets('pasted newlines split into atoms; tail stays editable', (
    tester,
  ) async {
    final controller = AtomListEditorController(const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    await tester.enterText(
      find.byKey(const Key('atom-editor-field')),
      'scene one, with commas\n\nscene two\nleft over, tail',
    );
    await tester.pump();

    // 空行丢弃；前两行各成原子，末行留作可编辑原文。
    expect(controller.documentText, '$markerA${markerB}left over, tail');
    expect(controller.atoms, [
      'scene one, with commas',
      'scene two',
      'left over, tail',
    ]);
  });

  testWidgets('save atoms picks up trailing raw text, drops whitespace', (
    tester,
  ) async {
    final controller = AtomListEditorController(const ['first']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    controller.field.value = const TextEditingValue(
      text: '$markerA   \t  ',
      selection: TextSelection.collapsed(offset: 8),
    );
    await tester.pump();

    expect(controller.atoms, ['first']);

    controller.field.value = const TextEditingValue(
      text: '$markerA  second atom, raw  ',
      selection: TextSelection.collapsed(offset: 25),
    );
    await tester.pump();

    expect(controller.atoms, ['first', 'second atom, raw']);
  });

  testWidgets('removing a marker character deletes its atom', (tester) async {
    final controller = AtomListEditorController(const ['a', 'b']);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    // 整段清空等价于选中删除/连按退格：atoms 表同步清空。
    await tester.enterText(find.byKey(const Key('atom-editor-field')), '');
    await tester.pump();

    expect(controller.documentText, isEmpty);
    expect(controller.atomMap, isEmpty);
    expect(controller.atoms, isEmpty);
  });

  testWidgets('orphan marker renders tombstone chip, tap removes it', (
    tester,
  ) async {
    final controller = AtomListEditorController(const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(controller));

    // 外来私用区字符（不在 atoms 表）→ 红色墓碑 chip。
    await tester.enterText(
      find.byKey(const Key('atom-editor-field')),
      'text $markerA more',
    );
    await tester.pump();

    expect(find.byKey(const Key('atom-editor-orphan-0')), findsOneWidget);
    // 孤儿标记在保存口径里也是边界：两侧原文各自收尾成原子。
    expect(controller.atoms, ['text', 'more']);

    await tester.tap(find.byKey(const Key('atom-editor-orphan-0')));
    await tester.pump();

    expect(controller.documentText, 'text  more');
    expect(find.byKey(const Key('atom-editor-orphan-0')), findsNothing);
  });
}
