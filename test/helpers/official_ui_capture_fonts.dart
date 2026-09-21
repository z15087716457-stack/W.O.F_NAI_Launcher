import 'dart:io';
import 'package:flutter/services.dart';

Future<void> loadOfficialUiCaptureFonts() async {
  if (Platform.environment['CAPTURE_OFFICIAL_UI'] != '1') return;
  await (FontLoader(
    'OfficialUiCapture',
  )..addFont(rootBundle.load('fonts/LXGWZhenKaiGB-Regular.ttf'))).load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}
