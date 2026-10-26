import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/autocomplete/autocomplete_settings.dart'
    as autocomplete;
import '../../../../core/settings/settings_preferences_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/font_provider.dart';
import '../../../providers/font_scale_provider.dart';
import '../../../providers/settings_font_scale_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/history_click_behavior_provider.dart';
import '../../../providers/simple_output_viewer_provider.dart';
import '../../../providers/simple_viewer_group_batches_provider.dart';
import '../../../providers/thumbnail_cache_limit_provider.dart';
import '../../../providers/canvas_settings_provider.dart';
import '../../../providers/notification_settings_provider.dart';
import '../../../providers/share_image_settings_provider.dart';
import '../../../providers/generation/generation_settings_notifiers.dart'
    as generation;
import '../../../widgets/common/app_toast.dart';
import 'settings_card.dart';
import 'settings_labeled_group.dart';
import 'settings_tile.dart';

class SettingsPreferencesPanel extends ConsumerStatefulWidget {
  const SettingsPreferencesPanel({super.key, this.labeled = false});
  final bool labeled;
  @override
  ConsumerState<SettingsPreferencesPanel> createState() =>
      _SettingsPreferencesPanelState();
}

class _SettingsPreferencesPanelState
    extends ConsumerState<SettingsPreferencesPanel> {
  bool busy = false;
  SettingsPreferencesService get service =>
      SettingsPreferencesService(ref.read(localStorageServiceProvider));
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          '${context.l10n.settings_actionIncomplete}: $error',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
    ref.invalidate(thumbnailCacheLimitGbProvider);
    ref.invalidate(canvasLockCameraNotifierProvider);
    ref.invalidate(canvasReducedMotionNotifierProvider);
    ref.invalidate(canvasZoomToFillNotifierProvider);
    ref.invalidate(notificationSettingsNotifierProvider);
    ref.invalidate(shareImageSettingsProvider);
    ref.invalidate(autocomplete.autocompleteSettingsProvider);
    ref.invalidate(generation.autocompleteSettingsProvider);
    ref.invalidate(generation.promptWeightScrollSettingsProvider);
    ref.invalidate(generation.promptWeightScrollModifierSettingsProvider);
  }

  Future<void> exportPreferences() => run(() async {
    final raw = service.encode(service.capture());
    final path = await FilePicker.platform.saveFile(
      dialogTitle: context.l10n.settings_exportPreferences,
      fileName: 'studio-preferences.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return;
    await File(path).writeAsString(raw, flush: true);
    if (mounted) {
      AppToast.success(context, context.l10n.settings_preferencesExported);
    }
  });
  Future<void> importPreferences([bool latest = false]) => run(() async {
    final l10n = context.l10n;
    File? file;
    if (latest) {
      file = await service.latestBackup();
    } else {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = selection?.files.single.path;
      if (path == null) return;
      file = File(path);
    }
    if (file == null) {
      if (mounted) {
        AppToast.info(context, context.l10n.settings_noAutomaticBackupYet);
      }
      return;
    }
    if (await file.length() > 1024 * 1024) {
      throw const FormatException('Preference file is too large.');
    }
    final values = service.decode(await file.readAsString());
    await confirmApply(
      values,
      latest
          ? l10n.settings_restorePreviousPreferences
          : l10n.settings_importPreferences,
    );
  });
  Future<void> confirmApply(Map<String, Object?> values, String title) async {
    if (!mounted) return;
    final expected = service.capture();
    final allowed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(
              context.l10n.settings_applyPreferencesConfirm(values.length),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.l10n.settings_apply),
              ),
            ],
          ),
        ) ??
        false;
    if (!allowed || !mounted) return;
    await service.apply(values, expected: expected);
    refresh();
    if (mounted) {
      AppToast.success(
        context,
        context.l10n.settings_preferencesAppliedPreviousSettingsBacked,
      );
    }
  }

  Future<void> reset() => run(() async {
    final selected = <PreferenceGroup>{PreferenceGroup.appearance};
    final groups = await showDialog<Set<PreferenceGroup>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.l10n.settings_restoreDefaultPreferences),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.settings_choosePreferencesResetCurrentSettings),
              for (final group in PreferenceGroup.values)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(group),
                  onChanged: (value) => setDialogState(() {
                    if (value == true) {
                      selected.add(group);
                    } else {
                      selected.remove(group);
                    }
                  }),
                  title: Text(switch (group) {
                    PreferenceGroup.appearance =>
                      context.l10n.settings_appearanceSoundControls,
                    PreferenceGroup.input =>
                      context.l10n.settings_inputAutocomplete,
                    PreferenceGroup.protection =>
                      context.l10n.settings_privacyGenerationProtection,
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.common_cancel),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, Set<PreferenceGroup>.of(selected)),
              child: Text(context.l10n.common_continue),
            ),
          ],
        ),
      ),
    );
    if (groups != null && mounted) {
      await confirmApply(
        service.defaults(groups),
        context.l10n.settings_restoreDefaultPreferences,
      );
    }
  });
  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        SettingsTile(
          hoverFeedback: !busy,
          title: Text(context.l10n.settings_preferenceBackupRestore),
          subtitle: Text(
            context.l10n.settings_moveAppearanceControlsInputProtection,
          ),
          trailing: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                key: const Key('preferences-export'),
                onPressed: busy ? null : exportPreferences,
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: Text(context.l10n.common_export),
              ),
              OutlinedButton.icon(
                key: const Key('preferences-import'),
                onPressed: busy ? null : importPreferences,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(context.l10n.common_import),
              ),
            ],
          ),
        ),
        SettingsTile(
          hoverFeedback: !busy,
          title: Text(context.l10n.settings_restorePreviousPreferences),
          subtitle: Text(context.l10n.settings_rollbackCopySavedBeforeImport),
          trailing: OutlinedButton(
            key: const Key('preferences-restore-previous'),
            onPressed: busy ? null : () => importPreferences(true),
            child: Text(context.l10n.settings_restore),
          ),
          onTap: busy ? null : () => importPreferences(true),
        ),
        SettingsTile(
          hoverFeedback: !busy,
          title: Text(context.l10n.settings_restoreDefaultPreferences),
          subtitle: Text(context.l10n.settings_resetSelectedScopeWhileKeeping),
          trailing: OutlinedButton(
            key: const Key('preferences-restore-defaults'),
            onPressed: busy ? null : reset,
            child: Text(context.l10n.settings_chooseScope),
          ),
          onTap: busy ? null : reset,
        ),
      ],
    );
    if (widget.labeled) {
      return SettingsLabeledGroup(
        key: const Key('about-preferences-group'),
        title: context.l10n.settings_preferenceManagement,
        description: context.l10n.settings_backupMigrationRecovery,
        child: content,
      );
    }
    return SettingsCard(
      title: context.l10n.settings_preferenceManagement,
      child: content,
    );
  }
}
