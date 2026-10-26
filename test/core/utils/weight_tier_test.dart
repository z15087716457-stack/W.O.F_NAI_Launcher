import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/weight_tier.dart';

void main() {
  test('shared weight tiers preserve every threshold exactly', () {
    for (final (weight, expected) in [
      (-1.0, WeightTier.negative),
      (-.0001, WeightTier.negative),
      (0.0, WeightTier.bottom),
      (.3, WeightTier.bottom),
      (.4999, WeightTier.bottom),
      (.5, WeightTier.low),
      (.7, WeightTier.low),
      (.9999, WeightTier.low),
      (1.0, WeightTier.none),
      (1.0001, WeightTier.high),
      (1.5, WeightTier.high),
      (2.0, WeightTier.high),
      (2.0001, WeightTier.top),
      (2.5, WeightTier.top),
    ]) {
      expect(weightTier(weight), expected, reason: '$weight');
    }
  });
}
