import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
// Existing locked dev dependency; sandbox must intercept the Windows plugin's
// independent AppData resolution without changing the dependency manifest.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Opt-in only. Invalid opt-in fails closed rather than accessing real data.
String? studioSandboxRoot([Map<String, String>? environment]) {
  final value = (environment ?? Platform.environment)['NAI_STUDIO_SANDBOX'];
  if (value == null) return null;
  if (value.isEmpty || !p.isAbsolute(value)) {
    throw ArgumentError('NAI_STUDIO_SANDBOX must be an absolute directory');
  }
  return p.normalize(value);
}

/// Synchronous fallback root for early logging and legacy path helpers. In
/// sandbox mode even error paths must not share the production temp namespace.
Directory studioTemporaryRoot() {
  final sandbox = studioSandboxRoot();
  return sandbox == null
      ? Directory.systemTemp
      : Directory(p.join(sandbox, 'user-data', 'temp'));
}

String studioWindowTitle(String title) =>
    studioSandboxRoot() == null ? title : '$title [sandbox]';

/// Windows SharedPreferences resolves AppData independently of our path helper.
/// Install before its first read; never migrate/copy the production preferences.
void initializeSandboxPreferences({String? root}) {
  final directory = root ?? studioSandboxRoot();
  if (directory == null) return;
  SharedPreferencesStorePlatform.instance = SandboxPreferencesStore(
    File(p.join(directory, 'user-data', 'shared_preferences.json')),
  );
}

class SandboxPreferencesStore extends SharedPreferencesStorePlatform {
  SandboxPreferencesStore(this.file);
  final File file;
  Future<Map<String, Object>> _read() async => await file.exists()
      ? Map<String, Object>.from(jsonDecode(await file.readAsString()) as Map)
      : {};
  Future<void> _pending = Future.value();

  Future<bool> _change(void Function(Map<String, Object>) change) {
    final operation = _pending.then((_) async {
      final values = await _read();
      change(values);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(values), flush: true);
      return true;
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    await _pending;
    return _read();
  }

  @override
  Future<bool> remove(String key) => _change((values) => values.remove(key));
  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _change((values) => values[key] = value);
  @override
  Future<bool> clear() => _change((values) => values.clear());
}
