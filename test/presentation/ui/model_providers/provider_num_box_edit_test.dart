import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_kit.dart';

import '../blocks/blocks_test_harness.dart' show blocksApp;

void main() {
  late List<int?> changes;
  setUp(() => changes = []);
  final field = find.byType(TextField);
  Future<void> mount(WidgetTester t, int? value) async {
    await t.pumpWidget(
      blocksApp(
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProviderNumBox(
                value: value,
                min: 0,
                max: 20000000,
                format: providerTokens,
                parse: providerParseTokens,
                onChanged: changes.add,
              ),
              const SizedBox(width: 80),
              GestureDetector(
                key: const Key('outside'),
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> open(WidgetTester t, int? value) async {
    await mount(t, value);
    await t.tap(
      find.text(providerTokens(value)),
      kind: PointerDeviceKind.mouse,
    );
    await t.pumpAndSettle();
  }

  Future<void> blur(WidgetTester t) async {
    await t.tap(
      find.byKey(const Key('outside')),
      kind: PointerDeviceKind.mouse,
    );
    await t.pumpAndSettle();
  }

  for (final value in [null, 0, 999, 1000, 1001, 131072, 1048576, 1048577]) {
    testWidgets(
      'editing $value exposes the exact integer and preserves unchanged input',
      (t) async {
        await open(t, value);
        expect(
          t.widget<TextField>(field).controller!.text,
          value == null ? '' : '$value',
        );
        await blur(t);
        expect(changes, isEmpty);
      },
    );
  }

  for (final (input, expected) in [
    ('131.5K', 131500),
    ('1.25M', 1250000),
    ('131073', 131073),
    ('', null),
  ]) {
    testWidgets('an explicit "$input" edit commits $expected once', (t) async {
      await open(t, 131072);
      await t.enterText(field, input);
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await blur(t);
      expect(changes, [expected]);
    });
  }

  testWidgets(
    'external values are not overwritten after an unchanged inspection',
    (t) async {
      await open(t, 131072);
      await mount(t, 2000000);
      expect(t.widget<TextField>(field).controller!.text, '131072');
      await blur(t);
      expect(changes, isEmpty);
      expect(find.text(providerTokens(2000000)), findsOneWidget);
    },
  );

  testWidgets('invalid token input does not change the value', (t) async {
    await open(t, 131072);
    await t.enterText(field, 'invalid');
    await blur(t);
    expect(changes, isEmpty);
    expect(t.takeException(), isNull);
  });
}
