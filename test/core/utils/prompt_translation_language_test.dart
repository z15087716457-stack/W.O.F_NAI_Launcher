import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_translation_document.dart';
import 'package:nai_launcher/core/utils/prompt_translation_edit.dart';
import 'package:nai_launcher/core/utils/prompt_translation_language.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

void main() {
  test(
    'legacy blocks keep Chinese and malformed metadata falls back safely',
    () {
      for (final value in [null, 'unsupported', 12]) {
        final pill = TranslationPill.fromJson({
          'source': 'blue eyes',
          'zh': '蓝眼睛',
          'languageCode': value,
        });
        expect(pill.languageCode, 'zh');
        expect(pill.translationEdited, isFalse);
      }
      expect(
        PromptTranslationLanguage.fromCode('ja-JP'),
        PromptTranslationLanguage.japanese,
      );
      expect(
        PromptTranslationLanguage.fromCode('ko_KR'),
        PromptTranslationLanguage.korean,
      );
    },
  );

  for (final language in PromptTranslationLanguage.values) {
    test(
      '${language.code} readings retain metadata through JSON and copies',
      () {
        final pill = TranslationPill(
          source: '1.2::{blue eyes}::',
          zh: 'reading',
          languageCode: language.code,
          needsReview: true,
          translationEdited: true,
        );
        final restored = TranslationPill.fromJson(
          jsonDecode(jsonEncode(pill.toJson())) as Map<String, dynamic>,
        );
        expect(restored, pill);
        expect(restored.hashCode, pill.hashCode);
        expect(
          restored.copyWith(showOriginal: true).languageCode,
          language.code,
        );
        expect(
          restored.copyWith(source: 'green eyes').translationEdited,
          isTrue,
        );
        expect(restored.source, '1.2::{blue eyes}::');
      },
    );

    test(
      '${language.code} batch stamps requested language on resulting blocks',
      () {
        final batch = PromptTranslationBatch.prepare({
          'main': const PillDocument(text: 'blue eyes', instances: {}),
        });
        expect(
          (jsonDecode(batch.requestJson([], languageCode: language.code))
              as Map)['target_language'],
          language.code,
        );
        final id = batch.segments['main']!.single.id;
        final rebuilt = batch.parseAndBuild(
          jsonEncode({
            'fields': [
              {
                'id': 'main',
                'groups': [
                  {
                    'ids': [id],
                    'zh': 'reading',
                  },
                ],
              },
            ],
          }),
          languageCode: language.code,
        )['main']!;
        final pill = rebuilt.instances.values.single.translation!;
        expect(pill.languageCode, language.code);
        expect(pill.source, 'blue eyes');
        expect(pill.translationEdited, isFalse);
      },
    );
  }

  test(
    'conversion distinguishes existing reading language from requested output',
    () {
      PromptTranslationEditRequest request(
        PromptTranslationDirection direction,
      ) => PromptTranslationEditRequest(
        direction: direction,
        source: 'blue eyes',
        zh: '青い目',
        baselineSource: 'blue eyes',
        baselineZh: '青い目',
        languageCode: 'ja',
        targetLanguageCode: 'ko',
      );
      final down =
          jsonDecode(
                request(PromptTranslationDirection.toChinese).requestJson([]),
              )
              as Map;
      final up =
          jsonDecode(
                request(PromptTranslationDirection.toSource).requestJson([]),
              )
              as Map;
      expect(down['reading_language'], 'ja');
      expect(down['target_language'], 'ko');
      expect(up['reading_language'], 'ja');
      expect(up['target_language'], 'en');
    },
  );
}
