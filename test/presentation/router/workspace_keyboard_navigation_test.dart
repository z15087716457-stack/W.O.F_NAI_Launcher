import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/app.dart';
import 'package:nai_launcher/presentation/providers/theme_provider.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/background_refresh_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/wiring/resource_window_wiring.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_page.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/widgets/common/macos_app_integration.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_help_dialog.dart';
import '../../helpers/light_theme_contrast.dart'
    show InMemoryLocalStorageService;
import '../../helpers/app_logger_test_isolation.dart';

class _Completion extends GenerationCompletionWatcher {
  @override
  void build() {}
}

class _Refresh extends BackgroundRefreshNotifier {
  @override
  BackgroundRefreshState build() => const BackgroundRefreshState();
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory dir;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('workspace-navigation-');
    Hive.init(dir.path);
    for (final name in [
      StorageKeys.settingsBox,
      StorageKeys.historyBox,
      'shortcuts',
    ]) {
      await Hive.openBox(name);
    }
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  testWidgets(
    'Mac settings, search, return, and subsequent workspace shortcuts work through the router',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1600, 900);
      addTearDown(t.view.reset);
      const paths = [
        AppRoutes.generation,
        AppRoutes.localGallery,
        AppRoutes.onlineGallery,
        AppRoutes.settings,
        AppRoutes.statistics,
        AppRoutes.vibeLibrary,
        AppRoutes.preciseRefLibrary,
        AppRoutes.promptBlockLibrary,
        AppRoutes.styleExplore,
        AppRoutes.tagWiki,
      ];
      var settingsPage = SettingsPageId.overview;
      final router = GoRouter(
        initialLocation: AppRoutes.generation,
        routes: [
          StatefulShellRoute(
            navigatorContainerBuilder: (_, shell, children) =>
                MainShell(navigationShell: shell, children: children),
            builder: (_, __, shell) => shell,
            branches: [
              for (final path in paths)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: path,
                      builder: (context, _) => path == AppRoutes.settings
                          ? SettingsPage(
                              data: SettingsFixture.view(page: settingsPage),
                              actions: SettingsActions.none,
                            )
                          : Scaffold(
                              body: Column(
                                children: [
                                  Text(path),
                                  const TextField(),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.settings),
                                    child: const Text('test entry settings'),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            InMemoryLocalStorageService(),
          ),
          appRouterProvider.overrideWithValue(router),
          nativeResourceWindowsProvider.overrideWithValue(false),
          generationCompletionWatcherProvider.overrideWith(_Completion.new),
          backgroundRefreshNotifierProvider.overrideWith(_Refresh.new),
          kritaBridgeNotifierProvider.overrideWith(
            (_) => KritaBridgeNotifier(),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        ],
      );
      Future<void> settle() async {
        await t.pump();
        await t.pump(const Duration(milliseconds: 420));
        await t.pump();
      }

      String route() => router.routerDelegate.currentConfiguration.uri.path;
      Future<void> press(LogicalKeyboardKey key, {bool cmd = false}) async {
        if (cmd) {
          await t.sendKeyDownEvent(
            LogicalKeyboardKey.metaLeft,
            platform: 'macos',
          );
        }
        await t.sendKeyEvent(key, platform: 'macos');
        if (cmd) {
          await t.sendKeyUpEvent(
            LogicalKeyboardKey.metaLeft,
            platform: 'macos',
          );
        }
        await settle();
      }

      Future<void> nativeSettings() async {
        await t.binding.defaultBinaryMessenger.handlePlatformMessage(
          macOSAppMenuChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('openSettings'),
          ),
          (_) {},
        );
        await settle();
        expect(route(), AppRoutes.settings);
      }

      try {
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const NAILauncherApp(),
          ),
        );
        await settle();
        await press(LogicalKeyboardKey.digit3, cmd: true);
        expect(route(), AppRoutes.localGallery);
        await nativeSettings();
        await press(LogicalKeyboardKey.keyF, cmd: true);
        final search = find
            .descendant(
              of: find.byType(SettingsPage),
              matching: find.byType(EditableText),
            )
            .hitTestable()
            .first;
        await t.enterText(search, 'canvas');
        await settle();
        await press(LogicalKeyboardKey.escape);
        expect(route(), AppRoutes.settings);
        expect(t.widget<EditableText>(search).controller.text, isEmpty);
        await press(LogicalKeyboardKey.escape);
        expect(route(), AppRoutes.localGallery);
        // Simulate the missing key-up following an AppKit key equivalent. Only
        // the actual modifier flags and pressed trigger define a Command shortcut.
        await t.sendKeyDownEvent(LogicalKeyboardKey.comma, platform: 'macos');
        await nativeSettings();
        await press(LogicalKeyboardKey.numpad1, cmd: true);
        expect(route(), AppRoutes.generation);
        await press(LogicalKeyboardKey.digit8, cmd: true);
        expect(route(), AppRoutes.tagWiki);
        await press(LogicalKeyboardKey.slash, cmd: true);
        expect(find.byType(ShortcutHelpDialog), findsOneWidget);
        await press(LogicalKeyboardKey.escape);
        expect(find.byType(ShortcutHelpDialog), findsNothing);
        await t.sendKeyUpEvent(LogicalKeyboardKey.comma, platform: 'macos');
        await nativeSettings();
        // Clicking outside a field may return focus to the shell's shortcut anchor.
        final shellAnchor = find
            .descendant(
              of: find.byType(MainShell),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Focus &&
                    w.focusNode?.debugLabel == 'ShortcutFocusAnchor',
              ),
            )
            .first;
        t.widget<Focus>(shellAnchor).focusNode!.requestFocus();
        await settle();
        await press(LogicalKeyboardKey.escape);
        expect(route(), AppRoutes.tagWiki);
        final oldTheme = container.read(themeNotifierProvider);
        await t.sendKeyDownEvent(
          LogicalKeyboardKey.shiftLeft,
          platform: 'macos',
        );
        await press(LogicalKeyboardKey.keyT, cmd: true);
        await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft, platform: 'macos');
        expect(container.read(themeNotifierProvider), isNot(oldTheme));
        settingsPage = SettingsPageId.agent;
        await nativeSettings();
        await t.tap(find.byKey(const Key('agent-tab-instructions')));
        await settle();
        final draft = find.byKey(const Key('agent-global'));
        await t.ensureVisible(draft);
        await t.enterText(draft, 'unsaved local fixture');
        await settle();
        expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
        await press(LogicalKeyboardKey.digit3, cmd: true);
        expect(route(), AppRoutes.settings);
        expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
        await t.tap(find.byKey(const Key('confirm-cancel')));
        await settle();
        expect(route(), AppRoutes.settings);
        expect(find.text('unsaved local fixture'), findsOneWidget);
        await press(LogicalKeyboardKey.escape);
        expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
        await t.tap(find.byKey(const Key('confirm-ok')));
        await settle();
        expect(route(), AppRoutes.tagWiki);
        expect(t.takeException(), isNull);
      } finally {
        await t.pumpWidget(const SizedBox());
        container.dispose();
        router.dispose();
        await t.pump(const Duration(seconds: 10));
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
