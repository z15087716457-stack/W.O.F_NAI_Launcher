import 'dart:async';

import 'app_logger.dart';

/// Slow-span diagnostics for Vibe library paths.
///
/// The logger is intentionally threshold-based so normal browsing does not
/// flood logs. Details must stay metadata-only: never include prompt text,
/// vibe encodings, or raw image bytes.
class VibePerformanceDiagnostics {
  static const String tag = 'VibePerf';
  static const Duration defaultSlowThreshold = Duration(milliseconds: 16);

  const VibePerformanceDiagnostics._();

  static VibePerfSpan start(
    String operation, {
    Duration slowThreshold = defaultSlowThreshold,
    Map<String, Object?> details = const {},
  }) {
    return VibePerfSpan._(
      operation: operation,
      slowThreshold: slowThreshold,
      details: details,
    );
  }

  static Future<T> measure<T>(
    String operation,
    FutureOr<T> Function() action, {
    Duration slowThreshold = defaultSlowThreshold,
    Map<String, Object?> details = const {},
    Map<String, Object?> Function(T result)? resultDetails,
  }) async {
    final span = start(
      operation,
      slowThreshold: slowThreshold,
      details: details,
    );
    try {
      final result = await action();
      span.finish(details: resultDetails?.call(result) ?? const {});
      return result;
    } catch (error) {
      span.finish(details: {'failed': true, 'errorType': error.runtimeType});
      rethrow;
    }
  }

  static T measureSync<T>(
    String operation,
    T Function() action, {
    Duration slowThreshold = defaultSlowThreshold,
    Map<String, Object?> details = const {},
    Map<String, Object?> Function(T result)? resultDetails,
  }) {
    final span = start(
      operation,
      slowThreshold: slowThreshold,
      details: details,
    );
    try {
      final result = action();
      span.finish(details: resultDetails?.call(result) ?? const {});
      return result;
    } catch (error) {
      span.finish(details: {'failed': true, 'errorType': error.runtimeType});
      rethrow;
    }
  }

  static bool shouldLog(Duration elapsed, Duration slowThreshold) {
    return elapsed >= slowThreshold;
  }

  static String severityFor(Duration elapsed) {
    if (elapsed >= const Duration(milliseconds: 500)) {
      return 'critical';
    }
    if (elapsed >= const Duration(milliseconds: 100)) {
      return 'major';
    }
    if (elapsed >= const Duration(milliseconds: 50)) {
      return 'moderate';
    }
    return 'frame';
  }

  static String buildSlowSpanMessage(
    String operation,
    Duration elapsed, {
    Map<String, Object?> details = const {},
  }) {
    final detailsText = formatDetails(details);
    final suffix = detailsText.isEmpty ? '' : ' details=[$detailsText]';
    return 'slow span: operation=$operation elapsed=${elapsed.inMilliseconds}ms '
        'severity=${severityFor(elapsed)}$suffix';
  }

  static String formatDetails(Map<String, Object?> details) {
    if (details.isEmpty) {
      return '';
    }

    return details.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${_formatDetailValue(entry.value)}')
        .join(', ');
  }

  static String _formatDetailValue(Object? value) {
    final text = switch (value) {
      final Duration duration => '${duration.inMilliseconds}ms',
      final Iterable<Object?> values => '${values.length} items',
      final Map<Object?, Object?> values => '${values.length} entries',
      _ => value.toString(),
    };
    final singleLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 120) {
      return singleLine;
    }
    return '${singleLine.substring(0, 117)}...';
  }
}

class VibePerfSpan {
  VibePerfSpan._({
    required this.operation,
    required this.slowThreshold,
    required Map<String, Object?> details,
  }) : _details = Map.unmodifiable(details),
       _stopwatch = Stopwatch()..start();

  final String operation;
  final Duration slowThreshold;
  final Map<String, Object?> _details;
  final Stopwatch _stopwatch;
  bool _finished = false;

  Duration get elapsed => _stopwatch.elapsed;

  Duration finish({Map<String, Object?> details = const {}}) {
    if (_finished) {
      return _stopwatch.elapsed;
    }

    _finished = true;
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed;
    if (VibePerformanceDiagnostics.shouldLog(elapsed, slowThreshold)) {
      AppLogger.i(
        VibePerformanceDiagnostics.buildSlowSpanMessage(
          operation,
          elapsed,
          details: {..._details, ...details},
        ),
        VibePerformanceDiagnostics.tag,
      );
    }
    return elapsed;
  }
}
