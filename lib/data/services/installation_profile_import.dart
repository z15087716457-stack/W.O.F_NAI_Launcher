import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_secure_storage_windows/flutter_secure_storage_windows.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/settings/settings_preferences_service.dart';
import '../../core/settings/studio_settings_backups.dart';
import '../../core/settings/ui_scale_preference.dart';
import '../../core/shortcuts/shortcut_config.dart';
import '../../core/storage/application_storage.dart';
import '../../core/utils/gallery_path_utils.dart';
import '../models/auth/saved_account_directory.dart';
import '../models/precise_ref/precise_ref_library_entry.dart';
import 'precise_ref_library_storage_service.dart';

enum ProfileFolder { images, gallery, categories, vibes, references }

class InstallationProfile {
  InstallationProfile._(
    this.root,
    this.settings,
    this.accounts,
    this.folders,
    this.missing,
    this.hasGalleryList,
  );

  final Directory root;
  final StudioSettingsSnapshot settings;
  final SavedAccountDirectory accounts;
  final Map<ProfileFolder, List<String>> folders;
  final Set<String> missing;
  final bool hasGalleryList;

  /// Read a byte snapshot. Opening the selected box on disk could recover,
  /// compact or lock a database belonging to the other installation.
  static Future<T> _read<T>(File file, T Function(Box) decode) async {
    final box = await Hive.openBox(
      'import_${const Uuid().v4()}',
      bytes: await file.readAsBytes(),
    );
    try {
      return decode(box);
    } finally {
      await box.close();
    }
  }

  static Future<InstallationProfile?> inspect(
    Directory selected,
    Directory current, {
    Directory? legacyGallery,
  }) async {
    var root = Directory(p.join(selected.path, 'user-data'));
    if (!await root.exists()) root = selected;
    File boxFile(String name) => File(p.join(root.path, 'hive', '$name.hive'));
    final file = boxFile(StorageKeys.settingsBox);
    if (!await file.exists() ||
        p.equals(
          await root.resolveSymbolicLinks(),
          await current.resolveSymbolicLinks(),
        )) {
      return null;
    }
    final values = await _read(
      file,
      (box) => {
        for (final key in {
          ...SettingsPreferencesService.keys,
          ...UiScalePreference.legacyKeys,
          StorageKeys.imageSavePath,
          StorageKeys.gallerySourcePaths,
          StorageKeys.galleryExtraRoots,
          StorageKeys.galleryCategoryBasePath,
          StorageKeys.vibeLibrarySavePath,
          StorageKeys.preciseRefLibrarySavePath,
        })
          if (box.containsKey(key)) key: box.get(key),
      },
    );
    final accountsFile = boxFile(SavedAccountDirectory.boxName);
    final accounts = await accountsFile.exists()
        ? await _read(accountsFile, SavedAccountDirectory.read)
        : const SavedAccountDirectory([], {});
    final shortcutsFile = boxFile('shortcuts');
    final shortcutJson = await shortcutsFile.exists()
        ? await _read(
            shortcutsFile,
            (box) => box.get('shortcut_config') as String?,
          )
        : null;
    final prefs = UiScalePreference.migrate({
      for (final key in [
        ...SettingsPreferencesService.keys,
        ...UiScalePreference.legacyKeys,
      ])
        if (values[key] != null &&
            SettingsPreferencesService.validValue(key, values[key]))
          key: values[key],
    });
    final settings = StudioSettingsSnapshot(
      prefs,
      shortcutJson == null
          ? null
          : ShortcutConfig.fromJson(
              jsonDecode(shortcutJson) as Map<String, dynamic>,
            ).withCurrentDefaults(),
    );

    Future<String?> folder(String key, String fallback) async {
      final custom = values[key] as String?;
      if (custom != null && custom.isNotEmpty) return p.normalize(custom);
      final old = Directory(p.join(root.path, fallback));
      return await old.exists() ? old.path : null;
    }

    final images = await folder(StorageKeys.imageSavePath, 'images');
    final historicalGallery =
        (values[StorageKeys.imageSavePath] as String?)?.isNotEmpty != true &&
            legacyGallery != null &&
            await legacyGallery.exists()
        ? legacyGallery.path
        : null;
    final categoryBase =
        values[StorageKeys.galleryCategoryBasePath] as String? ??
        historicalGallery ??
        images;
    final configured = values[StorageKeys.gallerySourcePaths] as List?;
    final extra = values[StorageKeys.galleryExtraRoots] as List?;
    final sources =
        configured?.cast<String>() ??
        [
          if (images != null) images,
          if (historicalGallery != null) historicalGallery,
          ...?extra?.cast<String>(),
        ];
    final folders = <ProfileFolder, List<String>>{
      ProfileFolder.images: [if (images != null) images],
      ProfileFolder.gallery: galleryDistinctRoots(sources),
      ProfileFolder.categories: [
        if (categoryBase != null && categoryBase.isNotEmpty) categoryBase,
      ],
      ProfileFolder.vibes: [
        if (await folder(StorageKeys.vibeLibrarySavePath, 'vibes')
            case final path?)
          path,
      ],
      ProfileFolder.references: [
        if (await folder(StorageKeys.preciseRefLibrarySavePath, 'precise_refs')
            case final path?)
          path,
      ],
    };
    final missing = <String>{};
    for (final path in folders.values.expand((items) => items).toSet()) {
      if (!await Directory(path).exists()) missing.add(path);
    }
    return InstallationProfile._(
      root,
      settings,
      accounts,
      folders,
      missing,
      configured != null,
    );
  }

  /// Missing directories can be remapped once for every role that uses them.
  /// Skipping all missing sources keeps the destination's gallery configuration;
  /// an explicitly empty source list in the old version is meaningful.
  Future<Map<String, Object>> folderSettings(
    Map<String, String> replacements,
  ) async {
    final resolved = <String, String>{};
    for (final path in folders.values.expand((items) => items).toSet()) {
      final target = replacements[path] ?? path;
      if ((!missing.contains(path) || replacements.containsKey(path)) &&
          await Directory(target).exists()) {
        resolved[path] = target;
      }
    }
    final result = <String, Object>{};
    const keys = {
      ProfileFolder.images: StorageKeys.imageSavePath,
      ProfileFolder.categories: StorageKeys.galleryCategoryBasePath,
      ProfileFolder.vibes: StorageKeys.vibeLibrarySavePath,
      ProfileFolder.references: StorageKeys.preciseRefLibrarySavePath,
    };
    for (final entry in keys.entries) {
      final value = resolved[folders[entry.key]?.firstOrNull];
      if (value != null) result[entry.value] = value;
    }
    final sources = folders[ProfileFolder.gallery]!;
    final mapped = galleryDistinctRoots(
      sources.map((path) => resolved[path]).whereType<String>(),
    );
    if (mapped.isNotEmpty || (hasGalleryList && sources.isEmpty)) {
      result[StorageKeys.gallerySourcePaths] = mapped;
    }
    return result;
  }

  Future<void> linkReferences(
    PreciseRefLibraryStorageService library,
    String target,
  ) async {
    final file = File(
      p.join(
        root.path,
        'hive',
        '${PreciseRefLibraryStorageService.entriesBoxName}.hive',
      ),
    );
    if (!await file.exists()) return;
    PreciseRefLibraryStorageService.registerEntryAdapter();
    final entries = await _read(
      file,
      (box) => box.values.cast<PreciseRefLibraryEntry>().toList(),
    );
    await library.linkExistingEntries(
      entries,
      folders[ProfileFolder.references]!.single,
      target,
    );
  }

  Future<Map<String, String>> readAccountCredentials() {
    final keys = {
      for (final account in accounts.accounts) ...[
        '${StorageKeys.accountTokenPrefix}${account.id}',
        '${StorageKeys.accountAccessKeyPrefix}${account.id}',
      ],
    };
    final rootPath = root.path;
    return Isolate.run(() => _readAccountCredentials(rootPath, keys));
  }
}

Future<Map<String, String>> _readAccountCredentials(
  String root,
  Set<String> keys,
) async {
  const filename = 'flutter_secure_storage.dat';
  final file = File(p.join(root, filename));
  if (keys.isEmpty || !await file.exists()) return {};
  // The Windows plugin removes unreadable files during recovery. Point its
  // isolate-local path provider at an encrypted scratch copy, never the source.
  final scratch = await Directory.systemTemp.createTemp('studio-profile-');
  try {
    await file.copy(p.join(scratch.path, filename));
    initializeApplicationStorage(scratch);
    final native = FlutterSecureStorageWindows();
    const options = {'useBackwardCompatibility': 'false'};
    final values = await native.readAll(options: options);
    return {
      for (final key in keys)
        if (values[key] case final value? when value.isNotEmpty) key: value,
    };
  } on Exception {
    // An unreadable or other-user DPAPI store still has usable account records.
    return {};
  } finally {
    await scratch.delete(recursive: true);
  }
}
