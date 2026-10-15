import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';

class _Window extends NaiAgentWindowHost {
  Rect rect = const Rect.fromLTWH(100, 40, 1000, 700);
  List<Rect> areas = [const Rect.fromLTWH(0, 0, 1920, 1040)];
  bool isLocked = false, failSet = false;
  VoidCallback? onChanged;
  Completer<Rect>? delayedBounds;
  final writes = <Rect>[];
  @override
  Future<Rect> bounds() async =>
      delayedBounds == null ? rect : await delayedBounds!.future;
  @override
  Future<bool> locked() async => isLocked;
  @override
  Future<List<Rect>> workAreas() async => areas;
  @override
  Future<void> setBounds(Rect value) async {
    if (failSet) throw PlatformException(code: 'unavailable');
    writes.add(value);
    rect = value;
    onChanged?.call();
  }

  @override
  void watch(VoidCallback onChanged) => this.onChanged = onChanged;
  @override
  void stopWatching() => onChanged = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Window window;
  late AgentSettings settings;
  late NaiAgentWindowController controller;
  bool failSave = false;
  setUp(() {
    window = _Window();
    settings = const AgentSettings();
    failSave = false;
    controller = NaiAgentWindowController(
      host: window,
      readSettings: () async => settings,
      saveExpanded: (expanded) async {
        if (failSave) throw StateError('save failed');
        settings = AgentSettings.fromJson({
          ...settings.toJson(),
          'panelExpanded': expanded,
        });
      },
    );
  });
  tearDown(() => controller.dispose());

  test(
    'opening extends only the right edge by the dock and handle width',
    () async {
      final original = window.rect;
      await controller.toggle();
      expect(settings.panelExpanded, isTrue);
      expect(controller.docked, isTrue);
      expect(controller.addedWidth, 528);
      expect(
        window.rect,
        Rect.fromLTWH(
          original.left,
          original.top,
          original.width + 528,
          original.height,
        ),
      );
      expect(window.rect.width - controller.addedWidth, original.width);
      await controller.close();
      expect(settings.panelExpanded, isFalse);
      expect(controller.docked, isFalse);
      expect(window.rect, original);
    },
  );

  test(
    'insufficient right-hand space keeps an internal dock without native growth',
    () async {
      window.rect = const Rect.fromLTWH(1000, 40, 900, 700);
      final original = window.rect;
      await controller.toggle();
      expect(settings.panelExpanded, isTrue);
      expect(controller.docked, isTrue);
      expect(window.rect, original);
      expect(window.writes, isEmpty);
      await controller.close();
      expect(window.writes, isEmpty);
    },
  );

  test('a maximized fullscreen or snapped window is never resized', () async {
    window.isLocked = true;
    await controller.toggle();
    expect(settings.panelExpanded, isTrue);
    expect(controller.docked, isTrue);
    expect(window.writes, isEmpty);
    await controller.close();
    expect(window.writes, isEmpty);
  });

  test(
    'the window monitor is selected rather than the primary display',
    () async {
      window.areas.add(const Rect.fromLTWH(-1920, 0, 1920, 1040));
      window.rect = const Rect.fromLTWH(-1800, 40, 1000, 700);
      await controller.toggle();
      expect(controller.docked, isTrue);
      expect(window.rect.left, -1800);
      expect(window.rect.right, -272);
    },
  );

  test('missing work-area information leaves the window unchanged', () async {
    window.areas = [const Rect.fromLTWH(0, 0, 0, 0)];
    await controller.toggle();
    expect(settings.panelExpanded, isTrue);
    expect(controller.docked, isTrue);
    expect(window.writes, isEmpty);
  });

  test('manual resizing is preserved when the panel closes', () async {
    await controller.toggle();
    window.rect = const Rect.fromLTWH(100, 40, 1250, 650);
    window.onChanged?.call();
    await controller.close();
    expect(window.rect, const Rect.fromLTWH(100, 40, 1250, 650));
    expect(window.writes, hasLength(1));
    expect(controller.docked, isFalse);
  });

  test('manual movement is not overwritten by restoring old bounds', () async {
    await controller.toggle();
    window.rect = window.rect.shift(const Offset(35, 20));
    final moved = window.rect;
    await controller.close();
    expect(window.rect, moved);
    expect(window.writes, hasLength(1));
  });

  test('maximizing while expanded discards the automatic restore', () async {
    await controller.toggle();
    window.isLocked = true;
    window.onChanged?.call();
    await controller.close();
    expect(window.writes, hasLength(1));
    expect(controller.docked, isFalse);
  });

  test('rapid toggles are serialized without stacking window growth', () async {
    await Future.wait([
      controller.toggle(),
      controller.toggle(),
      controller.toggle(),
    ]);
    expect(settings.panelExpanded, isTrue);
    expect(window.rect.width, 1528);
    expect(window.writes.map((r) => r.width), [1528, 1000, 1528]);
  });

  test(
    'partial right-hand space is used without exceeding the work area',
    () async {
      window.areas = [const Rect.fromLTWH(0, 0, 1400, 1040)];
      await controller.toggle();
      expect(window.rect.right, 1392);
      expect(controller.addedWidth, 292);
      expect(controller.docked, isTrue);
      await controller.close();
      expect(window.rect.width, 1000);
    },
  );

  test(
    'manual movement drops restoration ownership and preserves docking',
    () async {
      await controller.toggle();
      window.rect = window.rect.shift(const Offset(25, 0));
      window.onChanged?.call();
      await pumpEventQueue();
      expect(controller.addedWidth, 0);
      expect(controller.docked, isTrue);
      expect(settings.panelExpanded, isTrue);
      final manual = window.rect;
      await controller.close();
      expect(window.rect, manual);
    },
  );

  test(
    'manual resizing preserves docking before the panel is closed',
    () async {
      await controller.toggle();
      window.rect = const Rect.fromLTWH(100, 40, 1250, 650);
      window.onChanged?.call();
      await pumpEventQueue();
      expect(controller.docked, isTrue);
      expect(controller.addedWidth, 0);
      expect(settings.panelExpanded, isTrue);
      await controller.close();
      expect(window.rect.width, 1250);
    },
  );

  test(
    'failed preference persistence rolls back only owned window growth',
    () async {
      failSave = true;
      await expectLater(controller.toggle(), throwsStateError);
      expect(settings.panelExpanded, isFalse);
      expect(window.rect.width, 1000);
      expect(controller.docked, isFalse);
    },
  );

  test('unavailable window plugins keep the internal dock', () async {
    window.failSet = true;
    await controller.toggle();
    expect(settings.panelExpanded, isTrue);
    expect(controller.docked, isTrue);
    expect(window.rect.width, 1000);
  });

  test(
    'an expanded preference restored at startup does not shrink an unowned window',
    () async {
      settings = AgentSettings.fromJson({
        ...settings.toJson(),
        'panelExpanded': true,
      });
      await controller.close();
      expect(window.writes, isEmpty);
    },
  );

  test(
    'disposal during an async window query neither resizes nor saves',
    () async {
      window.delayedBounds = Completer<Rect>();
      final pending = controller.toggle();
      await pumpEventQueue();
      controller.dispose();
      window.delayedBounds!.complete(window.rect);
      await pending;
      expect(window.writes, isEmpty);
      expect(settings.panelExpanded, isFalse);
      controller = NaiAgentWindowController(
        host: null,
        readSettings: () async => settings,
        saveExpanded: (_) async {},
      );
    },
  );

  testWidgets(
    'desktop reveal sends scale geometry and respects reduced motion',
    (tester) async {
      const channel = MethodChannel('com.nailauncher/window_reveal');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'grow' ? true : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final adapter = NaiAgentDesktopWindowHost(readPixelRatio: () => 1.5);
      const original = Rect.fromLTWH(-100, 40, 1000, 700);
      const target = Rect.fromLTWH(-100, 40, 1528, 700);
      expect(await adapter.reveal(original, target), isTrue);
      expect(calls.single.arguments['pixelRatio'], 1.5);
      expect(calls.single.arguments['targetWidth'], 1528.0);
      expect(calls.single.arguments['durationMs'], 280.0);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await adapter.reveal(original, target);
      expect(calls.last.arguments['durationMs'], 0.0);
      await adapter.cancelReveal();
      expect(calls.last.method, 'cancel');
    },
  );

  testWidgets(
    'desktop adapter leaves maximized fullscreen and snapped states alone',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var lockedMethod = 'isMaximized';
      final calls = <String>[];
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          calls.add(call.method);
          return call.method == 'isDocked'
              ? (lockedMethod == 'isDocked' ? 1 : 0)
              : call.method == lockedMethod;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          null,
        ),
      );
      for (final method in ['isMaximized', 'isFullScreen', 'isDocked']) {
        lockedMethod = method;
        calls.clear();
        expect(await NaiAgentDesktopWindowHost().locked(), isTrue);
        expect(calls, contains(method));
        expect(calls, isNot(contains('setBounds')));
        expect(calls, isNot(contains('unmaximize')));
      }
    },
  );
  testWidgets(
    'monitor-local DPI coordinates are converted to window logical coordinates',
    (tester) async {
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetDevicePixelRatio);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('screen_retriever'),
        (_) async => {
          'displays': [
            {
              'id': 1,
              'size': {'width': 960.0, 'height': 540.0},
              'visiblePosition': {'x': -960.0, 'y': 0.0},
              'visibleSize': {'width': 960.0, 'height': 540.0},
              'scaleFactor': 2.0,
            },
          ],
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('screen_retriever'),
          null,
        ),
      );
      expect(
        await NaiAgentDesktopWindowHost(readPixelRatio: () => 1.5).workAreas(),
        [const Rect.fromLTWH(-1280, 0, 1280, 720)],
      );
    },
  );
}
