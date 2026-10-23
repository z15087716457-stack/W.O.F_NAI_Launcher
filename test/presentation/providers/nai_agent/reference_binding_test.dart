import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/nai_agent/generation_snapshot.dart';
import 'package:nai_launcher/core/utils/nai_api_utils.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_snapshot_files.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_reference_binding.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters, IdleGeneration, OfflineAuth;
import 'generation_binding_test.dart'
    show GenerationTestLibrary, GenerationTestVibes;

class _AfterBackup extends AgentSnapshotFiles {
  _AfterBackup(super.workspace, this.after);
  final Future<void> Function() after;
  @override
  Future<Map<String, dynamic>> save(
    String name,
    Map<String, dynamic> snapshot, {
    bool backup = false,
  }) async {
    final result = await super.save(name, snapshot, backup: backup);
    await after();
    return result;
  }
}

void main() {
  late Directory root;
  late ProviderContainer container;
  late bool busy, alive;
  late Uint8List pixels;
  NaiAgentStudioTools tools({bool vision = true}) =>
      container.read(naiAgentStudioFactoryProvider)(root, root, vision);
  GenerationParamsNotifier writer() =>
      container.read(generationParamsNotifierProvider.notifier);
  Future<Map<String, dynamic>> list() async =>
      (await tools().execute(
            'reference_manage',
            {},
            NaiAgentCancellation(),
          ))['details']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> apply(
    String action, [
    Map<String, dynamic> extra = const {},
  ]) async =>
      (await tools().execute('reference_manage', {
            'action': action,
            'expected_draft_version': (await list())['draft_version'],
            ...extra,
          }, NaiAgentCancellation()))['details']
          as Map<String, dynamic>;
  List<File> backups() =>
      Directory('${root.path}/.agent/snapshot-backups').existsSync()
      ? Directory(
          '${root.path}/.agent/snapshot-backups',
        ).listSync().whereType<File>().toList()
      : [];
  Matcher code(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));
  NaiAgentReferenceBinding custom({
    AgentSnapshotFiles? snapshots,
    Future<NaiAgentImage> Function(Map<String, dynamic>, NaiAgentCancellation)?
    loader,
  }) {
    final provider = Provider(
      (ref) => NaiAgentReferenceBinding(
        ref,
        root,
        loader ?? tools().loadImage,
        () => busy,
        () => alive,
        snapshots: snapshots,
      ),
    );
    return container.read(provider);
  }

  Future<Map<String, dynamic>> command(
    String action, [
    Map<String, dynamic> extra = const {},
  ]) async => {
    'action': action,
    'expected_draft_version': (await list())['draft_version'],
    ...extra,
  };

  setUp(() async {
    busy = false;
    alive = true;
    root = await Directory.systemTemp.createTemp('nai-agent-references-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final storage = PromptBlockStorage(hivePath: root.path);
    await storage.init();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(storage),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          GenerationTestLibrary.new,
        ),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          GenerationTestVibes(),
        ),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    writer().updateModel('nai-diffusion-4-5-full');
    writer().updatePrompt('kept, raw prompt');
    pixels = Uint8List.fromList(
      img.encodePng(img.Image(width: 128, height: 128)),
    );
    await File('${root.path}/input.png').writeAsBytes(pixels);
    final mask = img.Image(width: 128, height: 128);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    await File('${root.path}/mask.png').writeAsBytes(img.encodePng(mask));
  });
  tearDown(() async {
    alive = false;
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });

  test(
    'list is compact and read-only, without constructing the workflow',
    () async {
      final before = container.read(generationParamsNotifierProvider);
      final state = await list();
      expect(state['supports_vibe'], true);
      expect(state['supports_precise'], true);
      expect(state['source'], isNull);
      expect(state['vibes'], isEmpty);
      expect(state['workflow'], 'uninitialized');
      expect(container.exists(imageWorkflowControllerProvider), false);
      expect(container.read(generationParamsNotifierProvider), same(before));
      expect(backups(), isEmpty);
      expect(jsonEncode(state), isNot(contains(base64Encode(pixels))));
    },
  );

  test(
    'source/mask/focus/clear use native workflows and keep prompt with full backups',
    () async {
      final before = container.read(generationParamsNotifierProvider);
      final source = await apply('set_source', {
        'path': 'input.png',
        'use_image_size': false,
        'strength': 0.55,
        'noise': 0.12,
      });
      final params = container.read(generationParamsNotifierProvider);
      expect(params.sourceImage, pixels);
      expect(params.width, before.width);
      expect(params.height, before.height);
      expect(params.strength, 0.55);
      expect(params.noise, 0.12);
      expect(params.prompt, before.prompt);
      expect(params.maskImage, isNull);
      expect(source['action'], 'img2img');
      expect(source['workflow'], 'base');
      final backup = jsonDecode(
        await File(source['backup_path'] as String).readAsString(),
      );
      final restored = decodeAgentImageParams(
        Map<String, dynamic>.from(backup['generation']['image']),
      );
      expect(restored.sourceImage, before.sourceImage);
      expect(restored.prompt, before.prompt);
      expect(backup['generation']['draft']['fields']['prompt'], before.prompt);
      final masked = await apply('set_mask', {
        'path': 'mask.png',
        'focus_region': {
          'x': 0,
          'y': 0,
          'width': 64,
          'height': 64,
          'context': 8,
        },
      });
      expect(masked['action'], 'infill');
      expect(masked['workflow'], 'inpaint');
      expect(
        container
            .read(generationParamsNotifierProvider)
            .inpaintFocusRegion!
            .context,
        8,
      );
      final read = await tools().execute('image_read', {
        'image_id': 'draft:mask',
      }, NaiAgentCancellation());
      expect(read['details']['width'], 128);
      final clearMask = await apply('clear_mask');
      expect(clearMask['action'], 'img2img');
      expect(clearMask['mask'], isNull);
      expect(clearMask['focus_region'], isNull);
      final clear = await apply('clear_source');
      expect(clear['action'], 'generate');
      expect(clear['source'], isNull);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        before.prompt,
      );
      expect(backups(), hasLength(4));
    },
  );

  test(
    'replacing an inpaint source clears old mask and aligns native import dimensions',
    () async {
      await apply('set_source', {'path': 'input.png'});
      await apply('set_mask', {'path': 'mask.png'});
      final replaced = await apply('set_source', {'path': 'input.png'});
      expect(replaced['mask'], isNull);
      expect(replaced['action'], 'img2img');
      expect(replaced['workflow'], 'base');
      final read = await tools().execute('image_read', {
        'image_id': 'draft:source',
      }, NaiAgentCancellation());
      expect(read['details']['width'], 128);
      expect(read['details']['metadata'], isNull);
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        pixels,
      );
    },
  );

  test(
    'raw Vibe addition/update/removal defers encoding and preserves original bytes',
    () async {
      final added = await apply('add_vibe', {
        'path': 'input.png',
        'name': 'My Vibe',
        'strength': 1.5,
        'info_extracted': 0.5,
      });
      expect(added['vibes'].single['encoded'], false);
      expect(added['vibes'].single['image']['image_id'], 'draft:vibe:0');
      final reference = container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single;
      expect(reference.rawImageData, pixels);
      expect(reference.vibeEncoding, '');
      expect(reference.strength, 1.5);
      final updated = await apply('update_vibe', {
        'index': 0,
        'strength': 0.4,
        'info_extracted': 0.8,
        'enabled': false,
      });
      expect(updated['vibes'].single['enabled'], false);
      expect(updated['vibes'].single['info_extracted'], 0.8);
      expect(updated['vibes'].single['encoded'], false);
      final read = await tools().execute('image_read', {
        'image_id': 'draft:vibe:0',
      }, NaiAgentCancellation());
      expect(read['details']['source_bytes'], pixels.length);
      final removed = await apply('remove_vibe', {'index': 0});
      expect(removed['vibes'], isEmpty);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'kept, raw prompt',
      );
    },
  );

  test(
    'precise addition is normalized through native PNG workflow; update/removal is real',
    () async {
      final added = await apply('add_precise', {
        'path': 'input.png',
        'type': 'characterAndStyle',
        'strength': 1.5,
        'fidelity': 1.5,
      });
      final ref = container
          .read(generationParamsNotifierProvider)
          .preciseReferences
          .single;
      expect(NAIApiUtils.isKnownNormalizedPreciseReferencePng(ref.image), true);
      expect(added['precise'].single['type'], 'characterAndStyle');
      expect(added['precise'].single['strength'], 1.5);
      expect(added['precise'].single['fidelity'], 1.5);
      await expectLater(
        apply('update_precise', {'index': 0, 'strength': 10.1}),
        code('invalid_reference'),
      );
      final read = await tools().execute('image_read', {
        'image_id': 'draft:precise:0',
      }, NaiAgentCancellation());
      expect(read['details']['source_bytes'], ref.image.length);
      expect(read['details']['metadata'], isNull);
      final updated = await apply('update_precise', {
        'index': 0,
        'type': 'style',
        'enabled': false,
        'fidelity': 10.0,
      });
      expect(updated['precise'].single['type'], 'style');
      expect(updated['precise'].single['enabled'], false);
      final removed = await apply('remove_precise', {'index': 0});
      expect(removed['precise'], isEmpty);
    },
  );

  test(
    'unsupported models reject additions but allow clearing old references; limit is explicit',
    () async {
      for (var i = 0; i < 16; i++) {
        writer().addVibeReference(
          VibeReference(
            displayName: 'v$i',
            vibeEncoding: '',
            rawImageData: pixels,
          ),
        );
      }
      await expectLater(
        apply('add_vibe', {'path': 'input.png'}),
        code('reference_limit'),
      );
      writer().updateModel('nai-diffusion-5-full');
      await expectLater(
        apply('add_vibe', {'path': 'input.png'}),
        code('reference_unsupported'),
      );
      await expectLater(
        apply('add_precise', {'path': 'input.png'}),
        code('reference_unsupported'),
      );
      final cleared = await apply('clear_vibes');
      expect(cleared['vibes'], isEmpty);
      expect(backups(), hasLength(1));
    },
  );

  test(
    'nonvision models may configure original images while image_read remains gated',
    () async {
      final service = tools(vision: false),
          p = await command('add_vibe', {'path': 'input.png'});
      await service.execute('reference_manage', p, NaiAgentCancellation());
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .single
            .rawImageData,
        pixels,
      );
      await expectLater(
        service.execute('image_read', {
          'image_id': 'draft:vibe:0',
        }, NaiAgentCancellation()),
        code('vision_unavailable'),
      );
    },
  );

  test(
    'summary explains native precise priority and inpainting exclusions without disabling Vibe',
    () async {
      await apply('add_vibe', {'path': 'input.png'});
      await apply('add_precise', {'path': 'input.png'});
      var state = await list();
      expect(state['vibes'].single['enabled'], true);
      expect(state['vibes'].single['participates'], false);
      expect(
        state['vibes'].single['inactive_reason'],
        'precise_reference_priority',
      );
      await apply('clear_precise');
      expect((await list())['vibes'].single['participates'], true);
      await apply('set_source', {'path': 'input.png'});
      await apply('set_mask', {'path': 'mask.png'});
      state = await list();
      expect(
        state['vibes'].single['inactive_reason'],
        'inpainting_excludes_vibe',
      );
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .single
            .enabled,
        true,
      );
    },
  );

  test(
    'wrong versions and invalid settings/masks/focus leave draft untouched',
    () async {
      final current = container.read(generationParamsNotifierProvider);
      await expectLater(
        tools().execute('reference_manage', {
          'action': 'add_vibe',
          'path': 'input.png',
          'expected_draft_version': 'stale',
        }, NaiAgentCancellation()),
        code('draft_conflict'),
      );
      for (final extra in [
        {'strength': 2.0},
        {'strength': double.nan},
        {'use_image_size': 'yes'},
        {'type': 'style'},
      ]) {
        await expectLater(
          apply('set_source', {'path': 'input.png', ...extra}),
          code('invalid_reference'),
        );
      }
      await expectLater(
        apply('set_mask', {'path': 'mask.png'}),
        code('source_missing'),
      );
      await expectLater(
        apply('update_vibe', {'index': 0, 'strength': 0.2}),
        code('reference_missing'),
      );
      expect(backups(), isEmpty);
      expect(container.read(generationParamsNotifierProvider), same(current));
      await apply('set_source', {'path': 'input.png'});
      await File(
        '${root.path}/small.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 64, height: 64)));
      await expectLater(
        apply('set_mask', {'path': 'small.png'}),
        code('mask_size_mismatch'),
      );
      for (final focus in [
        {'x': 1, 'y': 0, 'width': 64, 'height': 64, 'context': 8},
        {'x': 120, 'y': 0, 'width': 64, 'height': 64, 'context': 8},
        {'x': 0, 'y': 0, 'width': 64, 'height': 64, 'context': 40},
      ]) {
        await expectLater(
          apply('set_mask', {'path': 'mask.png', 'focus_region': focus}),
          code('invalid_reference'),
        );
      }
      expect(backups(), hasLength(1));
      expect(
        container.read(generationParamsNotifierProvider).maskImage,
        isNull,
      );
    },
  );

  test(
    'changes while loading images reject before any backup or native write',
    () async {
      final waiting = Completer<NaiAgentImage>(), reached = Completer<void>();
      final binding = custom(
        loader: (_, __) {
          reached.complete();
          return waiting.future;
        },
      );
      final p = await command('add_vibe', {'path': 'input.png'});
      final pending = binding.execute(p, NaiAgentCancellation());
      final assertion = expectLater(pending, code('draft_conflict'));
      await reached.future;
      writer().updatePrompt('New human edit');
      waiting.complete(NaiAgentImage(id: 'original', bytes: pixels));
      await assertion;
      expect(backups(), isEmpty);
      expect(
        container.read(generationParamsNotifierProvider).vibeReferencesV4,
        isEmpty,
      );
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'New human edit',
      );
    },
  );

  test(
    'changes and Stop after real backup prevent write and preserve the old configuration',
    () async {
      final binding = custom(
        snapshots: _AfterBackup(
          root,
          () async => writer().updatePrompt('Human during backup'),
        ),
      );
      await expectLater(
        binding.execute(
          await command('add_vibe', {'path': 'input.png'}),
          NaiAgentCancellation(),
        ),
        code('draft_conflict'),
      );
      expect(
        container.read(generationParamsNotifierProvider).vibeReferencesV4,
        isEmpty,
      );
      final saved = jsonDecode(await backups().single.readAsString());
      expect(
        saved['generation']['draft']['fields']['prompt'],
        'kept, raw prompt',
      );
      final token = NaiAgentCancellation();
      final cancelling = custom(
        snapshots: _AfterBackup(root, () async => token.cancel()),
      );
      await expectLater(
        cancelling.execute(
          await command('add_vibe', {'path': 'input.png'}),
          token,
        ),
        code('cancelled'),
      );
      expect(backups(), hasLength(2));
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'Human during backup',
      );
    },
  );

  test('busy/closed binding rejects safely without mutation', () async {
    final binding = custom(),
        p = await command('add_vibe', {'path': 'input.png'});
    busy = true;
    await expectLater(binding.execute(p, NaiAgentCancellation()), code('busy'));
    busy = false;
    alive = false;
    await expectLater(
      binding.execute(p, NaiAgentCancellation()),
      code('closed'),
    );
    expect(backups(), isEmpty);
  });
}
