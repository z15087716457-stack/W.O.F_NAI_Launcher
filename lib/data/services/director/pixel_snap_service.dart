/// Pixel Snap — a standalone local reimplementation of the NovelAI director
/// tool of the same name. It snaps AI-generated pixel-art-style images back
/// onto their underlying pixel grid, with optional palette quantisation and
/// nearest-neighbour upscale to (approximately) the input resolution.
///
/// This is an independently expressed Dart port of the official web-worker
/// algorithm; no original JavaScript/WASM is bundled or executed. The heavy
/// pipeline lives in `pixel_snap_core.dart`, whose header documents the
/// numeric-semantics decisions that govern parity with the official tool.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

part 'pixel_snap_core.dart';

/// Palette handling, mirroring the official tool's "Palettize" control.
enum PixelSnapPaletteMode {
  /// Keep the per-cell median colours exactly as sampled.
  off,

  /// Octree quantisation (capacity 256) followed by Lab-space pairwise merging
  /// while the smallest weighted distance stays within the official
  /// tolerance (autoTol 6.5).
  auto,

  /// Same quantiser, but merging down to at most [PixelSnapOptions.colors]
  /// colours (officially a 16–256 slider, default 64).
  custom,
}

/// Options for [PixelSnapService.snap] / [PixelSnapService.snapSync].
///
/// Every field mirrors one official UI control; all other official worker
/// parameters are fixed constants (see `_k*` in `pixel_snap_core.dart`):
/// merge 20, lambda 1.2, margin 0.27, rigid false, paletteMethod "tree",
/// autoTol 6.5 and automatic pitch detection (px = py = 0).
class PixelSnapOptions {
  const PixelSnapOptions({
    this.paletteMode = PixelSnapPaletteMode.auto,
    this.colors = 64,
    this.avoidOverRefining = false,
    this.upscale = false,
  });

  /// Palette quantisation mode. Defaults to [PixelSnapPaletteMode.auto],
  /// matching the official UI.
  final PixelSnapPaletteMode paletteMode;

  /// Target palette size used by [PixelSnapPaletteMode.custom]
  /// (official slider range 16–256, default 64). Ignored otherwise.
  final int colors;

  /// Mirrors the official "Avoid Over-Refining" toggle. When true, the
  /// pitch/2 and pitch/3 sub-harmonic refinement candidates are skipped
  /// (`maxDetail: null`); when false they may replace the coarse pitch if
  /// their grid MAE improves by more than 20 % (`maxDetail: 0.2`).
  final bool avoidOverRefining;

  /// Mirrors the official "Upscale" toggle. When true, the snapped grid is
  /// nearest-neighbour-upscaled by `round((W/Wc + H/Hc) / 2)`; when false the
  /// output stays at the snapped cell resolution.
  final bool upscale;

  @override
  bool operator ==(Object other) =>
      other is PixelSnapOptions &&
      other.paletteMode == paletteMode &&
      other.colors == colors &&
      other.avoidOverRefining == avoidOverRefining &&
      other.upscale == upscale;

  @override
  int get hashCode =>
      Object.hash(paletteMode, colors, avoidOverRefining, upscale);

  @override
  String toString() =>
      'PixelSnapOptions(paletteMode: $paletteMode, '
      'colors: $colors, avoidOverRefining: $avoidOverRefining, '
      'upscale: $upscale)';
}

/// Stateless entry points for the Pixel Snap algorithm.
///
/// Both methods take encoded image bytes (PNG or any format decodable by
/// `package:image`) and return PNG bytes.
///
/// Errors are controlled and deterministic:
///  * [FormatException] — undecodable input, a fully transparent image, or an
///    image in which no repeating pixel grid could be detected;
///  * [ArgumentError] — input dimensions exceeding the memory bounds.
class PixelSnapService {
  PixelSnapService._();

  /// Runs the algorithm on a background isolate via Flutter `compute`.
  static Future<Uint8List> snap(
    Uint8List source, {
    PixelSnapOptions options = const PixelSnapOptions(),
  }) => compute(_pixelSnapEntry, (source, options), debugLabel: 'pixel-snap');

  /// Synchronous variant of [snap], intended for tests and isolate-internal
  /// use. Produces byte-identical output to [snap].
  static Uint8List snapSync(
    Uint8List source, {
    PixelSnapOptions options = const PixelSnapOptions(),
  }) => _pixelSnapRun(source, options);
}
