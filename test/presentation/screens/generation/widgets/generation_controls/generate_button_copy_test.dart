import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button_copy.dart';

void main() {
  group('GenerateButtonCopy.pick', () {
    test('同一种子结果稳定，种子变化换文案', () {
      final a = GenerateButtonCopy.pick(
        seed: 3,
        count: 2,
        languageCode: 'zh',
      );
      final b = GenerateButtonCopy.pick(
        seed: 3,
        count: 2,
        languageCode: 'zh',
      );
      final c = GenerateButtonCopy.pick(
        seed: 4,
        count: 2,
        languageCode: 'zh',
      );
      expect(a, b);
      expect(a, isNot(c));
    });

    test('每个数量档与语言都能产出非空文案且包含正确的数字（如适用）', () {
      for (final lang in ['zh', 'en', 'ja', 'fr']) {
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

    test('特殊数字彩蛋优先于常规区间（避开稀有池种子）', () {
      final text = GenerateButtonCopy.pick(
        seed: 1,
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
      final one = GenerateButtonCopy.debugPoolFor(
        languageCode: 'en',
        count: 1,
      );
      final five = GenerateButtonCopy.debugPoolFor(
        languageCode: 'en',
        count: 5,
      );
      expect(one, isNot(same(five)));
      expect(one.length, greaterThanOrEqualTo(10));
    });
  });
}
