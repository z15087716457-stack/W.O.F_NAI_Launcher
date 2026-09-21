import 'package:flutter/services.dart';

Future<void> loadStudioCaptureFonts() async {
  for (final entry in const {
    'Geist': [
      'Geist-Regular.ttf',
      'Geist-Medium.ttf',
      'Geist-SemiBold.ttf',
      'Geist-Bold.ttf',
    ],
    'Geist Mono': ['GeistMono-Regular.ttf', 'GeistMono-Medium.ttf'],
    'Geist Pixel Line': ['GeistPixel-Line.ttf'],
    'HarmonyOS Sans SC': [
      'HarmonyOS_Sans_SC_Regular.ttf',
      'HarmonyOS_Sans_SC_Medium.ttf',
      'HarmonyOS_Sans_SC_Bold.ttf',
    ],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await loader.load();
  }
}
