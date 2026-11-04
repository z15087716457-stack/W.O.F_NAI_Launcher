// 窗口看不见时（藏到托盘 / 菜单栏、最小化、macOS 上被完全挡住）停掉全部动画，回来时恢复。
// Mac 和 Windows 两条路径分别测：Mac 靠 Runner 的遮挡通道 + window_manager 的最小化事件 +
// 应用生命周期，Windows 靠 window_manager 的 hide / show / minimize / restore 事件；两边都有
// 我们自己调 hide / show 时打的标记。
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/main.dart' show AppTrayListener, AppWindowListener;
import 'package:nai_launcher/presentation/widgets/common/app_visibility_scope.dart';
import 'package:tray_manager/tray_manager.dart';

import '../../helpers/app_logger_test_isolation.dart';

const _windowManager = MethodChannel('window_manager');

bool get _visible => AppVisibility.instance.isVisible;

/// 模拟原生发来的消息（window_manager 事件、Mac Runner 的遮挡通知）。
Future<void> _fromNative(String channel, MethodCall call) =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel,
          const StandardMethodCodec().encodeMethodCall(call),
          (_) {},
        );

Future<void> _windowEvent(String name) => _fromNative(
  _windowManager.name,
  MethodCall('onEvent', {'eventName': name}),
);

Future<void> _occlusion(bool visible) => _fromNative(
  AppVisibilitySources.channel.name,
  MethodCall('visibilityChanged', visible),
);

/// 一个一直在转的动画，用来看 ticker 有没有在要帧。
class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _c,
    child: const SizedBox(width: 10, height: 10),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  var nativeVisible = true;
  var nativeQueries = 0;

  // window_manager 怎么回答 isVisible / isMinimized（窗口这时真的露着吗）。
  // show() 也先问 isMinimized。
  var windowVisible = true;
  var windowMinimized = false;
  var windowQueries = 0;
  // 设了就等它完成再回答 isVisible：模拟答案还没回来时又来了别的事件。
  Completer<bool>? visibleAnswer;

  setUp(() {
    nativeVisible = true;
    nativeQueries = 0;
    windowVisible = true;
    windowMinimized = false;
    windowQueries = 0;
    visibleAnswer = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AppVisibilitySources.channel, (
      call,
    ) async {
      if (call.method != 'isVisible') return null;
      nativeQueries++;
      return nativeVisible;
    });
    messenger.setMockMethodCallHandler(_windowManager, (call) async {
      switch (call.method) {
        case 'isVisible':
          windowQueries++;
          return visibleAnswer?.future ?? windowVisible;
        case 'isMinimized':
          return windowMinimized;
      }
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AppVisibilitySources.channel, null);
    messenger.setMockMethodCallHandler(_windowManager, null);
    AppVisibility.instance.debugSet(true);
  });

  test('对外的接口：instance / isVisible / 监听 / debugSet', () {
    var calls = 0;
    void listener() => calls++;
    final v = AppVisibility.instance..addListener(listener);
    addTearDown(() => v.removeListener(listener));
    expect(v.isVisible, isTrue);
    v.debugSet(false);
    expect(v.isVisible, isFalse);
    v.debugSet(false);
    expect(calls, 1, reason: '没变不通知');
    v.debugSet(true);
    expect(calls, 2);
  });

  group('macOS', () {
    late AppVisibilitySources s;
    setUp(() => s = AppVisibilitySources(platform: TargetPlatform.macOS));
    tearDown(() => s.detach());

    test('启动时向 Runner 要当前遮挡状态', () async {
      nativeVisible = false;
      s.attach();
      await pumpEventQueue();
      expect(nativeQueries, 1);
      expect(_visible, isFalse);
    });

    test('被完全挡住 → 看不见；露出来 → 看得见', () async {
      s.attach();
      await pumpEventQueue();
      expect(_visible, isTrue);
      await _occlusion(false);
      expect(_visible, isFalse);
      await _occlusion(true);
      expect(_visible, isTrue);
    });

    test('⌘M 最小化 / 从程序坞恢复', () async {
      s.attach();
      await pumpEventQueue();
      await _windowEvent('minimize');
      expect(_visible, isFalse);
      await _windowEvent('restore');
      expect(_visible, isTrue);
    });

    test('藏到菜单栏的标记；从程序坞点回来（不经 Dart）靠遮挡通知恢复', () async {
      s.attach();
      await pumpEventQueue();
      s.markHidden();
      expect(_visible, isFalse);
      await _occlusion(false);
      expect(_visible, isFalse);
      await _occlusion(true);
      expect(_visible, isTrue);
    });

    test('应用生命周期 hidden 也算看不见（藏到菜单栏、最小化时系统会报）', () async {
      s.attach();
      await pumpEventQueue();
      s.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(_visible, isFalse);
      s.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(_visible, isTrue, reason: '失焦但还露在外面照常');
    });

    test('防卡死：得到焦点就当成看得见', () async {
      s.attach();
      await pumpEventQueue();
      s.markHidden();
      await _windowEvent('focus');
      expect(_visible, isTrue);
    });

    testWidgets('防卡死：收到按键就当成看得见', (tester) async {
      s.attach();
      await tester.pump();
      s.markHidden();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(_visible, isTrue);
    });

    // 按下 M 时菜单项已经开始最小化：引擎报 hidden、Runner 报被挡住，M 和 ⌘ 的松开
    // 晚几毫秒才到（实测 hidden 后 10 ms 就被当成又露出来，最小化期间微动接着跑）
    testWidgets('⌘M 最小化后晚到的按键松开，不清引擎报的 hidden', (tester) async {
      s.attach();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
      s.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(_visible, isFalse);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(_visible, isFalse);

      s.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(_visible, isTrue, reason: '从程序坞点回来，引擎自己报恢复');
    });

    testWidgets('⌘M 最小化后晚到的按键松开，不清 Runner 报的遮挡', (tester) async {
      s.attach();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyM);
      await _occlusion(false);
      await _windowEvent('minimize');
      expect(_visible, isFalse);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyM);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(_visible, isFalse);

      await _occlusion(true);
      expect(_visible, isTrue);
    });

    test('失焦不算看不见', () async {
      s.attach();
      await pumpEventQueue();
      await _windowEvent('blur');
      expect(_visible, isTrue);
    });

    // 点程序坞图标时 Runner 的 applicationShouldHandleReopen 直接 makeKeyAndOrderFront，
    // 不经 Dart：Runner 的遮挡通知、引擎的生命周期、window_manager 的 focus 都会来
    test('关窗藏到菜单栏，再从程序坞点回来', () async {
      s.attach();
      await pumpEventQueue();
      s.markHidden();
      await _occlusion(false);
      s.didChangeAppLifecycleState(AppLifecycleState.hidden);
      await _windowEvent('blur');
      expect(_visible, isFalse);

      await _occlusion(true);
      s.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _windowEvent('focus');
      expect(_visible, isTrue);
    });

    // 引擎源码记着：同屏 Cmd-Tab / 调度中心切回来时 occlusionState 会停在旧值
    // （flutter#155977），遮挡通知和生命周期都可能不来，这时只剩窗口成为主窗口的 focus
    test('从程序坞点回来时遮挡状态没更新：靠 focus 恢复，不用等确认', () async {
      s.attach();
      await pumpEventQueue();
      s.markHidden();
      await _occlusion(false);
      s.didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(_visible, isFalse);

      await _windowEvent('focus');
      expect(_visible, isTrue);
      expect(windowQueries, 0, reason: 'Mac 上藏着 / 最小化的窗口成不了主窗口');
    });
  });

  group('Windows', () {
    late AppVisibilitySources s;
    setUp(() => s = AppVisibilitySources(platform: TargetPlatform.windows));
    tearDown(() => s.detach());

    test('不碰 Mac 的遮挡通道', () async {
      s.attach();
      await pumpEventQueue();
      expect(nativeQueries, 0);
    });

    test('藏到托盘（WM_SHOWWINDOW）/ 叫出来', () async {
      s.attach();
      await _windowEvent('hide');
      expect(_visible, isFalse);
      await _windowEvent('show');
      expect(_visible, isTrue);
    });

    test('最小化 / 恢复', () async {
      s.attach();
      await _windowEvent('minimize');
      expect(_visible, isFalse);
      await _windowEvent('restore');
      expect(_visible, isTrue);
    });

    test('我们自己的 hide / show 标记', () async {
      s.attach();
      s.markHidden();
      expect(_visible, isFalse);
      s.markShown();
      expect(_visible, isTrue);
    });

    // 托盘右键弹菜单：tray_manager 先对主窗口 SetForegroundWindow 再 TrackPopupMenu，
    // 藏在托盘里的窗口被激活（WM_NCACTIVATE），window_manager 照样发 focus。菜单关掉后
    // 窗口还在托盘里，之后不会再来 hide
    test('托盘右键：藏着的窗口被激活，来的 focus 不算看得见', () async {
      s.attach();
      await _windowEvent('hide');
      windowVisible = false;
      await _windowEvent('focus');
      await pumpEventQueue();
      expect(_visible, isFalse);

      // 菜单「显示」：真的叫出来照常
      windowVisible = true;
      await _windowEvent('show');
      await _windowEvent('focus');
      await pumpEventQueue();
      expect(_visible, isTrue);
    });

    test('托盘右键：最小化的窗口被激活也不算看得见', () async {
      s.attach();
      await _windowEvent('minimize');
      windowMinimized = true;
      await _windowEvent('focus');
      await pumpEventQueue();
      expect(_visible, isFalse);
    });

    testWidgets('托盘菜单关掉后按键落在藏着的窗口上：不算看得见', (tester) async {
      s.attach();
      s.onWindowEvent('hide');
      windowVisible = false;
      s.onWindowEvent('focus');
      await tester.pump();
      expect(_visible, isFalse);
      final asked = windowQueries;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(windowQueries, greaterThan(asked), reason: '按键也先问窗口在不在');
      expect(_visible, isFalse);
    });

    test('防卡死：哪个来源漏报了恢复，窗口真的露着时 focus 照样算看得见', () async {
      s.attach();
      await _windowEvent('minimize');
      expect(_visible, isFalse);
      // 窗口已经还原，restore 没来
      await _windowEvent('focus');
      await pumpEventQueue();
      expect(_visible, isTrue);
    });

    test('最大化过的窗口从任务栏还原：只来 maximize 也算没最小化', () async {
      s.attach();
      await _windowEvent('maximize');
      await _windowEvent('minimize');
      expect(_visible, isFalse);
      // WM_SIZE 是 SIZE_MAXIMIZED：window_manager 只发 maximize、不发 restore
      await _windowEvent('maximize');
      expect(_visible, isTrue);
    });

    test('focus 的确认还没回来先来了 hide：看不见', () async {
      s.attach();
      await _windowEvent('minimize');
      final answer = visibleAnswer = Completer<bool>();
      await _windowEvent('focus');
      await _windowEvent('hide');
      // 问的时候窗口还露着，答案回来时已经藏到托盘了
      answer.complete(true);
      await pumpEventQueue();
      expect(_visible, isFalse);
    });
  });

  group('窗口监听器在 hide / show 时打标记', () {
    setUp(() => AppVisibilitySources.instance.detach());
    tearDown(() => AppVisibilitySources.instance.detach());

    test('关窗藏到托盘 → 看不见；托盘图标 / 菜单「显示」→ 看得见', () async {
      final listener = AppWindowListener(nativeResourceWindows: false);
      await listener.onWindowClose();
      expect(_visible, isFalse);

      final tray = AppTrayListener(shuttingDown: () => false);
      await tray.onTrayIconMouseDown();
      expect(_visible, isTrue);

      await listener.onWindowClose();
      await tray.onTrayMenuItemClick(MenuItem(key: 'show', label: 'Show'));
      expect(_visible, isTrue);
    });
  });

  group('AppVisibilityScope', () {
    late AppVisibilitySources s;
    setUp(() => s = AppVisibilitySources(platform: TargetPlatform.macOS));
    tearDown(() => s.detach());

    Future<void> pumpScope(WidgetTester tester) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppVisibilityScope(
          sources: s,
          child: const Center(child: _Spinner()),
        ),
      ),
    );

    testWidgets('看不见时动画停（不再要帧），回来后接着转', (tester) async {
      await pumpScope(tester);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await _occlusion(false);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      // 停下的那一帧里 ticker 已经要过下一帧，再走一帧之后就不再要了
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);

      await _occlusion(true);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('最小化、藏到托盘同样停；直接改 AppVisibility 也停', (tester) async {
      await pumpScope(tester);
      await tester.pump();
      await _windowEvent('minimize');
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await _windowEvent('restore');
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      s.markHidden();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      s.markShown();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      AppVisibility.instance.debugSet(false);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      AppVisibility.instance.debugSet(true);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('Windows：托盘右键激活藏着的窗口，动画不会重新转起来', (tester) async {
      final windows = AppVisibilitySources(platform: TargetPlatform.windows);
      addTearDown(windows.detach);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AppVisibilityScope(
            sources: windows,
            child: const Center(child: _Spinner()),
          ),
        ),
      );
      windows.onWindowEvent('hide');
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);

      windowVisible = false;
      windows.onWindowEvent('focus');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_visible, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('指针移进窗口就当成看得见', (tester) async {
      await pumpScope(tester);
      s.markHidden();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(5, 5));
      await mouse.moveTo(const Offset(20, 20));
      await tester.pump();
      expect(_visible, isTrue);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('⌘M 时窗口缩下去，还在上面的鼠标不算看得见', (tester) async {
      await pumpScope(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(5, 5));
      s.didChangeAppLifecycleState(AppLifecycleState.hidden);
      await _occlusion(false);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);

      await mouse.moveTo(const Offset(20, 20));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_visible, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  test('只给桌面平台接 window_manager', () async {
    final s = AppVisibilitySources(platform: TargetPlatform.android)..attach();
    addTearDown(s.detach);
    await _windowEvent('minimize');
    expect(_visible, isTrue);
    expect(nativeQueries, 0);
    expect(defaultTargetPlatform, isNot(TargetPlatform.macOS));
  });
}
