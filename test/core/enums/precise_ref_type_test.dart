import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/model_spec.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';

void main() {
  group('PreciseRefType', () {
    const expectedValues = {
      PreciseRefType.character: ('character', 'preciseRef_typeCharacter'),
      PreciseRefType.style: ('style', 'preciseRef_typeStyle'),
      PreciseRefType.characterAndStyle: (
        'character&style',
        'preciseRef_typeCharacterAndStyle',
      ),
      PreciseRefType.outfit: ('costume', 'preciseRef_typeOutfit'),
    };

    test('keeps the original Hive indices and appends outfit at index 3', () {
      expect(PreciseRefType.values, expectedValues.keys.toList());
    });

    test('serializes and parses all official captions', () {
      const captions = {
        'character': (type: PreciseRefType.character, preferSameOutfit: false),
        'character_mainoutfit': (
          type: PreciseRefType.character,
          preferSameOutfit: true,
        ),
        'character&style': (
          type: PreciseRefType.characterAndStyle,
          preferSameOutfit: true,
        ),
        'character&style_anyoutfit': (
          type: PreciseRefType.characterAndStyle,
          preferSameOutfit: false,
        ),
        'style': (type: PreciseRefType.style, preferSameOutfit: null),
        'costume': (type: PreciseRefType.outfit, preferSameOutfit: null),
      };
      for (final entry in captions.entries) {
        final parsed = PreciseRefTypeExtension.parseApiCaption(entry.key);
        expect(parsed, entry.value);
        expect(
          parsed.type.toApiString(preferSameOutfit: parsed.preferSameOutfit),
          entry.key,
        );
      }
      expect(
        PreciseRefTypeExtension.parseApiCaption('outfit'),
        captions['costume'],
      );
      for (final unknown in [null, 'other']) {
        expect(PreciseRefTypeExtension.parseApiCaption(unknown), (
          type: PreciseRefType.character,
          preferSameOutfit: null,
        ));
      }
    });

    test(
      'V4.5 encodes the original character captions for either preference',
      () {
        final v45 = ModelSpecs.of(ImageModels.animeDiffusionV45Full);
        final v5 = ModelSpecs.of(ImageModels.animeDiffusionV5Full);
        for (final (type, prefer, legacy, current) in [
          (PreciseRefType.character, true, 'character', 'character_mainoutfit'),
          (
            PreciseRefType.characterAndStyle,
            false,
            'character&style',
            'character&style_anyoutfit',
          ),
        ]) {
          expect(type.supportsPreferSameOutfit, isTrue);
          expect(
            type.toApiStringForModel(v45, preferSameOutfit: prefer),
            legacy,
          );
          expect(
            type.toApiStringForModel(v5, preferSameOutfit: prefer),
            current,
          );
        }
        expect(PreciseRefType.style.supportsPreferSameOutfit, isFalse);
        expect(PreciseRefType.outfit.supportsPreferSameOutfit, isFalse);
      },
    );

    test('all values should be present', () {
      for (final type in expectedValues.keys) {
        expect(PreciseRefType.values, contains(type));
      }
    });

    test('toApiString() should return correct values', () {
      for (final entry in expectedValues.entries) {
        expect(entry.key.toApiString(), equals(entry.value.$1));
      }
    });

    test('displayNameKey should return correct values', () {
      for (final entry in expectedValues.entries) {
        expect(entry.key.displayNameKey, equals(entry.value.$2));
      }
    });

    test('all API strings should be unique', () {
      final apiStrings = PreciseRefType.values
          .map((t) => t.toApiString())
          .toList();
      expect(apiStrings.toSet().length, equals(apiStrings.length));
    });

    test('enum values should be distinct', () {
      const values = PreciseRefType.values;
      for (var i = 0; i < values.length; i++) {
        for (var j = i + 1; j < values.length; j++) {
          expect(values[i], isNot(equals(values[j])));
          expect(values[i].hashCode, isNot(equals(values[j].hashCode)));
        }
      }
    });
  });
}
