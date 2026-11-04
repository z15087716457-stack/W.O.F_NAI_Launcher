// Flutter's test clock dependency; no additional runtime dependency.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/connection_health_monitor.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';

import '../../helpers/app_logger_test_isolation.dart';

/// Counts checks. The pool is not initialized in this file, so every check
/// finishes at once and reads the metrics snapshot exactly once.
class _CountingMetrics extends ConnectionMetricsCollector {
  int checks = 0;
  @override
  ConnectionMetricsSnapshot get snapshot {
    checks++;
    return super.snapshot;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final visibility = AppVisibility.instance;
  tearDown(() => visibility.debugSet(true));

  test('without a window signal it checks every interval as before', () {
    fakeAsync((async) {
      final metrics = _CountingMetrics();
      final monitor = ConnectionHealthMonitor(metricsCollector: metrics);
      monitor.start();
      async.flushMicrotasks();
      expect(metrics.checks, 1);
      visibility.debugSet(false);
      async.elapse(const Duration(seconds: 30));
      expect(metrics.checks, 2);
      monitor.dispose();
    });
  });

  // The window signal itself is platform code (menu bar on macOS, tray on
  // Windows); the monitor only follows it, the same way on both.
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    group(platform.name, () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);
      tearDown(() => debugDefaultTargetPlatformOverride = null);

      test('a hidden window pauses the 30 s check', () {
        fakeAsync((async) {
          final metrics = _CountingMetrics();
          final monitor = ConnectionHealthMonitor(
            windowVisibility: visibility,
            metricsCollector: metrics,
          );
          monitor.start();
          async.elapse(const Duration(seconds: 30));
          expect(metrics.checks, 2);

          visibility.debugSet(false);
          expect(monitor.isRunning, isTrue);
          expect(monitor.isPaused, isTrue);
          async.elapse(const Duration(hours: 1));
          expect(metrics.checks, 2);

          visibility.debugSet(true);
          async.flushMicrotasks();
          expect(metrics.checks, 3, reason: 'checks once right away');
          async.elapse(const Duration(seconds: 30));
          expect(metrics.checks, 4);
          expect(monitor.isPaused, isFalse);
          monitor.dispose();
        });
      });

      test('a monitor started while hidden waits for the window', () {
        fakeAsync((async) {
          visibility.debugSet(false);
          final metrics = _CountingMetrics();
          final monitor = ConnectionHealthMonitor(
            windowVisibility: visibility,
            metricsCollector: metrics,
          );
          monitor.start();
          async.elapse(const Duration(minutes: 5));
          expect(metrics.checks, 1, reason: 'only the start-up check');
          visibility.debugSet(true);
          async.elapse(const Duration(seconds: 30));
          expect(metrics.checks, 3);
          monitor.dispose();
        });
      });

      test('a stopped monitor stays stopped when the window shows', () {
        fakeAsync((async) {
          final metrics = _CountingMetrics();
          final monitor = ConnectionHealthMonitor(
            windowVisibility: visibility,
            metricsCollector: metrics,
          );
          monitor.start();
          visibility.debugSet(false);
          monitor.stop();
          visibility.debugSet(true);
          async.elapse(const Duration(minutes: 5));
          expect(metrics.checks, 1);
          expect(monitor.isRunning, isFalse);
          monitor.dispose();
        });
      });
    });
  }
}
