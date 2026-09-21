import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Only the custom title bar reveals the native backdrop. Pages stay opaque.
abstract final class WindowMaterialService {
  static const _channel = MethodChannel('com.nailauncher/window_material');
  static final available = ValueNotifier<bool>(false);
  static bool _listening = false;
  static int _revision = 0;

  static Future<void> configure({
    required bool dark,
    required bool enabled,
  }) async {
    if (kIsWeb || !Platform.isWindows) return;
    if (!_listening) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'availabilityChanged') {
          available.value = call.arguments == true;
        }
      });
      _listening = true;
    }
    final revision = ++_revision;
    try {
      final result = await _channel.invokeMethod<bool>('configure', {
        'dark': dark,
        'enabled': enabled,
      });
      if (revision == _revision) available.value = result == true;
    } on MissingPluginException {
      if (revision == _revision) available.value = false;
    } on PlatformException {
      if (revision == _revision) available.value = false;
    }
  }
}
