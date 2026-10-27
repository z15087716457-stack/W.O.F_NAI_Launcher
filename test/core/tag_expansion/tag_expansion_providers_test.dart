import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/cooccurrence_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';

class _Catalog extends Mock implements UnifiedTagRepository {}

class _Related extends Mock implements CooccurrenceCompletionSource {}

class _Assistant extends Mock implements PromptAssistantService {}

class _Semantics extends TagSemanticsRepository {
  _Semantics()
    : super(
        () async => File('assets/databases/tag_semantics.db').absolute.path,
      );
  final batches = <List<String>>[];
  @override
  Future<Map<String, TagSemanticProfile>> findAll(Iterable<String> tags) {
    batches.add(tags.toList());
    return super.findAll(tags);
  }
}

const _eyes = CompletionCandidate(
  canonicalTag: 'green_eyes',
  category: TagCategory.general,
  postCount: 100,
  matchKind: CompletionMatchKind.englishPrefix,
  sources: {CompletionSourceKind.base},
);

void main() {
  setUpAll(
    () => registerFallbackValue(
      const CompletionQuery(
        fullText: '',
        cursorPosition: 0,
        token: '',
        replacementRange: TextReplacementRange(start: 0, end: 0),
        existingTags: {},
        limit: 12,
        locale: 'zh',
      ),
    ),
  );

  test(
    'production provider maps imported Chinese names and batches all local readings once',
    () async {
      final catalog = _Catalog();
      final related = _Related();
      final assistant = _Assistant();
      var reading = 'zh';
      when(
        () => assistant.targetLanguageFor(LauncherInterface.tagTranslate),
      ).thenAnswer((_) => reading);
      when(() => catalog.byNames(any())).thenAnswer(
        (call) async => [
          if ((call.positionalArguments.single as Iterable<String>).contains(
            'green_eyes',
          ))
            _eyes,
        ],
      );
      when(() => catalog.search(any())).thenAnswer((_) async => [_eyes]);
      when(
        () => catalog.searchContains(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);
      when(() => related.search(any())).thenAnswer((_) async => [_eyes]);
      final semantics = _Semantics();
      final container = ProviderContainer(
        overrides: [
          unifiedTagRepositoryProvider.overrideWithValue(catalog),
          cooccurrenceCompletionSourceProvider.overrideWithValue(related),
          promptAssistantServiceProvider.overrideWithValue(assistant),
          tagSemanticsRepositoryProvider.overrideWithValue(semantics),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(localTagExpansionServiceProvider);
      final chinese = await service.search('绿眼睛', locale: 'en');
      expect(chinese.single.canonicalTag, 'green_eyes');
      expect(chinese.single.translation, '绿眼睛');
      expect(chinese.single.matchKind, CompletionMatchKind.chineseExact);
      expect(semantics.batches, [
        ['green_eyes'],
      ]);
      verifyNever(() => catalog.search(any()));
      verifyNever(
        () => catalog.searchContains(any(), limit: any(named: 'limit')),
      );
      final english = await service.search('green', locale: 'en');
      expect(english.single.translation, '绿眼睛');
      expect(semantics.batches, hasLength(2));
      expect(
        (await service.related('hair', locale: 'en')).single.translation,
        '绿眼睛',
      );
      expect(semantics.batches, hasLength(3));
      reading = 'ja';
      final japanese = await service.search('绿眼睛', locale: 'zh');
      expect(japanese.single.canonicalTag, 'green_eyes');
      expect(japanese.single.translation, isNull);
      expect(semantics.batches, hasLength(3));
    },
  );
}
