import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_foundation/shared_preferences_foundation.dart';

/// Copies the previous version's SharedPreferences values that this version
/// does not have yet.
///
/// On macOS they live in the app's defaults domain
/// (`~/Library/Preferences/<bundle id>.plist`), outside the data folder, so
/// the folder copy cannot bring them; on Windows they are part of the data
/// folder. The previous domain is only read.
class LegacyPreferencesImport {
  LegacyPreferencesImport({
    required this.readLegacy,
    required this.readCurrentKeys,
    required this.write,
  });

  /// Reads the previous app's defaults domain [domain] (its bundle id) and
  /// writes into this app's own domain.
  factory LegacyPreferencesImport.macOS(String domain) {
    // Created on use: the platform side is only registered in a running app.
    return LegacyPreferencesImport(
      readLegacy: () => SharedPreferencesAsync(
        options: SharedPreferencesAsyncFoundationOptions(suiteName: domain),
      ).getAll(),
      readCurrentKeys: () => SharedPreferencesAsync().getKeys(),
      write: (key, value) async {
        final preferences = SharedPreferencesAsync();
        switch (value) {
          case final bool flag:
            await preferences.setBool(key, flag);
          case final int number:
            await preferences.setInt(key, number);
          case final double number:
            await preferences.setDouble(key, number);
          case final String text:
            await preferences.setString(key, text);
          case final List<String> texts:
            await preferences.setStringList(key, texts);
        }
      },
    );
  }

  /// Keys written through `SharedPreferences.getInstance()` carry this
  /// prefix; everything else in the domain belongs to macOS or plugins.
  static const prefix = 'flutter.';

  /// Sign-in data is not migrated: the user signs in again, as with the
  /// keychain items, which stay under the previous app's name.
  static const excluded = {'flutter.danbooru_credentials'};

  final Future<Map<String, Object?>> Function() readLegacy;
  final Future<Set<String>> Function() readCurrentKeys;
  final Future<void> Function(String key, Object value) write;

  /// Returns how many values were copied. Existing values are never
  /// overwritten.
  Future<int> copyMissing() async {
    final legacy = await readLegacy();
    final current = await readCurrentKeys();
    var copied = 0;
    for (final MapEntry(:key, :value) in legacy.entries) {
      if (!key.startsWith(prefix) ||
          excluded.contains(key) ||
          current.contains(key)) {
        continue;
      }
      final supported = switch (value) {
        bool() || int() || double() || String() => value,
        List() when value.every((item) => item is String) => List<String>.from(
          value,
        ),
        _ => null,
      };
      if (supported == null) continue;
      await write(key, supported);
      copied++;
    }
    return copied;
  }
}
