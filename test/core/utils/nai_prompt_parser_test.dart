import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/nai_prompt_parser.dart';

void main() {
  test('numeric groups retain internal commas and weight scopes', () {
    final tags = NaiPromptParser.parse('2::A, B, 1.5::C::, blue eyes');
    expect(tags.map((tag) => tag.text), ['A, B', 'C', 'blue eyes']);
    expect(tags.map((tag) => tag.weight), [2, 1.5, 1]);
    expect(
      NaiPromptParser.toPromptString(tags),
      '2::A, B, 1.5::C::, blue eyes',
    );
  });

  for (final text in [
    'blue dress, blue_eyes',
    '1.4::a, b::, <alias:x, y>, ||a,b|c||',
    '1::a::, -.5::b::',
    '2::A 1.5::B::, C',
    '1.4::a, b',
    '(unclosed, a',
    'orphan123::',
    '<prompt>girl, blue dress</prompt>',
    r'"a, b", c\, d',
  ]) {
    test('parser roundtrip preserves $text', () {
      final tags = NaiPromptParser.parse(text);
      expect(NaiPromptParser.toPromptString(tags), text);
    });
  }

  test('existing closures become safe without rewriting weight or content', () {
    final tags = NaiPromptParser.parse('1.40::artist123::, .5::Sentence.::');
    expect(
      NaiPromptParser.toPromptString(tags),
      '1.40::artist123 ::, .5::Sentence. ::',
    );
    expect(
      tags.first.copyWith(weight: 1.6).toSyntaxString(),
      '1.6::artist123 ::',
    );
  });
}
