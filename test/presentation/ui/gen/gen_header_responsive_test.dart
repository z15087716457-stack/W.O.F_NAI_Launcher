import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'drag_preview_test_support.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  const desktops = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
  });

  Future<void> pumpHeader(
    WidgetTester t, {
    double left = 400,
    String modelName = 'V5 Full',
    double accessory = 0,
    bool historyOpen = true,
    bool historyOwnsCaptions = true,
    GenRecorder? recorder,
  }) async {
    t.view.devicePixelRatio = 2;
    t.view.physicalSize = const Size((1600 - genRail) * 2, 900 * 2);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final base = GenFixture.empty();
    await t.pumpWidget(
      genApp(
        WindowChromeScope(
          enabled: historyOwnsCaptions,
          draggable: true,
          extraWidth: accessory,
          child: GenerationPage(
            data: base.copyWith(
              layout: GenLayout(
                leftWidth: left,
                historyWidth: 280,
                historyOpen: historyOpen,
              ),
              models: [GenModel(id: base.model, name: modelName)],
              quota: const GenQuota(opusPercent: 100, anlas: 68243),
            ),
            actions: (recorder ?? GenRecorder()).actions,
            slots: GenSlots(
              editor: (_, _) => const SizedBox(height: 64),
              historyCaptionInset: historyOwnsCaptions,
            ),
          ),
        ),
        dark: true,
      ),
    );
    await t.pumpAndSettle();
  }

  Finder keyed(String key) => find.byKey(Key(key));
  Rect bounds(WidgetTester t, String key) => t.getRect(keyed(key));
  Future<void> capture(WidgetTester t, String name) => captureUiuxRegion(
    t,
    keyed('gen-capture'),
    name,
    const Rect.fromLTWH(0, 0, 1600 - genRail, 112),
  );

  testWidgets(
    'V5 Full and the five-digit balance fit before and after resize',
    (t) async {
      final mac = defaultTargetPlatform == TargetPlatform.macOS;
      final recorder = GenRecorder();
      await pumpHeader(t, recorder: recorder);
      expect(find.text('V5 Full'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('68,243'), findsOneWidget);
      final model = bounds(t, 'gen-model-capsule');
      final initialQuota = bounds(t, 'gen-quota');
      final initialHeader = bounds(t, 'gen-header');
      expect(bounds(t, 'gen-left').width, 400);
      if (mac) await capture(t, 'default-400');

      final drag = await beginDividerDrag(t, 'gen-left-resize');
      await drag.moveBy(const Offset(8, 0));
      await drag.up();
      await t.pumpAndSettle();
      expect(bounds(t, 'gen-left').width, 408);
      final quota = bounds(t, 'gen-quota');
      expect(quota.top, model.top);
      expect(quota.left, greaterThan(bounds(t, 'gen-model-capsule').right));
      expect(
        quota.right,
        lessThanOrEqualTo(bounds(t, 'gen-collapse-left').left),
      );
      if (mac) await capture(t, 'resized-408');
      expect(
        initialQuota.top == model.top,
        mac,
        reason:
            'At 400: header $initialHeader, model $model, quota $initialQuota. '
            'After the 8px drag the quota is $quota.',
      );
      await t.tap(keyed('gen-quota'));
      await t.pumpAndSettle();
      expect(recorder.called('onOpenQuota'), isTrue);
      await t.tap(keyed('gen-collapse-left'));
      await t.pumpAndSettle();
      expect(recorder.last('onLayoutChanged'), contains('leftOpen: false'));
      expect(t.takeException(), isNull);
    },
    variant: desktops,
  );

  testWidgets('the full model and quota wrap when their widths require it', (
    t,
  ) async {
    for (final (left, modelName) in [
      (352.0, 'V5 Full'),
      (400.0, 'V5 Curated'),
    ]) {
      await pumpHeader(t, left: left, modelName: modelName);
      final model = bounds(t, 'gen-model-capsule');
      final quota = bounds(t, 'gen-quota');
      expect(quota.top, greaterThan(model.bottom));
      expect(quota.left, model.left);
      expect(
        model.right,
        lessThanOrEqualTo(bounds(t, 'gen-collapse-left').left),
      );
      expect(find.text(modelName), findsOneWidget);
      expect(find.text('68,243'), findsOneWidget);
      expect(t.takeException(), isNull);
      await capture(t, 'wrapped-${left.toInt()}');
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('image size controls fit through the sidebar resize range', (
    t,
  ) async {
    final overflowing = <int, double>{};
    final errors = <Object>[];
    for (var width = 352; width <= 420; width++) {
      await pumpHeader(t, left: width.toDouble());
      final error = t.takeException();
      if (error != null) errors.add(error);
      final image = bounds(t, 'gen-image');
      final picker = bounds(t, 'gen-size-group');
      final orientation = bounds(t, 'gen-orientation');
      final first = bounds(t, 'gen-width');
      final last = bounds(t, 'gen-height');
      final excess = last.right - (image.right - (picker.left - image.left));
      if (excess > .01) overflowing[width] = excess;
      expect(picker.right, lessThan(orientation.left), reason: 'left=$width');
      expect(orientation.right, lessThan(first.left), reason: 'left=$width');
    }
    expect(overflowing, isEmpty);
    expect(errors, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('history reserves only the caption footprint it owns', (t) async {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    for (final (accessory, owns) in [
      (0.0, true),
      (28.0, true),
      (28.0, false),
    ]) {
      final inset = owns && (!mac || accessory > 0) ? 36.0 : 0.0;
      await pumpHeader(t, accessory: accessory, historyOwnsCaptions: owns);
      final pane = bounds(t, 'gen-history');
      final header = bounds(t, 'gen-history-header');
      expect(header.top - pane.top, inset);
      expect(header.height, 40);
      for (final button in ['gen-collapse-history', 'gen-history-select']) {
        expect(bounds(t, button).center.dy, closeTo(header.center.dy, .6));
        expect(keyed(button).hitTestable(), findsOneWidget);
      }
      await pumpHeader(
        t,
        historyOpen: false,
        accessory: accessory,
        historyOwnsCaptions: owns,
      );
      final strip = keyed('gen-history-strip');
      final expand = find.descendant(of: strip, matching: find.byTooltip('展开'));
      expect(t.getTopLeft(expand).dy - t.getTopLeft(strip).dy, inset + 6);
      expect(t.takeException(), isNull);
    }
  }, variant: desktops);
}
