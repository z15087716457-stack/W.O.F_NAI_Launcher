import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_composer.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'agent_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'suggestions use the native input hint and share the caret and body baseline',
    (t) async {
      final d = AgentFixture.view(AgentScene.shelf);
      AgentViewData view(String? suggestion) => AgentViewData(
        now: d.now,
        workspace: d.workspace,
        chat: d.chat,
        workspaces: d.workspaces,
        chats: d.chats,
        composer: AgentComposerData(text: '', suggestion: suggestion),
        thread: d.thread,
        shelf: d.shelf,
        usage: d.usage,
        models: d.models,
        thinking: d.thinking,
        permission: d.permission,
        mentions: d.mentions,
        skills: d.skills,
      );
      debugDisableShadows = false;
      try {
        await pumpAgent(t, data: view(null), dark: true);
        final input = find.byKey(const Key('agent-input'));
        final emptySize = t.getSize(find.byType(AgentComposer));
        final editor = t.state(find.byType(EditableText));
        final placeholder = t.widget<TextField>(input).decoration!.hintText;
        for (final sample in [
          (420.0, true, '现在把 V5 那份也精简到和别的模型一样短'),
          (
            340.0,
            false,
            'Compare these two images and keep the lighting and composition '
                'of the first one, with the character design from the second.',
          ),
        ]) {
          await pumpAgent(
            t,
            data: view(sample.$3),
            width: sample.$1,
            dark: sample.$2,
          );
          await t.pumpAndSettle();
          await t.tap(input);
          await t.pumpAndSettle();
          final field = t.widget<TextField>(input);
          final text = t.widget<Text>(find.text(sample.$3));
          final paragraph = t.renderObject<RenderParagraph>(
            find.text(sample.$3),
          );
          final editable = t
              .state<EditableTextState>(find.byType(EditableText))
              .renderEditable;
          final hintBox = paragraph
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .first;
          final hintOrigin =
              paragraph.localToGlobal(Offset(hintBox.left, hintBox.top)) -
              t.getTopLeft(input);
          final cursorOrigin =
              editable.localToGlobal(
                editable
                    .getLocalRectForCaret(const TextPosition(offset: 0))
                    .topLeft,
              ) -
              t.getTopLeft(input);
          expect(field.decoration!.hintText, sample.$3);
          expect(field.controller!.text, isEmpty);
          expect(t.state(find.byType(EditableText)), same(editor));
          expect(find.byKey(const Key('agent-suggestion')), findsNothing);
          expect(
            find.descendant(of: input, matching: find.text('Tab')),
            findsOneWidget,
          );
          expect(text.style!.fontSize, field.style!.fontSize);
          expect(text.style!.height, field.style!.height);
          expect(
            t.getRect(find.text(sample.$3)).left,
            closeTo(editable.localToGlobal(Offset.zero).dx, 0.1),
          );
          if (sample.$1 == 420) {
            expect(t.getSize(find.byType(AgentComposer)), emptySize);
          } else {
            expect(
              t.getSize(find.text(sample.$3)).height,
              greaterThan(2 * 13.5 * 1.6),
            );
          }
          await captureUiuxRegion(
            t,
            find.byKey(const Key('agent-capture')),
            'native-suggestion-${sample.$1.toInt()}',
            t.getRect(find.byType(AgentComposer)),
          );
          await t.enterText(input, sample.$3);
          await t.pumpAndSettle();
          final body = t
              .state<EditableTextState>(find.byType(EditableText))
              .renderEditable;
          final bodyBox = body
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .first;
          final bodyOrigin =
              body.localToGlobal(Offset(bodyBox.left, bodyBox.top)) -
              t.getTopLeft(input);
          final bodyCursor =
              body.localToGlobal(
                body
                    .getLocalRectForCaret(const TextPosition(offset: 0))
                    .topLeft,
              ) -
              t.getTopLeft(input);
          expect(bodyOrigin.dx, closeTo(hintOrigin.dx, 0.1));
          expect(bodyOrigin.dy, closeTo(hintOrigin.dy, 0.1));
          expect(bodyCursor.dy, closeTo(cursorOrigin.dy, 0.1));
          expect(
            find.descendant(of: input, matching: find.text('Tab')),
            findsNothing,
          );
          await captureUiuxRegion(
            t,
            find.byKey(const Key('agent-capture')),
            'native-body-${sample.$1.toInt()}',
            t.getRect(find.byType(AgentComposer)),
          );
          await t.enterText(input, '');
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
        await t.enterText(input, '正在输入');
        await t.pump();
        expect(find.byKey(const Key('agent-suggestion')), findsNothing);
        expect(t.widget<TextField>(input).decoration!.hintText, placeholder);
        expect(t.state(find.byType(EditableText)), same(editor));
      } finally {
        debugDisableShadows = true;
      }
    },
  );

  testWidgets('composer attachments open the existing zoom viewer', (t) async {
    final d = AgentFixture.view(AgentScene.compose);
    await pumpAgent(
      t,
      data: AgentViewData(
        now: d.now,
        workspace: d.workspace,
        chat: d.chat,
        workspaces: d.workspaces,
        chats: d.chats,
        composer: AgentComposerData(
          text: d.composer.text,
          attachments: [
            AgentAttachment(
              id: 'a1',
              name: 'test.png',
              image: AgentFixture.img('test').image,
            ),
          ],
        ),
        thread: d.thread,
        shelf: d.shelf,
        usage: d.usage,
        models: d.models,
        thinking: d.thinking,
        permission: d.permission,
        mentions: d.mentions,
        skills: d.skills,
      ),
    );
    final attachment = find.byKey(const Key('agent-attachment-a1'));
    expect(attachment, findsOneWidget);
    await captureUiuxRegion(
      t,
      find.byKey(const Key('agent-capture')),
      'composer-attachments',
      const Rect.fromLTWH(0, 0, 420, 900),
    );
    await t.tap(attachment);
    await t.pump();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(const Key('agent-input')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('native drop slot and highlight cover only the composer', (
    t,
  ) async {
    void Function(bool)? hover;
    await pumpAgent(
      t,
      slots: AgentSlots(
        dropTarget: (_, changed, child) {
          hover = changed;
          return Container(key: const Key('drop-boundary'), child: child);
        },
      ),
    );
    final rect = t.getRect(find.byKey(const Key('drop-boundary')));
    expect(rect, t.getRect(find.byType(AgentComposer)));
    expect(rect.height, lessThan(300));
    hover!(true);
    await t.pump();
    expect(t.getRect(find.byKey(const Key('drop-boundary'))), rect);
    await captureUiuxRegion(
      t,
      find.byKey(const Key('agent-capture')),
      'composer-drop',
      const Rect.fromLTWH(0, 0, 420, 900),
    );
    expect(t.takeException(), isNull);
  });
}
