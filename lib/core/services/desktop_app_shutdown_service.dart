import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../database/database_manager.dart';
import '../utils/app_logger.dart';
import '../utils/desktop_platform.dart';

/// 桌面应用统一退出入口。
///
/// 先隐藏窗口并收尾后台任务，关闭存储和日志后统一退出。
class DesktopAppShutdownService {
  DesktopAppShutdownService._();

  static Future<void>? _shutdownFuture;
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

  /// Only register work after startup reaches it, so deferred callbacks never
  /// keep the process alive while it is quitting.
  static Future<void> runCriticalStartupTask(
    String name,
    Future<void> Function() action,
  ) async {
    if (isShuttingDown) return;
    final finished = Completer<void>();
    final unregister = registerCleanup(() => finished.future, name: name);
    try {
      await action();
    } finally {
      unregister();
      finished.complete();
    }
  }

  static Future<void> prepareBackgroundShutdown() async {
    await Future.wait([
      for (final entry in List.of(_cleanups.entries))
        _cleanup(entry.value, entry.key),
    ]);
  }

  static Future<void> prepareForExit() =>
      _shutdownFuture ??= _performShutdown();

  static Future<void> shutdownAndExit(int code) =>
      _shutdownFuture ??= _performShutdown(exitCode: code);

  static Future<void> _performShutdown({int? exitCode}) async {
    final elapsed = Stopwatch()..start();
    AppLogger.i('Application shutdown started', 'AppShutdown');
    if (isSupportedDesktop) {
      await _cleanup('Window hide', windowManager.hide);
    }
    await prepareBackgroundShutdown();
    await _cleanup('Database', () => DatabaseManager.instance.dispose());
    await _cleanup('Hive', Hive.close);
    if (isSupportedDesktop) {
      await _cleanup('Tray', trayManager.destroy);
    }
    if (Platform.isWindows && exitCode != null) {
      await _cleanup('WebView composition', () async {
        await const MethodChannel(
          'com.pichillilorenzo/flutter_inappwebview_manager',
        ).invokeMethod<void>('studioReleaseComposition');
      });
    }
    AppLogger.i(
      'Application shutdown completed in ${elapsed.elapsedMilliseconds}ms',
      'AppShutdown',
    );
    await AppLogger.flush();
    if (exitCode != null) exit(exitCode);
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
