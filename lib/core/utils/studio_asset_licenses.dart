import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Register on startup; license text is loaded lazily when the page is opened.
void registerStudioAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in const {
      'Geist / Geist Mono / Geist Pixel': 'Geist-OFL.txt',
      'HarmonyOS Sans SC': 'HarmonyOS-Sans-LICENSE.txt',
      'Geist UI Icons (community snapshot)': 'Geist-Icons-MIT.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString('assets/licenses/${entry.value}'));
    }
  });
}
