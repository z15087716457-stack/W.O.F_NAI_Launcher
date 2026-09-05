import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/explore_mutation_engine.dart';
import 'package:nai_launcher/core/utils/pill_roll_engine.dart';
import 'package:nai_launcher/core/utils/sd_to_nai_converter.dart';
import 'package:nai_launcher/data/models/prompt/prompt_tag.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

void main() {
  for (final content in ['artist123', 'A sentence.']) {
    test('PromptTag emits a safe numeric closure for $content', () {
      final tag = PromptTag.create(
        text: content,
        weight: 1.4,
        syntaxType: WeightSyntaxType.numeric,
      );
      expect(tag.toSyntaxString(), '1.4::$content ::');
      expect(tag.copyWith(weight: 1).toSyntaxString(), content);
      expect(tag.copyWith(enabled: false).toSyntaxString(), '');
    });

    test('SD conversion closes weighted-to-weighted branch for $content', () {
      expect(
        SdToNaiConverter.convert('($content:1.2)(next:1.3)'),
        '1.2::$content ::1.3::next::',
      );
    });
    test('SD conversion closes weighted-to-unweighted branch for $content', () {
      expect(
        SdToNaiConverter.convert('($content:1.2), next'),
        '1.2::$content ::, next',
      );
    });
    test('SD conversion closes final weighted branch for $content', () {
      expect(
        SdToNaiConverter.convert('next, ($content:1.2)'),
        'next, 1.2::$content ::',
      );
    });

    test(
      'pill wrapping keeps random draws and numeric values for $content',
      () {
        const settings = PillInstanceSettings(
          countMin: 1,
          countMax: 1,
          weightEnabled: true,
          weightMin: 0.8,
          weightMax: 0.8,
          weightAverage: 0.8,
        );
        final rng = Random(42);
        final control = Random(42);
        final actual = PillRollEngine.rollInstance(
          settings: settings,
          atoms: [content],
          rng: rng,
        );
        final plain = PillRollEngine.rollInstance(
          settings: settings,
          atoms: ['plain'],
          rng: control,
        );
        expect(actual, '0.8::$content ::');
        expect(plain, '0.8::plain::');
        expect(rng.nextDouble(), control.nextDouble());
      },
    );

    for (final enabled in [false, true]) {
      test(
        'pill preserves explicit weight with enabled=$enabled: $content',
        () {
          final actual = PillRollEngine.rollInstance(
            settings: PillInstanceSettings(
              countMin: 1,
              countMax: 1,
              weightEnabled: enabled,
            ),
            atoms: ['1.4::$content::'],
            rng: Random(42),
          );
          expect(actual, '1.4::$content ::');
        },
      );
    }

    for (final weighted in [false, true]) {
      test(
        'explore ${weighted ? 'perturbs' : 'assigns'} safe weight: $content',
        () {
          final parent = weighted ? '1.2::$content::' : content;
          final result = ExploreMutationEngine.generateDeepCandidates(
            parents: [ExploreMutationParent(id: 'p', text: parent)],
            count: 1,
            config: const ExploreMutationConfig(
              weightMin: 0.8,
              weightMax: 0.8,
              weightAmplitude: 0.5,
              weightPerturbProbability: 1,
              assignWeightProbability: 1,
              deleteProbability: 0,
            ),
            rng: Random(5),
          );
          expect(result, hasLength(1));
          expect(result.single.text, '0.8::$content ::');
        },
      );
    }
  }

  for (final text in [
    '<alias:(a:1.2), b>',
    '"(caption:1.2)"',
    '||a,(b:1.2)|c||',
    '<prompt>(cinematic lighting:1.3), blue eyes</prompt>',
    '1.4::a, (b:1.2), c::',
    '(unfinished (a:1.2)',
    '(a "b:1.2")',
  ]) {
    test('SD converter preserves opaque/protected input $text', () {
      expect(SdToNaiConverter.hasSDWeightSyntax(text), isFalse);
      expect(SdToNaiConverter.convert(text), text);
    });
  }
}
