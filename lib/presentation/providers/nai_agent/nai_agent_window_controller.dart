import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import 'nai_agent_workspace_provider.dart';

abstract class NaiAgentWindowHost {
  Future<Rect> bounds();
  Future<bool> locked();
  Future<List<Rect>> workAreas();
  Future<void> setBounds(Rect bounds);
  void watch(VoidCallback onChanged) {}
  void stopWatching() {}
}

class NaiAgentDesktopWindowHost extends NaiAgentWindowHost with WindowListener {
  NaiAgentDesktopWindowHost({double Function()? readPixelRatio})
    : _readPixelRatio = readPixelRatio ?? windowManager.getDevicePixelRatio;
  final double Function() _readPixelRatio;
  VoidCallback? _onChanged;
  @override
  Future<Rect> bounds() => windowManager.getBounds();
  @override
  Future<bool> locked() async =>
      await windowManager.isMaximized() ||
      await windowManager.isFullScreen() ||
      await windowManager.isDocked() != null;
  @override
  Future<List<Rect>> workAreas() async {
    final displays = await screenRetriever.getAllDisplays();
    final pixelRatio = _readPixelRatio();
    return [
      for (final display in displays)
        if (display.visiblePosition != null &&
            display.visibleSize != null &&
            display.scaleFactor != null &&
            display.scaleFactor!.isFinite &&
            display.scaleFactor! > 0 &&
            pixelRatio.isFinite &&
            pixelRatio > 0)
          Rect.fromLTWH(
            display.visiblePosition!.dx * display.scaleFactor! / pixelRatio,
            display.visiblePosition!.dy * display.scaleFactor! / pixelRatio,
            display.visibleSize!.width * display.scaleFactor! / pixelRatio,
            display.visibleSize!.height * display.scaleFactor! / pixelRatio,
          ),
    ];
  }

  @override
  Future<void> setBounds(Rect bounds) => windowManager.setBounds(bounds);
  @override
  void watch(VoidCallback onChanged) {
    _onChanged = onChanged;
    windowManager.addListener(this);
  }

  @override
  void stopWatching() {
    windowManager.removeListener(this);
    _onChanged = null;
  }

  @override
  void onWindowResize() => _onChanged?.call();
  @override
  void onWindowMove() => _onChanged?.call();
  @override
  void onWindowMaximize() => _onChanged?.call();
  @override
  void onWindowEnterFullScreen() => _onChanged?.call();
  @override
  void onWindowDocked() => _onChanged?.call();
}

class NaiAgentWindowController extends ChangeNotifier {
  NaiAgentWindowController({
    required this.host,
    required this.readSettings,
    required this.saveExpanded,
  }) {
    host?.watch(_windowChanged);
  }
  final NaiAgentWindowHost? host;
  final Future<AgentSettings> Function() readSettings;
  final Future<void> Function(bool expanded) saveExpanded;
  Future<void> _pending = Future.value();
  Rect? _original, _expected;
  bool _docked = false, _applying = false, _disposed = false;
  bool get docked => _docked;
  double get addedWidth => _original == null || _expected == null
      ? 0
      : _expected!.width - _original!.width;

  Future<void> _serial(Future<void> Function() action) {
    final task = _pending.then((_) async {
      if (!_disposed) await action();
    });
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<void> toggle() => _serial(() async {
    final settings = await readSettings();
    await _setExpanded(!settings.panelExpanded, settings.panelWidth);
  });

  Future<void> close() => _serial(() async {
    await _setExpanded(false, (await readSettings()).panelWidth);
  });

  Future<void> resizeDock(double width) => _serial(() async {
    if (!_docked || _original == null || host == null) return;
    if (!await _ownsBounds()) {
      _forget();
      return;
    }
    if (!await _grow(width)) await _restore();
  });

  Future<void> _setExpanded(bool expanded, double width) async {
    if (_disposed) return;
    if (expanded) {
      try {
        await _grow(width);
        if (!_disposed) await saveExpanded(true);
      } catch (_) {
        await _restore();
        rethrow;
      }
    } else {
      await saveExpanded(false);
      await _restore();
    }
  }

  bool _near(Rect a, Rect b) =>
      (a.left - b.left).abs() <= 1 &&
      (a.top - b.top).abs() <= 1 &&
      (a.width - b.width).abs() <= 1 &&
      (a.height - b.height).abs() <= 1;

  bool _valid(Rect rect) =>
      [rect.left, rect.top, rect.width, rect.height].every((v) => v.isFinite) &&
      rect.width > 0 &&
      rect.height > 0;

  Future<bool> _ownsBounds() async =>
      _expected != null &&
      !await host!.locked() &&
      _near(await host!.bounds(), _expected!);

  Future<bool> _grow(double width) async {
    if (host == null || _disposed || !width.isFinite) return false;
    try {
      if (await host!.locked()) return false;
      final current = await host!.bounds();
      final original = _original ?? current;
      if (!_valid(original)) return false;
      final areas = (await host!.workAreas()).where(_valid).toList();
      areas.sort((a, b) {
        double overlap(Rect area) {
          final intersection = area.intersect(original);
          return intersection.isEmpty
              ? 0
              : intersection.width * intersection.height;
        }

        return overlap(b).compareTo(overlap(a));
      });
      if (areas.isEmpty || !areas.first.contains(original.center)) return false;
      final target = Rect.fromLTWH(
        original.left,
        original.top,
        original.width + width.clamp(320.0, 720.0) + 8,
        original.height,
      );
      if (target.right > areas.first.right - 8 ||
          _disposed ||
          !(_near(await host!.bounds(), current)) ||
          await host!.locked()) {
        return false;
      }
      _applying = true;
      try {
        await host!.setBounds(target);
        final actual = await host!.bounds();
        if (_disposed || !_near(actual, target)) {
          _forget();
          return false;
        }
        _original = original;
        _expected = actual;
        _docked = true;
        notifyListeners();
        return true;
      } finally {
        _applying = false;
      }
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _restore() async {
    final original = _original;
    try {
      if (original != null && host != null && await _ownsBounds()) {
        _applying = true;
        await host!.setBounds(original);
      }
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    } finally {
      _applying = false;
      _forget();
    }
  }

  void _forget() {
    _original = _expected = null;
    _docked = false;
    if (!_disposed) notifyListeners();
  }

  void _windowChanged() {
    if (_applying || _expected == null || _disposed) return;
    unawaited(
      _serial(() async {
        if (_expected != null && !await _ownsBounds()) _forget();
      }).catchError((Object _) => _forget()),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    host?.stopWatching();
    super.dispose();
  }
}

final naiAgentWindowHostProvider = Provider<NaiAgentWindowHost?>(
  (ref) => Platform.isWindows ? NaiAgentDesktopWindowHost() : null,
);

final naiAgentWindowControllerProvider =
    ChangeNotifierProvider<NaiAgentWindowController>(
      (ref) => NaiAgentWindowController(
        host: ref.read(naiAgentWindowHostProvider),
        readSettings: () async {
          final c = ref.read(naiAgentControllerProvider);
          await c.ready;
          return c.settings;
        },
        saveExpanded: (expanded) => ref
            .read(naiAgentControllerProvider)
            .updateSettings({'panelExpanded': expanded}),
      ),
    );
