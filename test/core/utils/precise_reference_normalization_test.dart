import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/nai_api_utils.dart';

void main() {
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
