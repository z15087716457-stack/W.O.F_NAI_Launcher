import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/service_request_controls.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

Finder _field(String name) => find.byKey(Key('service-$name'));
Finder _button(String name, String action) => _field('$name-$action');
Finder _retry(String text) =>
    find.descendant(of: _field('retry-attempts'), matching: find.text(text));
String _text(WidgetTester tester, String name) =>
    tester.widget<TextFormField>(_field(name)).controller!.text;
Future<void> _type(WidgetTester tester, String name, String text) async {
  await tester.ensureVisible(_field(name));
  await tester.pumpAndSettle();
  await tester.enterText(_field(name), text);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await harness.tapVisible(tester, _field('advanced-toggle'));
  if (_field('retry-attempts').evaluate().isNotEmpty) {
    await tester.ensureVisible(_field('retry-attempts'));
    await tester.pumpAndSettle();
  }
}

void _expectAlignedStepper(WidgetTester tester, String name) {
  final editable = find.descendant(
    of: _field(name),
    matching: find.byType(EditableText),
  );
  final painted = InputDecorator.containerOf(tester.element(editable))!;
  final input = painted.localToGlobal(Offset.zero) & painted.size;
  for (final part in ['decrease', 'increase', 'unit']) {
    final bounds = tester.getRect(_button(name, part));
    expect(bounds.height, closeTo(input.height, .01));
    expect(bounds.center.dy, closeTo(input.center.dy, .01));
  }
}

class _PausedSecrets extends harness.MemorySecrets {
  Completer<void>? pause;
  @override
  Future<void> deletePromptAssistantHeaders(String providerId) async {
    await pause?.future;
    await super.deletePromptAssistantHeaders(providerId);
  }
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

  testWidgets('B controls support stepping, typing, folding and saved values', (
    tester,
  ) async {
    final container = await harness.pumpManagement(tester);
    final before = container.read(promptAssistantConfigProvider);
    await _open(tester);
    await harness.capture(tester, 'request-controls-wide-default');
    expect(_text(tester, 'request-timeout'), '120');
    expect(_text(tester, 'max-concurrency'), '5');
    _expectAlignedStepper(tester, 'request-timeout');
    _expectAlignedStepper(tester, 'max-concurrency');
    await harness.tapVisible(tester, _button('request-timeout', 'increase'));
    expect(_text(tester, 'request-timeout'), '130');
    await harness.tapVisible(tester, _button('request-timeout', 'decrease'));
    expect(_text(tester, 'request-timeout'), '120');
    await harness.tapVisible(tester, _button('max-concurrency', 'increase'));
    expect(_text(tester, 'max-concurrency'), '6');
    await _type(tester, 'request-timeout', '175');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: _field('request-timeout'),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isFalse,
    );
    await _type(tester, 'max-concurrency', '8');
    await harness.tapVisible(tester, _retry('2 次'));
    expect(
      container.read(promptAssistantConfigProvider).encode(),
      before.encode(),
    );
    await harness.capture(tester, 'request-controls-wide-edited');
    await _open(tester);
    expect(find.byType(ServiceRequestStepper), findsNothing);
    await _open(tester);
    expect(_text(tester, 'request-timeout'), '175');
    expect(_text(tester, 'max-concurrency'), '8');
    expect(
      tester.widget<ServiceRetrySegments>(_field('retry-attempts')).value,
      2,
    );
    await harness.tapVisible(tester, _field('save'));
    final saved = container.read(promptAssistantConfigProvider).providers.first;
    expect(saved.timeoutSeconds, 175);
    expect(saved.maxConcurrentRequests, 8);
    expect(saved.retryAttempts, 2);
    // Recreate the editor from the saved provider rather than its draft.
    await harness.tapVisible(tester, find.text('本地模型').first);
    await harness.tapVisible(tester, find.text('DeepSeek').first);
    await _open(tester);
    expect(_text(tester, 'request-timeout'), '175');
    expect(_text(tester, 'max-concurrency'), '8');
    expect(
      tester.widget<ServiceRetrySegments>(_field('retry-attempts')).value,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manual ranges block saving and step buttons clamp at both bounds',
    (tester) async {
      final container = await harness.pumpManagement(tester);
      final before = container.read(promptAssistantConfigProvider).encode();
      await _open(tester);
      await _type(tester, 'request-timeout', '601');
      await harness.tapVisible(tester, _field('save'));
      expect(container.read(promptAssistantConfigProvider).encode(), before);
      expect(find.text('请求超时应在 10–600 秒之间。'), findsOneWidget);
      await harness.tapVisible(tester, _button('request-timeout', 'decrease'));
      expect(_text(tester, 'request-timeout'), '600');
      expect(
        tester
            .widget<IconButton>(_button('request-timeout', 'increase'))
            .onPressed,
        isNull,
      );
      await _type(tester, 'request-timeout', '597');
      await harness.tapVisible(tester, _button('request-timeout', 'increase'));
      expect(_text(tester, 'request-timeout'), '600');
      await _type(tester, 'request-timeout', '12');
      await harness.tapVisible(tester, _button('request-timeout', 'decrease'));
      expect(_text(tester, 'request-timeout'), '10');
      expect(
        tester
            .widget<IconButton>(_button('request-timeout', 'decrease'))
            .onPressed,
        isNull,
      );
      await _type(tester, 'max-concurrency', '21');
      await harness.tapVisible(tester, _field('save'));
      expect(container.read(promptAssistantConfigProvider).encode(), before);
      expect(find.text('最大并发数量应在 1–20 个之间。'), findsOneWidget);
      await harness.tapVisible(tester, _button('max-concurrency', 'decrease'));
      expect(_text(tester, 'max-concurrency'), '20');
      expect(
        tester
            .widget<IconButton>(_button('max-concurrency', 'increase'))
            .onPressed,
        isNull,
      );
      await _type(tester, 'max-concurrency', '');
      await harness.tapVisible(tester, _field('save'));
      expect(container.read(promptAssistantConfigProvider).encode(), before);
      await harness.capture(tester, 'request-controls-invalid');
      await harness.tapVisible(tester, _button('max-concurrency', 'increase'));
      expect(_text(tester, 'max-concurrency'), '1');
      expect(
        tester
            .widget<IconButton>(_button('max-concurrency', 'decrease'))
            .onPressed,
        isNull,
      );
      await harness.tapVisible(tester, _retry('3 次'));
      await harness.tapVisible(tester, _retry('1 次'));
      await harness.tapVisible(tester, _retry('关闭'));
      await harness.tapVisible(tester, _field('save'));
      final saved = container
          .read(promptAssistantConfigProvider)
          .providers
          .first;
      expect(saved.timeoutSeconds, 10);
      expect(saved.maxConcurrentRequests, 1);
      expect(saved.retryAttempts, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all request controls disable while saving', (tester) async {
    final secrets = _PausedSecrets();
    final container = await harness.pumpManagement(tester, secrets: secrets);
    await _open(tester);
    await harness.tapVisible(tester, _button('max-concurrency', 'increase'));
    secrets.pause = Completer<void>();
    await tester.ensureVisible(_field('save'));
    await tester.pumpAndSettle();
    await tester.tap(_field('save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    for (final name in ['request-timeout', 'max-concurrency']) {
      expect(tester.widget<TextFormField>(_field(name)).enabled, isFalse);
      for (final action in ['increase', 'decrease']) {
        expect(
          tester.widget<IconButton>(_button(name, action)).onPressed,
          isNull,
        );
      }
    }
    final retry = tester.widget<SegmentedButton<int>>(
      find.descendant(
        of: _field('retry-attempts'),
        matching: find.byType(SegmentedButton<int>),
      ),
    );
    expect(retry.onSelectionChanged, isNull);
    secrets.pause!.complete();
    await tester.pumpAndSettle();
    expect(
      container
          .read(promptAssistantConfigProvider)
          .providers
          .first
          .maxConcurrentRequests,
      6,
    );
    await _open(tester);
    expect(
      tester.widget<TextFormField>(_field('max-concurrency')).enabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final spec in [
    (const Size(600, 760), 1.3, 'compact'),
    (const Size(400, 760), 1.3, 'narrow'),
  ]) {
    testWidgets(
      '${spec.$3} enlarged text keeps B controls visible and usable',
      (tester) async {
        final container = await harness.pumpManagement(
          tester,
          size: spec.$1,
          scale: spec.$2,
        );
        await _open(tester);
        await harness.capture(tester, 'request-controls-${spec.$3}');
        for (final name in ['request-timeout', 'max-concurrency']) {
          await tester.ensureVisible(_field(name));
          await tester.pumpAndSettle();
          final input = tester.getRect(_field(name));
          final minus = tester.getRect(_button(name, 'decrease'));
          final plus = tester.getRect(_button(name, 'increase'));
          _expectAlignedStepper(tester, name);
          expect(minus.left, greaterThanOrEqualTo(0));
          expect(minus.right, lessThan(input.left));
          expect(plus.left, greaterThan(input.right));
          expect(plus.right, lessThan(spec.$1.width));
          expect(minus.height, greaterThanOrEqualTo(34));
          await harness.tapVisible(tester, _button(name, 'increase'));
        }
        await harness.tapVisible(tester, _retry('3 次'));
        await harness.capture(tester, 'request-controls-${spec.$3}-selected');
        await harness.tapVisible(tester, _field('save'));
        final saved = container
            .read(promptAssistantConfigProvider)
            .providers
            .first;
        expect(saved.timeoutSeconds, 130);
        expect(saved.maxConcurrentRequests, 6);
        expect(saved.retryAttempts, 3);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
