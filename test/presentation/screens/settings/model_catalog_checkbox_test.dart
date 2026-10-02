import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
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
  for (final failure in [false, true]) {
    testWidgets(
      'selected and mixed catalog checkboxes retain neutral color during test, failure=$failure',
      (tester) async {
        RequestInterceptorHandler? pending;
        RequestOptions? pendingOptions;
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                if (options.method == 'GET') {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {
                        'data': [
                          {'id': 'deepseek-chat'},
                          {'id': 'deepseek-reasoner'},
                          {'id': 'unselected-model'},
                        ],
                      },
                    ),
                  );
                } else {
                  pending = handler;
                  pendingOptions = options;
                }
              },
            ),
          );
        addTearDown(dio.close);
        await harness.pumpManagement(
          tester,
          dio: dio,
          secrets: harness.MemorySecrets()..keys['deepseek'] = 'fixture',
        );
        await harness.tapVisible(
          tester,
          find.byKey(const Key('service-fetch-catalog')),
        );
        final all = find.byKey(const Key('service-catalog-select-all'));
        expect(tester.widget<Checkbox>(all).value, isNull);
        Color? fill(Checkbox box, bool disabled) => box.fillColor?.resolve({
          if (box.value != false) WidgetState.selected,
          if (disabled) WidgetState.disabled,
        });
        final selected = find.descendant(
          of: find.byKey(const ValueKey('catalog-model-deepseek-chat')),
          matching: find.byType(Checkbox),
        );
        final unselected = find.descendant(
          of: find.byKey(const ValueKey('catalog-model-unselected-model')),
          matching: find.byType(Checkbox),
        );
        final expected = Theme.of(tester.element(all)).colorScheme.onSurface;
        for (final finder in [all, selected]) {
          expect(fill(tester.widget<Checkbox>(finder), false), expected);
        }
        await harness.capture(tester, 'catalog-checkbox-before-$failure');
        await tester.tap(find.byKey(const Key('service-test')));
        for (var i = 0; i < 10 && pending == null; i++) {
          await tester.pump(const Duration(milliseconds: 30));
        }
        expect(pending, isNotNull);
        for (final finder in [all, selected, unselected]) {
          final box = tester.widget<Checkbox>(finder);
          expect(box.onChanged, isNull);
          expect(
            fill(box, true),
            finder == unselected ? Colors.transparent : expected,
          );
        }
        expect(tester.widget<Checkbox>(all).value, isNull);
        await harness.capture(tester, 'catalog-checkbox-testing-$failure');
        if (failure) {
          pending!.reject(
            DioException(
              requestOptions: pendingOptions!,
              error: 'offline-fixture',
            ),
          );
        } else {
          pending!.resolve(
            Response(
              requestOptions: pendingOptions!,
              statusCode: 200,
              data: {
                'choices': [
                  {
                    'message': {'content': 'ok'},
                  },
                ],
              },
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(selected).onChanged, isNotNull);
        expect(fill(tester.widget<Checkbox>(selected), false), expected);
        expect(tester.widget<Checkbox>(all).value, isNull);
        await harness.capture(tester, 'catalog-checkbox-after-$failure');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
