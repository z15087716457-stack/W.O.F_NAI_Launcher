import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/utils/explore_mutation_engine.dart';
import 'package:nai_launcher/core/utils/pill_roll_engine.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';

ExploreMutationParent _parent(
  String id,
  String text, {
  double preference = 1.0,
}) {
  return ExploreMutationParent(id: id, text: text, preference: preference);
}

List<String> _atoms(String text) => PillRollEngine.splitTopLevelAtoms(text);

void main() {
  group('seeded 确定性', () {
    final parents = [
      _parent('p1', '0.8::artist:a::, 1girl', preference: 1.5),
      _parent('p2', 'artist:b, 1.2::artist:c::, scenic'),
    ];

    List<String> fingerprint(int seed) {
      return ExploreMutationEngine.generateDeepCandidates(
        parents: parents,
        count: 8,
        injectionPool: const ['artist:x', 'artist:y'],
        rng: Random(seed),
      ).map((c) {
        final parentIds = c.parents.map((p) => p.id).join('+');
        return '${c.operation.name}|$parentIds|${c.text}';
      }).toList();
    }

    test('同一 seed 产出完全一致', () {
      expect(fingerprint(42), fingerprint(42));
    });

    test('不同 seed 产出不同', () {
      expect(fingerprint(42), isNot(fingerprint(7)));
    });
  });

  group('参数校验', () {
    test('空父本 / 子代数小于父本数抛 ArgumentError', () {
      expect(
        () => ExploreMutationEngine.generateDeepCandidates(
          parents: const [],
          count: 3,
          rng: Random(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => ExploreMutationEngine.generateDeepCandidates(
          parents: [_parent('p1', 'a'), _parent('p2', 'b')],
          count: 1,
          rng: Random(1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('保底（公平性）', () {
    test('每个父本至少一个变异子代，即使偏好最低', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [
          _parent('p1', '0.7::alpha::, beta', preference: 0.25),
          _parent('p2', 'gamma, delta', preference: 3.0),
          _parent('p3', 'epsilon, 1.1::zeta::'),
        ],
        count: 6,
        rng: Random(3),
      );
      for (final id in ['p1', 'p2', 'p3']) {
        expect(
          results.any(
            (c) =>
                c.operation == ExploreLineageOperation.mutation &&
                c.parents.single.id == id,
          ),
          isTrue,
          reason: '父本 $id 应有保底变异子代',
        );
      }
    });
  });

  group('权重扰动', () {
    test('以父权重为众数在 ±幅度内重采样，0.1 网格，内容不变', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [_parent('p1', '0.8::artist:a::, 0.8::artist:b::')],
        count: 4,
        config: const ExploreMutationConfig(
          weightPerturbProbability: 1.0,
          deleteProbability: 0,
          assignWeightProbability: 0,
        ),
        rng: Random(11),
      );
      expect(results, hasLength(4));
      final weightPattern = RegExp(r'^([-+]?\d+(?:\.\d+)?)::(.*)::$');
      for (final child in results) {
        expect(child.operation, ExploreLineageOperation.mutation);
        final atoms = _atoms(child.text);
        expect(atoms, hasLength(2));
        for (var i = 0; i < 2; i++) {
          final match = weightPattern.firstMatch(atoms[i])!;
          final weight = double.parse(match.group(1)!);
          expect(weight, inInclusiveRange(0.4, 1.2));
          expect(
            (weight * 10).roundToDouble() / 10,
            weight,
            reason: '权重落在 0.1 网格',
          );
          expect(match.group(2), i == 0 ? 'artist:a' : 'artist:b');
        }
      }
    });

    test('无权重原子按概率赋权', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [_parent('p1', 'alpha, beta')],
        count: 3,
        config: const ExploreMutationConfig(
          weightPerturbProbability: 0,
          deleteProbability: 0,
          assignWeightProbability: 1.0,
          assignWeightMode: 0.9,
          weightAmplitude: 0.3,
        ),
        rng: Random(5),
      );
      expect(results, hasLength(3));
      final weighted = RegExp(r'^[-+]?\d+(?:\.\d+)?::.*::$');
      for (final child in results) {
        for (final atom in _atoms(child.text)) {
          expect(weighted.hasMatch(atom), isTrue, reason: '原子应被赋权: $atom');
        }
      }
    });

    test('删除保底：子代至少保留一个原子', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [_parent('p1', 'alpha, beta, gamma')],
        count: 3,
        config: const ExploreMutationConfig(
          weightPerturbProbability: 0,
          deleteProbability: 1.0,
          assignWeightProbability: 1.0,
        ),
        rng: Random(9),
      );
      expect(results, hasLength(3));
      for (final child in results) {
        final atoms = _atoms(child.text);
        expect(atoms, hasLength(1), reason: '全删后兜底留一个: ${child.text}');
      }
    });

    test('单原子无权重父本强制改一处（赋权）', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [_parent('p1', 'solo')],
        count: 1,
        config: const ExploreMutationConfig(
          weightPerturbProbability: 0,
          deleteProbability: 0,
          assignWeightProbability: 0,
        ),
        rng: Random(2),
      );
      expect(results, hasLength(1));
      expect(results.single.text, isNot('solo'));
      expect(
        RegExp(r'^[-+]?\d+(?:\.\d+)?::solo::$').hasMatch(results.single.text),
        isTrue,
      );
    });
  });

  group('两父本交叉', () {
    test('子代含两个父本的原子且去重', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [
          _parent('p1', 'a1, a2, a3, a4'),
          _parent('p2', 'b1, b2, b3, b4'),
        ],
        count: 5,
        config: const ExploreMutationConfig(crossoverProbability: 1.0),
        rng: Random(21),
      );
      expect(results, hasLength(5));
      final crossovers = [
        for (final child in results)
          if (child.operation == ExploreLineageOperation.crossover) child,
      ];
      // 2 个保底变异 + 3 个交叉。
      expect(crossovers, hasLength(3));
      final atomsA = {'a1', 'a2', 'a3', 'a4'};
      final atomsB = {'b1', 'b2', 'b3', 'b4'};
      for (final child in crossovers) {
        expect(child.parents, hasLength(2));
        final atoms = _atoms(child.text).toSet();
        expect(atoms.intersection(atomsA), isNotEmpty);
        expect(atoms.intersection(atomsB), isNotEmpty);
        expect(atoms.length, _atoms(child.text).length, reason: '子代内原子不重复');
      }
    });
  });

  group('随机注入', () {
    test('注入子代 = 父本原子 + 池中新原子', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [_parent('p1', 'artist:a, artist:b')],
        count: 3,
        injectionPool: const ['artist:x', 'artist:y', 'artist:z'],
        config: const ExploreMutationConfig(injectionRatio: 1.0),
        rng: Random(13),
      );
      expect(results, hasLength(3));
      final injections = [
        for (final child in results)
          if (child.operation == ExploreLineageOperation.injection) child,
      ];
      expect(injections, hasLength(2));
      const pool = {'artist:x', 'artist:y', 'artist:z'};
      for (final child in injections) {
        final atoms = _atoms(child.text).toSet();
        expect(
          atoms.containsAll({'artist:a', 'artist:b'}),
          isTrue,
          reason: '注入保留父本原子',
        );
        final added = atoms.difference({'artist:a', 'artist:b'});
        expect(added, isNotEmpty);
        expect(pool.containsAll(added), isTrue);
      }
    });

    test('池被父本覆盖时注入名额自动放弃，不产出重复', () {
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: [_parent('p1', 'artist:a, artist:b')],
        count: 3,
        injectionPool: const ['artist:a'],
        config: const ExploreMutationConfig(
          injectionRatio: 1.0,
          maxAttempts: 8,
        ),
        rng: Random(17),
      );
      // 注入尝试必然产父本原文被去重拒绝；剩余名额由变异补齐。
      expect(results, hasLength(3));
      expect(
        results.where((c) => c.operation == ExploreLineageOperation.injection),
        isEmpty,
      );
      final texts = results.map((c) => c.text).toSet();
      expect(texts, hasLength(results.length));
    });
  });

  group('去重', () {
    test('产出串集合内不重复，也不与父本完全重复', () {
      final parents = [
        _parent('p1', '0.8::artist:a::, 1girl, scenic'),
        _parent('p2', 'artist:b, 1.2::artist:c::'),
      ];
      final results = ExploreMutationEngine.generateDeepCandidates(
        parents: parents,
        count: 8,
        injectionPool: const ['artist:x'],
        rng: Random(31),
      );
      final texts = results.map((c) => c.text);
      expect(texts.toSet(), hasLength(texts.length));
      for (final text in texts) {
        expect(parents.map((p) => p.text), isNot(contains(text)));
      }
    });
  });

  group('偏好加权', () {
    test('高偏好父本在统计上被选中更多', () {
      var hot = 0;
      var cold = 0;
      for (var seed = 0; seed < 40; seed++) {
        final results = ExploreMutationEngine.generateDeepCandidates(
          parents: [
            _parent('hot', '0.8::h1::, h2', preference: 4.0),
            _parent('cold', '0.8::c1::, c2', preference: 0.25),
          ],
          count: 8,
          rng: Random(seed),
        );
        for (final child in results.skip(2)) {
          // 跳过保底名额，只统计加权/交叉选择
          if (child.parents.any((p) => p.id == 'hot')) hot++;
          if (child.parents.any((p) => p.id == 'cold')) cold++;
        }
      }
      expect(hot, greaterThan(cold));
    });
  });
}
