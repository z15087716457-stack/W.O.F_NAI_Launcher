import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'mac_credential_store.dart';

/// Sandboxed credentials are session-only. A regular Mac uses the private
/// file vault; the other platforms use their existing credential provider.
class SandboxCredentialStore {
  SandboxCredentialStore({
    required this.sandbox,
    FlutterSecureStorage? storage,
    this.macStore,
  }) : _platformStore = sandbox == null && macStore == null
           ? storage ?? const FlutterSecureStorage(wOptions: WindowsOptions())
           : null;
  final String? sandbox;
  final MacCredentialStore? macStore;
  final FlutterSecureStorage? _platformStore;
  static final _sessions = <String, Map<String, String>>{};
  Map<String, String> get _values => _sessions.putIfAbsent(sandbox!, () => {});

  Future<void> write({required String key, required String value}) async {
    if (sandbox != null) {
      _values[key] = value;
      return;
    }
    if (macStore case final local?) {
      await local.update({key: value});
      return;
    }
    await _platformStore!.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    if (sandbox != null) return _values[key];
    if (macStore case final local?) return local.read(key);
    return _platformStore!.read(key: key);
  }

  Future<void> delete({required String key}) async {
    if (sandbox != null) {
      _values.remove(key);
      return;
    }
    if (macStore case final local?) {
      await local.update({key: null});
      return;
    }
    await _platformStore!.delete(key: key);
  }

  Future<void> deleteAll() async {
    if (sandbox != null) {
      _values.clear();
      return;
    }
    if (macStore case final local?) {
      await local.clear();
      return;
    }
    await _platformStore!.deleteAll();
  }
}
