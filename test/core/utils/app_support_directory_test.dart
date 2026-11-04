import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_support_directory.dart';

void main() {
  SupportDirectoryLayout layout({
    bool windows = false,
    bool macOS = false,
    bool test = false,
    String bundleId = 'com.aaalice.naiLauncher',
  }) => supportDirectoryLayoutFor(
    isWindows: windows,
    isMacOS: macOS,
    isTest: test,
    legacyBundleId: bundleId,
  );

  test('Windows keeps executable-adjacent data and never imports', () {
    expect(layout(windows: true), SupportDirectoryLayout.executableAdjacent);
    expect(
      layout(windows: true, bundleId: ''),
      SupportDirectoryLayout.executableAdjacent,
    );
  });

  test('macOS copies the previous app only when one is named', () {
    expect(layout(macOS: true), SupportDirectoryLayout.macLegacyImport);
    expect(
      layout(macOS: true, bundleId: 'com.example.trial'),
      SupportDirectoryLayout.macLegacyImport,
    );
    for (final disabled in ['', '../elsewhere', '/Users/me/data', '.', '..']) {
      expect(
        layout(macOS: true, bundleId: disabled),
        SupportDirectoryLayout.system,
        reason: disabled,
      );
    }
  });

  test('tests and other platforms use path_provider directly', () {
    expect(layout(windows: true, test: true), SupportDirectoryLayout.system);
    expect(layout(macOS: true, test: true), SupportDirectoryLayout.system);
    expect(layout(), SupportDirectoryLayout.system);
  });

  test('the previous app defaults to the 1.x macOS bundle', () {
    expect(macLegacyBundleId, 'com.aaalice.naiLauncher');
  });
}
