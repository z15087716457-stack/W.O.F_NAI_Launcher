import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/nai_prompt_formatter.dart';
import 'package:nai_launcher/core/utils/sd_to_nai_converter.dart';

void main() {
  final cases = {
    '': '',
    ' , ，\t ,　,': '',
    'girl，blue dress': 'girl, blue dress',
    '(cinematic lighting:1.3), blue eyes':
        '(cinematic lighting:1.3), blue eyes',
    '(cinematic  lighting:1.3)，blue  eyes':
        '(cinematic  lighting:1.3), blue eyes',
    '[bad\tanatomy:0.8], blue  eyes': '[bad\tanatomy:0.8], blue eyes',
    '1.4::ralada747372::': '1.4::ralada747372 ::',
    'blue dress, blue_eyes': 'blue dress, blue_eyes',
    '  girl　,\tblue dress  ': 'girl, blue dress',
    ' \t　girl\t blue　dress  ,\tblue_eyes  ': 'girl blue dress, blue_eyes',
    'two  spaces, blue dress': 'two spaces, blue dress',
    '1.4::She looks away.::,blue eyes': '1.4::She looks away. ::, blue eyes',
    '2::A, B, 1.5::C::,D': '2::A, B, 1.5::C::, D',
    '2::A  B,  1.5::C\t D::, z': '2::A B, 1.5::C D::, z',
    '1.4::a,b::,c': '1.4::a,b::, c',
    '1.4::blue\t  eyes， red　dress::,x': '1.4::blue eyes， red dress::, x',
    '1.4::ralada747372　\t ::': '1.4::ralada747372 ::',
    '1.4::version   2 ::': '1.4::version 2 ::',
    '1.4::version 2::': '1.4::version 2::',
    '1.4::2 ::': '1.4::2 ::',
    '1.4::word.   ::': '1.4::word. ::',
    '1.4::word. ::   ,  next': '1.4::word. ::, next',
    '<alias(a, b):x， y>,(foo, bar),||a,b|c,d||':
        '<alias(a, b):x， y>, (foo, bar), ||a,b|c,d||',
    '<alias:blue  dress,\tred　eyes>, blue\t dress':
        '<alias:blue  dress,\tred　eyes>, blue dress',
    '1.4::<alias:a  b, c>, blue \t eyes::,x':
        '1.4::<alias:a  b, c>, blue eyes::, x',
    '"(blue eyes:1.3)，red dress", blue_eyes':
        '"(blue eyes:1.3)，red dress", blue_eyes',
    '"blue  dress，red\t eyes",　 blue　eyes':
        '"blue  dress，red\t eyes", blue eyes',
    r'a\,b,blue eyes': r'a\,b, blue eyes',
    r'a\ ': r'a\ ',
    '1.4::unclosed  ': '1.4::unclosed  ',
    r'a\ ,blue eyes': r'a\ , blue eyes',
    '(blue eyes:NaN)': '(blue eyes:NaN)',
    '(blue eyes:Infinity)': '(blue eyes:Infinity)',
    r'\(literal\), blue eyes': r'\(literal\), blue eyes',
    'girl, (unfinished， a  b': 'girl, (unfinished， a  b',
    'girl, 1.4::unfinished， a  b': 'girl, 1.4::unfinished， a  b',
    'girl  , <alias:unfinished  ,\t  text  ':
        'girl, <alias:unfinished  ,\t  text  ',
    'girl  , 1.4::unclosed　  words,\t blue  eyes':
        'girl, 1.4::unclosed　  words,\t blue  eyes',
    '(a], b  c': '(a], b  c',
    'A girl walks.\nShe looks away, smiling.':
        'A girl walks.\nShe looks away, smiling.',
    'A\t girl walks.\r\n\r\nShe　looks  away.':
        'A girl walks.\r\n\r\nShe looks away.',
    'girl,\nblue\t eyes': 'girl,\nblue eyes',
    'girl,\n, blue\t eyes, \n': 'girl,\nblue eyes\n',
    '<prompt>\n  girl，blue dress (lighting:1.3)\n</prompt>':
        '<prompt>\n  girl，blue dress (lighting:1.3)\n</prompt>',
    ' \t<prompt>\r\n girl　 dress,  blue\teyes\r\n</prompt>  ':
        ' \t<prompt>\r\n girl　 dress,  blue\teyes\r\n</prompt>  ',
    '\uE000，blue dress,\uE001': '\uE000, blue dress, \uE001',
    'a, ,b,,': 'a, b',
    ', ,girl, , blue dress,,': 'girl, blue dress',
    '(artist123:1.2), (sentence.:.5), [bad anatomy:0.8]':
        '(artist123:1.2), (sentence.:.5), [bad anatomy:0.8]',
    '1.4::(blue eyes:1.3), a::': '1.4::(blue eyes:1.3), a::',
  };
  for (final entry in cases.entries) {
    test('format and formatTag are idempotent: ${entry.key}', () {
      final actual = NaiPromptFormatter.format(entry.key);
      expect(actual, entry.value);
      expect(NaiPromptFormatter.format(actual), actual);
      expect(NaiPromptFormatter.formatTag(entry.key), actual);
    });
  }

  for (final entry in {
    '(cinematic lighting:1.3), blue eyes':
        '1.3::cinematic lighting::, blue eyes',
    '(artist123:1.2), (sentence.:.5), [bad anatomy:0.8]':
        '1.2::artist123 ::, 0.5::sentence. ::, 0.8::bad anatomy::',
    r'\(literal\), (cinematic lighting:1.3)':
        '(literal), 1.3::cinematic lighting::',
    'girl，(cinematic  lighting:1.3), , blue　eyes,':
        'girl, 1.3::cinematic lighting::, blue eyes',
  }.entries) {
    test('SD conversion is explicit before formatting: ${entry.key}', () {
      final converted = SdToNaiConverter.convert(entry.key);
      final formatted = NaiPromptFormatter.format(converted);
      expect(formatted, entry.value);
      expect(NaiPromptFormatter.format(formatted), formatted);
      expect(
        NaiPromptFormatter.format(SdToNaiConverter.convert(formatted)),
        formatted,
      );
    });
  }
}
