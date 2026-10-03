import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final localizations = {
    for (final locale in AppLocalizations.supportedLocales)
      locale.toLanguageTag(): lookupAppLocalizations(locale),
  };
  final zh = localizations['zh']!;
  final day = DateTime(2026, 5, 1, 14);
  final night = DateTime(2026, 5, 1, 3);

  group('catalog', () {
    test('every surface has guides and copy in every locale', () {
      for (final surface in TipSurface.values) {
        final tips = tipsFor(surface);
        expect(tips, isNotEmpty, reason: '$surface');
        for (final l10n in localizations.values) {
          for (final tip in tips) {
            expect(tip.text(l10n).trim(), isNotEmpty);
            expect(tip.label(l10n).trim(), isNotEmpty);
          }
        }
        if (surface.leadsWithGuide) {
          expect(tips.where((tip) => tip.kind == TipKind.guide), isNotEmpty);
        }
      }
    });

    test('tips never repeat their own speaker label', () {
      for (final l10n in localizations.values) {
        for (final surface in TipSurface.values) {
          for (final tip in tipsFor(surface)) {
            final label = tip.label(l10n);
            expect(
              RegExp(
                '^${RegExp.escape(label)}'
                r'\s*[:：]',
              ).hasMatch(tip.text(l10n)),
              isFalse,
              reason: tip.text(l10n),
            );
          }
        }
      }
    });

    test('hint keeps the kind label in front of the text', () {
      final tip = tipsFor(TipSurface.prompt).first;
      expect(tip.hint(zh), '${zh.tips_kind_guide}：${tip.text(zh)}');
      final en = localizations['en']!;
      expect(tip.hint(en), '${en.tips_kind_guide}: ${tip.text(en)}');
    });

    test('the narrow prompt box has enough short tips of each kind', () {
      final short = tipsFor(TipSurface.prompt).where((tip) => tip.short);
      for (final kind in TipKind.values) {
        expect(short.where((tip) => tip.kind == kind), isNotEmpty);
      }
    });

    test('single-line surfaces stay short in every locale', () {
      // 搜索框与占位卡只有一行；超长会被省略号截断。
      const limits = {'zh': 20, 'zh-TW': 20, 'ja': 27, 'ko': 29, 'en': 55};
      for (final surface in [
        TipSurface.gallerySearch,
        TipSurface.onlineSearch,
        TipSurface.blockSearch,
        TipSurface.generating,
      ]) {
        for (final entry in localizations.entries) {
          for (final tip in tipsFor(surface)) {
            expect(
              tip.text(entry.value).runes.length,
              lessThanOrEqualTo(limits[entry.key]!),
              reason: '${entry.key} $surface ${tip.text(entry.value)}',
            );
          }
        }
      }
    });
  });

  group('TipDeck', () {
    test('walks a full shuffled cycle before repeating', () {
      final deck = TipDeck(seed: 7);
      for (final surface in TipSurface.values) {
        final daytime = tipsFor(surface).where((tip) => !tip.night).toList();
        final seen = [
          for (var i = 0; i < daytime.length; i++)
            deck.tipAt(surface, i, now: day),
        ];
        expect(seen.toSet(), daytime.toSet(), reason: '$surface');
        expect(deck.tipAt(surface, daytime.length, now: day), seen.first);
      }
    });

    test('night tips only appear at night', () {
      final deck = TipDeck(seed: 3);
      final tips = tipsFor(TipSurface.studio);
      expect(tips.where((tip) => tip.night), isNotEmpty);
      final dayTips = {
        for (var i = 0; i < tips.length * 2; i++)
          deck.tipAt(TipSurface.studio, i, now: day),
      };
      expect(dayTips.where((tip) => tip.night), isEmpty);
      final nightTips = {
        for (var i = 0; i < tips.length; i++)
          deck.tipAt(TipSurface.studio, i, now: night),
      };
      expect(nightTips, tips.toSet());
    });

    test('shortOnly and kind filters', () {
      final deck = TipDeck(seed: 1);
      for (var i = 0; i < 30; i++) {
        expect(
          deck.tipAt(TipSurface.prompt, i, now: day, shortOnly: true).short,
          isTrue,
        );
        expect(
          deck
              .tipAt(TipSurface.gallerySearch, i, now: day, kind: TipKind.guide)
              .kind,
          TipKind.guide,
        );
      }
    });

    test('the same seed gives the same order', () {
      final a = TipDeck(seed: 42);
      final b = TipDeck(seed: 42);
      for (var i = 0; i < 20; i++) {
        expect(
          a.tipAt(TipSurface.prompt, i, now: day),
          b.tipAt(TipSurface.prompt, i, now: day),
        );
      }
    });

    test('draw hands out the next tip on every visit', () {
      final deck = TipDeck(seed: 5);
      final count = tipsFor(TipSurface.lab).length;
      final drawn = {
        for (var i = 0; i < count; i++) deck.draw(TipSurface.lab, now: day),
      };
      expect(drawn.length, count);
    });
  });

  group('rotatingTip', () {
    test('stays put within an epoch and moves on the next', () {
      final deck = TipDeck(seed: 9);
      final a = rotatingTip(deck, TipSurface.prompt, epoch: 100, now: day);
      expect(rotatingTip(deck, TipSurface.prompt, epoch: 100, now: day), a);
      expect(
        rotatingTip(deck, TipSurface.prompt, epoch: 101, now: day),
        isNot(a),
      );
    });

    test('slots keep side-by-side character boxes apart', () {
      final deck = TipDeck(seed: 9);
      expect(
        rotatingTip(deck, TipSurface.character, epoch: 5, slot: 0, now: day),
        isNot(
          rotatingTip(deck, TipSurface.character, epoch: 5, slot: 1, now: day),
        ),
      );
    });

    test('search boxes open with a usage guide', () {
      final deck = TipDeck(seed: 11);
      for (final surface in [
        TipSurface.gallerySearch,
        TipSurface.onlineSearch,
      ]) {
        for (var epoch = 0; epoch < 30; epoch++) {
          expect(
            rotatingTip(
              deck,
              surface,
              epoch: epoch,
              firstEpoch: epoch,
              now: day,
            ).kind,
            TipKind.guide,
          );
        }
        final later = {
          for (var epoch = 1; epoch < 60; epoch++)
            rotatingTip(
              deck,
              surface,
              epoch: epoch,
              firstEpoch: 0,
              now: day,
            ).kind,
        };
        expect(later, containsAll([TipKind.trick, TipKind.wolf]));
      }
    });
  });

  test('deep night is 01:00–04:59 local time', () {
    expect(isTipNight(DateTime(2026, 1, 1, 0, 59)), isFalse);
    expect(isTipNight(DateTime(2026, 1, 1, 1)), isTrue);
    expect(isTipNight(DateTime(2026, 1, 1, 4, 59)), isTrue);
    expect(isTipNight(DateTime(2026, 1, 1, 5)), isFalse);
  });

  group('providers', () {
    test('tipEpochProvider emits the current epoch on first listen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final epoch = await container.read(tipEpochProvider.future);
      expect(epoch, currentTipEpoch());
    });

    test('the splash tip stays fixed for the session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final first = container.read(splashTipProvider);
      expect(container.read(splashTipProvider), same(first));
      expect(tipsFor(TipSurface.splash), contains(first));
    });
  });

  test('every locale resolves', () {
    expect(localizations.keys, containsAll(['zh', 'zh-TW', 'en', 'ja', 'ko']));
  });
}
