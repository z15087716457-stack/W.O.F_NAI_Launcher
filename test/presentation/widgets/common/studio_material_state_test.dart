import 'package:flutter/material.dart' as fw;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart'
    as studio;
import 'package:nai_launcher/presentation/widgets/common/workspace_typography_scope.dart';

void main() {
  testWidgets('workspace theme changes preserve input focus and composing', (
    tester,
  ) async {
    final controller = fw.TextEditingController(text: '画风');
    final focus = fw.FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    fw.Widget app(bool dark) => fw.MaterialApp(
      theme: dark ? fw.ThemeData.dark() : fw.ThemeData.light(),
      home: fw.Scaffold(
        body: WorkspaceTypographyScope(
          child: studio.TextField(controller: controller, focusNode: focus),
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    await tester.tap(find.byType(fw.EditableText));
    await tester.pump();
    const value = TextEditingValue(
      text: '画风探索',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 2, end: 4),
    );
    tester.testTextInput.updateEditingValue(value);
    await tester.pump();
    final before = tester.state(find.byType(fw.EditableText));
    await tester.pumpWidget(app(true));
    await tester.pumpWidget(app(false));
    expect(tester.state(find.byType(fw.EditableText)), same(before));
    expect(focus.hasFocus, isTrue);
    expect(controller.value, value);
  });

  testWidgets('form facade preserves validation save and reset', (
    tester,
  ) async {
    final form = fw.GlobalKey<fw.FormState>();
    String? saved;
    await tester.pumpWidget(
      fw.MaterialApp(
        home: fw.Scaffold(
          body: WorkspaceTypographyScope(
            child: fw.Form(
              key: form,
              child: studio.TextFormField(
                initialValue: '初始值',
                validator: (text) => text!.isEmpty ? '不能为空' : null,
                onSaved: (text) => saved = text,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(fw.EditableText), '');
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('不能为空'), findsOneWidget);
    await tester.enterText(find.byType(fw.EditableText), '新值');
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    expect(saved, '新值');
    form.currentState!.reset();
    await tester.pump();
    expect(
      tester
          .widget<fw.EditableText>(find.byType(fw.EditableText))
          .controller
          .text,
      '初始值',
    );
  });
}
