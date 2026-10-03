import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/generation/generation_settings_notifiers.dart';
import '../../../providers/notification_settings_provider.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_section_label.dart';
import '../widgets/settings_ui_theme.dart';
import '../../../widgets/common/app_toast.dart';

/// 生成设置板块
///
/// 按生成任务流组织：输入行为 → 完成提醒。
class GenerationSettingsSection extends ConsumerStatefulWidget {
  const GenerationSettingsSection({
    super.key,
    this.feedbackOnly = false,
    this.showHeading = true,
    this.explicitSoundPicker = false,
  });
  final bool feedbackOnly, showHeading, explicitSoundPicker;

  @override
  ConsumerState<GenerationSettingsSection> createState() =>
      _GenerationSettingsSectionState();
}

class _GenerationSettingsSectionState
    extends ConsumerState<GenerationSettingsSection> {
  bool _previewing = false;
  Future<void> _previewSound() async {
    if (_previewing) return;
    setState(() => _previewing = true);
    try {
      final settings = ref.read(notificationSettingsNotifierProvider);
      final ok = await ref.read(notificationSoundPreviewProvider)(
        settings.customSoundPath,
      );
      if (!ok && mounted) {
        AppToast.error(
          context,
          settingsText(
            context,
            '无法播放音效，请检查音频文件。',
            'Could not play the sound. Check the audio file.',
            '音声ファイルを確認してください。',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _selectCustomSound(NotificationSettingsNotifier notifier) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
    );
    if (result != null && result.files.single.path != null) {
      await notifier.setCustomSoundPath(result.files.single.path);
    }
  }

  /// 修饰键选择菜单
  ///
  /// 用 PopupMenuButton 而非 DropdownButton：后者按最宽项撑开且没法随
  /// 选中项变窄，这里需要宽度跟随当前值。
  Widget _buildModifierMenu(
    BuildContext context,
    AppLocalizations l10n,
    bool enabled,
  ) {
    final theme = Theme.of(context);
    final current = ref.watch(promptWeightScrollModifierSettingsProvider);
    final entries = <(String, String)>[
      ('alt', l10n.settings_weightScrollModifierAlt),
      ('ctrl', l10n.settings_weightScrollModifierCtrl),
      ('shift', l10n.settings_weightScrollModifierShift),
      ('none', l10n.settings_weightScrollModifierNone),
    ];
    final currentLabel = entries
        .firstWhere((e) => e.$1 == current, orElse: () => entries.first)
        .$2;
    final color = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return PopupMenuButton<String>(
      enabled: enabled,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 2),
      padding: EdgeInsets.zero,
      initialValue: current,
      onSelected: (value) => ref
          .read(promptWeightScrollModifierSettingsProvider.notifier)
          .set(value),
      itemBuilder: (context) => [
        for (final (value, label) in entries)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (value == current)
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLabel,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
            Icon(Icons.keyboard_arrow_down, size: 15, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final promptWeightScrollEnabled = ref.watch(
      promptWeightScrollSettingsProvider,
    );
    final notificationSettings = ref.watch(
      notificationSettingsNotifierProvider,
    );
    final notificationNotifier = ref.read(
      notificationSettingsNotifierProvider.notifier,
    );

    return SettingsCard(
      bottomSpacing: widget.feedbackOnly || !widget.showHeading ? 0 : 26,
      child: Column(
        children: [
          if (!widget.feedbackOnly) ...[
            if (widget.showHeading)
              SettingsSectionLabel(l10n.settings_generationInputSection),
            SettingsTile(
              controlWrapWidth: 300 * MediaQuery.textScalerOf(context).scale(1),
              leading: const Icon(Icons.mouse_outlined),
              title: Text(l10n.settings_enablePromptWeightScroll),
              subtitle: Text(l10n.settings_enablePromptWeightScrollSubtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModifierMenu(context, l10n, promptWeightScrollEnabled),
                  SettingsToggle(
                    value: promptWeightScrollEnabled,
                    onChanged: (value) async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      try {
                        await ref
                            .read(promptWeightScrollSettingsProvider.notifier)
                            .set(value);
                      } catch (error) {
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.globalSettings_saveFailed('$error'),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          if (widget.feedbackOnly) ...[
            if (widget.showHeading)
              SettingsSectionLabel(l10n.settings_generationFeedbackSection),
            SettingsSwitchTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: Text(l10n.settings_notificationSound),
              subtitle: Text(l10n.settings_notificationSoundSubtitle),
              value: notificationSettings.soundEnabled,
              onChanged: (value) => notificationNotifier.setSoundEnabled(value),
            ),
            SettingsTile(
              leading: const Icon(Icons.audiotrack_outlined),
              title: Text(l10n.settings_notificationCustomSound),
              subtitle: Text(
                notificationSettings.customSoundPath != null
                    ? Uri.file(
                        notificationSettings.customSoundPath!,
                      ).pathSegments.last
                    : widget.explicitSoundPicker
                    ? settingsText(
                        context,
                        '使用默认完成音效',
                        'Use the default completion sound',
                        '既定の完了音を使用',
                      )
                    : l10n.settings_notificationSelectSound,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (notificationSettings.customSoundPath != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: l10n.settings_notificationResetSound,
                      onPressed: () =>
                          notificationNotifier.setCustomSoundPath(null),
                    ),
                  if (widget.explicitSoundPicker)
                    OutlinedButton.icon(
                      key: const Key('settings-select-sound'),
                      onPressed: () => _selectCustomSound(notificationNotifier),
                      icon: const Icon(Icons.folder_open_outlined, size: 16),
                      label: Text(l10n.settings_notificationSelectSound),
                    )
                  else
                    const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _selectCustomSound(notificationNotifier),
            ),
            SettingsTile(
              hoverFeedback: !_previewing,
              title: Text(
                settingsText(context, '音效预览', 'Sound preview', '音声プレビュー'),
              ),
              subtitle: Text(
                settingsText(
                  context,
                  '试听当前完成音效',
                  'Listen to the current completion sound',
                  '現在の完了音を試聴',
                ),
              ),
              trailing: OutlinedButton.icon(
                key: const Key('settings-preview-sound'),
                onPressed: _previewing ? null : _previewSound,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(settingsText(context, '试听音效', 'Play sound', '試聴')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
