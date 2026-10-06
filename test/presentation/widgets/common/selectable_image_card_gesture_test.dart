import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/selectable_image_card.dart';

void main() {
  testWidgets('delete follows details in red and closes before its callback', (
    tester,
  ) async {
    var deletes = 0;
    await tester.pumpWidget(
      _testApp(
        _card(
          onFullscreen: () {},
          onDelete: () {
            expect(find.byType(MenuAnchor), findsNothing);
            deletes++;
          },
        ),
      ),
    );
    await tester.tap(
      find.byType(SelectableImageCard),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Details')).dy,
      lessThan(tester.getTopLeft(find.text('Delete')).dy),
    );
    final button = tester.widget<MenuItemButton>(
      find.ancestor(
        of: find.text('Delete'),
        matching: find.byType(MenuItemButton),
      ),
    );
    final colors = Theme.of(tester.element(find.text('Delete'))).colorScheme;
    expect(button.style!.foregroundColor!.resolve({}), colors.error);
    expect((button.leadingIcon! as Icon).color, colors.error);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deletes, 1);
  });
  testWidgets('linked double click is immediate tap then one double callback', (
    tester,
  ) async {
    var taps = 0;
    var doubles = 0;
    var previewActive = false;

    await tester.pumpWidget(
      _testApp(
        StatefulBuilder(
          builder: (context, setState) {
            return _card(
              isPreviewActive: previewActive,
              onTap: () {
                taps++;
                setState(() => previewActive = true);
              },
              onDoubleTap: () => doubles++,
            );
          },
        ),
      ),
    );

    final card = find.byType(SelectableImageCard);
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 1);
    expect(doubles, 0);

    await tester.tap(card);
    await tester.pump();
    expect(taps, 1);
    expect(doubles, 1);
  });

  testWidgets('legacy path retains duplicate click debounce', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_testApp(_card(onTap: () => taps++)));

    final card = find.byType(SelectableImageCard);
    await tester.tap(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('modifier bypass allows every rapid legacy click', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _testApp(_card(onTap: () => taps++, allowRepeatedModifierTaps: true)),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final card = find.byType(SelectableImageCard);
    await tester.tap(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(taps, 2);
  });

  testWidgets('legacy modifier clicks remain debounced unless opted in', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_testApp(_card(onTap: () => taps++)));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final card = find.byType(SelectableImageCard);
    await tester.tap(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(taps, 1);
  });

  testWidgets('selection border takes priority over preview-active border', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(_card(isPreviewActive: true, isSelected: false)),
    );
    final theme = Theme.of(tester.element(find.byType(SelectableImageCard)));

    expect(_activeBorder(tester).top.color, theme.colorScheme.tertiary);
    expect(_activeBorder(tester).top.width, 3);

    await tester.pumpWidget(
      _testApp(_card(isPreviewActive: true, isSelected: true)),
    );
    await tester.pump();

    expect(_activeBorder(tester).top.color, theme.colorScheme.primary);
    expect(_activeBorder(tester).top.width, 3);
  });

  testWidgets('history thumb marks state with one light-blue plate only', (
    tester,
  ) async {
    Widget thumb({bool active = false}) => SizedBox(
      width: 120,
      height: 120,
      child: SelectableImageCard(
        key: const ValueKey('image-card'),
        imageBytes: base64Decode(_oneByOnePngBase64),
        imageIdentity: 'image-1',
        historyThumb: true,
        isPreviewActive: active,
        enableSelection: false,
        onTap: () {},
      ),
    );
    final edgeGlow = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_EdgeGlowOverlay',
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    // Regular cards still glow on hover, so the finder is live.
    await tester.pumpWidget(_testApp(_card()));
    await mouse.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(edgeGlow, findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    await tester.pumpWidget(_testApp(thumb()));
    final blue = Theme.of(
      tester.element(find.byType(SelectableImageCard)),
    ).colorScheme.primary;
    expect(_historyPlate(tester), isNull);

    await mouse.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(edgeGlow, findsNothing);
    expect(_historyPlate(tester)!.color, blue.withValues(alpha: 0.11));

    await tester.pumpWidget(_testApp(thumb(active: true)));
    await tester.pump(const Duration(milliseconds: 300));
    final plate = _historyPlate(tester)!;
    expect(plate.color, blue.withValues(alpha: 0.22));
    expect(plate.spreadRadius, 2);
    expect(plate.blurRadius, 0);
    // The letterbox turns clear so the plate shows through it.
    expect(
      _cardDecorations(tester).where((d) => d.color == Colors.transparent),
      hasLength(1),
    );
  });

  testWidgets('right-click details closes the menu and opens the viewer once', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      _testApp(
        _card(
          onFullscreen: () => opens++,
          enableSaveAction: false,
          enableCopyAction: false,
        ),
      ),
    );

    await tester.tap(
      find.byType(SelectableImageCard),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(find.byType(MenuAnchor), findsNothing);
  });
}

Widget _card({
  VoidCallback? onTap,
  VoidCallback? onDoubleTap,
  VoidCallback? onFullscreen,
  VoidCallback? onDelete,
  bool isPreviewActive = false,
  bool isSelected = false,
  bool allowRepeatedModifierTaps = false,
  bool enableSaveAction = true,
  bool enableCopyAction = true,
}) {
  return SizedBox(
    width: 120,
    height: 120,
    child: SelectableImageCard(
      key: const ValueKey('image-card'),
      imageBytes: base64Decode(_oneByOnePngBase64),
      imageIdentity: 'image-1',
      isPreviewActive: isPreviewActive,
      isSelected: isSelected,
      allowRepeatedModifierTaps: allowRepeatedModifierTaps,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onFullscreen: onFullscreen,
      onDelete: onDelete,
      enableSelection: false,
      enableSaveAction: enableSaveAction,
      enableCopyAction: enableCopyAction,
    ),
  );
}

Iterable<BoxDecoration> _cardDecorations(WidgetTester tester) {
  return tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(SelectableImageCard),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .map((container) => container.decoration)
      .whereType<BoxDecoration>();
}

BoxShadow? _historyPlate(WidgetTester tester) {
  final shadows = _cardDecorations(
    tester,
  ).singleWhere((d) => d.borderRadius == BorderRadius.circular(3)).boxShadow;
  return shadows == null || shadows.isEmpty ? null : shadows.single;
}

Border _activeBorder(WidgetTester tester) {
  final containers = tester.widgetList<AnimatedContainer>(
    find.descendant(
      of: find.byType(SelectableImageCard),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return containers
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .map((decoration) => decoration.border)
      .whereType<Border>()
      .firstWhere((border) => border.top.width == 3);
}

Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

const _oneByOnePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6qv0YAAAAASUVORK5CYII=';
