import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

class _PausedSecrets extends harness.MemorySecrets {
  Completer<void>? pause;
  bool failNext = false;

  @override
  Future<void> deletePromptAssistantHeaders(String providerId) async {
    await pause?.future;
    if (failNext) {
      failNext = false;
      throw StateError('offline save failure');
    }
    await super.deletePromptAssistantHeaders(providerId);
  }
}

Future<void> _expectFilledEdges(WidgetTester tester) async {
  final button = find.byKey(const Key('service-save'));
  final bounds = tester.getRect(button);
  final color = Theme.of(tester.element(button)).colorScheme.primary;
  await tester.runAsync(() async {
    final boundary =
        harness.captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    for (final x in [bounds.left + 3, bounds.right - 3]) {
      final offset = (bounds.center.dy.floor() * image.width + x.floor()) * 4;
      for (final channel in [(0, color.r), (1, color.g), (2, color.b)]) {
        expect(
          (bytes.getUint8(offset + channel.$1) - channel.$2 * 255).abs(),
          lessThanOrEqualTo(25),
          reason: 'Both button edges must keep the action fill.',
        );
      }
      expect(bytes.getUint8(offset + 3), 255);
    }
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final fail in [false, true]) {
    testWidgets(
      'save keeps discovered models and solid button edges, fail=$fail',
      (tester) async {
        final secrets = _PausedSecrets();
        var requests = 0;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests++;
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'data': [
                        {'id': 'remote-model'},
                      ],
                    },
                  ),
                );
              },
            ),
          );
        addTearDown(dio.close);
        await harness.pumpManagement(tester, secrets: secrets, dio: dio);
        await harness.tapVisible(
          tester,
          find.byKey(const Key('service-fetch-catalog')),
        );
        final save = find.byKey(const Key('service-save'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        final originalBounds = tester.getRect(save);
        await _expectFilledEdges(tester);
        await harness.capture(tester, 'save-feedback-$fail-ready');
        secrets.pause = Completer<void>();
        secrets.failNext = fail;
        final gesture = await tester.startGesture(originalBounds.center);
        await tester.pump(const Duration(milliseconds: 20));
        await _expectFilledEdges(tester);
        await harness.capture(tester, 'save-feedback-$fail-pressed');
        await gesture.up();
        for (final delay in [20, 100, 300]) {
          await tester.pump(Duration(milliseconds: delay));
          expect(tester.widget<FilledButton>(save).onPressed, isNull);
          expect(tester.getRect(save), originalBounds);
          await _expectFilledEdges(tester);
        }
        await harness.capture(tester, 'save-feedback-$fail-busy');
        expect(requests, 1);
        expect(
          find.byKey(const ValueKey('catalog-model-remote-model')),
          findsOneWidget,
        );
        secrets.pause!.complete();
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
        expect(tester.getRect(save), originalBounds);
        await _expectFilledEdges(tester);
        expect(
          find.byKey(const ValueKey('catalog-model-remote-model')),
          findsOneWidget,
        );
        expect(requests, 1);
        await harness.capture(tester, 'save-feedback-$fail-complete');
        if (fail) {
          expect(find.textContaining('保存失败：'), findsOneWidget);
          await harness.tapVisible(tester, save);
          expect(find.textContaining('保存失败：'), findsNothing);
          expect(
            find.byKey(const ValueKey('catalog-model-remote-model')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
