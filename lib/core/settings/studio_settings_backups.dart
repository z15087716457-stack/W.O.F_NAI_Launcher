import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../shortcuts/shortcut_config.dart';
import 'settings_preferences_service.dart';

class StudioSettingsSnapshot {
  const StudioSettingsSnapshot(this.preferences, this.shortcuts);
  final Map<String, Object?> preferences;
  final ShortcutConfig? shortcuts;
}

class StudioSettingsBackupRecord {
  const StudioSettingsBackupRecord(this.id, this.reason, this.at);
  final String id, reason;
  final DateTime at;
}

class _PreparedPreferences extends SettingsPreferencesService {
  _PreparedPreferences(SettingsPreferencesService source, this.saved)
    : super(source.storage);
  final File saved;
  @override
  Future<File> backup(Map<String, Object?> values) async => saved;
}

/// Public preferences and shortcuts only. Existing v1 exports remain readable.
/// Automatic v2 snapshots have their own directory; old recovery files stay put.
class StudioSettingsBackups {
  StudioSettingsBackups({
    required this.preferences,
    required this.directory,
    required this.readShortcuts,
    required this.writeShortcuts,
  });
  final SettingsPreferencesService preferences;
  final Directory directory;
  final ShortcutConfig Function() readShortcuts;
  final Future<void> Function(ShortcutConfig) writeShortcuts;
  static const _schema = 'wof.studio.settings';
  static const _lastImport = 'settings_last_import_v2';
  static const _equal = DeepCollectionEquality();
  static final _name = RegExp(r'^settings-[0-9]+-[a-f0-9-]{36}\.json$');
  Future<void> _pending = Future.value();

  StudioSettingsSnapshot capture() =>
      StudioSettingsSnapshot(preferences.capture(), readShortcuts());
  String encode(
    StudioSettingsSnapshot snapshot, {
    String reason = 'export',
    DateTime? at,
  }) => const JsonEncoder.withIndent('  ').convert({
    'schema': _schema,
    'version': 2,
    'created_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
    'reason': reason,
    'preferences': snapshot.preferences,
    if (snapshot.shortcuts != null) 'shortcuts': snapshot.shortcuts!.toJson(),
  });

  StudioSettingsSnapshot decode(String raw) {
    if (raw.length > 1024 * 1024) {
      throw const FormatException('Settings file is too large');
    }
    final value = jsonDecode(raw);
    if (value is! Map) throw const FormatException('Invalid settings file');
    if (value['schema'] == SettingsPreferencesService.schema) {
      return StudioSettingsSnapshot(preferences.decode(raw), null);
    }
    if (value['schema'] != _schema ||
        value['version'] != 2 ||
        value['preferences'] is! Map ||
        value['shortcuts'] != null && value['shortcuts'] is! Map) {
      throw const FormatException('Unsupported settings file');
    }
    final public = Map<String, Object?>.from(value['preferences'] as Map);
    if (public.isNotEmpty) preferences.decode(preferences.encode(public));
    final shortcuts = value['shortcuts'] == null
        ? null
        : ShortcutConfig.fromJson(
            Map<String, dynamic>.from(value['shortcuts'] as Map),
          );
    if (public.isEmpty && shortcuts == null) {
      throw const FormatException('Empty settings file');
    }
    return StudioSettingsSnapshot(public, shortcuts);
  }

  bool _unchanged(StudioSettingsSnapshot snapshot) =>
      _equal.equals(snapshot.preferences, preferences.capture()) &&
      _equal.equals(snapshot.shortcuts?.toJson(), readShortcuts().toJson());

  Future<File> _save(StudioSettingsSnapshot before, String reason) async {
    await directory.create(recursive: true);
    final file = File(
      p.join(
        directory.path,
        'settings-${DateTime.now().microsecondsSinceEpoch}-${const Uuid().v4()}.json',
      ),
    );
    final stage = File('${file.path}.tmp');
    await stage.writeAsString(encode(before, reason: reason), flush: true);
    await stage.rename(file.path);
    return file;
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _pending.catchError((Object _) {}).then((_) => action());
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<void> apply(
    StudioSettingsSnapshot changes, {
    required StudioSettingsSnapshot expected,
    String reason = 'import',
  }) => _serial(() => _apply(changes, expected, reason));

  Future<void> _apply(
    StudioSettingsSnapshot changes,
    StudioSettingsSnapshot expected,
    String reason,
  ) async {
    decode(encode(changes));
    if (!_unchanged(expected)) {
      throw StateError('Settings changed before confirmation');
    }
    final saved = await _save(expected, reason);
    if (!_unchanged(expected)) {
      throw StateError('Settings changed while backing up');
    }
    final prepared = _PreparedPreferences(preferences, saved);
    var appliedPublic = false;
    try {
      if (changes.preferences.isNotEmpty) {
        await prepared.apply(
          changes.preferences,
          expected: expected.preferences,
          beforeWrite: () {
            if (!_equal.equals(
              readShortcuts().toJson(),
              expected.shortcuts?.toJson(),
            )) {
              throw StateError('Shortcuts changed while importing');
            }
          },
        );
        appliedPublic = true;
      }
      if (changes.shortcuts != null) {
        if (!_equal.equals(
          readShortcuts().toJson(),
          expected.shortcuts?.toJson(),
        )) {
          throw StateError('Shortcuts changed while importing');
        }
        await writeShortcuts(changes.shortcuts!);
      }
      if (reason == 'import') {
        await preferences.storage.setSetting(_lastImport, {
          'backup': p.basename(saved.path),
          'at': DateTime.now().toUtc().toIso8601String(),
          'after': jsonDecode(encode(changes)),
        });
      }
    } catch (_) {
      if (appliedPublic) {
        final current = preferences.capture();
        final own = <String, Object?>{
          for (final entry in changes.preferences.entries)
            if (_equal.equals(current[entry.key], entry.value))
              entry.key: expected.preferences[entry.key],
        };
        if (own.isNotEmpty) await prepared.apply(own, expected: current);
      }
      if (changes.shortcuts != null &&
          _equal.equals(
            readShortcuts().toJson(),
            changes.shortcuts!.toJson(),
          )) {
        await writeShortcuts(expected.shortcuts!);
      }
      rethrow;
    }
    final backups = await list();
    for (final record in backups.skip(5)) {
      // Only our own validated v2 files in this exact directory are pruned.
      try {
        await (await _file(record.id)).delete();
      } on FileSystemException {
        // A locked snapshot may be pruned on the next successful operation.
        // Settings have already committed; never report a failed import here.
      }
    }
  }

  Future<File> _file(String id) async {
    if (!_name.hasMatch(id)) throw ArgumentError.value(id, 'backup');
    final file = File(p.join(directory.path, id));
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const FileSystemException('Settings backup is missing');
    }
    if (!p.equals(
      p.dirname(await file.resolveSymbolicLinks()),
      await directory.resolveSymbolicLinks(),
    )) {
      throw const FileSystemException('Invalid backup path');
    }
    return file;
  }

  Future<StudioSettingsSnapshot> read(String id) async {
    final file = await _file(id);
    if (await file.length() > 1024 * 1024) {
      throw const FormatException('Settings file is too large');
    }
    return decode(await file.readAsString());
  }

  Future<List<StudioSettingsBackupRecord>> list() async {
    if (!await directory.exists()) return [];
    final result = <StudioSettingsBackupRecord>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !_name.hasMatch(p.basename(entity.path))) continue;
      try {
        final file = await _file(p.basename(entity.path));
        if (await file.length() > 1024 * 1024) continue;
        final raw = await file.readAsString();
        decode(raw);
        final value = jsonDecode(raw) as Map;
        if (value['schema'] != _schema) continue;
        result.add(
          StudioSettingsBackupRecord(
            p.basename(file.path),
            value['reason'] as String? ?? 'upgrade',
            DateTime.parse(value['created_at'] as String),
          ),
        );
      } catch (_) {
        /* An unrelated or damaged file is never a prune candidate. */
      }
    }
    result.sort((a, b) => b.at.compareTo(a.at));
    return result;
  }

  Future<DateTime?> lastImportAt() async {
    final value = preferences.storage.getSetting<Object?>(_lastImport);
    if (value is! Map || value['backup'] is! String) return null;
    try {
      await _file(value['backup'] as String);
      final after = decode(jsonEncode(value['after']));
      final current = capture();
      if (after.preferences.entries.any(
            (entry) =>
                !_equal.equals(current.preferences[entry.key], entry.value),
          ) ||
          after.shortcuts != null &&
              !_equal.equals(
                current.shortcuts?.toJson(),
                after.shortcuts!.toJson(),
              )) {
        return null;
      }
      return DateTime.tryParse(value['at'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> undoImport() => _serial(() async {
    final value = preferences.storage.getSetting<Object?>(_lastImport);
    if (value is! Map || value['backup'] is! String || value['after'] is! Map) {
      throw StateError('No import to undo');
    }
    final previous = await read(value['backup'] as String);
    final after = decode(jsonEncode(value['after']));
    final current = capture();
    if (after.preferences.entries.any(
          (e) => !_equal.equals(current.preferences[e.key], e.value),
        ) ||
        after.shortcuts != null &&
            !_equal.equals(
              current.shortcuts?.toJson(),
              after.shortcuts!.toJson(),
            )) {
      throw StateError('Imported settings have since changed');
    }
    await _apply(
      StudioSettingsSnapshot({
        for (final key in after.preferences.keys)
          key: previous.preferences[key],
      }, after.shortcuts == null ? null : previous.shortcuts),
      current,
      'reset',
    );
    await preferences.storage.deleteSetting(_lastImport);
  });
}
