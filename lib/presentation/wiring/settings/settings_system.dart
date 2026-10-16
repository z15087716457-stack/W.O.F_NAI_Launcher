import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_version.dart';
import '../../../core/services/desktop_app_shutdown_service.dart';
import '../../../core/services/update_check_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/rag_provider.dart';
import '../../providers/update_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../widgets/common/update_check_dialog.dart';
import 'settings_edits.dart';

final settingsUpdateCheckedAtProvider = FutureProvider<DateTime?>((ref) async {
  ref.watch(updateStateProvider);
  return (await ref.watch(
    updateCheckServiceReadyProvider.future,
  )).getLastCheckTime();
});

SettingsAboutData settingsAboutData(UpdateState state, DateTime? checkedAt) =>
    SettingsAboutData(
      build: AppVersion.buildNumber,
      platform: Platform.operatingSystem,
      update: switch (state.status) {
        UpdateStatus.checking => SettingsUpdateState.checking,
        UpdateStatus.available ||
        UpdateStatus.downloaded ||
        UpdateStatus.installing => SettingsUpdateState.available,
        UpdateStatus.downloading => SettingsUpdateState.downloading,
        UpdateStatus.error => SettingsUpdateState.failed,
        _ => SettingsUpdateState.upToDate,
      },
      latest: state.versionInfo?.version ?? '',
      releasedAt: DateTime.tryParse(state.versionInfo?.publishedAt ?? ''),
      updateBytes: state.versionInfo?.primaryAsset?.size ?? 0,
      notes: (state.versionInfo?.releaseNotes ?? '')
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(30)
          .toList(),
      progress: state.downloadProgress,
      checkedAt: checkedAt,
      system: [
        ('OS', Platform.operatingSystemVersion),
        ('Dart', Platform.version.split(' ').first),
      ],
    );

/// A positive allowlist: no settings maps, paths, account objects, bridge
/// discovery/secret, provider URLs/headers, prompt text or request logs enter it.
String settingsDiagnostics({
  required String version,
  required String os,
  required String runtime,
  required bool ragEnabled,
  required int indexed,
  required bool runtimeReady,
  required int providers,
}) => const JsonEncoder.withIndent('  ').convert({
  'version': version,
  'os': os,
  'runtime': runtime,
  'rag': {
    'enabled': ragEnabled,
    'indexed': indexed,
    'runtimeReady': runtimeReady,
  },
  'providers': providers,
});

typedef SettingsRestart = Future<void> Function();
final settingsRestartProvider = Provider<SettingsRestart>(
  (ref) => () async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Desktop restart requires Windows');
    }
    // Launch the current registered executable after a clean shutdown. The
    // detached helper has no visible window and never selects another install.
    final executable = Platform.resolvedExecutable.replaceAll("'", "''");
    final script =
        "Wait-Process -Id $pid -ErrorAction SilentlyContinue; Start-Process -FilePath '$executable' -WorkingDirectory (Split-Path -LiteralPath '$executable')";
    final encoded = base64Encode(
      script.codeUnits.expand((unit) => [unit & 255, unit >> 8]).toList(),
    );
    await Process.start('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-WindowStyle',
      'Hidden',
      '-EncodedCommand',
      encoded,
    ], mode: ProcessStartMode.detached);
    await DesktopAppShutdownService.shutdownAndExit(0);
  },
);

class SettingsSystemActions {
  SettingsSystemActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;
  Future<void> checkUpdate() async {
    await ref.read(updateCheckServiceReadyProvider.future);
    final state = ref.read(updateStateProvider);
    if (!state.hasNewVersion && !state.hasDownloadedUpdate) {
      await ref
          .read(updateStateProvider.notifier)
          .checkForUpdates(manual: true);
    }
    if (context.mounted) await UpdateCheckDialog.show(context);
  }

  Future<void> installUpdate() async {
    // Reuse the established download, integrity, task-idle and restart UI.
    if (context.mounted) await UpdateCheckDialog.show(context);
  }

  Future<void> openUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw StateError('Unable to open link');
    }
  }

  Future<void> changelog() => openUrl(
    ref.read(updateStateProvider).versionInfo?.htmlUrl ??
        'https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases',
  );
  Future<void> restart() async {
    if (ref.read(imageGenerationNotifierProvider).isGenerating ||
        ref.read(updateTaskBusyProvider) ||
        ref.read(ragControllerProvider).anyBusy) {
      throw StateError('A task is running');
    }
    await ref.read(settingsEditsProvider.notifier).settled;
    await ref.read(settingsRestartProvider)();
  }

  void licenses() => showLicensePage(
    context: context,
    applicationName: context.l10n.app_title,
    applicationVersion: AppVersion.versionName,
  );
}
