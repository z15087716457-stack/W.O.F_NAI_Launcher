import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_context_menu.dart';

void main() {
  for (final position in [const Offset(20, 20), const Offset(790, 590)]) {
    testWidgets('hover submenu follows its row and avoids edges at $position', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _MenuHarness(
          position: position,
          isKritaConnected: true,
          onSelected: (_) => calls++,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final parent = find.ancestor(
        of: find.text('Create & reference'),
        matching: find.byType(SubmenuButton),
      );
      final parentRect = tester.getRect(parent);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(parentRect.center);
      await tester.pumpAndSettle();
      final child = find.ancestor(
        of: find.text('Send to Text to Image'),
        matching: find.byType(MenuItemButton),
      );
      final childRect = tester.getRect(child);
      if (position.dx < 400) {
        expect(childRect.left, greaterThanOrEqualTo(parentRect.right));
        expect(childRect.top, closeTo(parentRect.top, 1));
      } else {
        expect(childRect.right, lessThanOrEqualTo(parentRect.left));
      }
      final last = tester.getRect(find.text('Send to Krita'));
      expect(childRect.left, greaterThanOrEqualTo(0));
      expect(childRect.top, greaterThanOrEqualTo(0));
      expect(last.right, lessThanOrEqualTo(800));
      expect(last.bottom, lessThanOrEqualTo(600));
      await mouse.moveTo(tester.getCenter(find.text('Vibe Transfer')));
      await tester.pumpAndSettle();
      expect(child, findsOneWidget);
      await tester.tap(find.text('Vibe Transfer'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(MenuAnchor), findsNothing);
    });
  }

  testWidgets(
    'compact menu has details before img2img and quick parameter copy',
    (tester) async {
      LocalImageContextAction? selected;
      await tester.pumpWidget(
        _MenuHarness(
          isKritaConnected: false,
          onSelected: (value) => selected = value,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Copy Prompt'), findsOneWidget);
      expect(find.text('Copy Seed'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Place on canvas')).dy,
        greaterThan(tester.getTopLeft(find.text('Import Image Metadata')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Place on canvas')).dy,
        lessThan(tester.getTopLeft(find.text('Show in Folder')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Details')).dy,
        lessThan(tester.getTopLeft(find.text('Image2Image')).dy),
      );
      expect(find.text('Move to…'), findsNothing);
      expect(find.text('Send to Krita'), findsNothing);
      await tester.tap(find.text('Create & reference'));
      await tester.pumpAndSettle();
      expect(find.text('Send to Text to Image'), findsOneWidget);
      expect(find.text('Vibe Transfer'), findsOneWidget);
      final krita = tester.widget<MenuItemButton>(
        find.ancestor(
          of: find.text('Send to Krita'),
          matching: find.byType(MenuItemButton),
        ),
      );
      expect(krita.onPressed, isNull);
      await tester.tap(find.text('Send to Krita'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.tap(find.text('Vibe Transfer'));
      await tester.pumpAndSettle();
      expect(selected, LocalImageContextAction.sendToStyleTransfer);
      expect(find.byType(MenuAnchor), findsNothing);
    },
  );

  testWidgets('no metadata still permits details and file actions', (
    tester,
  ) async {
    LocalImageContextAction? selected;
    await tester.pumpWidget(
      _MenuHarness(
        hasImportableMetadata: false,
        hasPrompt: false,
        hasSeed: false,
        isKritaConnected: true,
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Copy Prompt'), findsNothing);
    expect(find.text('Copy Seed'), findsNothing);
    expect(find.text('Import Image Metadata'), findsNothing);
    await tester.tap(find.text('File actions'));
    await tester.pumpAndSettle();
    expect(find.text('Move to…'), findsOneWidget);
    expect(find.text('Copy to…'), findsOneWidget);
    await tester.tap(find.text('Move to…'));
    await tester.pumpAndSettle();
    expect(selected, LocalImageContextAction.moveTo);
  });

  testWidgets('details closes the menu and returns the viewer action', (
    tester,
  ) async {
    LocalImageContextAction? selected;
    await tester.pumpWidget(
      _MenuHarness(
        isKritaConnected: true,
        position: const Offset(790, 590),
        onSelected: (value) => selected = value,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.text('Details'));
    expect(rect.right, lessThanOrEqualTo(800));
    expect(rect.bottom, lessThanOrEqualTo(600));
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(selected, LocalImageContextAction.details);
    expect(find.byType(MenuAnchor), findsNothing);
  });

  testWidgets(
    'plain image can be placed on canvas and returns its own action',
    (tester) async {
      LocalImageContextAction? selected;
      await tester.pumpWidget(
        _MenuHarness(
          hasImportableMetadata: false,
          isKritaConnected: false,
          onSelected: (action) => selected = action,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Place on canvas'));
      await tester.pumpAndSettle();
      expect(selected, LocalImageContextAction.placeOnCanvas);
      expect(find.byType(MenuAnchor), findsNothing);
    },
  );
  testWidgets('running generation disables place on canvas', (tester) async {
    await tester.pumpWidget(
      const _MenuHarness(isKritaConnected: false, canPlaceOnCanvas: false),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final button = tester.widget<MenuItemButton>(
      find.ancestor(
        of: find.text('Place on canvas'),
        matching: find.byType(MenuItemButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}

class _MenuHarness extends StatelessWidget {
  const _MenuHarness({
    this.hasImportableMetadata = true,
    this.hasPrompt = true,
    this.hasSeed = true,
    required this.isKritaConnected,
    this.onSelected,
    this.position = const Offset(20, 20),
    this.canPlaceOnCanvas = true,
  });

  final Offset position;
  final bool canPlaceOnCanvas;
  final bool hasImportableMetadata;
  final bool hasPrompt;
  final bool hasSeed;
  final bool isKritaConnected;
  final ValueChanged<LocalImageContextAction?>? onSelected;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final selected = await LocalImageContextMenu.show(
                context,
                position: position,
                hasImportableMetadata: hasImportableMetadata,
                hasPrompt: hasPrompt,
                hasSeed: hasSeed,
                isKritaConnected: isKritaConnected,
                canPlaceOnCanvas: canPlaceOnCanvas,
              );
              onSelected?.call(selected);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }
}
