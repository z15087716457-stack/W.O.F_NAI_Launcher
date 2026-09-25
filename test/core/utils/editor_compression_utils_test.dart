import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/editor_compression_utils.dart';

void main() {
  group('EditorCompressionPlan', () {
    test('uses aspect-preserving Normal and one-lower targets', () {
      final wide = EditorCompressionPlan.resolve(
        workWidth: 2560,
        workHeight: 896,
      );
      expect((wide.normalTarget.width, wide.normalTarget.height), (1728, 576));
      expect(
        (wide.minimumTarget.width, wide.minimumTarget.height),
        (1664, 576),
      );

      final twoToOne = EditorCompressionPlan.resolve(
        workWidth: 2560,
        workHeight: 1280,
      );
      expect(
        (twoToOne.normalTarget.width, twoToOne.normalTarget.height),
        (1408, 704),
      );
      expect(
        (twoToOne.minimumTarget.width, twoToOne.minimumTarget.height),
        (1344, 640),
      );

      final portrait = EditorCompressionPlan.resolve(
        workWidth: 832,
        workHeight: 1216,
      );
      expect(
        (portrait.normalTarget.width, portrait.normalTarget.height),
        (832, 1216),
      );
      expect(
        (portrait.minimumTarget.width, portrait.minimumTarget.height),
        (768, 1152),
      );
    });

    test('keeps exact work size as the uncompressed endpoint', () {
      final plan = EditorCompressionPlan.resolve(
        workWidth: 1001,
        workHeight: 1003,
      );

      expect(plan.highestTarget.isOriginal, isTrue);
      expect(
        (plan.highestTarget.width, plan.highestTarget.height),
        (1001, 1003),
      );
      expect(
        plan.targets.where((target) => !target.isOriginal),
        everyElement(
          isA<EditorCompressionTarget>()
              .having((target) => target.width % 64, 'width grid', 0)
              .having((target) => target.height % 64, 'height grid', 0),
        ),
      );
    });

    test('disables compression below the fixed minimum target', () {
      final plan = EditorCompressionPlan.resolve(
        workWidth: 900,
        workHeight: 900,
      );

      expect((plan.minimumTarget.width, plan.minimumTarget.height), (960, 960));
      expect(plan.canCompress, isFalse);
      expect(plan.targets, hasLength(1));
      expect(plan.targets.single.isOriginal, isTrue);
    });

    test('skips oversized compressed targets over the request area limit', () {
      final plan = EditorCompressionPlan.resolve(
        workWidth: 2560,
        workHeight: 2560,
      );

      expect(plan.targets.last.isOriginal, isTrue);
      expect(plan.targets.last.area, greaterThan(3145728));
      expect(
        plan.targets.where((target) => !target.isOriginal),
        everyElement(
          isA<EditorCompressionTarget>().having(
            (target) => target.area,
            'request-compatible area',
            lessThanOrEqualTo(3145728),
          ),
        ),
      );
    });

    test('resolves the nearest target without increasing linear scale', () {
      final plan = EditorCompressionPlan.resolve(
        workWidth: 2560,
        workHeight: 1280,
      );
      final target = plan.targetAtOrBelowScale(0.55);

      expect(target.linearScaleFor(2560, 1280), lessThanOrEqualTo(0.55));
      final index = plan.indexOf(target);
      if (index + 1 < plan.targets.length) {
        expect(
          plan.targets[index + 1].linearScaleFor(2560, 1280),
          greaterThan(0.55),
        );
      }
    });
  });

  test('EditorCompressionEncoder resizes raw RGBA and encodes once', () async {
    final rgba = Uint8List(4 * 2 * 4);
    for (var index = 0; index < rgba.length; index += 4) {
      rgba[index] = 24;
      rgba[index + 1] = 48;
      rgba[index + 2] = 72;
      rgba[index + 3] = 255;
    }

    final bytes = await EditorCompressionEncoder.encodeRgbaPngAsync(
      EditorRawRgbaImage(bytes: rgba, width: 4, height: 2),
      targetWidth: 64,
      targetHeight: 64,
    );
    final decoded = img.decodeImage(bytes)!;

    expect((decoded.width, decoded.height), (64, 64));
    expect(decoded.getPixel(32, 32).r, 24);
    expect(decoded.getPixel(32, 32).g, 48);
    expect(decoded.getPixel(32, 32).b, 72);
  });
}
