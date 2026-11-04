import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Uses Command on macOS and Control everywhere else.
bool isPrimarySelectionModifierPressed({
  HardwareKeyboard? keyboard,
  TargetPlatform? platform,
}) {
  final resolvedKeyboard = keyboard ?? HardwareKeyboard.instance;
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  return resolvedPlatform == TargetPlatform.macOS
      ? resolvedKeyboard.isMetaPressed
      : resolvedKeyboard.isControlPressed;
}

/// 快捷键的主修饰键：macOS 上是 ⌘，而且没按 Control（⌃⌘F 是系统的全屏键，不算 ⌘F）；其他平台是 Ctrl。
bool isPrimaryShortcutModifierPressed({
  HardwareKeyboard? keyboard,
  TargetPlatform? platform,
}) {
  final resolvedKeyboard = keyboard ?? HardwareKeyboard.instance;
  return (platform ?? defaultTargetPlatform) == TargetPlatform.macOS
      ? resolvedKeyboard.isMetaPressed && !resolvedKeyboard.isControlPressed
      : resolvedKeyboard.isControlPressed;
}

/// macOS 上按着 ⌘ 或 Control：这时的字母键是组合键（⌘Q 退出、⌘W 关窗口、⌃⌘F 全屏……），
/// 处理裸键（F、Q、工具字母）的地方先用它排除，留给系统菜单。其他平台总是 false，照原来的判断走。
bool isMacChordModifierPressed({
  HardwareKeyboard? keyboard,
  TargetPlatform? platform,
}) {
  final resolvedKeyboard = keyboard ?? HardwareKeyboard.instance;
  return (platform ?? defaultTargetPlatform) == TargetPlatform.macOS &&
      (resolvedKeyboard.isMetaPressed || resolvedKeyboard.isControlPressed);
}

/// 「Ctrl 或 ⌘ 都算」的写法按平台收紧：macOS 上只认 ⌘（不带 Control，⌃⌘F 是系统全屏），
/// 其他平台照旧 Ctrl 和 Win 键都算。
bool isControlOrCommandPressed({
  HardwareKeyboard? keyboard,
  TargetPlatform? platform,
}) {
  final resolvedKeyboard = keyboard ?? HardwareKeyboard.instance;
  return (platform ?? defaultTargetPlatform) == TargetPlatform.macOS
      ? resolvedKeyboard.isMetaPressed && !resolvedKeyboard.isControlPressed
      : resolvedKeyboard.isControlPressed || resolvedKeyboard.isMetaPressed;
}

/// 主修饰键本身：macOS 上是 ⌘，其他平台是 Ctrl（同 [isPrimarySelectionModifierPressed]）。
bool isPrimaryModifierKey(LogicalKeyboardKey key, {TargetPlatform? platform}) =>
    (platform ?? defaultTargetPlatform) == TargetPlatform.macOS
    ? key == LogicalKeyboardKey.metaLeft || key == LogicalKeyboardKey.metaRight
    : key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight;

/// 列表里的「删除」键：Delete；macOS 上再加 ⌘⌫（同访达「移到废纸篓」，Mac 笔记本上 Delete 要按 fn+⌫）。
bool isListDeleteKey(
  KeyEvent event, {
  HardwareKeyboard? keyboard,
  TargetPlatform? platform,
}) {
  if (event.logicalKey == LogicalKeyboardKey.delete) return true;
  return (platform ?? defaultTargetPlatform) == TargetPlatform.macOS &&
      event.logicalKey == LogicalKeyboardKey.backspace &&
      isPrimaryShortcutModifierPressed(keyboard: keyboard, platform: platform);
}
