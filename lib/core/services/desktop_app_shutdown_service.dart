import 'dart:async';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../database/database_manager.dart';
import '../utils/app_logger.dart';

/// 桌面应用统一退出入口。
///
/// 更新安装和托盘退出都必须先释放数据库、托盘与窗口资源，避免直接
/// `exit` 留下未刷新的日志或 Windows 文件锁。
class DesktopAppShutdownService {
  DesktopAppShutdownService._();

  static Future<void>? _shutdownFuture;
  static final _cleanups = <Future<void> Function()>{};

  /// Register owned background work that must finish before stores are closed.
  static void Function() registerCleanup(Future<void> Function() cleanup) {
    _cleanups.add(cleanup);
    return () => _cleanups.remove(cleanup);
  }

  static Future<void> prepareBackgroundShutdown() async {
    for (final cleanup in List.of(_cleanups)) {
      try {
        await cleanup();
      } catch (error) {
        AppLogger.w('Background shutdown failed: $error', 'AppShutdown');
      }
    }
  }

  static Future<void> shutdownAndExit(int code) {
    return _shutdownFuture ??= _performShutdown(code);
  }

  static Future<void> _performShutdown(int code) async {
    AppLogger.i('Application shutdown started', 'AppShutdown');
    await prepareBackgroundShutdown();

    try {
      await DatabaseManager.instance.dispose();
      AppLogger.i('Database closed successfully', 'AppShutdown');
    } catch (error) {
      AppLogger.w('Database shutdown skipped or failed: $error', 'AppShutdown');
    }

    try {
      await Hive.close();
      AppLogger.i('Hive boxes closed successfully', 'AppShutdown');
    } catch (error) {
      AppLogger.w('Hive shutdown skipped or failed: $error', 'AppShutdown');
    }

    if (Platform.isWindows) {
      try {
        await trayManager.destroy();
      } catch (error) {
        AppLogger.w('Tray shutdown failed: $error', 'AppShutdown');
      }

      try {
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
      } catch (error) {
        AppLogger.w('Window shutdown failed: $error', 'AppShutdown');
      }
    }

    AppLogger.i('Application shutdown completed', 'AppShutdown');
    await AppLogger.flush();
    exit(code);
  }
}
