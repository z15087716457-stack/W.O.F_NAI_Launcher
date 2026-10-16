import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/desktop_app_shutdown_service.dart';

/// Detail telemetry starts with this schema. Old daily totals cannot be
/// reconstructed into hours or individual balance deductions.
class AnlasUsageMetrics {
  const AnlasUsageMetrics({
    this.day = '',
    this.hourly = const [],
    this.warnings = 0,
    this.maxDeduction = 0,
  });
  final String day;
  final List<int> hourly;
  final int warnings, maxDeduction;
  static String dateKey(DateTime time) =>
      '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  AnlasUsageMetrics at(DateTime time) =>
      dateKey(time) == day ? this : AnlasUsageMetrics(day: dateKey(time));
  AnlasUsageMetrics record(
    DateTime time, {
    int cost = 0,
    bool warning = false,
  }) {
    final current = at(time);
    final hours = List<int>.from(
      current.hourly.isEmpty ? List.filled(24, 0) : current.hourly,
    );
    hours[time.hour] += cost;
    return AnlasUsageMetrics(
      day: current.day,
      hourly: hours,
      warnings: current.warnings + (warning ? 1 : 0),
      maxDeduction: cost > current.maxDeduction ? cost : current.maxDeduction,
    );
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'day': day,
    'hourly': hourly,
    'warnings': warnings,
    'maxDeduction': maxDeduction,
  };
  static AnlasUsageMetrics decode(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['version'] != 1 ||
        data['day'] is! String ||
        data['hourly'] is! List ||
        (data['hourly'] as List).length != 24 ||
        (data['hourly'] as List).any((x) => x is! int || x < 0) ||
        data['warnings'] is! int ||
        data['warnings'] < 0 ||
        data['maxDeduction'] is! int ||
        data['maxDeduction'] < 0) {
      throw const FormatException('Invalid usage metrics');
    }
    return AnlasUsageMetrics(
      day: data['day'],
      hourly: (data['hourly'] as List).cast<int>(),
      warnings: data['warnings'],
      maxDeduction: data['maxDeduction'],
    );
  }
}

final anlasUsageMetricsProvider =
    AsyncNotifierProvider<AnlasUsageMetricsStore, AnlasUsageMetrics>(
      AnlasUsageMetricsStore.new,
    );

class AnlasUsageMetricsStore extends AsyncNotifier<AnlasUsageMetrics> {
  static const storageKey = 'anlas_usage_metrics_v1';
  late SharedPreferences _preferences;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  @override
  Future<AnlasUsageMetrics> build() async {
    _disposed = false;
    final unregister = DesktopAppShutdownService.registerCleanup(
      () => _pending.catchError((Object _) {}),
    );
    ref.onDispose(() {
      _disposed = true;
      unregister();
    });
    _preferences = await SharedPreferences.getInstance();
    try {
      return AnlasUsageMetrics.decode(_preferences.getString(storageKey) ?? '');
    } catch (_) {
      return const AnlasUsageMetrics();
    }
  }

  Future<void> record({int cost = 0, bool warning = false, DateTime? at}) {
    if (cost < 0) throw ArgumentError.value(cost);
    final time = at ?? DateTime.now();
    final next = _pending.catchError((Object _) {}).then((_) async {
      final current = state.valueOrNull ?? await future;
      if (_disposed) return;
      // Late historical balance updates must not replace today's detail rows.
      if (AnlasUsageMetrics.dateKey(time) !=
          AnlasUsageMetrics.dateKey(DateTime.now())) {
        return;
      }
      final updated = current.record(time, cost: cost, warning: warning);
      if (!await _preferences.setString(
        storageKey,
        jsonEncode(updated.toJson()),
      )) {
        throw StateError('Usage metrics could not be saved');
      }
      if (!_disposed) state = AsyncData(updated);
    });
    _pending = next;
    return next;
  }
}
