import '../widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_version.dart';
import '../../../../core/services/update_check_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../providers/update_provider.dart';
import '../../../widgets/common/update_check_dialog.dart';
import '../widgets/settings_labeled_group.dart';
import '../widgets/settings_preferences_panel.dart';

/// 关于设置板块
///
/// 显示应用信息、版本号和开源链接。
class AboutSettingsSection extends ConsumerStatefulWidget {
  const AboutSettingsSection({super.key});

  @override
  ConsumerState<AboutSettingsSection> createState() =>
      _AboutSettingsSectionState();
}

class _AboutSettingsSectionState extends ConsumerState<AboutSettingsSection> {
  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateStateProvider);
    final updateNotifier = ref.read(updateStateProvider.notifier);
    final updateService = ref
        .watch(updateCheckServiceReadyProvider)
        .valueOrNull;
    final storage = ref.watch(localStorageServiceProvider);
    final VoidCallback? check = updateState.isChecking || updateService == null
        ? null
        : () async {
            if (updateState.hasNewVersion || updateState.hasDownloadedUpdate) {
              updateNotifier.showNotification();
            } else {
              await updateNotifier.checkForUpdates(manual: true);
            }
            if (context.mounted) await UpdateCheckDialog.show(context);
          };
    void licenses() => showLicensePage(
      context: context,
      applicationName: context.l10n.app_title,
      applicationVersion: AppVersion.versionName,
    );
    Future<void> project() async {
      final uri = Uri.parse(
        'https://github.com/z15087716457-stack/W.O.F_NAI_Launcher',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsLabeledGroup(
          key: const Key('about-version-group'),
          title: context.l10n.settings_versionUpdates,
          description: context.l10n.settings_currentVersionUpdateOptions,
          child: Column(
            children: [
              SettingsTile(
                hoverFeedback: false,
                title: Text(context.l10n.app_title),
                subtitle: Text(
                  context.l10n.settings_version(AppVersion.versionName),
                ),
              ),
              FutureBuilder<DateTime?>(
                future: updateService?.getLastCheckTime() ?? Future.value(null),
                builder: (context, snapshot) => SettingsTile(
                  hoverFeedback: check != null,
                  title: Text(context.l10n.checkForUpdate),
                  subtitle: Text(
                    updateState.hasDownloadedUpdate
                        ? context.l10n.updateSettingsReady(
                            updateState.versionInfo?.version ?? '',
                          )
                        : updateState.hasNewVersion
                        ? context.l10n.updateSettingsAvailable(
                            updateState.versionInfo?.version ?? '',
                          )
                        : _formatLastCheckTime(context, snapshot.data),
                  ),
                  trailing: OutlinedButton(
                    key: const Key('about-check-update'),
                    onPressed: check,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (updateState.isChecking) ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                        ] else if (updateState.hasNewVersion) ...[
                          const Badge(
                            smallSize: 6,
                            child: SizedBox(width: 4, height: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(context.l10n.checkForUpdate),
                      ],
                    ),
                  ),
                  onTap: check,
                ),
              ),
              FutureBuilder<bool>(
                future: Future.value(
                  updateService?.shouldIncludePrerelease() ??
                      storage.getIncludePrereleaseUpdates(),
                ),
                builder: (context, snapshot) => SettingsSwitchTile(
                  key: const Key('about-prerelease-setting'),
                  title: Text(context.l10n.includePrereleaseUpdates),
                  subtitle: Text(
                    context.l10n.includePrereleaseUpdatesDescription,
                  ),
                  value: snapshot.data ?? false,
                  onChanged: updateService == null
                      ? null
                      : (value) async {
                          await updateNotifier.setIncludePrerelease(value);
                          if (mounted) setState(() {});
                        },
                ),
              ),
            ],
          ),
        ),
        const SettingsPreferencesPanel(labeled: true),
        SettingsLabeledGroup(
          key: const Key('about-diagnostics-group'),
          title: context.l10n.settings_diagnosticsResources,
          description: context.l10n.settings_logsFontsOpenSourceProject,
          showDivider: false,
          child: Column(
            children: [
              SettingsSwitchTile(
                key: const Key('about-logging-setting'),
                title: Text(context.l10n.settings_fileLogging),
                subtitle: Text(context.l10n.settings_fileLoggingSubtitle),
                value: storage.getFileLoggingEnabled(),
                onChanged: (value) async {
                  await AppLogger.setFileLoggingEnabled(value);
                  await storage.setFileLoggingEnabled(
                    AppLogger.fileLoggingEnabled,
                  );
                  if (mounted) setState(() {});
                },
              ),
              SettingsTile(
                title: Text(context.l10n.settings_visualAssets),
                subtitle: const Text(
                  'Geist Sans / Mono / Pixel Line · HarmonyOS Sans SC',
                ),
                trailing: OutlinedButton(
                  key: const Key('about-view-licenses'),
                  onPressed: licenses,
                  child: Text(context.l10n.settings_viewLicenses),
                ),
                onTap: licenses,
              ),
              SettingsTile(
                title: Text(context.l10n.settings_openSource),
                subtitle: Text(context.l10n.settings_openSourceSubtitle),
                trailing: OutlinedButton.icon(
                  key: const Key('about-open-project'),
                  onPressed: project,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(context.l10n.settings_openProject),
                ),
                onTap: project,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 格式化上次检查时间
  String _formatLastCheckTime(BuildContext context, DateTime? lastCheckTime) {
    if (lastCheckTime == null) {
      return context.l10n.neverChecked;
    }

    final now = DateTime.now();
    final difference = now.difference(lastCheckTime);

    if (difference.inMinutes < 1) {
      return context.l10n.lastCheckedAt(context.l10n.common_justNow);
    } else if (difference.inHours < 1) {
      return context.l10n.lastCheckedAt(
        context.l10n.common_minutesAgo(difference.inMinutes),
      );
    } else if (difference.inDays < 1) {
      return context.l10n.lastCheckedAt(
        context.l10n.common_hoursAgo(difference.inHours),
      );
    } else {
      return context.l10n.lastCheckedAt(
        context.l10n.common_daysAgo(difference.inDays),
      );
    }
  }
}
