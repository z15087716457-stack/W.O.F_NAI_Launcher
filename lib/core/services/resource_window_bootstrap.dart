import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

/// The child isolate can enter main before desktop_multi_window has finished
/// registering its per-engine channels. Wait for that registration handshake
/// before querying the launch arguments or installing child handlers.
Future<WindowController> waitForResourceWindowPlugins({
  Duration timeout = const Duration(seconds: 5),
}) async {
  final elapsed = Stopwatch()..start();
  while (true) {
    try {
      return await WindowController.fromCurrentEngine();
    } on MissingPluginException {
      // Only a missing registration is transient. Native/protocol errors must
      // still surface, and a missing DLL must not leave startup waiting forever.
      if (elapsed.elapsed >= timeout) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }
}
