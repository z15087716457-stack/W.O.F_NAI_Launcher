import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../widgets/settings_labeled_group.dart';
import '../widgets/settings_tile.dart';
import '../widgets/shortcut_settings_panel.dart';
import '../widgets/settings_ui_theme.dart';

/// 快捷键设置板块
///
/// 显示快捷键设置入口，点击后打开快捷键设置面板
class ShortcutSettingsSection extends ConsumerStatefulWidget {
  const ShortcutSettingsSection({super.key});

  @override
  ConsumerState<ShortcutSettingsSection> createState() =>
      _ShortcutSettingsSectionState();
}

class _ShortcutSettingsSectionState
    extends ConsumerState<ShortcutSettingsSection> {
  @override
  Widget build(BuildContext context) {
    return SettingsLabeledGroup(
      title: settingsText(context, '键盘操作', 'Keyboard', 'キーボード操作'),
      description: settingsText(
        context,
        '按习惯配置常用操作',
        'Customize frequently used actions',
        'よく使う操作をカスタマイズ',
      ),
      showDivider: false,
      child: SettingsTile(
        leading: const Icon(Icons.keyboard_outlined),
        title: Text(context.l10n.shortcut_settings_title),
        subtitle: Text(context.l10n.settings_shortcutsSubtitle),
        trailing: OutlinedButton.icon(
          key: const Key('settings-manage-shortcuts'),
          onPressed: () => ShortcutSettingsPanel.show(context),
          icon: const Icon(Icons.keyboard_outlined, size: 16),
          label: Text(
            settingsText(context, '管理快捷键', 'Manage shortcuts', 'ショートカット管理'),
          ),
        ),
        onTap: () => ShortcutSettingsPanel.show(context),
      ),
    );
  }
}
