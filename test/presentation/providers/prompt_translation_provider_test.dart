import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/tag_translation_lookup.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/autocomplete/zh_dictionary_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_translation_provider.dart';

void main() {
  test(
    'model proposal is marked only after local catalog verification',
    () async {
      final service = _TranslationService();
      final tags = _Tags();
      when(
        () => service.translatePromptGroup(
          any(),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => jsonEncode({
          'fields': [
            {
              'id': 'main',
              'groups': [
                {
                  'ids': ['main:0', 'main:1'],
                  'zh': '镜音铃，蓝眼睛',
                  'parts': [
                    {
                      'text': '镜音铃',
                      'tag': 'kagamine_rin',
                      'source_id': 'main:0',
                    },
                    {'text': '，'},
                    {'text': '蓝眼睛', 'tag': 'blue_eyes', 'source_id': 'main:1'},
                  ],
                },
              ],
            },
          ],
        }),
      );
      final container = ProviderContainer(
        overrides: [
          characterPromptNotifierProvider.overrideWith(_Characters.new),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
          promptAssistantServiceProvider.overrideWith((ref) => service),
          unifiedTagRepositoryProvider.overrideWith((ref) => tags),
          tagTranslationLookupProvider.overrideWith((ref) => _Translations()),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .setText('portrait of Rin Kagamine, blue eyes');

      final result = await container
          .read(promptTranslationCoordinatorProvider)
          .translate(false);
      expect(result.convertedFields, 1);
      final pill = container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances
          .values
          .single
          .translation!;
      expect(pill.source, 'portrait of Rin Kagamine, blue eyes');
      expect(pill.zh, '镜音铃，蓝眼睛');
      expect(pill.marks, [
        const TranslationTagMark(
          start: 0,
          end: 3,
          tag: 'kagamine_rin',
          iconId: 'character',
        ),
      ]);
    expect(tags.lookups.any((lookup) => lookup.contains('kagamine_rin')), isTrue);
    },
  );

  test(
    'clear translations restores the selected side including disabled roles',
    () {
      final container = ProviderContainer(
        overrides: [
          characterPromptNotifierProvider.overrideWith(_Characters.new),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        ],
      );
      addTearDown(container.dispose);
      for (final scope in [
        PillScopes.main,
        PillScopes.charPos('active'),
        PillScopes.charPos('disabled'),
      ]) {
        container
            .read(pillWorkspaceProvider(scope).notifier)
            .insertTranslationAt(offset: 0, source: '$scope text', zh: '译文');
      }
      container
          .read(pillWorkspaceProvider(PillScopes.negative).notifier)
          .insertTranslationAt(offset: 0, source: 'negative text', zh: '负面');

      final coordinator = container.read(promptTranslationCoordinatorProvider);
      expect(coordinator.hasAnyTranslations(false), isTrue);
      expect(coordinator.clearTranslations(false), 3);
      for (final scope in [
        PillScopes.main,
        PillScopes.charPos('active'),
        PillScopes.charPos('disabled'),
      ]) {
        final state = container.read(pillWorkspaceProvider(scope));
        expect(state.document.text, '$scope text');
        expect(state.document.instances, isEmpty);
      }
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.negative))
            .document
            .instances
            .length,
        1,
      );
      expect(coordinator.hasAnyTranslations(false), isFalse);
      final main = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      main.setText('\uE000');
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances,
        isEmpty,
      );
    },
  );
}

class _TranslationService extends Mock implements PromptAssistantService {}

class _Tags extends UnifiedTagRepository {
  _Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async => throw StateError('not used'),
      );

  final List<Set<String>> lookups = [];

  @override
  Future<List<CompletionCandidate>> byNames(Iterable<String> names) async {
    final lookup = names.toSet();
    lookups.add(lookup);
    return [
      for (final (name, category) in [
        ('blue_eyes', TagCategory.general),
        ('kagamine_rin', TagCategory.character),
      ])
        if (lookup.contains(name))
          CompletionCandidate(
            canonicalTag: name,
            category: category,
            postCount: 1,
            matchKind: CompletionMatchKind.englishExact,
            sources: const {CompletionSourceKind.base},
          ),
    ];
  }
}

class _Translations extends TagTranslationLookup {
  _Translations() : super(ZhDictionaryService());

  @override
  Future<Map<String, String>> translateBatch(List<String> tags) async =>
      const {};
}

class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig(
    characters: [
      CharacterPrompt(id: 'active'),
      CharacterPrompt(id: 'disabled', enabled: false),
    ],
  );
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}
