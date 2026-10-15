import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
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
  Future<bool> reveal(Rect original, Rect target) async {
    await setBounds(target);
    return true;
  }

  Future<void> cancelReveal() async {}
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
  static const _reveal = MethodChannel('com.nailauncher/window_reveal');
  @override
  Future<bool> reveal(Rect original, Rect target) async {
    try {
      return await _reveal.invokeMethod<bool>('grow', {
            'left': original.left,
            'top': original.top,
            'width': original.width,
            'height': original.height,
            'targetWidth': target.width,
            'pixelRatio': _readPixelRatio(),
            'durationMs':
                WidgetsBinding
                    .instance
                    .platformDispatcher
                    .accessibilityFeatures
                    .disableAnimations
                ? 0.0
                : 280.0,
          }) ??
          false;
    } on MissingPluginException {
      await setBounds(target);
      return true;
    }
  }

  @override
  Future<void> cancelReveal() async {
    try {
      await _reveal.invokeMethod<void>('cancel');
    } on MissingPluginException {
      /* No native reveal on this host. */
    }
  }

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
  bool _nativeReveal = false;
  bool? _presentationExpanded;
  double _openingGrowth = 0;
  // Layout remains docked after manual movement, resizing and maximization.
  // Ownership below controls automatic restoration only.
  bool get docked => _docked;
  bool get nativeReveal => _nativeReveal;
  bool? get presentationExpanded => _presentationExpanded;
  double get openingGrowth => _openingGrowth;
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
  Future<void> close() => _serial(() => _setExpanded(false, 0));

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
      host != null &&
      !await host!.locked() &&
      _near(await host!.bounds(), _expected!);

  Future<({Rect original, Rect target})?> _growth(double width) async {
    if (host == null || _disposed || !width.isFinite) return null;
    try {
      if (await host!.locked()) return null;
      final current = await host!.bounds();
      if (!_valid(current) || _disposed) return null;
      final areas = (await host!.workAreas()).where(_valid).toList();
      areas.sort((a, b) {
        double overlap(Rect area) {
          final intersection = area.intersect(current);
          return intersection.isEmpty
              ? 0
              : intersection.width * intersection.height;
        }

        return overlap(b).compareTo(overlap(a));
      });
      if (areas.isEmpty || !areas.first.contains(current.center)) return null;
      final extra = (areas.first.right - 8 - current.right).clamp(
        0.0,
        width.clamp(320.0, 1280.0) + 8,
      );
      if (extra < 80 ||
          _disposed ||
          !(_near(await host!.bounds(), current)) ||
          await host!.locked()) {
        return null;
      }
      return (
        original: current,
        target: Rect.fromLTWH(
          current.left,
          current.top,
          current.width + extra,
          current.height,
        ),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _setExpanded(bool expanded, double width) async {
    if (_disposed) return;
    final plan = expanded ? await _growth(width) : null;
    if (_disposed) return;
    final restore = !expanded && await _ownsBounds();
    _nativeReveal = plan != null || restore;
    _openingGrowth = plan == null ? 0 : plan.target.width - plan.original.width;
    _presentationExpanded = expanded;
    _docked = expanded;
    notifyListeners();
    try {
      // Display state precedes native growth. The prepared surface can then
      // paint the complete pane before the window exposes a single new pixel.
      await saveExpanded(expanded);
      if (_disposed) return;
      if (plan != null) {
        if (await host!.locked() ||
            !(_near(await host!.bounds(), plan.original))) {
          return;
        }
        _applying = true;
        final completed = await host!.reveal(plan.original, plan.target);
        final actual = await host!.bounds();
        if (!_disposed && completed && _near(actual, plan.target)) {
          _original = plan.original;
          _expected = actual;
        } else {
          _forgetOwnership();
        }
      } else if (restore && _original != null && await _ownsBounds()) {
        _applying = true;
        await host!.setBounds(_original!);
        _forgetOwnership();
      }
    } on MissingPluginException {
      _forgetOwnership();
    } on PlatformException {
      _forgetOwnership();
    } catch (_) {
      _presentationExpanded = !expanded;
      _docked = !expanded;
      rethrow;
    } finally {
      _applying = false;
      _nativeReveal = false;
      _openingGrowth = 0;
      _presentationExpanded = null;
      if (!_disposed) notifyListeners();
    }
  }

  void _forgetOwnership() {
    _original = _expected = null;
  }

  void _windowChanged() {
    if (_applying || _expected == null || _disposed) return;
    unawaited(
      _serial(() async {
        if (_expected != null && !await _ownsBounds()) _forgetOwnership();
      }).catchError((Object _) => _forgetOwnership()),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    host?.stopWatching();
    unawaited(host?.cancelReveal().catchError((Object _) {}) ?? Future.value());
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
