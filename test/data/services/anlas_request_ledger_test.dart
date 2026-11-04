import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/services/anlas_calculator.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/services/anlas_request_ledger.dart';

import '../../helpers/app_logger_test_isolation.dart';

const _opus = UserSubscription(
  tier: 3,
  active: true,
  trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 100),
);

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  test('a charge records once, and only when NovelAI delivered', () async {
    final records = <int>[];
    final ledger = AnlasRequestLedger(
      readAccount: () => null,
      record: (anlas, _) async => records.add(anlas),
    );
    final charge = ledger.vibeEncoding();
    await pumpEventQueue();
    expect(records, isEmpty);
    charge
      ..delivered()
      ..delivered();
    await pumpEventQueue();
    expect(records, [AnlasCalculator.vibeEncodingCost]);
  });

  test('a request priced as free records 0', () async {
    final records = <int>[];
    final ledger = AnlasRequestLedger(
      readAccount: () => _opus,
      record: (anlas, _) async => records.add(anlas),
    );
    const request = ImageParams(
      prompt: 'synthetic',
      model: ImageModels.animeDiffusionV45Full,
    );
    ledger.generation(request).delivered();
    // Two images: the second one of the request is not free.
    ledger.generation(request.copyWith(nSamples: 2)).delivered();
    await pumpEventQueue();
    expect(records, [0, 20]);
  });

  test('a generation is priced on the request it sends', () {
    final ledger = AnlasRequestLedger(
      readAccount: () => _opus,
      record: (_, __) async {},
    );
    int price(ImageParams request) => ledger.generation(request).anlas;
    // V4 832×1216, three images: the first free on Opus, two at 20.
    expect(price(const ImageParams(prompt: 'synthetic', nSamples: 3)), 40);
    // V5 1024×1536 image to image at 0.4: 30 × 1.5 × 0.4; over 1 MP, so
    // not free.
    expect(
      price(
        const ImageParams(
          prompt: 'synthetic',
          model: ImageModels.animeDiffusionV5Full,
          width: 1024,
          height: 1536,
          action: ImageGenerationAction.img2img,
          strength: 0.4,
        ),
      ),
      18,
    );
    // V5 Max enhance of 1024×1024 at 0.7: priced on the 1760×1760 the
    // server upscales to (60 × 1.5 × 0.7), not on the source.
    expect(
      price(
        const ImageParams(
          prompt: 'synthetic',
          model: ImageModels.animeDiffusionV5Full,
          width: 1024,
          height: 1024,
          action: ImageGenerationAction.img2img,
          enhanceWorkflow: true,
          upscaledEnhance: true,
        ),
      ),
      63,
    );
  });

  test('a request without a price records nothing', () async {
    final records = <int>[];
    final ledger = AnlasRequestLedger(
      readAccount: () => null,
      record: (anlas, _) async => records.add(anlas),
    );
    // Beyond the largest priced upscale input.
    final charge = ledger.upscale(width: 4096, height: 4096);
    expect(charge.anlas, AnlasCalculator.invalidCost);
    charge.delivered();
    await pumpEventQueue();
    expect(records, isEmpty);
  });

  test('pricing or recording that fails never reaches the request', () async {
    final unpriced = AnlasRequestLedger(
      readAccount: () => throw StateError('no account'),
      record: (_, __) async => fail('an unpriced request was recorded'),
    );
    final charge = unpriced.generation(const ImageParams(prompt: 'synthetic'));
    expect(charge.anlas, AnlasCalculator.invalidCost);
    charge.delivered();
    AnlasRequestLedger(
      readAccount: () => null,
      record: (_, __) => throw StateError('statistics unavailable'),
    ).vibeEncoding().delivered();
    AnlasRequestLedger(
      readAccount: () => null,
      record: (_, __) async => throw StateError('preferences not saved'),
    ).vibeEncoding().delivered();
    await pumpEventQueue();
  });
}
