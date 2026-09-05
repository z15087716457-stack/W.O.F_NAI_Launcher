import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/prompt_token_parser.dart';

CompletionQuery _parse(String text, int cursor, {bool search = false}) =>
    PromptTokenParser.parse(
      text: text,
      cursorPosition: cursor,
      limit: 20,
      locale: 'en',
      splitOnSpaces: search,
    );

void main() {
  group('prompt completion contract', () {
    test('inserts display tags', () {
      const text = 'old_tag, lon, another_tag';
      final query = _parse(text, text.indexOf('lon') + 3);
      final applied = PromptTokenParser.apply(
        text: text,
        query: query,
        canonicalTag: 'long_hair',
        autoInsertComma: true,
      );
      expect(applied.text, 'old_tag, long hair, another_tag');
      expect(applied.cursorPosition, 'old_tag, long hair, '.length);
      expect(query.existingTags, {'old_tag', 'another_tag'});
    });

    final replacements = <String, String>{
      '1.2::artist:a, 1girl::, blu': '1.2::artist:a, 1girl::, blue eyes, ',
      '1.2::blu::': '1.2::blue eyes::, ',
      '1.2::artist:a, blu::, next_tag': '1.2::artist:a, blue eyes::, next_tag',
      '1.2::blu, artist:a, 1girl::': '1.2::blue eyes, artist:a, 1girl::',
      '{{old_tag, blu}}, tail_tag': '{{old_tag, blue eyes}}, tail_tag',
      '{1.2::[blu]::}, tail_tag': '{1.2::[blue eyes]::}, tail_tag',
      '<weighted:my_preset:2,other_preset:1>, blu':
          '<weighted:my_preset:2,other_preset:1>, blue eyes, ',
      'old_tag，blu，tail_tag': 'old_tag，blue eyes，tail_tag',
      'old_tag\nblu\ntail_tag': 'old_tag\nblue eyes, \ntail_tag',
    };
    for (final entry in replacements.entries) {
      test('only replaces the local token in ${entry.key}', () {
        final query = _parse(entry.key, entry.key.indexOf('blu') + 2);
        expect(query.token, 'blu');
        expect(
          entry.key.substring(
            query.replacementRange.start,
            query.replacementRange.end,
          ),
          'blu',
        );
        final applied = PromptTokenParser.apply(
          text: entry.key,
          query: query,
          canonicalTag: 'blue_eyes',
          autoInsertComma: true,
        );
        expect(applied.text, entry.value);
      });
    }

    for (final tag in ['feet_2', 'version_1.5', 'ending.']) {
      for (final comma in [false, true]) {
        test('safely closes $tag with auto comma $comma', () {
          const text = '1.2::blu::, old_tag';
          final applied = PromptTokenParser.apply(
            text: text,
            query: _parse(text, 7),
            canonicalTag: tag,
            autoInsertComma: comma,
          );
          expect(applied.text, '1.2::${tag.replaceAll('_', ' ')} ::, old_tag');
          expect(
            applied.cursorPosition,
            '1.2::${tag.replaceAll('_', ' ')} ::${comma ? ', ' : ''}'.length,
          );
        });
      }
    }

    test('keeps literal parentheses in canonical queries', () {
      const text = '1.2::hatsune_miku_(vocaloid)::, solo';
      final query = _parse(text, 15);
      expect(query.token, 'hatsune_miku_(vocaloid)');
      expect(query.existingTags, {'solo'});
    });

    test('keeps alias names and their internal commas unchanged', () {
      const text = '{1.2::<weighted:my_pr,other>::}, old_tag';
      final query = _parse(text, text.indexOf('my_pr') + 5);
      expect(query.kind, CompletionQueryKind.libraryAlias);
      final applied = PromptTokenParser.apply(
        text: text,
        query: query,
        canonicalTag: 'weighted:my_preset:2,other_preset:1',
        autoInsertComma: true,
      );
      expect(
        applied.text,
        '{1.2::<weighted:my_preset:2,other_preset:1>::}, old_tag',
      );
    });

    test('does not mistake a completed alias for a related tag', () {
      const text = '<my_preset,other_preset>, ';
      expect(
        PromptTokenParser.parseRelated(
          text: text,
          cursorPosition: text.length,
          limit: 20,
          locale: 'en',
        ),
        isNull,
      );
    });

    final relatedCases = <String, String>{
      '1.2::blue_hair, old_tag::': '1.2::blue_hair, long hair, old_tag::',
      '1.2::blue_hair::, old_tag': '1.2::blue_hair::, long hair, old_tag',
      '{1.2::blue_hair, old_tag::}': '{1.2::blue_hair, long hair, old_tag::}',
    };
    for (final entry in relatedCases.entries) {
      test('related insertion keeps weights in ${entry.key}', () {
        final query = PromptTokenParser.parseRelated(
          text: entry.key,
          cursorPosition: entry.key.indexOf('blue_hair') + 4,
          limit: 20,
          locale: 'en',
        )!;
        expect(query.relatedTag, 'blue_hair');
        expect(query.replacementRange.start, query.replacementRange.end);
        final applied = PromptTokenParser.apply(
          text: entry.key,
          query: query,
          canonicalTag: 'long_hair',
          autoInsertComma: false,
        );
        expect(applied.text, entry.value);
      });
    }

    test('related numeric tag safely precedes an existing closure', () {
      const text = '1.2::blue_hair, ::';
      final query = PromptTokenParser.parseRelated(
        text: text,
        cursorPosition: text.indexOf(',') + 2,
        limit: 20,
        locale: 'en',
      )!;
      expect(
        PromptTokenParser.apply(
          text: text,
          query: query,
          canonicalTag: 'feet_2',
          autoInsertComma: false,
        ).text,
        '1.2::blue_hair, feet 2 ::',
      );
    });
  });

  group('canonical external search', () {
    test('space separated search keeps canonical tags', () {
      const text = 'rating:g  foot_focus\tlo  -comic';
      final query = _parse(text, text.indexOf('lo') + 2, search: true);
      expect(query.token, 'lo');
      expect(query.existingTags, {'rating:g', 'foot_focus', '-comic'});
      final applied = PromptTokenParser.apply(
        text: text,
        query: query,
        canonicalTag: 'long_hair',
        autoInsertComma: false,
        splitOnSpaces: true,
      );
      expect(applied.text, 'rating:g  foot_focus\tlong_hair  -comic');
    });
  });
}
