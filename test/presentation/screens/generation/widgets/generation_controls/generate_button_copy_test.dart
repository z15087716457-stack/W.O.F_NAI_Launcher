import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button_copy.dart';

void main() {
  group('GenerateButtonCopy.pick', () {
    test('同一种子结果稳定，彩蛋种子与普通种子文案不同', () {
      final a = GenerateButtonCopy.pick(seed: 10, count: 2, languageCode: 'zh');
      final b = GenerateButtonCopy.pick(seed: 10, count: 2, languageCode: 'zh');
      final normal = GenerateButtonCopy.pick(
        seed: 3,
        count: 2,
        languageCode: 'zh',
      );
      expect(a, b);
      // seed 10 命中彩蛋池，seed 3 回退官方式文案
      expect(a, isNot(normal));
    });

    test('多数种子回退官方式默认文案', () {
      for (final seed in [1, 2, 3, 4, 6, 7, 8, 9]) {
        expect(
          GenerateButtonCopy.pick(seed: seed, count: 2, languageCode: 'zh'),
          '生成 2 张图片',
        );
      }
      expect(
        GenerateButtonCopy.pick(seed: 3, count: 1, languageCode: 'en'),
        'Generate 1 Image',
      );
      expect(
        GenerateButtonCopy.pick(seed: 3, count: 5, languageCode: 'en'),
        'Generate 5 Images',
      );
      expect(
        GenerateButtonCopy.pick(seed: 3, count: 2, languageCode: 'ja'),
        '2 枚生成',
      );
      expect(
        GenerateButtonCopy.pick(seed: 3, count: 2, languageCode: 'ko'),
        '이미지 2장 생성',
      );
    });

    test('每个数量档与语言都能产出非空文案且包含正确的数字（如适用）', () {
      for (final lang in ['zh', 'en', 'ja', 'ko', 'fr']) {
        for (var count = 1; count <= 120; count++) {
          for (var seed = 1; seed <= 12; seed++) {
            final text = GenerateButtonCopy.pick(
              seed: seed,
              count: count,
              languageCode: lang,
            );
            expect(text, isNotEmpty, reason: '$lang/$count/$seed');
            // 文案模板留空处必须已替换
            expect(text, isNot(contains('{count}')));
          }
        }
      }
    });

    test('特殊数字彩蛋优先于常规区间（彩蛋档内避开稀有池种子）', () {
      // seed 5：命中彩蛋档（%5==0）且非稀有档（%20!=0）
      final text = GenerateButtonCopy.pick(
        seed: 5,
        count: 42,
        languageCode: 'zh',
      );
      expect(text, contains('42'));
      // 42 属于 20-49 区间，常规池是「量产车间」风格；彩蛋必须不同
      final regular = GenerateButtonCopy.debugPoolFor(
        languageCode: 'zh',
        count: 42,
      );
      expect(regular, isNot(contains(text)));
    });

    test('种子为稀有倍数时取稀有池', () {
      final rareText = GenerateButtonCopy.pick(
        seed: 20,
        count: 5,
        languageCode: 'zh',
      );
      // 稀有池文案不在常规池里
      final regular = GenerateButtonCopy.debugPoolFor(
        languageCode: 'zh',
        count: 5,
      );
      expect(regular, isNot(contains(rareText)));
    });

    test('count 为 1 的文案池与 count 为 5 的不同', () {
      final one = GenerateButtonCopy.debugPoolFor(languageCode: 'en', count: 1);
      final five = GenerateButtonCopy.debugPoolFor(
        languageCode: 'en',
        count: 5,
      );
      expect(one, isNot(same(five)));
      expect(one.length, greaterThanOrEqualTo(10));
    });
  });
}
