import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// 支持的桌面平台：Windows 和 macOS。
///
/// 只判断宿主平台（窗口、托盘、代理这类原生能力）。界面上要按 Mac 习惯走的地方用
/// [usesMacOSConventions]。
bool get isSupportedDesktop => Platform.isWindows || Platform.isMacOS;

/// 界面按 macOS 习惯走：⌘ 当主修饰键、窗口按钮交给系统标题栏等。
///
/// 用 [defaultTargetPlatform] 而不是 `Platform.isMacOS`：真机上两者一样；组件测试里
/// [defaultTargetPlatform] 默认不是 macOS，原有测试照旧按 Windows 的行为跑，
/// 要测 macOS 分支用 `debugDefaultTargetPlatformOverride` 切过去。
bool get usesMacOSConventions => defaultTargetPlatform == TargetPlatform.macOS;
