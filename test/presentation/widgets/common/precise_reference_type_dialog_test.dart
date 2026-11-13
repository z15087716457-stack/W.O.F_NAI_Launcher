import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/precise_reference_type_dialog.dart';

import '../../../helpers/studio_capture_fonts.dart';

const _dialogKey = Key('precise-reference-type-dialog');
final _capture = GlobalKey();

Future<void> _open(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  Size size = const Size(900, 700),
  double scale = 1,
  ValueChanged<PreciseRefType?>? onResult,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: AppTheme.getTheme(AppStyle.geist, brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(key: _capture, child: child!),
      ),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              key: const Key('open-pr-dialog'),
              autofocus: true,
              onPressed: () async {
                final value = await PreciseReferenceTypeDialog.show(context);
                onResult?.call(value);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-pr-dialog')));
  await tester.pumpAndSettle();
}

Future<void> _captureLayout(WidgetTester tester, String name) async {
  final output = Platform.environment['PR_TYPE_DIALOG_CAPTURES'];
  if (output == null) return;
  Map<String, double> rect(Finder finder) {
    final r = tester.getRect(finder);
    final origin = tester.getTopLeft(find.byKey(_dialogKey));
    return {
      'x': r.left - origin.dx,
      'y': r.top - origin.dy,
      'width': r.width,
      'height': r.height,
    };
  }

  final metrics = {
    'dialog': rect(find.byKey(_dialogKey)),
    'header': rect(find.byKey(const Key('precise-reference-type-header'))),
    'footer': rect(find.byKey(const Key('precise-reference-type-footer'))),
    for (final type in PreciseRefType.values)
      type.name: rect(
        find.byKey(ValueKey('precise-reference-type-${type.name}')),
      ),
  };
  await tester.runAsync(() async {
    final boundary =
        _capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('$output/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await File('$output/$name.json').writeAsString(jsonEncode(metrics));
    image.dispose();
  });
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final type in PreciseRefType.values) {
    testWidgets('returns the selected precise reference type: $type', (
      tester,
    ) async {
      PreciseRefType? selected;
      await _open(tester, onResult: (value) => selected = value);
      expect(find.text('Character'), findsOneWidget);
      expect(find.text('Style'), findsOneWidget);
      expect(find.text('Character + Style'), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey('precise-reference-type-${type.name}')),
      );
      await tester.pumpAndSettle();
      expect(selected, type);
      expect(find.byType(PreciseReferenceTypeDialog), findsNothing);
    });
  }

  for (final dismissal in ['close', 'cancel', 'escape', 'barrier']) {
    testWidgets('$dismissal cancels without selecting a reference type', (
      tester,
    ) async {
      var finished = false;
      PreciseRefType? selected = PreciseRefType.character;
      await _open(
        tester,
        onResult: (value) {
          finished = true;
          selected = value;
        },
      );
      switch (dismissal) {
        case 'close':
        case 'cancel':
          await tester.tap(
            find.byKey(Key('precise-reference-type-$dismissal')),
          );
        case 'escape':
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'barrier':
          await tester.tapAt(const Offset(5, 5));
      }
      await tester.pumpAndSettle();
      expect(finished, isTrue);
      expect(selected, isNull);
      expect(find.byType(PreciseReferenceTypeDialog), findsNothing);
      expect(
        Focus.of(tester.element(find.text('Open'))).hasPrimaryFocus,
        isTrue,
      );
    });
  }

  testWidgets('keyboard focus stays in the dialog and Enter selects a type', (
    tester,
  ) async {
    PreciseRefType? selected;
    await _open(tester, onResult: (value) => selected = value);
    final first = find.byKey(const Key('precise-reference-type-close'));
    final last = find.byKey(const Key('precise-reference-type-cancel'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
      Focus.of(
        tester.element(
          find.descendant(of: last, matching: find.text('Cancel')),
        ),
      ).hasPrimaryFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      Focus.of(
        tester.element(
          find.descendant(of: first, matching: find.byIcon(Icons.close)),
        ),
      ).hasPrimaryFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, PreciseRefType.character);
  });

  testWidgets('short windows scroll choices while cancel remains visible', (
    tester,
  ) async {
    PreciseRefType? selected;
    await _open(
      tester,
      size: const Size(320, 320),
      scale: 1.5,
      onResult: (value) => selected = value,
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('precise-reference-type-cancel')).hitTestable(),
      findsOneWidget,
    );
    final both = find.byKey(
      const ValueKey('precise-reference-type-characterAndStyle'),
    );
    await tester.ensureVisible(both);
    await tester.pumpAndSettle();
    await tester.tap(both);
    await tester.pumpAndSettle();
    expect(selected, PreciseRefType.characterAndStyle);
  });

  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final layout in const [
        (name: 'normal', size: Size(900, 700), scale: 1.0),
        (name: 'narrow', size: Size(320, 560), scale: 1.0),
        (name: 'large-text', size: Size(400, 480), scale: 1.5),
      ]) {
        final name =
            '${locale.toLanguageTag()}-${brightness.name}-${layout.name}';
        testWidgets('fits real fonts and controls: $name', (tester) async {
          debugDisableShadows = false;
          await _open(
            tester,
            locale: locale,
            brightness: brightness,
            size: layout.size,
            scale: layout.scale,
          );
          expect(tester.takeException(), isNull);
          final bounds = tester.getRect(find.byKey(_dialogKey));
          expect(bounds.left, greaterThanOrEqualTo(16));
          expect(bounds.right, lessThanOrEqualTo(layout.size.width - 16));
          expect(bounds.top, greaterThanOrEqualTo(16));
          expect(bounds.bottom, lessThanOrEqualTo(layout.size.height - 16));
          if (layout.name == 'normal' && locale.languageCode == 'zh') {
            expect(bounds.size, const Size(368, 370));
          }
          final cancel = find.byKey(const Key('precise-reference-type-cancel'));
          expect(cancel.hitTestable(), findsOneWidget);
          for (final type in PreciseRefType.values) {
            expect(
              find.byKey(ValueKey('precise-reference-type-${type.name}')),
              findsOneWidget,
            );
          }
          await _captureLayout(tester, name);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          debugDisableShadows = true;
        });
      }
    }
  }
}
