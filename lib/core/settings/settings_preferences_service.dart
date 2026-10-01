import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/storage_keys.dart';
import '../autocomplete/completion_models.dart';
import '../storage/local_storage_service.dart';

enum PreferenceGroup { appearance, input, protection }

/// Public preferences only. Credentials, paths, drafts and model bindings stay
/// outside this allowlist, including when an imported file contains extra keys.
class SettingsPreferencesService {
  SettingsPreferencesService(this.storage, {this.backupDirectory});
  final LocalStorageService storage;
  final Directory? backupDirectory;
  static const schema = 'wof.studio.preferences';
  static final groups = <PreferenceGroup, List<String>>{
    PreferenceGroup.appearance: [
      StorageKeys.studioThemeMode,
      StorageKeys.fontFamily,
      StorageKeys.fontScale,
      StorageKeys.settingsFontScale,
      StorageKeys.locale,
      StorageKeys.historyClickBehavior,
      StorageKeys.simpleOutputViewer,
      StorageKeys.canvasLockCamera,
      StorageKeys.canvasReducedMotion,
      StorageKeys.canvasZoomToFill,
      StorageKeys.notificationSoundEnabled,
    ],
    PreferenceGroup.input: [
      StorageKeys.enablePromptWeightScroll,
      StorageKeys.promptWeightScrollModifier,
      StorageKeys.tagExpansionResultLimit,
      StorageKeys.enableCooccurrenceRecommendation,
    ],
    PreferenceGroup.protection: [
      StorageKeys.shareStripMetadata,
      StorageKeys.protectionConfirmDangerousActions,
      StorageKeys.protectionWarnExternalImageSend,
      StorageKeys.protectionPreventOverwrite,
      StorageKeys.protectionWarnHighAnlasCost,
      StorageKeys.protectionHighAnlasCostThreshold,
      StorageKeys.protectionLimitGenerationInterval,
      StorageKeys.protectionGenerationIntervalSeconds,
      StorageKeys.protectionGenerationIntervalJitterPercent,
    ],
  };
  static Set<String> get keys => groups.values.expand((items) => items).toSet();
  static bool validValue(String key, Object? value) {
    if (value == null) return true;
    if (key == StorageKeys.studioThemeMode) {
      return ['dark', 'light'].contains(value);
    }
    if (key == StorageKeys.locale) return ['zh', 'en', 'ja'].contains(value);
    if (key == StorageKeys.fontFamily) {
      return value is String && value.isNotEmpty && value.length <= 128;
    }
    if (key == StorageKeys.fontScale || key == StorageKeys.settingsFontScale) {
      return value is num && value.isFinite && value >= .8 && value <= 1.5;
    }
    if (key == StorageKeys.historyClickBehavior) {
      return ['open_detail', 'select_preview'].contains(value);
    }
    if (key == StorageKeys.promptWeightScrollModifier) {
      return ['alt', 'ctrl', 'shift', 'none'].contains(value);
    }
    if ([
      StorageKeys.autocompleteResultLimit,
      StorageKeys.tagExpansionResultLimit,
    ].contains(key)) {
      return value is int && value > 0 && value <= CompletionResultLimits.all;
    }
    if (key == StorageKeys.protectionHighAnlasCostThreshold) {
      return value is int && value > 0 && value <= 1000000;
    }
    if (key == StorageKeys.protectionGenerationIntervalSeconds) {
      return value is int && value >= 1 && value <= 3600;
    }
    if (key == StorageKeys.protectionGenerationIntervalJitterPercent) {
      return value is int && value >= 0 && value <= 50;
    }
    return value is bool;
  }

  Map<String, Object?> capture() => {
    for (final key in keys) key: storage.getSetting<Object?>(key),
  };
  String encode(Map<String, Object?> values) =>
      const JsonEncoder.withIndent('  ').convert({
        'schema': schema,
        'version': 1,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'preferences': values,
      });
  Map<String, Object?> decode(String raw) {
    if (raw.length > 1024 * 1024) {
      throw const FormatException('Preference file is too large.');
    }
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['schema'] != schema ||
        data['version'] != 1 ||
        data['preferences'] is! Map) {
      throw const FormatException('Unsupported preference backup.');
    }
    final values = Map<String, Object?>.from(data['preferences'] as Map);
    if (values.isEmpty ||
        values.entries.any(
          (e) => !keys.contains(e.key) || !validValue(e.key, e.value),
        )) {
      throw const FormatException(
        'Preference backup contains unsupported keys or values.',
      );
    }
    return values;
  }

  Map<String, Object?> defaults(Set<PreferenceGroup> selected) => {
    for (final group in selected)
      for (final key in groups[group]!) key: null,
  };
  Future<Directory> _directory() async {
    final result =
        backupDirectory ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/settings_backups',
        );
    await result.create(recursive: true);
    return result;
  }

  Future<File> backup(Map<String, Object?> values) async {
    final dir = await _directory();
    final file = File(
      '${dir.path}/preferences-${DateTime.now().toUtc().microsecondsSinceEpoch}-${const Uuid().v4()}.json',
    );
    final stage = File('${file.path}.tmp');
    await stage.writeAsString(encode(values), flush: true);
    return stage.rename(file.path);
  }

  Future<File?> latestBackup() async {
    final files = (await (await _directory()).list().toList())
        .whereType<File>()
        .where(
          (f) =>
              f.uri.pathSegments.last.startsWith('preferences-') &&
              f.path.endsWith('.json'),
        )
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files.firstOrNull;
  }

  Future<File> apply(
    Map<String, Object?> values, {
    required Map<String, Object?> expected,
  }) async {
    decode(encode(values));
    bool unchanged() {
      final current = capture();
      return expected.length == current.length &&
          current.entries.every(
            (e) => expected.containsKey(e.key) && expected[e.key] == e.value,
          );
    }

    if (!unchanged()) {
      throw StateError('Preferences changed. Open the confirmation again.');
    }
    final saved = await backup(expected);
    if (!unchanged()) {
      throw StateError('Preferences changed while preparing the backup.');
    }
    final touched = <String>[];
    try {
      for (final entry in values.entries) {
        if (storage.getSetting<Object?>(entry.key) != expected[entry.key]) {
          throw StateError('Preference changed during import: ${entry.key}');
        }
        touched.add(entry.key);
        if (entry.value == null) {
          await storage.deleteSetting(entry.key);
        } else {
          await storage.setSetting(entry.key, entry.value);
        }
      }
    } catch (_) {
      for (final key in touched.reversed) {
        // A later user write must not be overwritten by rollback.
        if (storage.getSetting<Object?>(key) != values[key]) continue;
        final previous = expected[key];
        if (previous == null) {
          await storage.deleteSetting(key);
        } else {
          await storage.setSetting(key, previous);
        }
      }
      rethrow;
    }
    return saved;
  }
}
