import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

final imageViewerPlatformProvider = Provider<ImageViewerPlatform>(
  (ref) => ImageViewerPlatform(),
);

class ImageViewerPlatform {
  Future<void>? _windowQueue;
  Future<void>? _preferenceQueue;

  Future<void> serializeWindow(Future<void> Function() action) {
    final result = _windowQueue == null
        ? Future<void>.sync(action)
        : _windowQueue!.then((_) => action());
    _windowQueue = result.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<({bool infoOpen, bool zoomHintSeen})> preferences() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      infoOpen: prefs.getBool('viewer_info_open') ?? true,
      zoomHintSeen: prefs.getBool('viewer_zoom_hint_seen') ?? false,
    );
  }

  Future<void> setPreference(String key, bool value) {
    Future<void> write() async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(key, value)) {
        throw StateError('Cannot save viewer preference');
      }
    }

    final result = _preferenceQueue == null
        ? Future<void>.sync(write)
        : _preferenceQueue!.then((_) => write());
    _preferenceQueue = result.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> backupDraft(String snapshot) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'draft-backups'));
    await directory.create(recursive: true);
    await File(
      p.join(
        directory.path,
        'before-viewer-${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    ).writeAsString(snapshot, flush: true);
  }

  Future<bool> isFullscreen() async {
    try {
      return await windowManager.isFullScreen();
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isMaximized() async {
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

class ImageViewerWindow {
  ImageViewerWindow(this.platform);
  final ImageViewerPlatform platform;
  bool? _originalFullscreen;
  bool _originalMaximized = false;
  bool? _current;
  bool _closed = false;

  Future<void> change(bool value) => platform.serializeWindow(() async {
    if (_closed) {
      return;
    }
    _originalFullscreen ??= await platform.isFullscreen();
    _current ??= _originalFullscreen;
    if (_current == value) {
      return;
    }
    if (_originalFullscreen == false && _current == false) {
      _originalMaximized = await platform.isMaximized();
    }
    if (_closed) {
      return;
    }
    await platform.setFullscreen(value);
    _current = value;
    if (!value && _originalMaximized) {
      await platform.maximize();
    }
  });

  Future<void> restore() {
    _closed = true;
    return platform.serializeWindow(() async {
      final original = _originalFullscreen;
      if (original == null || _current == original) {
        return;
      }
      try {
        await platform.setFullscreen(original);
        _current = original;
        if (!original && _originalMaximized) {
          await platform.maximize();
        }
      } catch (_) {
        _closed = false;
        rethrow;
      }
    });
  }
}
