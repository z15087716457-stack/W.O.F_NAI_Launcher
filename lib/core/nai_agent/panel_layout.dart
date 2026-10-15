import 'dart:math' as math;

/// Shared width budget: the Agent never consumes the history strip's space.
abstract final class AgentPanelLayout {
  static const minimum = 320.0;
  static const maximum = 1280.0;
  static const initial = 520.0;
  static const handle = 8.0;
  // 40px collapsed editor + 200px history + 160px usable canvas.
  static const minimumPage = 400.0;

  static double cap(double available) =>
      math.max(0, math.min(maximum, available - minimumPage - handle));
  static double resolve(double preferred, double available) {
    final upper = cap(available);
    return (preferred.isFinite ? preferred : initial)
        .clamp(math.min(minimum, upper), upper)
        .toDouble();
  }
}
