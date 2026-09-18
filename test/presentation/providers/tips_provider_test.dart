import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final localizations = <String, AppLocalizations>{
    for (final locale in AppLocalizations.supportedLocales)
      locale.languageCode: lookupAppLocalizations(locale),
  };

  group('pickTip', () {
    test('returns a non-empty tip for every module in every locale', () {
      for (final l10n in localizations.values) {
        for (final module in TipModule.values) {
          for (var seed = 0; seed < 10; seed++) {
            expect(
              pickTip(l10n, module, random: Random(seed)),
              isNotEmpty,
              reason: '${l10n.localeName} / $module',
            );
          }
        }
      }
    });

    test('same epoch yields a stable pick', () {
      final l10n = localizations['en']!;
      final a = pickTip(l10n, TipModule.gen, epoch: 42);
      final b = pickTip(l10n, TipModule.gen, epoch: 42);
      expect(a, b);
    });

    test('different modules draw from their own pools', () {
      final l10n = localizations['en']!;
      final blocklibTips = {
        for (final key in [
          l10n.tips_blocklib_teach_1,
          l10n.tips_blocklib_teach_2,
          l10n.tips_blocklib_teach_3,
          l10n.tips_blocklib_teach_4,
          l10n.tips_blocklib_teach_5,
          l10n.tips_blocklib_fun_1,
          l10n.tips_blocklib_fun_2,
          l10n.tips_blocklib_fun_3,
          l10n.tips_blocklib_fun_4,
          l10n.tips_blocklib_fun_5,
        ])
          key,
      };
      final genericTips = {
        l10n.tips_gen_1,
        l10n.tips_gen_2,
        l10n.tips_gen_3,
        l10n.tips_gen_4,
        l10n.tips_gen_5,
        l10n.tips_fun_1,
        l10n.tips_fun_2,
        l10n.tips_fun_3,
        l10n.tips_fun_4,
        l10n.tips_fun_5,
      };
      final foreignTips = {
        l10n.tips_explore_fun_1,
        l10n.tips_gallerySearch_fun_1,
        l10n.tips_gen_fun_1,
      };

      var sawModuleSpecific = false;
      for (var seed = 0; seed < 200; seed++) {
        final tip = pickTip(l10n, TipModule.blockLibrary, random: Random(seed));
        expect(foreignTips.contains(tip), isFalse);
        expect(
          blocklibTips.contains(tip) || genericTips.contains(tip),
          isTrue,
          reason: tip,
        );
        if (blocklibTips.contains(tip)) sawModuleSpecific = true;
      }
      expect(sawModuleSpecific, isTrue);
    });

    test('gallerySearch start pool wins on mount epoch only', () {
      final l10n = localizations['en']!;
      final startTips = {
        for (final getter in [
          l10n.tips_gallerySearch_start_1,
          l10n.tips_gallerySearch_start_2,
          l10n.tips_gallerySearch_start_3,
          l10n.tips_gallerySearch_start_4,
          l10n.tips_gallerySearch_start_5,
          l10n.tips_gallerySearch_start_6,
          l10n.tips_gallerySearch_start_7,
          l10n.tips_gallerySearch_start_8,
          l10n.tips_gallerySearch_start_9,
          l10n.tips_gallerySearch_start_10,
        ])
          getter,
      };

      // 挂载轮次内：必然来自启动池。
      for (var seed = 0; seed < 50; seed++) {
        expect(
          startTips.contains(
            pickTip(
              l10n,
              TipModule.gallerySearch,
              epoch: 7,
              firstEpoch: 7,
              random: Random(seed),
            ),
          ),
          isTrue,
        );
      }
      // 进入下一轮：恢复常规配比，不再命中启动池文案。
      var sawNonStart = false;
      for (var seed = 0; seed < 400; seed++) {
        final tip = pickTip(
          l10n,
          TipModule.gallerySearch,
          epoch: 8,
          firstEpoch: 7,
          random: Random(seed),
        );
        expect(startTips.contains(tip), isFalse, reason: tip);
        if (tip.isNotEmpty) sawNonStart = true;
      }
      expect(sawNonStart, isTrue);
    });

    test('explore module can draw generic pool (50% share)', () {
      final l10n = localizations['en']!;
      final genericTips = {
        l10n.tips_gen_1,
        l10n.tips_gen_2,
        l10n.tips_gen_3,
        l10n.tips_gen_4,
        l10n.tips_gen_5,
        l10n.tips_fun_1,
        l10n.tips_fun_2,
        l10n.tips_fun_3,
        l10n.tips_fun_4,
        l10n.tips_fun_5,
      };
      var sawGeneric = false;
      var sawTeach = false;
      for (var seed = 0; seed < 400; seed++) {
        final tip = pickTip(l10n, TipModule.explore, random: Random(seed));
        if (genericTips.contains(tip)) sawGeneric = true;
        if (tip.startsWith('Heart + folder')) sawTeach = true;
      }
      expect(sawGeneric, isTrue);
      expect(sawTeach, isTrue);
    });
  });

  group('tipHint', () {
    test('prefixes Tip:', () {
      for (final l10n in localizations.values) {
        expect(
          tipHint(l10n, TipModule.gen, random: Random(1)),
          startsWith('Tip: '),
        );
      }
    });
  });

  group('tipEpochProvider', () {
    test('emits the current epoch on first listen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final epoch = await container.read(tipEpochProvider.future);
      expect(epoch, currentTipEpoch());
    });
  });
}
