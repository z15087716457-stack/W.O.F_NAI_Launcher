import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Window extends ImageViewerPlatform {
  _Window({this.fullscreen = false, this.maximized = false});
  bool fullscreen;
  final bool maximized;
  final events = <Object>[];
  Completer<void>? exitWait;
  @override
  Future<bool> isFullscreen() async => fullscreen;
  @override
  Future<bool> isMaximized() async => maximized;
  @override
  Future<void> setFullscreen(bool value) async {
    events.add(value);
    if (!value) {
      await exitWait?.future;
    }
    fullscreen = value;
  }

  @override
  Future<void> maximize() async => events.add('maximize');
}

void main() {
  test(
    'closing old viewer cannot undo a new viewer fullscreen transition',
    () async {
      final platform = _Window();
      final old = ImageViewerWindow(platform);
      await old.change(true);
      platform.exitWait = Completer<void>();
      final closing = old.restore();
      await Future<void>.delayed(Duration.zero);
      final next = ImageViewerWindow(platform);
      final entering = next.change(true);
      await Future<void>.delayed(Duration.zero);
      platform.exitWait!.complete();
      await Future.wait([closing, entering]);
      expect(platform.fullscreen, isTrue);
      expect(platform.events, [true, false, true]);
      await next.restore();
    },
  );
  test('enter exit and closing restore originally maximized state', () async {
    final platform = _Window(maximized: true);
    final window = ImageViewerWindow(platform);
    await window.change(true);
    await window.restore();
    expect(platform.events, [true, false, 'maximize']);
  });

  test('closing preserves a window which was already fullscreen', () async {
    final platform = _Window(fullscreen: true);
    final window = ImageViewerWindow(platform);
    await window.change(true);
    await window.change(false);
    await window.restore();
    expect(platform.events, [false, true]);
  });

  test('duplicate requests do not dispatch duplicate transitions', () async {
    final platform = _Window();
    final window = ImageViewerWindow(platform);
    await Future.wait([
      window.change(true),
      window.change(true),
      window.change(false),
    ]);
    await window.restore();
    expect(platform.events, [true, false]);
  });

  test('closing before queued enter prevents late fullscreen', () async {
    final platform = _Window();
    final window = ImageViewerWindow(platform);
    final changing = window.change(true);
    await window.restore();
    await changing;
    expect(platform.events, isEmpty);
  });

  test('viewer preferences have separate defaults and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final platform = ImageViewerPlatform();
    expect(await platform.preferences(), (infoOpen: true, zoomHintSeen: false));
    await platform.setPreference('viewer_info_open', false);
    await platform.setPreference('viewer_zoom_hint_seen', true);
    expect(await platform.preferences(), (infoOpen: false, zoomHintSeen: true));
  });
}
