import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../ui/settings/settings_contract.dart';

/// Persist only the measured summary, not the potentially large per-file walk.
class SettingsStorageSnapshotStore {
  static const key = 'settings_storage_snapshot_v1';

  SettingsStorageData? read(String signature) {
    final raw = LocalStorageService().getSetting<String>(key);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['signature'] != signature) return null;
      return SettingsStorageData(
        configurationKey: signature,
        measuredAt: DateTime.parse(value['at'] as String),
        slices: [
          for (final s in value['slices'] as List)
            SettingsStorageSlice(
              SettingsStorageKind.values.byName(s['kind'] as String),
              s['bytes'] as int,
              paths: (s['paths'] as List).cast<String>(),
            ),
        ],
        roots: [
          for (final r in value['roots'] as List)
            SettingsGalleryRoot(
              id: r['path'] as String,
              path: r['path'] as String,
              images: r['images'] as int,
              primary: r['primary'] as bool,
            ),
        ],
        imageCount: value['images'] as int,
        thumbnailBytes: value['thumbBytes'] as int,
        thumbnailCount: value['thumbCount'] as int,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  Future<void> save(String signature, SettingsStorageData data) async {
    if (!Hive.isBoxOpen(StorageKeys.settingsBox)) return;
    await LocalStorageService().setSetting(
      key,
      jsonEncode({
        'signature': signature,
        'at': data.measuredAt!.toIso8601String(),
        'slices': [
          for (final s in data.slices)
            {'kind': s.kind.name, 'bytes': s.bytes, 'paths': s.paths},
        ],
        'roots': [
          for (final r in data.roots)
            {'path': r.path, 'images': r.images, 'primary': r.primary},
        ],
        'images': data.imageCount,
        'thumbBytes': data.thumbnailBytes,
        'thumbCount': data.thumbnailCount,
      }),
    );
  }
}

final settingsStorageSnapshotStoreProvider = Provider(
  (ref) => SettingsStorageSnapshotStore(),
);
final settingsStorageManualRefreshProvider = StateProvider<bool>(
  (ref) => false,
);
