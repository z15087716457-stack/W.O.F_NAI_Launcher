import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import 'app_visibility.dart';

/// Installs [AppImageCache] as the app's image cache.
mixin AppImageCacheBinding on PaintingBinding {
  @override
  ImageCache createImageCache() => AppImageCache();
}

/// The app's [ImageCache]: Flutter's, plus [isInUse], which also counts the
/// images on screen while the window is hidden.
///
/// Flutter counts an image as in use ("live") while a widget listens to it.
/// While the window is hidden, `AppVisibilityScope` turns `TickerMode` off
/// for the whole app, and every `Image` then stops listening and keeps its
/// decode with a handle instead: the pictures on screen look unused. Dropping
/// them from the cache frees nothing (the widgets still hold the decodes) and
/// makes them decode again when the window is back, blank until then without
/// gaplessPlayback.
///
/// So for a hidden window an image also counts as in use if it was live when
/// the window was hidden, or was resolved since: the frame that pauses the
/// images resolves each of them again, and an image put on screen while
/// hidden resolves too. While hidden, [clear] (memory pressure, see
/// `HiddenWindowMemoryTrim`) keeps those. The record ends with the first
/// frame after the window is shown again, in which the images listen again.
///
/// The record only grows: a paused `Image` switching to another picture, or
/// going away, tells the cache nothing, so what was on screen at any point
/// of the hidden period counts until it ends. Code that knows a picture is
/// gone for good evicts it itself (a replaced stream preview); and what
/// [clear] kept that no widget listens to in that first frame goes then.
class AppImageCache extends ImageCache {
  AppImageCache({AppVisibility? visibility})
    : _visibility = visibility ?? AppVisibility.instance {
    _visibility.addListener(_visibilityChanged);
  }

  final AppVisibility _visibility;

  /// Every key the cache may hold, with the hidden period (numbered from 1)
  /// it was last in use in, 0 for none. Keys the cache no longer tracks are
  /// pruned, so this stays about as large as the cache.
  final _keys = HashMap<Object, int>();
  int _pruneAt = _pruneSlack;
  static const _pruneSlack = 64;

  /// The latest hidden period, and whether it still lasts: from the window
  /// hiding to the first frame after it is shown again.
  int _period = 0;
  bool _hidden = false;
  bool _watchingFrames = false;

  /// Keys [clear] kept for a hidden window, checked again when it ends.
  final _kept = HashSet<Object>();

  /// Whether a widget shows [key]: it listens to it, or the image was on
  /// screen in the hidden period still going on.
  bool isInUse(Object key) =>
      statusForKey(key).live || (_hidden && _keys[key] == _period);

  /// Cached (or loading) images in use.
  int get inUseCount =>
      _keys.keys.where((key) => containsKey(key) && isInUse(key)).length;

  /// [isInUse] for [cache], or whether [key] has listeners if [cache] is
  /// Flutter's own (a binding without [AppImageCacheBinding]).
  static bool inUse(ImageCache cache, Object key) => cache is AppImageCache
      ? cache.isInUse(key)
      : cache.statusForKey(key).live;

  @visibleForTesting
  int get debugKeyCount => _keys.length;

  @visibleForTesting
  Iterable<Object> get debugKeys => _keys.keys;

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) {
    final completer = super.putIfAbsent(key, loader, onError: onError);
    if (completer != null) {
      if (_hidden) {
        _keys[key] = _period;
      } else {
        _keys.putIfAbsent(key, () => 0);
      }
      if (_keys.length >= _pruneAt) _prune();
    }
    return completer;
  }

  @override
  bool evict(Object key, {bool includeLive = true}) {
    final evicted = super.evict(key, includeLive: includeLive);
    if (statusForKey(key).untracked) {
      _keys.remove(key);
      _kept.remove(key);
    }
    return evicted;
  }

  /// [evict] for every key [test] accepts.
  void evictWhere(bool Function(Object key) test, {bool includeLive = true}) {
    for (final key in _keys.keys.where(test).toList()) {
      evict(key, includeLive: includeLive);
    }
  }

  /// Flutter's while the window is visible (or the cache is turned off).
  /// While it is hidden, images in use stay: dropping them would free
  /// nothing. Those not on screen any more go when the window is back.
  @override
  void clear() {
    if (_visibility.isVisible || maximumSize == 0 || maximumSizeBytes == 0) {
      super.clear();
      _kept.clear();
    } else {
      for (final key in _keys.keys.toList()) {
        if (isInUse(key)) {
          _kept.add(key);
        } else {
          super.evict(key);
        }
      }
    }
    _prune();
  }

  /// Also forgets what was on screen in the hidden period (hot reload).
  @override
  void clearLiveImages() {
    super.clearLiveImages();
    _period++;
    _prune();
  }

  void _visibilityChanged() {
    if (_visibility.isVisible) return; // the period ends with the next frame
    if (!_hidden) {
      _hidden = true;
      _period++;
      if (!_watchingFrames) {
        _watchingFrames = true;
        SchedulerBinding.instance.addPersistentFrameCallback(_frame);
      }
    }
    // On screen now; they stop listening in the next frame.
    _keys.updateAll((key, period) => statusForKey(key).live ? _period : period);
  }

  void _frame(Duration _) {
    if (!_hidden || !_visibility.isVisible) return;
    _hidden = false;
    if (_kept.isEmpty) return;
    // This frame's build made the pictures on screen listen again; what the
    // hidden-window clear kept but nothing listens to has left the screen.
    for (final key in _kept) {
      if (!statusForKey(key).live) super.evict(key);
    }
    _kept.clear();
    _prune();
  }

  void _prune() {
    _keys.removeWhere((key, _) => statusForKey(key).untracked);
    _kept.removeWhere((key) => !_keys.containsKey(key));
    _pruneAt = _keys.length + _pruneSlack;
  }
}
