import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../providers/canvas_settings_provider.dart';
import '../../../providers/font_provider.dart';
import '../../../providers/settings_font_scale_provider.dart';
import '../../../providers/history_click_behavior_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/simple_output_viewer_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/settings/studio_theme_picker.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/settings_font_dialog.dart';
import '../widgets/settings_ui_theme.dart';
import '../../../widgets/common/app_toast.dart';
import 'generation_settings_section.dart';

/// 外观设置板块
///
/// 包含主题选择、字体选择、语言选择三个设置项。
class AppearanceSettingsSection extends ConsumerStatefulWidget {
  const AppearanceSettingsSection({super.key, this.controlsOnly = false});
  final bool controlsOnly;

  @override
  ConsumerState<AppearanceSettingsSection> createState() =>
      _AppearanceSettingsSectionState();
}

class _AppearanceSettingsSectionState
    extends ConsumerState<AppearanceSettingsSection> {
  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeNotifierProvider);
    final currentFont = ref.watch(fontNotifierProvider);
    final currentLocale = ref.watch(localeNotifierProvider);
    final fontScale = ref.watch(settingsFontScaleProvider);
    final historyClickBehavior = ref.watch(
      historyClickBehaviorNotifierProvider,
    );
    final simpleOutputViewer = ref.watch(simpleOutputViewerNotifierProvider);

    Widget valueControl(String value) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
    return SettingsCard(
      child: Column(
        children: [
          if (!widget.controlsOnly) ...[
            // 主题选择
            SettingsTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(context.l10n.settings_style),
              trailing: valueControl(
                currentTheme == Brightness.dark
                    ? context.l10n.settings_geistDark
                    : context.l10n.settings_geistLight,
              ),
              onTap: () => _showThemeDialog(context),
            ),

            // 字体选择
            SettingsTile(
              leading: const Icon(Icons.text_fields),
              title: Text(context.l10n.settings_font),
              trailing: valueControl(currentFont.displayName),
              onTap: () => _showFontDialog(context, currentFont),
            ),

            // 字体大小选择
            SettingsTile(
              leading: const Icon(Icons.format_size),
              title: Text(context.l10n.settings_fontScale),
              subtitle: Text(
                settingsText(
                  context,
                  '仅调整设置页面与设置弹窗的字号',
                  'Adjust settings pages and dialogs only',
                  '設定画面と設定ダイアログの文字サイズ',
                ),
              ),
              trailing: valueControl('${(fontScale * 100).round()}%'),
              onTap: () => _showFontScaleDialog(context, fontScale),
            ),

            // 语言选择
            SettingsTile(
              leading: const Icon(Icons.language),
              title: Text(context.l10n.settings_language),
              trailing: valueControl(
                _languageLabel(context, currentLocale.languageCode),
              ),
              onTap: () => _showLanguageDialog(context, currentLocale),
            ),
          ],
          if (widget.controlsOnly) ...[
            SettingsTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.settings_historyClickBehavior),
              subtitle: Text(
                historyClickBehavior == HistoryClickBehavior.selectPreview
                    ? context.l10n.settings_historyClickBehavior_linked
                    : context.l10n.settings_historyClickBehavior_classic,
              ),
              onTap: () => _showHistoryClickBehaviorDialog(
                context,
                historyClickBehavior,
              ),
            ),

            // 输出查看器模式（G11 自由画布 / 简单视图）
            SettingsTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(context.l10n.settings_outputViewer),
              subtitle: Text(
                simpleOutputViewer
                    ? context.l10n.settings_outputViewer_simple
                    : context.l10n.settings_outputViewer_canvas,
              ),
              onTap: () => _showOutputViewerDialog(context, simpleOutputViewer),
            ),

            // 画布门控（官网 canvasLockCamera / canvasReducedMotion）
            SettingsSwitchTile(
              secondary: const Icon(Icons.lock_outline),
              title: Text(context.l10n.settings_canvasLockCamera),
              subtitle: Text(context.l10n.settings_canvasLockCameraDescription),
              value: ref.watch(canvasLockCameraNotifierProvider),
              onChanged: (v) => unawaited(
                ref
                    .read(canvasLockCameraNotifierProvider.notifier)
                    .setLocked(v),
              ),
            ),
          ],
          if (!widget.controlsOnly) ...[
            SettingsSwitchTile(
              secondary: const Icon(Icons.motion_photos_off_outlined),
              title: Text(context.l10n.settings_canvasReducedMotion),
              subtitle: Text(
                context.l10n.settings_canvasReducedMotionDescription,
              ),
              value: ref.watch(canvasReducedMotionNotifierProvider),
              onChanged: (v) => unawaited(
                ref
                    .read(canvasReducedMotionNotifierProvider.notifier)
                    .setReduced(v),
              ),
            ),
            const GenerationSettingsSection(feedbackOnly: true),
            SettingsTile(
              title: Text(
                Localizations.localeOf(context).languageCode == 'zh'
                    ? '通知样式'
                    : 'Notification style',
              ),
              trailing: OutlinedButton.icon(
                onPressed: () => AppToast.info(
                  context,
                  Localizations.localeOf(context).languageCode == 'zh'
                      ? '通知会显示在右上角，长文本自动换行，进度任务完成后自动收起。'
                      : 'Notifications appear at the upper right, wrap long messages, and close when progress tasks finish.',
                ),
                icon: const Icon(Icons.info_outline, size: 16),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'zh'
                      ? '预览'
                      : 'Preview',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showOutputViewerDialog(
    BuildContext context,
    bool simpleCurrent,
  ) async {
    final value = await showSettingsChoice<bool>(
      context: context,
      title: context.l10n.settings_outputViewer,
      value: simpleCurrent,
      choices: [
        SettingsChoice(
          false,
          context.l10n.settings_outputViewer_canvas,
          description: context.l10n.settings_outputViewer_canvasDescription,
          icon: Icons.dashboard_outlined,
        ),
        SettingsChoice(
          true,
          context.l10n.settings_outputViewer_simple,
          description: context.l10n.settings_outputViewer_simpleDescription,
          icon: Icons.image_outlined,
        ),
      ],
    );
    if (value != null && mounted) {
      await ref
          .read(simpleOutputViewerNotifierProvider.notifier)
          .setSimple(value);
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.settings_selectStyle),
        content: const SizedBox(width: 420, child: StudioThemePicker()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _showFontDialog(
    BuildContext context,
    FontConfig currentFont,
  ) async {
    final font = await showDialog<FontConfig>(
      context: context,
      builder: (_) => SettingsFontDialog(current: currentFont),
    );
    if (font != null && mounted) {
      ref.read(fontNotifierProvider.notifier).setFont(font);
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    Locale currentLocale,
  ) async {
    final language = await showSettingsChoice<String>(
      context: context,
      title: context.l10n.settings_selectLanguage,
      value: currentLocale.languageCode,
      choices: const [
        SettingsChoice('zh', '中文', description: '简体中文'),
        SettingsChoice('en', 'English', description: 'English'),
        SettingsChoice('ja', '日本語', description: '日本語'),
      ],
    );
    if (language != null && mounted) {
      ref.read(localeNotifierProvider.notifier).setLocale(language);
    }
  }

  Future<void> _showHistoryClickBehaviorDialog(
    BuildContext context,
    HistoryClickBehavior currentBehavior,
  ) async {
    final value = await showSettingsChoice<HistoryClickBehavior>(
      context: context,
      title: context.l10n.settings_historyClickBehavior,
      value: currentBehavior,
      choices: [
        SettingsChoice(
          HistoryClickBehavior.openDetail,
          context.l10n.settings_historyClickBehavior_classic,
          description:
              context.l10n.settings_historyClickBehavior_classicDescription,
        ),
        SettingsChoice(
          HistoryClickBehavior.selectPreview,
          context.l10n.settings_historyClickBehavior_linked,
          description:
              context.l10n.settings_historyClickBehavior_linkedDescription,
        ),
      ],
    );
    if (value != null && mounted) {
      await ref
          .read(historyClickBehaviorNotifierProvider.notifier)
          .setBehavior(value);
    }
  }

  String _languageLabel(BuildContext context, String languageCode) {
    switch (languageCode) {
      case 'zh':
        return context.l10n.settings_languageChinese;
      case 'ja':
        return context.l10n.settings_languageJapanese;
      default:
        return context.l10n.settings_languageEnglish;
    }
  }

  Future<void> _showFontScaleDialog(
    BuildContext context,
    double currentScale,
  ) async {
    var draft = currentScale;
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => SettingsDialogFrame(
          title: context.l10n.settings_fontScale,
          actions: [
            TextButton(
              onPressed: () => update(() => draft = 1),
              child: Text(context.l10n.common_reset),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, draft),
              child: Text(context.l10n.settings_fontScale_done),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .035),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      SettingsFontScaleNotifier.effectiveScale(draft),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.settings_fontScale_previewLarge,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.settings_fontScale_previewMedium,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.settings_fontScale_previewSmall,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('80%'),
                  Expanded(
                    child: Slider(
                      value: draft,
                      min: .8,
                      max: 1.5,
                      divisions: 7,
                      label: '${(draft * 100).round()}%',
                      onChanged: (value) => update(() => draft = value),
                    ),
                  ),
                  const Text('150%'),
                ],
              ),
              Center(
                child: Text(
                  '${(draft * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      await ref.read(settingsFontScaleProvider.notifier).setFontScale(result);
    }
  }
}
