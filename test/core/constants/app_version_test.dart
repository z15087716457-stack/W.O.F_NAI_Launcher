import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nai_launcher/core/constants/app_version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> version(String name, String build) async {
    PackageInfo.setMockInitialValues(
      appName: 'nai_launcher',
      packageName: 'nai_launcher',
      version: name,
      buildNumber: build,
      buildSignature: '',
    );
    await AppVersion.initialize();
  }

  test(
    '2.0 preview displays the release label and retains machine version/build',
    () async {
      await version('2.0.0-preview', '6');
      expect(AppVersion.versionName, '2.0 Preview');
      expect(
        AppVersion.getDisplayName('W.O.F NAI Studio'),
        'W.O.F NAI Studio 2.0 Preview',
      );
      expect(AppVersion.fullVersion, '2.0.0-preview+6');
      expect(AppVersion.buildNumber, '6');
      expect((AppVersion.major, AppVersion.minor, AppVersion.patch), (2, 0, 0));
      // pubspec 每次交付都会升 build 号，只锁定 2.0 Preview 系列格式。
      expect(
        File('pubspec.yaml').readAsStringSync(),
        matches(RegExp(r'^version: 2\.0\.0-preview\+\d+\s*$', multiLine: true)),
      );
    },
  );

  test('full version does not duplicate embedded build numbers', () async {
    await version('2.0.0-preview+6', '6');
    expect(AppVersion.versionName, '2.0 Preview');
    expect(AppVersion.fullVersion, '2.0.0-preview+6');
  });

  test(
    'stable and earlier beta formats still compare and display normally',
    () async {
      await version('2.0.0', '');
      expect(AppVersion.versionName, '2.0.0');
      expect(AppVersion.fullVersion, '2.0.0');
      await version('1.0.0-beta3.1', '3');
      expect(AppVersion.versionName, '1.0.0-Beta3.1');
      expect(AppVersion.fullVersion, '1.0.0-beta3.1+3');
    },
  );
}
