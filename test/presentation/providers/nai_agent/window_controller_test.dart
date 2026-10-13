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
      expect(controller.addedWidth, 388);
      expect(
        window.rect,
        Rect.fromLTWH(
          original.left,
          original.top,
          original.width + 388,
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
    'insufficient right-hand space leaves the window unchanged for overlay',
    () async {
      window.rect = const Rect.fromLTWH(1000, 40, 900, 700);
      final original = window.rect;
      await controller.toggle();
      expect(settings.panelExpanded, isTrue);
      expect(controller.docked, isFalse);
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
    expect(controller.docked, isFalse);
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
      expect(window.rect.right, -412);
    },
  );

  test(
    'missing and invalid work-area information falls back to overlay',
    () async {
      window.areas = [const Rect.fromLTWH(0, 0, 0, 0)];
      await controller.toggle();
      expect(settings.panelExpanded, isTrue);
      expect(controller.docked, isFalse);
      expect(window.writes, isEmpty);
    },
  );

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
    expect(window.rect.width, 1388);
    expect(window.writes.map((r) => r.width), [1388, 1000, 1388]);
  });

  test('resizing the dock uses the same original canvas width', () async {
    await controller.toggle();
    await controller.resizeDock(460);
    expect(window.rect.width, 1468);
    expect(window.rect.width - controller.addedWidth, 1000);
    await controller.close();
    expect(window.rect.width, 1000);
  });

  test(
    'a dock too wide for the work area restores the window and overlays',
    () async {
      window.areas = [const Rect.fromLTWH(0, 0, 1660, 1040)];
      await controller.toggle();
      await controller.resizeDock(720);
      expect(settings.panelExpanded, isTrue);
      expect(controller.docked, isFalse);
      expect(window.rect.width, 1000);
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

  test('unavailable window plugins fall back to overlay', () async {
    window.failSet = true;
    await controller.toggle();
    expect(settings.panelExpanded, isTrue);
    expect(controller.docked, isFalse);
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
