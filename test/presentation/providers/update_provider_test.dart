import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/services/app_installation_service.dart';
import 'package:nai_launcher/core/services/update_check_service.dart';
import 'package:nai_launcher/core/services/update_installer_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/data/models/version/version_info.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';

void main() {
  test(
    'completed download wins a cancellation at the commit boundary',
    () async {
      const asset = ReleaseAssetInfo(
        type: ReleaseAssetType.windowsPortable,
        platform: 'windows',
        fileName: 'update.zip',
        downloadUrl: 'https://example.test/update.zip',
        sha256: 'hash',
        size: 7,
      );
      const versionInfo = VersionInfo(
        version: '2.0.0',
        currentVersion: '1.0.0',
        releaseNotes: 'test',
        primaryAsset: asset,
        assets: [asset],
        isNewer: true,
      );
      final downloaded = DownloadedUpdate(
        file: File('update.zip'),
        asset: asset,
        version: versionInfo.version,
      );
      final checkService = _MockUpdateCheckService();
      when(
        () => checkService.checkForUpdates(ignoreSkipped: false),
      ).thenAnswer((_) async => versionInfo);
      when(checkService.clearReminder).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [
          updateCheckServiceProvider.overrideWithValue(checkService),
          updateInstallerServiceProvider.overrideWithValue(
            _CommitBoundaryInstaller(downloaded),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(updateStateNotifierProvider.notifier);

      await notifier.checkForUpdates();
      await notifier.downloadUpdate();

      final state = container.read(updateStateNotifierProvider);
      expect(state.status, UpdateStatus.downloaded);
      expect(state.downloadedUpdate, same(downloaded));
      expect(state.downloadProgress, 1);
    },
  );
  for (final installed in [false, true]) {
    test(
      'restart ${installed ? 'clears completed update' : 'retains failed update'}',
      () async {
        const asset = ReleaseAssetInfo(
          type: ReleaseAssetType.windowsPortable,
          platform: 'windows',
          fileName: 'update.zip',
          downloadUrl: 'https://example.test/update.zip',
          sha256: 'abc',
        );
        const info = VersionInfo(
          version: '2.0.0',
          primaryAsset: asset,
          isNewer: true,
        );
        final check = _MockUpdateCheckService();
        when(
          () => check.currentVersion,
        ).thenReturn(installed ? '2.0.0' : '1.0.0');
        final installer = _MockInstaller();
        when(installer.consumeExecutionResult).thenAnswer(
          (_) async => UpdateExecutionResult(
            success: installed,
            version: '2.0.0',
            message: 'failed',
          ),
        );
        when(installer.restorePendingUpdate).thenAnswer(
          (_) async => RestoredDownloadedUpdate(
            update: DownloadedUpdate(
              file: File('not-read.zip'),
              asset: asset,
              version: '2.0.0',
            ),
            versionInfo: info,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            updateCheckServiceProvider.overrideWithValue(check),
            updateInstallerServiceProvider.overrideWithValue(installer),
          ],
        );
        addTearDown(container.dispose);
        await container.read(updateStateProvider.notifier).initialize();
        expect(container.read(updateStateProvider).hasNewVersion, !installed);
      },
    );
  }
  test(
    'background check failure keeps a previously discovered update',
    () async {
      final check = _MockUpdateCheckService();
      const info = VersionInfo(version: '2.0.0', isNewer: true);
      when(
        () => check.checkForUpdates(ignoreSkipped: false),
      ).thenAnswer((_) async => info);
      final container = ProviderContainer(
        overrides: [updateCheckServiceProvider.overrideWithValue(check)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(updateStateProvider.notifier);
      await notifier.checkForUpdates();
      when(
        () => check.checkForUpdates(ignoreSkipped: false),
      ).thenThrow(Exception('offline'));
      await notifier.checkForUpdates();
      expect(container.read(updateStateProvider).hasNewVersion, isTrue);
      expect(container.read(updateStateProvider).versionInfo, info);
    },
  );
}

class _MockUpdateCheckService extends Mock implements UpdateCheckService {}

class _SupportedInstallationService extends AppInstallationService {
  @override
  bool get supportsInAppInstall => true;
}

class _CommitBoundaryInstaller extends UpdateInstallerService {
  _CommitBoundaryInstaller(this.downloaded)
    : super(dio: Dio(), installationService: _SupportedInstallationService());

  final DownloadedUpdate downloaded;

  @override
  Future<DownloadedUpdate> downloadUpdate(
    VersionInfo versionInfo, {
    void Function(UpdateDownloadProgress progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    cancelToken?.cancel('completed at the cancellation boundary');
    return downloaded;
  }
}

class _MockInstaller extends Mock implements UpdateInstallerService {}
