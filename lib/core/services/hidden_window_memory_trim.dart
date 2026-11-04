import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../utils/app_logger.dart';
import 'app_image_cache.dart';
import 'app_visibility.dart';

/// Once the main window has been hidden (menu bar / tray, minimized) for
/// [delay], frees what can be rebuilt: Flutter's memory-pressure handling,
/// which drops every decoded image nothing on screen holds (gallery
/// thumbnails scrolled away, closed viewers, earlier canvas decodes) and
/// tells memory-pressure observers. Images on screen stay (to Flutter alone
/// they look unused while the window is hidden, see [AppImageCache]), so the
/// page shown again does not decode or blink anything; the rest decode on
/// demand.
class HiddenWindowMemoryTrim {
  HiddenWindowMemoryTrim({
    AppVisibility? visibility,
    this.delay = defaultDelay,
    VoidCallback? trim,
  }) : _visibility = visibility ?? AppVisibility.instance,
       _trim = trim ?? _relieveMemoryPressure;

  static const defaultDelay = Duration(minutes: 1);
  static final instance = HiddenWindowMemoryTrim();

  final AppVisibility _visibility;
  final Duration delay;
  final VoidCallback _trim;
  Timer? _timer;
  bool _started = false;

  static void _relieveMemoryPressure() {
    WidgetsBinding.instance.handleMemoryPressure();
    // The image cache lets go of what it dropped at the end of the next
    // frame, and a hidden window draws none: without one the memory only
    // comes back once the window is shown. Draw that one frame now; with
    // TickerMode off nothing asks for another, and the window stays hidden.
    SchedulerBinding.instance.scheduleForcedFrame();
  }

  void start() {
    if (_started) return;
    _started = true;
    _visibility.addListener(_changed);
    _changed();
  }

  void _changed() {
    if (_visibility.isVisible) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer(delay, () {
      _timer = null;
      if (_visibility.isVisible) return;
      final cache = PaintingBinding.instance.imageCache;
      final inUse = cache is AppImageCache
          ? cache.inUseCount
          : cache.liveImageCount;
      AppLogger.i(
        'Window hidden for ${delay.inSeconds}s, releasing decoded images '
            '(${cache.currentSize} cached, ${cache.currentSizeBytes >> 20} MB; '
            '$inUse in use stay)',
        'Memory',
      );
      _trim();
    });
  }

  void stop() {
    _started = false;
    _timer?.cancel();
    _timer = null;
    _visibility.removeListener(_changed);
  }
}
