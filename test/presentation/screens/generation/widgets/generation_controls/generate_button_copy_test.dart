import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button_copy.dart';

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));
  final day = DateTime(2026, 5, 1, 14);
  final night = DateTime(2026, 5, 1, 2);

  String pick(AppLocalizations l10n, int seed, int count, {DateTime? now}) =>
      GenerateButtonCopy.pick(
        l10n: l10n,
        seed: seed,
        count: count,
        now: now ?? day,
      );

  group('GenerateButtonCopy.pick', () {
    test('most seeds show the official label', () {
      for (final seed in [1, 2, 3, 5, 6, 7, 9, 10, 11]) {
        expect(pick(zh, seed, 2), '生成 2 张图片');
      }
      expect(pick(en, 3, 1), 'Generate 1 Image');
      expect(pick(en, 3, 5), 'Generate 5 Images');
      expect(pick(lookupAppLocalizations(const Locale('ja')), 3, 2), '2 枚生成');
      expect(
        pick(lookupAppLocalizations(const Locale('ko')), 3, 2),
        '이미지 2장 생성',
      );
      expect(
        pick(lookupAppLocalizations(const Locale('zh', 'TW')), 3, 2),
        '生成 2 張圖片',
      );
    });

    test('a quarter of seeds land in the fun pools, stable per seed', () {
      final fun = [
        for (var seed = 0; seed < 400; seed++)
          if (pick(zh, seed, 3) != '生成 3 张图片') seed,
      ];
      expect(fun.length, 100);
      expect(fun.every((seed) => seed % 4 == 0), isTrue);
      expect(pick(zh, 8, 3), pick(zh, 8, 3));
    });

    test('every count and locale yields filled-in copy', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        for (var count = 1; count <= 120; count++) {
          for (var seed = 0; seed <= 24; seed++) {
            for (final now in [day, night]) {
              final text = pick(l10n, seed, count, now: now);
              expect(text, isNotEmpty, reason: '$locale/$count/$seed');
              expect(text, isNot(contains('{')));
            }
          }
        }
      }
    });

    test('counted pools always show the real number', () {
      for (final count in [2, 4, 5, 9, 10, 49, 50, 120]) {
        for (final text in GenerateButtonCopy.debugPoolFor(zh, count)) {
          expect(text, contains('$count'), reason: text);
        }
      }
    });

    test('pools follow the count buckets', () {
      expect(GenerateButtonCopy.debugPoolFor(en, 1).length, 12);
      expect(
        GenerateButtonCopy.debugPoolFor(en, 3),
        isNot(GenerateButtonCopy.debugPoolFor(en, 6)),
      );
      expect(
        GenerateButtonCopy.debugPoolFor(en, 20),
        isNot(GenerateButtonCopy.debugPoolFor(en, 60)),
      );
    });

    test('special numbers beat the regular bucket', () {
      final text = pick(zh, 4, 42);
      expect(text, contains('42'));
      expect(GenerateButtonCopy.debugPoolFor(zh, 42), isNot(contains(text)));
    });

    test('rare lines need seed % 20 == 0', () {
      expect(GenerateButtonCopy.debugRarePool(zh), contains(pick(zh, 20, 5)));
      expect(
        GenerateButtonCopy.debugRarePool(zh),
        isNot(contains(pick(zh, 4, 5))),
      );
    });

    test('night lines only show up in the small hours', () {
      final nightPool = GenerateButtonCopy.debugNightPool(zh);
      expect(nightPool, contains(pick(zh, 8, 5, now: night)));
      for (var seed = 0; seed < 200; seed++) {
        expect(nightPool, isNot(contains(pick(zh, seed, 5))));
      }
    });
  });
}
