import 'dart:io';

import 'package:nai_launcher/core/utils/app_logger.dart';

/// AppLogger 测试隔离：把全局单例的日志目录指到本套件唯一的临时目录。
///
/// 根因（实测复现）：无 path_provider 绑定的测试里 AppLogger 日志目录
/// 回退 systemTemp，文件名只到秒级（test_YYYYMMDD_HHMMSS.log）——并发
/// 测试套件同秒初始化会追加写同一文件（行间交错乱码），初始化时的
/// 轮换清理（只留最新 2 个）还会删对方套件的活文件。
///
/// 用法：
/// ```dart
/// setUpAll(AppLoggerTestIsolation.setUp);
/// tearDownAll(AppLoggerTestIsolation.tearDown);
/// ```
class AppLoggerTestIsolation {
  static Directory? _dir;

  /// 建立隔离目录并注入覆盖。
  /// 非 async：createTempSync 同步完成，可直接喂给 setUpAll。
  static void setUp() {
    _dir = Directory.systemTemp.createTempSync('app_logger_isolated_');
    AppLogger.debugLogDirectoryOverride = _dir!.path;
  }

  /// 关闭文件输出并清理隔离目录。
  /// 先 setFileLoggingEnabled(false) 销毁 sink——Windows 下句柄未释放
  /// 删目录会抛 PathAccessException。即便销毁后，Windows 索引/杀毒可能
  /// 短暂持有新文件句柄（参考 reference_panel 测试的同款容错）：删目录
  /// 失败时短退避重试一次，仍失败则留空目录无害（系统 temp 会被 OS 回收）。
  static Future<void> tearDown() async {
    await AppLogger.setFileLoggingEnabled(false);
    AppLogger.debugLogDirectoryOverride = null;
    final dir = _dir;
    _dir = null;
    if (dir == null || !await dir.exists()) return;
    try {
      await dir.delete(recursive: true);
    } on PathAccessException {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
      } on PathAccessException {
        // Windows 句柄延迟释放，不影响断言结果
      }
    }
  }
}
