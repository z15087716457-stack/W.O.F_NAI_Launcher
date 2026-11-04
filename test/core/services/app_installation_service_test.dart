import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_installation_service.dart';

void main() {
  group('AppInstallationService', () {
    test('checks the Studio key before the legacy 1.x key', () {
      expect(AppInstallationService.uninstallRegistryPaths, [
        r'Software\Microsoft\Windows\CurrentVersion\Uninstall\W.O.F NAI Studio',
        r'Software\Microsoft\Windows\CurrentVersion\Uninstall\Aaalice NAI Launcher',
      ]);
    });

    test('macOS uses the app archive and finishes updates in Finder', () {
      final service = AppInstallationService(operatingSystem: 'macos');

      expect(service.getInstallationType(), AppInstallationType.macosPortable);
      expect(service.getReleaseAssetPreference(), 'macos');
      expect(service.supportsInAppInstall, isTrue);
    });

    test('Windows outside a registered install directory is portable', () {
      // 测试进程不在任何安装目录里；注册表读不到（非 Windows）时同样按便携版。
      final service = AppInstallationService(operatingSystem: 'windows');

      expect(
        service.getInstallationType(),
        AppInstallationType.windowsPortable,
      );
      expect(service.getReleaseAssetPreference(), 'windows-portable');
      expect(service.supportsInAppInstall, isTrue);
    });

    test('other platforms have no release package', () {
      final service = AppInstallationService(operatingSystem: 'linux');

      expect(service.getInstallationType(), AppInstallationType.unsupported);
      expect(service.getReleaseAssetPreference(), 'unknown');
      expect(service.supportsInAppInstall, isFalse);
      expect(service.readWindowsInstallLocation(), isNull);
    });

    test('detects executable inside install directory', () {
      expect(
        AppInstallationService.isExecutableInsideInstallDir(
          executablePath:
              r'C:\Users\alice\AppData\Local\Programs\W.O.F NAI Studio\nai_launcher.exe',
          installLocation:
              r'C:\Users\alice\AppData\Local\Programs\W.O.F NAI Studio',
        ),
        isTrue,
      );
    });

    test('does not match similar path prefixes', () {
      expect(
        AppInstallationService.isExecutableInsideInstallDir(
          executablePath:
              r'C:\Users\alice\AppData\Local\Programs\W.O.F NAI Studio Portable\nai_launcher.exe',
          installLocation:
              r'C:\Users\alice\AppData\Local\Programs\W.O.F NAI Studio',
        ),
        isFalse,
      );
    });

    test('normalizes slash and trailing separator differences', () {
      expect(
        AppInstallationService.isExecutableInsideInstallDir(
          executablePath:
              'C:/Users/alice/AppData/Local/Programs/W.O.F NAI Studio/nai_launcher.exe',
          installLocation:
              r'C:\Users\alice\AppData\Local\Programs\W.O.F NAI Studio\',
        ),
        isTrue,
      );
    });
  });
}
