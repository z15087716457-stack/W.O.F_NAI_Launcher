import 'package:nai_launcher/core/wiki/tag_translation_glossary.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';

/// No application files, caches or model requests are touched in service tests.
class FakeTagTranslationGlossary implements TagTranslationGlossary {
  const FakeTagTranslationGlossary();
  @override
  TagWikiRepository get wiki => throw StateError('not used');
  @override
  VisibleTagTranslationCache get cache => throw StateError('not used');
  @override
  Future<Map<String, Map<String, String>>> termsFor(
    Iterable<String> tags,
  ) async => {
    for (final tag in tags)
      if (tag == 'blue_eyes')
        tag: {
          'zh': '蓝眼睛',
          'definition': '虹膜呈蓝色的眼睛。',
          'definition_language': 'zh',
        }
      else if (tag == 'kagamine_rin')
        tag: {
          'zh': '镜音铃',
          'definition': '名为镜音铃的虚拟歌手角色。',
          'definition_language': 'zh',
        },
  };
}
