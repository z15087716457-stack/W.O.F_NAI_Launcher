import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Called before any preferences or credentials open, using the prepared root.
void initializeApplicationStorage(Directory directory) {
  if (Platform.isWindows) {
    PathProviderPlatform.instance = _ApplicationDataPaths(directory);
  }
  SharedPreferencesStorePlatform.instance = _FilePreferencesStore(
    File(p.join(directory.path, 'shared_preferences.json')),
  );
}

class _ApplicationDataPaths extends PathProviderWindows {
  _ApplicationDataPaths(this.directory);
  final Directory directory;

  @override
  Future<String?> getApplicationSupportPath() async => directory.path;
}

class _FilePreferencesStore extends SharedPreferencesStorePlatform {
  _FilePreferencesStore(this.file);
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
    return (await _read())
      ..removeWhere((key, _) => !key.startsWith('flutter.'));
  }

  @override
  Future<bool> remove(String key) => _change((values) => values.remove(key));
  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _change((values) => values[key] = value);
  @override
  Future<bool> clear() => _change(
    (values) => values.removeWhere((key, _) => key.startsWith('flutter.')),
  );
}
