import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/nai_weight_syntax.dart';

void main() {
  for (final entry in {
    'ralada747372': '1.4::ralada747372 ::',
    'She looks away.': '1.4::She looks away. ::',
    'tag 12.5': '1.4::tag 12.5 ::',
    'artist name': '1.4::artist name::',
    'artist_name': '1.4::artist_name::',
    'tag (series2)': '1.4::tag (series2)::',
    'tag1 ': '1.4::tag1 ::',
    'tag.\n': '1.4::tag.\n::',
  }.entries) {
    test('wrap and close preserve content: ${entry.key}', () {
      expect(NaiWeightSyntax.wrap('1.4', entry.key), entry.value);
      expect(NaiWeightSyntax.close('1.4::${entry.key}'), entry.value);
    });
  }

  for (final entry in {
    '1.4::ralada747372::': '1.4::ralada747372 ::',
    '1.4::A sentence.::, blue eyes': '1.4::A sentence. ::, blue eyes',
    '2::A, B, 1.5::C::': '2::A, B, 1.5::C::',
    '2::tag123::, 1.5::C::': '2::tag123 ::, 1.5::C::',
    '2::A 1.5::C2::': '2::A 1.5::C2 ::',
    '1.4::version 2::': '1.4::version 2::',
    '1.4::version 2::C::': '1.4::version 2::C::',
    '.5::tag2::, -.4::tag3::': '.5::tag2 ::, -.4::tag3 ::',
    '2::A, +1.5::tag2::': '2::A, +1.5::tag2 ::',
    '1.4::123::': '1.4::123::',
    '1.4::tag1 ::': '1.4::tag1 ::',
    '1.4::tag1': '1.4::tag1',
    'artist123::, next': 'artist123::, next',
    '{1.4::tag1::}': '{1.4::tag1 ::}',
    '<alias:1.4::tag1::>, "1.4::tag2::"': '<alias:1.4::tag1::>, "1.4::tag2::"',
    r'1.4::tag1\::': r'1.4::tag1\::',
    '<prompt>1.4::tag1::, hello</prompt>':
        '<prompt>1.4::tag1::, hello</prompt>',
  }.entries) {
    test('guard is conservative and idempotent: ${entry.key}', () {
      final result = NaiWeightSyntax.guardClosures(entry.key);
      expect(result, entry.value);
      expect(NaiWeightSyntax.guardClosures(result), result);
    });
  }
}
