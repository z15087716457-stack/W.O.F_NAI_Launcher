import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_translation_edit.dart';

PromptTranslationEditRequest request({
  PromptTranslationDirection direction = PromptTranslationDirection.toSource,
  String source = '1.2::blue eyes::, {smile}, artist:asteroid_ill',
  String zh = '蓝眼睛，微笑',
  List<PromptSelectedTerm> terms = const [],
}) => PromptTranslationEditRequest(
  direction: direction,
  source: source,
  zh: zh,
  baselineSource: 'blue eyes',
  baselineZh: '蓝眼睛',
  selectedTerms: terms,
);

void main() {
  test(
    'request keeps both reference fields and drops deleted picked phrases',
    () {
      final data =
          jsonDecode(
                request(
                  terms: const [
                    PromptSelectedTerm(start: 0, text: '蓝眼睛', tag: 'blue_eyes'),
                    PromptSelectedTerm(start: 4, text: '红头发', tag: 'red_hair'),
                    PromptSelectedTerm(
                      start: -1,
                      text: '蓝眼睛',
                      tag: 'blue_eyes',
                    ),
                  ],
                ).requestJson(const []),
              )
              as Map;
      expect(data['direction'], 'toSource');
      expect(data['original_source'], 'blue eyes');
      expect(data['current_source'], contains('artist:'));
      expect(data['selected_terms'], [
        {'text': '蓝眼睛', 'tag': 'blue_eyes', 'start': 0},
      ]);
    },
  );

  test(
    'picked ranges shift with prefix edits and disappear on replacement',
    () {
      const terms = [
        PromptSelectedTerm(start: 3, text: '蓝眼睛', tag: 'blue_eyes'),
      ];
      final shifted = PromptSelectedTerm.afterEdit(
        terms,
        '微笑，蓝眼睛',
        '微笑，长发，蓝眼睛',
      );
      expect(shifted.single.start, 6);
      expect(
        PromptSelectedTerm.afterEdit(shifted, '微笑，长发，蓝眼睛', '微笑，长发，绿眼睛'),
        isEmpty,
      );
      expect(
        PromptSelectedTerm.afterEdit(terms, '微笑，蓝眼睛', '蓝眼睛').single.start,
        0,
      );
      expect(PromptSelectedTerm.afterEdit(terms, '微笑，蓝眼睛', '微笑，'), isEmpty);
      expect(
        PromptSelectedTerm.afterEdit(terms, '微笑，蓝眼睛', '微笑，蓝眼睛，长发').single.start,
        3,
      );
    },
  );

  for (final raw in [
    'not json',
    '{"text":""}',
    '{"source":"blue eyes"}',
    '{"text":42}',
    '{"text":"```blue```"}',
    jsonEncode({'text': '\uE000'}),
  ]) {
    test('reject invalid response $raw', () {
      expect(
        () => PromptTranslationEditResult.parse(raw, request(), const []),
        throwsFormatException,
      );
    });
  }
  for (final text in [
    '{blue eyes',
    'blue eyes}',
    '1.3::blue eyes',
    'blue eyes::',
  ]) {
    test('reject broken prompt syntax $text', () {
      expect(
        () => PromptTranslationEditResult.parse(
          jsonEncode({'text': text}),
          request(),
          const [],
        ),
        throwsFormatException,
      );
    });
  }
  test('accept weights, groups and escaped punctuation without rewriting', () {
    const text =
        r'1.4::{green eyes}, [smile]::, character\(name\), artist:asteroid_ill';
    expect(
      PromptTranslationEditResult.parse(
        jsonEncode({'text': text}),
        request(),
        const [],
      ).text,
      text,
    );
  });
  test('Chinese annotations require a whole verified source tag', () {
    const glossary = [
      {'tag': 'kagamine_rin', 'icon_id': 'character'},
      {'tag': 'rin', 'icon_id': 'character'},
    ];
    final draft = request(
      direction: PromptTranslationDirection.toChinese,
      source: 'kagamine rin',
    );
    final result = PromptTranslationEditResult.parse(
      jsonEncode({
        'text': '镜音铃，铃',
        'parts': [
          {'text': '镜音铃', 'tag': 'kagamine_rin'},
          {'text': '，'},
          {'text': '铃', 'tag': 'rin'},
        ],
      }),
      draft,
      glossary,
    );
    expect(result.marks.single.tag, 'kagamine_rin');
    expect(result.marks.single.start, 0);
    final mismatched = PromptTranslationEditResult.parse(
      jsonEncode({
        'text': '镜音铃',
        'parts': [
          {'text': '错误', 'tag': 'kagamine_rin'},
        ],
      }),
      draft,
      glossary,
    );
    expect(mismatched.text, '镜音铃');
    expect(mismatched.marks, isEmpty);
  });
}
