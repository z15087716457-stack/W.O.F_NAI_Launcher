import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/shortcut_settings_panel.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_help_dialog.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Config extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault()
      .setCustomShortcut(ShortcutIds.navigateToGeneration, 'Ctrl+J')
      .setEnabled(ShortcutIds.quitApp, false);
}

class _DefaultConfig extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

Widget _host({
  Locale locale = const Locale('zh'),
  bool dark = false,
  double scale = 1,
  GoRouter? router,
  GlobalKey? capture,
  bool defaults = false,
}) {
  final theme = dark ? GeistTheme.dark : GeistTheme.light;
  Widget builder(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: RepaintBoundary(key: capture, child: child!),
  );
  return ProviderScope(
    overrides: [
      shortcutConfigNotifierProvider.overrideWith(
        defaults ? _DefaultConfig.new : _Config.new,
      ),
    ],
    child: router == null
        ? MaterialApp(
            locale: locale,
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: builder,
            home: const Scaffold(body: ShortcutHelpDialog()),
          )
        : MaterialApp.router(
            routerConfig: router,
            locale: locale,
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: builder,
          ),
  );
}

void main() {
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('localized search respects context and custom bindings', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ShortcutHelpDialog)),
    )!;
    final search = find.byKey(const Key('shortcut-help-search'));
    await tester.enterText(search, l10n.shortcut_action_navigate_to_generation);
    await tester.pumpAndSettle();
    expect(find.text('Ctrl+J'), findsOneWidget);
    expect(
      find.byKey(const Key('shortcut-help-item-${ShortcutIds.quitApp}')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('shortcut-context-gallery')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.shortcut_settings_no_matches), findsOneWidget);
    await tester.tap(find.byKey(const Key('shortcut-help-clear-search')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.shortcut_action_refresh_gallery), findsOneWidget);
    expect(
      find.byKey(
        const Key('shortcut-help-item-${ShortcutIds.navigateToGeneration}'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('shortcut-context-all')));
    await tester.enterText(search, 'ctrl+j');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut-help-list')),
        matching: find.text(l10n.shortcut_action_navigate_to_generation),
      ),
      findsOneWidget,
    );
    expect(find.text('Ctrl+J'), findsOneWidget);

    await tester.enterText(search, l10n.shortcut_action_quit_app);
    await tester.pumpAndSettle();
    expect(find.text(l10n.shortcut_settings_no_matches), findsOneWidget);
    await tester.enterText(search, l10n.vibeLibrary_title);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut-help-list')),
        matching: find.text(l10n.vibeLibrary_title),
      ),
      findsOneWidget,
    );
    expect(find.text('navigate_to_vibe_library'), findsNothing);
    for (final (id, name) in [
      (ShortcutIds.navigateToStyleExplore, l10n.nav_styleExplore),
      (ShortcutIds.navigateToPreciseRefLibrary, l10n.nav_preciseRefLibrary),
      (ShortcutIds.navigateToTagWiki, l10n.nav_tagWiki),
    ]) {
      await tester.enterText(search, name);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('shortcut-help-item-$id')), findsOneWidget);
      expect(find.text(id), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  for (final customize in [false, true]) {
    testWidgets('header action closes help customize=$customize', (
      tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => ShortcutHelpDialog.show(context),
                child: const Text('Open help'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) =>
                const Scaffold(body: Text('Settings route')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_host(router: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open help'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          Key(customize ? 'shortcut-help-customize' : 'shortcut-help-close'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShortcutHelpDialog), findsNothing);
      expect(
        find.byType(ShortcutSettingsPanel),
        customize ? findsOneWidget : findsNothing,
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        customize ? AppRoutes.settings : '/',
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final narrow in [false, true]) {
        testWidgets(
          'help layout ${locale.toLanguageTag()} dark=$dark narrow=$narrow',
          (tester) async {
            await tester.binding.setSurfaceSize(
              narrow ? const Size(360, 640) : const Size(1000, 800),
            );
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final capture = GlobalKey();
            await tester.pumpWidget(
              _host(
                locale: locale,
                dark: dark,
                scale: narrow ? 1.3 : 1,
                capture: capture,
                defaults: true,
              ),
            );
            await tester.pumpAndSettle();
            final l10n = AppLocalizations.of(
              tester.element(find.byType(ShortcutHelpDialog)),
            )!;
            expect(
              find.byKey(const Key('shortcut-help-customize')),
              findsOneWidget,
            );
            final lastFilter = find.byKey(
              const Key('shortcut-context-vibeDetail'),
            );
            final divider = find.byType(Divider);
            expect(
              tester.getTopLeft(divider).dy -
                  tester.getBottomLeft(lastFilter).dy,
              greaterThanOrEqualTo(16),
            );
            expect(tester.takeException(), isNull);

            if (Platform.environment['CAPTURE_SHORTCUT_HELP'] == '1' &&
                locale == const Locale('zh')) {
              await tester.runAsync(() async {
                final boundary =
                    capture.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final dir = Directory('.dart_tool/shortcut-help-captures')
                  ..createSync(recursive: true);
                File(
                  '${dir.path}/zh-${dark ? 'dark' : 'light'}-${narrow ? 'narrow' : 'desktop'}.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }

            // Exercise the longest category and search field at the same width.
            await tester.ensureVisible(lastFilter);
            await tester.tap(lastFilter);
            await tester.enterText(
              find.byKey(const Key('shortcut-help-search')),
              'not a shortcut',
            );
            await tester.pumpAndSettle();
            expect(
              find.text(l10n.shortcut_settings_no_matches),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
