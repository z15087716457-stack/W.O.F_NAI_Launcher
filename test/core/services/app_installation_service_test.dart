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
