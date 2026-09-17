import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';

void main() {
  group('Samplers.samplersForModel', () {
    test('V5 model excludes DDIM and DPM++ SDE (mirrors official site)', () {
      final samplers = Samplers.samplersForModel('nai-diffusion-5-full');
      expect(samplers, hasLength(5));
      expect(samplers, contains(Samplers.kEulerAncestral));
      expect(samplers, contains(Samplers.kEuler));
      expect(samplers, isNot(contains(Samplers.ddim)));
      expect(samplers, isNot(contains(Samplers.ddimV3)));
      expect(samplers, isNot(contains(Samplers.kDpmppSde)));
    });

    test('V4.5 model excludes DDIM but keeps k-diffusion set', () {
      final samplers = Samplers.samplersForModel('nai-diffusion-4-5-full');
      expect(samplers, hasLength(6));
      expect(samplers, contains(Samplers.kDpmppSde));
      expect(samplers, isNot(contains(Samplers.ddim)));
      expect(samplers, isNot(contains(Samplers.ddimV3)));
    });

    test('V3-era model keeps the full list including DDIM', () {
      final samplers =
          Samplers.samplersForModel('nai-diffusion-3');
      expect(samplers, contains(Samplers.ddim));
      expect(samplers, contains(Samplers.ddimV3));
      expect(samplers, hasLength(Samplers.allSamplers.length));
    });
  });

  group('Samplers.recommendedSamplers', () {
    test('recommended group is Euler Ancestral only', () {
      expect(Samplers.recommendedSamplers, [Samplers.kEulerAncestral]);
    });
  });
}
