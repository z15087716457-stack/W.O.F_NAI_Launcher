import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';

void main() {
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
