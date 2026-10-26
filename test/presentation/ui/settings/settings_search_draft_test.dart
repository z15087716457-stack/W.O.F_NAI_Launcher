import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_page.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../model_providers/model_providers_harness.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  const draft = 'Fixture instructions remain pending';
  final search = find.byKey(const Key('settings-search-input'));
  Finder global() => find.descendant(
    of: find.byKey(const Key('agent-global')),
    matching: find.byType(TextField),
  );
  Future<SettingsRecorder> edit(WidgetTester t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.agent,
      agentTab: 'instructions',
      window: 2000,
      height: 1300,
    );
    await t.enterText(global(), draft);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
    return rec;
  }

  Future<void> query(WidgetTester t, String value) async {
    await t.enterText(search, value);
    await t.pumpAndSettle();
  }

  for (final escape in [false, true]) {
    testWidgets(
      'Agent draft survives search and ${escape ? 'Escape' : 'clearing'}',
      (t) async {
        final rec = await edit(t);
        final textController = t.widget<TextField>(global()).controller!;
        await query(t, 'proxy');
        expect(find.byKey(const Key('hit-proxyEnabled')), findsOneWidget);
        expect(find.byKey(const Key('agent-global')), findsNothing);
        expect(find.byKey(const Key('settings-confirm')), findsNothing);
        if (escape) {
          await t.sendKeyEvent(LogicalKeyboardKey.escape);
          await t.pumpAndSettle();
        } else {
          await query(t, '');
        }
        expect(t.widget<TextField>(global()).controller, same(textController));
        expect(textController.text, draft);
        expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
        expect(rec.has('saveInstructions:'), isFalse);
        expect(t.takeException(), isNull);
      },
    );
  }

  for (final confirm in [false, true]) {
    testWidgets(
      'search navigation retains the existing leave guard, confirm=$confirm',
      (t) async {
        final rec = await edit(t);
        await query(t, 'proxy');
        await t.tap(find.byKey(const Key('jump-proxyEnabled')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
        expect(rec.pages, isEmpty);
        await t.tap(find.byKey(Key(confirm ? 'confirm-ok' : 'confirm-cancel')));
        await t.pumpAndSettle();
        if (confirm) {
          expect(rec.pages, [SettingsPageId.network]);
        } else {
          expect(rec.pages, isEmpty);
          await query(t, '');
          expect(t.widget<TextField>(global()).controller!.text, draft);
          expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
        }
        expect(rec.has('saveInstructions:'), isFalse);
      },
    );
  }

  for (final success in [false, true]) {
    testWidgets(
      'Agent save result survives searching while pending, success=$success',
      (t) async {
        final rec = await edit(t);
        final gate = Completer<bool>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete(false);
        });
        rec.saveInstructions = ({required global, required prefix}) =>
            gate.future;
        await t.tap(find.byKey(const Key('dock-保存')));
        await t.pump();
        await query(t, 'proxy');
        gate.complete(success);
        await t.pumpAndSettle();
        await query(t, '');
        expect(t.widget<TextField>(global()).controller!.text, draft);
        expect(
          find.byKey(const Key('agent-unsaved')),
          success ? findsNothing : findsOneWidget,
        );
        expect(
          rec.calls.where((c) => c.startsWith('saveInstructions:')),
          hasLength(1),
        );
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('provider draft and its controller survive a search round trip', (
    t,
  ) async {
    final rec = await pumpProviders(t, window: 2000, height: 1300);
    await t.tap(find.byKey(const Key('mp-cap-search')));
    await t.pumpAndSettle();
    final state = t.state<ModelProvidersPanelState>(
      find.byType(ModelProvidersPanel),
    );
    expect(state.ctrl.changes(rec.data.providers.first), 1);
    await query(t, 'proxy');
    expect(find.byType(ModelProvidersPanel), findsNothing);
    await query(t, '');
    expect(t.state(find.byType(ModelProvidersPanel)), same(state));
    expect(state.ctrl.changes(rec.data.providers.first), 1);
    expect(find.byKey(const Key('mp-dock')), findsOneWidget);
    expect(rec.has('save:'), isFalse);
  });

  testWidgets(
    'provider save finishes in place while search results are visible',
    (t) async {
      final rec = await pumpProviders(t, window: 2000, height: 1300);
      await t.tap(find.byKey(const Key('mp-cap-search')));
      await t.pumpAndSettle();
      final state = t.state<ModelProvidersPanelState>(
        find.byType(ModelProvidersPanel),
      );
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      rec.saveGate = gate.future;
      await t.tap(find.byKey(const Key('dock-保存')));
      await t.pump();
      await query(t, 'proxy');
      gate.complete();
      await t.pumpAndSettle();
      await query(t, '');
      expect(t.state(find.byType(ModelProvidersPanel)), same(state));
      expect(rec.lastSaved, isNotNull);
      expect(state.ctrl.changes(rec.data.providers.first), 0);
      expect(find.byKey(const Key('mp-dock')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
