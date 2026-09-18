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
