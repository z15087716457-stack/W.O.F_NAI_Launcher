import 'dart:async';
import 'package:nai_launcher/presentation/wiring/resource_window_wiring.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/app.dart';
import 'package:nai_launcher/main.dart' show AppWindowListener;
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_windows_host.dart';
import 'package:nai_launcher/core/services/desktop_app_shutdown_service.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/background_refresh_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_logger_test_isolation.dart';
import 'helpers/light_theme_contrast.dart' show InMemoryLocalStorageService;

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

class _ExitCaptured {
  const _ExitCaptured(this.code);
  final int code;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final calls = <MethodCall>[];
  late Directory directory;

  setUp(() async {
    calls.clear();
    directory = await Directory.systemTemp.createTemp('quit_shortcut_');
    Hive.init(directory.path);
    final box = await Hive.openBox(StorageKeys.settingsBox);
    await box.put('test-draft', 'kept');
    for (final channel in [
      'window_manager',
      'tray_manager',
      'com.nailauncher/resource_window_native',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (call) async {
            calls.add(call);
            return null;
          });
    }
  });

  tearDown(() async {
    for (final channel in [
      'window_manager',
      'tray_manager',
      'com.nailauncher/resource_window_native',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), null);
    }
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('ordinary window close still hides to tray', () async {
    await AppWindowListener(nativeResourceWindows: true).onWindowClose();
    expect(calls.map((call) => call.method), [
      'setPreventClose',
      'hide',
      'closeAll',
    ]);
  });

  test(
    'ordinary close hides before a resource window finishes cleanup',
    () async {
      final release = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.nailauncher/resource_window_native'),
            (call) async {
              calls.add(call);
              await release.future;
              return null;
            },
          );
      final closing = AppWindowListener(
        nativeResourceWindows: true,
      ).onWindowClose();
      await Future<void>.delayed(Duration.zero);
      expect(calls.map((call) => call.method), [
        'setPreventClose',
        'hide',
        'closeAll',
      ]);
      release.complete();
      await closing;
    },
  );

  test(
    'macOS window close hides without the Windows resource window channel',
    () async {
      // 没有原生资源小窗时不调 closeAll：Mac 上那个通道没有实现，一调就抛错，窗口就藏不起来
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.nailauncher/resource_window_native'),
            null,
          );
      await AppWindowListener(nativeResourceWindows: false).onWindowClose();
      expect(calls.map((call) => call.method), ['setPreventClose', 'hide']);
    },
  );

  test('by default only Windows closes native resource windows', () async {
    await AppWindowListener().onWindowClose();
    expect(calls.map((call) => call.method), [
      'setPreventClose',
      'hide',
      if (Platform.isWindows) 'closeAll',
    ]);
  });

  testWidgets(
    'native Agent button follows workspace routes and toggles the existing dock controller',
    (t) async {
      SharedPreferences.setMockInitialValues({'auto_login': false});
      const chrome = MethodChannel('com.wof.naiStudio/window_chrome');
      final published = <MethodCall>[];
      final messenger = t.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(chrome, (call) async {
        published.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(chrome, null));
      const viewer = '${AppRoutes.generation}/viewer';
      final router = GoRouter(
        routes: [
          for (final path in [
            AppRoutes.home,
            AppRoutes.generation,
            AppRoutes.styleExplore,
            viewer,
            AppRoutes.settings,
          ])
            GoRoute(path: path, builder: (_, _) => const SizedBox()),
        ],
      );
      addTearDown(router.dispose);
      var expanded = false;
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
          naiAgentUiPreferencesProvider.overrideWith(
            (_) => NaiAgentUiPreferences(),
          ),
          naiAgentWindowControllerProvider.overrideWith(
            (ref) => NaiAgentWindowController(
              host: null,
              readSettings: () async => AgentSettings(panelExpanded: expanded),
              saveExpanded: (value) async {
                expanded = value;
                ref
                    .read(naiAgentUiPreferencesProvider)
                    .replace(AgentSettings(panelExpanded: value));
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const NAILauncherApp(),
        ),
      );
      await t.pumpAndSettle();
      for (final (path, showsAgent) in [
        (AppRoutes.home, true),
        (AppRoutes.settings, false),
        (AppRoutes.generation, true),
        (viewer, false),
        (AppRoutes.styleExplore, true),
      ]) {
        router.go(path);
        await t.pumpAndSettle();
        expect(
          published.last.arguments['agent'],
          showsAgent ? 'NAI Agent' : null,
          reason: path,
        );
        final previous = expanded;
        await messenger.handlePlatformMessage(
          chrome.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('toggleAgent'),
          ),
          (_) {},
        );
        await t.pumpAndSettle();
        expect(expanded, showsAgent ? !previous : previous, reason: path);
        expect(
          container.read(naiAgentWindowControllerProvider).docked,
          expanded,
        );
        if (showsAgent) expect(published.last.arguments['expanded'], expanded);
      }
      await t.pumpWidget(const SizedBox());
      expect(t.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('root quit action waits for cleanup, closes stores and exits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(
      initialLocation: AppRoutes.generation,
      routes: [
        GoRoute(
          path: AppRoutes.generation,
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(
          InMemoryLocalStorageService(),
        ),
        appRouterProvider.overrideWithValue(router),
        nativeResourceWindowsProvider.overrideWithValue(false),
        generationCompletionWatcherProvider.overrideWith(_Completion.new),
        backgroundRefreshNotifierProvider.overrideWith(_Refresh.new),
        kritaBridgeNotifierProvider.overrideWith((_) => KritaBridgeNotifier()),
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
    final shortcuts = tester.widget<GlobalShortcuts>(
      find.byType(GlobalShortcuts),
    );
    expect(find.byType(FloatingResourceWindowsHost), findsOneWidget);
    expect(DefaultShortcuts.all[ShortcutIds.openResourceWindow], isEmpty);
    expect(
      DefaultShortcuts.getContext(ShortcutIds.openResourceWindow),
      ShortcutContext.global,
    );
    shortcuts.shortcuts[ShortcutIds.openResourceWindow]!();
    await tester.pump();
    expect(
      container.read(floatingResourceWindowsProvider).single.kind,
      FloatingResourceKind.gallery,
    );
    container
        .read(floatingResourceWindowsProvider.notifier)
        .close(container.read(floatingResourceWindowsProvider).single.id);
    await tester.pump();
    await tester.runAsync(() async {
      final cleanupStarted = Completer<void>();
      final release = Completer<void>();
      final unregister = DesktopAppShutdownService.registerCleanup(() async {
        cleanupStarted.complete();
        await release.future;
      });
      addTearDown(unregister);
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final exited = Completer<int>();
      runZonedGuarded(
        () {
          IOOverrides.runZoned(
            () => shortcuts.shortcuts[ShortcutIds.quitApp]!(),
            exit: (code) => throw _ExitCaptured(code),
          );
        },
        (error, stack) {
          if (error is _ExitCaptured) {
            exited.complete(error.code);
          } else {
            exited.completeError(error, stack);
          }
        },
      );
      final mac = Platform.isMacOS;
      await cleanupStarted.future;
      expect(cleanupStarted.isCompleted, isTrue);
      expect(exited.isCompleted, isFalse);
      if (mac) {
        expect(calls.map((call) => call.method), ['hide', 'destroy']);
      } else {
        expect(calls.any((call) => call.method == 'destroy'), isFalse);
      }
      release.complete();
      expect(await exited.future, 0);
      expect(Hive.isBoxOpen(StorageKeys.settingsBox), isFalse);
      expect(calls.map((call) => call.method), [
        if (mac || Platform.isWindows) ...['hide', 'destroy'],
        if (mac) ...['setPreventClose', 'destroy'],
      ]);
      expect(
        (await Hive.openBox(StorageKeys.settingsBox)).get('test-draft'),
        'kept',
      );
    });
    await tester.pumpWidget(const SizedBox());
  });
}
