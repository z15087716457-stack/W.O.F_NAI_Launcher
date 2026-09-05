import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/pill_roll_engine.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

/// P2.5 块实例随机引擎的纯函数单测。
void main() {
  group('splitTopLevelAtoms', () {
    test('splits on top-level commas and trims', () {
      expect(PillRollEngine.splitTopLevelAtoms('a, b ,c'), ['a', 'b', 'c']);
    });

    test('weight segments protect inner commas', () {
      expect(
        PillRollEngine.splitTopLevelAtoms('0.5::artist:a, 1girl::, solo'),
        ['0.5::artist:a, 1girl::', 'solo'],
      );
    });

    test('negative weight segments are protected too', () {
      expect(PillRollEngine.splitTopLevelAtoms('-2::upscaled, blurry::, x'), [
        '-2::upscaled, blurry::',
        'x',
      ]);
    });

    test('empty atoms are dropped', () {
      expect(PillRollEngine.splitTopLevelAtoms('a,, , b,'), ['a', 'b']);
    });

    test('unclosed weight prefix swallows the rest as one atom', () {
      expect(PillRollEngine.splitTopLevelAtoms('0.5::abc, def'), [
        '0.5::abc, def',
      ]);
    });

    test('hasTopLevelWeightPrefix detects weighted atoms', () {
      expect(PillRollEngine.hasTopLevelWeightPrefix('0.8::x::'), isTrue);
      expect(PillRollEngine.hasTopLevelWeightPrefix('  -1.5::x::'), isTrue);
      expect(PillRollEngine.hasTopLevelWeightPrefix('artist:a'), isFalse);
    });
  });

  group('rollInstance', () {
    const atoms = ['a', 'b', 'c', 'd'];

    PillInstanceSettings settings({
      int countMin = 1,
      int countMax = 1,
      PillRollOrder order = PillRollOrder.drawn,
      bool weightEnabled = false,
      double triggerProbability = 1.0,
    }) {
      return PillInstanceSettings(
        mode: PillRollMode.random,
        countMin: countMin,
        countMax: countMax,
        order: order,
        weightEnabled: weightEnabled,
        triggerProbability: triggerProbability,
      );
    }

    test('trigger probability 0 always yields empty', () {
      final roll = PillRollEngine.rollInstance(
        settings: settings(triggerProbability: 0.0),
        atoms: atoms,
        rng: Random(1),
      );
      expect(roll, '');
    });

    test('count 0~0 yields empty (概率性空块)', () {
      final roll = PillRollEngine.rollInstance(
        settings: settings(countMin: 0, countMax: 0),
        atoms: atoms,
        rng: Random(1),
      );
      expect(roll, '');
    });

    test('draws are distinct pool members (均匀无放回)', () {
      for (var seed = 0; seed < 20; seed++) {
        final roll = PillRollEngine.rollInstance(
          settings: settings(countMin: 3, countMax: 3),
          atoms: atoms,
          rng: Random(seed),
        );
        final drawn = roll.split(', ');
        expect(drawn.length, 3);
        expect(drawn.toSet().length, 3, reason: '无放回：不得重复');
        expect(drawn.every(atoms.contains), isTrue);
      }
    });

    test('count clamps to pool size (池不足截断)', () {
      final roll = PillRollEngine.rollInstance(
        settings: settings(countMin: 8, countMax: 10),
        atoms: atoms,
        rng: Random(7),
      );
      expect(roll.split(', ').length, atoms.length);
    });

    test('order original sorts by pool index', () {
      for (var seed = 0; seed < 20; seed++) {
        final roll = PillRollEngine.rollInstance(
          settings: settings(
            countMin: 2,
            countMax: 2,
            order: PillRollOrder.original,
          ),
          atoms: atoms,
          rng: Random(seed),
        );
        final indices = roll.split(', ').map(atoms.indexOf).toList();
        expect(indices, orderedEquals(indices.toList()..sort()));
      }
    });

    test('empty pool yields empty', () {
      final roll = PillRollEngine.rollInstance(
        settings: settings(countMin: 1, countMax: 3),
        atoms: const [],
        rng: Random(1),
      );
      expect(roll, '');
    });

    test('seeded rng makes rolls reproducible', () {
      String rollOnce() => PillRollEngine.rollInstance(
        settings: settings(countMin: 2, countMax: 3, weightEnabled: true),
        atoms: atoms,
        rng: Random(42),
      );
      expect(rollOnce(), rollOnce());
    });

    test('trigger probability splits outcomes (seeded)', () {
      var empty = 0, nonEmpty = 0;
      for (var seed = 0; seed < 30; seed++) {
        final roll = PillRollEngine.rollInstance(
          settings: settings(triggerProbability: 0.5),
          atoms: atoms,
          rng: Random(seed),
        );
        if (roll.isEmpty) {
          empty++;
        } else {
          nonEmpty++;
        }
      }
      expect(empty, greaterThan(0));
      expect(nonEmpty, greaterThan(0));
    });
  });

  group('weights', () {
    const atoms = ['alpha', 'beta'];

    test('weight wrap format w::atom:: with 0.1 grid', () {
      final roll = PillRollEngine.rollInstance(
        settings: const PillInstanceSettings(
          mode: PillRollMode.random,
          countMin: 2,
          countMax: 2,
          weightEnabled: true,
          softBalance: false,
        ),
        atoms: atoms,
        rng: Random(3),
      );
      final parts = roll.split(', ');
      expect(parts, hasLength(2));
      for (final part in parts) {
        final match = RegExp(r'^(-?\d\.\d)::(.+)::$').firstMatch(part);
        expect(match, isNotNull, reason: part);
        final weight = double.parse(match!.group(1)!);
        expect(weight, inInclusiveRange(0.1, 2.0));
        // 0.1 网格
        expect((weight * 10).roundToDouble() / 10, weight);
        expect(atoms, contains(match.group(2)));
      }
    });

    test('pre-weighted atoms are not double-wrapped', () {
      final roll = PillRollEngine.rollInstance(
        settings: const PillInstanceSettings(
          mode: PillRollMode.random,
          countMin: 1,
          countMax: 1,
          weightEnabled: true,
        ),
        atoms: const ['0.5::artist:x::'],
        rng: Random(5),
      );
      expect(roll, '0.5::artist:x::');
    });

    test('split-beta respects degenerate range (min==max==mode)', () {
      for (var seed = 0; seed < 10; seed++) {
        final w = PillRollEngine.sampleSplitBetaWeight(
          const PillInstanceSettings(
            weightEnabled: true,
            weightMin: 1.2,
            weightMax: 1.2,
            weightAverage: 1.2,
          ),
          Random(seed),
        );
        expect(w, 1.2);
      }
    });

    test('samples stay within bounds across dispersions', () {
      for (final dispersion in [0.0, 0.4, 1.0]) {
        for (var seed = 0; seed < 50; seed++) {
          final w = PillRollEngine.sampleSplitBetaWeight(
            PillInstanceSettings(
              weightEnabled: true,
              weightMin: 0.1,
              weightMax: 2.0,
              weightAverage: 0.8,
              leftDispersion: dispersion,
              rightDispersion: dispersion,
            ),
            Random(seed),
          );
          expect(w, inInclusiveRange(0.1, 2.0));
        }
      }
    });

    test('soft balance pulls the string mean toward average', () {
      final balanced = PillRollEngine.softBalanceWeights(
        [1.5, 1.5],
        const PillInstanceSettings(
          weightEnabled: true,
          weightAverage: 0.8,
          weightMin: 0.1,
          weightMax: 2.0,
          softBalanceStrength: 1.0,
        ),
      );
      expect(balanced[0], closeTo(0.8, 1e-9));
      expect(balanced[1], closeTo(0.8, 1e-9));
    });

    test('soft balance strength 0 keeps weights untouched', () {
      final balanced = PillRollEngine.softBalanceWeights(
        [1.5, 0.3],
        const PillInstanceSettings(
          weightEnabled: true,
          weightAverage: 0.8,
          softBalanceStrength: 0.0,
        ),
      );
      expect(balanced, [1.5, 0.3]);
    });

    test('soft balance clamps shifted values into range', () {
      final balanced = PillRollEngine.softBalanceWeights(
        [1.9, 2.0],
        const PillInstanceSettings(
          weightEnabled: true,
          weightMin: 0.1,
          weightMax: 2.0,
          weightAverage: 1.6,
          softBalanceStrength: 1.0,
        ),
      );
      // mean 1.95 → shift -0.35 → 1.55/1.65，范围内不截断
      expect(balanced[0], closeTo(1.55, 1e-9));
      expect(balanced[1], closeTo(1.65, 1e-9));
      // 反向：整体远低于平均时平移也不许越界
      final clamped = PillRollEngine.softBalanceWeights(
        [1.9, 1.8],
        const PillInstanceSettings(
          weightEnabled: true,
          weightMin: 0.1,
          weightMax: 2.0,
          weightAverage: 0.2,
          softBalanceStrength: 1.0,
        ),
      );
      expect(clamped.every((w) => w >= 0.1 && w <= 2.0), isTrue);
    });

    test('discretize rounds to 0.1 and clamps', () {
      expect(PillRollEngine.discretizeWeight(0.85, 0.1, 2.0), 0.9);
      expect(PillRollEngine.discretizeWeight(0.84, 0.1, 2.0), 0.8);
      expect(PillRollEngine.discretizeWeight(2.07, 0.1, 2.0), 2.0);
      expect(PillRollEngine.discretizeWeight(-0.01, 0.1, 2.0), 0.1);
    });
  });

  group('PillInstanceSettings json', () {
    test('round trip keeps every field', () {
      const settings = PillInstanceSettings(
        mode: PillRollMode.random,
        countMin: 2,
        countMax: 5,
        order: PillRollOrder.original,
        weightEnabled: true,
        weightMin: 0.2,
        weightMax: 1.5,
        weightAverage: 0.9,
        leftDispersion: 0.3,
        rightDispersion: 0.6,
        softBalance: false,
        softBalanceStrength: 0.5,
        triggerProbability: 0.7,
      );
      final restored = PillInstanceSettings.fromJson(settings.toJson());
      expect(restored, settings);
    });

    test('missing keys fall back to fixed defaults (旧存档零迁移)', () {
      final restored = PillInstanceSettings.fromJson(const {});
      expect(restored, PillInstanceSettings.fixedDefault);
      expect(restored.mode, PillRollMode.fixed);
    });

    test('out-of-range values are clamped', () {
      final restored = PillInstanceSettings.fromJson(const {
        'weightMin': -99.0,
        'triggerProbability': 7.0,
        'countMin': -3,
      });
      expect(restored.weightMin, PillInstanceSettings.weightFloor);
      expect(restored.triggerProbability, 1.0);
      expect(restored.countMin, 0);
    });

    test('instance defaults to unlocked', () {
      const instance = PillInstance(blockId: 'b1');
      expect(instance.locked, isFalse);
      expect(instance.toJson()['locked'], isFalse);
    });

    test('instance json round trip with locked settings and currentRoll', () {
      const instance = PillInstance(
        blockId: 'b1',
        enabled: false,
        locked: true,
        settings: PillInstanceSettings(mode: PillRollMode.random, countMax: 3),
        currentRoll: 'rolled text',
      );
      final restored = PillInstance.fromJson(instance.toJson());
      expect(restored, instance);
      expect(restored.locked, isTrue);
    });

    test(
      'legacy instance json without settings/currentRoll/locked loads as fixed',
      () {
        final restored = PillInstance.fromJson(const {
          'blockId': 'b1',
          'enabled': true,
        });
        expect(restored.settings, PillInstanceSettings.fixedDefault);
        expect(restored.currentRoll, isNull);
        expect(restored.locked, isFalse);
      },
    );
  });
}
