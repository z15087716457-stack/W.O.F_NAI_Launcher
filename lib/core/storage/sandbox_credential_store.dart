import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sandbox credentials are deliberately session-only. No credential-manager
/// call (including deleteAll) can cross this boundary while sandboxed.
class SandboxCredentialStore {
  SandboxCredentialStore({required this.sandbox, FlutterSecureStorage? storage})
    : _storage =
          storage ?? const FlutterSecureStorage(wOptions: WindowsOptions());
  final String? sandbox;
  final FlutterSecureStorage _storage;
  static final _sessions = <String, Map<String, String>>{};
  Map<String, String> get _values => _sessions.putIfAbsent(sandbox!, () => {});

  Future<void> write({required String key, required String value}) async {
    if (sandbox == null) {
      await _storage.write(key: key, value: value);
    } else {
      _values[key] = value;
    }
  }

  Future<String?> read({required String key}) async =>
      sandbox == null ? _storage.read(key: key) : _values[key];
  Future<void> delete({required String key}) async {
    if (sandbox == null) {
      await _storage.delete(key: key);
    } else {
      _values.remove(key);
    }
  }

  Future<void> deleteAll() async {
    if (sandbox == null) {
      await _storage.deleteAll();
    } else {
      _values.clear();
    }
  }
}
