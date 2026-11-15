import 'dart:io';

import 'package:path/path.dart' as p;

import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';
import 'app_support_directory.dart';
import 'file_system_utils.dart';

/// Vibe files default to the prepared application data directory. Existing
/// library entries retain their original absolute paths.
class VibeLibraryPathHelper {
  VibeLibraryPathHelper._();
  static final VibeLibraryPathHelper instance = VibeLibraryPathHelper._();

  final _localStorage = LocalStorageService();
  String? _cachedDefaultPath;

  String? getCustomPath() =>
      _localStorage.getSetting<String>(StorageKeys.vibeLibrarySavePath);

  bool get hasCustomPath => getCustomPath()?.isNotEmpty ?? false;

  Future<String> getPath() async {
    final custom = getCustomPath();
    return custom != null && custom.isNotEmpty ? custom : getDefaultPath();
  }

  String? getPathSync() => hasCustomPath ? getCustomPath() : _cachedDefaultPath;

  Future<String> getDefaultPath() async =>
      _cachedDefaultPath ??= await getUserAssetPath('vibes');

  /// Keep files from the former default discoverable without copying them or
  /// creating duplicate library entries. A custom directory remains explicit.
  Future<List<String>> getReadPaths() async {
    final current = await getPath();
    if (hasCustomPath) return [current];
    final docs = await getApplicationDocumentsDirectory();
    for (final legacy in [
      p.join(docs.path, 'NAI_Launcher', 'vibes'),
      p.join(docs.path, 'vibes'),
    ]) {
      final directory = Directory(legacy);
      if (legacy != current &&
          await directory.exists() &&
          !(await directory.list().isEmpty)) {
        // The old migration kept a copy in Documents/vibes. Prefer its newer
        // NAI_Launcher location so those retained copies do not reappear twice.
        return [current, legacy];
      }
    }
    return [current];
  }

  Future<void> setPath(String? path) async {
    if (path != null && path.isNotEmpty) {
      await _localStorage.setSetting(StorageKeys.vibeLibrarySavePath, path);
    } else {
      await _localStorage.deleteSetting(StorageKeys.vibeLibrarySavePath);
    }
  }

  Future<void> resetToDefault() async {
    await setPath(null);
    clearCache();
  }

  Future<bool> ensurePathExists(String path) =>
      FileSystemUtils.ensureDirectory(path, logTag: 'VibeLibrary');

  String getDisplayPath([String defaultLabel = '默认']) =>
      getCustomPath() ?? defaultLabel;

  void clearCache() => _cachedDefaultPath = null;
}
