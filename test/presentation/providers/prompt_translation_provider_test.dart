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
      expect(
        tags.lookups.any((lookup) => lookup.contains('kagamine_rin')),
        isTrue,
      );
      final coordinator = container.read(promptTranslationCoordinatorProvider);
      final before = container.read(pillWorkspaceNotifierProvider).document;
      expect(coordinator.canUndoLast, isTrue);
      coordinator.clearTranslations(false);
      expect(coordinator.canUndoLast, isFalse);
      expect(coordinator.restoreTranslations(false), isTrue);
      expect(container.read(pillWorkspaceNotifierProvider).document, before);
      expect(coordinator.canUndoLast, isTrue);
      expect(coordinator.undoLast(), isTrue);
      expect(
        container.read(pillWorkspaceNotifierProvider).document.text,
        'portrait of Rin Kagamine, blue eyes',
      );
    },
  );

  test(
    'plain text conversion and restore include disabled roles on the selected side',
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
      final before = {
        for (final scope in [
          PillScopes.main,
          PillScopes.charPos('active'),
          PillScopes.charPos('disabled'),
        ])
          scope: container.read(pillWorkspaceProvider(scope)).document,
      };
      expect(coordinator.hasAnyTranslations(false), isTrue);
      expect(coordinator.canRestoreTranslations(false), isFalse);
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
      expect(coordinator.canRestoreTranslations(false), isTrue);
      expect(coordinator.restoreTranslations(false), isTrue);
      for (final entry in before.entries) {
        expect(
          container.read(pillWorkspaceProvider(entry.key)).document,
          entry.value,
        );
      }
      expect(coordinator.canRestoreTranslations(false), isFalse);
      expect(coordinator.clearTranslations(false), 3);
      expect(coordinator.restoreTranslations(false), isTrue);
      expect(coordinator.clearTranslations(false), 3);
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

  test(
    'restore preserves repeated blocks, tag marks, display and library blocks',
    () {
      final container = _testContainer();
      final main = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      const translation = TranslationPill(
        source: '1.2::blue eyes::',
        zh: '1.2::蓝眼睛::',
        showOriginal: true,
        needsReview: true,
        marks: [
          TranslationTagMark(
            start: 5,
            end: 8,
            tag: 'blue_eyes',
            iconId: 'general',
          ),
        ],
      );
      const before = PillDocument(
        text: 'prefix, \uE000, \uE001, \uE000',
        instances: {
          '\uE000': PillInstance(blockId: '', translation: translation),
          '\uE001': PillInstance(blockId: 'library-block', locked: true),
        },
      );
      expect(main.replaceIfCurrent(PillDocument.empty(), before), isTrue);
      final projection = container
          .read(pillWorkspaceNotifierProvider)
          .projection;
      final coordinator = container.read(promptTranslationCoordinatorProvider);

      expect(coordinator.clearTranslations(false), 1);
      final plain = container.read(pillWorkspaceNotifierProvider);
      expect(
        plain.document.text,
        'prefix, 1.2::blue eyes::, \uE001, 1.2::blue eyes::',
      );
      expect(plain.document.instances, {'\uE001': before.instances['\uE001']});
      expect(plain.projection, projection);
      expect(coordinator.restoreTranslations(false), isTrue);
      expect(container.read(pillWorkspaceNotifierProvider).document, before);
      expect(
        container.read(pillWorkspaceNotifierProvider).projection,
        projection,
      );
    },
  );

  test('positive and negative plain text undo histories stay independent', () {
    final container = _testContainer();
    for (final scope in [PillScopes.main, PillScopes.negative]) {
      container
          .read(pillWorkspaceProvider(scope).notifier)
          .insertTranslationAt(offset: 0, source: '$scope original', zh: '译文');
    }
    final coordinator = container.read(promptTranslationCoordinatorProvider);
    expect(coordinator.clearTranslations(false), 1);
    expect(coordinator.clearTranslations(true), 1);
    expect(coordinator.canRestoreTranslations(false), isTrue);
    expect(coordinator.canRestoreTranslations(true), isTrue);
    expect(coordinator.restoreTranslations(false), isTrue);
    expect(coordinator.hasAnyTranslations(false), isTrue);
    expect(coordinator.hasAnyTranslations(true), isFalse);
    expect(coordinator.canRestoreTranslations(true), isTrue);
    expect(coordinator.restoreTranslations(true), isTrue);
    expect(coordinator.hasAnyTranslations(true), isTrue);
  });

  test(
    'restore skips newer edits and removed roles but restores untouched fields',
    () {
      final container = _testContainer();
      for (final scope in [
        PillScopes.main,
        PillScopes.charPos('active'),
        PillScopes.charPos('disabled'),
      ]) {
        container
            .read(pillWorkspaceProvider(scope).notifier)
            .insertTranslationAt(
              offset: 0,
              source: '$scope original',
              zh: '译文',
            );
      }
      final coordinator = container.read(promptTranslationCoordinatorProvider);
      coordinator.clearTranslations(false);
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .setText('new edit');
      (container.read(characterPromptNotifierProvider.notifier) as _Characters)
          .removeForTest('active');

      expect(coordinator.canRestoreTranslations(false), isTrue);
      expect(coordinator.restoreTranslations(false), isTrue);
      expect(
        container.read(pillWorkspaceNotifierProvider).document.text,
        'new edit',
      );
      expect(
        container.read(pillWorkspaceNotifierProvider).document.instances,
        isEmpty,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.charPos('active')))
            .document
            .instances,
        isEmpty,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.charPos('disabled')))
            .document
            .instances
            .length,
        1,
      );
      expect(coordinator.canRestoreTranslations(false), isFalse);
    },
  );

  test(
    'busy translation blocks conversion and restoration without losing undo',
    () {
      final container = _testContainer();
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertTranslationAt(offset: 0, source: 'blue eyes', zh: '蓝眼睛');
      final coordinator = container.read(promptTranslationCoordinatorProvider);
      container.read(promptTranslationBusyProvider.notifier).state = true;
      expect(coordinator.clearTranslations(false), 0);
      expect(coordinator.hasAnyTranslations(false), isTrue);
      container.read(promptTranslationBusyProvider.notifier).state = false;
      expect(coordinator.clearTranslations(false), 1);
      container.read(promptTranslationBusyProvider.notifier).state = true;
      expect(coordinator.restoreTranslations(false), isFalse);
      expect(coordinator.canRestoreTranslations(false), isTrue);
      container.read(promptTranslationBusyProvider.notifier).state = false;
      expect(coordinator.restoreTranslations(false), isTrue);
    },
  );
}

ProviderContainer _testContainer() {
  final container = ProviderContainer(
    overrides: [
      characterPromptNotifierProvider.overrideWith(_Characters.new),
      promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
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
  void removeForTest(String id) => state = state.removeCharacter(id);

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
