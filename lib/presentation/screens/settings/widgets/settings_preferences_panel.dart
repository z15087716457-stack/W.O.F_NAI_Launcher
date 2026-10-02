import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/autocomplete/autocomplete_settings.dart'
    as autocomplete;
import '../../../../core/settings/settings_preferences_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/font_provider.dart';
import '../../../providers/font_scale_provider.dart';
import '../../../providers/settings_font_scale_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/history_click_behavior_provider.dart';
import '../../../providers/simple_output_viewer_provider.dart';
import '../../../providers/canvas_settings_provider.dart';
import '../../../providers/notification_settings_provider.dart';
import '../../../providers/share_image_settings_provider.dart';
import '../../../providers/generation/generation_settings_notifiers.dart'
    as generation;
import '../../../widgets/common/app_toast.dart';
import 'settings_card.dart';
import 'settings_tile.dart';
import 'settings_ui_theme.dart';

class SettingsPreferencesPanel extends ConsumerStatefulWidget {
  const SettingsPreferencesPanel({super.key});
  @override
  ConsumerState<SettingsPreferencesPanel> createState() =>
      _SettingsPreferencesPanelState();
}

class _SettingsPreferencesPanelState
    extends ConsumerState<SettingsPreferencesPanel> {
  bool busy = false;
  SettingsPreferencesService get service =>
      SettingsPreferencesService(ref.read(localStorageServiceProvider));
  String text(String zh, String en, String ja) =>
      settingsText(context, zh, en, ja);
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          '${text('操作未完成', 'Action incomplete', '操作は完了しませんでした')}: $error',
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
      dialogTitle: text('导出偏好', 'Export preferences', '設定をエクスポート'),
      fileName: 'studio-preferences.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null) return;
    await File(path).writeAsString(raw, flush: true);
    if (mounted) {
      AppToast.success(
        context,
        text('偏好已导出', 'Preferences exported', '設定をエクスポートしました'),
      );
    }
  });
  Future<void> importPreferences([bool latest = false]) => run(() async {
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
        AppToast.info(
          context,
          text('尚无自动回退备份', 'No automatic backup yet', '自動バックアップはまだありません'),
        );
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
          ? text('恢复上次偏好', 'Restore previous preferences', '前の設定に復元')
          : text('导入偏好', 'Import preferences', '設定をインポート'),
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
              text(
                '将应用 ${values.length} 项偏好。当前偏好会自动备份，可从“恢复上次偏好”找回。账号、密钥、草稿、图库和模型配置保持独立。',
                'Apply ${values.length} preferences. Current preferences are backed up automatically. Accounts, secrets, drafts, libraries and model configurations are kept separately.',
                '${values.length} 件の設定を適用します。現在の設定は自動保存されます。アカウント、認証情報、下書き、ライブラリ、モデル設定は個別に保持されます。',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(text('取消', 'Cancel', 'キャンセル')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(text('确认应用', 'Apply', '適用')),
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
        text(
          '偏好已应用，旧设置已自动备份',
          'Preferences applied; previous settings backed up',
          '設定を適用し、以前の設定を保存しました',
        ),
      );
    }
  }

  Future<void> reset() => run(() async {
    final selected = <PreferenceGroup>{PreferenceGroup.appearance};
    final groups = await showDialog<Set<PreferenceGroup>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            text('恢复默认偏好', 'Restore default preferences', '既定の設定に戻す'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text(
                  '选择需要恢复的范围，当前偏好将自动备份。',
                  'Choose the preferences to reset. Current settings will be backed up.',
                  'リセットする項目を選択します。現在の設定は保存されます。',
                ),
              ),
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
                    PreferenceGroup.appearance => text(
                      '外观、声音与操作',
                      'Appearance, sound & controls',
                      '外観・サウンド・操作',
                    ),
                    PreferenceGroup.input => text(
                      '输入与自动补全',
                      'Input & autocomplete',
                      '入力と自動補完',
                    ),
                    PreferenceGroup.protection => text(
                      '隐私与生成保护',
                      'Privacy & generation protection',
                      'プライバシーと生成の保護',
                    ),
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(text('取消', 'Cancel', 'キャンセル')),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, Set<PreferenceGroup>.of(selected)),
              child: Text(text('继续', 'Continue', '続行')),
            ),
          ],
        ),
      ),
    );
    if (groups != null) {
      await confirmApply(
        service.defaults(groups),
        text('恢复默认偏好', 'Restore default preferences', '既定の設定に戻す'),
      );
    }
  });
  @override
  Widget build(BuildContext context) => SettingsCard(
    title: text('偏好管理', 'Preference management', '設定の管理'),
    child: Column(
      children: [
        SettingsTile(
          hoverFeedback: !busy,
          title: Text(
            text('偏好备份与恢复', 'Preference backup & restore', '設定のバックアップと復元'),
          ),
          subtitle: Text(
            text(
              '界面、操作、输入和保护偏好，可跨设备迁移。',
              'Move appearance, controls, input and protection preferences between devices.',
              '外観・操作・入力・保護の設定を他の端末へ移行できます。',
            ),
          ),
          trailing: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : exportPreferences,
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: Text(text('导出', 'Export', 'エクスポート')),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : importPreferences,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(text('导入', 'Import', 'インポート')),
              ),
            ],
          ),
        ),
        SettingsTile(
          title: Text(
            text('恢复上次偏好', 'Restore previous preferences', '前の設定に復元'),
          ),
          subtitle: Text(
            text(
              '导入或恢复默认前会自动保存回退副本。',
              'A rollback copy is saved before an import or reset.',
              'インポートやリセットの前に元の設定を自動保存します。',
            ),
          ),
          onTap: busy ? null : () => importPreferences(true),
        ),
        SettingsTile(
          title: Text(
            text('恢复默认偏好', 'Restore default preferences', '既定の設定に戻す'),
          ),
          subtitle: Text(
            text(
              '按范围恢复，保留账号、模型、图库和创作内容。',
              'Reset a selected scope while keeping accounts, models, libraries and creative work.',
              '範囲を選んでリセットし、アカウント・モデル・ライブラリ・創作内容を保持します。',
            ),
          ),
          onTap: busy ? null : reset,
        ),
      ],
    ),
  );
}
