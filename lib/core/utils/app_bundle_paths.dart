import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_support_directory.dart';

/// 随应用发布的工具和 Agent 数据的位置。
///
/// Windows 包把 NAI Agent 的运行时（`tools/nai-agent`）、桥接客户端
/// （`tools/studio-bridge.exe`）放在 exe 旁边，Agent 的会话和设置（`agent-data`）也写在
/// exe 旁边。macOS 的可执行文件在 `xxx.app/Contents/MacOS` 里：随包的工具放
/// `Contents/Resources/tools`，写的数据放「应用支持」目录（和 Hive、数据库同一处），
/// 不往应用包里写（写了会破坏签名）。
abstract final class AppBundlePaths {
  static String? _applicationSupport;

  /// 启动时（`main.dart` 的 bootstrap 里）解析一次「应用支持」目录，之后同步取。
  static Future<void> init() async {
    _applicationSupport = (await getApplicationSupportDirectory()).path;
  }

  /// 「应用支持」目录；没 [init] 过（测试）就退回系统临时目录下的一个子目录。
  static String get applicationSupport =>
      _applicationSupport ??
      p.join(Directory.systemTemp.path, 'nai_launcher_app_support');

  /// 随包工具所在的目录。
  static String get toolsDirectory {
    final executableDirectory = p.dirname(Platform.resolvedExecutable);
    if (Platform.isMacOS) {
      return p.join(p.dirname(executableDirectory), 'Resources', 'tools');
    }
    return p.join(executableDirectory, 'tools');
  }

  /// NAI Agent 的会话和设置。
  static String get agentDataDirectory => Platform.isMacOS
      ? p.join(applicationSupport, 'agent-data')
      : p.join(p.dirname(Platform.resolvedExecutable), 'agent-data');

  /// macOS 应用包的路径（`xxx.app`）；不在应用包里运行（测试、命令行）时为 null。
  static String? get macOSBundle {
    if (!Platform.isMacOS) return null;
    final contents = p.dirname(p.dirname(Platform.resolvedExecutable));
    final bundle = p.dirname(contents);
    return bundle.endsWith('.app') ? bundle : null;
  }
}
