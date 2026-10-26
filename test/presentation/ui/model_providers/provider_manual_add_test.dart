import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_providers_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  const newId = 'fixture-model-id';
  final field = find.descendant(
    of: find.byKey(const Key('mp-manual-input')),
    matching: find.byType(TextField),
  );
  Future<ProvidersRecorder> open(WidgetTester t, {String value = newId}) async {
    final rec = await pumpProviders(t, window: 2000, height: 1300);
    await t.ensureVisible(find.byKey(const Key('mp-manual')));
    await t.tap(
      find.byKey(const Key('mp-manual')),
      kind: PointerDeviceKind.mouse,
    );
    await t.pumpAndSettle();
    await t.enterText(field, value);
    await t.pump();
    return rec;
  }

  Finder cancel() {
    final row = find
        .ancestor(
          of: find.byKey(const Key('mp-manual-input')),
          matching: find.byType(Row),
        )
        .first;
    return find.descendant(of: row, matching: find.text('取消'));
  }

  void notAdded(ProvidersRecorder rec) {
    expect(rec.calls.where((c) => c.startsWith('add:')), isEmpty);
    expect(
      rec.data.providers.any((p) => p.settings.model(newId) != null),
      isFalse,
    );
  }

  testWidgets('mouse Cancel discards the entered model ID', (t) async {
    final rec = await open(t);
    await t.tap(cancel(), kind: PointerDeviceKind.mouse);
    await t.pumpAndSettle();
    notAdded(rec);
    expect(field, findsNothing);
  });

  testWidgets('Escape cancels without adding a model', (t) async {
    final rec = await open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    notAdded(rec);
    expect(field, findsNothing);
  });

  testWidgets(
    'selecting another model keeps the manual text without adding it',
    (t) async {
      final rec = await open(t);
      await t.tap(
        find.byKey(const Key('mp-model-deepseek-v4-pro')),
        kind: PointerDeviceKind.mouse,
      );
      await t.pumpAndSettle();
      notAdded(rec);
      expect(t.widget<TextField>(field).controller!.text, newId);
    },
  );

  testWidgets('switching providers does not submit the old manual ID', (
    t,
  ) async {
    final rec = await open(t);
    await t.tap(
      find.byKey(const Key('mp-provider-an')),
      kind: PointerDeviceKind.mouse,
    );
    await t.pumpAndSettle();
    notAdded(rec);
  });

  for (final enter in [false, true]) {
    testWidgets('explicit ${enter ? 'Enter' : 'Add'} adds the model once', (
      t,
    ) async {
      final rec = await open(t);
      if (enter) {
        await t.testTextInput.receiveAction(TextInputAction.done);
      } else {
        await t.tap(
          find.byKey(const Key('mp-manual-confirm')),
          kind: PointerDeviceKind.mouse,
        );
      }
      await t.pumpAndSettle();
      expect(rec.calls.where((c) => c.startsWith('add:')).toList(), [
        'add:ds:$newId:true',
      ]);
      expect(rec.data.providers.first.settings.model(newId), isNotNull);
      expect(field, findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('a duplicate ID cannot be submitted', (t) async {
    final rec = await open(t, value: 'deepseek-flash');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(rec.calls.where((c) => c.startsWith('add:')), isEmpty);
    expect(field, findsOneWidget);
  });

  testWidgets('blank input cannot be submitted or added by cancelling', (
    t,
  ) async {
    final rec = await open(t, value: '   ');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    await t.tap(cancel(), kind: PointerDeviceKind.mouse);
    await t.pumpAndSettle();
    notAdded(rec);
  });
}
