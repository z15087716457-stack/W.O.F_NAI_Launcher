import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'desktop_platform.dart';

/// 主修饰键的组合键：macOS 上是 ⌘，其他平台是 Ctrl（同快捷键配置里的 ctrl，见 ShortcutParser）。
///
/// 只绑了 Ctrl 的 `SingleActivator(key, control: true)` 换成 `PrimaryActivator(key)`：Windows 上不变，
/// Mac 上按 ⌘ 触发、按 Control 不触发。平台在按键时才判断，可以写成 const。
class PrimaryActivator extends SingleActivator {
  const PrimaryActivator(
    super.trigger, {
    super.shift,
    super.alt,
    super.includeRepeats,
  });

  @override
  bool get control => !usesMacOSConventions;

  @override
  bool get meta => usesMacOSConventions;
}

/// 粘贴键：Ctrl+V，Windows 上 Win+V 也算（照旧）；macOS 上只认 ⌘V，
/// Control+V 留给文本框（Mac 文本框里是向下翻页）。
Map<ShortcutActivator, Intent> pasteShortcuts(Intent intent) => {
  const PrimaryActivator(LogicalKeyboardKey.keyV): intent,
  if (!usesMacOSConventions)
    const SingleActivator(LogicalKeyboardKey.keyV, meta: true): intent,
};

extension DesktopPrimaryModifier on HardwareKeyboard {
  bool get isPrimaryPressed =>
      usesMacOSConventions ? isMetaPressed : isControlPressed;

  bool get isPrimaryOrWindowsMetaPressed =>
      isPrimaryPressed || (!usesMacOSConventions && isMetaPressed);
}
