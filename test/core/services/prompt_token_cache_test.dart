import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';

class _Encoder extends PromptTokenEncoder {
  final calls = <String>[];
  Completer<int>? gate;
  bool fail = false;
  @override
  Future<int> countTokens(String text) async {
    calls.add(text);
    if (fail) throw StateError('synthetic encoder failure');
    return gate?.future ?? text.length;
  }
}

void main() {
  test(
    'breakdown, totals and concurrent contributions share normalized encodes',
    () async {
      final encoder = _Encoder()..gate = Completer<int>();
      final service = PromptTokenCounterService(encoder: encoder);
      final first = service.countTokensForTexts(['1.2::blue sky::']);
      final second = service.countUsageFromTexts(
        model: 'nai-diffusion-5-full',
        mainText: 'blue sky',
      );
      await Future<void>.delayed(Duration.zero);
      expect(encoder.calls, ['blue sky']);
      encoder.gate!.complete(17);
      expect(await first, 17);
      final usage = (await second)!;
      expect(usage.usedTokens, 18);
      expect(usage.limit, 1471);
      expect(
        (await service.countUsageFromTexts(
          model: 'nai-diffusion-4-5-full',
          mainText: 'blue sky',
        ))!.limit,
        512,
      );
      expect(encoder.calls, ['blue sky']);
    },
  );

  test('cache is bounded and recently used encodes survive eviction', () async {
    final encoder = _Encoder();
    final service = PromptTokenCounterService(encoder: encoder);
    for (var i = 0; i < PromptTokenCounterService.tokenCacheCapacity; i++) {
      await service.countTokensForTexts(['text-$i']);
    }
    await service.countTokensForTexts(['text-0']);
    await service.countTokensForTexts(['new']);
    final before = encoder.calls.length;
    await service.countTokensForTexts(['text-0']);
    expect(encoder.calls.length, before);
    await service.countTokensForTexts(['text-1']);
    expect(encoder.calls.length, before + 1);
  });

  test('failed encodes are retried and do not poison later totals', () async {
    final encoder = _Encoder()..fail = true;
    final service = PromptTokenCounterService(encoder: encoder);
    await expectLater(service.countTokensForTexts(['retry']), throwsStateError);
    encoder.fail = false;
    expect(await service.countTokensForTexts(['retry']), 5);
    expect(encoder.calls, ['retry', 'retry']);
  });
}
