import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/services/character_conversion_service.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/metadata/metadata_import_options.dart';
import '../../data/models/online_gallery/gallery_item.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/bridge_draft_snapshot.dart';
import '../providers/pending_prompt_provider.dart';
import '../ui/online/online_contract.dart';
import '../utils/metadata_import_coordinator.dart';

final onlineDraftBackupProvider = Provider<OnlineDraftBackup>(
  (ref) => const OnlineDraftBackup(),
);
final onlineGenerationTargetProvider = Provider<OnlineGenerationTarget>(
  (ref) => OnlineGenerationTarget(ref, ref.read(onlineDraftBackupProvider)),
);

class OnlineDraftBackup {
  const OnlineDraftBackup();

  Future<void> save(String snapshot) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'draft-backups'));
    await directory.create(recursive: true);
    await File(
      p.join(
        directory.path,
        'before-online-${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    ).writeAsString(snapshot, flush: true);
  }
}

class OnlineGenerationSnapshot {
  const OnlineGenerationSnapshot(this.version, this.pending, this.json);
  final String version;
  final String pending;
  final String json;
}

class OnlineGenerationTarget {
  const OnlineGenerationTarget(this.ref, this.backup);
  final Ref ref;
  final OnlineDraftBackup backup;

  Map<String, Object?> _pending() {
    final pending = ref.read(pendingPromptNotifierProvider);
    return {
      'prompt': pending.prompt,
      'negativePrompt': pending.negativePrompt,
      'clearOnConsume': pending.clearOnConsume,
      'targetType': pending.targetType?.name,
    };
  }

  OnlineGenerationSnapshot capture() => OnlineGenerationSnapshot(
    ref.read(bridgeDraftVersionProvider),
    jsonEncode(_pending()),
    jsonEncode({
      ...readBridgeDraft(ref).toJson(),
      'generation': ref.read(generationParamsNotifierProvider).toJson(),
      'pending': _pending(),
    }),
  );

  void _check(OnlineGenerationSnapshot snapshot, bool Function() alive) {
    if (!alive() ||
        snapshot.version != ref.read(bridgeDraftVersionProvider) ||
        snapshot.pending != jsonEncode(_pending())) {
      throw StateError(currentL10n.bridge_conflict);
    }
    if (ref.read(imageGenerationNotifierProvider).isGenerating) {
      throw StateError(currentL10n.networkError_conflict);
    }
  }

  Future<void> apply(
    GalleryDetail detail,
    OnlineSendMode mode, {
    required OnlineGenerationSnapshot snapshot,
    required bool Function() alive,
  }) async {
    final media = detail.media.firstOrNull;
    final prompt =
        media?.prompt ?? detail.prompt ?? detail.item.tags.join(', ');
    final negative = media?.negativePrompt ?? detail.negativePrompt ?? '';
    final metadata = media?.naiMetadata;
    if (mode == OnlineSendMode.withParams && metadata == null) {
      throw StateError(currentL10n.onlineGallery_noTagInfo);
    }
    if (prompt.isEmpty && metadata == null) {
      throw StateError(currentL10n.onlineGallery_noTagInfo);
    }
    _check(snapshot, alive);
    await backup.save(snapshot.json);
    _check(snapshot, alive);
    final params = ref.read(generationParamsNotifierProvider.notifier);
    if (mode == OnlineSendMode.withParams) {
      ref.read(pendingPromptNotifierProvider.notifier).clear();
      await MetadataImportCoordinator.applyOfficialSelection(
        read: ref.read,
        metadata: metadata!,
        selection: const OfficialMetadataImportSelection(
          importPrompt: true,
          importNegativePrompt: true,
          importGenerationParams: true,
          importSeed: true,
          importCharacters: true,
        ),
      );
    } else {
      if (mode == OnlineSendMode.replace) {
        ref.read(characterPromptNotifierProvider.notifier).clearAllCharacters();
      }
      params.updatePromptImmediately(prompt);
      params.updateNegativePromptImmediately(negative);
      ref
          .read(pendingPromptNotifierProvider.notifier)
          .set(prompt: prompt, negativePrompt: negative);
    }
    if (mode != OnlineSendMode.promptOnly) {
      final converted = CharacterConversionService().convert(
        ref.read(characterPromptNotifierProvider),
        resolveAliases: false,
      );
      params.clearCharacters();
      for (final character in converted.characters) {
        params.addCharacter(character);
      }
      params.updateUseCoords(converted.useCoords);
    }
  }
}
