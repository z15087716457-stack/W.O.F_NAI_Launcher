import 'dart:async';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../database/database_manager.dart';
import '../utils/app_logger.dart';
import 'app_visibility.dart';

/// 桌面应用统一退出入口。
///
/// 先隐藏窗口并收尾后台任务，关闭存储和日志后统一退出。
class DesktopAppShutdownService {
  DesktopAppShutdownService._();

  static Future<void>? _shutdownFuture;
  static Future<void>? _exitFuture;
  static final _cleanups = <Future<void> Function(), String>{};

  static bool get isShuttingDown => _shutdownFuture != null;

  /// Register owned background work that must finish before stores are closed.
  static void Function() registerCleanup(
    Future<void> Function() cleanup, {
    String name = 'Background task',
  }) {
    _cleanups[cleanup] = name;
    return () => _cleanups.remove(cleanup);
  }

  static Future<void> prepareBackgroundShutdown() async {
    await Future.wait([
      for (final entry in List.of(_cleanups.entries))
        _cleanup(entry.value, entry.key),
    ]);
  }

  static Future<void> shutdownAndExit(int code) {
    return _exitFuture ??= _finishAndExit(code);
  }

  /// AppKit owns termination during a system request. Return after cleanup
  /// so the native delegate can reply to the original logout/quit request.
  static Future<void> prepareForTermination() =>
      _shutdownFuture ??= _performShutdown();

  static Future<void> _performShutdown() async {
    final elapsed = Stopwatch()..start();
    AppLogger.i('Application shutdown started', 'AppShutdown');
    if (Platform.isMacOS || Platform.isWindows) {
      AppVisibilitySources.instance.markHidden();
      await _cleanup('Window hide', windowManager.hide);
    }
    if (Platform.isMacOS) await _cleanup('Tray', trayManager.destroy);
    await prepareBackgroundShutdown();
    await _cleanup('Database', () => DatabaseManager.instance.dispose());
    await _cleanup('Hive', Hive.close);
    if (Platform.isWindows) {
      await _cleanup('Tray', trayManager.destroy);
    }
    AppLogger.i(
      'Application shutdown completed in ${elapsed.elapsedMilliseconds}ms',
      'AppShutdown',
    );
    await AppLogger.flush();
  }

  static Future<void> _finishAndExit(int code) async {
    await prepareForTermination();
    // AppKit may finish quitting as soon as the last window is destroyed.
    if (Platform.isMacOS) {
      await _cleanup('Window', () async {
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
      });
    }
    exit(code);
  }

  static Future<void> _cleanup(
    String name,
    Future<void> Function() action,
  ) async {
    final elapsed = Stopwatch()..start();
    try {
      await action();
    } catch (error) {
      AppLogger.w('$name shutdown failed: $error', 'AppShutdown');
    } finally {
      AppLogger.i(
        '$name shutdown took ${elapsed.elapsedMilliseconds}ms',
        'AppShutdown',
      );
    }
  }
}
