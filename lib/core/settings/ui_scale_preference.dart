import '../constants/storage_keys.dart';

abstract final class UiScalePreference {
  static const min = .8;
  static const max = 1.5;
  static const defaultValue = 1.0;
  static const legacyKeys = [
    StorageKeys.settingsFontScale,
    StorageKeys.workspaceFontScale,
    StorageKeys.fontScale,
  ];

  static bool valid(Object? value) =>
      value is num && value.isFinite && value >= min && value <= max;

  static double normalize(num value) =>
      ((value.clamp(min, max) * 10).round() / 10).clamp(min, max);

  static double read(Object? Function(String) valueOf) => resolve({
    StorageKeys.uiScale: valueOf(StorageKeys.uiScale),
    for (final key in legacyKeys) key: valueOf(key),
  });

  /// Prefer the current interface setting, then creative text. The retired
  /// global value is only a fallback for installations predating both.
  static double resolve(Map<String, Object?> values) {
    final current = values[StorageKeys.uiScale];
    if (valid(current)) return normalize(current as num);
    final local = legacyKeys.take(2).map((key) => values[key]).toList();
    for (final value in local) {
      if (valid(value) && value != 1) return normalize(value as num);
    }
    if (local.any((value) => value != null)) return defaultValue;
    final legacy = values[StorageKeys.fontScale];
    return valid(legacy) ? normalize(legacy as num) : defaultValue;
  }

  static Map<String, Object?> migrate(Map<String, Object?> values) => {
    for (final entry in values.entries)
      if (!legacyKeys.contains(entry.key) && entry.key != StorageKeys.uiScale)
        entry.key: entry.value,
    if (values.containsKey(StorageKeys.uiScale) ||
        legacyKeys.any(values.containsKey))
      StorageKeys.uiScale: values.containsKey(StorageKeys.uiScale)
          ? values[StorageKeys.uiScale] == null
                ? defaultValue
                : normalize(values[StorageKeys.uiScale] as num)
          : resolve(values),
  };
}
