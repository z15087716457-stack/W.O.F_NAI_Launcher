part of 'pixel_snap_service.dart';

// =============================================================================
// Pixel Snap core — independently expressed Dart port of the official worker.
//
// Pipeline (same stage order and numeric semantics as the original):
//   decode RGBA (transparent pixels contribute RGB 0, fully transparent input
//   is rejected) → optional point-sample downscale above the 4 MP backend
//   budget → column/row edge-energy spectra → 6-channel u32 integral image
//   → pitch candidates via phase-binned autocorrelation (3–24 px scan)
//   → coarse ±3.5 % pitch/phase fit → fine ±4 % × 33-step × 16-phase fit with
//   optional pitch/2, pitch/3 sub-harmonics → DP grid-line alignment
//   → per-cell RGB / alpha medians with a 27 % margin → optional octree + Lab
//   palette → optional integer nearest-neighbour upscale → PNG encode.
//
// Numeric parity notes (verified against the worker source, which governs
// wherever the archived markdown disagrees):
//  * `p()` is round-half-EVEN (banker's rounding), not Dart `round()`
//    (half-away). `_roundHalfEven` reproduces it; it is used for every grid
//    index, segment bound and output quantisation.
//  * The reference spread backend computes in float32 with `Math.fround` at
//    every accumulation step (the WebGL/WASM backends do the same in f32).
//    `_f32` reproduces that rounding so near-tie comparisons behave the same.
//    Note: `1e18` stored into a Float32List becomes 999999984306749440, so the
//    original's `>= 1e18` invalid-score guards never actually fire — that is
//    reproduced here verbatim.
//  * The integral image uses unsigned 32-bit wrap-around (`>>>0`). Dart ints
//    are 64-bit, so `& 0xFFFFFFFF` reproduces it; every rectangle queried is a
//    small grid cell whose sums stay far below 2^32, so recovered values are
//    exact.
//  * Summation order is load-bearing: `_fsum` keeps the original 8-way
//    unrolling and parenthesisation, `_spread` keeps the outer-major pair
//    iteration (only skipping unselected intervals, which is value-neutral).
//  * `Math.cbrt` is approximated by `pow(x, 1/3)` plus two Newton refinement
//    steps (Dart has no cbrt); this is the only known <1-ulp-class deviation.
// =============================================================================

/// Fixed constants the official tool never exposes in its UI.
const double _kLambda = 1.2; // lam — DP segment-length penalty weight
const double _kMargin = 0.27; // margin — cell-edge discard when sampling
const double _kAutoTol = 6.5; // autoTol — Lab merge tolerance in auto mode
const double _kMaxDetail = 0.2; // maxDetail when over-refining is allowed
const double _kMinPitch = 3.0;
const double _kMaxPitch = 24.0;
const int _kMaxPixels = 4000000; // backend pixel budget (JS/WASM cap)
const int _kMaxInputPixels = 67108864; // hard input bound (64 MP)
const int _kMaxInputSide = 16384;

// Deliberately non-const so the branches below stay live code: the official
// UI always runs with px = py = 0 (auto pitch) and rigid = false (DP grid).
// The manual-pitch and rigid-grid paths are ported for completeness.
// ignore: prefer_const_declarations
final double _kPx = 0;
// ignore: prefer_const_declarations
final double _kPy = 0;
// ignore: prefer_const_declarations
final bool _kRigid = false;

/// Isolate entry for [PixelSnapService.snap]; must stay a top-level function.
Uint8List _pixelSnapEntry((Uint8List, PixelSnapOptions) job) =>
    _pixelSnapRun(job.$1, job.$2);

// ---------------------------------------------------------------------------
// Small numeric helpers
// ---------------------------------------------------------------------------

final Float32List _f32box = Float32List(1);

/// `Math.fround` — round a double to the nearest float32 value.
double _f32(double v) {
  _f32box[0] = v;
  return _f32box[0];
}

/// `p(e)` — round-half-even (banker's rounding). Not Dart's `round()`.
int _roundHalfEven(double e) {
  final t = e.floor();
  final r = e - t;
  if (r < .5) return t;
  if (r > .5) return t + 1;
  return t.isEven ? t : t + 1;
}

/// `w(e,t)` — positive modulo built on the truncated JS remainder (Dart's `%`
/// on doubles is already floor-mod; `remainder` matches JS `x % y` exactly).
double _pmod(double e, double t) {
  final r = e.remainder(t);
  return r < 0 ? r + t : r;
}

/// `b(e,t,r)` — r evenly spaced values from e to t, last element pinned to t.
Float64List _linspace(double e, double t, int r) {
  final n = Float64List(r);
  if (r == 1) {
    n[0] = e;
    return n;
  }
  final a = (t - e) / (r - 1);
  for (var i = 0; i < r; i++) {
    n[i] = i * a + e;
  }
  n[r - 1] = t;
  return n;
}

/// `y(e,t)` — percentile (0–100) with linear interpolation between ranks.
double _percentile(List<double> e, double t) {
  final r = Float64List.fromList(e)..sort();
  final n = r.length;
  if (n == 0) return double.nan;
  if (n == 1) return r[0];
  final a = t / 100 * (n - 1);
  final l = a.floor(), o = a.ceil();
  return r[l] + (r[o] - r[l]) * (a - l);
}

/// `A(e,t,r)` — sum of `e[t .. t+r)`. The 8-way unrolling and the exact
/// parenthesisation of the final combine are load-bearing for parity.
double _fsum(Float64List e, int t, int r) {
  if (r < 8) {
    var n = 0.0;
    for (var a = 0; a < r; a++) {
      n += e[t + a];
    }
    return n;
  }
  if (r <= 128) {
    var a = e[t],
        l = e[t + 1],
        o = e[t + 2],
        i = e[t + 3],
        u = e[t + 4],
        s = e[t + 5],
        f = e[t + 6],
        c = e[t + 7];
    var n = 8;
    for (; n < r - r % 8; n += 8) {
      a += e[t + n];
      l += e[t + n + 1];
      o += e[t + n + 2];
      i += e[t + n + 3];
      u += e[t + n + 4];
      s += e[t + n + 5];
      f += e[t + n + 6];
      c += e[t + n + 7];
    }
    var h = a + l + (o + i) + (u + s + (f + c));
    for (; n < r; n++) {
      h += e[t + n];
    }
    return h;
  }
  var n = r ~/ 2;
  n -= n % 8;
  return _fsum(e, t, n) + _fsum(e, t + n, r - n);
}

/// `R(e)` — the phase set `[0, 1/e, ..., (e-1)/e]`.
Float64List _phaseSet(int e) {
  final t = Float64List(e);
  for (var i = 0; i < e; i++) {
    t[i] = i / e;
  }
  return t;
}

/// `T(e,t,r)` — index of the first strict minimum in `e[t .. t+r)`.
int _argmin(List<double> e, int t, int r) {
  var n = 0;
  var a = e[t];
  for (var l = 1; l < r; l++) {
    final v = e[t + l];
    if (v < a) {
      a = v;
      n = l;
    }
  }
  return n;
}

/// `w` inside `B` — median of the first `t` entries (sorted copy; the two
/// middle values are averaged for even counts).
double _median(Float64List e, int t) {
  final r = e.sublist(0, t)..sort();
  final n = t >> 1;
  return t.isOdd ? r[n] : (r[n - 1] + r[n]) / 2;
}

/// Approximation of `Math.cbrt` for x > 0: pow estimate + Newton refinement.
double _cbrt(double x) {
  if (x <= 0 || !x.isFinite) return x <= 0 ? 0.0 : x;
  var y = math.pow(x, 1 / 3).toDouble();
  y = (x / (y * y) + 2 * y) / 3;
  y = (x / (y * y) + 2 * y) / 3;
  return y;
}

// ---------------------------------------------------------------------------
// Decode / bounds / downscale
// ---------------------------------------------------------------------------

/// Reads the PNG IHDR dimensions without decoding, to bound memory early.
(int, int)? _pngSize(Uint8List b) {
  if (b.length < 24 ||
      b[0] != 0x89 ||
      b[1] != 0x50 ||
      b[2] != 0x4E ||
      b[3] != 0x47 ||
      b[12] != 0x49 ||
      b[13] != 0x48 ||
      b[14] != 0x44 ||
      b[15] != 0x52) {
    return null;
  }
  final bd = ByteData.sublistView(b);
  return (bd.getUint32(16), bd.getUint32(20));
}

void _checkBounds(int w, int h) {
  if (w <= 0 || h <= 0) {
    throw const FormatException('pixel-snap: image has zero dimensions');
  }
  if (w > _kMaxInputSide || h > _kMaxInputSide || w * h > _kMaxInputPixels) {
    throw ArgumentError(
      'pixel-snap: image ${w}x$h exceeds the input bound '
      '(max $_kMaxInputSide px per side, $_kMaxInputPixels px total)',
    );
  }
}

/// `X` — decode to an RGB double plane plus an alpha mask. Fully transparent
/// input is rejected; transparent pixels keep RGB 0 (matching the original,
/// where their bytes are simply never written).
({Float64List rgb, Uint8List? alpha, int w, int h}) _decodeRgba(
  Uint8List bytes,
) {
  final sniffed = _pngSize(bytes);
  if (sniffed != null) _checkBounds(sniffed.$1, sniffed.$2);
  final raw = img.decodeImage(bytes);
  if (raw == null) {
    throw const FormatException('pixel-snap: input is not a decodable image');
  }
  _checkBounds(raw.width, raw.height);
  final im = raw.numChannels == 4 && raw.format == img.Format.uint8
      ? raw
      : raw.convert(format: img.Format.uint8, numChannels: 4);
  final w = im.width, h = im.height;
  final rgb = Float64List(w * h * 3);
  final alpha = Uint8List(w * h);
  var hasAlpha = false, allTransparent = true;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = im.getPixel(x, y);
      final e = y * w + x;
      final a = p.a.toInt();
      alpha[e] = a;
      if (a < 255) hasAlpha = true;
      if (a != 0) {
        allTransparent = false;
        rgb[3 * e] = p.r.toDouble();
        rgb[3 * e + 1] = p.g.toDouble();
        rgb[3 * e + 2] = p.b.toDouble();
      }
    }
  }
  if (allTransparent) {
    throw const FormatException(
      'pixel-snap: image decoded blank (fully transparent)',
    );
  }
  return (rgb: rgb, alpha: hasAlpha ? alpha : null, w: w, h: h);
}

/// `$` — point-sampled (nearest) downscale applied when the image exceeds the
/// backend pixel budget. Not a box filter: it picks single source pixels.
Float64List _pointDownscale3(Float64List e, int sh, int sw, int nw, int nh) {
  final o = Float64List(nw * nh * 3);
  for (var i = 0; i < nh; i++) {
    final u = math.min(sh - 1, (i * sh / nh).truncate());
    for (var j = 0; j < nw; j++) {
      final a = math.min(sw - 1, (j * sw / nw).truncate());
      final s = (u * sw + a) * 3, f = (i * nw + j) * 3;
      o[f] = e[s];
      o[f + 1] = e[s + 1];
      o[f + 2] = e[s + 2];
    }
  }
  return o;
}

Uint8List _pointDownscale1(Uint8List e, int sh, int sw, int nw, int nh) {
  final o = Uint8List(nw * nh);
  for (var i = 0; i < nh; i++) {
    final u = math.min(sh - 1, (i * sh / nh).truncate());
    for (var j = 0; j < nw; j++) {
      final a = math.min(sw - 1, (j * sw / nw).truncate());
      o[i * nw + j] = e[u * sw + a];
    }
  }
  return o;
}

// ---------------------------------------------------------------------------
// Step 1 — edge-energy spectra and the summed-area table
// ---------------------------------------------------------------------------

/// `N` inline helper — column spectrum (|ΔRGB| between horizontally adjacent
/// pixels, summed over rows) and row spectrum (vertical adjacency).
(Float64List, Float64List) _diffSpectra(Float64List rgb, int h, int w) {
  final col = Float64List(w - 1);
  final row = Float64List(h - 1);
  for (var y = 0; y < h; y++) {
    final base = y * w * 3;
    for (var x = 0; x < w - 1; x++) {
      final a = base + 3 * x, b = a + 3;
      col[x] +=
          (rgb[b] - rgb[a]).abs() +
          (rgb[b + 1] - rgb[a + 1]).abs() +
          (rgb[b + 2] - rgb[a + 2]).abs();
    }
  }
  for (var y = 0; y < h - 1; y++) {
    final cur = y * w * 3, nxt = cur + 3 * w;
    var o = 0.0;
    for (var x = 0; x < w; x++) {
      final a = cur + 3 * x, b = nxt + 3 * x;
      o +=
          (rgb[b] - rgb[a]).abs() +
          (rgb[b + 1] - rgb[a + 1]).abs() +
          (rgb[b + 2] - rgb[a + 2]).abs();
    }
    row[y] = o;
  }
  return (col, row);
}

/// `k` inside `N` — 6-channel (R,G,B,R²,G²,B²) summed-area table with
/// unsigned 32-bit wrap-around (`>>>0`).
Uint32List _integralImage(Float64List rgb, int h, int w) {
  final stride = w + 1;
  final sat = Uint32List((h + 1) * stride * 6);
  for (var y = 1; y <= h; y++) {
    final prev = (y - 1) * stride, cur = y * stride;
    for (var x = 1; x <= w; x++) {
      final i = ((y - 1) * w + (x - 1)) * 3;
      final r = rgb[i].toInt(), g = rgb[i + 1].toInt(), b = rgb[i + 2].toInt();
      final c = (cur + x) * 6,
          up = (prev + x) * 6,
          lf = (cur + x - 1) * 6,
          ul = (prev + x - 1) * 6;
      sat[c] = (r + sat[up] + sat[lf] - sat[ul]) & 0xFFFFFFFF;
      sat[c + 1] = (g + sat[up + 1] + sat[lf + 1] - sat[ul + 1]) & 0xFFFFFFFF;
      sat[c + 2] = (b + sat[up + 2] + sat[lf + 2] - sat[ul + 2]) & 0xFFFFFFFF;
      sat[c + 3] =
          (r * r + sat[up + 3] + sat[lf + 3] - sat[ul + 3]) & 0xFFFFFFFF;
      sat[c + 4] =
          (g * g + sat[up + 4] + sat[lf + 4] - sat[ul + 4]) & 0xFFFFFFFF;
      sat[c + 5] =
          (b * b + sat[up + 5] + sat[lf + 5] - sat[ul + 5]) & 0xFFFFFFFF;
    }
  }
  return sat;
}

// ---------------------------------------------------------------------------
// Step 2 — spread engine (port of the JS backend `a()`; the GPU/WASM backends
// compute the same value in f32) over cell/band interval sets
// ---------------------------------------------------------------------------

class _Intervals {
  _Intervals(this.a, this.z, this.sel, this.b, this.p, this.k);

  /// Per-interval start (inclusive) and end (exclusive) coordinates.
  final Int32List a, z;

  /// Whether the interval is a fully in-range, stride-selected cell.
  final Uint8List sel;

  /// Pitches (B), phases per pitch (P), intervals per (pitch, phase) (K).
  final int b, p, k;
}

/// `v(e,t,r,n,a)` — builds, for every pitch × phase, the list of inner cell
/// intervals between grid lines at `phase*pitch - pitch + k*pitch`, shrunk by
/// `max(1, .27*pitch)` on each side. `a` is the cell subsampling stride: only
/// every a-th fully in-range cell is marked in `sel`.
_Intervals _buildInner(
  double e,
  double t,
  Float64List r,
  List<List<double>> n,
  int a,
) {
  final l = r.length, o = n[0].length;
  var lo = double.infinity;
  for (final v in r) {
    if (v < lo) lo = v;
  }
  final u = ((t - e) / lo).ceil() + 3;
  final loA = Int32List(l * o * u),
      hiA = Int32List(l * o * u),
      sel = Uint8List(l * o * u);
  for (var i = 0; i < l; i++) {
    final pitch = r[i];
    final shrink = math.max(1.0, .27 * pitch);
    for (var j = 0; j < o; j++) {
      final d = e + _pmod(n[i][j], 1) * pitch - pitch;
      var g = -1;
      final base = (i * o + j) * u;
      for (var q = 0; q < u; q++) {
        final pos = d + q * pitch;
        final inside = pos >= e - 1e-9 && pos + pitch <= t + 1e-9;
        var i0 = (pos + shrink).floor(), u0 = (pos + pitch - shrink).ceil();
        if (u0 - i0 < 2) {
          final mid = (pos + pitch / 2).floor();
          i0 = mid - 1;
          u0 = mid + 1;
        }
        loA[base + q] = i0;
        hiA[base + q] = u0;
        var s = 0;
        if (inside) {
          g += 1;
          if (g % a == 0) s = 1;
        }
        sel[base + q] = s;
      }
    }
  }
  return _Intervals(loA, hiA, sel, l, o, u);
}

/// `F(e,t,r,n,a)` — same builder but with one phase per pitch (a flat list).
_Intervals _buildOuter(
  double e,
  double t,
  Float64List r,
  List<double> n,
  int a,
) => _buildInner(e, t, r, [
  for (final p in n) [p],
], a);

/// `a()` of the JS backend — mean per-channel population standard deviation
/// inside each (inner cell × outer band) rectangle, averaged over all
/// selected pairs. float32 arithmetic reproduces `Math.fround` at each step.
///
/// Only selected intervals are iterated; this is value-neutral versus the
/// original (skipped `sel == 0` entries contribute nothing) but much faster.
Float32List _spread(
  _Intervals inner,
  _Intervals outer,
  Uint32List sat,
  int w1,
  bool innerIsCol,
) {
  final l = inner.a, z = inner.z, i = inner.sel;
  final u = inner.b, s = inner.p, c = inner.k;
  final h = outer.a, d = outer.z, g = outer.sel, m = outer.k;
  final p = Float32List(u * s);
  for (var t = 0; t < u; t++) {
    final rr = t * m;
    final selOuter = <int>[];
    for (var q = 0; q < m; q++) {
      if (g[rr + q] != 0) selOuter.add(q);
    }
    for (var w = 0; w < s; w++) {
      final b = (t * s + w) * c;
      final selInner = <int>[];
      for (var q = 0; q < c; q++) {
        if (i[b + q] != 0) selInner.add(q);
      }
      if (selInner.length < 3 || selOuter.length < 3) {
        p[t * s + w] = 1e18;
        continue;
      }
      var acc = 0.0;
      for (final q in selOuter) {
        final ou = h[rr + q], oz = d[rr + q];
        for (final q2 in selInner) {
          final iu = l[b + q2], iz = z[b + q2];
          final int r0, r1, c0, c1;
          if (innerIsCol) {
            r0 = ou;
            r1 = oz;
            c0 = iu;
            c1 = iz;
          } else {
            r0 = iu;
            r1 = iz;
            c0 = ou;
            c1 = oz;
          }
          final n = (r1 - r0) * (c1 - c0);
          final o11 = (r1 * w1 + c1) * 6,
              o10 = (r0 * w1 + c1) * 6,
              o01 = (r1 * w1 + c0) * 6,
              o00 = (r0 * w1 + c0) * 6;
          // Sub-pixel refinement can produce an edge interval outside the
          // SAT. JS reads undefined there: the sum becomes NaN, then >>> 0
          // yields zero. Keep its zero contribution and original divisor.
          if (o11 < 0 ||
              o10 < 0 ||
              o01 < 0 ||
              o00 < 0 ||
              o11 + 5 >= sat.length ||
              o10 + 5 >= sat.length ||
              o01 + 5 >= sat.length ||
              o00 + 5 >= sat.length) {
            continue;
          }
          var sd = 0.0;
          for (var ch = 0; ch < 3; ch++) {
            final s1 =
                (sat[o11 + ch] -
                    sat[o10 + ch] -
                    sat[o01 + ch] +
                    sat[o00 + ch]) &
                0xFFFFFFFF;
            final s2 =
                (sat[o11 + ch + 3] -
                    sat[o10 + ch + 3] -
                    sat[o01 + ch + 3] +
                    sat[o00 + ch + 3]) &
                0xFFFFFFFF;
            var vn = n * s2 - s1 * s1;
            if (vn < 0) vn = 0;
            sd = _f32(
              sd +
                  _f32(
                    _f32(math.sqrt(_f32(vn.toDouble()))) / _f32(n.toDouble()),
                  ),
            );
          }
          acc = _f32(acc + _f32(sd / 3));
        }
      }
      p[t * s + w] = _f32(
        acc /
            _f32(
              _f32(selOuter.length.toDouble()) *
                  _f32(selInner.length.toDouble()),
            ),
      );
    }
  }
  return p;
}

// ---------------------------------------------------------------------------
// Step 3 — phase detection (C) and manual-pitch variant (G)
// ---------------------------------------------------------------------------

/// `C(e,t,r,n,a,l)` — for each pitch in `t`, the best phase among `a`
/// evenly spaced phases, independently on x (via spreadRows) and y
/// (via spreadCols). Returns (xPhases, yPhases) as fractions in [0, 1).
(Float64List, Float64List) _phaseDetect(
  Float64List pitches,
  int w,
  int h,
  Uint32List sat,
  int phases,
  int stride,
) {
  final o = pitches.length;
  final set = _phaseSet(phases);
  final groups = List<List<double>>.filled(o, set);
  final rowBands = _buildOuter(
    0,
    h.toDouble(),
    pitches,
    List<double>.filled(o, .37),
    stride,
  );
  final colCells = _buildInner(0, w.toDouble(), pitches, groups, stride);
  final rowSpread = _spread(colCells, rowBands, sat, w + 1, true);
  final xPh = Float64List(o);
  for (var e = 0; e < o; e++) {
    xPh[e] = set[_argmin(rowSpread, e * phases, phases)];
  }
  final colBands = _buildOuter(0, w.toDouble(), pitches, xPh, stride);
  final rowCells = _buildInner(0, h.toDouble(), pitches, groups, stride);
  final colSpread = _spread(rowCells, colBands, sat, w + 1, false);
  final yPh = Float64List(o);
  for (var e = 0; e < o; e++) {
    yPh[e] = set[_argmin(colSpread, e * phases, phases)];
  }
  return (xPh, yPh);
}

/// `G` — phase detection when the pitch is known on both axes. Unused under
/// the fixed defaults (px = py = 0), ported for parity completeness.
(double, double) _manualPhases(
  double px,
  double py,
  int w,
  int h,
  Uint32List sat,
  int phases, {
  int stride = 1,
}) {
  final set = _phaseSet(phases);
  final rs = _spread(
    _buildInner(0, w.toDouble(), Float64List.fromList([px]), [set], stride),
    _buildOuter(0, h.toDouble(), Float64List.fromList([py]), const [
      .37,
    ], stride),
    sat,
    w + 1,
    true,
  );
  final sx = set[_argmin(rs, 0, phases)];
  final cs = _spread(
    _buildInner(0, h.toDouble(), Float64List.fromList([py]), [set], stride),
    _buildOuter(0, w.toDouble(), Float64List.fromList([px]), [sx], stride),
    sat,
    w + 1,
    false,
  );
  return (sx, set[_argmin(cs, 0, phases)]);
}

// ---------------------------------------------------------------------------
// Step 4 — pitch candidate extraction
// ---------------------------------------------------------------------------

/// Per-spectrum clamp: values above 2 % of the max are winsorised at the
/// 60th percentile of the kept values (or the max when none qualify).
Float64List _truncateSpectrum(Float64List e) {
  var t = -double.infinity;
  for (final r in e) {
    if (r > t) t = r;
  }
  final r = .02 * t + 1e-12;
  final above = <double>[];
  for (final v in e) {
    if (v > r) above.add(v);
  }
  final cap = above.isNotEmpty ? _percentile(above, 60) : t;
  final out = Float64List(e.length);
  for (var i = 0; i < e.length; i++) {
    out[i] = math.min(e[i], cap);
  }
  return out;
}

/// Fractional pitch scan positions — 3.00, 3.02, … below `t` in steps of `r`.
/// The peculiar `l = e + r - e` step is reproduced verbatim (it can differ
/// from `r` by 1 ulp).
Float64List _scanPositions(double e, double t, double r) {
  final n = math.max(0, ((t - e) / r).ceil());
  final a = Float64List(n);
  if (n > 0) a[0] = e;
  if (n > 1) a[1] = e + r;
  final l = e + r - e;
  for (var i = 2; i < n; i++) {
    a[i] = e + i * l;
  }
  return a;
}

/// Phase-binned autocorrelation score for spectrum `e` at (fractional)
/// period `t`: energy is folded into `max(8, round(t/.25))` phase bins over
/// windows of `trunc(max(80, 14t))` samples; the score is the energy-weighted
/// mean of the best `u`-bin window share normalised by its coverage.
double _autoScore(Float64List e, double t, {double r = .7, double n = 14}) {
  final a = e.length;
  final l = math.max(80, n * t).truncate();
  final o = math.max(8, _roundHalfEven(t / .25));
  final i = t / o;
  final u = math.max(1, _roundHalfEven(r / i));
  final s = ((a - 1) / l).floor() + 1;
  final f = Float64List(s * o);
  for (var q = 0; q < a; q++) {
    final n2 = q + 1;
    final a2 = q ~/ l;
    var u2 = (_pmod(n2.toDouble(), t) / i).floor();
    if (u2 > o - 1) u2 = o - 1;
    f[a2 * o + u2] += e[q];
  }
  final c = o + u;
  final h = Float64List(c + 1);
  final d = u * i / t;
  final g = Float64List(s), m = Float64List(s);
  var b = 0;
  for (var e2 = 0; e2 < s; e2++) {
    final t2 = e2 * o;
    final r2 = _fsum(f, t2, o);
    if (r2 <= 1e-9) continue;
    h[0] = 0;
    for (var e3 = 0; e3 < c; e3++) {
      h[e3 + 1] = h[e3] + f[t2 + (e3 < o ? e3 : e3 - o)];
    }
    var n3 = -double.infinity;
    for (var e3 = 0; e3 < o; e3++) {
      final t3 = h[e3 + u] - h[e3];
      if (t3 > n3) n3 = t3;
    }
    g[b] = n3 / r2 / d;
    m[b] = r2;
    b++;
  }
  if (b == 0) return 0;
  final y = Float64List(b);
  for (var e2 = 0; e2 < b; e2++) {
    y[e2] = g[e2] * m[e2];
  }
  return _fsum(y, 0, b) / _fsum(m, 0, b);
}

/// Pitch candidates from both axis spectra: local maxima of the
/// autocorrelation score (±15 bins, threshold > 1.12), top 8 per axis, then
/// harmonic expansion (÷1, ÷2, … while >= `_kMinPitch`, dedupe within .12).
Float64List _detectPitches(List<Float64List> spectra) {
  final found = <double>[];
  for (final spec in spectra) {
    final e = _truncateSpectrum(spec);
    final positions = _scanPositions(_kMinPitch, _kMaxPitch, .02);
    final scores = Float64List(positions.length);
    for (var i = 0; i < positions.length; i++) {
      scores[i] = _autoScore(e, positions[i]);
    }
    final peaks = <List<double>>[];
    for (var i = 0; i < positions.length; i++) {
      var best = -double.infinity;
      final lo = math.max(0, i - 15), hi = math.min(positions.length, i + 16);
      for (var j = lo; j < hi; j++) {
        if (scores[j] > best) best = scores[j];
      }
      if (scores[i] >= best && scores[i] > 1.12) {
        peaks.add([scores[i], positions[i]]);
      }
    }
    peaks.sort((a, b) {
      final c = b[0].compareTo(a[0]);
      return c != 0 ? c : b[1].compareTo(a[1]);
    });
    for (final p in peaks.take(8)) {
      found.add(p[1]);
    }
  }
  found.sort();
  final expanded = <double>[];
  for (final pitch in found) {
    var div = 1;
    while (pitch / div >= _kMinPitch - 1e-9) {
      final sub = pitch / div;
      if (expanded.every((e) => (sub - e).abs() > .12)) expanded.add(sub);
      div++;
    }
  }
  expanded.sort();
  return Float64List.fromList(expanded);
}

// ---------------------------------------------------------------------------
// Step 5 — pitch scoring passes (L) and coarse selection (W)
// ---------------------------------------------------------------------------

/// `L` — grid-fit score for each candidate pitch: `steps` pitch variants in
/// ±3.5 %, `phases` phases (via [_phaseDetect]), optional ±0.04 phase jitter.
/// Returns one `[score, pitch, phaseX, phaseY]` entry per input pitch.
List<List<double>> _fitPitches(
  Float64List pitches,
  int w,
  int h,
  Uint32List sat,
  int steps,
  int phases,
  int stride,
  bool jitter,
) {
  final u = pitches.length;
  final s = Float64List(u * steps);
  for (var e = 0; e < u; e++) {
    s.setRange(
      e * steps,
      e * steps + steps,
      _linspace(.965 * pitches[e], 1.035 * pitches[e], steps),
    );
  }
  final ph = _phaseDetect(s, w, h, sat, phases, stride);
  final jit = jitter ? const [-.04, 0.0, .04] : const [0.0];
  final d = jit.length, g = u * steps * d;
  final m = Float64List(g), p = Float64List(g);
  final wg = List<List<double>>.generate(g, (_) => Float64List(d));
  for (var e = 0; e < g; e++) {
    final t = e ~/ d;
    m[e] = s[t];
    p[e] = ph.$2[t] + jit[e % d];
    final wl = wg[e];
    for (var j = 0; j < d; j++) {
      wl[j] = ph.$1[t] + jit[j];
    }
  }
  final y = _spread(
    _buildInner(0, w.toDouble(), m, wg, stride),
    _buildOuter(0, h.toDouble(), m, p, stride),
    sat,
    w + 1,
    true,
  );
  final perPitch = steps * d * d;
  final out = <List<double>>[];
  for (var e = 0; e < u; e++) {
    final base = e * perPitch;
    var ai = 0;
    var av = y[base];
    for (var j = 1; j < perPitch; j++) {
      final v = y[base + j];
      if (v < av) {
        av = v;
        ai = j;
      }
    }
    if (av >= 1e18) {
      out.add([1e18, pitches[e], 0, 0]);
      continue;
    }
    final l2 = base + ai, o2 = l2 ~/ d, i2 = l2 % d, u2 = o2 ~/ d, g2 = o2 % d;
    out.add([av, s[u2], ph.$1[u2] + jit[i2], ph.$2[u2] + jit[g2]]);
  }
  return out;
}

/// `W` — two-stage coarse selection: keep candidates within
/// `1.35 * max(1.25*best, best + .5)` of the best coarse score (plus the top
/// four regardless, capped at 12), refine the survivors at finer resolution
/// (15 steps / 14 phases / jitter), then pick the largest pitch whose score
/// is within `max(1.25*best, best + .5)`. Returns `[score, pitch, phX, phY]`.
List<double> _coarseSelect(
  int w,
  int h,
  Float64List candidates,
  Uint32List sat,
) {
  final scores = _fitPitches(candidates, w, h, sat, 7, 10, 2, false);
  var best = double.infinity;
  for (final e in scores) {
    if (e[0] < best) best = e[0];
  }
  final thresh = 1.35 * math.max(1.25 * best, best + .5);
  final keep = <double>[];
  for (var e = 0; e < candidates.length; e++) {
    if (scores[e][0] <= thresh) keep.add(candidates[e]);
  }
  final order = List<int>.generate(candidates.length, (i) => i)
    ..sort((a, b) {
      final c = scores[a][0].compareTo(scores[b][0]);
      return c != 0 ? c : candidates[a].compareTo(candidates[b]);
    });
  final ranked = [for (final i in order) candidates[i]];
  for (final e in ranked.take(4)) {
    if (!keep.contains(e)) keep.add(e);
  }
  if (keep.length > 12) {
    final rank = {for (var i = 0; i < ranked.length; i++) ranked[i]: i};
    keep.sort((a, b) => rank[a]!.compareTo(rank[b]!));
    keep.removeRange(12, keep.length);
  }
  keep.sort();
  final refined = _fitPitches(
    Float64List.fromList(keep),
    w,
    h,
    sat,
    15,
    14,
    1,
    true,
  );
  var best2 = double.infinity;
  for (final e in refined) {
    if (e[0] < best2) best2 = e[0];
  }
  final thresh2 = math.max(1.25 * best2, best2 + .5);
  List<double>? sel;
  for (final e in refined) {
    if (e[0] <= thresh2 && (sel == null || e[1] > sel[1])) sel = e;
  }
  return sel!;
}

// ---------------------------------------------------------------------------
// Step 6 — fine refinement (k) with optional sub-harmonics (D)
// ---------------------------------------------------------------------------

/// `x` helper — Gaussian smoothing (σ fixed .8, kernel radius
/// `max(1, trunc(3σ))`, full convolution centre-cropped to input length).
Float64List _gaussSmooth(Float64List e, double sigma) {
  final r = math.max(1, (3 * sigma).truncate());
  final kernel = Float64List(2 * r + 1);
  var acc = 0.0;
  for (var k = -r, j = 0; k <= r; k++, j++) {
    final q = k / sigma;
    kernel[j] = math.exp(-.5 * q * q);
    acc += kernel[j];
  }
  for (var j = 0; j < kernel.length; j++) {
    kernel[j] /= acc;
  }
  final rl = e.length, kl = kernel.length;
  final conv = Float64List(rl + kl - 1);
  for (var o = 0; o < conv.length; o++) {
    var a = 0.0;
    final i0 = math.max(0, o - (rl - 1)), u0 = math.min(kl - 1, o);
    for (var k = i0; k <= u0; k++) {
      a += kernel[k] * e[o - k];
    }
    conv[o] = a;
  }
  final off = (kl - 1) >> 1;
  return conv.sublist(off, off + rl);
}

/// `x` — the "snap" proper: DP selection of grid-line positions along one
/// axis. Smoothed, percentile-clamped spectrum height rewards cuts; a
/// quadratic phase penalty keeps them near the expected period; each interior
/// segment pays `lambda * ((len - pitch) / pitch)²`.
List<int> _dpLines(Float64List spec, double t, double? phase) {
  const lam = _kLambda, a = .35, l = .6, o = .7, i = 1.35;
  final u = _gaussSmooth(spec, .8);
  final s = _percentile(u, 98) + 1e-9;
  for (var e = 0; e < u.length; e++) {
    u[e] = math.min(math.max(u[e] / s, 0), 1.5);
  }
  final c = spec.length + 1;
  final hh = Float64List(c + 1);
  for (var e = 1; e < c; e++) {
    hh[e] = u[e - 1];
  }
  hh[0] = l;
  hh[c] = l;
  if (phase != null) {
    for (var e = 0; e <= c; e++) {
      final r = _pmod(e - phase + t / 2, t) - t / 2;
      final q = r / (t / 2);
      hh[e] -= a * q * q;
    }
  }
  final d = math.max(2, _roundHalfEven(o * t));
  final g = math.max(d + 1, _roundHalfEven(i * t));
  final m = Float64List(c + 1)..fillRange(0, c + 1, -1e18);
  final back = Int32List(c + 1)..fillRange(0, c + 1, -1);
  final init = math.min(c, g);
  for (var e = 0; e <= init; e++) {
    m[e] = hh[e];
  }
  for (var e = d; e <= c; e++) {
    final lo = math.max(0, e - g), hi = e - d;
    var bestI = -1, best = -1e18;
    for (var j = lo; j <= hi; j++) {
      final n = e - j;
      final dq = (n - t) / t;
      final v = m[j] - lam * dq * dq + hh[e];
      if (v > best) {
        best = v;
        bestI = j;
      }
    }
    if (best > m[e]) {
      m[e] = best;
      back[e] = bestI;
    }
  }
  var end = math.max(0, c - g);
  var bestEnd = m[end];
  for (var e = end + 1; e <= c; e++) {
    if (m[e] > bestEnd) {
      bestEnd = m[e];
      end = e;
    }
  }
  var v = end;
  final rev = <int>[];
  while (v >= 0) {
    rev.add(v);
    v = back[v];
  }
  final f = rev.reversed.toList();
  if (f[0] != 0) f.insert(0, 0);
  if (f.last != c) f.add(c);
  while (f.length > 2 && f[1] - f[0] < 2) {
    f.removeAt(1);
  }
  while (f.length > 2 && f.last - f[f.length - 2] < 2) {
    f.removeAt(f.length - 2);
  }
  return f;
}

/// `M` — the rigid-grid alternative (unused under the fixed defaults,
/// rigid = false); ported so the decision space is complete.
List<int> _rigidLines(int e, double t, double r) {
  final ph = _pmod(r, t);
  final n = ((e - ph) / t).floor() + 2;
  final set = <int>{0, e};
  for (var l = 0; l < n; l++) {
    final v = _roundHalfEven(ph + l * t);
    if (v >= 0 && v <= e) set.add(v);
  }
  final list = set.toList()..sort();
  while (list.length > 2 && list[1] - list[0] < 2) {
    list.removeAt(1);
  }
  while (list.length > 2 && list.last - list[list.length - 2] < 2) {
    list.removeAt(list.length - 2);
  }
  return list;
}

/// `E` — per-axis line placement: DP (`x`) unless the rigid flag is set.
(List<int>, List<int>) _gridLines(
  Float64List cs,
  Float64List rs,
  int w,
  int h,
  double px,
  double py,
  double ox,
  double oy,
) => _kRigid
    ? (_rigidLines(w, px, ox), _rigidLines(h, py, oy))
    : (_dpLines(cs, px, ox), _dpLines(rs, py, oy));

/// `B` — sample each grid cell: drop `margin` (27 %) on every side, take the
/// per-channel median over pixels with alpha > 0, plus the alpha median over
/// all pixels when an alpha mask exists. Returns RGB cell colours (0 where a
/// cell is fully transparent, matching the original's unwritten buffer).
({Float64List cells, Float64List? alpha, int hc, int wc}) _sampleCells(
  Float64List rgb,
  List<int> xb,
  List<int> yb,
  int w,
  double margin,
  Uint8List? alpha,
) {
  final o = yb.length - 1, i = xb.length - 1;
  final cells = Float64List(o * i * 3);
  final am = alpha == null ? null : Float64List(o * i);
  var cap = 0;
  var hr = Float64List(0),
      dg = Float64List(0),
      gb = Float64List(0),
      mb = Float64List(0);
  for (var b = 0; b < o; b++) {
    final y0 = yb[b], y1 = yb[b + 1];
    final ay = _roundHalfEven((y1 - y0) * margin);
    var r0 = y0 + ay, r1 = y1 - ay;
    if (r1 - r0 < 1) {
      r0 = y0;
      r1 = y1;
    }
    for (var ri = 0; ri < i; ri++) {
      final x0 = xb[ri], x1 = xb[ri + 1];
      final ax = _roundHalfEven((x1 - x0) * margin);
      var c0 = x0 + ax, c1 = x1 - ax;
      if (c1 - c0 < 1) {
        c0 = x0;
        c1 = x1;
      }
      final f = (r1 - r0) * (c1 - c0);
      if (f > cap) {
        cap = f;
        hr = Float64List(cap);
        dg = Float64List(cap);
        gb = Float64List(cap);
        mb = Float64List(cap);
      }
      var cnt = 0, u2 = 0;
      for (var y = r0; y < r1; y++) {
        var p3 = (y * w + c0) * 3, ai = y * w + c0;
        for (var x = c0; x < c1; x++) {
          final av = alpha == null ? 255 : alpha[ai];
          if (alpha != null) mb[u2] = av.toDouble();
          if (av > 0) {
            hr[cnt] = rgb[p3];
            dg[cnt] = rgb[p3 + 1];
            gb[cnt] = rgb[p3 + 2];
            cnt++;
          }
          u2++;
          p3 += 3;
          ai++;
        }
      }
      final pi = (b * i + ri) * 3;
      if (cnt > 0) {
        cells[pi] = _median(hr, cnt);
        cells[pi + 1] = _median(dg, cnt);
        cells[pi + 2] = _median(gb, cnt);
      }
      if (am != null) am[b * i + ri] = _median(mb, f);
    }
  }
  return (cells: cells, alpha: am, hc: o, wc: i);
}

/// Inline MAE from `k` — mean |cell colour − source pixel| over pixels
/// strictly inside the grid, normalised by W·H·3 (line pixels excluded from
/// the numerator but still counted in the denominator, as in the original).
double _cellMae(
  Float64List rgb,
  Float64List cells,
  List<int> xb,
  List<int> yb,
  int w,
  int h,
) {
  final o = xb.length - 1;
  var i = 0.0;
  for (var l = 0; l < yb.length - 1; l++) {
    for (var u = yb[l]; u < yb[l + 1]; u++) {
      for (var n = 0; n < o; n++) {
        final s = (l * o + n) * 3;
        for (var l2 = xb[n]; l2 < xb[n + 1]; l2++) {
          final r = (u * w + l2) * 3;
          i +=
              (cells[s] - rgb[r]).abs() +
              (cells[s + 1] - rgb[r + 1]).abs() +
              (cells[s + 2] - rgb[r + 2]).abs();
        }
      }
    }
  }
  return i / (w * h * 3);
}

/// `k` — fine refinement: for every candidate pitch, 33 pitch variants in
/// ±4 % × 16 phases are scored; the best grid per pitch is then evaluated by
/// cell MAE. Returns one record per input pitch.
List<({double px, double py, double phx, double phy, double mae})> _fineGrids(
  Float64List rgb,
  Float64List cs,
  Float64List rs,
  int w,
  int h,
  List<double> pitches,
  List<List<double>> phases,
  Uint32List sat,
) {
  final c = pitches.length;
  final set = _phaseSet(16);
  final variants = Float64List(33 * c),
      basePitch = Float64List(33 * c),
      xPh = Float64List(33 * c),
      yPh = Float64List(33 * c);
  for (var e = 0; e < c; e++) {
    variants.setRange(
      33 * e,
      33 * e + 33,
      _linspace(.96 * pitches[e], 1.04 * pitches[e], 33),
    );
    for (var t = 0; t < 33; t++) {
      final r = 33 * e + t;
      basePitch[r] = pitches[e];
      xPh[r] = phases[e][0];
      yPh[r] = phases[e][1];
    }
  }
  final groups = List<List<double>>.filled(33 * c, set);
  final rowSpread = _spread(
    _buildInner(0, w.toDouble(), variants, groups, 1),
    _buildOuter(0, h.toDouble(), basePitch, yPh, 1),
    sat,
    w + 1,
    true,
  );
  final colSpread = _spread(
    _buildInner(0, h.toDouble(), variants, groups, 1),
    _buildOuter(0, w.toDouble(), basePitch, xPh, 1),
    sat,
    w + 1,
    false,
  );
  (double, double) bestOf(Float32List scores, int t, double fallback) {
    final base = 33 * t * 16;
    var ai = 0;
    var av = scores[base];
    for (var j = 1; j < 528; j++) {
      final v = scores[base + j];
      if (v < av) {
        av = v;
        ai = j;
      }
    }
    if (av >= 1e18) return (pitches[t], fallback);
    return (variants[33 * t + (ai ~/ 16)], set[ai % 16]);
  }

  final out = <({double px, double py, double phx, double phy, double mae})>[];
  for (var e = 0; e < c; e++) {
    final (px, phx) = bestOf(rowSpread, e, phases[e][0]);
    final (py, phy) = bestOf(colSpread, e, phases[e][1]);
    final ox = _pmod(phx * px, px), oy = _pmod(phy * py, py);
    final lines = _gridLines(cs, rs, w, h, px, py, ox, oy);
    final cells = _sampleCells(
      rgb,
      lines.$1,
      lines.$2,
      w,
      _kMargin,
      null,
    ).cells;
    final mae = _cellMae(rgb, cells, lines.$1, lines.$2, w, h);
    out.add((px: px, py: py, phx: phx, phy: phy, mae: mae));
  }
  return out;
}

/// `D` — evaluate the coarse pitch plus (unless [maxDetail] is null) its /2
/// and /3 sub-harmonics, and adopt the finest grid whose cell MAE improves on
/// the base grid by more than `maxDetail`. Returns `(px, py, phx, phy)`.
({double px, double py, double phx, double phy}) _refine(
  Float64List rgb,
  Float64List cs,
  Float64List rs,
  int w,
  int h,
  double pitch,
  double phx,
  double phy,
  Uint32List sat, {
  double? maxDetail,
  double minSubPitch = 1.5,
}) {
  final pitches = <double>[pitch];
  final phases = <List<double>>[
    [phx, phy],
  ];
  if (maxDetail != null) {
    for (final div in const [2, 3]) {
      final sub = pitch / div;
      if (sub < minSubPitch) break;
      pitches.add(sub);
    }
  }
  if (pitches.length > 1) {
    final sub = _phaseDetect(
      Float64List.fromList(pitches.sublist(1)),
      w,
      h,
      sat,
      14,
      1,
    );
    for (var e = 1; e < pitches.length; e++) {
      phases.add([sub.$1[e - 1], sub.$2[e - 1]]);
    }
  }
  final results = _fineGrids(rgb, cs, rs, w, h, pitches, phases, sat);
  var best = results[0];
  for (var e = 1; e < results.length; e++) {
    if (results[e].mae < best.mae * (1 - maxDetail!)) best = results[e];
  }
  return (px: best.px, py: best.py, phx: best.phx, phy: best.phy);
}

// ---------------------------------------------------------------------------
// Step 7 — palette quantisation (I): octree → Lab pairwise merge → remap
// ---------------------------------------------------------------------------

/// sRGB → CIE Lab (D65), `S` of the original.
List<double> _srgbToLab(double r, double g, double b) {
  double lin(double v) {
    final x = v / 255;
    return x <= .04045
        ? x / 12.92
        : math.pow((x + .055) / 1.055, 2.4).toDouble();
  }

  double f(double x) => x > .008856 ? _cbrt(x) : 7.787 * x + 16 / 116;

  final a = lin(r), l = lin(g), o = lin(b);
  final u = f((.4124 * a + .3576 * l + .1805 * o) / .95047);
  final s = f(.2126 * a + .7152 * l + .0722 * o);
  return [
    116 * s - 16,
    500 * (u - s),
    200 * (s - f((.0193 * a + .1192 * l + .9505 * o) / 1.08883)),
  ];
}

class _OctNode {
  _OctNode(this.leaf);

  bool leaf;
  int count = 0;
  double r = 0, g = 0, b = 0;
  List<_OctNode?>? kids;
}

class _PalEntry {
  _PalEntry(this.r, this.g, this.b, this.count, this.lab);

  double r, g, b;
  int count;
  List<double> lab;
}

/// `I` — palette via 8-level octree (capacity `capacity`), then iterative
/// merge of the Lab-distance-minimising pair until `stop(distance, length)`.
/// Every input colour is finally remapped to its nearest palette entry in
/// Lab space. Returns the mapped colours and the used-palette size.
(Float64List, int) _paletteTree(
  Float64List e,
  int t,
  int capacity,
  bool Function(double, int) stop,
) {
  if (t <= 0) return (Float64List.fromList(e), 0);
  final levels = List.generate(8, (_) => <_OctNode>[]);
  var leafCount = 0;
  final root = _OctNode(false);
  void reduce() {
    var lvl = 7;
    while (lvl >= 0 && levels[lvl].isEmpty) {
      lvl--;
    }
    if (lvl < 0) return;
    final bucket = levels[lvl];
    var sel = 0;
    for (var j = 1; j < bucket.length; j++) {
      if (bucket[j].count < bucket[sel].count) sel = j;
    }
    final node = bucket.removeAt(sel);
    var kids = 0;
    for (var j = 0; j < 8; j++) {
      final k = node.kids![j];
      if (k != null) {
        node.r += k.r;
        node.g += k.g;
        node.b += k.b;
        node.count += k.count;
        kids++;
      }
    }
    node.kids = null;
    node.leaf = true;
    leafCount += 1 - kids;
  }

  for (var u = 0; u < t; u++) {
    final rr = math.min(255, math.max(0, _roundHalfEven(e[3 * u])));
    final gg = math.min(255, math.max(0, _roundHalfEven(e[3 * u + 1])));
    final bb = math.min(255, math.max(0, _roundHalfEven(e[3 * u + 2])));
    var c = root;
    var hh = 0;
    while (!c.leaf && hh < 8) {
      final shift = 7 - hh;
      final idx =
          ((rr >> shift) & 1) << 2 |
          ((gg >> shift) & 1) << 1 |
          ((bb >> shift) & 1);
      if (c.kids == null) {
        c.kids = List<_OctNode?>.filled(8, null);
        levels[hh].add(c);
      }
      if (c.kids![idx] == null) {
        final leaf = hh == 7;
        c.kids![idx] = _OctNode(leaf);
        if (leaf) leafCount++;
      }
      c = c.kids![idx]!;
      hh++;
    }
    c.count++;
    c.r += rr;
    c.g += gg;
    c.b += bb;
    while (leafCount > capacity) {
      reduce();
    }
  }
  final pal = <_PalEntry>[];
  void collect(_OctNode n) {
    final kids = n.kids;
    if (kids != null) {
      for (final k in kids) {
        if (k != null) collect(k);
      }
    } else if (n.count > 0) {
      pal.add(
        _PalEntry(
          n.r / n.count,
          n.g / n.count,
          n.b / n.count,
          n.count,
          _srgbToLab(n.r / n.count, n.g / n.count, n.b / n.count),
        ),
      );
    }
  }

  collect(root);
  double weight(int cnt) =>
      1 +
      math.max(
        math.max(0.0, 1 - cnt / t / .02),
        3 * math.max(0.0, 1 - cnt / 16),
      );
  while (pal.length > 1) {
    var bi = -1, bj = -1;
    var bd = double.infinity;
    for (var n = 0; n < pal.length; n++) {
      for (var o = n + 1; o < pal.length; o++) {
        final x = pal[n], y = pal[o];
        final dl = x.lab[0] - y.lab[0],
            da = x.lab[1] - y.lab[1],
            db = x.lab[2] - y.lab[2];
        final dd =
            math.sqrt(dl * dl + da * da + db * db) /
            weight(math.min(x.count, y.count));
        if (dd < bd) {
          bd = dd;
          bi = n;
          bj = o;
        }
      }
    }
    if (stop(bd, pal.length)) break;
    final x = pal[bi], y = pal[bj];
    final u = x.count + y.count;
    x.r = (x.r * x.count + y.r * y.count) / u;
    x.g = (x.g * x.count + y.g * y.count) / u;
    x.b = (x.b * x.count + y.b * y.count) / u;
    x.count = u;
    x.lab = _srgbToLab(x.r, x.g, x.b);
    pal.removeAt(bj);
  }
  final out = Float64List(3 * t);
  final used = <int>{};
  for (var r = 0; r < t; r++) {
    final lab = _srgbToLab(e[3 * r], e[3 * r + 1], e[3 * r + 2]);
    var best = 0;
    var bd = double.infinity;
    for (var j = 0; j < pal.length; j++) {
      final pl = pal[j].lab;
      final d0 = lab[0] - pl[0], d1 = lab[1] - pl[1], d2 = lab[2] - pl[2];
      final dd = d0 * d0 + d1 * d1 + d2 * d2;
      if (dd < bd) {
        bd = dd;
        best = j;
      }
    }
    used.add(best);
    out[3 * r] = pal[best].r;
    out[3 * r + 1] = pal[best].g;
    out[3 * r + 2] = pal[best].b;
  }
  return (out, used.length);
}

// ---------------------------------------------------------------------------
// Step 8 — quantise, upscale, encode
// ---------------------------------------------------------------------------

/// `_` — banker's-round and clamp to bytes.
Uint8List _quantize(Float64List e) {
  final t = Uint8List(e.length);
  for (var i = 0; i < e.length; i++) {
    final n = _roundHalfEven(e[i]);
    t[i] = n < 0 ? 0 : (n > 255 ? 255 : n);
  }
  return t;
}

/// `H` — RGBA assembly plus optional integer nearest-neighbour upscale,
/// PNG-encoded via `package:image`.
Uint8List _encodePng(
  Uint8List rgb,
  Uint8List? alpha,
  int w,
  int h,
  int factor,
) {
  final out = img.Image(width: w * factor, height: h * factor, numChannels: 4);
  for (var y = 0; y < out.height; y++) {
    final sy = y ~/ factor;
    for (var x = 0; x < out.width; x++) {
      final ci = sy * w + x ~/ factor;
      final s = ci * 3;
      out.setPixelRgba(
        x,
        y,
        rgb[s],
        rgb[s + 1],
        rgb[s + 2],
        alpha == null ? 255 : alpha[ci],
      );
    }
  }
  return Uint8List.fromList(img.encodePng(out));
}

// ---------------------------------------------------------------------------
// Orchestration (`N` + the worker message handler's fixed options)
// ---------------------------------------------------------------------------

Uint8List _pixelSnapRun(Uint8List source, PixelSnapOptions options) {
  final dec = _decodeRgba(source);
  var rgb = dec.rgb;
  var alpha = dec.alpha;
  var w = dec.w, h = dec.h;
  final srcW = w, srcH = h;
  if (w * h > _kMaxPixels) {
    final scale = math.sqrt(_kMaxPixels / (w * h));
    final nw = math.max(1, (w * scale).floor());
    final nh = math.max(1, (h * scale).floor());
    rgb = _pointDownscale3(rgb, h, w, nw, nh);
    alpha = alpha == null ? null : _pointDownscale1(alpha, h, w, nw, nh);
    w = nw;
    h = nh;
  }
  final spec = _diffSpectra(rgb, h, w);
  final sat = _integralImage(rgb, h, w);
  double px, py;
  final double phx, phy;
  if (_kPx > 0 && _kPy > 0) {
    final ph = _manualPhases(_kPx, _kPy, w, h, sat, 24);
    px = _kPx;
    py = _kPy;
    phx = ph.$1;
    phy = ph.$2;
  } else {
    final candidates = _detectPitches([spec.$1, spec.$2]);
    if (candidates.isEmpty) {
      throw const FormatException(
        "pixel-snap: no pitch candidates detected -- the image doesn't look "
        'like scaled pixel art (no repeating grid found)',
      );
    }
    final best = _coarseSelect(w, h, candidates, sat);
    final grid = _refine(
      rgb,
      spec.$1,
      spec.$2,
      w,
      h,
      best[1],
      best[2],
      best[3],
      sat,
      maxDetail: options.avoidOverRefining ? null : _kMaxDetail,
    );
    px = grid.px;
    py = grid.py;
    phx = grid.phx;
    phy = grid.phy;
    if (_kPx > 0) px = _kPx;
    if (_kPy > 0) py = _kPy;
  }
  final ox = _pmod(phx * px, px), oy = _pmod(phy * py, py);
  final lines = _gridLines(spec.$1, spec.$2, w, h, px, py, ox, oy);
  final sampled = _sampleCells(rgb, lines.$1, lines.$2, w, _kMargin, alpha);
  final count = sampled.wc * sampled.hc;
  final cells = switch (options.paletteMode) {
    PixelSnapPaletteMode.off => sampled.cells,
    PixelSnapPaletteMode.auto => _paletteTree(
      sampled.cells,
      count,
      256,
      (d, l) => d > _kAutoTol,
    ).$1,
    PixelSnapPaletteMode.custom => _paletteTree(
      sampled.cells,
      count,
      math.max(256, math.max(1, options.colors)),
      (d, l) => l <= math.max(1, options.colors),
    ).$1,
  };
  final rgb8 = _quantize(cells);
  final alpha8 = sampled.alpha == null ? null : _quantize(sampled.alpha!);
  final factor = options.upscale
      ? math.max(1, ((srcW / sampled.wc + srcH / sampled.hc) / 2).round())
      : 1;
  return _encodePng(rgb8, alpha8, sampled.wc, sampled.hc, factor);
}
