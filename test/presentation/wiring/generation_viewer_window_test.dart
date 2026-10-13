import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/wiring/generation_viewer_window.dart';

class MemoryViewerWindow extends GenerationViewerPlatform {
  bool full = false;
  bool max = true;
  Completer<void>? pending;
  final writes = <bool>[];
  @override
  Future<bool> fullscreen() async => full;
  @override
  Future<bool> maximized() async => max;
  @override
  Future<void> setFullscreen(bool value) async {
    await pending?.future;
    full = value;
    writes.add(value);
  }

  @override
  Future<void> maximize() async => max = true;
}

void main() {
  test('全屏退出恢复原最大化状态，未使用窗口时不写窗口', () async {
    final platform = MemoryViewerWindow();
    final unused = GenerationViewerWindow(platform);
    await unused.restore();
    expect(platform.writes, isEmpty);
    final window = GenerationViewerWindow(platform);
    await window.change(true);
    await window.restore();
    expect(platform.writes, [true, false]);
    expect(platform.max, isTrue);
  });
  test('旧查看器退出不覆盖后开的查看器全屏状态', () async {
    final platform = MemoryViewerWindow();
    final old = GenerationViewerWindow(platform);
    await old.change(true);
    platform.pending = Completer<void>();
    final restoring = old.restore();
    final next = GenerationViewerWindow(platform);
    final opening = next.change(true);
    platform.pending!.complete();
    await restoring;
    await opening;
    expect(platform.full, isTrue);
    expect(platform.writes, [true, false, true]);
    await next.restore();
    expect(platform.full, isFalse);
  });
}
