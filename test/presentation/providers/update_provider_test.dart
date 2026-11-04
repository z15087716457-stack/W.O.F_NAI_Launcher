import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nai_launcher/core/services/app_installation_service.dart';
import 'package:nai_launcher/core/services/update_check_service.dart';
import 'package:nai_launcher/core/services/update_installer_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/data/models/version/version_info.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';

void main() {
  test(
    'startup keeps the ready service across a disk wait with no settings listener',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'test',
        packageName: 'test',
        version: '2.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ready = await container.read(
        updateCheckServiceReadyProvider.future,
      );
      await container.pump();
      expect(container.read(updateCheckServiceProvider), same(ready));
    },
  );

  test(
    'a failed pending metadata read can be retried in this session',
    () async {
      final backend = _MockInstaller();
      var reads = 0;
      when(backend.consumeExecutionResult).thenAnswer((_) async {
        if (++reads == 1) throw const FileSystemException('temporarily busy');
        return null;
      });
      when(backend.restorePendingUpdate).thenAnswer((_) async => null);
      final container = ProviderContainer(
        overrides: [
          updateInstallerServiceProvider.overrideWithValue(backend),
          updateCheckServiceProvider.overrideWithValue(
            _MockUpdateCheckService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(updateStateProvider.notifier);
      await expectLater(
        notifier.initialize(),
        throwsA(isA<FileSystemException>()),
      );
      await Future.wait([notifier.initialize(), notifier.initialize()]);
      expect(reads, 2);
      verify(backend.restorePendingUpdate).called(1);
    },
  );

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
  group('finishing a downloaded update', () {
    const macAsset = ReleaseAssetInfo(
      type: ReleaseAssetType.macosPortable,
      platform: 'macos',
      fileName: 'WOF_NAI_Studio_macOS_2.1.0_Portable.zip',
      downloadUrl: 'https://example.test/macos.zip',
      sha256: 'hash',
      size: 7,
    );
    const windowsAsset = ReleaseAssetInfo(
      type: ReleaseAssetType.windowsPortable,
      platform: 'windows',
      fileName: 'WOF_NAI_Studio_Windows_2.1.0_Portable.zip',
      downloadUrl: 'https://example.test/windows.zip',
      sha256: 'hash',
      size: 7,
    );

    Future<(ProviderContainer, _RecordingInstaller)> downloaded(
      ReleaseAssetInfo asset,
    ) async {
      final info = VersionInfo(
        version: '2.1.0',
        currentVersion: '2.0.0',
        primaryAsset: asset,
        assets: [asset],
        isNewer: true,
      );
      final check = _MockUpdateCheckService();
      when(
        () => check.checkForUpdates(ignoreSkipped: false),
      ).thenAnswer((_) async => info);
      when(check.clearReminder).thenAnswer((_) async {});
      final installer = _RecordingInstaller(
        DownloadedUpdate(
          file: File(asset.fileName),
          asset: asset,
          version: '2.1.0',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          updateCheckServiceProvider.overrideWithValue(check),
          updateInstallerServiceProvider.overrideWithValue(installer),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(updateStateProvider.notifier);
      await notifier.checkForUpdates();
      await notifier.downloadUpdate();
      return (container, installer);
    }

    test(
      'macOS selects the new app in Finder and keeps the app running',
      () async {
        final (container, installer) = await downloaded(macAsset);

        await container
            .read(updateStateProvider.notifier)
            .installDownloadedUpdate();

        expect(installer.calls, ['reveal']);
        final state = container.read(updateStateProvider);
        expect(state.status, UpdateStatus.downloaded);
        expect(state.downloadedUpdate?.asset, macAsset);
        expect(state.requiresManualReplace, isTrue);
      },
    );

    test(
      'launching the current release from staging offers the existing Finder action',
      () async {
        final check = _MockUpdateCheckService();
        when(() => check.currentVersion).thenReturn('2.1.0');
        const info = VersionInfo(
          version: '2.1.0',
          primaryAsset: macAsset,
          isNewer: true,
        );
        final update = DownloadedUpdate(
          file: File('fixture.zip'),
          asset: macAsset,
          version: '2.1.0',
        );
        final installer = _MockInstaller();
        when(installer.consumeExecutionResult).thenAnswer((_) async => null);
        when(installer.restorePendingUpdate).thenAnswer(
          (_) async =>
              RestoredDownloadedUpdate(versionInfo: info, update: update),
        );
        when(
          () => installer.clearPendingUpdate(update),
        ).thenAnswer((_) async => false);
        when(
          () => installer.revealUpdateInFinder(update),
        ).thenAnswer((_) async => 'fixture.app');
        final container = ProviderContainer(
          overrides: [
            updateCheckServiceProvider.overrideWithValue(check),
            updateInstallerServiceProvider.overrideWithValue(installer),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(updateStateProvider.notifier);
        await notifier.initialize();
        final state = container.read(updateStateProvider);
        expect(state.status, UpdateStatus.downloaded);
        expect(state.runningFromStaging, true);
        expect(state.notificationVisible, true);
        await notifier.installDownloadedUpdate();
        verify(() => installer.revealUpdateInFinder(update)).called(1);
      },
    );

    test('a Finder failure is shown and can be retried', () async {
      final (container, installer) = await downloaded(macAsset);
      installer.revealError = const UpdateInstallException('unpack failed');

      await container
          .read(updateStateProvider.notifier)
          .installDownloadedUpdate();

      final state = container.read(updateStateProvider);
      expect(state.status, UpdateStatus.error);
      expect(state.errorMessage, 'unpack failed');
      expect(state.hasDownloadedUpdate, isTrue);
    });

    test('Windows still installs and restarts', () async {
      final (container, installer) = await downloaded(windowsAsset);

      await container
          .read(updateStateProvider.notifier)
          .installDownloadedUpdate();

      expect(installer.calls, ['install']);
      expect(
        container.read(updateStateProvider).requiresManualReplace,
        isFalse,
      );
    });
  });

  for (final asset in const [
    ReleaseAssetInfo(
      type: ReleaseAssetType.macosPortable,
      platform: 'macos',
      fileName: 'mac.zip',
      downloadUrl: 'https://example.test/mac.zip',
      sha256: 'abc',
    ),
    ReleaseAssetInfo(
      type: ReleaseAssetType.windowsPortable,
      platform: 'windows',
      fileName: 'update.zip',
      downloadUrl: 'https://example.test/update.zip',
      sha256: 'abc',
    ),
  ]) {
    test(
      'after the update is in place, ${asset.platform} '
      '${asset.requiresManualReplace ? 'clears' : 'leaves'} the old package',
      () async {
        final check = _MockUpdateCheckService();
        when(() => check.currentVersion).thenReturn('2.1.0');
        final installer = _MockInstaller();
        when(installer.consumeExecutionResult).thenAnswer((_) async => null);
        final update = DownloadedUpdate(
          file: File(asset.fileName),
          asset: asset,
          version: '2.1.0',
        );
        when(installer.restorePendingUpdate).thenAnswer(
          (_) async => RestoredDownloadedUpdate(
            update: update,
            versionInfo: VersionInfo(
              version: '2.1.0',
              primaryAsset: asset,
              isNewer: true,
            ),
          ),
        );
        when(
          () => installer.clearPendingUpdate(update),
        ).thenAnswer((_) async => true);
        final container = ProviderContainer(
          overrides: [
            updateCheckServiceProvider.overrideWithValue(check),
            updateInstallerServiceProvider.overrideWithValue(installer),
          ],
        );
        addTearDown(container.dispose);

        await container.read(updateStateProvider.notifier).initialize();

        expect(container.read(updateStateProvider).hasNewVersion, isFalse);
        if (asset.requiresManualReplace) {
          verify(() => installer.clearPendingUpdate(update)).called(1);
        } else {
          // Windows 的更新脚本自己清理，这里保持原样。
          verifyNever(() => installer.clearPendingUpdate(update));
        }
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

/// 下载直接给出结果，安装和在访达中显示只记录调用。
class _RecordingInstaller extends UpdateInstallerService {
  _RecordingInstaller(this.downloaded)
    : super(dio: Dio(), installationService: _SupportedInstallationService());

  final DownloadedUpdate downloaded;
  final calls = <String>[];
  UpdateInstallException? revealError;

  @override
  Future<DownloadedUpdate> downloadUpdate(
    VersionInfo versionInfo, {
    void Function(UpdateDownloadProgress progress)? onProgress,
    CancelToken? cancelToken,
  }) async => downloaded;

  @override
  Future<String> revealUpdateInFinder(DownloadedUpdate update) async {
    calls.add('reveal');
    if (revealError != null) throw revealError!;
    return '/tmp/macos-2.1.0/W.O.F NAI Studio.app';
  }

  @override
  Future<void> installAndRestart(DownloadedUpdate update) async {
    calls.add('install');
  }
}
