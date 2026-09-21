import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/director/pixel_snap_service.dart';

Uint8List _encode(img.Image image) => Uint8List.fromList(img.encodePng(image));

int _cellR(int cx, int cy) => (37 + cx * 23 + cy * 11) % 256;
int _cellG(int cx, int cy) => (91 + cx * 7 + cy * 29) % 256;
int _cellB(int cx, int cy) => (153 + cx * 41 + cy * 3) % 256;

/// Synthetic "scaled pixel art": a [cellsX]×[cellsY] grid of flat-colour
/// cells, each [scale]×[scale] device pixels. [transparent] marks cells that
/// are fully transparent (alpha 0).
Uint8List _gridPng({
  int cellsX = 10,
  int cellsY = 10,
  int scale = 8,
  bool Function(int cx, int cy)? transparent,
}) {
  final image = img.Image(
    width: cellsX * scale,
    height: cellsY * scale,
    numChannels: 4,
  );
  for (var cy = 0; cy < cellsY; cy++) {
    for (var cx = 0; cx < cellsX; cx++) {
      final a = (transparent != null && transparent(cx, cy)) ? 0 : 255;
      for (var y = cy * scale; y < (cy + 1) * scale; y++) {
        for (var x = cx * scale; x < (cx + 1) * scale; x++) {
          image.setPixelRgba(
            x,
            y,
            _cellR(cx, cy),
            _cellG(cx, cy),
            _cellB(cx, cy),
            a,
          );
        }
      }
    }
  }
  return _encode(image);
}

/// A 100×100 image that simulates a non-integer pixel scale (~6.5 px/cell):
/// each output pixel takes the colour of cell `x * 10 ~/ 65`, so cells are 6
/// or 7 px wide — a realistic input for fractional pitch detection.
Uint8List _nonUniformGridPng({int cells = 10, int size = 65}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    final cy = y * cells ~/ size;
    for (var x = 0; x < size; x++) {
      final cx = x * cells ~/ size;
      image.setPixelRgba(
        x,
        y,
        _cellR(cx, cy),
        _cellG(cx, cy),
        _cellB(cx, cy),
        255,
      );
    }
  }
  return _encode(image);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PixelSnapService.snapSync', () {
    test('snaps a clean scaled pixel grid back to cell resolution', () {
      final src = _gridPng(cellsX: 10, cellsY: 10, scale: 8);
      final out = img.decodePng(
        PixelSnapService.snapSync(
          src,
          options: const PixelSnapOptions(
            paletteMode: PixelSnapPaletteMode.off,
          ),
        ),
      )!;
      expect(out.width, 10);
      expect(out.height, 10);
      for (var cy = 0; cy < 10; cy++) {
        for (var cx = 0; cx < 10; cx++) {
          final p = out.getPixel(cx, cy);
          expect(p.r.toInt(), _cellR(cx, cy), reason: 'cell $cx,$cy red');
          expect(p.g.toInt(), _cellG(cx, cy), reason: 'cell $cx,$cy green');
          expect(p.b.toInt(), _cellB(cx, cy), reason: 'cell $cx,$cy blue');
          expect(p.a.toInt(), 255, reason: 'cell $cx,$cy alpha');
        }
      }
    });

    test('recovers a non-integer pitch grid', () {
      final out = img.decodePng(
        PixelSnapService.snapSync(
          _nonUniformGridPng(cells: 10, size: 65),
          options: const PixelSnapOptions(
            paletteMode: PixelSnapPaletteMode.off,
          ),
        ),
      )!;
      // The exact pitch (~6.5) must land within one cell of the true count.
      expect(out.width, inInclusiveRange(9, 11));
      expect(out.height, inInclusiveRange(9, 11));
      // Corner cells must reproduce the source corner colours.
      final tl = out.getPixel(0, 0);
      expect(tl.r.toInt(), _cellR(0, 0));
      expect(tl.g.toInt(), _cellG(0, 0));
      expect(tl.b.toInt(), _cellB(0, 0));
    });

    test('upscale returns approximately the input resolution', () {
      final src = _gridPng(cellsX: 8, cellsY: 8, scale: 5);
      final out = img.decodePng(
        PixelSnapService.snapSync(
          src,
          options: const PixelSnapOptions(
            paletteMode: PixelSnapPaletteMode.off,
            upscale: true,
          ),
        ),
      )!;
      expect(out.width, 40);
      expect(out.height, 40);
      final p = out.getPixel(2, 2);
      expect(p.r.toInt(), _cellR(0, 0));
      expect(p.g.toInt(), _cellG(0, 0));
      expect(p.b.toInt(), _cellB(0, 0));
      expect(p.a.toInt(), 255);
    });

    test('custom palette reduces the unique colour count to at most N', () {
      final src = _gridPng(cellsX: 12, cellsY: 12, scale: 5);
      final out = img.decodePng(
        PixelSnapService.snapSync(
          src,
          options: const PixelSnapOptions(
            paletteMode: PixelSnapPaletteMode.custom,
            colors: 4,
          ),
        ),
      )!;
      final unique = <int>{};
      for (var y = 0; y < out.height; y++) {
        for (var x = 0; x < out.width; x++) {
          final p = out.getPixel(x, y);
          unique.add((p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt());
        }
      }
      expect(unique.length, lessThanOrEqualTo(4));
    });

    test('auto palette matches the reference worker merge result', () {
      final src = _gridPng(cellsX: 10, cellsY: 10, scale: 8);
      final out = img.decodePng(PixelSnapService.snapSync(src))!;
      expect(out.width, 10);
      expect(out.height, 10);
      // Offline JS CPU oracle (autoTol 6.5): palette size 26, first RGB below.
      // Automatic quantisation may merge the corner with nearby colours.
      final p = out.getPixel(0, 0);
      expect([p.r.toInt(), p.g.toInt(), p.b.toInt()], [52, 127, 194]);
    });

    test('transparent cells stay transparent and opaque cells stay opaque', () {
      final src = _gridPng(
        cellsX: 10,
        cellsY: 10,
        scale: 8,
        transparent: (cx, cy) => cx == 0,
      );
      final out = img.decodePng(
        PixelSnapService.snapSync(
          src,
          options: const PixelSnapOptions(
            paletteMode: PixelSnapPaletteMode.off,
          ),
        ),
      )!;
      expect(out.width, 10);
      for (var cy = 0; cy < 10; cy++) {
        expect(
          out.getPixel(0, cy).a.toInt(),
          0,
          reason: 'transparent column cell $cy',
        );
        expect(
          out.getPixel(1, cy).a.toInt(),
          255,
          reason: 'opaque column cell $cy',
        );
      }
    });

    test('rejects a fully transparent image', () {
      final src = _gridPng(transparent: (cx, cy) => true);
      expect(() => PixelSnapService.snapSync(src), throwsFormatException);
    });

    test('rejects undecodable bytes', () {
      expect(
        () => PixelSnapService.snapSync(
          Uint8List.fromList(const [1, 2, 3, 4, 5, 6, 7, 8]),
        ),
        throwsFormatException,
      );
    });

    test('rejects images without a detectable pixel grid', () {
      final image = img.Image(width: 64, height: 64, numChannels: 4);
      for (var y = 0; y < 64; y++) {
        for (var x = 0; x < 64; x++) {
          image.setPixelRgba(x, y, 120, 60, 200, 255);
        }
      }
      expect(
        () => PixelSnapService.snapSync(_encode(image)),
        throwsFormatException,
      );
    });
  });

  group('PixelSnapService.snap', () {
    test('produces byte-identical output to snapSync', () async {
      final src = _gridPng(cellsX: 6, cellsY: 6, scale: 6);
      const options = PixelSnapOptions(paletteMode: PixelSnapPaletteMode.off);
      final async = await PixelSnapService.snap(src, options: options);
      final sync = PixelSnapService.snapSync(src, options: options);
      expect(async, sync);
    });
  });
}
