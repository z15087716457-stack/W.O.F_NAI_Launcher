// Non-prompt text inputs: application-wide undo/redo regressions (Q1–Q7).
import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/widgets/common/text_editing_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_composer.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_inputs.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../ui/blocks/blocks_test_harness.dart' as blocks_harness;
import '../../ui/agent/agent_test_harness.dart' as agent_harness;

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: GeistTheme.light,
  locale: const Locale('zh'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: TextEditingShortcuts(child: c!),
  ),
  home: Scaffold(body: WindowChromeScope(child: child)),
);

Future<void> _ctrlKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String text) async {
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}

Future<void> _flushHistory(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
}

TextEditingController _controller(WidgetTester tester, Key key) {
  final root = find.byKey(key);
  final nested = find.descendant(of: root, matching: find.byType(TextField));
  final finder = nested.evaluate().isEmpty ? root : nested;
  return tester.widget<TextField>(finder).controller!;
}

void main() {
  testWidgets('Q1 基线：ThemedInput 原生输入 Ctrl+Z / Ctrl+Y 可用', (tester) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        const Center(
          child: SizedBox(
            width: 400,
            child: ThemedInput(
              key: Key('probe-themed'),
              maxLines: 3,
              minLines: 3,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('probe-themed')));
    await tester.pump();
    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, solo');
    await _flushHistory(tester);
    final controller = _controller(tester, const Key('probe-themed'));
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('Q1 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    debugPrint('Q1 after Ctrl+Y: ${controller.text}');
    expect(controller.text, '1girl, solo');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('Q2 块编辑：标题（UiTextInput 受控）Ctrl+Z', (tester) async {
    await blocks_harness.pumpBlocks(
      tester,
      Center(
        child: BlockEditDialog(
          data: const BlockEditData(
            blockId: 'fixture',
            draft: BlockDraft(title: 'Fixture', atoms: ['red_hair']),
          ),
          actions: BlockEditActions(
            onSave: (_) {},
            onCancel: () {},
            onPickThumbnail: () async => null,
            onCaptureParams: () async => null,
          ),
        ),
      ),
    );
    final field = find.byKey(const Key('block-edit-title'));
    await tester.tap(field);
    await tester.pump();
    final controller = _controller(tester, const Key('block-edit-title'));
    await _type(tester, 'Style');
    await _flushHistory(tester);
    await _type(tester, 'Style A');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('Q2 after Ctrl+Z: ${controller.text}');
    expect(controller.text, 'Style');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(controller.text, 'Style A');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('Q3 块编辑：正文（TextField）Ctrl+Z', (tester) async {
    await blocks_harness.pumpBlocks(
      tester,
      Center(
        child: BlockEditDialog(
          data: const BlockEditData(
            blockId: 'fixture',
            draft: BlockDraft(title: 'Fixture', atoms: ['red_hair']),
          ),
          actions: BlockEditActions(
            onSave: (_) {},
            onCancel: () {},
            onPickThumbnail: () async => null,
            onCaptureParams: () async => null,
          ),
        ),
      ),
    );
    await blocks_harness.tapKey(tester, 'block-edit-tab-text');
    final field = find.byKey(const Key('block-edit-text'));
    await tester.tap(field);
    await tester.pump();
    final controller = _controller(tester, const Key('block-edit-text'));
    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, solo');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('Q3 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(controller.text, '1girl, solo');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('Q4 块编辑：标签输入（TextField，提交后重建列表）Ctrl+Z', (tester) async {
    await blocks_harness.pumpBlocks(
      tester,
      Center(
        child: BlockEditDialog(
          data: const BlockEditData(
            blockId: 'fixture',
            draft: BlockDraft(title: 'Fixture', atoms: ['red_hair']),
          ),
          actions: BlockEditActions(
            onSave: (_) {},
            onCancel: () {},
            onPickThumbnail: () async => null,
            onCaptureParams: () async => null,
          ),
        ),
      ),
    );
    final field = find.byKey(const Key('block-atom-input'));
    await tester.tap(field);
    await tester.pump();
    final controller = _controller(tester, const Key('block-atom-input'));
    await _type(tester, 'blue');
    await _flushHistory(tester);
    await _type(tester, 'blue_eyes');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('Q4 after Ctrl+Z: ${controller.text}');
    expect(controller.text, 'blue');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(controller.text, 'blue_eyes');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('Q5 Agent composer：普通输入与插入文本（粘贴路径）的 Ctrl+Z', (tester) async {
    await agent_harness.pumpAgent(tester);
    final field = find.byKey(const Key('agent-input'));
    await tester.tap(field);
    await tester.pump();
    final controller = _controller(tester, const Key('agent-input'));
    await _type(tester, 'hello');
    await _flushHistory(tester);
    await _type(tester, 'hello world');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('Q5a after Ctrl+Z: ${controller.text}');
    expect(controller.text, 'hello');

    // 粘贴/插入路径：insert() 是整体替换式写入（R07 落地方法）
    final state = tester.state<AgentComposerState>(find.byType(AgentComposer));
    state.insert('C:/tmp/a.txt');
    await tester.pump();
    await _flushHistory(tester);
    debugPrint('Q5b after insert: ${controller.text}');
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('Q5b after Ctrl+Z: ${controller.text}');
    expect(controller.text, 'hello');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(controller.text, 'helloC:/tmp/a.txt');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('Q7 Ctrl+Y 在各输入框的一致性（非 ThemedInput 字段）', (tester) async {
    await agent_harness.pumpAgent(tester);
    final field = find.byKey(const Key('agent-input'));
    await tester.tap(field);
    await tester.pump();
    final controller = _controller(tester, const Key('agent-input'));
    await _type(tester, 'hello');
    await _flushHistory(tester);
    await _type(tester, 'hello world');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    expect(controller.text, 'hello');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    debugPrint('Q7 agent composer after Ctrl+Y: "${controller.text}"');
    expect(
      controller.text,
      'hello world',
      reason: '非 ThemedInput 的输入框也必须支持 Ctrl+Y 重做',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('settings text field supports undo and both redo shortcuts', (
    tester,
  ) async {
    await _appSettings(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await _type(tester, 'proxy');
    await _flushHistory(tester);
    await _type(tester, 'proxy.local');
    await _flushHistory(tester);
    final controller = controllerOf(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    expect(controller.text, 'proxy');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(controller.text, 'proxy.local');
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(controller.text, 'proxy.local');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('Q6 搜索框（UiSearchField 受控）：外部值改写后 Ctrl+Z', (tester) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var external = '';

    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: SizedBox(
              width: 400,
              child: UiSearchField(
                value: external,
                hint: 'search',
                onChanged: (v) => setState(() => external = v),
              ),
            ),
          ),
        ),
      ),
    );
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    final controller = controllerOf(tester);
    await _type(tester, '1girl');
    await _flushHistory(tester);
    // 父级把受控值改写为别的文本（外部同步）
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: SizedBox(
              width: 400,
              child: UiSearchField(
                value: 'external value',
                hint: 'search',
                onChanged: (v) => setState(() => external = v),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    debugPrint('Q6 after external write: ${controller.text}');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('Q6 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(controller.text, 'external value');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}

Future<void> _appSettings(WidgetTester tester) => tester.pumpWidget(
  _app(
    const Center(
      child: SizedBox(width: 400, child: SettingsInput(value: '')),
    ),
  ),
);

TextEditingController controllerOf(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!;
