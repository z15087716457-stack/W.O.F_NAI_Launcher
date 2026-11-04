import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

import '../../../helpers/app_logger_test_isolation.dart';

const _json = '{"prompt":"rain over a quiet harbor","seed":42}';

/// A picture with noisy colours and alpha, so every PNG filter has work.
img.Image _picture(int width, int height, {int channels = 4, int seed = 1}) {
  final random = Random(seed);
  final image = img.Image(width: width, height: height, numChannels: channels);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      if (channels >= 3) {
        pixel
          ..r = (x * 3 + random.nextInt(40)) % 256
          ..g = (y * 5 + random.nextInt(40)) % 256
          ..b = (x ^ y) % 256;
      } else {
        pixel.r = (x + y + random.nextInt(30)) % 256;
      }
      if (channels == 2 || channels == 4) {
        pixel.a = 160 + random.nextInt(96);
      }
    }
  }
  return image;
}

/// Writes NovelAI's stealth data the way the app (and NovelAI) does: magic,
/// bit length, gzip payload, one bit per alpha LSB, column by column.
img.Image _withStealth(img.Image image, String json) {
  final payload = GZipCodec().encode(utf8.encode(json));
  final length = ByteData(4)..setInt32(0, payload.length * 8);
  final data = [
    ...utf8.encode('stealth_pngcomp'),
    ...length.buffer.asUint8List(),
    ...payload,
  ];
  var bit = 0;
  for (var x = 0; x < image.width; x++) {
    for (var y = 0; y < image.height; y++) {
      if (bit ~/ 8 >= data.length) return image;
      final value = (data[bit ~/ 8] >> (7 - bit % 8)) & 1;
      final pixel = image.getPixel(x, y);
      pixel.a = (pixel.a.toInt() & ~1) | value;
      bit++;
    }
  }
  return image;
}

Uint8List _png(img.Image image, [img.PngFilter filter = img.PngFilter.paeth]) =>
    Uint8List.fromList(img.PngEncoder(filter: filter).encode(image));

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late int decodes;
  setUp(() => decodes = UnifiedMetadataParser.debugStealthDecodes);
  int newDecodes() => UnifiedMetadataParser.debugStealthDecodes - decodes;

  test('an RGB PNG without text metadata is not decoded at all', () {
    final result = UnifiedMetadataParser.parseFromPng(
      _png(_picture(320, 480, channels: 3)),
    );
    expect(result.success, isFalse);
    expect(result.metadataAbsent, isTrue);
    // Before: every pixel decoded in Dart, only to find no alpha channel.
    expect(newDecodes(), 0);
  });

  test('a full-size RGB gallery image is not decoded in any read step', () {
    final bytes = _png(_picture(832, 1216, channels: 3));
    expect(bytes.length, greaterThan(500 * 1024));
    final result = UnifiedMetadataParser.parseFromBytesGradual(bytes);
    expect(result.success, isFalse);
    expect(result.metadataAbsent, isTrue);
    // Before: one full decode per prefix tried (100 KB, 500 KB...) and the file.
    expect(newDecodes(), 0);
  });

  test('an RGBA PNG without stealth data is read only for its first rows', () {
    final result = UnifiedMetadataParser.parseFromPng(_png(_picture(320, 480)));
    expect(result.success, isFalse);
    expect(result.metadataAbsent, isTrue);
    expect(newDecodes(), 0);
  });

  for (final filter in img.PngFilter.values) {
    test('stealth data is still found with the ${filter.name} filter', () {
      final result = UnifiedMetadataParser.parseFromPng(
        _png(
          _withStealth(_picture(320, 480, seed: filter.index), _json),
          filter,
        ),
      );
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.metadata!.prompt, 'rain over a quiet harbor');
      expect(result.sourceFormat, 'NovelAI stealth_pngcomp');
      expect(newDecodes(), 1);
    });
  }

  test('grey + alpha images are checked the same way', () {
    final plain = UnifiedMetadataParser.parseFromPng(
      _png(_picture(200, 300, channels: 2)),
    );
    expect(plain.metadataAbsent, isTrue);
    expect(newDecodes(), 0);
    final stealth = UnifiedMetadataParser.parseFromPng(
      _png(_withStealth(_picture(200, 300, channels: 2), _json)),
    );
    expect(stealth.success, isTrue, reason: stealth.errorMessage);
    expect(newDecodes(), 1);
  });

  test('a prefix that stops before the marker rows leaves it to the file', () {
    final bytes = _png(_withStealth(_picture(832, 1216), _json));
    final prefix = Uint8List.sublistView(bytes, 0, 2048);
    final partial = UnifiedMetadataParser.parseFromPng(prefix);
    expect(partial.success, isFalse);
    expect(partial.metadataAbsent, isFalse, reason: 'not known yet');
    expect(newDecodes(), 0);
    final gradual = UnifiedMetadataParser.parseFromBytesGradual(bytes);
    expect(gradual.success, isTrue, reason: gradual.errorMessage);
    expect(gradual.metadata!.prompt, 'rain over a quiet harbor');
    expect(newDecodes(), 1, reason: 'only the complete file');
  });

  test('uncommon layouts still get the full decoder (16-bit RGBA)', () {
    final image = img.Image(
      width: 200,
      height: 300,
      numChannels: 4,
      format: img.Format.uint16,
    );
    for (final pixel in image) {
      pixel
        ..r = 30000
        ..g = 20000
        ..b = 10000
        ..a = 65000;
    }
    final result = UnifiedMetadataParser.parseFromPng(_png(image));
    expect(result.metadataAbsent, isTrue);
    expect(newDecodes(), 1);
  });

  test('text metadata still wins without any decode', () async {
    final bytes = await UnifiedMetadataParser.embedMetadata(
      _png(_picture(320, 480)),
      _json,
      useStealth: true,
    );
    decodes = UnifiedMetadataParser.debugStealthDecodes;
    final result = UnifiedMetadataParser.parseFromPng(bytes);
    expect(result.success, isTrue);
    expect(result.metadata!.prompt, 'rain over a quiet harbor');
    expect(newDecodes(), 0);
  });
}
