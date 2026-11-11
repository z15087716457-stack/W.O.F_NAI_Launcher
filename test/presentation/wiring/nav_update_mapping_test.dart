import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/update_installer_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/data/models/version/version_info.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/wiring/nav_wiring.dart';

void main() {
  const info = VersionInfo(version: '2.3.3');
  test(
    'checking, skipped, up-to-date and failed checks do not show an update action',
    () {
      for (final status in [
        UpdateStatus.idle,
        UpdateStatus.checking,
        UpdateStatus.skipped,
        UpdateStatus.upToDate,
        UpdateStatus.error,
      ]) {
        expect(navUpdateData(UpdateState(status: status)), isNull);
      }
    },
  );
  test(
    'every actionable backend state maps to the corresponding sidebar state',
    () {
      for (final (backend, ui) in [
        (UpdateStatus.available, NavUpdateStatus.available),
        (UpdateStatus.downloading, NavUpdateStatus.downloading),
        (UpdateStatus.downloaded, NavUpdateStatus.downloaded),
        (UpdateStatus.installing, NavUpdateStatus.installing),
        (UpdateStatus.error, NavUpdateStatus.downloadFailed),
      ]) {
        final data = navUpdateData(
          UpdateState(
            status: backend,
            versionInfo: info,
            downloadProgress: .46,
            notificationVisible: false,
          ),
        )!;
        expect(data.status, ui);
        expect(data.version, '2.3.3');
        expect(data.progress, .46);
      }
    },
  );
  test(
    'installation failure preserves retry state and manual replacement platform',
    () {
      const asset = ReleaseAssetInfo(
        type: ReleaseAssetType.macosPortable,
        platform: 'macos',
        fileName: 'Studio.zip',
        downloadUrl: 'https://example.test/Studio.zip',
      );
      final data = navUpdateData(
        UpdateState(
          status: UpdateStatus.error,
          versionInfo: info,
          downloadedUpdate: DownloadedUpdate(
            file: File('unused.zip'),
            asset: asset,
            version: '2.3.3',
          ),
        ),
      )!;
      expect(data.status, NavUpdateStatus.installFailed);
      expect(data.manualReplace, isTrue);
    },
  );
  test('invalid progress is normalized once before reaching the painter', () {
    for (final (raw, expected) in [
      (double.nan, 0.0),
      (double.infinity, 0.0),
      (-.2, 0.0),
      (1.2, 1.0),
    ]) {
      expect(
        navUpdateData(
          UpdateState(
            status: UpdateStatus.downloading,
            versionInfo: info,
            downloadProgress: raw,
          ),
        )!.progress,
        expected,
      );
    }
  });
}
