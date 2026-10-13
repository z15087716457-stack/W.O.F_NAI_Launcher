import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters;
import 'generation_binding_test.dart'
    show
        GenerationTestAuth,
        ControlledAgentGeneration,
        GenerationTestVibes,
        GenerationTestLibrary;

final _draft = Provider(
  (ref) =>
      () => readBridgeDraft(ref),
);
Matcher error(String code) =>
    isA<NaiAgentToolError>().having((e) => e.code, 'code', code);

void main() {
  late Directory root, workspace;
  late ProviderContainer container;
  late NaiAgentStudioTools tools;
  late Uint8List pixels;
  late List<ImageParams> generated;
  late ExploreGenerateFn generate;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-exploration-');
    workspace = await Directory('${root.path}/workspace').create();
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox<String>(StorageKeys.promptWorkspaceStateBox);
    final blocks = PromptBlockStorage(hivePath: root.path);
    await blocks.init();
    final runs = StyleExploreRunStorage(hivePath: root.path);
    await runs.init();
    pixels = Uint8List.fromList(img.encodePng(img.Image(width: 6, height: 4)));
    generated = [];
    generate = (params) async => ExploreGenerationResult(
      imageBytes: pixels,
      seed: 42,
      elapsedMs: 1,
      imageWidth: 6,
      imageHeight: 4,
    );
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(blocks),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          GenerationTestLibrary.new,
        ),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          GenerationTestVibes(),
        ),
        imageGenerationNotifierProvider.overrideWith(
          ControlledAgentGeneration.new,
        ),
        authNotifierProvider.overrideWith(GenerationTestAuth.new),
        styleExploreRunStorageProvider.overrideWithValue(runs),
        exploreRunImageStoreProvider.overrideWithValue(
          ExploreRunImageStore(
            rootPathResolver: () async => '${root.path}/images',
          ),
        ),
        exploreGenerateFnProvider.overrideWithValue((params) async {
          generated.add(params);
          return generate(params);
        }),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    tools = container.read(naiAgentStudioFactoryProvider)(
      workspace,
      root,
      true,
      owner: const NaiAgentConversationOwner('workspace', 'chat'),
    );
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  Future<Map> call(
    String action, [
    Map<String, dynamic> fields = const {},
    NaiAgentCancellation? token,
  ]) async =>
      (await tools.execute('explore_manage', {
            'action': action,
            ...fields,
          }, token ?? NaiAgentCancellation()))['details']
          as Map;
  Future<String> create([int count = 2]) async =>
      (await call('create', {
            'name': 'Synthetic exploration',
            'count': count,
            'expected_draft_version': container
                .read(_draft)()
                .acknowledgementVersion,
          }))['id']
          as String;
  Future<Map> read(String id) => call('read', {'id': id});
  Future<Map> edit(
    String id,
    String action, [
    Map<String, dynamic> fields = const {},
  ]) async => call(action, {
    'id': id,
    'expected_version': (await read(id))['version'],
    ...fields,
  });
  Future<Map> quote(
    String id, [
    Map<String, dynamic> fields = const {},
  ]) async =>
      (await call('prepare', {
            'id': id,
            'expected_version': (await read(id))['version'],
            ...fields,
          }))['quote']
          as Map;
  Future<AgentGenerationApproval> approval() async {
    for (var i = 0; i < 100; i++) {
      final pending = container
          .read(naiAgentGenerationApprovalsProvider)
          .forChat('chat');
      if (pending.isNotEmpty) return pending.single;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    throw StateError('No approval');
  }

  Future<Map> runApproved(String id, Map q) async {
    final future = call('run', {'id': id, 'quote_id': q['quote_id']});
    final request = await approval();
    container
        .read(naiAgentGenerationApprovalsProvider)
        .decide(request.id, generate: true);
    return future;
  }

  test(
    'creation, reads and organization use native persisted runs and preserve visible draft/selection',
    () async {
      expect(container.exists(exploreRunRunnerProvider), isFalse);
      await call('list');
      expect(container.exists(exploreRunRunnerProvider), isFalse);
      final before = container.read(_draft)().acknowledgementVersion;
      final id = await create();
      expect((await call('list'))['runs'][0]['id'], id);
      expect((await read(id))['run']['targetCount'], 2);
      final folder = await edit(id, 'folder_create', {'name': 'Keep'});
      await edit(id, 'folder_rename', {
        'folder_id': folder['folder_id'],
        'name': 'Best',
      });
      await edit(id, 'folder_delete', {'folder_id': folder['folder_id']});
      await edit(id, 'rename', {'name': 'Renamed'});
      expect((await read(id))['run']['name'], 'Renamed');
      await edit(id, 'complete');
      expect((await read(id))['run']['status'], 'completed');
      expect(container.read(_draft)().acknowledgementVersion, before);
      expect(container.read(exploreActiveRunIdProvider), isNull);
      expect(await File(folder['backup_path'] as String).exists(), isTrue);
    },
  );
  test(
    'stale exploration edits and draft creation reject before overwriting native state',
    () async {
      final id = await create();
      final version = (await read(id))['version'];
      await container
          .read(exploreRunListNotifierProvider.notifier)
          .rename(id, 'User edit');
      await expectLater(
        call('rename', {
          'id': id,
          'name': 'Stale',
          'expected_version': version,
        }),
        throwsA(error('explore_conflict')),
      );
      await expectLater(
        call('create', {
          'name': 'Stale',
          'count': 1,
          'expected_draft_version': 'old',
        }),
        throwsA(error('draft_conflict')),
      );
      expect((await read(id))['run']['name'], 'User edit');
      expect((await call('list'))['total'], 1);
    },
  );
  test(
    'native candidate batch waits for real approval, persists pixels and rejects quote replay',
    () async {
      final id = await create(3), q = await quote(await create(1));
      final actualQuote = await quote(id);
      expect(actualQuote['requests'], 3);
      expect(actualQuote['balance_anlas'], 10000);
      expect(generated, isEmpty);
      final future = call('run', {
        'id': id,
        'quote_id': actualQuote['quote_id'],
        'authorized': true,
      });
      final request = await approval();
      expect(generated, isEmpty);
      container
          .read(naiAgentGenerationApprovalsProvider)
          .decide(request.id, generate: true);
      final result = await future;
      expect(result['status'], 'generated');
      expect(result['done_count'], 3);
      expect(result['authorization']['source'], 'user_button');
      expect(generated, hasLength(3));
      expect(generated.every((p) => p.nSamples == 1 && p.seed == -1), isTrue);
      final candidates = (await read(id))['run']['candidates'] as List;
      final image = await tools.execute('image_read', {
        'image_id': candidates[0]['image_id'],
      }, NaiAgentCancellation());
      expect(image['content'][1]['type'], 'image');
      expect(image['details']['metadata']['candidate_id'], candidates[0]['id']);
      await expectLater(
        call('run', {'id': id, 'quote_id': actualQuote['quote_id']}),
        throwsA(error('quote_missing')),
      );
      expect(q['quote_id'], isNot(actualQuote['quote_id']));
      await edit(id, 'heart', {
        'candidate_id': candidates[0]['id'],
        'heart': true,
      });
      final folder = await edit(id, 'folder_create', {'name': 'Favorites'});
      await edit(id, 'candidate_move', {
        'candidate_id': candidates[0]['id'],
        'folder_id': folder['folder_id'],
      });
      expect(
        (await read(id))['run']['candidates'][0]['review']['heart'],
        isTrue,
      );
      await edit(id, 'folder_delete', {'folder_id': folder['folder_id']});
      expect((await read(id))['run']['candidates'][0]['folderId'], isNull);
    },
  );
  test('quote changes and user rejection cause no native generation', () async {
    final id = await create(), q = await quote(id);
    await container
        .read(exploreRunListNotifierProvider.notifier)
        .rename(id, 'Changed');
    await expectLater(
      call('run', {'id': id, 'quote_id': q['quote_id']}),
      throwsA(error('explore_conflict')),
    );
    final fresh = await quote(id);
    final future = call('run', {'id': id, 'quote_id': fresh['quote_id']});
    container
        .read(naiAgentGenerationApprovalsProvider)
        .decide((await approval()).id, generate: false);
    expect((await future)['status'], 'cancelled');
    expect(generated, isEmpty);
  });
  test(
    'Agent Stop cancels its admitted batch, retaining completed candidates',
    () async {
      final first = Completer<ExploreGenerationResult?>();
      generate = (_) => first.future;
      final id = await create(3), q = await quote(await create(1));
      final owned = await quote(id), token = NaiAgentCancellation();
      final future = call('run', {
        'id': id,
        'quote_id': owned['quote_id'],
      }, token);
      container
          .read(naiAgentGenerationApprovalsProvider)
          .decide((await approval()).id, generate: true);
      for (var i = 0; i < 100 && generated.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(generated, hasLength(1));
      token.cancel();
      first.complete(
        ExploreGenerationResult(
          imageBytes: pixels,
          seed: 1,
          elapsedMs: 1,
          imageWidth: 6,
          imageHeight: 4,
        ),
      );
      final result = await future;
      expect(result['status'], 'cancelled');
      expect(result['done_count'], 1);
      expect(generated, hasLength(1));
      expect(q['quote_id'], isNot(owned['quote_id']));
    },
  );
  test('stale ownership cannot pause or cancel a later manual run', () async {
    final id = await create(1);
    await runApproved(id, await quote(id));
    final blocked = Completer<ExploreGenerationResult?>();
    generate = (_) => blocked.future;
    final runner = container.read(exploreRunRunnerProvider.notifier);
    final manual = runner.start(id);
    expect((await call('cancel', {'id': id}))['status'], 'already_finished');
    expect((await call('pause', {'id': id}))['status'], 'already_finished');
    blocked.complete(
      ExploreGenerationResult(
        imageBytes: pixels,
        seed: 3,
        elapsedMs: 1,
        imageWidth: 6,
        imageHeight: 4,
      ),
    );
    expect(await manual, isTrue);
    expect((await read(id))['run']['status'], 'generated');
  });
  test(
    'Agent cancellation cannot interrupt main generation taken over during an admitted exploration',
    () async {
      final native =
          container.read(imageGenerationNotifierProvider.notifier)
              as ControlledAgentGeneration;
      final pending = Completer<ExploreGenerationResult?>();
      generate = (params) {
        unawaited(native.generate(params));
        return pending.future;
      };
      final id = await create(2),
          q = await quote(id),
          token = NaiAgentCancellation();
      final future = call('run', {'quote_id': q['quote_id']}, token);
      container
          .read(naiAgentGenerationApprovalsProvider)
          .decide((await approval()).id, generate: true);
      for (var i = 0; i < 100 && generated.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(generated, hasLength(1));
      native.manualTakeover();
      token.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(native.cancels, 0);
      pending.complete(
        ExploreGenerationResult(
          imageBytes: pixels,
          seed: 1,
          elapsedMs: 1,
          imageWidth: 6,
          imageHeight: 4,
        ),
      );
      expect((await future)['status'], 'cancelled');
      expect(
        container.read(imageGenerationNotifierProvider).generationRunId,
        2,
      );
      expect(
        container.read(imageGenerationNotifierProvider).isGenerating,
        isTrue,
      );
      native.pending.complete();
    },
  );

  test(
    'changed parameters between images stop before the next paid request',
    () async {
      final id = await create(3);
      generate = (_) async {
        final notifier = container.read(
          generationParamsNotifierProvider.notifier,
        );
        notifier.updateSteps(30);
        return ExploreGenerationResult(
          imageBytes: pixels,
          seed: 1,
          elapsedMs: 1,
          imageWidth: 6,
          imageHeight: 4,
        );
      };
      final result = await runApproved(id, await quote(id));
      expect(generated, hasLength(1));
      expect(result['done_count'], 1);
      expect(result['status'], 'paused');
    },
  );

  test(
    'retry quote prices only pending and failed candidates and keeps completed results',
    () async {
      final id = await create(3);
      generate = (_) async => generated.length == 1
          ? null
          : ExploreGenerationResult(
              imageBytes: pixels,
              seed: generated.length,
              elapsedMs: 1,
              imageWidth: 6,
              imageHeight: 4,
            );
      final first = await runApproved(id, await quote(id));
      expect(first['failed_count'], 1);
      expect(first['done_count'], 2);
      final retry = await quote(id, {'mode': 'retry'});
      expect(retry['requests'], 1);
      final result = await runApproved(id, retry);
      expect(result['done_count'], 3);
      expect(result['new_image_count'], 1);
      expect(generated, hasLength(4));
    },
  );
  test(
    'deep generation uses existing native family and guard, without writing mutated text into the draft',
    () async {
      final repository = container.read(promptBlockRepositoryProvider);
      final block = await repository.createBlock(
        title: 'Pool',
        content: 'blue hair, red hair, green hair',
      );
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh(preserveCurrent: true);
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .restoreDocument(
            PillDocument(
              text: 'base, \uE000',
              instances: {
                '\uE000': PillInstance(
                  blockId: block.id,
                  evolutionEnabled: true,
                  settings: const PillInstanceSettings(
                    mode: PillRollMode.random,
                  ),
                ),
              },
            ),
          );
      final id = await create(1);
      final family = await container
          .read(exploreRunListNotifierProvider.notifier)
          .createFamily(
            id,
            name: 'Family',
            parents: [
              (sourceCandidateId: null, artistString: 'blue hair'),
              (sourceCandidateId: null, artistString: 'red hair'),
            ],
          );
      final before = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document;
      final q = await quote(id, {
        'mode': 'deep',
        'count': 2,
        'family_id': family.id,
        'parent_set_id': family.activeParentSetId,
      });
      expect(q['requests'], 2);
      final result = await runApproved(id, q);
      expect(result['done_count'], 2);
      expect(result['new_image_count'], 2);
      final run = await container
          .read(styleExploreRunRepositoryProvider)
          .getRun(id);
      expect(run!.rounds.single.phase, ExploreRoundPhase.deep);
      expect(
        run.candidates.every((c) => c.lineage.mutatedText != null),
        isTrue,
      );
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
        before.text,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances['\uE000']!
            .currentRoll,
        before.instances['\uE000']!.currentRoll,
      );
    },
  );
}
