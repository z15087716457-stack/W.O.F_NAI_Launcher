import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_context_menu.dart';

void main() {
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

  testWidgets('send button menu reuses the context menu send action group', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _MenuHarness(isKritaConnected: true, sendOnly: true),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final actions = tester
        .widgetList<PopupMenuItem<LocalImageContextAction>>(
          find.byWidgetPredicate(
            (widget) => widget is PopupMenuItem<LocalImageContextAction>,
          ),
        )
        .map((item) => item.value)
        .toList();

    expect(actions, const [
      LocalImageContextAction.sendToTextToImage,
      LocalImageContextAction.sendToImg2Img,
      LocalImageContextAction.sendToStyleTransfer,
      LocalImageContextAction.sendToPreciseReference,
      LocalImageContextAction.saveToPreciseRefLibrary,
      LocalImageContextAction.sendToKrita,
      LocalImageContextAction.upscale,
    ]);
    expect(find.text('Import Image Metadata'), findsNothing);
    expect(find.text('Show in Folder'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });
}

class _MenuHarness extends StatelessWidget {
  const _MenuHarness({
    this.hasImportableMetadata = true,
    this.hasPrompt = true,
    this.hasSeed = true,
    required this.isKritaConnected,
    this.sendOnly = false,
    this.onSelected,
    this.position = const Offset(20, 20),
  });

  final Offset position;
  final bool hasImportableMetadata;
  final bool hasPrompt;
  final bool hasSeed;
  final bool isKritaConnected;
  final bool sendOnly;
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
              final selected = sendOnly
                  ? await LocalImageContextMenu.showSendActions(
                      context,
                      position: position,
                      isKritaConnected: isKritaConnected,
                    )
                  : await LocalImageContextMenu.show(
                      context,
                      position: position,
                      hasImportableMetadata: hasImportableMetadata,
                      hasPrompt: hasPrompt,
                      hasSeed: hasSeed,
                      isKritaConnected: isKritaConnected,
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
