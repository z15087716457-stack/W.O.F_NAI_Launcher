import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/core/utils/max_enhance_utils.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import '../nai_agent/generation_binding_test.dart' show GenerationTestAuth;

void main() {
  test(
    'Max quote uses the native target dimensions and cannot retain source-size Opus free pricing',
    () {
      final container = ProviderContainer(
        overrides: [authNotifierProvider.overrideWith(GenerationTestAuth.new)],
      );
      addTearDown(container.dispose);
      const p = ImageParams(
        model: 'nai-diffusion-5-curated',
        width: 832,
        height: 1216,
        steps: 28,
        action: ImageGenerationAction.img2img,
        strength: .5,
        upscaledEnhance: true,
      );
      final target = MaxEnhanceMath.targetSize(p.width, p.height);
      final expected = AnlasCalculator.calculateRequestCost(
        width: target.width,
        height: target.height,
        steps: p.steps,
        model: p.model,
        strength: p.strength,
        subscriptionTier: AnlasCalculator.opusTier,
        batchCount: 1,
        batchSize: 1,
        smea: false,
        smeaDyn: false,
      );
      expect(expected, greaterThan(0));
      final actual = container.read(
        Provider((ref) => readBridgeBilling(ref, p)),
      );
      expect(actual['estimated_anlas'], expected);
      expect(actual['per_request_anlas'], expected);
      for (final plain in [
        p.copyWith(upscaledEnhance: false),
        p.copyWith(model: 'nai-diffusion-4-5-full'),
      ]) {
        expect(
          container.read(
            Provider((ref) => readBridgeBilling(ref, plain)),
          )['estimated_anlas'],
          0,
        );
      }
    },
  );
}
