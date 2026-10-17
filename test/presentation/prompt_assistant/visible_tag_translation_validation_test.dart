import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';

void main() {
  test(
    'semantic reference fields are bounded, distinct from reading and required for new requests',
    () {
      final value = <String, dynamic>{
        'tag': 'grass',
        'name_zh': '草原',
        'definition': '日本語の説明',
        'core_zh': '草地',
        'synonyms_zh': ['草地', '草'],
        'summary_zh': '植物覆盖的地面。',
        'wiki_zh': null,
        'wiki_original': null,
      };
      VisibleTagTranslationResult parse(Map<String, dynamic> input) =>
          PromptAssistantService.validateVisibleTagTranslationResponse(
            jsonEncode(input),
            tag: 'grass',
            includeWikiTranslation: false,
            requireSemanticFields: true,
          );
      final result = parse(value);
      expect(result.nameZh, '草原');
      expect(result.coreZh, '草地');
      expect(result.synonymsZh, ['草地', '草']);
      for (final fields in [
        {'synonyms_zh': 'not-an-array'},
        {
          'synonyms_zh': ['草地', '草地'],
        },
        {
          'synonyms_zh': ['wrong-first'],
        },
        {'summary_zh': 'two\nlines'},
        {'core_zh': '长' * 65},
        {'summary_zh': '长' * 241},
        {
          'synonyms_zh': [42],
        },
      ]) {
        expect(() => parse({...value, ...fields}), throwsFormatException);
      }
      expect(
        () => parse({...value}..remove('summary_zh')),
        throwsFormatException,
      );
      expect(
        parse({
          ...value,
          'core_zh': null,
          'synonyms_zh': [],
          'summary_zh': null,
        }).summaryZh,
        isNull,
      );
    },
  );
  test('name-only response retains a separate short definition', () {
    final result = PromptAssistantService.validateVisibleTagTranslationResponse(
      jsonEncode({
        'tag': 'sun',
        'name_zh': '太阳',
        'definition': '太阳系中心的恒星，发出光和热。',
        'wiki_zh': null,
      }),
      tag: 'sun',
      includeWikiTranslation: false,
      requireDefinition: true,
    );
    expect(result.nameZh, '太阳');
    expect(result.definition, '太阳系中心的恒星，发出光和热。');
    expect(result.wikiZh, isNull);
    for (final invalid in [null, 42, '', '两行\n释义', '长' * 241]) {
      expect(
        () => PromptAssistantService.validateVisibleTagTranslationResponse(
          jsonEncode({
            'tag': 'sun',
            'name_zh': '太阳',
            'definition': invalid,
            'wiki_zh': null,
          }),
          tag: 'sun',
          includeWikiTranslation: false,
          requireDefinition: true,
        ),
        throwsFormatException,
      );
    }
    expect(
      PromptAssistantService.validateVisibleTagTranslationResponse(
        '{"tag":"unknown","name_zh":"未知","definition":null,"wiki_zh":null}',
        tag: 'unknown',
        includeWikiTranslation: false,
      ).definition,
      isNull,
    );
  });
  test(
    'source presentation is accepted with the translation and rejects malformed or unsolicited bodies',
    () {
      final article = PromptAssistantService.validateVisibleTagTranslationResponse(
        '{"tag":"medium_hair","name_zh":"中发","wiki_zh":"示例\\n- [中发](wof-tag:medium_hair)","wiki_original":"Examples\\n- [Medium hair](wof-tag:medium_hair)"}',
        tag: 'medium_hair',
        includeWikiTranslation: true,
      );
      expect(
        article.wikiOriginal,
        'Examples\n- [Medium hair](wof-tag:medium_hair)',
      );
      for (final original in ['42', '""', '"Unsolicited body"']) {
        expect(
          () => PromptAssistantService.validateVisibleTagTranslationResponse(
            '{"tag":"medium_hair","name_zh":"中发","wiki_zh":null,"wiki_original":$original}',
            tag: 'medium_hair',
            includeWikiTranslation: false,
          ),
          throwsFormatException,
        );
      }
    },
  );
  test('accepts one tag name and optional opened wiki translation', () {
    final name = PromptAssistantService.validateVisibleTagTranslationResponse(
      '{"tag":"blue_eyes","name_zh":"蓝眼","wiki_zh":null}',
      tag: 'blue_eyes',
      includeWikiTranslation: false,
    );
    expect(name.nameZh, '蓝眼');
    expect(name.wikiZh, isNull);

    final article =
        PromptAssistantService.validateVisibleTagTranslationResponse(
          '{"tag":"blue_eyes","name_zh":"蓝眼","wiki_zh":"蓝色的眼睛。"}',
          tag: 'blue_eyes',
          includeWikiTranslation: true,
          existingNameZh: '蓝眼',
        );
    expect(article.wikiZh, '蓝色的眼睛。');
  });

  test(
    'rejects mismatched tags, unsolicited wiki, and renamed existing term',
    () {
      expect(
        () => PromptAssistantService.validateVisibleTagTranslationResponse(
          '{"tag":"red_eyes","name_zh":"红眼","wiki_zh":null}',
          tag: 'blue_eyes',
          includeWikiTranslation: false,
        ),
        throwsFormatException,
      );
      expect(
        () => PromptAssistantService.validateVisibleTagTranslationResponse(
          '{"tag":"blue_eyes","name_zh":"蓝眼","wiki_zh":"多余译文"}',
          tag: 'blue_eyes',
          includeWikiTranslation: false,
        ),
        throwsFormatException,
      );
      expect(
        () => PromptAssistantService.validateVisibleTagTranslationResponse(
          '{"tag":"blue_eyes","name_zh":"蓝色眼睛","wiki_zh":"正文"}',
          tag: 'blue_eyes',
          includeWikiTranslation: true,
          existingNameZh: '蓝眼',
        ),
        throwsFormatException,
      );
    },
  );
}
