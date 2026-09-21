import 'dart:io';

import 'package:flutter/services.dart';

/// Load the restored bundled font; OS fonts are used only for local captures.
Future<void> loadStudioCaptureFonts() async {
  await (FontLoader(
    'LXGW ZhenKai GB',
  )..addFont(rootBundle.load('fonts/LXGWZhenKaiGB-Regular.ttf'))).load();
  if (!Platform.isWindows || Platform.environment['CAPTURE_STUDIO_UI'] != '1') {
    return;
  }
  for (final entry in const {
    'monospace': 'C:/Windows/Fonts/segoeui.ttf',
    'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
  }.entries) {
    final file = File(entry.value);
    if (!await file.exists()) continue;
    await (FontLoader(
      entry.key,
    )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
  }
}
