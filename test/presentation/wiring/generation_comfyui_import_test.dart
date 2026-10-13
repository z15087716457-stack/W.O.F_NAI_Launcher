import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/prompt/comfyui_import_wrapper.dart';
import 'package:nai_launcher/presentation/widgets/prompt/comfyui_import_dialog.dart';

const source =
    'global scenery, detailed background\n| 1girl, blue hair\n| 1boy, red hair';

Future<void> pumpImport(
  WidgetTester tester,
  TextEditingController controller,
  void Function(String, List<CharacterPrompt>) import, {
  ComfyuiImportBegin? begin,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ComfyuiImportWrapper(
          controller: controller,
          onImport: import,
          beginImport: begin,
          child: TextField(controller: controller),
        ),
      ),
    ),
  );
  controller.text = source;
  await tester.pumpAndSettle();
  expect(find.byType(ComfyuiImportDialog), findsOneWidget);
}

void main() {
  testWidgets('导入确认期间新编辑不被旧 ComfyUI 解析结果覆盖', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final imports = <String>[];
    await pumpImport(tester, controller, (prompt, _) => imports.add(prompt));
    controller.text = 'latest user editing';
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(imports, isEmpty);
    expect(controller.text, 'latest user editing');
  });
  testWidgets('未变化的旧导入路径仍正常提交', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final imports = <String>[];
    await pumpImport(tester, controller, (prompt, _) => imports.add(prompt));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(imports, ['global scenery, detailed background']);
    expect(controller.text, 'global scenery, detailed background');
  });
  testWidgets('编辑目标换成相同文本的新控制器，旧弹窗不能提交', (tester) async {
    final first = TextEditingController();
    final second = TextEditingController(text: source);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var current = first;
    late StateSetter rebuild;
    final imports = <String>[];
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ComfyuiImportWrapper(
                controller: current,
                onImport: (prompt, _) => imports.add(prompt),
                child: TextField(controller: current),
              ),
            ),
          );
        },
      ),
    );
    first.text = source;
    await tester.pumpAndSettle();
    rebuild(() => current = second);
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(imports, isEmpty);
    expect(second.text, source);
  });
  testWidgets('取消导入不提交也不清掉原粘贴内容', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final imports = <String>[];
    await pumpImport(tester, controller, (prompt, _) => imports.add(prompt));
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(imports, isEmpty);
    expect(controller.text, source);
  });
  testWidgets('异步受保护导入在弹窗前捕获状态，包装器不提前写控制器', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final imports = <String>[];
    final gate = Completer<void>();
    var captured = 0;
    var legacyCalls = 0;
    await pumpImport(
      tester,
      controller,
      (_, _) => legacyCalls++,
      begin: () {
        captured++;
        return (prompt, _) async {
          await gate.future;
          imports.add(prompt);
        };
      },
    );
    expect(captured, 1);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(imports, isEmpty);
    expect(controller.text, source);
    gate.complete();
    await tester.pump();
    expect(imports, ['global scenery, detailed background']);
    expect(legacyCalls, 0);
    expect(controller.text, source);
  });
}
