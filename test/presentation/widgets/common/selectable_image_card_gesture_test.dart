import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
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

  testWidgets('history hover draws a thin outline without a plate or glow', (
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
    await tester.pumpWidget(_testApp(_card()));
    await mouse.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(edgeGlow, findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    await tester.pumpWidget(_testApp(thumb()));
    final scheme = Theme.of(
      tester.element(find.byType(SelectableImageCard)),
    ).colorScheme;
    final outline = find.byKey(const ValueKey('history-image-outline'));
    expect(outline, findsNothing);
    await mouse.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(edgeGlow, findsNothing);
    final hovered =
        tester.widget<DecoratedBox>(outline).decoration as BoxDecoration;
    expect((hovered.border! as Border).top.width, 1);
    expect(
      (hovered.border! as Border).top.color,
      scheme.onSurface.withValues(alpha: .25),
    );
    await tester.pumpWidget(_testApp(thumb(active: true)));
    await tester.pump(const Duration(milliseconds: 300));
    final active =
        tester.widget<DecoratedBox>(outline).decoration as BoxDecoration;
    expect((active.border! as Border).top.color, scheme.primary);
    expect((active.border! as Border).top.width, 2);
    for (final decoration in _cardDecorations(tester)) {
      expect(decoration.color, isNull);
      expect(decoration.boxShadow, isNull);
    }
  });

  for (final dimensions in [(80, 160), (160, 80), (120, 120)]) {
    testWidgets(
      'history outline follows ${dimensions.$1} x ${dimensions.$2} image bounds',
      (tester) async {
        for (final selected in [false, true]) {
          await tester.pumpWidget(
            _testApp(
              SizedBox(
                width: 120,
                height: 120,
                child: SelectableImageCard(
                  imageBytes: img.encodePng(
                    img.Image(
                      width: dimensions.$1,
                      height: dimensions.$2,
                      numChannels: 4,
                    ),
                  ),
                  imageWidth: dimensions.$1,
                  imageHeight: dimensions.$2,
                  historyThumb: true,
                  isSelected: selected,
                  isPreviewActive: !selected,
                  batchBadgeCount: 2,
                  sourceBadge: const SizedBox(
                    key: Key('source'),
                    width: 10,
                    height: 10,
                  ),
                  enableSelection: false,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final card = tester.getRect(find.byType(SelectableImageCard));
          final picture = tester.getRect(
            find.byKey(const Key('history-image-display-area')),
          );
          final expected = dimensions.$1 < dimensions.$2
              ? Rect.fromCenter(center: card.center, width: 60, height: 120)
              : dimensions.$1 > dimensions.$2
              ? Rect.fromCenter(center: card.center, width: 120, height: 60)
              : card;
          expect(picture, expected);
          expect(
            tester.getRect(find.byKey(const Key('history-image-outline'))),
            expected.inflate(4),
          );
          expect(
            tester.getTopLeft(find.byKey(const Key('source'))),
            picture.topLeft + const Offset(6, 6),
          );
          final badge = tester.getRect(find.text('×2'));
          expect(badge.right, lessThanOrEqualTo(picture.right - 5));
          expect(badge.bottom, lessThanOrEqualTo(picture.bottom - 5));
          for (final decoration in _cardDecorations(tester)) {
            expect(decoration.color, isNull);
            expect(decoration.boxShadow, isNull);
          }
        }
      },
    );
  }

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
