import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';

void main() {
  group('ReleaseAssetInfo', () {
    test('detects Windows installer asset', () {
      final asset = ReleaseAssetInfo.fromGitHubAsset({
        'name': 'NAI_Launcher_Windows_1.0.0-beta13+16_Setup.exe',
        'browser_download_url': 'https://example.com/setup.exe',
        'size': 123,
      });

      expect(asset.type, ReleaseAssetType.windowsInstaller);
      expect(asset.platform, 'windows');
      expect(asset.supportsInAppInstall, isTrue);
      expect(asset.typeId, 'windows-installer');
    });

    test('detects portable assets', () {
      final windowsAsset = ReleaseAssetInfo.fromGitHubAsset({
        'name': 'NAI_Launcher_Windows_1.0.0_Portable.zip',
        'browser_download_url': 'https://example.com/windows.zip',
      });

      expect(windowsAsset.type, ReleaseAssetType.windowsPortable);
      expect(windowsAsset.supportsInAppInstall, isTrue);
      expect(windowsAsset.platform, 'windows');
    });

    test('retains the SHA256 digest supplied by GitHub', () {
      const hash =
          'AC94C80DF00816B0DEC6B46D68FB82BC1A1C36C35088D6BB3EE5B29702D9B39A';
      final asset = ReleaseAssetInfo.fromGitHubAsset({
        'name': 'WOF_NAI_Studio_Windows_2.2.0_Portable.zip',
        'browser_download_url': 'https://example.com/update.zip',
        'digest': 'sha256:$hash',
      });

      expect(asset.sha256, hash.toLowerCase());
    });

    test('ignores unavailable or invalid GitHub digests', () {
      for (final digest in [null, '', 'sha256:abc', 'md5:${'a' * 32}', 123]) {
        final asset = ReleaseAssetInfo.fromGitHubAsset({
          'name': 'WOF_NAI_Studio_Windows_2.2.0_Portable.zip',
          'digest': digest,
        });
        expect(asset.sha256, isNull, reason: '$digest');
      }
    });

    test('merges manifest metadata with GitHub asset', () {
      final githubAsset = ReleaseAssetInfo.fromGitHubAsset({
        'name': 'NAI_Launcher_Windows_1.0.0_Setup.exe',
        'browser_download_url': 'https://example.com/setup.exe',
        'size': 123,
      });
      final asset = ReleaseAssetInfo.fromManifestAsset({
        'type': 'windows-installer',
        'fileName': 'NAI_Launcher_Windows_1.0.0_Setup.exe',
        'sha256': 'abc123',
        'description': '安装版',
      }, githubAsset: githubAsset);

      expect(asset.downloadUrl, githubAsset.downloadUrl);
      expect(asset.size, 123);
      expect(asset.sha256, 'abc123');
      expect(asset.description, '安装版');
    });
  });
}
