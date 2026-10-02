import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/service_request_controls.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final spec in [
    (const Size(1200, 820), 1.0, 'wide'),
    (const Size(600, 760), 1.3, 'compact'),
    (const Size(400, 760), 1.3, 'narrow'),
  ]) {
    testWidgets('B grouped service actions fit ${spec.$3} layout', (
      tester,
    ) async {
      await harness.pumpManagement(tester, size: spec.$1, scale: spec.$2);
      final toolbar = find.byKey(const Key('service-actions'));
      final bounds = tester.getRect(toolbar);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(spec.$1.width));
      for (final action in ['enabled', 'test', 'save', 'delete']) {
        expect(
          find.descendant(
            of: toolbar,
            matching: find.byKey(Key('service-$action')),
          ),
          findsOneWidget,
        );
      }
      final material = tester.widget<Material>(toolbar);
      expect(
        (material.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(10),
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('service-test')))
            .onPressed,
        isNotNull,
      );
      await harness.capture(tester, 'service-finish-actions-${spec.$3}');
      await harness.tapVisible(
        tester,
        find.byKey(const Key('service-advanced-toggle')),
      );
      final stepper = find.byKey(const Key('service-request-timeout'));
      await tester.ensureVisible(stepper);
      await tester.pumpAndSettle();
      expect(
        (tester
                    .widget<TextField>(
                      find.descendant(
                        of: stepper,
                        matching: find.byType(TextField),
                      ),
                    )
                    .decoration!
                    .border
                as OutlineInputBorder)
            .borderRadius,
        serviceControlRadius,
      );
      final retry = tester.widget<TextButton>(
        find.byKey(const ValueKey('service-retry-0')),
      );
      expect(
        (retry.style!.shape!.resolve({}) as RoundedRectangleBorder)
            .borderRadius,
        serviceControlRadius,
      );
      await harness.capture(tester, 'service-finish-controls-${spec.$3}');
      await harness.tapVisible(tester, find.byKey(const Key('service-delete')));
      expect(find.text('删除 DeepSeek？'), findsOneWidget);
      await harness.tapVisible(tester, find.text('取消'));
      expect(tester.takeException(), isNull);
    });
  }
}
