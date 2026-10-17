import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Register on startup; license text is loaded lazily when the page is opened.
void registerStudioAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in const {
      'Geist / Geist Mono / Geist Pixel': 'Geist-OFL.txt',
      'HarmonyOS Sans SC': 'HarmonyOS-Sans-LICENSE.txt',
      'Pretendard': 'Pretendard-OFL.txt',
      'Lobe Icons (provider brand assets)': 'LobeIcons-LICENSE.txt',
      'SeedVR (ByteDance-Seed project logo)': 'SeedVR-Logo-LICENSE.txt',
      'DanbooruSearchOnline (Chinese semantic data)':
          'DanbooruSearchOnline-GPL-3.0.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString('assets/licenses/${entry.value}'));
    }
  });
}
