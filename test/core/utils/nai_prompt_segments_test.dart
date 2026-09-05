import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/nai_prompt_segments.dart';

void main() {
  final cases = <String, List<String>>{
    'girl，blue dress, blue_eyes': ['girl', 'blue dress', 'blue_eyes'],
    ', a,, , b,': ['a', 'b'],
    '1.4::a, b::, c': ['1.4::a, b::', 'c'],
    '2::A, B, 1.5::C::, D': ['2::A, B', '1.5::C::', 'D'],
    '2::A 1.5::C::, D': ['2::A 1.5::C::', 'D'],
    '.5::tag1::, -.4::b::': ['.5::tag1::', '-.4::b::'],
    '<alias(a, b):x, y>, (foo, bar), {a, [b, c]}, ||a, b|c, d||, z': [
      '<alias(a, b):x, y>',
      '(foo, bar)',
      '{a, [b, c]}',
      '||a, b|c, d||',
      'z',
    ],
    '"a, b", \'c, d\', girl\'s dress, x': [
      '"a, b"',
      "'c, d'",
      "girl's dress",
      'x',
    ],
    r'a\, b, c': [r'a\, b', 'c'],
    'a, 2::b, c': ['a', '2::b, c'],
    'a, (b, c': ['a', '(b, c'],
    'a, <alias:b, c': ['a', '<alias:b, c'],
    'a, ||b, c': ['a', '||b, c'],
    '<prompt>girl, blue dress</prompt>': ['<prompt>girl, blue dress</prompt>'],
    '\uE000, 1.4::\uE001, a::, \uE002': [
      '\uE000',
      '1.4::\uE001, a::',
      '\uE002',
    ],
  };
  for (final entry in cases.entries) {
    test('top-level segments: ${entry.key}', () {
      expect(splitNaiPromptSegments(entry.key), entry.value);
    });
  }
}
