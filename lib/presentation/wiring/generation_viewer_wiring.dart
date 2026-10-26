import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'generation_viewer_window.dart';

import '../../core/constants/api_constants.dart';
import '../../core/shortcuts/default_shortcuts.dart';
import '../../core/shortcuts/shortcut_config.dart';
import '../../core/shortcuts/shortcut_manager.dart';
import '../providers/shortcuts_provider.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/services/image_metadata_service.dart';
import '../providers/image_generation_provider.dart';
import '../providers/prompt_translation_provider.dart';
import 'blocks_edit_wiring.dart';
import '../screens/generation/handlers/vibe_import_handler.dart';
import '../ui/gen/gen_contract.dart';
import '../widgets/navigation/integrated_title_bar.dart';
import '../ui/viewer/viewer_contract.dart';
import '../ui/viewer/viewer_page.dart';
import '../utils/precise_ref_library_import_helper.dart';
import 'generation_history_actions.dart';
import 'generation_operations.dart';

final generationViewerWindowProvider =
    StateProvider<({bool fullscreen, bool captionOverStage})>(
      (ref) => (fullscreen: false, captionOverStage: false),
    );

final generationViewerOwnerProvider = StateProvider<Object?>((ref) => null);

Map<ViewerCommand, List<SingleActivator>> generationViewerKeys(
  ShortcutConfig config,
) {
  if (!config.enableShortcuts) {
    return {for (final command in ViewerCommand.values) command: []};
  }
  const ids = {
    ViewerCommand.previous: ShortcutIds.previousImage,
    ViewerCommand.next: ShortcutIds.nextImage,
    ViewerCommand.zoomIn: ShortcutIds.zoomIn,
    ViewerCommand.zoomOut: ShortcutIds.zoomOut,
    ViewerCommand.zoomFit: ShortcutIds.resetZoom,
    ViewerCommand.fullscreen: ShortcutIds.toggleFullscreen,
    ViewerCommand.close: ShortcutIds.closeViewer,
    ViewerCommand.toggleInfo: ShortcutIds.toggleInfoPanel,
    ViewerCommand.copyPrompt: ShortcutIds.copyPrompt,
    ViewerCommand.reuse: ShortcutIds.reuseGalleryParams,
    ViewerCommand.favorite: ShortcutIds.toggleFavorite,
    ViewerCommand.delete: ShortcutIds.deleteImage,
    ViewerCommand.save: ShortcutIds.saveImage,
  };
  final result = {...ViewerKeys.defaults};
  for (final entry in ids.entries) {
    final binding = config.bindings[entry.value];
    if (binding == null) continue;
    final parsed = AppShortcutManager.parseActivator(binding.effectiveShortcut);
    if (parsed is! LogicalKeySet ||
        binding.context != ShortcutContext.viewer &&
            binding.context != ShortcutContext.generation &&
            binding.context != ShortcutContext.global) {
      result[entry.key] = [];
      continue;
    }
    final keys = parsed.keys;
    final trigger = keys
        .where(
          (key) => !{
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.alt,
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
              shift: keys.contains(LogicalKeyboardKey.shift),
              alt: keys.contains(LogicalKeyboardKey.alt),
              meta: keys.contains(LogicalKeyboardKey.meta),
            ),
          ];
  }
  return result;
}

class GenerationViewerRequest {
  GenerationViewerRequest(List<GeneratedImage> images, this.selected)
    : images = List.unmodifiable(images);
  final List<GeneratedImage> images;
  final String selected;
}

ViewerDetail generationViewerDetail(
  String id,
  NaiImageMetadata? source, {
  bool loading = false,
}) {
  final metadata = source?.upgradeFromRawJsonIfNeeded();
  return ViewerDetail(
    key: id,
    status: loading
        ? ViewerMetaStatus.loading
        : metadata?.hasData == true
        ? ViewerMetaStatus.ready
        : ViewerMetaStatus.none,
    model:
        ImageModels.modelDisplayNames[metadata?.effectiveModel] ??
        metadata?.effectiveModel,
    sampler:
        Samplers.samplerDisplayNames[metadata?.sampler] ?? metadata?.sampler,
    seed: metadata?.seed,
    steps: metadata?.steps,
    scale: metadata?.scale,
    cfgRescale: metadata?.cfgRescale,
    noiseSchedule: metadata?.noiseSchedule,
    qualityTags: metadata?.qualityToggle,
    prompt: metadata?.prompt ?? '',
    negative: metadata?.negativePrompt ?? '',
    preciseCount: metadata?.preciseReferenceImages.length ?? 0,
    characters: [
      for (final character
          in metadata?.characterInfos ?? <CharacterPromptInfo>[])
        ViewerCharacter(
          prompt: character.prompt,
          negative: character.negativePrompt ?? '',
          x: character.centerX,
          y: character.centerY,
        ),
    ],
    vibes: [
      for (final vibe in metadata?.vibeReferences ?? [])
        ViewerVibe(
          name: vibe.displayName,
          thumb: vibe.thumbnail == null ? null : MemoryImage(vibe.thumbnail!),
          strength: vibe.strength,
          infoExtracted: vibe.infoExtracted,
        ),
    ],
  );
}

class GenerationViewerWiring extends ConsumerStatefulWidget {
  const GenerationViewerWiring({super.key, required this.request});
  final GenerationViewerRequest request;
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    List<GeneratedImage> images,
    String id,
  ) async {
    final grouped = ref
        .read(imageGenerationNotifierProvider)
        .detailSequenceFor(images.firstWhere((image) => image.id == id));
    await context.push<void>(
      '/generation/viewer',
      extra: GenerationViewerRequest(
        grouped.any((image) => image.id == id) ? grouped : images,
        id,
      ),
    );
  }

  @override
  ConsumerState<GenerationViewerWiring> createState() =>
      _GenerationViewerWiringState();
}

class _GenerationViewerWiringState
    extends ConsumerState<GenerationViewerWiring> {
  late final List<GeneratedImage> _images;
  late String current;
  final metadata = <String, NaiImageMetadata?>{};
  final loading = <String>{};
  final translations = <ViewerPart, ViewerTranslation>{};
  final translationRequests = <ViewerPart, Object>{};
  bool info = true;
  bool hint = false;
  bool fullscreen = false;
  late GenerationViewerWindow window;
  late StateController<({bool fullscreen, bool captionOverStage})> chrome;
  late StateController<Object?> owner;
  final identity = Object();
  int revision = 0;
  GenerationOperations get operations =>
      GenerationOperations(ref, context, () => mounted);
  @override
  void initState() {
    super.initState();
    _images = List.of(widget.request.images);
    current = widget.request.selected;
    window = GenerationViewerWindow(ref.read(generationViewerPlatformProvider));
    chrome = ref.read(generationViewerWindowProvider.notifier);
    owner = ref.read(generationViewerOwnerProvider.notifier);
    final storage = ref.read(localStorageServiceProvider);
    info =
        storage.getSetting<bool>('viewer_info_open', defaultValue: true) ??
        true;
    hint =
        storage.getSetting<bool>(
          'viewer_zoom_hint_seen',
          defaultValue: false,
        ) ??
        false;
    for (final image in _images) {
      if (image.metadata != null) metadata[image.id] = image.metadata;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      owner.state = identity;
      operations.run(load);
    });
  }

  Future<void> load() async {
    final id = current;
    if (metadata.containsKey(id) || loading.contains(id)) return;
    loading.add(id);
    final image = _images.firstWhere((image) => image.id == id);
    final value =
        image.metadata ??
        await ImageMetadataService().getMetadataFromBytes(image.bytes);
    if (!mounted) return;
    setState(() {
      metadata[id] = value;
      loading.remove(id);
    });
  }

  void select(String id) {
    if (!_images.any((image) => image.id == id)) return;
    setState(() {
      current = id;
      revision++;
      translations.clear();
      translationRequests.clear();
    });
    unawaited(load());
  }

  Future<void> setFullscreen(bool value) async {
    await window.change(value);
    if (!mounted || window.closed || !identical(owner.state, identity)) return;
    chrome.state = (fullscreen: value, captionOverStage: false);
    setState(() => fullscreen = value);
  }

  Future<void> restore() async {
    await window.restore();
    if (owner.mounted && chrome.mounted && identical(owner.state, identity)) {
      chrome.state = (fullscreen: false, captionOverStage: false);
      owner.state = null;
    }
  }

  @override
  void dispose() {
    unawaited(restore().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> close() async {
    await restore();
    if (mounted) context.pop();
  }

  Future<void> delete(String id) async {
    await ref.read(generationHistoryActionsProvider).delete([id]);
    if (!mounted) return;
    final index = _images.indexWhere((image) => image.id == id);
    if (index < 0) return;
    if (_images.length == 1) {
      await close();
      return;
    }
    setState(() => _images.removeAt(index));
    if (current == id) {
      select(_images[index.clamp(0, _images.length - 1)].id);
    }
  }

  String partText(String id, ViewerPart part) {
    final detail = generationViewerDetail(id, metadata[id]);
    return switch (part.kind) {
      ViewerPartKind.prompt => detail.prompt,
      ViewerPartKind.negative => detail.negative,
      ViewerPartKind.seed => detail.seed?.toString() ?? '',
      ViewerPartKind.character =>
        detail.characters.elementAtOrNull(part.index)?.prompt ?? '',
    };
  }

  Future<void> translate(String id, ViewerPart part) async {
    if (!mounted || id != current) return;
    if (translations.containsKey(part)) {
      setState(() {
        translations.remove(part);
        translationRequests.remove(part);
      });
      return;
    }
    final version = revision;
    final pending = Object();
    setState(() {
      translations[part] = const ViewerTranslation(busy: true);
      translationRequests[part] = pending;
    });
    bool valid() =>
        mounted &&
        id == current &&
        version == revision &&
        identical(translationRequests[part], pending);
    late final PillDocument value;
    try {
      value = await ref
          .read(promptTranslationCoordinatorProvider)
          .translateDocument(
            PillDocument(text: partText(id, part), instances: const {}),
            sessionId: 'generation-viewer-$id',
          );
    } catch (_) {
      if (!valid()) return;
      setState(() {
        translations.remove(part);
        translationRequests.remove(part);
      });
      rethrow;
    }
    if (!valid()) return;
    translationRequests.remove(part);
    setState(
      () => translations[part] = ViewerTranslation(
        text: value.text
            .split('')
            .map(
              (character) =>
                  value.instances[character]?.translation?.zh ?? character,
            )
            .join(),
      ),
    );
  }

  Future<void> action(String id, ViewerAction action) async {
    final op = operations;
    switch (action) {
      case ViewerAction.save:
        await op.saveImages([id]);
      case ViewerAction.img2img:
        await op.sendTo([id], GenSendTarget.img2img);
      case ViewerAction.styleTransfer:
        await op.sendTo([id], GenSendTarget.vibe);
      case ViewerAction.preciseRef:
        await op.sendTo([id], GenSendTarget.precise);
      case ViewerAction.upscale:
        await op.upscale(id);
      case ViewerAction.copyImage:
        await op.copyImage(id);
      case ViewerAction.copyPath:
        await Clipboard.setData(
          ClipboardData(
            text:
                ref.read(generationHistoryActionsProvider).image(id).filePath ??
                '',
          ),
        );
      case ViewerAction.copyAllPrompts:
        await Clipboard.setData(
          ClipboardData(text: metadata[id]?.fullPrompt ?? ''),
        );
      case ViewerAction.showInFolder:
        await op.reveal(id);
      case ViewerAction.saveToRefLibrary:
        await saveBytesToPreciseRefLibrary(
          ref,
          context,
          ref.read(generationHistoryActionsProvider).image(id).bytes,
        );
      case ViewerAction.saveAsBlock:
        await BlocksEditWiring.createWithDialog(
          context,
          ref,
          initialContent: metadata[id]?.fullPrompt,
          initialImageBytes: ref
              .read(generationHistoryActionsProvider)
              .image(id)
              .bytes,
        );
      case ViewerAction.reuse:
        await op.reuse(id, selected: () => current == id && !window.closed);
      case ViewerAction.krita || ViewerAction.moveTo || ViewerAction.copyTo:
        throw UnsupportedError(currentL10n.bridge_conflict);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sequence = _images;
    final index = sequence.indexWhere((image) => image.id == current);
    final history = ref.watch(imageGenerationNotifierProvider);
    final latest = {
      for (final image in [
        ...sequence,
        ...history.mergedPanelImages,
        ...history.displayImages,
      ])
        image.id: image,
    };
    final op = operations;
    void run(Future<void> Function() task) => op.run(task);
    final chrome = ref.watch(generationViewerWindowProvider);
    return WindowChromePage(
      hidden: fullscreen,
      captionTheme: chrome.captionOverStage ? ThemeData.dark() : null,
      child: ImageViewerPage(
        data: ViewerViewData(
          mode: ViewerMode.generation,
          currentKey: current,
          position: index,
          total: sequence.length,
          now: DateTime.now(),
          infoOpen: info,
          zoomHintSeen: hint,
          fullscreen: fullscreen,
          translations: translations,
          highlight: ref.watch(highlightEmphasisSettingsProvider),
          keys: generationViewerKeys(
            ref.watch(shortcutConfigNotifierProvider).valueOrNull ??
                ShortcutConfig.createDefault(),
          ),
          items: [
            for (final original in sequence)
              ViewerItem(
                key: original.id,
                width: original.width,
                height: original.height,
                thumb: ResizeImage(MemoryImage(original.bytes), width: 240),
                image: MemoryImage(original.bytes),
                date: original.createdAt.toLocal(),
                saved: latest[original.id]?.filePath != null,
                path: latest[original.id]?.filePath,
                sizeBytes: original.bytes.length,
              ),
          ],
          detail: generationViewerDetail(
            current,
            metadata[current],
            loading: !metadata.containsKey(current),
          ),
          actions: {
            ViewerAction.save,
            ViewerAction.img2img,
            ViewerAction.styleTransfer,
            ViewerAction.preciseRef,
            ViewerAction.upscale,
            ViewerAction.copyImage,
            ViewerAction.copyAllPrompts,
            ViewerAction.saveToRefLibrary,
            ViewerAction.saveAsBlock,
            ViewerAction.showInFolder,
            if (metadata[current]?.hasData == true) ViewerAction.reuse,
            if (latest[current]?.filePath != null) ViewerAction.copyPath,
          },
        ),
        actions: ViewerActions(
          onClose: ({required keyboard}) => run(close),
          onSelect: select,
          onStep: (delta) => select(
            sequence[(index + delta).clamp(0, sequence.length - 1)].id,
          ),
          onJump: ({required last}) =>
              select(last ? sequence.last.id : sequence.first.id),
          onLoadMore: ({required forward}) {
            final next = index + (forward ? 1 : -1);
            if (next >= 0 && next < sequence.length) select(sequence[next].id);
          },
          onInfoChanged: (value) {
            setState(() => info = value);
            run(
              () => ref
                  .read(localStorageServiceProvider)
                  .setSetting('viewer_info_open', value),
            );
          },
          onFullscreenChanged: (value) => run(() => setFullscreen(value)),
          onSetFavorite: (id, value) => run(() => op.favorite(id, value)),
          onToggleCollection: (id, collection, member) => run(() async {
            throw UnsupportedError(context.l10n.bridge_conflict);
          }),
          onCreateCollection: (id) => run(() async {
            throw UnsupportedError(context.l10n.bridge_conflict);
          }),
          onDelete: (id) => run(() => delete(id)),
          onUndoDelete: () => run(() async {
            throw UnsupportedError(context.l10n.bridge_conflict);
          }),
          onDismissUndo: () {},
          onAction: (id, value) => run(() => action(id, value)),
          onCopy: (id, part) => run(
            () => Clipboard.setData(ClipboardData(text: partText(id, part))),
          ),
          onToggleTranslation: (id, part) => run(() => translate(id, part)),
          onSaveVibe: (id, index) => run(() async {
            final vibes = metadata[id]?.vibeReferences ?? [];
            if (index >= 0 && index < vibes.length) {
              await VibeImportHandler(
                context: context,
                ref: ref,
              ).saveToLibrary([vibes[index]]);
            }
          }),
          onZoomHintSeen: () {
            setState(() => hint = true);
            run(
              () => ref
                  .read(localStorageServiceProvider)
                  .setSetting('viewer_zoom_hint_seen', true),
            );
          },
          onCaptionOverStage: (value) =>
              ref.read(generationViewerWindowProvider.notifier).state = (
                fullscreen: fullscreen,
                captionOverStage: !fullscreen && value,
              ),
        ),
      ),
    );
  }
}
