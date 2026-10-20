import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../settings/settings_preferences_service.dart';
import 'agent_tool.dart';

String naiAgentPreferencesVersion(Map<String, Object?> values) =>
    sha256.convert(utf8.encode(jsonEncode(values))).toString();

/// The same public preference allowlist and persistence used by Settings.
class NaiAgentSettingsTools {
  NaiAgentSettingsTools(
    this.service, {
    required this.isAlive,
    required this.refresh,
  });
  final SettingsPreferencesService service;
  final bool Function() isAlive;
  final void Function() refresh;

  Future<Map<String, dynamic>> read(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    final raw = params['keys'];
    if (raw != null &&
        (raw is! List ||
            raw.isEmpty ||
            raw.any(
              (key) =>
                  key is! String ||
                  !SettingsPreferencesService.keys.contains(key),
            ))) {
      throw const NaiAgentToolError(
        'invalid_settings',
        'Use keys from allowed_keys',
      );
    }
    final all = service.capture();
    return naiAgentTextResult({
      'version': naiAgentPreferencesVersion(all),
      'values': {
        for (final key in raw as List? ?? all.keys) key as String: all[key],
      },
      'allowed_keys': SettingsPreferencesService.keys.toList(),
      'groups': {
        for (final group in SettingsPreferencesService.groups.entries)
          group.key.name: group.value,
      },
      'null_means_native_default': true,
    });
  }

  Future<Map<String, dynamic>> update(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    final raw = params['changes'];
    if (raw is! Map || raw.isEmpty || raw.keys.any((key) => key is! String)) {
      throw const NaiAgentToolError(
        'invalid_settings',
        'Provide a nonempty changes object',
      );
    }
    final changes = Map<String, Object?>.from(raw);
    try {
      service.decode(service.encode(changes));
    } on FormatException catch (error) {
      throw NaiAgentToolError('invalid_settings', error.message);
    }
    final before = service.capture();
    if (params['expected_version'] != naiAgentPreferencesVersion(before)) {
      throw const NaiAgentToolError(
        'settings_conflict',
        'Read settings_read again',
      );
    }
    try {
      final backup = await service.apply(
        changes,
        expected: before,
        beforeWrite: () => _check(token),
      );
      return naiAgentTextResult({
        'applied_fields': changes.keys.toList(),
        'before': before,
        'backup_path': backup.path,
        'values': service.capture(),
        'version': naiAgentPreferencesVersion(service.capture()),
      });
    } finally {
      if (isAlive()) refresh();
    }
  }

  void _check(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Settings binding closed');
    }
  }
}
