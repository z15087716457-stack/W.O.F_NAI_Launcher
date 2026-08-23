import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/utils/gallery_model_labels.dart';

void main() {
  group('galleryModelFriendlyName', () {
    test('maps known models to friendly names', () {
      expect(galleryModelFriendlyName('nai-diffusion-3'), 'NAI 3');
      expect(galleryModelFriendlyName('nai-diffusion-furry-3'), 'Furry 3');
      expect(
        galleryModelFriendlyName('nai-diffusion-4-curated-preview'),
        'NAI 4 Curated',
      );
      expect(galleryModelFriendlyName('nai-diffusion-4-full'), 'NAI 4 Full');
      expect(
        galleryModelFriendlyName('nai-diffusion-4-5-curated'),
        'NAI 4.5 Curated',
      );
      expect(galleryModelFriendlyName('nai-diffusion-4-5-full'), 'NAI 4.5 Full');
      expect(
        galleryModelFriendlyName('nai-diffusion-5-curated'),
        'NAI 5 Curated',
      );
      expect(galleryModelFriendlyName('nai-diffusion-5-full'), 'NAI 5 Full');
    });

    test('returns unknown models verbatim', () {
      expect(
        galleryModelFriendlyName('some-custom-model'),
        'some-custom-model',
      );
      expect(galleryModelFriendlyName(''), '');
    });
  });
}
