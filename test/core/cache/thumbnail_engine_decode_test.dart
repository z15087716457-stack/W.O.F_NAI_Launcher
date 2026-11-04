import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:path/path.dart' as p;

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  final service = ThumbnailCacheService.instance;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('thumbnail_engine_');
    await service.init();
    service.setRootPaths([directory.path]);
    service.resetStats();
  });
  tearDown(() async {
    expect(service.getStats()['activeGenerations'], 0);
    service.setRootPaths([]);
    await directory.delete(recursive: true);
  });

  /// Left half red, right half blue; the top-left quarter green, so every
  /// rotation and mirror lands somewhere different.
  img.Image quadrants(int width, int height, {int alpha = 255}) {
    final image = img.Image(width: width, height: height, numChannels: 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final left = x < width / 2, top = y < height / 2;
        if (left && top) {
          image.setPixelRgba(x, y, 0, 220, 0, alpha);
        } else {
          image.setPixelRgba(x, y, left ? 220 : 0, 0, left ? 0 : 220, alpha);
        }
      }
    }
    return image;
  }

  Future<File> write(String name, List<int> bytes) =>
      File(p.join(directory.path, name)).writeAsBytes(bytes);

  img.Image jpeg(Uint8List bytes) => img.decodeJpg(bytes)!;

  /// Mean absolute difference per channel, 0..255.
  double difference(img.Image a, img.Image b) {
    var total = 0.0;
    for (var y = 0; y < a.height; y++) {
      for (var x = 0; x < a.width; x++) {
        final pa = a.getPixel(x, y), pb = b.getPixel(x, y);
        total +=
            (pa.r - pb.r).abs() + (pa.g - pb.g).abs() + (pa.b - pb.b).abs();
      }
    }
    return total / (a.width * a.height * 3);
  }

  ({num r, num g, num b}) colorAt(img.Image image, double fx, double fy) {
    final pixel = image.getPixel(
      (fx * (image.width - 1)).round(),
      (fy * (image.height - 1)).round(),
    );
    return (r: pixel.r, g: pixel.g, b: pixel.b);
  }

  Future<(img.Image, img.Image)> both(File file, ThumbnailSize size) async {
    final before = service.getStats();
    final engine = jpeg(await service.renderThumbnail(file.path, size: size));
    final dart = jpeg(
      await service.renderThumbnail(file.path, size: size, engine: false),
    );
    final after = service.getStats();
    // One of each: the engine really decoded the first, no silent fallback.
    expect(after['engineDecodes'] - before['engineDecodes'], 1);
    expect(after['dartDecodes'] - before['dartDecodes'], 1);
    return (engine, dart);
  }

  group('engine decode matches the Dart thumbnails already on disk', () {
    for (final (width, height) in [
      (832, 1216),
      (1216, 832),
      (1024, 1024),
      (2000, 1),
      (1, 2000),
      (40, 30),
    ]) {
      for (final size in ThumbnailSize.values) {
        test(
          '$width x $height PNG at $size: same size, same picture',
          () async {
            final file = await write(
              'source.png',
              img.encodePng(quadrants(width, height)),
            );
            final (engine, dart) = await both(file, size);
            final expected = thumbnailPixelSize(
              width,
              height,
              targetWidth: size.width,
              targetHeight: size.height,
            );
            expect(
              (engine.width, engine.height),
              (expected.width, expected.height),
            );
            expect((dart.width, dart.height), (engine.width, engine.height));
            if (width >= 8 && height >= 8) {
              // Scaling filters differ slightly at the colour edges only.
              expect(difference(engine, dart), lessThan(12));
            }
          },
        );
      }
    }
  });

  test('a JPEG keeps its format and quality', () async {
    final file = await write(
      'photo.jpg',
      img.encodeJpg(quadrants(600, 400), quality: 95),
    );
    final bytes = await service.renderThumbnail(
      file.path,
      size: ThumbnailSize.medium,
    );
    expect(bytes.sublist(0, 2), [0xFF, 0xD8], reason: 'JPEG start marker');
    expect(img.findFormatForData(bytes), img.ImageFormat.jpg);
  });

  for (final orientation in [1, 2, 3, 6, 8]) {
    test('EXIF orientation $orientation is applied like before', () async {
      final source = quadrants(400, 200)
        ..exif.imageIfd.orientation = orientation;
      final file = await write('rotated.jpg', img.encodeJpg(source));
      final (engine, dart) = await both(file, ThumbnailSize.small);
      expect((engine.width, engine.height), (dart.width, dart.height));
      final upright = orientation >= 5;
      expect(engine.height > engine.width, upright);
      for (final (fx, fy) in [(0.1, 0.1), (0.9, 0.1), (0.1, 0.9), (0.9, 0.9)]) {
        final e = colorAt(engine, fx, fy), d = colorAt(dart, fx, fy);
        expect(
          [(e.r - d.r).abs(), (e.g - d.g).abs(), (e.b - d.b).abs()],
          everyElement(lessThan(40)),
          reason: 'corner ($fx, $fy) $e vs $d',
        );
      }
    });
  }

  test('transparency: colours are not darkened by their alpha', () async {
    // A half-transparent picture, and one transparent pixel stored black.
    final source = quadrants(200, 200, alpha: 128)
      ..setPixelRgba(199, 199, 0, 0, 0, 0);
    final file = await write('alpha.png', img.encodePng(source));
    final (engine, dart) = await both(file, ThumbnailSize.small);
    // Straight colour, as the Dart path wrote it: red stays ~220, not ~110.
    expect(colorAt(engine, 0.2, 0.8).r, greaterThan(190));
    expect(colorAt(engine, 0.8, 0.8).b, greaterThan(190));
    expect(colorAt(engine, 0.2, 0.2).g, greaterThan(190));
    expect(difference(engine, dart), lessThan(12));
  });

  test('a picture the engine cannot decode falls back to the Dart decoder '
      '(TGA / TIFF on Windows)', () async {
    final file = await write('legacy.tga', img.encodeTga(quadrants(300, 200)));
    ThumbnailCacheService.engineDecoder =
        (bytes, {required targetWidth, required targetHeight}) =>
            throw Exception('Invalid image data');
    addTearDown(
      () => ThumbnailCacheService.engineDecoder = decodeThumbnailWithEngine,
    );
    final bytes = await service.renderThumbnail(
      file.path,
      size: ThumbnailSize.small,
    );
    final thumbnail = jpeg(bytes);
    expect(service.getStats()['dartDecodes'], 1);
    expect(service.getStats()['engineDecodes'], 0);
    expect((thumbnail.width, thumbnail.height), (180, 120));
    expect(colorAt(thumbnail, 0.8, 0.8).b, greaterThan(190));
  });

  test('an existing thumbnail is read as it is, not regenerated', () async {
    final source = await write('kept.png', img.encodePng(quadrants(832, 1216)));
    await source.setLastModified(DateTime(2025));
    // Written by the previous (Dart) generator.
    final legacy = await service.renderThumbnail(
      source.path,
      size: ThumbnailSize.small,
      engine: false,
    );
    final cached = File(
      p.join(directory.path, '.thumbs', 'kept.png.small.thumb.jpg'),
    );
    final existing = await service.getThumbnailPath(source.path);
    final path = existing ?? cached.path;
    await File(path).parent.create(recursive: true);
    await File(path).writeAsBytes(legacy);
    expect(await service.getOrGenerateThumbnail(source.path), path);
    expect(await File(path).readAsBytes(), legacy);
    expect(service.getStats()['generatedCount'], 0);
  });

  test('at most two thumbnails are generated at once', () async {
    final files = [
      for (var i = 0; i < 8; i++)
        await write('many_$i.png', img.encodePng(quadrants(832, 1216))),
    ];
    var peak = 0;
    final sampler = Timer.periodic(const Duration(milliseconds: 2), (_) {
      final active = service.getStats()['activeGenerations'] as int;
      if (active > peak) peak = active;
    });
    final paths = await Future.wait([
      for (final file in files) service.getOrGenerateThumbnail(file.path),
    ]);
    sampler.cancel();
    expect(paths.whereType<String>(), hasLength(files.length));
    expect(service.getStats()['engineDecodes'], files.length);
    expect(peak, inInclusiveRange(1, 2));
    expect(ThumbnailCacheService.maxConcurrentGenerations, 2);
  });
}
