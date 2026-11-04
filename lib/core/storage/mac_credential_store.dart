import 'package:flutter/services.dart';

class LocalCredentialStoreException implements Exception {
  const LocalCredentialStoreException({this.corrupt = false});
  final bool corrupt;
}

/// All Mac credential types share one encrypted, per-user file. The native
/// backend owns permissions, inter-process locking and atomic replacement.
class MacCredentialStore {
  const MacCredentialStore();
  static const _channel = MethodChannel('com.wof.naiStudio/local_credentials');

  Future<T?> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      throw const LocalCredentialStoreException();
    } on PlatformException catch (error) {
      throw LocalCredentialStoreException(
        corrupt: error.code == 'local_credential_corrupt',
      );
    }
  }

  Future<String?> read(String key) => _call<String>('read', {'key': key});
  Future<Map<String, String?>> update(
    Map<String, String?> changes, {
    Map<String, String?>? expected,
  }) async {
    final previous = await _call<Map<Object?, Object?>>('update', {
      'changes': changes,
      if (expected != null) 'expected': expected,
    });
    if (previous == null) throw const LocalCredentialStoreException();
    return Map<String, String?>.from(previous);
  }

  Future<bool> resetIfCorrupt() async =>
      await _call<bool>('resetCorrupt') ?? false;

  Future<void> clear() => _call<void>('clear');
}
