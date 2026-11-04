import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// 应用窗口现在看不看得见：藏到菜单栏 / 托盘、最小化、被完全挡住时为 false。
///
/// 别的代码只用这几样：[instance]、[isVisible]、`addListener` / `removeListener`，
/// 测试用 [debugSet]。值由下面的 [AppVisibilitySources] 汇总各个来源后写进来。
class AppVisibility extends ChangeNotifier {
  AppVisibility._();
  static final AppVisibility instance = AppVisibility._();
  bool _visible = true;
  bool get isVisible => _visible;
  @visibleForTesting
  void debugSet(bool visible) => _update(visible);
  void _update(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    notifyListeners();
  }
}

/// [AppVisibility] 的来源，汇总后写进 [AppVisibility.instance]（内部用，别的代码只读
/// [AppVisibility]）。
///
/// 看不见：藏到托盘 / 菜单栏、最小化、引擎报应用 hidden；macOS 上还有窗口被别的窗口
/// 完全挡住、在别的桌面（NSWindow.occlusionState 不含 visible）。只是失焦、还露在外面
/// 的算看得见。任一来源说看不见就算看不见：
/// - 我们自己调 hide / show 的地方打的标记：[markHidden] / [markShown]；
/// - window_manager 的事件：minimize / restore（还原成最大化时是 maximize）；Windows 上
///   还有 hide / show（WM_SHOWWINDOW，Mac 版插件不发这两个）；
/// - macOS：Runner 监听 NSWindow 的遮挡状态，经 [channel] 告诉 Dart
///   （`macos/Runner/MainFlutterWindow.swift`）；
/// - 引擎的应用生命周期 hidden / paused（实测 Mac 上藏到菜单栏、最小化时都会报 hidden）。
///
/// 防卡死：窗口得到焦点、收到指针或按键时当成看得见（[noteSeen]、[noteInput]），哪个
/// 来源漏报了“恢复”，动画也不会一直停着。Windows 上焦点和按键要先确认窗口真的露着（托盘
/// 右键会激活藏着的窗口，见 `_noteFocusOrKey`）；macOS 上指针和按键不清引擎和 Runner
/// 报的看不见（⌘M 那一下的按键会晚到，见 [noteInput]）。
class AppVisibilitySources with WindowListener, WidgetsBindingObserver {
  /// [platform] 默认取 [defaultTargetPlatform]：真机上就是系统；组件测试默认不是桌面，
  /// 不接 window_manager 和原生通道，要测哪条路径就传哪个平台。
  AppVisibilitySources({TargetPlatform? platform}) : _platform = platform;

  /// 应用里用的那一份；各个 runApp 根部的 `AppVisibilityScope`
  ///（`presentation/widgets/common/app_visibility_scope.dart`）把它接上。
  static final AppVisibilitySources instance = AppVisibilitySources();

  /// macOS Runner 的遮挡状态通道：Dart 调 `isVisible` 取当前值，原生在遮挡状态变化时
  /// 调 `visibilityChanged`（参数是 bool：看得见吗）。
  static const channel = MethodChannel('com.nailauncher/window_visibility');

  final TargetPlatform? _platform;
  TargetPlatform get _target => _platform ?? defaultTargetPlatform;
  bool get _mac => _target == TargetPlatform.macOS;
  bool get _windows => _target == TargetPlatform.windows;
  bool get _desktop => _mac || _windows;

  bool _attached = false;
  bool _hidden = false;
  bool _minimized = false;
  bool _occluded = false;
  bool _lifecycleHidden = false;

  /// 说看不见的消息（[markHidden]、hide、minimize、被挡住、生命周期 hidden）每来一条加一。
  /// 确认焦点 / 按键时等 window_manager 回答的那段时间里来了这种消息，答案就过时了。
  int _hiddenSignals = 0;

  /// 正在确认的那一轮（发起时的 [_hiddenSignals]）：同一轮里再来焦点、按键不重复问。
  int? _confirming;

  bool get _visible =>
      !(_hidden || _minimized || _occluded || _lifecycleHidden);

  /// 接上 window_manager、应用生命周期、按键和（macOS）原生遮挡通道。重复调用没有副作用。
  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    if (_desktop) windowManager.addListener(this);
    if (_mac) unawaited(_attachNative());
  }

  /// 测试用：断开所有来源，回到看得见。
  @visibleForTesting
  void detach() {
    if (_attached) {
      _attached = false;
      WidgetsBinding.instance.removeObserver(this);
      HardwareKeyboard.instance.removeHandler(_onKey);
      if (_desktop) windowManager.removeListener(this);
      if (_mac) channel.setMethodCallHandler(null);
    }
    _hiddenSignals++;
    _confirming = null;
    _update(() {
      _hidden = _minimized = _occluded = _lifecycleHidden = false;
    });
  }

  /// 我们要把窗口藏到托盘 / 菜单栏了（在调 `windowManager.hide()` 之前标记）。
  void markHidden() => _updateHidden(() => _hidden = true);

  /// 我们把窗口叫出来了（`windowManager.show()` 之后标记）：show 会顺带恢复最小化的窗口。
  void markShown() => _update(() {
    _hidden = false;
    _minimized = false;
    _occluded = false;
  });

  /// 窗口显然在屏幕上（得到焦点，见 `_noteFocusOrKey`）：清掉所有“看不见”的标记。
  void noteSeen() {
    if (_visible) return;
    _update(() {
      _hidden = _minimized = _occluded = _lifecycleHidden = false;
    });
  }

  /// 收到指针（`AppVisibilityScope`）或按键。
  ///
  /// macOS 上 ⌘M 最小化、关窗藏到菜单栏的那一下，快捷键松开（含引擎补发的修饰键）和
  /// 窗口缩下去时还在上面的鼠标，会比引擎报 hidden 晚几毫秒到：只说明窗口刚才还露着。
  /// 所以只清我们自己的标记和 window_manager 的最小化；引擎的生命周期和 Runner 的遮挡
  /// 等它们自己报恢复，漏报时窗口成为主窗口的 focus 照样全清。Windows 上按键先确认
  /// （见 `_noteFocusOrKey`），指针照旧全清。
  void noteInput() {
    if (_visible) return;
    if (!_mac) {
      noteSeen();
      return;
    }
    _update(() => _hidden = _minimized = false);
  }

  void _update(void Function() change) {
    change();
    AppVisibility.instance._update(_visible);
  }

  /// 说看不见的来源走这里：顺带让还没回来的确认作废（见 [_noteFocusOrKey]）。
  void _updateHidden(void Function() change) {
    _hiddenSignals++;
    _update(change);
  }

  bool _onKey(KeyEvent event) {
    if (_mac) {
      noteInput();
    } else {
      _noteFocusOrKey();
    }
    return false;
  }

  /// 得到焦点、收到按键（macOS 上的按键见 [noteInput]）。
  ///
  /// macOS 上藏起来或最小化的窗口成不了主窗口，focus 来了窗口就露着，照旧直接
  /// [noteSeen]。Windows 上托盘右键弹菜单时，tray_manager 先对主窗口 SetForegroundWindow，
  /// 藏在托盘里或最小化的窗口也会被激活、收到 focus；菜单关掉后它可能还是前台窗口，按键也
  /// 落在它身上。当成看得见就一直卡住（窗口没动，之后不会再来 hide / minimize），所以先问
  /// window_manager 窗口是不是可见、没最小化，是才算；问的时候来了说看不见的消息，答案过时，
  /// 丢掉。指针只会发给露着的窗口，不用问。
  void _noteFocusOrKey() {
    if (_visible) return;
    if (!_windows) {
      noteSeen();
      return;
    }
    final round = _hiddenSignals;
    if (_confirming == round) return;
    _confirming = round;
    unawaited(_confirmOnScreen(round));
  }

  Future<void> _confirmOnScreen(int round) async {
    var onScreen = false;
    try {
      final answers = await Future.wait([
        windowManager.isVisible(),
        windowManager.isMinimized(),
      ]);
      onScreen = answers[0] && !answers[1];
    } catch (_) {
      // 问不到就不算，等别的来源报恢复。
    }
    if (_confirming == round) _confirming = null;
    if (onScreen && round == _hiddenSignals) noteSeen();
  }

  @override
  void onWindowEvent(String eventName) {
    switch (eventName) {
      case 'minimize':
        _updateHidden(() => _minimized = true);
      // 最大化过的窗口从最小化还原：Windows 版 window_manager 只发 maximize、不发 restore。
      // 不只等随后的 focus：Windows 上 focus 要先确认（见 _noteFocusOrKey）
      case 'restore' || 'maximize':
        _update(() => _minimized = false);
      case 'hide':
        _updateHidden(() => _hidden = true);
      case 'show':
        _update(() => _hidden = false);
      case 'focus':
        _noteFocusOrKey();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // detached 不算：有的平台启动时先报它，那时窗口正要出来。
    final hidden =
        state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    if (hidden) _hiddenSignals++;
    _update(() => _lifecycleHidden = hidden);
  }

  Future<void> _attachNative() async {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'visibilityChanged') {
        _setOnScreen(call.arguments != false);
      }
      return null;
    });
    try {
      final visible = await channel.invokeMethod<bool>('isVisible');
      if (visible != null && _attached) _setOnScreen(visible);
    } on MissingPluginException {
      // 没有原生实现（旧 Runner）：只靠其他来源。
    } on PlatformException {
      // 同上。
    }
  }

  void _setOnScreen(bool visible) {
    if (!visible) _hiddenSignals++;
    _update(() {
      _occluded = !visible;
      // 原生说露在屏幕上，那就既没藏起来也没最小化（比如从程序坞点回来，没经过 Dart）。
      if (visible) _hidden = _minimized = false;
    });
  }
}
