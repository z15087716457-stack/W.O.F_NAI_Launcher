import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/prompt_assistant_models.dart';

final providerModelListCacheProvider = Provider<ProviderModelListCache>(
  (ref) => ProviderModelListCache(ref.watch(localStorageServiceProvider)),
);

/// Explicit discovery results only. Selection and bundled facts stay separate.
class ProviderModelListCache {
  ProviderModelListCache(this._storage);
  final LocalStorageService _storage;
  Future<void> _pending = Future.value();

  static String fingerprint(
    ProviderConfig provider,
    String? apiKey,
    Map<String, String> headers,
  ) => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            (provider.preset ?? ProviderPreset.openaiCompatibleChat).name,
            provider.protocol.name,
            provider.baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
            apiKey?.trim() ?? '',
            for (final name in headers.keys.toList()..sort())
              [name, headers[name]],
          ]),
        ),
      )
      .toString();

  Map<String, dynamic> _read() {
    try {
      final raw = _storage.getSetting<String>(
        StorageKeys.providerModelListCacheV1,
      );
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['providers'] is! Map) {
        return {};
      }
      return Map<String, dynamic>.from(decoded['providers'] as Map);
    } catch (_) {
      return {};
    }
  }

  List<String>? modelsFor(String providerId, String connection) {
    final entry = _read()[providerId];
    if (entry is! Map ||
        entry['connection'] != connection ||
        entry['models'] is! List) {
      return null;
    }
    final models = entry['models'] as List;
    if (models.any((id) => id is! String || id.trim().isEmpty)) return null;
    return List<String>.unmodifiable(models.cast<String>().toSet());
  }

  Future<bool> save(String providerId, String connection, List<String> models) {
    final ids = models
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    return _change(
      (providers) =>
          providers[providerId] = {'connection': connection, 'models': ids},
    );
  }

  Future<bool> remove(String providerId) =>
      _change((providers) => providers.remove(providerId));

  Future<bool> _change(void Function(Map<String, dynamic>) update) {
    final operation = _pending.then((_) async {
      final providers = _read();
      update(providers);
      try {
        await _storage.setSetting(
          StorageKeys.providerModelListCacheV1,
          jsonEncode({'version': 1, 'providers': providers}),
        );
        return true;
      } catch (_) {
        AppLogger.w('Model list cache write failed.', 'PromptAssistant');
        return false;
      }
    });
    _pending = operation.then((_) {});
    return operation;
  }
}
