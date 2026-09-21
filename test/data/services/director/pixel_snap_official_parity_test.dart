import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/director/pixel_snap_service.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'test/fixtures/pixel_snap/official_cpu.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final f in data['fixtures'] as List) {
    test(
      'official CPU parity ${f['mode']} refine=${!f['avoid']} pitch=${f['pitch']} alpha=${f['alpha']}',
      () {
        final input = img.Image(
          width: f['w'] as int,
          height: f['h'] as int,
          numChannels: 4,
        );
        for (var y = 0; y < input.height; y++) {
          for (var x = 0; x < input.width; x++) {
            final a = (x + (f['offset'] as int)) ~/ (f['pitch'] as int);
            final b = (y + (f['offset'] as int)) ~/ (f['pitch'] as int);
            final cell = (a * 13 + b * 7 + a * b * 3) % 23;
            final alpha = f['alpha'] == true
                ? (cell % 7 == 0
                      ? 0
                      : cell % 3 == 0
                      ? 128
                      : 255)
                : 255;
            input.setPixelRgba(
              x,
              y,
              (cell * 53 + 15) % 256,
              (cell * 83 + 71) % 256,
              (cell * 37 + 129) % 256,
              alpha,
            );
          }
        }
        final result = img.decodePng(
          PixelSnapService.snapSync(
            Uint8List.fromList(img.encodePng(input)),
            options: PixelSnapOptions(
              paletteMode: PixelSnapPaletteMode.values.byName(
                f['mode'] as String,
              ),
              colors: 16,
              avoidOverRefining: f['avoid'] as bool,
            ),
          ),
        )!;
        expect((result.width, result.height), (f['width'], f['height']));
        final expected = f['rgb'] as List;
        final alpha = f['outAlpha'] as List?;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            final pixel = result.getPixel(x, y), index = y * result.width + x;
            expect(
              [pixel.r, pixel.g, pixel.b, pixel.a],
              [
                expected[index * 3],
                expected[index * 3 + 1],
                expected[index * 3 + 2],
                alpha?[index] ?? 255,
              ],
              reason: 'Pixel $x,$y',
            );
          }
        }
      },
    );
  }
}
