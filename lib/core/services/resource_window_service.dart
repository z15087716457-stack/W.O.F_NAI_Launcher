import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import 'resource_window_protocol.dart';

/// Main-engine API for the technical spike. No providers/stores are opened.
/// The existing in-app floating windows remain the production entry point.
class ResourceWindowService {
  static const _native = MethodChannel(
    'com.nailauncher/resource_window_native',
  );
  static const hostChannel = WindowMethodChannel(
    'com.nailauncher/resources/host/v1',
    mode: ChannelMode.unidirectional,
  );

  Future<void> initialize() => hostChannel.setMethodCallHandler((call) async {
    if (call.method == 'ready') return {'version': 1};
    // query/get/thumbnail are intentionally not implemented in this spike.
    throw MissingPluginException('Unsupported resource method: ${call.method}');
  });

  Future<WindowController> open(ResourceWindowArguments arguments) =>
      WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: arguments.encode(),
        ),
      );

  /// Native close works even before the child has installed its Dart handler.
  /// Owner destruction is the final synchronous safety net in Win32.
  Future<void> closeAll() => _native.invokeMethod<void>('closeAll');

  /// Individual methods require the child to have announced `ready`.
  Future<void> close(WindowController window) =>
      window.invokeMethod<void>('resource.close');

  Future<void> setAlwaysOnTop(WindowController window, bool enabled) =>
      window.invokeMethod<void>('resource.setAlwaysOnTop', enabled);
}
