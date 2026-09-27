import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/app.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/background_refresh_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/theme_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/widgets/branding/brand_entry_scene.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_button.dart';
import 'package:nai_launcher/presentation/widgets/settings/studio_theme_picker.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nai_launcher/core/constants/app_version.dart';

import '../../helpers/light_theme_contrast.dart';

class _Balance extends AnlasBalanceWatcher {
  @override
  void build() {}
}

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
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'W.O.F NAI Studio',
      packageName: 'nai_launcher',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await AppVersion.initialize();
  });

  for (final theme in [GeistTheme.dark, GeistTheme.light]) {
    testWidgets('loading action stays readable on ${theme.brightness.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ThemedButton(
              isLoading: true,
              onPressed: () {},
              label: const Text('生成中'),
            ),
          ),
        ),
      );
      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final background = theme.filledButtonTheme.style!.backgroundColor!
          .resolve({WidgetState.disabled})!;
      final foreground = Color.alphaBlend(spinner.color!, background);
      final l1 = foreground.computeLuminance(),
          l2 = background.computeLuminance();
      expect(
        (l1 > l2 ? (l1 + .05) / (l2 + .05) : (l2 + .05) / (l1 + .05)),
        greaterThanOrEqualTo(3),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  test(
    'appearance survives disposed scopes and storage reopening; old settings remain intact',
    () async {
      await setUpTemporaryHive();
      var box = await Hive.openBox(StorageKeys.settingsBox);
      await box.putAll({
        StorageKeys.themeType: 8,
        'last_prompt': 'keep this draft',
      });
      final container = ProviderContainer();
      expect(container.read(themeNotifierProvider), Brightness.dark);
      await container
          .read(themeNotifierProvider.notifier)
          .setTheme(Brightness.light);
      container.dispose();
      await box.close();
      box = await Hive.openBox(StorageKeys.settingsBox);
      final reopened = ProviderContainer();
      addTearDown(reopened.dispose);
      expect(reopened.read(themeNotifierProvider), Brightness.light);
      // No listeners during the splash/router handoff must not reset appearance.
      await reopened.pump();
      expect(reopened.read(themeNotifierProvider), Brightness.light);
      await reopened.read(themeNotifierProvider.notifier).nextTheme();
      expect(box.get(StorageKeys.studioThemeMode), 'dark');
      expect(box.get(StorageKeys.themeType), 8);
      expect(box.get('last_prompt'), 'keep this draft');
    },
  );

  testWidgets(
    'root theme stays identical on login, kept-alive routes, overlays and shortcut switches',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // 登录页的字符场在“关闭动画”时只画静态一帧，pumpAndSettle 才能结束
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final storage = InMemoryLocalStorageService();
      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (_, _) => const WindowChromePage(
              child: BrandEntryScene(child: Text('entry')),
            ),
          ),
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              for (final path in [
                AppRoutes.generation,
                AppRoutes.localGallery,
                AppRoutes.promptBlockLibrary,
              ])
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: path,
                      builder: (_, _) => WindowChromePage(
                        child: Scaffold(key: ValueKey(path), body: Text(path)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, _) => WindowChromePage(
              child: Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(
                        content: SizedBox(
                          width: 420,
                          child: StudioThemePicker(),
                        ),
                      ),
                    ),
                    child: const Text('appearance'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          appRouterProvider.overrideWithValue(router),
          anlasBalanceWatcherProvider.overrideWith(_Balance.new),
          generationCompletionWatcherProvider.overrideWith(_Completion.new),
          backgroundRefreshNotifierProvider.overrideWith(_Refresh.new),
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => KritaBridgeNotifier(),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const NAILauncherApp(),
        ),
      );
      await tester.pumpAndSettle();

      void expectAppearance(Brightness brightness) {
        for (final element in tester.elementList(
          find.byType(Scaffold, skipOffstage: false),
        )) {
          final theme = Theme.of(element);
          expect(theme.brightness, brightness);
          expect(
            theme.scaffoldBackgroundColor,
            brightness == Brightness.dark
                ? const Color(0xFF111111)
                : Colors.white,
          );
          for (final surface in [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainer,
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ]) {
            expect(surface.r, surface.g);
            expect(surface.g, surface.b);
          }
        }
      }

      expectAppearance(Brightness.dark);
      await tester.tap(find.byKey(const Key('brand_appearance_toggle')));
      await tester.pumpAndSettle();
      expectAppearance(Brightness.light);
      for (final path in [
        AppRoutes.generation,
        AppRoutes.localGallery,
        AppRoutes.promptBlockLibrary,
        AppRoutes.generation,
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expectAppearance(Brightness.light);
        expect(
          find.byKey(const Key('window-caption-controls')),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(find.byKey(const Key('window-caption-controls')))
              .height,
          path == AppRoutes.localGallery
              ? 62
              : path == AppRoutes.promptBlockLibrary
              ? 64
              : 36,
        );
      }
      final shortcuts = tester.widget<GlobalShortcuts>(
        find.byType(GlobalShortcuts),
      );
      shortcuts.shortcuts[ShortcutIds.toggleTheme]!();
      await tester.pumpAndSettle();
      expectAppearance(Brightness.dark);
      router.go(AppRoutes.settings);
      await tester.pumpAndSettle();
      await tester.tap(find.text('appearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('studio_theme_light')));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(AlertDialog))).brightness,
        Brightness.light,
      );
      expect(storage.getStudioThemeMode(), 'light');
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();
      expectAppearance(Brightness.light);
      expect(tester.takeException(), isNull);
    },
  );
}
