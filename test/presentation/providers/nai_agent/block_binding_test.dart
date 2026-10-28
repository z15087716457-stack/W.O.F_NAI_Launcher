import 'dart:convert';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/core/storage/pill_workspace_storage.dart';
import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_block_binding.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/wiring/blocks_actions.dart';
import 'package:nai_launcher/presentation/wiring/blocks_mapping.dart';
import 'package:nai_launcher/presentation/utils/prompt_block_generation_settings_applier.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters, OfflineAuth, IdleGeneration;

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async {
    final data = await ref.read(promptBlockRepositoryProvider).load();
    return PromptBlockLibraryState(
      blocks: data.blocks,
      folders: data.folders,
      collections: data.collections,
    );
  }
}

class _ProjectionMismatch extends PillWorkspaceNotifier {
  @override
  List<String> applyInlineEdits(
    List<PillInlineEdit> edits, {
    String prefix = '',
    void Function()? afterApply,
    PillDocument? document,
  }) => super.applyInlineEdits(
    edits,
    prefix: prefix,
    document: document,
    afterApply: () {
      state = state.copyWith(projection: 'synthetic mismatch');
      afterApply?.call();
    },
  );
}

class _Preferences extends BlocksPreferencesNotifier {
  bool fail = false;
  int calls = 0;

  @override
  Future<void> recordUse(String id) {
    calls++;
    if (fail) return Future.error(StateError('Synthetic preference failure'));
    return super.recordUse(id);
  }
}

class _Vibes extends VibeLibraryStorageService {
  @override
  Future<void> saveGenerationStateJson(String value) async {}
  @override
  Future<String?> loadGenerationStateJson() async => null;
}

class _Blocks extends PromptBlockRepository {
  _Blocks(super.storage);
  Future<void> Function()? afterUsage;
  void Function()? beforeOrganizationWrite;
  void Function()? beforeCreateWrite;
  @override
  Future<PromptBlock> createBlock({
    required String title,
    required String content,
    String? folderId,
    String color = '#FF607D8B',
    String appearance = 'classic',
    String? readingTranslationZh,
    List<Map<String, dynamic>>? readingTranslationMarks,
    bool readingTranslationNeedsReview = false,
    String readingTranslationLanguageCode = 'zh',
    bool readingTranslationEdited = false,
    String? iconName,
    String? thumbnail,
    double thumbnailOffsetX = 0,
    double thumbnailOffsetY = 0,
    double thumbnailScale = 1,
    int? sortOrder,
    List<String>? atoms,
    String negativeContent = '',
    List<String>? negativeAtoms,
    PromptBlockGenerationSettings? generationSettings,
    List<PromptBlockTag> tags = const [],
    bool isFavorite = false,
    void Function()? beforeWrite,
  }) => super.createBlock(
    title: title,
    content: content,
    folderId: folderId,
    color: color,
    appearance: appearance,
    readingTranslationZh: readingTranslationZh,
    readingTranslationMarks: readingTranslationMarks,
    readingTranslationNeedsReview: readingTranslationNeedsReview,
    readingTranslationLanguageCode: readingTranslationLanguageCode,
    readingTranslationEdited: readingTranslationEdited,
    iconName: iconName,
    thumbnail: thumbnail,
    thumbnailOffsetX: thumbnailOffsetX,
    thumbnailOffsetY: thumbnailOffsetY,
    thumbnailScale: thumbnailScale,
    sortOrder: sortOrder,
    atoms: atoms,
    negativeContent: negativeContent,
    negativeAtoms: negativeAtoms,
    generationSettings: generationSettings,
    tags: tags,
    isFavorite: isFavorite,
    beforeWrite: () {
      beforeCreateWrite?.call();
      beforeWrite?.call();
    },
  );
  @override
  Future<PromptBlockFolder> createFolder({
    required String name,
    String? parentId,
    int? sortOrder,
    void Function()? beforeWrite,
  }) => super.createFolder(
    name: name,
    parentId: parentId,
    sortOrder: sortOrder,
    beforeWrite: () {
      beforeOrganizationWrite?.call();
      beforeWrite?.call();
    },
  );
  @override
  Future<PromptBlock?> incrementUseCount(String id) async {
    final actual = await super.incrementUseCount(id);
    await afterUsage?.call();
    return actual;
  }
}

final _draftProvider = Provider<BridgeDraftSnapshot Function()>(
  (ref) =>
      () => readBridgeDraft(ref),
);
Matcher toolError(String code) =>
    isA<NaiAgentToolError>().having((e) => e.code, 'code', code);

void main() {
  late Directory root, workspace;
  late PromptBlockStorage storage;
  late _Blocks repository;
  late ProviderContainer container;
  late _Preferences preferences;
  late bool projectionMismatch;
  setUp(() async {
    projectionMismatch = false;
    SharedPreferences.setMockInitialValues({});
    preferences = _Preferences();
    root = await Directory.systemTemp.createTemp('nai-agent-blocks-');
    workspace = await Directory('${root.path}/workspace').create();
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    storage = PromptBlockStorage(hivePath: root.path);
    await storage.init();
    repository = _Blocks(storage);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(repository),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(_Vibes()),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        blocksPreferencesProvider.overrideWith(() => preferences),
        pillWorkspaceProvider.overrideWith(
          () => projectionMismatch
              ? _ProjectionMismatch()
              : PillWorkspaceNotifier(),
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  Future<Map<String, dynamic>> run(
    String tool,
    Map<String, dynamic> params,
  ) async =>
      (await container
              .read(naiAgentStudioFactoryProvider)(workspace, root, true)
              .execute(tool, params, NaiAgentCancellation()))['details']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> block(String id) async =>
      (await run('block_query', {'id': id}))['block'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> create(Map<String, dynamic> changes) async =>
      await run('block_manage', {'action': 'create', 'changes': changes});
  BridgeDraftSnapshot draft() => container.read(_draftProvider)();
  Future<Map<String, dynamic>> insert(
    String id, {
    String scope = 'main',
    int? offset,
  }) async => run('block_manage', {
    'action': 'insert',
    'id': id,
    'expected_version': (await block(id))['version'],
    'expected_draft_version': draft().acknowledgementVersion,
    'scope': scope,
    if (offset != null) 'offset': offset,
  });
  Future<Map<String, dynamic>> instance(
    String action,
    Map<String, dynamic> params,
  ) => run('block_manage', {
    'action': action,
    'expected_draft_version': draft().acknowledgementVersion,
    ...params,
  });
  PillWorkspaceState lane([String scope = 'main']) =>
      container.read(pillWorkspaceProvider(scope));
  PillWorkspaceNotifier editor([String scope = 'main']) =>
      container.read(pillWorkspaceProvider(scope).notifier);
  int backupCount() =>
      workspace.listSync(recursive: true).whereType<File>().length;

  test(
    'inline temp roundtrip, display edit, no-original revert, roll and default promote',
    () async {
      editor().setText('start');
      final result = await instance('instance_create', {
        'kind': 'temporary',
        'instance': {
          'content': '猫😀',
          'title': '  one-off  ',
          'color': '#12ab34',
          'icon': 'star',
        },
      });
      final marker = result['marker'] as String;
      expect(lane().projection, 'start, 猫😀');
      final saved = lane().document;
      expect(saved.instances[marker]!.blockId, '');
      expect(saved.instances[marker]!.temp!.title, 'one-off');
      expect(saved.instances[marker]!.temp!.color, '#FF12AB34');
      expect(saved.instances[marker]!.temp!.iconName, 'star');
      expect(
        PillDocument.fromJson(
          jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
        ),
        saved,
      );
      editor().revertTemp(marker);
      expect(lane().document, saved);
      expect(editor().rollAllRandom(), isFalse);
      editor().rollMarker(marker);
      expect(lane().projection, 'start, 猫😀');
      final context = await run('studio_context', {'scope': 'draft'});
      final json = context['draft']['documents']['prompt']['instances'][marker];
      expect(json.containsKey('kind'), false);
      expect(json['temporary'], true);
      expect(json['temp']['iconName'], 'star');
      await instance('instance_update', {
        'marker': marker,
        'instance': {'title': 'renamed', 'color': '#80112233', 'icon': 'moon'},
      });
      expect(lane().document.instances[marker]!.temp!.title, 'renamed');
      final before = lane().document;
      final promoted = await instance('instance_promote', {
        'marker': marker,
        'expected_library_version': (await run('block_query', {
          'kind': 'tree',
        }))['library_version'],
      });
      expect(promoted['block']['title'], 'renamed');
      expect(promoted['block']['color'], '#80112233');
      expect(promoted['block']['iconName'], 'moon');
      expect(promoted['version'], promoted['block']['version']);
      expect(lane().document.instances[marker]!.temp, isNull);
      expect(lane().projection, 'start, 猫😀');
      editor().undo();
      expect(lane().document, before);
    },
  );

  test(
    'translation creation/update emits source and review semantics, unwrap uses selected occurrence',
    () async {
      editor().setText('tail');
      final result = await instance('instance_create', {
        'kind': 'translation',
        'anchor': {'text': 'tail', 'mode': 'before'},
        'translation': {'source': 'rain', 'zh': '雨天'},
      });
      final marker = result['marker'] as String;
      final original = lane().document.instances[marker]!.translation!;
      expect(original.toJson().containsKey('needsReview'), false);
      expect(original.toJson().containsKey('languageCode'), false);
      expect(
        lane().document.instances[marker]!.toJson().containsKey('kind'),
        false,
      );
      // Existing native tag marks remain supported, but are not Agent input.
      const marks = [
        TranslationTagMark(start: 0, end: 1, tag: 'rain', iconId: 'weather'),
      ];
      editor().updateTranslation(marker, original.copyWith(marks: marks));
      expect(lane().projection, 'raintail');
      expect(
        lane().document.instances[marker]!.translation!.translationEdited,
        isTrue,
      );
      await instance('instance_update', {
        'marker': marker,
        'translation': {'source': 'snow'},
      });
      expect(lane().projection, 'snowtail');
      expect(lane().document.instances[marker]!.translation!.marks, marks);
      expect(
        lane().document.instances[marker]!.translation!.toJson()['needsReview'],
        true,
      );
      expect(
        lane().document.instances[marker]!.translation!.needsReview,
        isTrue,
      );
      await instance('instance_update', {
        'marker': marker,
        'translation': {'zh': '雨天'},
      });
      expect(lane().document.instances[marker]!.translation!.marks, marks);
      expect(
        lane().document.instances[marker]!.translation!.needsReview,
        false,
      );
      await instance('instance_update', {
        'marker': marker,
        'translation': {'zh': '雪', 'language_code': 'ja'},
      });
      expect(
        lane().document.instances[marker]!.translation!
            .toJson()['languageCode'],
        'ja',
      );
      expect(lane().document.instances[marker]!.translation!.marks, isEmpty);
      expect(
        lane().document.instances[marker]!.translation!.needsReview,
        isFalse,
      );
      editor().setText('$marker/$marker');
      final before = lane().document;
      final projection = lane().projection;
      await instance('instance_unwrap', {'marker': marker, 'occurrence': 1});
      expect(lane().document.text, '$marker/snow');
      expect(lane().projection, projection);
      editor().undo();
      expect(lane().document, before);
      await expectLater(
        instance('instance_promote', {
          'marker': marker,
          'expected_library_version': (await run('block_query', {
            'kind': 'tree',
          }))['library_version'],
        }),
        throwsA(toolError('unsupported_kind')),
      );
    },
  );

  test(
    'batch convert resolves pre-operation anchors, writes once, preserves projection and undoes once',
    () async {
      const text = '中文😀, 1.2::x::, rain, 中文😀';
      editor().setText(text);
      final before = lane().document;
      final revision = container.read(pillWorkspaceRevisionProvider);
      final count = backupCount();
      final result = await instance('instance_convert', {
        'segments': [
          {
            'anchor': {'text': 'rain', 'mode': 'replace'},
            'kind': 'translation',
            'translation': {'zh': '雨'},
          },
          {
            'anchor': {'text': '中文😀', 'occurrence': 1, 'mode': 'replace'},
            'kind': 'temporary',
            'instance': {'title': 'last'},
          },
          {
            'anchor': {'text': '1.2::x::', 'mode': 'replace'},
            'kind': 'temporary',
            'instance': {'title': 'weight'},
          },
        ],
      });
      expect(result['markers'], hasLength(3));
      expect(result.containsKey('marker'), false);
      expect(container.read(pillWorkspaceRevisionProvider), revision + 1);
      expect(backupCount(), count + 1);
      expect(lane().projection, text);
      final markers = (result['markers'] as List).cast<String>();
      expect(
        lane().document.instances[markers[0]]!.translation!.source,
        'rain',
      );
      expect(lane().document.instances[markers[1]]!.temp!.content, '中文😀');
      editor().undo();
      expect(lane().document, before);
    },
  );

  test(
    'invalid batch is atomic before backup: overlap, missing, marker crossing, changed source',
    () async {
      editor().setText('left right rain');
      await instance('instance_create', {
        'kind': 'temporary',
        'offset': 4,
        'instance': {'content': 'middle', 'title': 'middle'},
      });
      final before = draft().acknowledgementVersion;
      final count = backupCount();
      final valid = {
        'anchor': {'text': 'rain', 'mode': 'replace'},
        'kind': 'temporary',
        'instance': {'title': 'rain'},
      };
      for (final item in [
        [
          valid,
          {
            ...valid,
            'anchor': {'text': 'missing', 'mode': 'replace'},
          },
        ],
        [valid, valid],
        [
          valid,
          {
            ...valid,
            'anchor': {'text': 'left right', 'mode': 'replace'},
          },
        ],
        [
          valid,
          {
            'anchor': {'text': 'right', 'mode': 'replace'},
            'kind': 'translation',
            'translation': {'source': 'wrong', 'zh': '右'},
          },
        ],
      ]) {
        await expectLater(
          instance('instance_convert', {'segments': item}),
          throwsA(
            isA<NaiAgentToolError>().having(
              (e) => e.message,
              'segment',
              contains('Segment 2'),
            ),
          ),
        );
        expect(draft().acknowledgementVersion, before);
        expect(backupCount(), count);
      }
      await expectLater(
        instance('instance_convert', valid),
        throwsA(toolError('invalid_arguments')),
      );
      await expectLater(
        instance('instance_convert', {'segments': List.filled(65, valid)}),
        throwsA(toolError('invalid_arguments')),
      );
    },
  );

  test(
    'create anchors handle ambiguity, modes, offsets and exact boundaries without backup',
    () async {
      editor().setText('a😀, a😀');
      final before = draft().acknowledgementVersion;
      final count = backupCount();
      for (final params in [
        {
          'anchor': {'text': 'a😀', 'mode': 'after'},
        },
        {
          'anchor': {'text': 'missing', 'mode': 'before'},
        },
        {
          'anchor': {'text': 'a😀', 'occurrence': 2, 'mode': 'after'},
        },
        {
          'anchor': {'text': 'a😀', 'mode': 'replace'},
        },
        {'offset': 2},
        {
          'offset': 0,
          'anchor': {'text': 'a😀', 'occurrence': 0, 'mode': 'before'},
        },
      ]) {
        await expectLater(
          instance('instance_create', {
            'kind': 'temporary',
            'instance': {'title': 'x', 'content': 'new'},
            ...params,
          }),
          throwsA(isA<NaiAgentToolError>()),
        );
        expect(draft().acknowledgementVersion, before);
        expect(backupCount(), count);
      }
      await instance('instance_create', {
        'kind': 'temporary',
        'instance': {'title': 'x', 'content': 'new'},
        'anchor': {'text': 'a😀', 'occurrence': 1, 'mode': 'after'},
      });
      expect(lane().projection, 'a😀, a😀new');
    },
  );

  test(
    'inline validation rejects display fields, bundle and invalid translation before backup',
    () async {
      for (final fields in [
        <String, dynamic>{},
        {'title': ' '},
        {'title': 'x' * 41},
        {'title': 'ok', 'color': 'blue'},
        {'title': 'ok', 'icon': 'unknown'},
        {'title': 'ok', 'negative_content': 'UC'},
      ]) {
        await expectLater(
          instance('instance_create', {
            'kind': 'temporary',
            'instance': {'content': 'words', ...fields},
          }),
          throwsA(isA<NaiAgentToolError>()),
        );
      }
      for (final translation in [
        {'source': 'rain', 'zh': '雨', 'language_code': 'xx'},
      ]) {
        await expectLater(
          instance('instance_create', {
            'kind': 'translation',
            'translation': translation,
          }),
          throwsA(toolError('invalid_translation')),
        );
      }
      await expectLater(
        instance('instance_create', {
          'kind': 'translation',
          'instance': {'title': 'ignored?'},
          'translation': {'source': 'rain', 'zh': '雨'},
        }),
        throwsA(toolError('invalid_arguments')),
      );
      expect(backupCount(), 0);
    },
  );

  test(
    'creation and conversion reject ineffective instance options before backup',
    () async {
      editor().setText('rain');
      final before = draft().acknowledgementVersion;
      final count = backupCount();
      for (final kind in ['temporary', 'translation']) {
        for (final option in [
          {'locked': true},
          {'evolutionEnabled': true},
          {
            'settings': {'mode': 'random'},
          },
        ]) {
          final fields = {
            'kind': kind,
            'instance': {
              if (kind == 'temporary') ...{'title': 'rain', 'content': 'rain'},
              ...option,
            },
            if (kind == 'translation')
              'translation': {'source': 'rain', 'zh': '雨'},
          };
          await expectLater(
            instance('instance_create', fields),
            throwsA(toolError('invalid_instance')),
          );
          await expectLater(
            instance('instance_convert', {
              'segments': [
                {
                  ...fields,
                  'anchor': {'text': 'rain', 'mode': 'replace'},
                },
              ],
            }),
            throwsA(toolError('invalid_instance')),
          );
          expect(draft().acknowledgementVersion, before);
          expect(backupCount(), count);
        }
      }
    },
  );

  test(
    'all inline actions reject stale draft before backup and promote rejects stale library',
    () async {
      final result = await instance('instance_create', {
        'kind': 'temporary',
        'instance': {'title': 'x', 'content': 'words'},
      });
      final marker = result['marker'];
      final count = backupCount();
      for (final params in [
        {
          'action': 'instance_create',
          'kind': 'translation',
          'translation': {'source': 'rain', 'zh': '雨'},
        },
        {
          'action': 'instance_convert',
          'segments': [
            {
              'kind': 'temporary',
              'anchor': {'text': 'missing', 'mode': 'replace'},
              'instance': {'title': 'x'},
            },
          ],
        },
        {
          'action': 'instance_update',
          'marker': marker,
          'instance': {'title': 'x'},
        },
        {'action': 'instance_delete', 'marker': marker},
        {'action': 'instance_unwrap', 'marker': marker},
        {
          'action': 'instance_promote',
          'marker': marker,
          'expected_library_version': (await run('block_query', {
            'kind': 'tree',
          }))['library_version'],
        },
      ]) {
        await expectLater(
          instance(params['action'] as String, {
            ...params,
            'expected_draft_version': 'stale',
          }),
          throwsA(isA<NaiAgentToolError>()),
        );
        expect(backupCount(), count);
      }
      await expectLater(
        instance('instance_promote', {
          'marker': marker,
          'expected_library_version': 'stale',
        }),
        throwsA(toolError('library_conflict')),
      );
      expect((await repository.load()).blocks, isEmpty);
    },
  );

  test(
    'delete one occurrence versus all; library bundle peers follow native semantics',
    () async {
      final result = await instance('instance_create', {
        'kind': 'temporary',
        'instance': {'title': 'one', 'content': 'words'},
      });
      final marker = result['marker'] as String;
      editor().setText('$marker/$marker');
      final before = lane().document;
      await instance('instance_delete', {'marker': marker, 'occurrence': 1});
      expect(lane().document.text, '$marker/');
      editor().undo();
      expect(lane().document, before);
      await instance('instance_delete', {'marker': marker});
      expect(lane().document.text, '/');
      expect(lane().document.instances, isEmpty);
      final created = await create({
        'title': 'pair',
        'content': 'positive',
        'negativeContent': 'negative',
      });
      await insert(created['block']['id'] as String);
      const m = '\uE000';
      final original = lane().document;
      final negOriginal = lane('negative').document;
      await instance('instance_unwrap', {'marker': m});
      expect(lane().projection, '/, positive');
      expect(lane('negative').projection, 'negative');
      expect(lane('negative').document.instances, isEmpty);
      editor().undo();
      editor('negative').undo();
      expect(lane().document, original);
      expect(lane('negative').document, negOriginal);
      await instance('instance_delete', {'marker': m});
      expect(lane('negative').projection, '');
      expect(lane().document.instances, isEmpty);
    },
  );

  test(
    'character positive and negative scopes support all inline operations',
    () async {
      final id = container
          .read(characterPromptNotifierProvider)
          .characters
          .single
          .id;
      for (final scope in ['char:$id:pos', 'char:$id:neg']) {
        editor(scope).setText('rain sky');
        final result = await instance('instance_convert', {
          'scope': scope,
          'segments': [
            {
              'kind': 'translation',
              'anchor': {'text': 'rain', 'mode': 'replace'},
              'translation': {'zh': '雨'},
            },
          ],
        });
        expect(result.containsKey('marker'), false);
        final marker = (result['markers'] as List).single as String;
        expect(lane(scope).projection, 'rain sky');
        await instance('instance_update', {
          'scope': scope,
          'marker': marker,
          'translation': {'source': 'snow'},
        });
        expect(lane(scope).projection, 'snow sky');
        await instance('instance_unwrap', {'scope': scope, 'marker': marker});
        final temp = await instance('instance_create', {
          'scope': scope,
          'kind': 'temporary',
          'instance': {'title': 'inline', 'content': 'sun'},
        });
        await instance('instance_promote', {
          'scope': scope,
          'marker': temp['marker'],
          'expected_library_version': (await run('block_query', {
            'kind': 'tree',
          }))['library_version'],
        });
        await instance('instance_delete', {
          'scope': scope,
          'marker': temp['marker'],
        });
        expect(lane(scope).projection, 'snow sky, ');
      }
    },
  );

  test(
    'prompt_update protects instances but permits exact projection no-op and other fields',
    () async {
      await instance('instance_create', {
        'kind': 'temporary',
        'instance': {'title': 'one', 'content': 'words'},
      });
      final before = lane().document;
      final version = draft();
      await expectLater(
        run('prompt_update', {
          'changes': {'prompt': 'different'},
          'expected': version.fieldVersions,
        }),
        throwsA(toolError('pill_conflict')),
      );
      await run('prompt_update', {
        'changes': {'prompt': 'words', 'steps': 20},
        'expected': version.fieldVersions,
      });
      expect(lane().document, before);
    },
  );

  test(
    'unopened lane conversion is one write and one undo back to actual draft',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateModel(ImageModels.animeDiffusionV5Full);
      // Direct initialization deliberately avoids the prompt setter opening a lane.
      container
          .read(generationParamsNotifierProvider.notifier)
          .restoreAgentSnapshot(
            container
                .read(generationParamsNotifierProvider)
                .copyWith(prompt: 'rain sky'),
          );
      expect(container.exists(pillWorkspaceProvider('main')), false);
      final before = draft().documents['prompt'];
      final revision = container.read(pillWorkspaceRevisionProvider);
      await instance('instance_convert', {
        'segments': [
          {
            'kind': 'temporary',
            'anchor': {'text': 'rain', 'mode': 'replace'},
            'instance': {'title': 'rain'},
          },
        ],
      });
      expect(container.read(pillWorkspaceRevisionProvider), revision + 1);
      expect(lane().projection, 'rain sky');
      editor().undo();
      expect(lane().document.toJson(), before);
    },
  );

  test(
    'library-free temp persists across storage/provider restoration and snapshots',
    () async {
      await Hive.openBox<String>(PillWorkspaceStorage.boxName);
      await instance('instance_create', {
        'kind': 'temporary',
        'instance': {
          'title': 'snapshot temp',
          'content': 'kept',
          'color': '#123456',
          'icon': 'star',
        },
      });
      final expected = lane().document;
      final saved = await run('snapshot', {
        'action': 'save',
        'name': 'inline temp',
      });
      await container
          .read(pillWorkspaceStorageProvider)
          .persist('main', expected);
      container.invalidate(pillWorkspaceProvider('main'));
      expect(lane().document, expected);
      editor().replaceWithPlainText('replacement');
      final loaded = await run('snapshot', {
        'action': 'load',
        'id': saved['saved']['id'],
        'expected_version': draft().acknowledgementVersion,
      });
      expect(loaded, isNotNull);
      expect(lane().document, expected);
      expect(lane().projection, 'kept');
    },
  );

  test(
    'projection mismatch rolls back conversion with no conversion undo entry',
    () async {
      projectionMismatch = true;
      editor().setText('rain sky');
      final before = lane().document;
      await expectLater(
        instance('instance_convert', {
          'segments': [
            {
              'kind': 'temporary',
              'anchor': {'text': 'rain', 'mode': 'replace'},
              'instance': {'title': 'x'},
            },
          ],
        }),
        throwsA(toolError('projection_changed')),
      );
      expect(lane().document, before);
      expect(lane().projection, 'rain sky');
      editor().undo();
      expect(lane().document, PillDocument.empty());
    },
  );

  test(
    'promote final Hive admission rejects draft edit, busy and closed without library write',
    () async {
      var busy = false, alive = true;
      final toolsProvider = Provider(
        (ref) => bindNaiAgentBlocks(ref, workspace, () => busy, () => alive),
      );
      final tools = container.read(toolsProvider);
      final created = await instance('instance_create', {
        'kind': 'temporary',
        'instance': {'title': 'x', 'content': 'words'},
      });
      for (final code in ['draft_conflict', 'busy', 'closed']) {
        busy = false;
        alive = true;
        repository.beforeCreateWrite = () {
          if (code == 'draft_conflict') {
            editor().setText('${lane().document.text}newer');
          }
          if (code == 'busy') busy = true;
          if (code == 'closed') alive = false;
        };
        await expectLater(
          tools.manage({
            'action': 'instance_promote',
            'marker': created['marker'],
            'expected_draft_version': draft().acknowledgementVersion,
            'expected_library_version': (await run('block_query', {
              'kind': 'tree',
            }))['library_version'],
          }, NaiAgentCancellation()),
          throwsA(toolError(code)),
        );
        expect((await repository.load()).blocks, isEmpty);
        expect(lane().document.instances[created['marker']]!.temporary, true);
      }
    },
  );

  test(
    'new instance actions refuse active generation and closed binding before backup',
    () async {
      var busy = true, alive = true;
      final toolsProvider = Provider(
        (ref) => bindNaiAgentBlocks(ref, workspace, () => busy, () => alive),
      );
      final tools = container.read(toolsProvider);
      for (final code in ['busy', 'closed']) {
        if (code == 'closed') {
          busy = false;
          alive = false;
        }
        for (final action in [
          'instance_create',
          'instance_convert',
          'instance_unwrap',
          'instance_delete',
          'instance_update',
          'instance_promote',
        ]) {
          await expectLater(
            tools.manage({
              'action': action,
              'expected_draft_version': draft().acknowledgementVersion,
            }, NaiAgentCancellation()),
            throwsA(toolError(code)),
          );
        }
      }
      expect(backupCount(), 0);
    },
  );

  test(
    'library-backed temps reject display edits and bundle occurrence deletion preserves other peer',
    () async {
      final created = await create({
        'title': 'paired',
        'content': 'P',
        'negativeContent': 'N',
      });
      await insert(created['block']['id'] as String);
      const marker = '\uE000';
      editor().setText('$marker/$marker');
      editor('negative').setText('$marker/$marker');
      await instance('instance_update', {
        'marker': marker,
        'instance': {'content': 'temporary'},
      });
      final actual = lane().document.text[0];
      await expectLater(
        instance('instance_update', {
          'marker': actual,
          'instance': {'title': 'no'},
        }),
        throwsA(toolError('unsupported_kind')),
      );
      await instance('instance_delete', {'marker': actual, 'occurrence': 0});
      expect(lane().projection, '/P');
      expect(lane('negative').projection, '/N');
    },
  );

  test(
    'instance conversion near markers and disabled options keep exact projection contracts',
    () async {
      final result = await instance('instance_create', {
        'kind': 'temporary',
        'instance': {'title': 'center', 'content': 'middle'},
      });
      final marker = result['marker'] as String;
      editor().setText('left${marker}right');
      await instance('instance_convert', {
        'segments': [
          {
            'kind': 'temporary',
            'anchor': {'text': 'left', 'mode': 'replace'},
            'instance': {'title': 'L'},
          },
          {
            'kind': 'translation',
            'anchor': {'text': 'right', 'mode': 'replace'},
            'translation': {'zh': '右'},
          },
        ],
      });
      expect(lane().projection, 'leftmiddleright');
      expect(lane().document.instances[marker]!.temp!.content, 'middle');
      editor().undo();
      final before = draft().acknowledgementVersion;
      final count = backupCount();
      await expectLater(
        instance('instance_convert', {
          'segments': [
            {
              'kind': 'temporary',
              'anchor': {'text': 'left', 'mode': 'replace'},
              'instance': {'title': 'L', 'enabled': false},
            },
          ],
        }),
        throwsA(toolError('projection_changed')),
      );
      expect(draft().acknowledgementVersion, before);
      expect(backupCount(), count);
      final disabled = await instance('instance_create', {
        'kind': 'translation',
        'offset': 0,
        'instance': {'enabled': false},
        'translation': {'source': 'hidden', 'zh': '隐藏'},
      });
      expect(lane().projection, 'leftmiddleright');
      final inserted = lane().document.instances[disabled['marker']]!;
      expect(inserted.locked, false);
      expect(inserted.evolutionEnabled, false);
      expect(inserted.settings, PillInstanceSettings.fixedDefault);
      expect(
        (await run(
              'studio_context',
              {'scope': 'draft'},
            ))['draft']['documents']['prompt']['instances'][disabled['marker']]['translation']
            .containsKey('languageCode'),
        false,
      );
    },
  );

  test('promote explicit display overrides temp defaults', () async {
    final result = await instance('instance_create', {
      'kind': 'temporary',
      'instance': {
        'title': 'temp',
        'content': 'words',
        'color': '#112233',
        'icon': 'star',
      },
    });
    final promoted = await instance('instance_promote', {
      'marker': result['marker'],
      'expected_library_version': (await run('block_query', {
        'kind': 'tree',
      }))['library_version'],
      'changes': {'title': 'saved', 'color': '#FF998877', 'iconName': 'moon'},
    });
    expect(promoted['block']['title'], 'saved');
    expect(promoted['block']['color'], '#FF998877');
    expect(promoted['block']['iconName'], 'moon');
  });

  test(
    'quality and UC capture save reload apply round trip, native and custom',
    () async {
      final preset = await repository.createBlock(
        title: 'custom preset',
        content: 'custom words',
      );
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      for (final custom in [false, true]) {
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateModel(ImageModels.animeDiffusionV5Full);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateQualityPreset(QualityTagPreset.light);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateUcPreset(UcPresets.toApiValue(UcPresetType.humanFocus));
        if (custom) {
          container
              .read(qualityPresetNotifierProvider.notifier)
              .setCustomEntry(preset.id);
          container
              .read(ucPresetNotifierProvider.notifier)
              .setCustomEntry(preset.id);
        }
        final captured = storedBlockParams(captureBlockParams(container.read))!;
        final created = await create({
          'title': 'saved',
          'content': 'prompt',
          'generationSettings': captured.toJson(),
        });
        final saved = await repository.getBlock(
          (created['block'] as Map)['id'] as String,
        );
        final reloaded = PromptBlock.fromJson(
          saved!.toJson(),
        ).generationSettings!;
        expect(reloaded, captured);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateQualityPreset(QualityTagPreset.none);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateUcPreset(3);
        applyPromptBlockGenerationSettingsWithReader(container.read, reloaded);
        expect(storedBlockParams(captureBlockParams(container.read)), captured);
      }
      expect(
        PromptBlockGenerationSettings.fromJson({'steps': 28}).qualityPreset,
        isNull,
      );
    },
  );

  test(
    'Agent temporary edits isolate one shared occurrence, persist, revert and save as new',
    () async {
      final created = await create({
        'title': 'original',
        'content': 'old',
        'negativeContent': 'old UC',
        'color': '#FF123456',
        'appearance': 'dots',
        'iconName': 'star',
        'tags': [
          {'name': 'tag'},
        ],
        'generationSettings': {'qualityPreset': 'light', 'ucPreset': 1},
      });
      final id = (created['block'] as Map)['id'] as String;
      await insert(id);
      const m = '\uE000';
      final pos = container.read(pillWorkspaceProvider('main').notifier);
      final neg = container.read(pillWorkspaceProvider('negative').notifier);
      pos.setText('$m / $m');
      neg.setText('$m / $m');
      final result = await run('block_manage', {
        'action': 'instance_update',
        'scope': 'main',
        'marker': m,
        'occurrence': 1,
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'content': 'new', 'negative_content': 'new UC'},
      });
      final document = container.read(pillWorkspaceProvider('main')).document;
      final tempMarker = document.instances.keys.singleWhere((key) => key != m);
      expect(document.text, '$m / $tempMarker');
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'old / new',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'old UC / new UC',
      );
      expect((await repository.getBlock(id))!.content, 'old');
      expect(document.instances[m]!.temp, isNull);
      expect(document.instances[tempMarker]!.temp!.editedBy, 'agent');
      expect(
        ((result['lanes'] as Map)['main'] as Map)['document'],
        document.toJson(),
      );
      final roundTrip = PillDocument.fromJson(
        jsonDecode(jsonEncode(document.toJson())) as Map<String, dynamic>,
      );
      expect(roundTrip, document);
      pos.restoreDocument(roundTrip);
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'old / new',
      );
      final queried = await run('block_query', {'id': id});
      expect(
        (queried['instances'] as List).where(
          (e) => (e as Map)['temporary'] == true,
        ),
        hasLength(2),
      );
      pos.revertTemp(tempMarker);
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'old / old',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'old UC / old UC',
      );
      pos.editTempContent(tempMarker, 'saved text', 'saved UC');
      final saved = await pos.saveTempAsNewBlock(
        tempMarker,
        title: 'new library block',
      );
      expect(saved!.id, isNot(id));
      expect(saved.content, 'saved text');
      expect(saved.negativeContent, 'saved UC');
      final original = (await repository.getBlock(id))!;
      expect(original.content, 'old');
      expect(saved.color, original.color);
      expect(saved.appearance, original.appearance);
      expect(saved.iconName, original.iconName);
      expect(saved.tags, original.tags);
      expect(saved.generationSettings, original.generationSettings);
      final actual = container.read(pillWorkspaceProvider('main'));
      expect(actual.document.instances[tempMarker]!.blockId, saved.id);
      expect(actual.document.instances[tempMarker]!.temporary, isFalse);
      expect(actual.projection, 'old / saved text');
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'old UC / saved UC',
      );
    },
  );

  test(
    'temporary draft survives provider restart and library edits, including a reading block',
    () async {
      await Hive.openBox<String>(PillWorkspaceStorage.boxName);
      final created = await create({
        'title': 'reading',
        'content': 'source',
        'negativeContent': 'UC',
        'readingTranslationZh': '译文',
      });
      final id = (created['block'] as Map)['id'] as String;
      await insert(id);
      final lane = container.read(pillWorkspaceProvider('main').notifier);
      lane.editTempContent(
        '\uE000',
        'local source',
        'local UC',
        editedBy: 'agent',
      );
      final expected = container.read(pillWorkspaceProvider('main')).document;
      await container
          .read(pillWorkspaceStorageProvider)
          .persist('main', expected);
      container.invalidate(pillWorkspaceProvider('main'));
      expect(container.read(pillWorkspaceProvider('main')).document, expected);
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'local source',
      );
      final original = (await repository.getBlock(id))!;
      await repository.updateBlock(
        original.copyWith(content: 'library changed'),
      );
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'local source',
      );
      final saved = await container
          .read(pillWorkspaceProvider('main').notifier)
          .saveTempAsNewBlock('\uE000', title: 'new fixed');
      final actual = container.read(pillWorkspaceProvider('main'));
      expect(actual.document.instances.values.single.translation, isNull);
      expect(actual.projection, 'local source');
      expect(actual.document.instances.values.single.blockId, saved!.id);
      expect((await repository.getBlock(id))!.content, 'library changed');
    },
  );

  test(
    'negative-only Agent temp edit preserves the positive temporary content',
    () async {
      final created = await create({
        'title': 'two sides',
        'content': 'positive',
        'negativeContent': 'negative',
      });
      await insert((created['block'] as Map)['id'] as String);
      await run('block_manage', {
        'action': 'instance_update',
        'scope': 'negative',
        'marker': '\uE000',
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'negative_content': 'new negative'},
      });
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'positive',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'new negative',
      );
    },
  );

  test(
    'temporary random instance is fixed and independent of another instance of the same block',
    () async {
      final created = await create({'title': 'pool', 'content': 'one, two'});
      final id = (created['block'] as Map)['id'] as String;
      await insert(id, offset: 0);
      await insert(id, offset: 1);
      final lane = container.read(pillWorkspaceProvider('main').notifier);
      lane.updateInstanceSettings(
        '\uE000',
        const PillInstanceSettings(mode: PillRollMode.random),
      );
      final old = container
          .read(pillWorkspaceProvider('main'))
          .document
          .instances['\uE000']!;
      lane.editTempContent('\uE000', 'fixed', null);
      lane.rollMarker('\uE000');
      lane.rollAllRandom();
      final actual = container.read(pillWorkspaceProvider('main'));
      expect(actual.projection, 'fixedone, two');
      expect(actual.document.instances['\uE000']!.currentRoll, old.currentRoll);
      expect(actual.document.instances['\uE001']!.temporary, isFalse);
      lane.revertTemp('\uE000');
      expect(
        container
            .read(pillWorkspaceProvider('main'))
            .document
            .instances['\uE000']!
            .settings
            .mode,
        PillRollMode.random,
      );
    },
  );

  test(
    'partial temporary content edits freeze the other side current roll, not the whole library pool',
    () async {
      final created = await create({
        'title': 'rolled pair',
        'content': 'a, b',
        'negativeContent': 'c, d',
      });
      await insert((created['block'] as Map)['id'] as String);
      final pos = container.read(pillWorkspaceProvider('main').notifier);
      final neg = container.read(pillWorkspaceProvider('negative').notifier);
      pos.updateInstanceSettings(
        '\uE000',
        const PillInstanceSettings(mode: PillRollMode.sequential),
      );
      neg.updateInstanceSettings(
        '\uE000',
        const PillInstanceSettings(mode: PillRollMode.sequential),
      );
      final positive = container.read(pillWorkspaceProvider('main')).projection;
      await run('block_manage', {
        'action': 'instance_update',
        'scope': 'negative',
        'marker': '\uE000',
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'negative_content': 'edited UC'},
      });
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        positive,
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'edited UC',
      );
      pos.revertTemp('\uE000');
      await Future<void>.delayed(Duration.zero);
      final negative = container
          .read(pillWorkspaceProvider('negative'))
          .projection;
      await run('block_manage', {
        'action': 'instance_update',
        'scope': 'main',
        'marker': '\uE000',
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'content': 'edited positive'},
      });
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'edited positive',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        negative,
      );
    },
  );

  Future<Map<String, dynamic>> organize(
    String action, [
    Map<String, dynamic> fields = const {},
  ]) async => run('block_manage', {
    'action': action,
    'expected_library_version': (await run('block_query', {
      'kind': 'tree',
    }))['library_version'],
    ...fields,
  });

  test(
    'folder CRUD, movement, complete reordering and deletion preserve native blocks and draft',
    () async {
      final before = draft();
      final parent = await organize('folder_create', {
        'changes': {'name': 'Parent'},
      });
      final child = await organize('folder_create', {
        'changes': {'name': 'Child', 'parentId': parent['id']},
      });
      await organize('folder_update', {
        'id': child['id'],
        'changes': {'name': 'Renamed'},
      });
      await organize('folder_move', {'id': child['id'], 'parent_id': null});
      await organize('folder_reorder', {
        'parent_id': null,
        'ordered_ids': [child['id'], parent['id']],
      });
      expect((await repository.getFolder(child['id'] as String))!.sortOrder, 0);
      final entry = await create({
        'title': 'Retained',
        'content': 'blue_eyes',
        'folderId': parent['id'],
      });
      await expectLater(
        organize('folder_delete', {'id': parent['id']}),
        throwsA(toolError('invalid_organization')),
      );
      await organize('folder_delete', {'id': child['id']});
      expect(await repository.getFolder(child['id'] as String), isNull);
      expect((await repository.load()).blocks.single.id, entry['block']['id']);
      expect(draft().acknowledgementVersion, before.acknowledgementVersion);
      expect(await File(parent['backup_path'] as String).exists(), isTrue);
    },
  );
  test(
    'collection hierarchy and explicit membership use native favorites without deleting blocks',
    () async {
      final entry = await create({'title': 'Member', 'content': 'blue_eyes'});
      final blockId = entry['block']['id'];
      final folder = await organize('collection_create', {
        'changes': {'name': 'Folder', 'isFolder': true},
      });
      final collection = await organize('collection_create', {
        'changes': {'name': 'Set', 'parentId': folder['id']},
      });
      await organize('collection_update', {
        'id': collection['id'],
        'changes': {'name': 'New set'},
      });
      await organize('collection_add', {
        'id': collection['id'],
        'block_id': blockId,
      });
      await organize('collection_add', {
        'id': collection['id'],
        'block_id': blockId,
      });
      expect(
        (await repository.load())
            .getCollection(collection['id'] as String)!
            .blockIds,
        [blockId],
      );
      expect(
        (await repository.getBlock(blockId as String))!.isFavorite,
        isTrue,
      );
      await organize('collection_remove', {
        'id': collection['id'],
        'block_id': blockId,
      });
      expect((await repository.getBlock(blockId))!.isFavorite, isTrue);
      await organize('collection_add', {
        'id': collection['id'],
        'block_id': blockId,
      });
      await organize('collection_delete', {'id': folder['id']});
      expect((await repository.load()).collections, isEmpty);
      expect(await repository.getBlock(blockId), isNotNull);
    },
  );
  test(
    'organization rejects stale library versions, cycles and incomplete reorder before overwriting',
    () async {
      final parent = await organize('folder_create', {
        'changes': {'name': 'Parent'},
      });
      final version = (await run('block_query', {
        'kind': 'tree',
      }))['library_version'];
      final child = await organize('folder_create', {
        'changes': {'name': 'Child', 'parentId': parent['id']},
      });
      await expectLater(
        run('block_manage', {
          'action': 'folder_update',
          'id': parent['id'],
          'changes': {'name': 'Stale'},
          'expected_library_version': version,
        }),
        throwsA(toolError('library_conflict')),
      );
      await expectLater(
        organize('folder_move', {'id': parent['id'], 'parent_id': child['id']}),
        throwsA(toolError('invalid_organization')),
      );
      await expectLater(
        organize('folder_reorder', {'parent_id': null, 'ordered_ids': []}),
        throwsA(toolError('invalid_organization')),
      );
      expect(
        (await repository.getFolder(parent['id'] as String))!.name,
        'Parent',
      );
    },
  );

  test(
    'late native organization edits and cancellation are checked at Hive admission',
    () async {
      final parent = await organize('folder_create', {
        'changes': {'name': 'Parent'},
      });
      final folder = (await repository.getFolder(parent['id'] as String))!;
      final version = (await run('block_query', {
        'kind': 'tree',
      }))['library_version'];
      repository.beforeOrganizationWrite = () {
        Hive.box<String>(StorageKeys.promptBlockLibraryBox).put(
          PromptBlockStorage.folderKey(folder.id),
          jsonEncode(folder.copyWith(name: 'User edit').toJson()),
        );
      };
      await expectLater(
        run('block_manage', {
          'action': 'folder_create',
          'changes': {'name': 'Rejected'},
          'expected_library_version': version,
        }),
        throwsA(toolError('library_conflict')),
      );
      expect((await repository.load()).folders.single.name, 'User edit');
      final token = NaiAgentCancellation();
      repository.beforeOrganizationWrite = token.cancel;
      final current = (await run('block_query', {
        'kind': 'tree',
      }))['library_version'];
      await expectLater(
        container
            .read(naiAgentStudioFactoryProvider)(workspace, root, true)
            .execute('block_manage', {
              'action': 'folder_create',
              'changes': {'name': 'Cancelled'},
              'expected_library_version': current,
            }, token),
        throwsA(toolError('cancelled')),
      );
      expect((await repository.load()).folders, hasLength(1));
    },
  );

  test(
    'real CRUD returns persisted fields and backs up the complete previous library/draft',
    () async {
      final folder = await repository.createFolder(name: '风格');
      final before = draft();
      final created = await create({
        'title': '冷色积木',
        'content': 'blue theme',
        'folderId': folder.id,
        'isFavorite': true,
        'atoms': ['blue', 'cyan'],
        'negativeContent': 'red theme',
        'generationSettings': {'width': 832, 'height': 1216},
      });
      final id = created['id'] as String;
      expect((await repository.getBlock(id))!.isFavorite, true);
      expect(draft().acknowledgementVersion, before.acknowledgementVersion);
      final row = await block(id);
      final updated = await run('block_manage', {
        'action': 'update',
        'id': id,
        'expected_version': row['version'],
        'changes': {'content': 'green theme', 'folderId': null},
      });
      expect(updated['block']['atoms'], null);
      expect(updated['block']['folderId'], null);
      final backup =
          jsonDecode(
                await File(updated['backup_path'] as String).readAsString(),
              )
              as Map;
      expect(backup['generation']['blocks'].single['content'], 'blue theme');
      expect(backup['generation']['draft']['fields'], before.fields);
      final deleted = await run('block_manage', {
        'action': 'delete',
        'id': id,
        'expected_version': updated['block']['version'],
      });
      expect(deleted['block'], null);
      expect(await repository.getBlock(id), null);
    },
  );

  test(
    'query pages, favorites, folders, collections and hidden dependencies use real library rows',
    () async {
      final folder = await repository.createFolder(name: 'Characters');
      final a = await repository.createBlock(
        title: 'Blue',
        content: 'blue eyes',
        folderId: folder.id,
        isFavorite: true,
      );
      await repository.createBlock(title: 'Green', content: 'green hair');
      final hidden = PromptBlock.create(
        title: 'Archived',
        content: 'blue archive',
        isArchived: true,
      );
      await repository.importBlocks([hidden]);
      final collection = await repository.createCollection(name: 'Favorites');
      await storage.putCollection(collection.copyWith(blockIds: [a.id]));
      final page = await run('block_query', {'limit': 1});
      expect(page['total'], 2);
      expect(page['next_offset'], 1);
      expect(
        (await run('block_query', {
          'folder_id': folder.id,
          'favorites': true,
        }))['blocks'].single['id'],
        a.id,
      );
      expect(
        (await run('block_query', {
          'collection_id': collection.id,
        }))['blocks'].single['id'],
        a.id,
      );
      expect(
        (await run('block_query', {
          'query': 'blue',
          'include_archived': true,
        }))['total'],
        2,
      );
      final tree = await run('block_query', {'kind': 'tree'});
      expect(tree['folders'].single['id'], folder.id);
      expect(tree['collections'].single['id'], collection.id);
      expect((await run('block_query', {'id': 'missing'}))['block'], null);
    },
  );

  test(
    'unopened prompt editors preserve saved text and pair both sides of a block',
    () async {
      final p = container.read(generationParamsNotifierProvider.notifier);
      p.restoreAgentSnapshot(
        container
            .read(generationParamsNotifierProvider)
            .copyWith(prompt: '1girl', negativePrompt: 'bad quality'),
      );
      expect(container.exists(pillWorkspaceProvider(PillScopes.main)), false);
      final created = await create({
        'title': '双面',
        'content': 'blue eyes',
        'negativeContent': 'red eyes',
      });
      final result = await insert(created['id'] as String);
      final params = container.read(generationParamsNotifierProvider);
      expect(params.prompt, '1girl, blue eyes');
      expect(params.negativePrompt, 'bad quality, red eyes');
      final lanes = result['lanes'] as Map;
      final pos = lanes['main']['document']['instances'] as Map;
      final neg = lanes['negative']['document']['instances'] as Map;
      expect(pos.values.single['bundleId'], neg.values.single['bundleId']);
      expect(neg.values.single['useNegativeContent'], true);
      expect(result['draft_version'], draft().acknowledgementVersion);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((await repository.getBlock(created['id'] as String))!.useCount, 1);
    },
  );

  test(
    'Agent insert records LRU once per bundle and ignores preference failures',
    () async {
      final first = await create({
        'title': 'first',
        'content': 'one',
        'negativeContent': 'bad one',
      });
      final second = await create({'title': 'second', 'content': 'two'});
      final a = first['id'] as String, b = second['id'] as String;
      await container.read(blocksPreferencesProvider.future);
      await insert(a);
      await insert(b);
      await insert(a);
      // Drain the preference queue without recording an extra use.
      await preferences.change((p) => p);
      expect(preferences.calls, 3);
      expect(container.read(blocksPreferencesProvider).requireValue.recentIds, [
        a,
        b,
      ]);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          'blocks_recent_ids',
        ),
        [a, b],
      );

      final before = preferences.calls;
      await expectLater(
        run('block_manage', {
          'action': 'insert',
          'id': b,
          'expected_version': (await block(b))['version'],
          'expected_draft_version': 'stale',
        }),
        throwsA(toolError('draft_conflict')),
      );
      expect(preferences.calls, before);

      preferences.fail = true;
      final result = await insert(b);
      await Future<void>.delayed(Duration.zero);
      expect(result['action'], 'insert');
      expect(result['lanes']['main']['inserted_markers'], hasLength(1));
      expect(result['draft_version'], draft().acknowledgementVersion);
      expect(preferences.calls, before + 1);
    },
  );

  test(
    'negative-only blocks do not change the main prompt or open its empty editor',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .restoreAgentSnapshot(
            container
                .read(generationParamsNotifierProvider)
                .copyWith(prompt: 'kept main'),
          );
      final created = await create({
        'title': '负面',
        'content': '',
        'negativeContent': 'bad anatomy',
      });
      final result = await insert(created['id'] as String);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'kept main',
      );
      expect(container.exists(pillWorkspaceProvider(PillScopes.main)), false);
      expect(result['lanes'].keys.toList(), ['negative']);
      expect(
        container.read(generationParamsNotifierProvider).negativePrompt,
        'bad anatomy',
      );
    },
  );

  for (final (input, prefix) in const [
    ('dress', 'dress, '),
    ('eyes', 'eyes, '),
    ('cat', 'cat, '),
    (r'cat$', r'cat$, '),
    ('cat ', 'cat , '),
    ('cat,', 'cat,'),
    ('cat,  ', 'cat,  '),
    ('', ''),
    (' \t ', ' \t '),
  ]) {
    test(
      'append keeps tag boundaries in both lanes: ${jsonEncode(input)}',
      () async {
        final created = await create({
          'title': 'Fixture',
          'content': 'blue_eyes',
          'negativeContent': 'bad_hands',
        });
        for (final scope in [PillScopes.main, PillScopes.negative]) {
          container
              .read(pillWorkspaceProvider(scope).notifier)
              .replaceWithPlainText(input);
        }
        container
            .read(generationParamsNotifierProvider.notifier)
            .updatePromptImmediately(input);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateNegativePromptImmediately(input);
        await insert(created['id'] as String);
        expect(
          container.read(pillWorkspaceProvider(PillScopes.main)).projection,
          '${prefix}blue_eyes',
        );
        expect(
          container.read(pillWorkspaceProvider(PillScopes.negative)).projection,
          '${prefix}bad_hands',
        );
      },
    );
  }

  test(
    'character insertion preserves identity/metadata and supports explicit raw offsets',
    () async {
      final created = await create({
        'title': '角色',
        'content': 'blue eyes',
        'negativeContent': 'red eyes',
      });
      final scope = PillScopes.charPos('kept');
      await insert(created['id'] as String, scope: scope, offset: 0);
      final config = container.read(characterPromptNotifierProvider);
      expect(config.characters.single.prompt, 'blue eyesraw character');
      expect(config.characters.single.negativePrompt, 'raw uc, red eyes');
      expect(config.characters.single.name, 'My character');
      expect(config.characters.single.thumbnailPath, 'local-thumbnail');
    },
  );

  test(
    'instance settings, locking and enabled state change the actual editor, not the library',
    () async {
      final created = await create({
        'title': '随机',
        'content': 'blue, green',
        'atoms': ['blue', 'green'],
      });
      final id = created['id'] as String;
      final inserted = await insert(id);
      final marker =
          inserted['lanes']['main']['inserted_markers'].single as String;
      final result = await run('block_manage', {
        'action': 'instance_update',
        'scope': 'main',
        'marker': marker,
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {
          'settings': {'mode': 'random', 'countMin': 1, 'countMax': 1},
          'locked': true,
        },
      });
      final actual =
          result['lanes']['main']['document']['instances'][marker] as Map;
      expect(actual['settings']['mode'], 'random');
      expect(actual['currentRoll'], anyOf('blue', 'green'));
      expect(actual['locked'], true);
      expect((await repository.getBlock(id))!.content, 'blue, green');
      await run('block_manage', {
        'action': 'instance_update',
        'marker': marker,
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'enabled': false},
      });
      expect(container.read(generationParamsNotifierProvider).prompt, '');
    },
  );

  test(
    'updating a library block preserves mounted instances and immediately refreshes unmounted projections',
    () async {
      final created = await create({'title': '眼睛', 'content': 'blue eyes'});
      final id = created['id'] as String;
      final inserted = await insert(id, scope: 'negative');
      final document = container
          .read(pillWorkspaceProvider('negative'))
          .document;
      await run('block_manage', {
        'action': 'update',
        'id': id,
        'expected_version': (await block(id))['version'],
        'changes': {'content': 'green eyes'},
      });
      expect(
        container.read(pillWorkspaceProvider('negative')).document.text,
        document.text,
      );
      expect(
        container.read(generationParamsNotifierProvider).negativePrompt,
        'green eyes',
      );
      expect(inserted['lanes']['negative']['inserted_markers'].length, 1);
    },
  );

  test(
    'stale block and draft versions never overwrite newer changes',
    () async {
      final created = await create({'title': 'one', 'content': 'original'});
      final id = created['id'] as String,
          oldVersion = created['block']['version'] as String;
      final originalDraft = draft();
      await repository.updateBlock(
        (await repository.getBlock(id))!.copyWith(content: 'new user edit'),
      );
      await expectLater(
        run('block_manage', {
          'action': 'update',
          'id': id,
          'expected_version': oldVersion,
          'changes': {'content': 'stale model edit'},
        }),
        throwsA(toolError('block_conflict')),
      );
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new draft');
      await expectLater(
        run('block_manage', {
          'action': 'insert',
          'id': id,
          'expected_version': (await block(id))['version'],
          'expected_draft_version': originalDraft.acknowledgementVersion,
        }),
        throwsA(toolError('draft_conflict')),
      );
      expect((await repository.getBlock(id))!.content, 'new user edit');
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'new draft',
      );
    },
  );

  test(
    'invalid block fields and instance scopes/markers/settings fail before a backup or mutation',
    () async {
      await expectLater(
        create({'title': 'bad', 'content': 'raw', 'id': 'invented'}),
        throwsA(toolError('invalid_changes')),
      );
      final created = await create({'title': 'good', 'content': 'raw'});
      final dir = Directory('${workspace.path}/.agent/snapshot-backups');
      final count = await dir.list().length;
      final id = created['id'] as String;
      for (final patch in [
        {'scope': 'unknown'},
        {'scope': 'char:deleted:pos'},
        {'offset': 999999},
      ]) {
        await expectLater(
          run('block_manage', {
            'action': 'insert',
            'id': id,
            'expected_version': (await block(id))['version'],
            'expected_draft_version': draft().acknowledgementVersion,
            ...patch,
          }),
          throwsA(isA<NaiAgentToolError>()),
        );
      }
      final inserted = await insert(id);
      final marker =
          inserted['lanes']['main']['inserted_markers'].single as String;
      final before = draft();
      await expectLater(
        run('block_manage', {
          'action': 'instance_update',
          'marker': marker,
          'expected_draft_version': before.acknowledgementVersion,
          'instance': {
            'settings': {'triggerProbability': 8},
          },
        }),
        throwsA(toolError('invalid_instance')),
      );
      expect(draft().acknowledgementVersion, before.acknowledgementVersion);
      expect(
        await dir.list().length,
        count + 1,
      ); // only the valid insertion added a backup
    },
  );

  test(
    'a thumbnail is backed up as bytes before deleting its library row',
    () async {
      final file = File('${root.path}/synthetic-thumbnail.png');
      final pixels = <int>[137, 80, 78, 71, 0, 1, 2, 3];
      await file.writeAsBytes(pixels);
      final original = await repository.createBlock(
        title: 'preview',
        content: 'raw',
        thumbnail: file.path,
      );
      final result = await run('block_manage', {
        'action': 'delete',
        'id': original.id,
        'expected_version': (await block(original.id))['version'],
      });
      final backup = jsonDecode(
        await File(result['backup_path'] as String).readAsString(),
      );
      expect(
        base64Decode(backup['generation']['affected_thumbnail']['data_base64']),
        pixels,
      );
      expect(await repository.getBlock(original.id), null);
      expect(await file.exists(), true);
    },
  );

  test(
    'a delayed usage reply cannot restore old content into a newer provider projection',
    () async {
      final created = await create({'title': 'live', 'content': 'old content'});
      final id = created['id'] as String;
      final reached = Completer<void>(), release = Completer<void>();
      repository.afterUsage = () async {
        if (!reached.isCompleted) reached.complete();
        await release.future;
      };
      try {
        await insert(id);
        await reached.future;
        await run('block_manage', {
          'action': 'update',
          'id': id,
          'expected_version': (await block(id))['version'],
          'changes': {'content': 'newer content'},
        });
        expect(
          container.read(pillWorkspaceProvider('main')).projection,
          'newer content',
        );
        release.complete();
        await Future<void>.delayed(Duration.zero);
        expect(
          container
              .read(promptBlockLibraryNotifierProvider)
              .valueOrNull!
              .blockById(id)!
              .content,
          'newer content',
        );
        expect(
          container.read(pillWorkspaceProvider('main')).projection,
          'newer content',
        );
        expect(
          container.read(generationParamsNotifierProvider).prompt,
          'newer content',
        );
        expect((await repository.getBlock(id))!.useCount, 1);
      } finally {
        if (!release.isCompleted) release.complete();
      }
    },
  );

  test(
    'stopping before a tool starts leaves the real repository unchanged',
    () async {
      final token = NaiAgentCancellation()..cancel();
      await expectLater(
        container
            .read(naiAgentStudioFactoryProvider)(workspace, root, true)
            .execute('block_manage', {
              'action': 'create',
              'changes': {'title': 'cancelled', 'content': 'raw'},
            }, token),
        throwsA(toolError('cancelled')),
      );
      expect((await repository.load()).blocks, isEmpty);
    },
  );
}
