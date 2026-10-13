import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

final generationViewerPlatformProvider = Provider<GenerationViewerPlatform>(
  (ref) => GenerationViewerPlatform(),
);

class GenerationViewerPlatform {
  Future<void> _queue = Future.value();
  Future<void> serialize(Future<void> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<bool> fullscreen() async {
    try {
      return await windowManager.isFullScreen();
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> maximized() async {
    try {
      return await windowManager.isMaximized();
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> setFullscreen(bool value) async {
    try {
      await windowManager.setFullScreen(value);
    } on MissingPluginException {
      return;
    }
  }

  Future<void> maximize() async {
    try {
      await windowManager.maximize();
    } on MissingPluginException {
      return;
    }
  }
}

class GenerationViewerWindow {
  GenerationViewerWindow(this.platform);
  final GenerationViewerPlatform platform;
  bool? original;
  bool? current;
  bool wasMaximized = false;
  bool closed = false;
  Future<void> change(bool value) => platform.serialize(() async {
    if (closed) return;
    original ??= await platform.fullscreen();
    current ??= original;
    if (current == value) return;
    if (original == false && current == false) {
      wasMaximized = await platform.maximized();
    }
    if (closed) return;
    await platform.setFullscreen(value);
    current = value;
    if (!value && wasMaximized) await platform.maximize();
  });
  Future<void> restore() {
    closed = true;
    return platform.serialize(() async {
      if (original == null || current == original) return;
      try {
        await platform.setFullscreen(original!);
        current = original;
        if (!original! && wasMaximized) await platform.maximize();
      } catch (_) {
        closed = false;
        rethrow;
      }
    });
  }
}
