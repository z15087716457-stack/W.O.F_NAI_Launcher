import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../providers/generation/generation_settings_notifiers.dart';
import '../../../providers/notification_settings_provider.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_section_label.dart';

/// 生成设置板块
///
/// 按生成任务流组织：输入行为 → 完成提醒。
class GenerationSettingsSection extends ConsumerStatefulWidget {
  const GenerationSettingsSection({super.key});

  @override
  ConsumerState<GenerationSettingsSection> createState() =>
      _GenerationSettingsSectionState();
}

class _GenerationSettingsSectionState
    extends ConsumerState<GenerationSettingsSection> {
  Future<void> _selectCustomSound(NotificationSettingsNotifier notifier) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
    );
    if (result != null && result.files.single.path != null) {
      await notifier.setCustomSoundPath(result.files.single.path);
    }
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
      title: l10n.settings_generation,
      icon: Icons.tune_outlined,
      child: Column(
        children: [
          SettingsSectionLabel(l10n.settings_generationInputSection),
          SwitchListTile(
            secondary: const Icon(Icons.mouse_outlined),
            title: Text(l10n.settings_enablePromptWeightScroll),
            subtitle: Text(l10n.settings_enablePromptWeightScrollSubtitle),
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
                    content: Text(l10n.globalSettings_saveFailed('$error')),
                  ),
                );
              }
            },
          ),
          SettingsSectionLabel(l10n.settings_generationFeedbackSection),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(l10n.settings_notificationSound),
            subtitle: Text(l10n.settings_notificationSoundSubtitle),
            value: notificationSettings.soundEnabled,
            onChanged: (value) => notificationNotifier.setSoundEnabled(value),
          ),
          if (notificationSettings.soundEnabled)
            ListTile(
              leading: const Icon(Icons.audiotrack_outlined),
              title: Text(l10n.settings_notificationCustomSound),
              subtitle: Text(
                notificationSettings.customSoundPath != null
                    ? Uri.file(
                        notificationSettings.customSoundPath!,
                      ).pathSegments.last
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
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _selectCustomSound(notificationNotifier),
            ),
        ],
      ),
    );
  }
}
