import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/services/app_image_cache.dart';
import '../../core/utils/desktop_platform.dart';

/// macOS 上按住 Control 单击当右键（次键）用，和系统、浏览器一样。
///
/// Flutter 在 macOS 上把 Control+单击报成主键按下，右键菜单收不到，单击和多选反而会响应。
/// 这里在指针事件进框架的入口统一改：主键按下时按着 Control、没按 ⌘，这一下就改成次键，
/// 同一个指针后面的移动、抬起、取消跟着改。按下之后才按 Control 不算；滚轮、触控板手势、
/// 悬停都不动。
///
/// 平台和修饰键由调用方传进来，这里不读全局状态。
class ControlClickMapper {
  final Set<int> _secondaryPointers = {};

  PointerEvent map(
    PointerEvent event, {
    required bool macOS,
    required bool control,
    required bool command,
  }) {
    if (event is PointerDownEvent) {
      if (!macOS || !control || command || event.buttons != kPrimaryButton) {
        return event;
      }
      _secondaryPointers.add(event.pointer);
      return event.copyWith(buttons: kSecondaryButton);
    }
    final follows =
        event is PointerMoveEvent ||
        event is PointerUpEvent ||
        event is PointerCancelEvent;
    if (!follows || !_secondaryPointers.contains(event.pointer)) return event;
    if (event is! PointerMoveEvent) _secondaryPointers.remove(event.pointer);
    if (event.buttons & kPrimaryButton == 0) return event;
    return event.copyWith(
      buttons: event.buttons & ~kPrimaryButton | kSecondaryButton,
    );
  }
}

/// 所有指针事件先过 [ControlClickMapper] 再交给框架。
mixin ControlClickBinding on GestureBinding {
  final ControlClickMapper _controlClick = ControlClickMapper();

  @override
  void handlePointerEvent(PointerEvent event) {
    final keyboard = HardwareKeyboard.instance;
    super.handlePointerEvent(
      _controlClick.map(
        event,
        macOS: usesMacOSConventions,
        control: keyboard.isControlPressed,
        command: keyboard.isMetaPressed,
      ),
    );
  }
}

/// 应用用的 binding：[WidgetsFlutterBinding] 加上 [ControlClickBinding]，图片缓存换成
/// [AppImageCache]（[AppImageCacheBinding]：窗口藏着时也认得屏幕上的图）。
class AppWidgetsBinding extends WidgetsFlutterBinding
    with ControlClickBinding, AppImageCacheBinding {
  static AppWidgetsBinding? _instance;

  /// 在 main 里代替 [WidgetsFlutterBinding.ensureInitialized]，最先调用。
  static WidgetsBinding ensureInitialized() =>
      _instance ??= AppWidgetsBinding();
}
