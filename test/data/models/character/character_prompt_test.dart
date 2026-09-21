import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';

void main() {
  test('new and missing names remain empty through persistence', () {
    final config = const CharacterPromptConfig().addCharacter();
    final character = config.characters.single;
    expect(character.name, isEmpty);
    expect(character.customName, isEmpty);
    expect(
      CharacterPromptConfig.fromJson(
        jsonDecode(jsonEncode(config)) as Map<String, dynamic>,
      ).characters.single.name,
      isEmpty,
    );
    expect(CharacterPrompt.fromJson({'id': 'missing'}).name, isEmpty);
  });

  test(
    'legacy generated names act as placeholders without deleting original data',
    () {
      final old = CharacterPrompt.fromJson({
        'id': 'old',
        'name': 'Character 2',
        'prompt': 'girl, Alice',
      });
      expect(old.name, 'Character 2');
      expect(old.customName, isEmpty);
      expect(old.toJson()['name'], 'Character 2');
      expect(
        CharacterPrompt.fromJson({'id': 'custom', 'name': 'Alice'}).customName,
        'Alice',
      );
    },
  );

  test(
    'explicit names including Character N survive serialization and clearing',
    () {
      final named = CharacterPrompt.create(
        name: 'Character 2',
        prompt: 'girl, Elsa',
      );
      final restored = CharacterPrompt.fromJson(named.toJson());
      expect(restored.customName, 'Character 2');
      expect(restored.nameIsCustom, isTrue);
      final cleared = restored.copyWith(name: '', nameIsCustom: false);
      expect(CharacterPrompt.fromJson(cleared.toJson()).customName, isEmpty);
      expect(cleared.prompt, named.prompt);
    },
  );
}
