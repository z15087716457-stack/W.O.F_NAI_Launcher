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
import '../../../widgets/common/github_icon.dart';
import '../../../widgets/common/update_check_dialog.dart';
import '../widgets/settings_card.dart';

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
    final updateServiceState = ref.watch(updateCheckServiceReadyProvider);
    final updateService = updateServiceState.valueOrNull;
    final localStorageService = ref.watch(localStorageServiceProvider);
    final fileLoggingEnabled = localStorageService.getFileLoggingEnabled();

    return SettingsCard(
      child: Column(
        children: [
          SettingsTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.app_title),
            subtitle: Text(
              context.l10n.settings_version(AppVersion.versionName),
            ),
          ),
          SettingsTile(
            leading: const Icon(Icons.text_fields),
            title: Text(context.l10n.settings_visualAssets),
            subtitle: const Text(
              'Geist Sans / Mono / Pixel Line · HarmonyOS Sans SC',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: context.l10n.app_title,
              applicationVersion: AppVersion.versionName,
            ),
          ),
          SettingsSwitchTile(
            secondary: const Icon(Icons.article_outlined),
            title: Text(context.l10n.settings_fileLogging),
            subtitle: Text(context.l10n.settings_fileLoggingSubtitle),
            value: fileLoggingEnabled,
            onChanged: (value) async {
              await AppLogger.setFileLoggingEnabled(value);
              await localStorageService.setFileLoggingEnabled(
                AppLogger.fileLoggingEnabled,
              );
              if (mounted) {
                setState(() {});
              }
            },
          ),
          // 检查更新按钮
          FutureBuilder<DateTime?>(
            future: updateService?.getLastCheckTime() ?? Future.value(null),
            builder: (context, snapshot) {
              final lastCheckTime = snapshot.data;
              return SettingsTile(
                hoverFeedback: !updateState.isChecking && updateService != null,
                leading: Badge(
                  isLabelVisible: updateState.hasNewVersion,
                  smallSize: 7,
                  child: const Icon(Icons.system_update),
                ),
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
                      : _formatLastCheckTime(context, lastCheckTime),
                ),
                trailing: updateState.isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: updateState.isChecking || updateService == null
                    ? null
                    : () async {
                        if (updateState.hasNewVersion ||
                            updateState.hasDownloadedUpdate) {
                          updateNotifier.showNotification();
                        } else {
                          await updateNotifier.checkForUpdates(manual: true);
                        }
                        if (context.mounted) {
                          await UpdateCheckDialog.show(context);
                        }
                      },
              );
            },
          ),
          // 包含预发布版本开关
          FutureBuilder<bool>(
            future: Future.value(
              updateService?.shouldIncludePrerelease() ??
                  localStorageService.getIncludePrereleaseUpdates(),
            ),
            builder: (context, snapshot) {
              final includePrerelease = snapshot.data ?? false;
              return SettingsSwitchTile(
                secondary: const Icon(Icons.new_releases_outlined),
                title: Text(context.l10n.includePrereleaseUpdates),
                subtitle: Text(
                  context.l10n.includePrereleaseUpdatesDescription,
                ),
                value: includePrerelease,
                onChanged: updateService == null
                    ? null
                    : (value) async {
                        await updateNotifier.setIncludePrerelease(value);
                        if (mounted) {
                          setState(
                            () {},
                          ); // Force widget rebuild to refresh value
                        }
                      },
              );
            },
          ),
          SettingsTile(
            leading: const GitHubIcon(),
            title: Text(context.l10n.settings_openSource),
            subtitle: Text(context.l10n.settings_openSourceSubtitle),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final uri = Uri.parse(
                'https://github.com/z15087716457-stack/W.O.F_NAI_Launcher',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
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
