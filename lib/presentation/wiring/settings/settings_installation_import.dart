import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/storage_keys.dart';
import '../../../core/settings/studio_settings_backups.dart';
import '../../../core/utils/app_support_directory.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/repositories/gallery_folder_repository.dart';
import '../../../data/services/installation_profile_import.dart';
import '../../../data/services/precise_ref_library_storage_service.dart';
import '../../../data/services/vibe_library_storage_service.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/image_save_settings_provider.dart';
import '../../providers/gallery_category_provider.dart';
import '../../providers/precise_ref_library_provider.dart';
import '../../providers/vibe_library_provider.dart';
import '../../ui/settings/settings_dialog_kit.dart';
import '../../ui/settings/settings_kit.dart';
import 'settings_backups.dart';
import 'settings_dialogs.dart';
import 'settings_edits.dart';
import 'settings_inventory.dart';

Future<void> importInstallation(SettingsBackupActions backup) async {
  final context = backup.context;
  final ref = backup.ref;
  final path = await FilePicker.platform.getDirectoryPath();
  if (path == null || !context.mounted) return;
  final current = await getApplicationSupportDirectory();
  final docs = await getApplicationDocumentsDirectory();
  final profile = await InstallationProfile.inspect(
    Directory(path),
    current,
    legacyGallery: Directory(p.join(docs.path, 'NAI_Launcher', 'images')),
  );
  if (!context.mounted) return;
  if (profile == null) {
    return settingsNotice(
      context,
      context.l10n.set_importInstallation,
      context.l10n.set_importInstallationInvalid,
    );
  }
  final service = await backup.ready();
  final expected = service.capture();
  final box = Hive.box(StorageKeys.settingsBox);
  const folderKeys = [
    StorageKeys.imageSavePath,
    StorageKeys.gallerySourcePaths,
    StorageKeys.galleryCategoryBasePath,
    StorageKeys.vibeLibrarySavePath,
    StorageKeys.preciseRefLibrarySavePath,
  ];
  final before = {for (final key in folderKeys) key: box.get(key)};
  if (!context.mounted) return;
  final replacements = await showSettingsDialog<Map<String, String>>(
    context,
    (_) => InstallationImportPreview(
      profile: profile,
      chooseDirectory: () => FilePicker.platform.getDirectoryPath(),
    ),
  );
  if (replacements == null || !context.mounted) return;
  final paths = await profile.folderSettings(replacements);
  final credentials = await profile.readAccountCredentials();
  if (!context.mounted) return;
  ({int added, int withoutToken})? result;
  var vibeSyncFailed = false;
  await ref.read(settingsEditsProvider.notifier).transaction(() async {
    if (paths.keys.any(
      (key) =>
          !const DeepCollectionEquality().equals(before[key], box.get(key)),
    )) {
      return;
    }
    final changes = StudioSettingsSnapshot(
      {
        for (final entry in profile.settings.preferences.entries)
          if (expected.preferences[entry.key] != entry.value)
            entry.key: entry.value,
      },
      expected.shortcuts == profile.settings.shortcuts
          ? null
          : profile.settings.shortcuts,
    );
    if (changes.preferences.isNotEmpty || changes.shortcuts != null) {
      await service.apply(changes, expected: expected);
    }
    result = await ref
        .read(accountManagerNotifierProvider.notifier)
        .importMissingAccounts(profile.accounts, credentials);
    if (paths.isNotEmpty) {
      await box.putAll(paths);
      ref.invalidate(imageSaveSettingsNotifierProvider);
      ref.invalidate(galleryCategoryNotifierProvider);
      GalleryFolderRepository.instance.notifyRootsChanged();
      ref.invalidate(settingsFoldersProvider);
      ref.invalidate(settingsGallerySourcesProvider);
      if (paths[StorageKeys.preciseRefLibrarySavePath]
          case final String target) {
        await profile.linkReferences(
          ref.read(preciseRefLibraryStorageServiceProvider),
          target,
        );
        if (ref.exists(preciseRefLibraryNotifierProvider)) {
          await ref.read(preciseRefLibraryNotifierProvider.notifier).reload();
        }
      }
      if (paths.containsKey(StorageKeys.vibeLibrarySavePath)) {
        final sync = await ref
            .read(vibeLibraryStorageServiceProvider)
            .syncWithFileSystem(removeMissingEntries: false);
        vibeSyncFailed = sync.failedCount > 0;
        if (ref.exists(vibeLibraryNotifierProvider)) {
          await ref.read(vibeLibraryNotifierProvider.notifier).reload();
        }
      }
    }
    backup.refresh();
  });
  if (context.mounted) {
    final imported = result;
    await settingsNotice(
      context,
      context.l10n.set_importInstallation,
      imported == null
          ? context.l10n.set_importInstallationChanged
          : [
              context.l10n.set_importInstallationDone(
                imported.added,
                imported.withoutToken,
              ),
              if (vibeSyncFailed)
                '${context.l10n.set_stVibes} · ${context.l10n.vibe_import_importFailed}',
            ].join('\n'),
    );
  }
}

class InstallationImportPreview extends StatefulWidget {
  const InstallationImportPreview({
    super.key,
    required this.profile,
    required this.chooseDirectory,
  });
  final InstallationProfile profile;
  final Future<String?> Function() chooseDirectory;
  @override
  State<InstallationImportPreview> createState() =>
      _InstallationImportPreviewState();
}

class _InstallationImportPreviewState extends State<InstallationImportPreview> {
  final replacements = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = widget.profile;
    final labels = {
      ProfileFolder.images: l.set_stSavePath,
      ProfileFolder.gallery: l.set_stRoots,
      ProfileFolder.categories: l.set_importCategoryBase,
      ProfileFolder.vibes: l.set_stVibePath,
      ProfileFolder.references: l.set_stPrPath,
    };
    final roles = <String, List<String>>{};
    for (final entry in profile.folders.entries) {
      for (final path in entry.value) {
        roles.putIfAbsent(path, () => []).add(labels[entry.key]!);
      }
    }
    return SettingsDialogFrame(
      title: l.set_importInstallation,
      width: 560,
      subtitle: Text(
        l.set_importInstallationPreview(
          profile.accounts.accounts.length,
          profile.settings.preferences.length,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(profile.root.path),
            if (profile.settings.shortcuts != null) Text(l.set_pageShortcuts),
            if (profile.hasGalleryList &&
                profile.folders[ProfileFolder.gallery]!.isEmpty)
              Text(l.set_importEmptyGallery),
            for (final entry in roles.entries)
              SettingsRow(
                title: entry.value.join(' · '),
                subtitle: [
                  replacements[entry.key] ?? entry.key,
                  if (profile.missing.contains(entry.key) &&
                      !replacements.containsKey(entry.key))
                    l.set_importMissingFolder,
                ].join('\n'),
                control: profile.missing.contains(entry.key)
                    ? SettingsBtn(
                        label: l.set_choose,
                        small: true,
                        onTap: () async {
                          final path = await widget.chooseDirectory();
                          if (mounted && path != null) {
                            setState(() => replacements[entry.key] = path);
                          }
                        },
                      )
                    : null,
              ),
          ],
        ),
      ),
      actions: [
        SettingsBtn(
          label: l.common_cancel,
          onTap: () => Navigator.pop(context),
        ),
        SettingsBtn(
          label: l.set_importIt,
          tone: SettingsBtnTone.primary,
          onTap: () => Navigator.pop(context, replacements),
        ),
      ],
    );
  }
}
