import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PromptTokenCounterService', () {
    test(
      'countUsage should aggregate base prompt and enabled character prompts for V4.5',
      () async {
        final service = PromptTokenCounterService(
          encoder: _FakePromptTokenEncoder({
            'masterpiece, best quality': 4,
            '1girl, blue dress': 3,
          }),
        );

        final result = await service.countUsage(
          model: 'nai-diffusion-4-5-full',
          basePrompt: 'masterpiece, best quality',
          characters: [
            CharacterPrompt.create(name: 'A', prompt: '1girl, blue dress'),
            CharacterPrompt.create(
              name: 'B',
              prompt: 'ignored',
              thumbnailPath: null,
            ).copyWith(enabled: false),
            CharacterPrompt.create(name: 'C', prompt: ''),
          ],
        );

        expect(result, isNotNull);
        expect(result!.usedTokens, equals(8));
        expect(result.limit, equals(512));
        expect(result.isOverLimit, isFalse);
      },
    );

    test('countUsage should use the V5 token limit for V5 models', () async {
      final service = PromptTokenCounterService(
        encoder: _FakePromptTokenEncoder({'prompt': 400, 'character': 140}),
      );

      final result = await service.countUsage(
        model: 'nai-diffusion-5-full',
        basePrompt: 'prompt',
        characters: [CharacterPrompt.create(name: 'A', prompt: 'character')],
      );

      expect(result, isNotNull);
      expect(result!.usedTokens, equals(541));
      expect(result.limit, equals(1471));
      expect(result.isOverLimit, isFalse);
    });

    test(
      'countUsage should report over-limit usage for supported V4 models',
      () async {
        final service = PromptTokenCounterService(
          encoder: _FakePromptTokenEncoder({'prompt': 400, 'character': 140}),
        );

        final result = await service.countUsage(
          model: 'nai-diffusion-4-full',
          basePrompt: 'prompt',
          characters: [CharacterPrompt.create(name: 'A', prompt: 'character')],
        );

        expect(result, isNotNull);
        expect(result!.usedTokens, equals(541));
        expect(result.isOverLimit, isTrue);
      },
    );

    test('countUsage should return null for unsupported models', () async {
      final service = PromptTokenCounterService(
        encoder: _FakePromptTokenEncoder({'prompt': 12}),
      );

      final result = await service.countUsage(
        model: 'nai-diffusion-3',
        basePrompt: 'prompt',
        characters: const [],
      );

      expect(result, isNull);
    });

    test('createDefault should load bundled T5 tokenizer asset', () async {
      final service = await PromptTokenCounterService.createDefault();

      final result = await service.countUsage(
        model: 'nai-diffusion-4-5-full',
        basePrompt: 'masterpiece, best quality',
        characters: const [],
      );

      expect(result, isNotNull);
      expect(result!.usedTokens, greaterThan(0));
      expect(result.limit, equals(512));
    });

    test(
      'countUsageFromTexts should aggregate main text and extra texts',
      () async {
        final service = PromptTokenCounterService(
          encoder: _FakePromptTokenEncoder({
            'masterpiece, best quality': 4,
            '1girl, blue dress': 3,
            'bad hands': 2,
          }),
        );

        final result = await service.countUsageFromTexts(
          model: 'nai-diffusion-4-5-full',
          mainText: 'masterpiece, best quality',
          extraTexts: const ['[1girl, blue dress]', '', 'bad hands'],
        );

        expect(result, isNotNull);
        expect(result!.usedTokens, equals(10));
        expect(result.limit, equals(512));
      },
    );

    test(
      'countUsageFromTexts should strip NAI weight syntax before token counting',
      () async {
        final service = PromptTokenCounterService(
          encoder: _FakePromptTokenEncoder({
            'simple_illustration, artist_collaboration, purple pupils, telephoto_lens':
                17,
          }),
        );

        final result = await service.countUsageFromTexts(
          model: 'nai-diffusion-4-5-full',
          mainText:
              '-3::simple_illustration::, -4::artist_collaboration::, {{{{purple pupils}}}}, 1.3::telephoto_lens::',
        );

        expect(result, isNotNull);
        expect(result!.usedTokens, equals(18));
        expect(result.limit, equals(512));
      },
    );

    test(
      'countUsageFromTexts should preserve existing comma spacing while stripping weight syntax',
      () async {
        final service = PromptTokenCounterService(
          encoder: _FakePromptTokenEncoder({
            'artist:a,artist:b, telephoto_lens': 9,
          }),
        );

        final result = await service.countUsageFromTexts(
          model: 'nai-diffusion-4-5-full',
          mainText: 'artist:a,artist:b, 1.3::telephoto_lens::',
        );

        expect(result, isNotNull);
        expect(result!.usedTokens, equals(10));
      },
    );

    test(
      'countTokensForTexts should keep raw subtotal when web adjustment is off',
      () async {
        final service = PromptTokenCounterService(
          encoder: _FakePromptTokenEncoder({'prompt': 4, 'quality': 2}),
        );

        final tokens = await service.countTokensForTexts(const [
          'prompt',
          'quality',
        ]);

        expect(tokens, equals(6));
      },
    );
  });
}

class _FakePromptTokenEncoder implements PromptTokenEncoder {
  _FakePromptTokenEncoder(this._counts);

  final Map<String, int> _counts;

  @override
  Future<int> countTokens(String text) async => _counts[text] ?? text.length;
}
