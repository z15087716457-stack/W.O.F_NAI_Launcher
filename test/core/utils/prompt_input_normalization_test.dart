import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_input_normalization.dart';

void main() {
  for (final autoFormat in [false, true]) {
    for (final sdAutoConvert in [false, true]) {
      test('independent gates: format=$autoFormat SD=$sdAutoConvert', () {
        final result = PromptInputNormalization.normalize(
          'girl，blue dress, (ralada747372:1.4)',
          autoFormat: autoFormat,
          sdAutoConvert: sdAutoConvert,
        );
        expect(
          result.text,
          '${autoFormat ? 'girl, blue dress' : 'girl，blue dress'}, '
          '${sdAutoConvert ? '1.4::ralada747372 ::' : '(ralada747372:1.4)'}',
        );
        expect(result.sdConverted, sdAutoConvert);
        expect(result.formatted, autoFormat);
      });
    }
  }

  test('disabled gates preserve whitespace, punctuation and literal text', () {
    const input = '  girl， blue dress\n(cinematic lighting:1.3)  ';
    final result = PromptInputNormalization.normalize(
      input,
      autoFormat: false,
      sdAutoConvert: false,
    );
    expect(result.text, input);
    expect(result.changed, isFalse);
  });

  test(
    'format-only preserves SD groups without leaking protection markers',
    () {
      const input = '\uE000，((blue eyes):1.3), [red dress:0.8]，blue hair';
      final result = PromptInputNormalization.normalize(
        input,
        autoFormat: true,
        sdAutoConvert: false,
      );
      expect(
        result.text,
        '\uE000, ((blue eyes):1.3), [red dress:0.8], blue hair',
      );
    },
  );

  test('combined normalization is stable on already normalized NAI text', () {
    const input = '1.4::ralada747372 ::, 1.3::cinematic lighting::, blue eyes';
    final result = PromptInputNormalization.normalize(
      input,
      autoFormat: true,
      sdAutoConvert: true,
    );
    expect(result.text, input);
    expect(result.changed, isFalse);
  });
}
