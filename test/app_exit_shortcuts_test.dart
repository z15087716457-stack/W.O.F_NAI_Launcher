import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/app.dart';
import 'package:nai_launcher/main.dart' show AppWindowListener;
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
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_logger_test_isolation.dart';
import 'helpers/light_theme_contrast.dart' show InMemoryLocalStorageService;

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
    for (final channel in ['window_manager', 'tray_manager']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (call) async {
            calls.add(call);
            return null;
          });
    }
  });

  tearDown(() async {
    for (final channel in ['window_manager', 'tray_manager']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), null);
    }
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('ordinary window close still hides to tray', () async {
    await AppWindowListener().onWindowClose();
    expect(calls.map((call) => call.method), ['setPreventClose', 'hide']);
  });

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
        anlasBalanceWatcherProvider.overrideWith(_Balance.new),
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
      await Future<void>.delayed(Duration.zero);
      expect(cleanupStarted.isCompleted, isTrue);
      expect(exited.isCompleted, isFalse);
      expect(calls.any((call) => call.method == 'destroy'), isFalse);
      release.complete();
      expect(await exited.future, 0);
      expect(Hive.isBoxOpen(StorageKeys.settingsBox), isFalse);
      expect(calls.map((call) => call.method), [
        'destroy',
        'setPreventClose',
        'destroy',
      ]);
      expect(
        (await Hive.openBox(StorageKeys.settingsBox)).get('test-draft'),
        'kept',
      );
    });
    await tester.pumpWidget(const SizedBox());
  });
}
