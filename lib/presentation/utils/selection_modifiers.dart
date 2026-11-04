import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../core/utils/keyboard_modifier_utils.dart';

/// 按下指针那一刻的修饰键。
///
/// 点击回调在抬起时才执行，这时再读 [HardwareKeyboard]，⌘ / Ctrl、⇧ 可能已经比鼠标键先松开，
/// 修饰键点击就成了普通点击。引擎发指针事件之前会先按事件上的修饰键同步键盘状态，按下那一刻
/// 读到的是准的。
///
/// 用法：控件的 initState 里调 [ensureInstalled]，点击回调里读 [selection]、[shift]。
abstract final class PointerDownModifiers {
  static bool _installed = false;
  static bool _selection = false;
  static bool _shift = false;

  /// 装上全局指针路由；重复调用只装一次。
  static void ensureInstalled() {
    if (_installed) return;
    _installed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_record);
  }

  static void _record(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    _selection = isControlOrCommandPressed();
    _shift = HardwareKeyboard.instance.isShiftPressed;
  }

  /// 最近一次按下时，多选用的修饰键（见 [isControlOrCommandPressed]）是否按着。
  static bool get selection => _selection;

  /// 最近一次按下时 ⇧ 是否按着。
  static bool get shift => _shift;
}
