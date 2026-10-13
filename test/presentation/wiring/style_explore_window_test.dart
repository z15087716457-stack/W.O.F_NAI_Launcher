import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/wiring/style_explore_platform.dart';

class _Window extends StyleExplorePlatform {
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
    if (!value) await exitWait?.future;
    fullscreen = value;
  }

  @override
  Future<void> maximize() async => events.add('maximize');
}

void main() {
  test(
    'closing an old exploration cannot undo the next fullscreen transition',
    () async {
      final platform = _Window();
      final old = StyleExploreWindow(platform);
      await old.change(true);
      platform.exitWait = Completer<void>();
      final closing = old.restore();
      await Future<void>.delayed(Duration.zero);
      final next = StyleExploreWindow(platform);
      final entering = next.change(true);
      await Future<void>.delayed(Duration.zero);
      platform.exitWait!.complete();
      await Future.wait([closing, entering]);
      expect(platform.fullscreen, isTrue);
      expect(platform.events, [true, false, true]);
      await next.restore();
    },
  );

  test('closing restores the originally maximized window', () async {
    final platform = _Window(maximized: true);
    final window = StyleExploreWindow(platform);
    await window.change(true);
    await window.restore();
    expect(platform.events, [true, false, 'maximize']);
  });

  test('closing preserves a window that was already fullscreen', () async {
    final platform = _Window(fullscreen: true);
    final window = StyleExploreWindow(platform);
    await window.change(true);
    await window.change(false);
    await window.restore();
    expect(platform.events, [false, true]);
  });

  test('duplicate requests do not dispatch duplicate transitions', () async {
    final platform = _Window();
    final window = StyleExploreWindow(platform);
    await Future.wait([
      window.change(true),
      window.change(true),
      window.change(false),
    ]);
    await window.restore();
    expect(platform.events, [true, false]);
  });

  test('closing before a queued enter prevents late fullscreen', () async {
    final platform = _Window();
    final window = StyleExploreWindow(platform);
    final changing = window.change(true);
    await window.restore();
    await changing;
    expect(platform.events, isEmpty);
  });
}
