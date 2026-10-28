import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_snapshot.dart';
import '../../../core/nai_agent/snapshot_tool.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/character/character_prompt.dart' as character;
import '../../../data/models/image/image_params.dart';
import '../../../data/models/prompt/prompt_preset_mode.dart';
import '../../../data/models/prompt_block/pill_document.dart';
import '../../../data/models/prompt_block/prompt_block.dart';
import '../../../data/services/nai_agent/agent_snapshot_files.dart';
import '../image_generation_provider.dart';
import '../generation/image_workflow_controller.dart';
import '../generation/image_workflow_snapshot.dart';
import '../character_prompt_provider.dart';
import '../pill_workspace_provider.dart';
import '../prompt_block_library_provider.dart';
import '../quality_preset_provider.dart';
import '../uc_preset_provider.dart';
import '../krita/bridge_draft_snapshot.dart';

class _PreparedSnapshot {
  _PreparedSnapshot(
    this.image,
    this.workflow,
    this.documents,
    this.config,
    this.quality,
    this.qualityId,
    this.uc,
    this.ucId,
    this.format,
    this.convert,
    this.dependencies,
  );
  final ImageParams image;
  final ImageWorkflowState workflow;
  final Map<String, PillDocument> documents;
  final character.CharacterPromptConfig config;
  final PromptPresetMode quality;
  final UcPresetType uc;
  final String? qualityId, ucId;
  final bool format, convert;
  final Map<String, String> dependencies;
}

NaiAgentSnapshotTool bindNaiAgentSnapshots(
  Ref ref,
  Directory workspace,
  bool Function() isBusy,
  bool Function() isAlive,
) {
  Map<String, dynamic> capture() {
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final image = controller.snapshotDraftParams;
    final draft = readBridgeDraft(ref, imageOverride: image);
    final ids = <String>{};
    void collect(Object? value) {
      if (value is Map) {
        if (value['blockId'] is String &&
            (value['blockId'] as String).isNotEmpty &&
            value['translation'] == null) {
          ids.add(value['blockId'] as String);
        }
        for (final child in value.values) {
          collect(child);
        }
      } else if (value is List) {
        for (final child in value) {
          collect(child);
        }
      }
    }

    collect(draft.documents);
    final quality = ref.read(qualityPresetNotifierProvider);
    final uc = ref.read(ucPresetNotifierProvider);
    if (quality.customEntryId case final id?) ids.add(id);
    if (uc.customEntryId case final id?) ids.add(id);
    final library = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    final blocks = <Map<String, dynamic>>[];
    for (final id in ids) {
      final block = library?.blockById(id);
      if (block == null) {
        throw NaiAgentToolError(
          'block_missing',
          'Snapshot references missing block: $id',
        );
      }
      blocks.add(block.toJson());
    }
    return {
      'version': 1,
      'draft': draft.toJson(),
      'image': encodeAgentImageParams(image),
      'image_workflow': encodeImageWorkflowConfiguration(
        controller.snapshotDraftWorkflow,
        image,
      ),
      'blocks': blocks,
      'auto_format': ref.read(autoFormatPromptSettingsProvider),
      'sd_syntax_convert': ref.read(sdSyntaxAutoConvertSettingsProvider),
    };
  }

  return NaiAgentSnapshotTool(
    files: AgentSnapshotFiles(workspace),
    capture: capture,
    isBusy: isBusy,
    isAlive: isAlive,
    readVersion: () => readBridgeDraft(ref).acknowledgementVersion,
    readWriteContext: () => ref.read(imageWorkflowControllerProvider),
    readBack: () => {
      ...readBridgeDraft(ref).toJson(),
      'image_workflow': encodeImageWorkflowConfiguration(
        ref.read(imageWorkflowControllerProvider),
        ref.read(generationParamsNotifierProvider),
      ),
    },
    prepare: (snapshot, check) async {
      if (snapshot['version'] != 1) {
        throw const FormatException('Unknown generation snapshot version');
      }
      final image = decodeAgentImageParams(_map(snapshot['image']));
      final workflow = decodeImageWorkflowConfiguration(
        snapshot['image_workflow'],
        image,
        legacyPreferences: ref.read(imageWorkflowControllerProvider),
      );
      final savedDraft = _map(snapshot['draft']);
      final fields = _map(savedDraft['fields']);
      validateBridgePatch(fields);
      // Validate actual restored values too, before any library or draft writes.
      validateBridgePatch({
        'model': image.model,
        'width': image.width,
        'height': image.height,
        'steps': image.steps,
        'cfg_scale': image.scale,
        'sampler': image.sampler,
        'seed': image.seed,
        'n_samples': image.nSamples,
        'cfg_rescale': image.cfgRescale,
        'noise_schedule': image.noiseSchedule,
      });
      for (final bytes in [
        image.sourceImage,
        image.maskImage,
        ...image.preciseReferences.map((e) => e.image),
        ...image.vibeReferencesV4.map((e) => e.rawImageData),
      ]) {
        if (bytes == null) continue;
        final size = NaiResolutionAdapter.readImageSize(bytes);
        if (size == null || size.$1 * size.$2 > 64000000) {
          throw const FormatException('Invalid or oversized snapshot image');
        }
      }
      final docs = _map(savedDraft['documents']);
      final config = character.CharacterPromptConfig.fromJson(
        _map(_map(docs['characters'])['config']),
      );
      final ids = config.characters.map((e) => e.id).toSet();
      if (ids.length != config.characters.length ||
          ids.any((id) => id.isEmpty)) {
        throw const FormatException('Invalid snapshot character IDs');
      }
      final lanes = _map(_map(docs['characters'])['lanes']);
      final documents = <String, PillDocument>{
        PillScopes.main: PillDocument.fromJson(_map(docs['prompt'])),
        PillScopes.negative: PillDocument.fromJson(
          _map(docs['negative_prompt']),
        ),
        for (final c in config.characters) ...{
          PillScopes.charPos(c.id): PillDocument.fromJson(
            _map(_map(lanes[c.id])['positive']),
          ),
          PillScopes.charNeg(c.id): PillDocument.fromJson(
            _map(_map(lanes[c.id])['negative']),
          ),
        },
      };
      final q = _map(docs['quality_preset']), u = _map(docs['uc_preset']);
      final quality = PromptPresetMode.values.asNameMap()[q['mode']];
      final uc = UcPresetType.values.asNameMap()[u['type']];
      if (quality == null || uc == null) {
        throw const FormatException('Invalid snapshot preset');
      }
      final qualityId = q['selected'] == null
          ? null
          : _map(q['selected'])['id'] as String;
      final ucId = u['selected'] == null
          ? null
          : _map(u['selected'])['id'] as String;
      if (quality == PromptPresetMode.custom && qualityId == null) {
        throw const FormatException('Custom quality preset is missing');
      }
      final format = snapshot['auto_format'] as bool;
      final convert = snapshot['sd_syntax_convert'] as bool;
      final savedBlocks = (snapshot['blocks'] as List)
          .map((b) => PromptBlock.fromJson(_map(b)))
          .toList();
      final byId = {for (final b in savedBlocks) b.id: b};
      final requiredIds = {
        if (qualityId != null) qualityId,
        if (ucId != null) ucId,
        for (final doc in documents.values)
          for (final instance in doc.instances.values)
            if (instance.translation == null && instance.blockId.isNotEmpty)
              instance.blockId,
      };
      if (!requiredIds.every(byId.containsKey)) {
        throw const FormatException(
          'Snapshot block definitions are incomplete',
        );
      }
      check();
      final library = await ref.read(promptBlockLibraryNotifierProvider.future);
      check();
      final remap = <String, String>{}, imports = <PromptBlock>[];
      for (final id in requiredIds) {
        final saved = byId[id]!;
        final signature = _blockContent(saved);
        final current = library.blockById(id);
        final same = current != null && _blockContent(current) == signature
            ? current
            : [...library.blocks, ...library.archivedBlocks]
                  .where(
                    (b) =>
                        (b.lineageId ?? b.id) ==
                            (saved.lineageId ?? saved.id) &&
                        _blockContent(b) == signature,
                  )
                  .firstOrNull;
        if (same != null) {
          remap[id] = same.id;
          continue;
        }
        final copyId = const Uuid().v4();
        remap[id] = copyId;
        imports.add(
          saved.copyWith(
            id: copyId,
            lineageId: saved.lineageId ?? saved.id,
            folderId: null,
            thumbnail: null,
            sourcePath: null,
            sourceHash: null,
            importedAt: null,
            isArchived: true,
            useCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (imports.isNotEmpty) {
        // Only fresh UUIDs are added. Existing blocks, including newer edits,
        // are never overwritten when restoring an old configuration.
        check();
        await ref.read(promptBlockRepositoryProvider).importBlocks(imports);
        await ref.read(promptBlockLibraryNotifierProvider.notifier).refresh();
        check();
      }
      return _PreparedSnapshot(
        image,
        workflow,
        {
          for (final e in documents.entries)
            e.key: e.value.copyWith(
              instances: {
                for (final i in e.value.instances.entries)
                  i.key: i.value.translation == null
                      ? i.value.copyWith(blockId: remap[i.value.blockId])
                      : i.value,
              },
            ),
        },
        config,
        quality,
        qualityId == null ? null : remap[qualityId],
        uc,
        ucId == null ? null : remap[ucId],
        format,
        convert,
        {for (final id in requiredIds) remap[id]!: _blockContent(byId[id]!)},
      );
    },
    apply: (value) {
      final saved = value as _PreparedSnapshot;
      final library = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
      for (final entry in saved.dependencies.entries) {
        final actual = library?.blockById(entry.key);
        if (actual == null || _blockContent(actual) != entry.value) {
          throw const NaiAgentToolError(
            'block_conflict',
            'A snapshot dependency changed during loading; load again against the current draft',
          );
        }
      }
      ref
          .read(characterPromptNotifierProvider.notifier)
          .restoreAgentSnapshot(saved.config);
      final quality = ref.read(qualityPresetNotifierProvider.notifier);
      switch (saved.quality) {
        case PromptPresetMode.naiDefault:
          quality.setNaiDefault();
        case PromptPresetMode.naiLight:
          quality.setNaiLight();
        case PromptPresetMode.none:
          quality.setNone();
        case PromptPresetMode.custom:
          quality.setCustomEntry(saved.qualityId!);
      }
      final uc = ref.read(ucPresetNotifierProvider.notifier);
      uc.setPresetType(saved.uc);
      if (saved.ucId != null) uc.setCustomEntry(saved.ucId!);
      ref.read(autoFormatPromptSettingsProvider.notifier).set(saved.format);
      ref.read(sdSyntaxAutoConvertSettingsProvider.notifier).set(saved.convert);
      for (final entry in saved.documents.entries) {
        ref
            .read(pillWorkspaceProvider(entry.key).notifier)
            .restoreDocument(entry.value);
      }
      ref
          .read(imageWorkflowControllerProvider.notifier)
          .restoreConfiguration(saved.image, saved.workflow);
    },
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Invalid snapshot document');
  return Map<String, dynamic>.from(value);
}

String _blockContent(PromptBlock block) => jsonEncode({
  'content': block.content,
  'negative': block.negativeContent,
  'atoms': block.atoms,
  'negative_atoms': block.negativeAtoms,
  'settings': block.generationSettings?.toJson(),
});
