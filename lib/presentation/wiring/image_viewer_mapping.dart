import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/api_constants.dart';
import '../../core/shortcuts/default_shortcuts.dart';
import '../../core/shortcuts/shortcut_config.dart';
import '../../core/shortcuts/shortcut_manager.dart';
import '../../data/models/gallery/image_collection.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/services/gallery/gallery_sort.dart';
import '../ui/viewer/viewer_contract.dart';

String viewerTranslationText(PillDocument document) => document.text
    .split('')
    .map(
      (character) =>
          document.instances[character]?.translation?.zh ?? character,
    )
    .join();

ViewerDetail viewerDetailOf(
  String key,
  NaiImageMetadata? source, {
  String? path,
  bool loading = false,
}) {
  final metadata = source?.upgradeFromRawJsonIfNeeded();
  final model = metadata?.effectiveModel;
  final v3 = model == 'nai-diffusion-3' || model == 'nai-diffusion-furry-3';
  final characters = metadata?.characterInfos.isNotEmpty == true
      ? metadata!.characterInfos
      : [
          for (var i = 0; i < (metadata?.characterPrompts.length ?? 0); i++)
            CharacterPromptInfo(
              prompt: metadata!.characterPrompts[i],
              negativePrompt: i < metadata.characterNegativePrompts.length
                  ? metadata.characterNegativePrompts[i]
                  : null,
            ),
        ];
  double? coordinate(double? value) =>
      value != null && value.isFinite && value >= 0 && value <= 1
      ? value
      : null;
  return ViewerDetail(
    key: key,
    status: loading
        ? ViewerMetaStatus.loading
        : metadata?.hasData == true
        ? ViewerMetaStatus.ready
        : ViewerMetaStatus.none,
    fileName: path == null ? null : p.basename(path),
    folder: path == null ? null : p.dirname(path),
    model: ImageModels.modelDisplayNames[model] ?? model,
    sampler:
        Samplers.samplerDisplayNames[metadata?.sampler] ?? metadata?.sampler,
    seed: metadata?.seed,
    steps: metadata?.steps,
    scale: metadata?.scale,
    noiseSchedule: metadata?.noiseSchedule,
    cfgRescale: metadata?.cfgRescale,
    smea: v3
        ? metadata?.smeaDyn == true
              ? 'DYN'
              : metadata?.smea == true
              ? 'ON'
              : null
        : null,
    qualityTags: metadata?.qualityToggle,
    preciseCount: metadata?.preciseReferenceImages.length ?? 0,
    prompt: metadata?.prompt ?? '',
    negative: metadata?.negativePrompt ?? '',
    characters: [
      for (final c in characters)
        ViewerCharacter(
          prompt: c.prompt,
          negative: c.negativePrompt ?? '',
          x: coordinate(c.centerX),
          y: coordinate(c.centerY),
        ),
    ],
    vibes: [
      for (final vibe in metadata?.vibeReferences ?? [])
        ViewerVibe(
          name: vibe.displayName,
          thumb: vibe.thumbnail?.isNotEmpty == true
              ? MemoryImage(vibe.thumbnail!)
              : null,
          strength: vibe.strength,
          infoExtracted: vibe.infoExtracted,
        ),
    ],
  );
}

ViewerSort viewerSortOf(GallerySortField field) => switch (field) {
  GallerySortField.modifiedAt => ViewerSort.modified,
  GallerySortField.createdAt => ViewerSort.created,
  GallerySortField.fileName => ViewerSort.fileName,
  GallerySortField.fileSize => ViewerSort.fileSize,
  GallerySortField.imageDimensions => ViewerSort.dimensions,
};

List<ViewerCollection> viewerCollectionsOf(
  List<ImageCollection> collections,
  Set<String> members,
) {
  final result = <ViewerCollection>[];
  final visited = <String>{};
  void append(ImageCollection node, int depth) {
    if (!visited.add(node.id)) return;
    if (!node.isFolder) {
      result.add(
        ViewerCollection(
          id: node.id,
          name: node.name,
          member: members.contains(node.id),
          depth: depth,
        ),
      );
    }
    for (final child in collections.where((c) => c.parentId == node.id)) {
      append(child, depth + 1);
    }
  }

  final ids = collections.map((c) => c.id).toSet();
  for (final root in collections.where(
    (c) => c.parentId == null || !ids.contains(c.parentId),
  )) {
    append(root, 0);
  }
  for (final orphan in collections.where((c) => !visited.contains(c.id))) {
    append(orphan, 0);
  }
  return result;
}

String? viewerPartText(NaiImageMetadata? metadata, ViewerPart part) =>
    switch (part.kind) {
      ViewerPartKind.prompt => metadata?.prompt,
      ViewerPartKind.negative => metadata?.negativePrompt,
      ViewerPartKind.seed => metadata?.seed?.toString(),
      ViewerPartKind.character =>
        metadata == null || part.index < 0
            ? null
            : part.index < metadata.characterInfos.length
            ? metadata.characterInfos[part.index].prompt
            : part.index < metadata.characterPrompts.length
            ? metadata.characterPrompts[part.index]
            : null,
    };

Map<ViewerCommand, List<SingleActivator>> viewerKeysOf(ShortcutConfig config) {
  const ids = {
    ViewerCommand.previous: ShortcutIds.previousImage,
    ViewerCommand.next: ShortcutIds.nextImage,
    ViewerCommand.zoomIn: ShortcutIds.zoomIn,
    ViewerCommand.zoomOut: ShortcutIds.zoomOut,
    ViewerCommand.zoomFit: ShortcutIds.resetZoom,
    ViewerCommand.fullscreen: ShortcutIds.toggleFullscreen,
    ViewerCommand.close: ShortcutIds.closeViewer,
    ViewerCommand.toggleInfo: ShortcutIds.toggleInfoPanel,
    ViewerCommand.favorite: ShortcutIds.toggleFavorite,
    ViewerCommand.copyPrompt: ShortcutIds.copyPrompt,
    ViewerCommand.reuse: ShortcutIds.reuseGalleryParams,
    ViewerCommand.delete: ShortcutIds.deleteImage,
  };
  if (!config.enableShortcuts) {
    return {for (final command in ViewerCommand.values) command: []};
  }
  final result = <ViewerCommand, List<SingleActivator>>{};
  for (final entry in ids.entries) {
    final binding = config.bindings[entry.value];
    if (binding == null) continue;
    final parsed = AppShortcutManager.parseActivator(binding.effectiveShortcut);
    if (parsed is! LogicalKeySet) {
      result[entry.key] = [];
      continue;
    }
    final keys = parsed.keys;
    final trigger = keys
        .where(
          (key) => !{
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.meta,
          }.contains(key),
        )
        .firstOrNull;
    result[entry.key] = trigger == null
        ? []
        : [
            SingleActivator(
              trigger,
              control: keys.contains(LogicalKeyboardKey.control),
              alt: keys.contains(LogicalKeyboardKey.alt),
              shift: keys.contains(LogicalKeyboardKey.shift),
              meta: keys.contains(LogicalKeyboardKey.meta),
            ),
          ];
  }
  return result;
}
