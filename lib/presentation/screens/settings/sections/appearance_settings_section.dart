import 'dart:async';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_language.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/canvas_settings_provider.dart';
import '../../../providers/font_provider.dart';
import '../../../providers/settings_font_scale_provider.dart';
import '../../../providers/history_click_behavior_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/simple_output_viewer_provider.dart';
import '../../../widgets/settings/studio_theme_picker.dart';
import '../widgets/settings_labeled_group.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/settings_font_dialog.dart';
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
  Widget _valueControl(String value, VoidCallback onPressed) => SizedBox(
    width: 200 * MediaQuery.textScalerOf(context).scale(1),
    child: OutlinedButton(
      onPressed: onPressed,
      child: Row(
        children: [
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wrapWidth = 500 * MediaQuery.textScalerOf(context).scale(1);
    if (widget.controlsOnly) {
      final behavior = ref.watch(historyClickBehaviorNotifierProvider);
      final simple = ref.watch(simpleOutputViewerNotifierProvider);
      return Column(
        children: [
          SettingsLabeledGroup(
            title: context.l10n.settings_browsing,
            description: context.l10n.settings_chooseHowViewImages,
            child: Column(
              children: [
                SettingsTile(
                  controlWrapWidth: wrapWidth,
                  title: Text(l10n.settings_historyClickBehavior),
                  subtitle: Text(
                    behavior == HistoryClickBehavior.selectPreview
                        ? l10n.settings_historyClickBehavior_linkedDescription
                        : l10n.settings_historyClickBehavior_classicDescription,
                  ),
                  trailing: _valueControl(
                    behavior == HistoryClickBehavior.selectPreview
                        ? l10n.settings_historyClickBehavior_linked
                        : l10n.settings_historyClickBehavior_classic,
                    () => _showHistoryClickBehaviorDialog(context, behavior),
                  ),
                  onTap: () =>
                      _showHistoryClickBehaviorDialog(context, behavior),
                ),
                SettingsTile(
                  controlWrapWidth: wrapWidth,
                  title: Text(l10n.settings_outputViewer),
                  subtitle: Text(
                    simple
                        ? l10n.settings_outputViewer_simpleDescription
                        : l10n.settings_outputViewer_canvasDescription,
                  ),
                  trailing: _valueControl(
                    simple
                        ? l10n.settings_outputViewer_simple
                        : l10n.settings_outputViewer_canvas,
                    () => _showOutputViewerDialog(context, simple),
                  ),
                  onTap: () => _showOutputViewerDialog(context, simple),
                ),
              ],
            ),
          ),
          SettingsLabeledGroup(
            title: context.l10n.settings_canvasControls,
            description: context.l10n.settings_keepViewSteady,
            child: SettingsSwitchTile(
              title: Text(l10n.settings_canvasLockCamera),
              subtitle: Text(l10n.settings_canvasLockCameraDescription),
              value: ref.watch(canvasLockCameraNotifierProvider),
              onChanged: (value) => unawaited(
                ref
                    .read(canvasLockCameraNotifierProvider.notifier)
                    .setLocked(value),
              ),
            ),
          ),
        ],
      );
    }

    final font = ref.watch(fontNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final fontScale = ref.watch(settingsFontScaleProvider);
    return Column(
      children: [
        SettingsLabeledGroup(
          title: context.l10n.settings_appearance2,
          description: context.l10n.settings_chooseLightDarkWorkspace,
          child: const StudioThemePicker(compact: true),
        ),
        SettingsLabeledGroup(
          title: context.l10n.settings_textLanguage,
          description: context.l10n.settings_makeReadingComfortable,
          child: Column(
            children: [
              SettingsTile(
                controlWrapWidth: wrapWidth,
                title: Text(l10n.settings_font),
                trailing: _valueControl(
                  font.displayName,
                  () => _showFontDialog(context, font),
                ),
                onTap: () => _showFontDialog(context, font),
              ),
              SettingsTile(
                controlWrapWidth: wrapWidth,
                title: Text(l10n.settings_fontScale),
                subtitle: Text(
                  context.l10n.settings_adjustSettingsPagesDialogsOnly,
                ),
                trailing: _valueControl(
                  '${(fontScale * 100).round()}%',
                  () => _showFontScaleDialog(context, fontScale),
                ),
                onTap: () => _showFontScaleDialog(context, fontScale),
              ),
              SettingsTile(
                controlWrapWidth: wrapWidth,
                title: Text(l10n.settings_language),
                trailing: _valueControl(
                  AppLanguage.fromLocale(locale).nativeName,
                  () => _showLanguageDialog(context, locale),
                ),
                onTap: () => _showLanguageDialog(context, locale),
              ),
            ],
          ),
        ),
        SettingsLabeledGroup(
          title: context.l10n.settings_motionNotifications,
          description: context.l10n.settings_reduceDistractionsKnowWorkFinishes,
          showDivider: false,
          child: Column(
            children: [
              SettingsSwitchTile(
                title: Text(l10n.settings_canvasReducedMotion),
                subtitle: Text(l10n.settings_canvasReducedMotionDescription),
                value: ref.watch(canvasReducedMotionNotifierProvider),
                onChanged: (value) => unawaited(
                  ref
                      .read(canvasReducedMotionNotifierProvider.notifier)
                      .setReduced(value),
                ),
              ),
              const GenerationSettingsSection(
                feedbackOnly: true,
                showHeading: false,
                explicitSoundPicker: true,
              ),
              SettingsTile(
                title: Text(context.l10n.settings_notificationStyle),
                trailing: OutlinedButton.icon(
                  key: const Key('settings-preview-notification'),
                  onPressed: () => AppToast.info(
                    context,
                    context.l10n.settings_notificationsAppearUpperRightWrap,
                  ),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(context.l10n.settings_preview),
                ),
              ),
            ],
          ),
        ),
      ],
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
    final language = await showSettingsChoice<AppLanguage>(
      context: context,
      title: context.l10n.settings_selectLanguage,
      value: AppLanguage.fromLocale(currentLocale),
      choices: [
        for (final language in AppLanguage.values)
          SettingsChoice(language, language.nativeName),
      ],
    );
    if (language != null && mounted) {
      await ref
          .read(localeNotifierProvider.notifier)
          .setLocale(language.storageCode);
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
