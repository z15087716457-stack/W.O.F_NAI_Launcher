import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadStudioCaptureFonts() async {
  for (final entry in const {
    'StudioIcons': ['StudioIcons.ttf'],
    'Geist': [
      'Geist-Regular.ttf',
      'Geist-Medium.ttf',
      'Geist-SemiBold.ttf',
      'Geist-Bold.ttf',
    ],
    'Geist Mono': [
      'GeistMono-Regular.ttf',
      'GeistMono-Medium.ttf',
      'GeistMono-Prototype600.ttf',
      'GeistMono-Prototype700.ttf',
    ],
    'Geist Pixel Line': ['GeistPixel-Line.ttf'],
    'Geist Pixel Square': ['GeistPixel-Square.ttf'],
    'Geist Pixel Circle': ['GeistPixel-Circle.ttf'],
    'HarmonyOS Sans SC': [
      'HarmonyOS_Sans_SC_Regular.ttf',
      'HarmonyOS_Sans_SC_Medium.ttf',
      'HarmonyOS_Sans_SC_Bold.ttf',
    ],
    'Pretendard': [
      'Pretendard-Regular.otf',
      'Pretendard-Medium.otf',
      'Pretendard-SemiBold.otf',
      'Pretendard-Bold.otf',
    ],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await loader.load();
  }
  // The legacy titlebar uses the Windows UI fallback instead of a bundled font.
  if (Platform.isWindows && Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
    // Wiki's selected prototype uses Windows faces rather than HOS/Geist.
    for (final entry in const {
      'Segoe UI': ['segoeui.ttf', 'seguisb.ttf', 'segoeuib.ttf'],
      'Microsoft YaHei UI': ['msyh.ttc', 'msyhbd.ttc'],
      'Microsoft YaHei': ['msyh.ttc', 'msyhbd.ttc'],
      'Consolas': ['consola.ttf', 'consolab.ttf'],
      'Cascadia Code': ['CascadiaCode.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      var found = false;
      for (final name in entry.value) {
        final systemFile = File('C:/Windows/Fonts/$name');
        if (await systemFile.exists()) {
          loader.addFont(systemFile.readAsBytes().then(ByteData.sublistView));
          found = true;
        }
      }
      if (found) await loader.load();
    }
    final file = File('C:/Windows/Fonts/segoeui.ttf');
    if (await file.exists()) {
      await (FontLoader(
        'monospace',
      )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
    }
  }
}
