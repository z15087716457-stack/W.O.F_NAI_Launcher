import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/prompt_token_parser.dart';

void main() {
  test('explicit insertion preserves the existing tag and its NAI weight', () {
    const source = '1.2::blue hair::, solo';
    final result = PromptTokenParser.insertAtCaret(
      text: source,
      cursorPosition: source.indexOf('blue') + 2,
      canonicalTag: 'red_eyes',
      autoInsertComma: true,
    );

    expect(result.text, '1.2::blue hair::, red eyes, solo');
    expect(result.cursorPosition, result.text.indexOf('solo'));
  });

  test('explicit insertion works in an empty editor and beside a pill', () {
    final empty = PromptTokenParser.insertAtCaret(
      text: '',
      cursorPosition: 0,
      canonicalTag: 'red_eyes',
      autoInsertComma: true,
    );
    const withPill = '\uE000, blue hair';
    final besidePill = PromptTokenParser.insertAtCaret(
      text: withPill,
      cursorPosition: withPill.indexOf('blue') + 2,
      canonicalTag: 'red_eyes',
      autoInsertComma: true,
    );

    expect(empty.text, 'red eyes, ');
    expect(besidePill.text, '\uE000, blue hair, red eyes, ');
  });
}
