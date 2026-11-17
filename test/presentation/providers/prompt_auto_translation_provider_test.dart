import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_translation_glossary.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_auto_translation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_translation_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_translation_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';

import '../../helpers/empty_tag_expansion.dart';
import '../../helpers/fake_tag_translation_glossary.dart';

void main() {
  late ProviderContainer container;
  late _Service service;
  late _Memory memory;
  late List<Map<String, dynamic>> requests;
  late Future<String> Function(Map<String, dynamic>) respond;
  final editor = Object();
  var active = true;

  setUp(() {
    memory = _Memory();
    service = _Service();
    requests = [];
    active = true;
    respond = (request) async => _reply(request);
    when(
      () => service.cancelCurrentTask(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async {});
    when(
      () => service.translatePromptGroup(
        any(),
        sessionId: any(named: 'sessionId'),
        validateOutput: any(named: 'validateOutput'),
      ),
    ).thenAnswer((call) async {
      final request =
          jsonDecode(call.positionalArguments.single as String)
              as Map<String, dynamic>;
      requests.add(request);
      final raw = await respond(request);
      (call.namedArguments[#validateOutput] as void Function(String)?)?.call(
        raw,
      );
      return raw;
    });
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(memory),
        promptAssistantConfigProvider.overrideWith((ref) => _Config()),
        promptAssistantServiceProvider.overrideWithValue(service),
        unifiedTagRepositoryProvider.overrideWith((ref) => _Tags()),
        tagTranslationGlossaryProvider.overrideWith((ref) => _Glossary()),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        characterPromptNotifierProvider.overrideWith(_Characters.new),
        emptyTagExpansionOverride,
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> enable() => container
      .read(promptAutoTranslationEnabledProvider.notifier)
      .setEnabled(true);
  void edit(
    String text, {
    String scope = PillScopes.main,
    TextRange composing = TextRange.empty,
  }) {
    final value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: composing,
    );
    container
        .read(pillWorkspaceProvider(scope).notifier)
        .setText(text, userEdit: true);
    container
        .read(promptAutoTranslationProvider)
        .edited(
          editor: editor,
          scope: scope,
          value: value,
          isActive: () => active,
        );
  }

  testWidgets('default off persists a deliberate choice', (t) async {
    expect(container.read(promptAutoTranslationEnabledProvider), isFalse);
    edit('soft light');
    await t.pump(const Duration(seconds: 2));
    expect(requests, isEmpty);
    await enable();
    expect(memory.values[PromptAutoTranslationEnabled.storageKey], isTrue);
    final reopened = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(memory)],
    );
    expect(reopened.read(promptAutoTranslationEnabledProvider), isTrue);
    reopened.dispose();
  });

  testWidgets('debounces and translates only the changed field and ranges', (
    t,
  ) async {
    await enable();
    edit('soft');
    await t.pump(const Duration(milliseconds: 500));
    edit('soft light');
    await t.pump(const Duration(milliseconds: 799));
    expect(requests, isEmpty);
    await t.pump(const Duration(milliseconds: 1));
    expect(requests, hasLength(1));
    expect(requests.single['fields'], hasLength(1));
    expect(
      container.read(pillWorkspaceNotifierProvider).document.readings,
      hasLength(1),
    );
    edit('soft light, silver hair');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, hasLength(2));
    expect(_sources(requests.last).join(), contains('silver hair'));
    expect(_sources(requests.last).join(), isNot(contains('soft light')));
    await t.pump(const Duration(seconds: 5));
    expect(requests, hasLength(2));
  });

  testWidgets('one in flight keeps just the latest pending edit', (t) async {
    await enable();
    final first = Completer<String>();
    respond = (request) =>
        requests.length == 1 ? first.future : Future.value(_reply(request));
    edit('old text');
    await t.pump(const Duration(milliseconds: 800));
    edit('intermediate text');
    await t.pump(const Duration(milliseconds: 800));
    edit('latest text');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, hasLength(1));
    first.complete(_reply(requests.first));
    await t.pump();
    expect(requests, hasLength(2));
    expect(_sources(requests.last).join(), 'latest text');
    final document = container.read(pillWorkspaceNotifierProvider).document;
    expect(document.text, 'latest text');
    expect(document.readings.single.source, 'latest text');
  });

  testWidgets('waits for manual translation before sending the latest edit', (
    t,
  ) async {
    await enable();
    container.read(promptTranslationBusyProvider.notifier).state = true;
    edit('old text');
    await t.pump(const Duration(milliseconds: 800));
    edit('latest text');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, isEmpty);
    container.read(promptTranslationBusyProvider.notifier).state = false;
    await t.pump();
    expect(requests, hasLength(1));
    expect(_sources(requests.single).join(), 'latest text');
  });

  testWidgets(
    'IME waits for composition commit even when text stays the same',
    (t) async {
      await enable();
      edit('soft light', composing: const TextRange(start: 0, end: 4));
      await t.pump(const Duration(seconds: 2));
      expect(requests, isEmpty);
      edit('soft light');
      await t.pump(const Duration(milliseconds: 800));
      expect(requests, hasLength(1));
    },
  );

  testWidgets('valid empty IME ranges also wait for composition end', (
    t,
  ) async {
    await enable();
    edit('soft light', composing: const TextRange(start: 10, end: 10));
    await t.pump(const Duration(seconds: 2));
    expect(requests, isEmpty);
    edit('soft light');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, hasLength(1));
  });

  for (final stop in [
    'off',
    'blocks',
    'hidden',
    'cleared',
    'inactive',
    'unmounted',
    'route',
  ]) {
    testWidgets('$stop discards pending automatic work', (t) async {
      await enable();
      edit('soft light');
      switch (stop) {
        case 'off':
          await container
              .read(promptAutoTranslationEnabledProvider.notifier)
              .setEnabled(false);
        case 'blocks':
          await container
              .read(promptTranslationModeProvider.notifier)
              .select(PromptTranslationMode.blocks);
        case 'hidden':
          final before = container.read(pillWorkspaceNotifierProvider).document;
          container
              .read(pillWorkspaceNotifierProvider.notifier)
              .replaceIfCurrent(
                before,
                before.copyWith(readingsVisible: false),
              );
        case 'cleared':
          container.read(promptAutoTranslationProvider).suspend();
        case 'inactive':
          active = false;
        case 'unmounted':
          container.read(promptAutoTranslationProvider).forget(editor);
        case 'route':
          (container.read(promptAssistantConfigProvider.notifier) as _Config)
              .removeRoute();
      }
      await t.pump(const Duration(seconds: 3));
      expect(requests, isEmpty);
    });
  }

  testWidgets('disabling cancels the session and rejects a late response', (
    t,
  ) async {
    await enable();
    final pending = Completer<String>();
    respond = (_) => pending.future;
    edit('soft light');
    await t.pump(const Duration(milliseconds: 800));
    await container
        .read(promptAutoTranslationEnabledProvider.notifier)
        .setEnabled(false);
    verify(
      () => service.cancelCurrentTask(sessionId: 'prompt-auto-main'),
    ).called(1);
    pending.complete(_reply(requests.single));
    await t.pump();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.readings,
      isEmpty,
    );
    expect(container.read(promptAutoTranslationFailuresProvider), isEmpty);
  });

  testWidgets('automatic annotations never add a source undo step', (t) async {
    await enable();
    final workspace = container.read(pillWorkspaceNotifierProvider.notifier);
    workspace.replaceWithPlainText('previous text');
    workspace.closeTypingGroup();
    edit('next text');
    await t.pump(const Duration(milliseconds: 800));
    expect(
      container.read(pillWorkspaceNotifierProvider).document.readings,
      hasLength(1),
    );
    workspace.undo();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.text,
      'previous text',
    );
    workspace.redo();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.text,
      'next text',
    );
    expect(
      container.read(pillWorkspaceNotifierProvider).document.readings,
      hasLength(1),
    );
    expect(
      container.read(promptTranslationCoordinatorProvider).canUndoLast,
      isFalse,
    );
  });

  testWidgets('same-language tag cache avoids a model request', (t) async {
    await enable();
    edit('1.3::blue_eyes::,');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, isEmpty);
    final document = container.read(pillWorkspaceNotifierProvider).document;
    expect(document.text, '1.3::blue_eyes::,');
    expect(document.readings.single.translation, '蓝眼睛');
    expect(document.readings.single.languageCode, 'zh');
  });

  testWidgets('mixed cached tags and sentences request only missing readings', (
    t,
  ) async {
    await enable();
    edit('blue_eyes, soft light');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, hasLength(1));
    expect(_sources(requests.single).join().trim(), 'soft light');
    final document = container.read(pillWorkspaceNotifierProvider).document;
    expect(document.text, 'blue_eyes, soft light');
    expect(document.readings.map((item) => item.translation), ['蓝眼睛', '译文']);
  });

  testWidgets('failure is quiet and cannot retry forever', (t) async {
    await enable();
    respond = (_) async => '{"fields":[]}';
    edit('soft light');
    await t.pump(const Duration(milliseconds: 800));
    expect(container.read(promptAutoTranslationFailuresProvider), {
      PillScopes.main,
    });
    await t.pump(const Duration(seconds: 20));
    expect(requests, hasLength(1));
    respond = (request) async => _reply(request);
    edit('soft light, smiling');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, hasLength(2));
    expect(container.read(promptAutoTranslationFailuresProvider), isEmpty);
  });

  testWidgets('character and negative scopes do not request other fields', (
    t,
  ) async {
    await enable();
    edit('soft light', scope: PillScopes.charNeg('active'));
    await t.pump(const Duration(milliseconds: 800));
    expect(
      (requests.single['fields'] as List).single['id'],
      PillScopes.charNeg('active'),
    );
    expect(
      container.read(pillWorkspaceNotifierProvider).document.readings,
      isEmpty,
    );
  });

  testWidgets(
    'real editor typing schedules once; selection and readings do not',
    (t) async {
      await enable();
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: PromptPillEditor(
                  config: UnifiedPromptConfig(embedded: true),
                  enableAutomaticTranslation: true,
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      final field = find.byType(EditableText).first;
      await t.enterText(field, 'soft light');
      await t.pump(const Duration(milliseconds: 799));
      expect(requests, isEmpty);
      await t.pump(const Duration(milliseconds: 1));
      expect(requests, hasLength(1));
      t.widget<EditableText>(field).controller.selection =
          const TextSelection.collapsed(offset: 2);
      await t.pump(const Duration(seconds: 3));
      expect(requests, hasLength(1));
      expect(
        container.read(pillWorkspaceNotifierProvider).document.text,
        'soft light',
      );
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('translation finishing during IME never rewrites its buffer', (
    t,
  ) async {
    await enable();
    final response = Completer<String>();
    respond = (request) =>
        requests.length == 1 ? response.future : Future.value(_reply(request));
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: PromptPillEditor(
                config: UnifiedPromptConfig(embedded: true),
                enableAutomaticTranslation: true,
              ),
            ),
          ),
        ),
      ),
    );
    final field = find.byType(EditableText).first;
    await t.enterText(field, 'soft light');
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, hasLength(1));
    final view = t.widget<EditableText>(field).controller;
    view.selection = const TextSelection.collapsed(offset: 5);
    await t.pump();
    t.testTextInput.log.clear();
    final begin = view.value.copyWith(
      composing: const TextRange(start: 5, end: 5),
    );
    t.testTextInput.updateEditingValue(begin);
    await t.pump();
    response.complete(_reply(requests.single));
    await t.pump();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.readings,
      hasLength(1),
    );
    expect(view.value, begin);
    for (final letters in ['a', 'as', "a's'd", '阿斯顿']) {
      final next = TextEditingValue(
        text: 'soft ${letters}light',
        selection: TextSelection.collapsed(offset: 5 + letters.length),
        composing: TextRange(start: 5, end: 5 + letters.length),
      );
      t.testTextInput.updateEditingValue(next);
      await t.pump(const Duration(seconds: 1));
      expect(view.value, next);
      expect(requests, hasLength(1));
    }
    expect(
      t.testTextInput.log.where(
        (call) => call.method == 'TextInput.setEditingState',
      ),
      isEmpty,
    );
    t.testTextInput.updateEditingValue(
      view.value.copyWith(composing: TextRange.empty),
    );
    await t.pump(const Duration(milliseconds: 800));
    expect(requests, hasLength(2));
    expect(
      container.read(pillWorkspaceNotifierProvider).document.text,
      'soft 阿斯顿light',
    );
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump();
    expect(t.takeException(), isNull);
  });

  for (final started in [false, true]) {
    testWidgets('disabling the editor cancels work started=$started', (
      t,
    ) async {
      await enable();
      final response = Completer<String>();
      respond = (_) => response.future;
      var enabled = true;
      late StateSetter rebuild;
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Scaffold(
                  body: PromptPillEditor(
                    config: const UnifiedPromptConfig(embedded: true),
                    enableAutomaticTranslation: enabled,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await t.enterText(find.byType(EditableText).first, 'soft light');
      if (started) await t.pump(const Duration(milliseconds: 800));
      rebuild(() => enabled = false);
      await t.pump();
      if (started) response.complete(_reply(requests.single));
      await t.pump(const Duration(seconds: 2));
      expect(requests, hasLength(started ? 1 : 0));
      expect(
        container.read(pillWorkspaceNotifierProvider).document.readings,
        isEmpty,
      );
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}

List<String> _sources(Map<String, dynamic> request) => [
  for (final field in request['fields'] as List)
    for (final item in field['segments'] as List) item['source'] as String,
];

String _reply(Map<String, dynamic> request) => jsonEncode({
  'fields': [
    for (final field in request['fields'] as List)
      {
        'id': field['id'],
        'groups': [
          for (final item in field['segments'] as List)
            {
              'ids': [item['id']],
              'readings': [
                {'source': item['source'], 'zh': '译文'},
              ],
            },
        ],
      },
  ],
});

class _Memory extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

class _Service extends Mock implements PromptAssistantService {}

class _Config extends StateNotifier<PromptAssistantConfigState>
    implements PromptAssistantConfigNotifier {
  _Config()
    : super(
        const PromptAssistantConfigState(
          providers: [
            ProviderConfig(
              id: 'test',
              name: 'Test',
              baseUrl: 'https://example.test/v1',
            ),
          ],
          models: [
            ModelConfig(
              providerId: 'test',
              name: 'test-model',
              displayName: 'Test model',
            ),
          ],
          interfaces: {
            LauncherInterface.translate: InterfaceSlotConfig(
              providerId: 'test',
              model: 'test-model',
            ),
          },
          providerHasApiKey: {},
        ),
      );
  void removeRoute() => state = state.copyWith(interfaces: {});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tags extends UnifiedTagRepository {
  _Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async => throw StateError('not used'),
      );
  @override
  Future<List<CompletionCandidate>> byNames(Iterable<String> names) async => [
    if (names.contains('blue_eyes'))
      const CompletionCandidate(
        canonicalTag: 'blue_eyes',
        category: TagCategory.general,
        postCount: 1,
        matchKind: CompletionMatchKind.englishExact,
        sources: {CompletionSourceKind.base},
      ),
  ];
}

class _Cache extends VisibleTagTranslationCache {
  @override
  Future<Map<String, CachedVisibleTagTranslation>> chineseTerms(
    Iterable<String> tags,
  ) async => {
    if (tags.contains('blue_eyes'))
      'blue_eyes': const CachedVisibleTagTranslation(
        nameZh: '蓝眼睛',
        nameLanguage: 'zh',
      ),
  };
}

class _Glossary extends FakeTagTranslationGlossary {
  @override
  VisibleTagTranslationCache get cache => _Cache();
}

class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() =>
      const CharacterPromptConfig(characters: [CharacterPrompt(id: 'active')]);
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}
