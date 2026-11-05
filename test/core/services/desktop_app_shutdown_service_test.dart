import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/desktop_app_shutdown_service.dart';
import 'package:nai_launcher/main.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _ExitCaptured {
  const _ExitCaptured(this.code);
  final int code;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  test('all owners start cancelling before either finishes', () async {
    final first = Completer<void>();
    final second = Completer<void>();
    final calls = <String>[];
    addTearDown(
      DesktopAppShutdownService.registerCleanup(() async {
        calls.add('first:cancel');
        await first.future;
        calls.add('first:finished');
      }),
    );
    addTearDown(
      DesktopAppShutdownService.registerCleanup(() async {
        calls.add('second:cancel');
        await second.future;
        calls.add('second:finished');
      }),
    );
    var finished = false;
    final shuttingDown = DesktopAppShutdownService.prepareBackgroundShutdown()
        .then((_) => finished = true);
    expect(calls, ['first:cancel', 'second:cancel']);
    second.complete();
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    first.complete();
    await shuttingDown;
    expect(calls, [
      'first:cancel',
      'second:cancel',
      'second:finished',
      'first:finished',
    ]);
  });

  test('failed owner does not prevent another owner from draining', () async {
    final release = Completer<void>();
    var cancelled = false;
    addTearDown(
      DesktopAppShutdownService.registerCleanup(() {
        throw StateError('fixture cleanup failure');
      }),
    );
    addTearDown(
      DesktopAppShutdownService.registerCleanup(() async {
        cancelled = true;
        await release.future;
      }),
    );
    var finished = false;
    final shuttingDown = DesktopAppShutdownService.prepareBackgroundShutdown()
        .then((_) => finished = true);
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, isTrue);
    expect(finished, isFalse);
    release.complete();
    await shuttingDown;
  });

  test(
    'disposed owners unregister and each drain uses a stable snapshot',
    () async {
      final calls = <String>[];
      final removed = DesktopAppShutdownService.registerCleanup(() async {
        calls.add('disposed');
      });
      removed();
      void Function()? removeLate;
      addTearDown(() => removeLate?.call());
      addTearDown(
        DesktopAppShutdownService.registerCleanup(() async {
          calls.add('first');
          removeLate ??= DesktopAppShutdownService.registerCleanup(() async {
            calls.add('late');
          });
        }),
      );
      await DesktopAppShutdownService.prepareBackgroundShutdown();
      expect(calls, ['first']);
      await DesktopAppShutdownService.prepareBackgroundShutdown();
      expect(calls, ['first', 'first', 'late']);
    },
  );

  test(
    'draining waits for a critical startup write already in progress',
    () async {
      final release = Completer<void>();
      final calls = <String>[];
      final write = DesktopAppShutdownService.runCriticalStartupTask(
        'Fixture startup write',
        () async {
          calls.add('write started');
          await release.future;
          calls.add('write finished');
        },
      );
      final drain = DesktopAppShutdownService.prepareBackgroundShutdown().then((
        _,
      ) {
        calls.add('stores can close');
      });
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['write started']);
      release.complete();
      await Future.wait([write, drain]);
      expect(calls, ['write started', 'write finished', 'stores can close']);
    },
  );

  test(
    'full quit hides first, keeps stores until drained, then exits once',
    () async {
      final directory = await Directory.systemTemp.createTemp('app_quit_');
      Hive.init(directory.path);
      final box = await Hive.openBox(StorageKeys.settingsBox);
      final release = Completer<void>();
      final started = Completer<void>();
      final calls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          calls.add('window:${call.method}');
          return null;
        },
      );
      messenger.setMockMethodCallHandler(const MethodChannel('tray_manager'), (
        call,
      ) async {
        expect(Hive.isBoxOpen(StorageKeys.settingsBox), isFalse);
        calls.add('tray:${call.method}');
        return null;
      });
      addTearDown(() async {
        messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('tray_manager'),
          null,
        );
        await Hive.close();
        await directory.delete(recursive: true);
      });
      addTearDown(
        DesktopAppShutdownService.registerCleanup(() async {
          calls.add('owner:cancel');
          started.complete();
          await release.future;
          await box.put('draft', 'saved before closing');
          calls.add('owner:saved');
        }, name: 'Fixture owner'),
      );

      var exits = 0;
      final quit = IOOverrides.runZoned(
        () => DesktopAppShutdownService.shutdownAndExit(7),
        exit: (code) {
          exits++;
          calls.add('exit:$code');
          throw _ExitCaptured(code);
        },
      );
      final exited = expectLater(
        quit,
        throwsA(isA<_ExitCaptured>().having((e) => e.code, 'code', 7)),
      );
      await started.future;
      expect(DesktopAppShutdownService.isShuttingDown, isTrue);
      expect(DesktopAppShutdownService.shutdownAndExit(99), same(quit));
      expect(calls, ['window:hide', 'owner:cancel']);
      expect(Hive.isBoxOpen(StorageKeys.settingsBox), isTrue);

      // During real exit, neither the tray nor a late window event can reopen it
      // or write to stores that are about to close.
      var lateWriteStarted = false;
      await DesktopAppShutdownService.runCriticalStartupTask(
        'Late write',
        () async => lateWriteStarted = true,
      );
      expect(lateWriteStarted, isFalse);
      await AppTrayListener().onTrayIconMouseDown();
      AppTrayListener().onTrayIconRightMouseDown();
      await AppTrayListener().onTrayMenuItemClick(MenuItem(key: 'show'));
      final window = AppWindowListener();
      await window.onWindowClose();
      await window.onWindowMove();
      await window.onWindowResize();
      await WindowStateObserver().didChangeAppLifecycleState(
        AppLifecycleState.paused,
      );
      expect(calls, ['window:hide', 'owner:cancel']);

      release.complete();
      await exited;
      expect(exits, 1);
      expect(calls, [
        'window:hide',
        'owner:cancel',
        'owner:saved',
        'tray:destroy',
        'exit:7',
      ]);
      expect(Hive.isBoxOpen(StorageKeys.settingsBox), isFalse);
      expect(
        (await Hive.openBox(StorageKeys.settingsBox)).get('draft'),
        'saved before closing',
      );
      await WindowStateObserver().didChangeAppLifecycleState(
        AppLifecycleState.detached,
      );
      expect(calls.last, 'exit:7');
    },
  );
}
