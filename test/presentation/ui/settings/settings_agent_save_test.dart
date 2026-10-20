import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  SettingsHostState host(WidgetTester t) =>
      t.state<SettingsHostState>(find.byType(SettingsHost));

  Future<SettingsRecorder> agent(WidgetTester t, {String locale = 'zh'}) {
    final data = SettingsFixture.view(page: SettingsPageId.agent);
    return pumpSettings(
      t,
      window: 900,
      locale: locale,
      agentTab: 'instructions',
      data: data.copyWith(
        agent: data.agent.copyWith(systemPrompt: SettingsFixture.systemPrompt),
      ),
    );
  }

  Future<void> edit(WidgetTester t, String key, String text) async {
    final field = find.byKey(Key(key));
    await t.ensureVisible(field);
    await t.enterText(field, text);
    await t.pumpAndSettle();
  }

  String text(WidgetTester t, String key) => t
      .widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  Future<void> tap(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  Future<void> save(WidgetTester t) async {
    final dock = find.byKey(const Key('agent-unsaved'));
    final l = AppLocalizations.of(t.element(dock))!;
    await tap(t, find.descendant(of: dock, matching: find.text(l.set_save)));
  }

  Future<void> refresh(WidgetTester t) async {
    final h = host(t);
    h.updateData(h.data.copyWith());
    await t.pumpAndSettle();
  }

  Future<void> editBase(WidgetTester t, String value) async {
    await tap(t, find.byKey(const Key('agent-base-toggle')));
    await edit(t, 'agent-base-text', value);
  }

  testWidgets(
    'pending write retains both drafts, leave guard and single submission',
    (t) async {
      final rec = await agent(t);
      final pending = Completer<bool>();
      rec.saveInstructions = ({required global, required prefix}) =>
          pending.future;
      await edit(t, 'agent-global', 'draft global');
      await edit(t, 'agent-prefix', 'draft prefix');
      await save(t);
      await refresh(t);
      expect(text(t, 'agent-global'), 'draft global');
      expect(text(t, 'agent-prefix'), 'draft prefix');
      expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
      expect(find.text('正在保存指令…'), findsOneWidget);

      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyS);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      expect(
        rec.calls.where((x) => x.startsWith('saveInstructions:')),
        hasLength(1),
      );
      await tap(t, find.byKey(const Key('settings-nav-network')));
      expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
      expect(rec.pages, isEmpty);
      await tap(t, find.byKey(const Key('confirm-cancel')));

      pending.complete(false);
      await t.pumpAndSettle();
      expect(text(t, 'agent-global'), 'draft global');
      expect(text(t, 'agent-prefix'), 'draft prefix');
      expect(find.textContaining('指令未保存：'), findsOneWidget);
      expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
    },
  );

  for (final throws in [false, true]) {
    testWidgets(
      'failed write (${throws ? 'exception' : 'false'}) retains retryable draft',
      (t) async {
        final rec = await agent(t);
        rec.saveInstructions = ({required global, required prefix}) async {
          if (throws) throw StateError('isolated disk failure');
          return false;
        };
        await edit(t, 'agent-global', 'retry global');
        await edit(t, 'agent-prefix', 'retry prefix');
        await save(t);
        await refresh(t);
        expect(text(t, 'agent-global'), 'retry global');
        expect(text(t, 'agent-prefix'), 'retry prefix');
        expect(find.textContaining('指令未保存：'), findsOneWidget);
        expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
        rec.saveInstructions = ({required global, required prefix}) async =>
            true;
        await save(t);
        await refresh(t); // Acknowledgement may precede provider publication.
        expect(find.byKey(const Key('agent-unsaved')), findsNothing);
        expect(text(t, 'agent-global'), 'retry global');
        expect(text(t, 'agent-prefix'), 'retry prefix');
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'new edits during a successful save remain dirty and are the next submission',
    (t) async {
      final rec = await agent(t);
      final pending = Completer<bool>();
      final submissions = <(String, String)>[];
      rec.saveInstructions = ({required global, required prefix}) {
        submissions.add((global, prefix));
        return pending.future;
      };
      await edit(t, 'agent-global', 'submitted global');
      await edit(t, 'agent-prefix', 'submitted prefix');
      await save(t);
      await edit(t, 'agent-global', 'newer global');
      await edit(t, 'agent-prefix', 'newer prefix');
      final h = host(t);
      h.updateData(
        h.data.copyWith(
          agent: h.data.agent.copyWith(
            globalInstructions: 'submitted global',
            systemPrefix: 'submitted prefix',
          ),
        ),
      );
      await t.pumpAndSettle();
      pending.complete(true);
      await t.pumpAndSettle();
      expect(text(t, 'agent-global'), 'newer global');
      expect(text(t, 'agent-prefix'), 'newer prefix');
      expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
      rec.saveInstructions = ({required global, required prefix}) async {
        submissions.add((global, prefix));
        return true;
      };
      await save(t);
      await refresh(t);
      expect(submissions, [
        ('submitted global', 'submitted prefix'),
        ('newer global', 'newer prefix'),
      ]);
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
      expect(text(t, 'agent-global'), 'newer global');
      expect(text(t, 'agent-prefix'), 'newer prefix');
    },
  );

  for (final instructionsOk in [true, false]) {
    testWidgets(
      'partial save (instructions=$instructionsOk) retries only the failed layer',
      (t) async {
        final rec = await agent(t);
        rec.saveInstructions = ({required global, required prefix}) async =>
            instructionsOk;
        rec.promptResult = !instructionsOk;
        await edit(t, 'agent-global', 'independent global');
        await editBase(t, 'independent base');
        await save(t);
        expect(rec.calls, [
          'saveInstructions:independent global',
          'savePrompt:global:independent base:inspire',
        ]);
        expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
        await refresh(t);
        expect(text(t, 'agent-global'), 'independent global');
        expect(text(t, 'agent-base-text'), 'independent base');
        rec.calls.clear();
        rec.saveInstructions = ({required global, required prefix}) async =>
            true;
        rec.promptResult = true;
        await save(t);
        expect(
          rec.calls,
          instructionsOk
              ? ['savePrompt:global:independent base:inspire']
              : ['saveInstructions:independent global'],
        );
        await refresh(t);
        expect(find.byKey(const Key('agent-unsaved')), findsNothing);
        expect(text(t, 'agent-global'), 'independent global');
        expect(text(t, 'agent-base-text'), 'independent base');
      },
    );
  }

  testWidgets(
    'base write exception leaves draft retryable instead of staying busy',
    (t) async {
      final rec = await agent(t);
      rec.saveSystemPrompt =
          ({required scope, required text, required workspaceId}) async {
            throw StateError('isolated base write failure');
          };
      await editBase(t, 'base retry');
      await save(t);
      await refresh(t);
      expect(text(t, 'agent-base-text'), 'base retry');
      expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
      rec.saveSystemPrompt = null;
      await save(t);
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('confirmed navigation while saving tolerates late completion', (
    t,
  ) async {
    final rec = await agent(t);
    final pending = Completer<bool>();
    rec.saveInstructions = ({required global, required prefix}) =>
        pending.future;
    await edit(t, 'agent-global', 'leaving draft');
    await save(t);
    await tap(t, find.byKey(const Key('settings-nav-network')));
    await tap(t, find.byKey(const Key('confirm-ok')));
    expect(rec.pages, [SettingsPageId.network]);
    pending.complete(true);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    testWidgets('failure status fits narrow Agent page in $locale', (t) async {
      final rec = await agent(t, locale: locale);
      rec.saveInstructions = ({required global, required prefix}) async =>
          false;
      await edit(t, 'agent-global', 'unsaved fixture');
      await save(t);
      await t.ensureVisible(find.byKey(const Key('agent-instructions-status')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
      expect(t.takeException(), isNull);
      final directory = Platform.environment['CAPTURE_SETTINGS_SAVE'];
      if (directory != null) {
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('settings-capture')),
        );
        await t.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final file = File('$directory/failure-$locale.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
    });
  }
}
