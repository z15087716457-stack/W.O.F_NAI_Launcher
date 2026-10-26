import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_popovers.dart';

import 'agent_test_harness.dart';

void main() {
  group('Ask keyboard', () {
    for (final (key, digit) in [
      (LogicalKeyboardKey.digit1, '1'),
      (LogicalKeyboardKey.digit2, '2'),
      (LogicalKeyboardKey.digit3, '3'),
    ]) {
      testWidgets('digit $digit preserves a focused custom answer', (t) async {
        final rec = await pumpAgent(t, scene: AgentScene.ask);
        final field = find.byKey(const Key('agent-ask-custom-keep'));
        await t.enterText(field, 'Keep my draft');
        await t.pump();
        expect(
          t
              .widget<EditableText>(
                find.descendant(of: field, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        await t.sendKeyEvent(key, character: digit);
        await t.pump();
        expect(t.widget<TextField>(field).controller!.text, 'Keep my draft');
        await t.tap(find.byKey(const Key('agent-ask-submit')));
        final (_, answers) =
            rec.last('answer')! as (String, Map<String, String>);
        expect(answers['keep'], 'Keep my draft');
      });
    }

    for (final modifier in [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.metaLeft,
    ]) {
      testWidgets('${modifier.keyLabel}+digit is not an option shortcut', (
        t,
      ) async {
        final rec = await pumpAgent(t, scene: AgentScene.ask);
        await t.sendKeyDownEvent(modifier);
        try {
          await t.sendKeyEvent(LogicalKeyboardKey.digit1, character: '1');
        } finally {
          await t.sendKeyUpEvent(modifier);
        }
        await t.pump();
        await t.tap(find.byKey(const Key('agent-ask-submit')));
        final (_, answers) =
            rec.last('answer')! as (String, Map<String, String>);
        expect(answers['keep'], AgentFixture.ask.questions.single.prefill);
      });
    }

    testWidgets('plain digit still selects an option in card navigation', (
      t,
    ) async {
      final rec = await pumpAgent(t, scene: AgentScene.ask);
      await t.sendKeyEvent(LogicalKeyboardKey.digit1, character: '1');
      await t.pump();
      await t.tap(find.byKey(const Key('agent-ask-submit')));
      final (_, answers) = rec.last('answer')! as (String, Map<String, String>);
      expect(answers['keep'], AgentFixture.ask.questions.single.options.first);
    });

    testWidgets('out-of-range digit leaves the selected answer unchanged', (
      t,
    ) async {
      final rec = await pumpAgent(t, scene: AgentScene.ask);
      await t.sendKeyEvent(LogicalKeyboardKey.digit9, character: '9');
      await t.pump();
      await t.tap(find.byKey(const Key('agent-ask-submit')));
      final (_, answers) = rec.last('answer')! as (String, Map<String, String>);
      expect(answers['keep'], AgentFixture.ask.questions.single.prefill);
    });
  });

  group('Mention cursor', () {
    Future<TextEditingController> open(WidgetTester t, String text) async {
      await pumpAgent(t, scene: AgentScene.welcome, height: 1200);
      final field = find.byKey(const Key('agent-input'));
      await t.enterText(field, text);
      await t.pump();
      expect(find.byType(AgentMentionPanel), findsOneWidget);
      return t.widget<TextField>(field).controller!;
    }

    for (final marker in ['@', '/']) {
      testWidgets('$marker closes after the caret leaves its trigger', (
        t,
      ) async {
        final text = marker == '@' ? 'hello @' : 'hello\n/';
        final controller = await open(t, text);
        await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await t.pump();
        expect(controller.selection.baseOffset, 5);
        expect(find.byType(AgentMentionPanel), findsNothing);
        await t.sendKeyEvent(LogicalKeyboardKey.enter);
        await t.pump();
        expect(t.takeException(), isNull);
        expect(controller.text, text);
      });

      testWidgets('$marker closes for a non-collapsed selection', (t) async {
        final controller = await open(t, marker);
        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 1,
        );
        await t.pump();
        expect(find.byType(AgentMentionPanel), findsNothing);
      });
    }

    testWidgets('keyboard movement refreshes the current mention query', (
      t,
    ) async {
      final controller = await open(t, '@角色');
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await t.pump();
      expect(
        t.widget<AgentMentionPanel>(find.byType(AgentMentionPanel)).query,
        '角',
      );
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(controller.text, '@角色 1 色');
      expect(t.takeException(), isNull);
    });

    testWidgets('caret movement can reopen an existing mention', (t) async {
      final controller = await open(t, '@');
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await t.pump();
      expect(find.byType(AgentMentionPanel), findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(find.byType(AgentMentionPanel), findsOneWidget);
      expect(controller.text, '@');
    });

    testWidgets('a queued candidate callback cannot use an invalidated range', (
      t,
    ) async {
      final controller = await open(t, 'hello @');
      final pick = t
          .widget<AgentMentionPanel>(find.byType(AgentMentionPanel))
          .onPick;
      controller.selection = const TextSelection.collapsed(offset: 5);
      expect(() => pick('@角色 1 ', null), returnsNormally);
      await t.pump();
      expect(controller.text, 'hello @');
      expect(t.takeException(), isNull);
    });
  });
}
