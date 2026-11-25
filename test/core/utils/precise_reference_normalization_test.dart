import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/model_spec.dart';
import 'package:nai_launcher/core/utils/nai_api_utils.dart';
import 'package:nai_launcher/core/utils/isolate_pool.dart';

void main() {
  final v45 = ModelSpecs.of(ImageModels.animeDiffusionV45Full);
  final v5 = ModelSpecs.of(ImageModels.animeDiffusionV5Full);

  test('selects the closest of 97 buckets by log aspect', () {
    expect(v5PreciseReferenceBuckets.toSet(), hasLength(97));
    for (final (width, height) in v5PreciseReferenceBuckets) {
      expect(computeV5PreciseReferenceBucket(width, height), (width, height));
    }
    expect(computeV5PreciseReferenceBucket(5, 4), (1152, 896));
    expect(computeV5PreciseReferenceBucket(4, 5), (896, 1152));
    expect(computeV5PreciseReferenceBucket(80, 2), (4096, 256));
    expect(computeV5PreciseReferenceBucket(2, 80), (256, 4096));
    expect(computeV5PreciseReferenceBucket(0, 0), (1024, 1024));
  });

  test(
    'V5 center-crops and caches separately from V4.5 letterboxing',
    () async {
      final source = img.Image(width: 180, height: 10);
      for (final pixel in source) {
        final middle = pixel.x >= 7 && pixel.x < 173;
        pixel.setRgb(middle ? 0 : 240, middle ? 180 : 0, 0);
      }
      final raw = img.encodePng(source);
      final before = Uint8List.fromList(raw);
      final firstV5 = NAIApiUtils.normalizePreciseReferenceForModel(raw, v5);
      final firstV45 = NAIApiUtils.normalizePreciseReferenceForModel(raw, v45);
      expect(
        NAIApiUtils.normalizePreciseReferenceForModel(raw, v5),
        same(firstV5),
      );
      expect(
        NAIApiUtils.normalizePreciseReferenceForModel(raw, v45),
        same(firstV45),
      );
      final bucketedBytes = await firstV5;
      final letterboxedBytes = await firstV45;
      final bucketed = img.decodePng(bucketedBytes)!;
      final letterboxed = img.decodePng(letterboxedBytes)!;
      expect((bucketed.width, bucketed.height), (4096, 256));
      for (final (x, y) in [(0, 0), (4095, 255), (2048, 128)]) {
        expect(bucketed.getPixel(x, y).g, 180);
        expect(bucketed.getPixel(x, y).r, 0);
      }
      expect((letterboxed.width, letterboxed.height), (1536, 1024));
      expect(letterboxed.getPixel(0, 0).g, 0);
      expect(
        await NAIApiUtils.normalizePreciseReferenceForModel(raw, v5),
        same(bucketedBytes),
      );
      expect(
        await NAIApiUtils.normalizePreciseReferenceForModel(raw, v45),
        same(letterboxedBytes),
      );
      expect(raw, before);
      expect(NAIApiUtils.isKnownNormalizedPreciseReferencePng(raw), isFalse);
      expect(
        NAIApiUtils.isKnownNormalizedPreciseReferencePng(bucketedBytes),
        isFalse,
      );
    },
  );

  test(
    'V5 returns existing bucket PNG by identity and converts matching JPEG',
    () async {
      final image = img.Image(width: 1024, height: 1024);
      final png = img.encodePng(image);
      final jpeg = img.encodeJpg(image);
      expect(
        await NAIApiUtils.normalizePreciseReferenceForModel(png, v5),
        same(png),
      );
      final converted = await NAIApiUtils.normalizePreciseReferenceForModel(
        jpeg,
        v5,
      );
      final decoded = img.decodePng(converted)!;
      expect((decoded.width, decoded.height), (1024, 1024));
    },
  );

  test(
    'multi-file normalization cannot bypass the shared compute limit',
    () async {
      final gate = ComputeGate();
      final release = Completer<void>();
      final entered = [
        for (var i = 0; i < gate.maxConcurrentTasks; i++) Completer<void>(),
      ];
      final blockers = [
        for (final started in entered)
          gate.run(() async {
            started.complete();
            await release.future;
          }),
      ];
      await Future.wait(entered.map((e) => e.future));
      var completed = 0;
      final conversions = [
        for (var i = 0; i < 8; i++)
          NAIApiUtils.ensurePngFormatAsync(Uint8List(32)..[0] = i).then((
            bytes,
          ) {
            completed++;
            return bytes;
          }),
      ];
      // All permits are held. Even invalid images must queue, not spawn isolates.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final blockedCount = completed;
      release.complete();
      await Future.wait(blockers);
      await Future.wait(conversions);
      expect(blockedCount, 0);
      expect(completed, 8);
    },
  );

  test(
    '832x1216 PNG uses byte-identical normalization; record isolated timing',
    () async {
      final raw = Uint8List.fromList(
        img.encodePng(
          img.fill(
            img.Image(width: 832, height: 1216),
            color: img.ColorRgb8(40, 80, 120),
          ),
        ),
      );
      final clock = Stopwatch()..start();
      final normalized = await NAIApiUtils.normalizePreciseReference(raw);
      clock.stop();
      // ignore: avoid_print
      print('PRECISE_NORMALIZE_832x1216_MS=${clock.elapsedMilliseconds}');
      expect(normalized, NAIApiUtils.ensurePngFormat(raw));
      final decoded = img.decodePng(normalized)!;
      expect((decoded.width, decoded.height), (1024, 1536));
      expect(
        NAIApiUtils.isKnownNormalizedPreciseReferencePng(normalized),
        true,
      );
    },
  );

  test('shared future cleans up after a failure and allows retry', () async {
    final raw = Uint8List.fromList([1, 2, 3]);
    final gate = Completer<Uint8List>();
    var calls = 0;
    Future<Uint8List> normalize(Uint8List _) {
      calls++;
      return gate.future;
    }

    final first = NAIApiUtils.normalizePreciseReference(
      raw,
      normalize: normalize,
    );
    final second = NAIApiUtils.normalizePreciseReference(
      raw,
      normalize: normalize,
    );
    expect(second, same(first));
    final rejected = expectLater(first, throwsStateError);
    gate.completeError(StateError('fixture'));
    await rejected;
    expect(calls, 1);
    final retry = await NAIApiUtils.normalizePreciseReference(
      raw,
      normalize: (_) async => Uint8List.fromList([4]),
    );
    expect(retry, [4]);
  });
}
