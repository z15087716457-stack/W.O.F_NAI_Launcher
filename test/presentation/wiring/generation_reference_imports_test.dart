import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/nai_api_utils.dart';
import 'package:nai_launcher/core/utils/vibe_export_utils.dart';
import 'package:nai_launcher/core/network/request_builders/nai_image_request_builder.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_reference_identity.dart';
import 'package:nai_launcher/presentation/wiring/generation_reference_imports.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks;
import 'generation_backend_test.dart'
    show MemoryGenerationPlatform, RecordingGeneration, SwitchingAuth;

class ImportStorage extends VibeLibraryStorageService {
  String? generationJson;
  final entries = <String, VibeLibraryEntry>{};
  @override
  Future<VibeLibraryEntry?> findMatchingEntry(VibeReference vibe) async => null;
  @override
  Future<VibeLibraryEntry> saveEntry(VibeLibraryEntry entry) async {
    entries[entry.id] = entry;
    return entry;
  }

  @override
  Future<VibeLibraryEntry?> incrementUsedCount(String id) async => entries[id];
  @override
  Future<List<VibeLibraryEntry>> getRecentDisplayEntries({
    int limit = 20,
  }) async => entries.values.take(limit).toList();
  @override
  Future<void> saveGenerationStateJson(String stateJson) async {
    generationJson = stateJson;
  }

  @override
  Future<String?> loadGenerationStateJson() async => generationJson;
}

class ImportDecoder extends GenerationReferenceDecoder {
  Future<List<VibeReference>> Function(GenerationReferenceFile)? parseVibes;
  final pending = <Uint8List, Completer<Uint8List>>{};
  int normalizations = 0;
  @override
  Future<Uint8List> precise(GenerationReferenceFile file) {
    normalizations++;
    return (pending[file.bytes] ??= Completer<Uint8List>()).future;
  }

  @override
  Future<List<VibeReference>> vibes(GenerationReferenceFile file) async =>
      parseVibes != null
      ? await parseVibes!(file)
      : [VibeReference(displayName: file.name, vibeEncoding: 'offline-data')];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late MemoryGenerationPlatform platform;
  late GenerationReferenceImports imports;
  late List<String> encoded;
  late ImportDecoder decoder;
  late ImportStorage storage;
  Completer<String?>? pendingEncoding;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp(
      'generation-reference-imports-',
    );
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    encoded = [];
    pendingEncoding = null;
    platform = MemoryGenerationPlatform();
    decoder = ImportDecoder();
    storage = ImportStorage();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        imageGenerationNotifierProvider.overrideWith(RecordingGeneration.new),
        authNotifierProvider.overrideWith(SwitchingAuth.new),
        generationPlatformProvider.overrideWithValue(platform),
        generationReferenceDecoderProvider.overrideWithValue(decoder),
        vibeLibraryStorageServiceProvider.overrideWithValue(storage),
        estimatedCostProvider.overrideWithValue(12),
        generationVibeEncoderProvider.overrideWithValue((vibe, model) {
          encoded.add(model);
          return pendingEncoding?.future ?? Future.value('encoded-result');
        }),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updateModel(ImageModels.animeDiffusionV45Full);
    params.updatePromptImmediately('original');
    imports = container.read(generationReferenceImportsProvider);
  });
  tearDown(() async {
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  String pendingVibe() {
    container.read(generationParamsNotifierProvider.notifier).setVibeReferences(
      [
        VibeReference(
          displayName: 'raw',
          vibeEncoding: '',
          rawImageData: Uint8List.fromList([1]),
        ),
      ],
    );
    return container.read(generationReferenceIdentityProvider).vibes.single;
  }

  for (final count in [16, 17]) {
    test(
      'encoded PNG with $count references respects the existing limit',
      () async {
        decoder.parseVibes = const GenerationReferenceDecoder().vibes;
        final png = Uint8List.fromList(
          img.encodePng(img.Image(width: 16, height: 16)),
        );
        final bytes = await VibeExportUtils.buildEmbeddedPngBytes(
          vibes: [
            for (var i = 0; i < count; i++)
              VibeReference(
                displayName: 'v$i',
                vibeEncoding: 'offline-$i',
                encodingModel: ImageModels.animeDiffusionV45Full,
              ),
          ],
          carrierImageBytes: png,
        );
        final importing = imports.files(
          GenDropTarget.vibe,
          () async => [GenerationReferenceFile('bundle.png', bytes)],
        );
        if (count == 17) {
          await expectLater(importing, throwsStateError);
          expect(
            container.read(generationParamsNotifierProvider).vibeReferencesV4,
            isEmpty,
          );
          expect(platform.backups, isEmpty);
        } else {
          await importing;
          final actual = container
              .read(generationParamsNotifierProvider)
              .vibeReferencesV4;
          expect(actual, hasLength(16));
          expect(actual.map((v) => v.vibeEncoding), [
            for (var i = 0; i < 16; i++) 'offline-$i',
          ]);
        }
        expect(encoded, isEmpty);
      },
    );
  }

  test(
    'precise stages immediately, generate shares normalization, saves final PNG',
    () async {
      final raw = Uint8List.fromList([1, 2, 3]);
      var applied = 0;
      await imports.files(
        GenDropTarget.precise,
        () async => [GenerationReferenceFile('ref.png', raw)],
        replaceRequested: () => true,
        onApplied: () => applied++,
      );
      final writer = container.read(generationParamsNotifierProvider.notifier);
      final staged = container.read(generationParamsNotifierProvider);
      final idBefore = container
          .read(generationReferenceIdentityProvider)
          .precise
          .single;
      expect(staged.preciseReferences.single.image, raw);
      expect(applied, 1);
      expect(platform.backups, hasLength(1));
      final request = NAIImageRequestBuilder(
        params: staged,
        encodeVibe: (_, {required model, informationExtracted = 1}) async =>
            'unused',
      );
      final payload = <String, dynamic>{};
      final generating = request.buildPreciseReferenceParameters(payload);
      writer.updatePreciseReference(0, strength: 1.5);
      final normalized = Uint8List.fromList([9, 8, 7]);
      decoder.pending[raw]!.complete(normalized);
      await generating;
      await Future<void>.delayed(Duration.zero);
      expect(decoder.normalizations, 1);
      final finalRef = container
          .read(generationParamsNotifierProvider)
          .preciseReferences
          .single;
      expect(finalRef.image, same(normalized));
      expect(
        container.read(generationReferenceIdentityProvider).precise.single,
        idBefore,
      );
      expect(finalRef.strength, 1.5);
      await writer.saveGenerationState();
      final restoredContainer = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
          vibeLibraryStorageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(restoredContainer.dispose);
      await restoredContainer
          .read(generationParamsNotifierProvider.notifier)
          .restoreGenerationState();
      final restored = restoredContainer
          .read(generationParamsNotifierProvider)
          .preciseReferences
          .single;
      expect(restored.image, normalized);
      expect(restored.strength, 1.5);
      expect(
        NAIApiUtils.isKnownNormalizedPreciseReferencePng(restored.image),
        true,
      );
      expect(
        NAIApiUtils.isKnownNormalizedPreciseReferencePng(finalRef.image),
        true,
      );
    },
  );

  test(
    'normalization follows byte identity through reorder, never fills a removed slot',
    () async {
      final a = Uint8List.fromList([1]);
      final b = Uint8List.fromList([2]);
      await imports.files(
        GenDropTarget.precise,
        () async => [
          GenerationReferenceFile('a.png', a),
          GenerationReferenceFile('b.png', b),
        ],
      );
      final writer = container.read(generationParamsNotifierProvider.notifier);
      final before = container.read(generationParamsNotifierProvider);
      writer.restoreAgentSnapshot(
        before.copyWith(
          preciseReferences: before.preciseReferences.reversed.toList(),
        ),
      );
      decoder.pending[a]!.complete(Uint8List.fromList([11]));
      await Future<void>.delayed(Duration.zero);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .preciseReferences
            .last
            .image,
        [11],
      );
      writer.removePreciseReference(0);
      writer.addPreciseReference(
        Uint8List.fromList([3]),
        type: before.preciseReferences.first.type,
      );
      decoder.pending[b]!.complete(Uint8List.fromList([22]));
      await Future<void>.delayed(Duration.zero);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .preciseReferences
            .map((r) => r.image.first),
        [11, 3],
      );
    },
  );

  test(
    'remove then re-add of the exact input object never accepts the old result',
    () async {
      final raw = Uint8List.fromList([1]);
      final old = Completer<Uint8List>();
      final fresh = Completer<Uint8List>();
      final writer = container.read(generationParamsNotifierProvider.notifier);
      final type = GenerationReferenceFile('x', raw).type;
      final first = writer.addPreciseReferenceFromImage(
        raw,
        type: type,
        normalize: (_) => old.future,
      );
      writer.removePreciseReference(0);
      final second = writer.addPreciseReferenceFromImage(
        raw,
        type: type,
        normalize: (_) => fresh.future,
      );
      old.complete(Uint8List.fromList([9]));
      await first;
      expect(
        container
            .read(generationParamsNotifierProvider)
            .preciseReferences
            .single
            .image,
        [1],
      );
      fresh.complete(Uint8List.fromList([8]));
      await second;
      expect(
        container
            .read(generationParamsNotifierProvider)
            .preciseReferences
            .single
            .image,
        [8],
      );
    },
  );

  test(
    'precise file picker still rejects a newer draft before staging or decoding',
    () async {
      final selected = Completer<List<GenerationReferenceFile>>();
      var applied = false;
      final importing = imports.files(
        GenDropTarget.precise,
        () => selected.future,
        replaceRequested: () => true,
        onApplied: () => applied = true,
      );
      final rejected = expectLater(importing, throwsStateError);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new draft');
      selected.complete([
        GenerationReferenceFile('x.png', Uint8List.fromList([1])),
      ]);
      await rejected;
      expect(decoder.normalizations, 0);
      expect(applied, false);
      expect(
        container.read(generationParamsNotifierProvider).preciseReferences,
        isEmpty,
      );
    },
  );

  test('文件选择取消不备份；导入只解析并写入，不调用编码', () async {
    await imports.files(GenDropTarget.vibe, () async => []);
    expect(platform.backups, isEmpty);
    await imports.files(
      GenDropTarget.vibe,
      () async => [
        GenerationReferenceFile('entry.png', Uint8List.fromList([1])),
      ],
    );
    expect(platform.backups, hasLength(1));
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .displayName,
      'entry.png',
    );
    expect(encoded, isEmpty);
  });
  test('选择期间新编辑不被旧导入覆盖或追加', () async {
    final selected = Completer<List<GenerationReferenceFile>>();
    final running = imports.files(GenDropTarget.vibe, () => selected.future);
    final expectation = expectLater(running, throwsStateError);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new input');
    selected.complete([
      GenerationReferenceFile('old.png', Uint8List.fromList([1])),
    ]);
    await expectation;
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'new input',
    );
    expect(
      container.read(generationParamsNotifierProvider).vibeReferencesV4,
      isEmpty,
    );
    expect(platform.backups, isEmpty);
  });
  test('同一投放目标后发导入生效，先发慢选择不能覆盖新选择', () async {
    final first = Completer<List<GenerationReferenceFile>>();
    final running = imports.files(GenDropTarget.vibe, () => first.future);
    final rejected = expectLater(running, throwsStateError);
    await imports.files(
      GenDropTarget.vibe,
      () async => [
        GenerationReferenceFile('new.png', Uint8List.fromList([2])),
      ],
    );
    first.complete([
      GenerationReferenceFile('old.png', Uint8List.fromList([1])),
    ]);
    await rejected;
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .displayName,
      'new.png',
    );
  });
  test('编码取消及备份失败都不能调用付费编码入口', () async {
    final id = pendingVibe();
    await imports.encode(
      id,
      confirm: (cost) async {
        expect(cost, 2);
        return false;
      },
    );
    expect(encoded, isEmpty);
    expect(platform.backups, isEmpty);
    platform.fail = true;
    await expectLater(
      imports.encode(id, confirm: (_) async => true),
      throwsStateError,
    );
    expect(encoded, isEmpty);
    expect(container.read(generationEncodingReferencesProvider), isEmpty);
  });
  test('编码结果按原 ID 和草稿世代复查，期间改参数不写旧编码', () async {
    final id = pendingVibe();
    pendingEncoding = Completer<String?>();
    final running = imports.encode(id, confirm: (_) async => true);
    final rejected = expectLater(running, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    expect(encoded, hasLength(1));
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateVibeReference(0, infoExtracted: .4);
    pendingEncoding!.complete('obsolete-encoding');
    await rejected;
    final vibe = container
        .read(generationParamsNotifierProvider)
        .vibeReferencesV4
        .single;
    expect(vibe.infoExtracted, .4);
    expect(vibe.vibeEncoding, isEmpty);
    expect(container.read(generationEncodingReferencesProvider), isEmpty);
  });
  test('编码中不能重复编码或生成，结束后旧生成确认也不能继续', () async {
    final confirmation = Completer<bool>();
    final backend = container.read(generationBackendProvider);
    final id = pendingVibe();
    final oldGeneration = backend.generate(confirm: (_) => confirmation.future);
    pendingEncoding = Completer<String?>();
    final running = imports.encode(id, confirm: (_) async => true);
    await Future<void>.delayed(Duration.zero);
    await imports.encode(id, confirm: (_) async => true);
    await backend.generate(confirm: (_) async => true);
    expect(encoded, hasLength(1));
    expect(
      (container.read(imageGenerationNotifierProvider.notifier)
              as RecordingGeneration)
          .requests,
      isEmpty,
    );
    pendingEncoding!.complete('encoded-result');
    await running;
    confirmation.complete(true);
    await oldGeneration;
    expect(
      (container.read(imageGenerationNotifierProvider.notifier)
              as RecordingGeneration)
          .requests,
      isEmpty,
    );
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .vibeEncoding,
      'encoded-result',
    );
  });
  test('图生图开关改后又改回，不能使旧生成确认重新有效', () async {
    final confirmation = Completer<bool>();
    final running = container
        .read(generationBackendProvider)
        .generate(confirm: (_) => confirmation.future);
    final flag = container.read(generationImg2ImgEnabledProvider.notifier);
    flag.set(false);
    flag.set(true);
    confirmation.complete(true);
    await running;
    expect(
      (container.read(imageGenerationNotifierProvider.notifier)
              as RecordingGeneration)
          .requests,
      isEmpty,
    );
  });
}
