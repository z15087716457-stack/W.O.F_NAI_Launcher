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
    },
  );

  test('stable build 42 displays 2.0.0 and retains the full version', () async {
    for (final name in ['2.0.0', '2.0.0+42']) {
      await version(name, '42');
      expect(AppVersion.versionName, '2.0.0');
      expect(AppVersion.fullVersion, '2.0.0+42');
      expect(
        AppVersion.getDisplayName('W.O.F NAI Studio'),
        'W.O.F NAI Studio 2.0.0',
      );
    }
  });

  test('current pubspec version displays without build metadata', () async {
    final declared = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(declared, isNotNull);
    final name = declared!.group(1)!;
    final build = declared.group(2)!;
    for (final value in [name, '$name+$build']) {
      await version(value, build);
      expect(AppVersion.versionName, name);
      expect(AppVersion.fullVersion, '$name+$build');
      expect(AppVersion.buildNumber, build);
      expect(
        AppVersion.getDisplayName('W.O.F NAI Studio'),
        'W.O.F NAI Studio $name',
      );
    }
  });

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
