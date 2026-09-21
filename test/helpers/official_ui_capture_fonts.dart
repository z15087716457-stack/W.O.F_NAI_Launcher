import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Exercises themes whose surface slots are identical, as in the user's UI.
ThemeData officialUiCaptureTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'OfficialUiCapture',
  colorScheme: const ColorScheme.dark(
    primary: Color(0xfff0ecd5),
    onPrimary: Color(0xff191919),
    surface: Color(0xff191919),
    onSurface: Color(0xfff0ecd5),
    surfaceContainer: Color(0xff191919),
    surfaceContainerHigh: Color(0xff191919),
    surfaceContainerHighest: Color(0xff191919),
    outline: Color(0xffa2a095),
  ),
);

Future<void> loadOfficialUiCaptureFonts() async {
  if (Platform.environment['CAPTURE_OFFICIAL_UI'] != '1') return;
  await (FontLoader(
    'OfficialUiCapture',
  )..addFont(rootBundle.load('fonts/LXGWZhenKaiGB-Regular.ttf'))).load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}
