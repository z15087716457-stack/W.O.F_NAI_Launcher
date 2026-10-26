import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';

import '../../../core/settings/settings_preferences_service.dart';
import '../../../core/autocomplete/autocomplete_settings.dart' as autocomplete;
import '../../../core/settings/studio_settings_backups.dart';
import '../../../core/shortcuts/shortcut_config.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/canvas_settings_provider.dart';
import '../../providers/font_provider.dart';
import '../../providers/font_scale_provider.dart';
import '../../providers/generation/generation_settings_notifiers.dart';
import '../../providers/history_click_behavior_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/settings_font_scale_provider.dart';
import '../../providers/share_image_settings_provider.dart';
import '../../providers/shortcuts_provider.dart';
import '../../providers/simple_output_viewer_provider.dart';
import '../../providers/simple_viewer_group_batches_provider.dart';
import '../../providers/theme_provider.dart';
import '../../ui/settings/settings_contract.dart';
import 'settings_dialogs.dart';
import 'settings_edits.dart';
import 'settings_values.dart';

final settingsBackupDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory(
        p.join(
          (await getApplicationSupportDirectory()).path,
          'settings_backups',
          'v2',
        ),
      ),
);
final settingsBackupsProvider = FutureProvider(
  (ref) async => StudioSettingsBackups(
    preferences: SettingsPreferencesService(
      ref.read(localStorageServiceProvider),
    ),
    directory: await ref.read(settingsBackupDirectoryProvider)(),
    readShortcuts: () => ref.read(shortcutConfigNotifierProvider).requireValue,
    writeShortcuts: (config) => ref
        .read(shortcutConfigNotifierProvider.notifier)
        .importConfig(jsonEncode(config.toJson())),
  ),
);
final settingsBackupDataProvider = FutureProvider((ref) async {
  final service = await ref.watch(settingsBackupsProvider.future);
  final config = await ref.watch(shortcutConfigNotifierProvider.future);
  final defaults = ShortcutConfig.createDefault();
  return SettingsBackupData(
    lastImportAt: await service.lastImportAt(),
    backups: [
      for (final record in (await service.list()).take(5))
        SettingsBackup(
          id: record.id,
          at: record.at,
          kind:
              SettingsBackupKind.values
                  .where((kind) => kind.name == record.reason)
                  .firstOrNull ??
              SettingsBackupKind.upgrade,
        ),
    ],
    shortcutsCustomized: config.bindings.values
        .where(
          (binding) =>
              binding.effectiveShortcut !=
              defaults.bindings[binding.id]?.effectiveShortcut,
        )
        .length,
  );
});

class SettingsBackupActions {
  SettingsBackupActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;
  Future<StudioSettingsBackups> ready() async {
    await ref.read(shortcutConfigNotifierProvider.future);
    return ref.read(settingsBackupsProvider.future);
  }

  void refresh() {
    ref.invalidate(themeNotifierProvider);
    ref.invalidate(fontNotifierProvider);
    ref.invalidate(fontScaleNotifierProvider);
    ref.invalidate(settingsFontScaleProvider);
    ref.invalidate(localeNotifierProvider);
    ref.invalidate(historyClickBehaviorNotifierProvider);
    ref.invalidate(simpleOutputViewerNotifierProvider);
    ref.invalidate(simpleViewerGroupBatchesProvider);
    ref.invalidate(canvasLockCameraNotifierProvider);
    ref.invalidate(canvasReducedMotionNotifierProvider);
    ref.invalidate(canvasZoomToFillNotifierProvider);
    ref.invalidate(notificationSettingsNotifierProvider);
    ref.invalidate(shareImageSettingsProvider);
    ref.invalidate(promptWeightScrollSettingsProvider);
    ref.invalidate(promptWeightScrollModifierSettingsProvider);
    ref.invalidate(cooccurrenceSettingsProvider);
    ref.invalidate(autocomplete.autocompleteSettingsProvider);
    ref.invalidate(settingsBackupDataProvider);
    ref.read(settingsRefreshProvider.notifier).state++;
  }

  Future<void> exportConfig() async {
    final service = await ready();
    final raw = service.encode(service.capture());
    if (!context.mounted) return;
    final path = await FilePicker.platform.saveFile(
      fileName: 'studio-preferences.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path != null) await File(path).writeAsString(raw, flush: true);
  }

  Future<void> importConfig() async {
    final service = await ready();
    // Capture before opening the picker/confirmation, never after a newer edit.
    final expected = service.capture();
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = selected?.files.single.path;
    if (path == null || !context.mounted) return;
    final file = File(path);
    if (await file.length() > 1024 * 1024) {
      throw const FormatException('Preference file is too large');
    }
    final changes = service.decode(await file.readAsString());
    if (!context.mounted ||
        !await settingsConfirm(
          context,
          context.l10n.settings_importPreferences,
          context.l10n.settings_applyPreferencesConfirm(
            changes.preferences.length,
          ),
        ) ||
        !context.mounted) {
      return;
    }
    await ref.read(settingsEditsProvider.notifier).transaction(() async {
      await service.apply(changes, expected: expected);
      refresh();
    });
  }

  Future<void> restore(String id) async {
    final service = await ready();
    final expected = service.capture();
    final changes = await service.read(id);
    await ref.read(settingsEditsProvider.notifier).transaction(() async {
      await service.apply(changes, expected: expected, reason: 'reset');
      refresh();
    });
  }

  Future<void> undoImport() async {
    final service = await ready();
    await ref.read(settingsEditsProvider.notifier).transaction(() async {
      await service.undoImport();
      refresh();
    });
  }

  Future<void> reset(Set<SettingsResetScope> scopes) async {
    final service = await ready();
    final expected = service.capture();
    final groups = {
      for (final scope in scopes)
        if (scope != SettingsResetScope.shortcuts)
          PreferenceGroup.values.byName(scope.name),
    };
    await ref.read(settingsEditsProvider.notifier).transaction(() async {
      await service.apply(
        StudioSettingsSnapshot(
          service.preferences.defaults(groups),
          scopes.contains(SettingsResetScope.shortcuts)
              ? expected.shortcuts!.copyWith(
                  bindings: ShortcutConfig.createDefault().bindings,
                )
              : null,
        ),
        expected: expected,
        reason: 'reset',
      );
      refresh();
    });
  }
}
