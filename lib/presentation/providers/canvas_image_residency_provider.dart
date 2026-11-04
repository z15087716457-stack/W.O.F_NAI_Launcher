import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_image_cache.dart';
import '../../core/services/app_visibility.dart';
import '../screens/generation/widgets/canvas/generation_canvas_controller.dart';
import '../ui/kit/ui_preview_image.dart';
import 'canvas_settings_provider.dart';
import 'generation/preview_selection_provider.dart';
import 'image_generation_provider.dart';

/// How the generation canvas decodes its images. The user's rule: the latest
/// generated images (5–10) always at full resolution; images the user looked
/// at keep it for a while (about 5 minutes); everything else at the size it
/// is shown, sharpened when zoomed in. Change the numbers here.
abstract final class CanvasImageResidencyLimits {
  /// The newest images on the canvas that always keep full resolution.
  static const recent = 10;

  /// How long an image the user looked at (selected it, opened it in the
  /// viewer) keeps full resolution afterwards.
  static const viewedFor = Duration(minutes: 5);

  /// At most this many looked-at images keep it at once (oldest go first).
  static const viewed = 10;

  /// Full-resolution images at most: the newest, the looked-at, the selected.
  static const fullResolution = recent + viewed + 1;

  /// Shown images decode this much larger than their size on screen, the
  /// same margin the history covers use, so filtering never looks softer.
  static const filterHeadroom = 1.5;

  /// Tiles outside the view decode at most this wide: a placeholder until
  /// they are scrolled into view.
  static const offscreenWidth = 256;

  /// Decode widths are powers of two from here, so zooming only re-decodes
  /// when the size really changes.
  static const minimumWidth = 64;

  /// The view counts as this much larger on every side (a fraction of the
  /// viewport), so tiles about to scroll in are already sharp.
  static const visibleMargin = 0.5;
}

/// Which canvas images keep full resolution right now.
@immutable
class CanvasImageResidency {
  const CanvasImageResidency({
    this.recent = const {},
    this.viewed = const {},
    this.selected,
  });

  /// The newest [CanvasImageResidencyLimits.recent] images.
  final Set<String> recent;

  /// Looked-at images and when they were last looked at, oldest first.
  final Map<String, DateTime> viewed;

  /// The selected image: being looked at now.
  final String? selected;

  /// Whether [id] shows at full resolution. With [at], a look older than
  /// [CanvasImageResidencyLimits.viewedFor] no longer counts, even before
  /// the notifier has dropped it.
  bool keepsFullResolution(String id, {DateTime? at}) {
    if (id == selected || recent.contains(id)) return true;
    final looked = viewed[id];
    if (looked == null) return false;
    return at == null ||
        at.difference(looked) < CanvasImageResidencyLimits.viewedFor;
  }

  Set<String> get fullResolutionIds => {...recent, ...viewed.keys, ?selected};

  CanvasImageResidency copyWith({
    Set<String>? recent,
    Map<String, DateTime>? viewed,
    String? selected,
    bool clearSelected = false,
  }) => CanvasImageResidency(
    recent: recent ?? this.recent,
    viewed: viewed ?? this.viewed,
    selected: clearSelected ? null : selected ?? this.selected,
  );
}

/// The clock the residency rules use; tests replace it.
final canvasResidencyClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final canvasImageResidencyProvider =
    NotifierProvider<CanvasImageResidencyNotifier, CanvasImageResidency>(
      CanvasImageResidencyNotifier.new,
    );

class CanvasImageResidencyNotifier extends Notifier<CanvasImageResidency> {
  Timer? _expiry;
  bool _disposed = false;

  /// Canvas tiles on screen. Looks only expire while there are some: with
  /// none mounted nothing holds a decode, and no timer is left running.
  int _tiles = 0;

  @override
  CanvasImageResidency build() {
    ref.onDispose(() {
      _disposed = true;
      _expiry?.cancel();
    });
    ref.listen(imageGenerationNotifierProvider.select(_recentKey), (_, _) {
      final recent = _recentIds(ref.read(imageGenerationNotifierProvider));
      if (!setEquals(recent, state.recent)) {
        _set(state.copyWith(recent: recent));
      }
    });
    ref.listen(generationPreviewSelectionProvider, (previous, next) {
      // The image left behind was looked at until now.
      var residency = state;
      if (previous != null && previous != next && _exists(previous)) {
        residency = residency.copyWith(viewed: _viewedWith(previous));
      }
      _set(
        next == null
            ? residency.copyWith(clearSelected: true)
            : residency.copyWith(selected: next),
      );
    });
    ref.listen(
      imageGenerationNotifierProvider.select(
        (generation) => generation.streamPreviewSlots,
      ),
      _releaseReplacedPreviews,
    );
    return CanvasImageResidency(
      recent: _recentIds(ref.read(imageGenerationNotifierProvider)),
      selected: ref.read(generationPreviewSelectionProvider),
    );
  }

  bool _exists(String id) =>
      ref.read(canvasPinnedNotifierProvider).contains(id) ||
      ref.read(imageGenerationNotifierProvider).findImageById(id) != null;

  /// The image was looked at (opened in the viewer, shown there, closed).
  void markViewed(String id) {
    if (_disposed || !_exists(id)) return;
    _set(state.copyWith(viewed: _viewedWith(id)));
  }

  /// A canvas tile was mounted; [detach] when it goes.
  void attach() {
    if (_tiles++ == 0) _scheduleExpiry();
  }

  void detach() {
    if (--_tiles > 0) return;
    _tiles = 0;
    _expiry?.cancel();
    _expiry = null;
  }

  DateTime get _now => ref.read(canvasResidencyClockProvider)();

  Map<String, DateTime> _viewedWith(String id) {
    final viewed = LinkedHashMap<String, DateTime>.of(state.viewed)
      ..remove(id)
      ..[id] = _now;
    while (viewed.length > CanvasImageResidencyLimits.viewed) {
      viewed.remove(viewed.keys.first);
    }
    return viewed;
  }

  void _set(CanvasImageResidency next) {
    final lost = state.fullResolutionIds.difference(next.fullResolutionIds);
    state = next;
    _scheduleExpiry();
    if (lost.isNotEmpty) _release(lost);
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    _expiry = null;
    if (state.viewed.isEmpty || _tiles == 0 || _disposed) return;
    final oldest = state.viewed.values.reduce((a, b) => a.isBefore(b) ? a : b);
    final due = oldest
        .add(CanvasImageResidencyLimits.viewedFor)
        .difference(_now);
    _expiry = Timer(due.isNegative ? Duration.zero : due, _expire);
  }

  void _expire() {
    _expiry = null;
    if (_disposed) return;
    final now = _now;
    final kept = LinkedHashMap<String, DateTime>.fromEntries(
      state.viewed.entries.where(
        (e) => now.difference(e.value) < CanvasImageResidencyLimits.viewedFor,
      ),
    );
    if (kept.length != state.viewed.length) {
      _set(state.copyWith(viewed: kept));
    } else {
      _scheduleExpiry();
    }
  }

  /// Images that lost full resolution give their full decode back now
  /// instead of when the image cache fills up. A tile still showing one
  /// switches to its smaller decode during the next frame, so those go after
  /// it; one still shown large (or open elsewhere) is in use and stays with
  /// the cache's own limits, as before. In use as [AppImageCache] sees it:
  /// while the window is hidden, paused tiles do not listen to their images.
  void _release(Set<String> ids) {
    final generation = ref.read(imageGenerationNotifierProvider);
    final pending = <String, MemoryImage>{
      for (final id in ids)
        if (generation.findImageById(id) case final image?)
          id: MemoryImage(image.bytes),
    };
    _evictUnused(pending);
    if (pending.isNotEmpty) _evictAfterFrame(pending);
  }

  /// [_evictUnused] after the next frame. While the window is hidden,
  /// [AppImageCache] counts what the paused tiles showed in that time as in
  /// use, the full decodes they have just switched away from too: the check
  /// waits for a frame with the window back, whose build makes only the
  /// pictures on screen listen again. A hidden window still draws frames
  /// (the release a minute after hiding draws one, Windows keeps drawing in
  /// the tray); checking in one of them left such a decode to the cache's
  /// limits.
  void _evictAfterFrame(Map<String, MemoryImage> pending) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (AppVisibility.instance.isVisible || _disposed) {
        _evictUnused(pending);
      } else {
        _evictAfterFrame(pending);
      }
    });
  }

  void _evictUnused(Map<String, MemoryImage> pending) {
    if (_disposed) {
      pending.clear();
      return;
    }
    final cache = PaintingBinding.instance.imageCache;
    final now = _now;
    pending.removeWhere((id, full) {
      if (state.keepsFullResolution(id, at: now)) return true;
      if (AppImageCache.inUse(cache, full)) return false;
      cache.evict(full);
      return true;
    });
  }

  /// Drop deleted canvas tiles and their history covers once no remaining
  /// generation or pin uses the same encoded bytes. Live listeners keep their
  /// image until they detach, including an open viewer closing after deletion.
  void releaseRemovedImages(List<GeneratedImage> candidates) {
    if (_disposed || candidates.isEmpty) return;
    final generation = ref.read(imageGenerationNotifierProvider);
    final removedIds = candidates.map((image) => image.id).toSet();
    final discarded = HashMap<Uint8List, GeneratedImage>.identity()
      ..addEntries(candidates.map((image) => MapEntry(image.bytes, image)));
    for (final list in [
      generation.currentImages,
      generation.history,
      generation.displayImages,
      ref.read(canvasPinnedNotifierProvider.notifier).images,
    ]) {
      for (final image in list) {
        removedIds.remove(image.id);
        discarded.remove(image.bytes);
        discarded.remove(image.originalBytes);
        if (removedIds.isEmpty && discarded.isEmpty) return;
      }
    }
    if (removedIds.contains(state.selected) ||
        state.viewed.keys.any(removedIds.contains)) {
      _set(
        state.copyWith(
          clearSelected: removedIds.contains(state.selected),
          viewed: Map.of(state.viewed)
            ..removeWhere((id, _) => removedIds.contains(id)),
        ),
      );
    }

    final sources = <MemoryImage>{};
    final cache = PaintingBinding.instance.imageCache;
    for (final image in discarded.values) {
      final full = MemoryImage(image.bytes);
      sources.add(full);
      cache.evict(full, includeLive: false);
      // ResizeImage keys are opaque. The canvas only uses these power-of-two
      // widths below native resolution, backed by a synchronous MemoryImage key.
      for (
        var width = CanvasImageResidencyLimits.minimumWidth;
        width < image.width;
        width *= 2
      ) {
        final provider = canvasImageProvider(image, decodeWidth: width);
        unawaited(
          provider.obtainKey(ImageConfiguration.empty).then<void>((key) {
            cache.evict(key, includeLive: false);
          }),
        );
      }
    }
    if (sources.isNotEmpty && cache is AppImageCache) {
      cache.evictWhere(
        (key) => key is PreviewImageKey && sources.contains(key.source),
        includeLive: false,
      );
    }
  }

  /// A stream preview the next step of its image replaced is never shown
  /// again: its decodes (full size on the canvas tile and in the navigation
  /// tip, the history panel's cover) leave the image cache now instead of
  /// filling it until its limits push them out. While the window is hidden
  /// nothing else would let them go: [AppImageCache] counts every image put
  /// on screen in that time as in use until the window is back.
  void _releaseReplacedPreviews(
    List<StreamPreviewSlot>? previous,
    List<StreamPreviewSlot> next,
  ) {
    if (previous == null || _disposed) return;
    final now = {for (final slot in next) slot.imageNumber: slot.previewBytes};
    final replaced = [
      for (final slot in previous)
        if (slot.previewBytes case final bytes?
            when bytes.isNotEmpty &&
                now.containsKey(slot.imageNumber) &&
                !identical(now[slot.imageNumber], bytes))
          bytes,
    ];
    if (replaced.isEmpty) return;
    // Bytes a finished image shows keep their decode (a slot's last preview
    // is the finished image itself).
    final generation = ref.read(imageGenerationNotifierProvider);
    final shown = Set<Uint8List>.identity()
      ..addAll([
        for (final images in [
          generation.currentImages,
          generation.history,
          generation.displayImages,
        ])
          for (final image in images) image.bytes,
      ]);
    final cache = PaintingBinding.instance.imageCache;
    for (final bytes in replaced) {
      if (shown.contains(bytes)) continue;
      final full = MemoryImage(bytes);
      cache.evict(full, includeLive: false);
      if (cache is AppImageCache) {
        cache.evictWhere(
          (key) => key is PreviewImageKey && key.source == full,
          includeLive: false,
        );
      }
    }
  }

  static String _recentKey(ImageGenerationState state) =>
      _recentIds(state).join('\n');

  /// The newest images on the canvas: the current batch, then history from
  /// newest to oldest, then images shown only in the centre.
  static Set<String> _recentIds(ImageGenerationState state) {
    final ids = <String>{};
    for (final images in [
      state.currentImages,
      state.history,
      state.displayImages,
    ]) {
      for (final image in images) {
        ids.add(image.id);
        if (ids.length == CanvasImageResidencyLimits.recent) return ids;
      }
    }
    return ids;
  }
}

/// The width to decode a canvas tile at, or null for its full resolution.
///
/// [tileRect] is the tile in world coordinates (native image pixels);
/// [camera] maps the world to the screen. A tile in view decodes at the
/// physical size it is shown with [CanvasImageResidencyLimits.filterHeadroom]
/// (rounded up to a power of two); one outside it at most
/// [CanvasImageResidencyLimits.offscreenWidth]. A size reaching the image's
/// own width means full resolution.
int? canvasTileDecodeWidth({
  required Rect tileRect,
  required int nativeWidth,
  required CanvasCamera camera,
  required Size? viewport,
  required double devicePixelRatio,
}) {
  if (nativeWidth <= 0 || camera.scale <= 0 || tileRect.width <= 0) {
    return null;
  }
  var inView = true;
  if (viewport != null && !viewport.isEmpty) {
    final view = camera.visibleWorldRect(viewport);
    final mx = view.width * CanvasImageResidencyLimits.visibleMargin;
    final my = view.height * CanvasImageResidencyLimits.visibleMargin;
    inView = Rect.fromLTRB(
      view.left - mx,
      view.top - my,
      view.right + mx,
      view.bottom + my,
    ).overlaps(tileRect);
  }
  var wanted =
      tileRect.width *
      camera.scale *
      devicePixelRatio *
      CanvasImageResidencyLimits.filterHeadroom;
  if (!inView) {
    wanted = math.min(
      wanted,
      CanvasImageResidencyLimits.offscreenWidth.toDouble(),
    );
  }
  var width = CanvasImageResidencyLimits.minimumWidth;
  while (width < wanted) {
    width *= 2;
  }
  return width >= nativeWidth ? null : width;
}

/// A canvas image at full resolution, or decoded [decodeWidth] wide. Same
/// keys for the same bytes and width, so tiles share decodes.
ImageProvider canvasImageProvider(GeneratedImage image, {int? decodeWidth}) {
  final full = MemoryImage(image.bytes);
  return decodeWidth == null
      ? full
      : ResizeImage(
          full,
          width: decodeWidth,
          policy: ResizeImagePolicy.fit,
          allowUpscaling: false,
        );
}
