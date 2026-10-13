import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/cache/thumbnail_cache_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../core/utils/window_focus_tracker.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/services/thumbnail_service.dart';
import '../providers/collection_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/local_gallery_focus_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../providers/share_image_settings_provider.dart';
import '../providers/shortcuts_provider.dart';
import '../router/app_router.dart';
import '../ui/viewer/viewer_contract.dart';
import '../ui/viewer/viewer_page.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/image_detail/components/detail_prompt_translation.dart';
import '../widgets/common/image_detail/file_image_detail_data.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import '../widgets/common/save_vibe_dialog.dart';
import '../widgets/common/themed_input_dialog.dart';
import '../widgets/navigation/integrated_title_bar.dart';
import 'image_viewer_actions.dart';
import 'image_viewer_backend.dart';
import 'image_viewer_gallery.dart';
import 'image_viewer_mapping.dart';
import 'image_viewer_platform.dart';
import 'image_viewer_session.dart';

class ImageViewerHost extends ConsumerWidget {
  const ImageViewerHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(imageViewerSessionProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: session != null,
          child: TickerMode(enabled: session == null, child: child),
        ),
        if (session != null)
          ImageViewerWiring(key: ObjectKey(session), session: session),
      ],
    );
  }
}

class ImageViewerWiring extends ConsumerStatefulWidget {
  const ImageViewerWiring({super.key, required this.session});
  final ImageViewerSession session;

  @override
  ConsumerState<ImageViewerWiring> createState() => _ImageViewerWiringState();
}

class _ImageViewerWiringState extends ConsumerState<ImageViewerWiring> {
  ImageViewerBackend get backend => widget.session.backend;
  late final ImageViewerPlatform _platform;
  late final ImageViewerWindow _window;
  late final ProviderContainer _container;
  final _media = <String, ViewerItem>{};
  final _mediaLoading = <String>{};
  final _translations = <ViewerPart, ViewerTranslation>{};
  final _translationTokens = <ViewerPart, Object>{};
  final _actionsPending = <String>{};
  String? _selection;
  List<ViewerCollection>? _collections;
  int _collectionRequest = 0;
  bool _infoTouched = false;
  bool _zoomTouched = false;
  bool _infoOpen = true;
  bool _zoomHintSeen = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _platform = ref.read(imageViewerPlatformProvider);
    _window = ImageViewerWindow(_platform);
    backend.addListener(_changed);
    unawaited(
      _run(() async {
        final preferences = await _platform.preferences();
        if (mounted && !_closing) {
          setState(() {
            if (!_infoTouched) {
              _infoOpen = preferences.infoOpen;
            }
            if (!_zoomTouched) {
              _zoomHintSeen = preferences.zoomHintSeen;
            }
          });
        }
      }),
    );
    unawaited(_run(backend.initialize));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      AppLogger.w(
        'Viewer operation failed (${error.runtimeType})\n$stack',
        'ImageViewer',
      );
      if (mounted && !_closing) {
        AppToast.error(
          context,
          context.l10n.gallery_sendFailed(error.toString()),
        );
      }
    }
  }

  void _changed() {
    if (!mounted || _closing) {
      return;
    }
    if (_selection != backend.currentKey) {
      _selection = backend.currentKey;
      _translations.clear();
      _translationTokens.clear();
      _collections = null;
      _collectionRequest++;
      if (widget.session.mode == ViewerMode.gallery && _selection != null) {
        unawaited(_run(_refreshCollections));
      }
    }
    setState(() {});
    for (final source in backend.sources) {
      if (_media.containsKey(source.identifier) ||
          !_mediaLoading.add(source.identifier)) {
        continue;
      }
      unawaited(_run(() => _loadMedia(source)));
    }
  }

  Future<void> _loadMedia(ImageDetailData source) async {
    final key = source.identifier;
    try {
      final path = viewerSourcePath(source);
      final dimensions = widget.session.dimensions[key];
      final metadata = source.metadata;
      final memorySize = source is GeneratedImageDetailData
          ? NaiResolutionAdapter.readImageSize(source.imageBytes)
          : null;
      var width = memorySize?.$1 ?? dimensions?.width ?? metadata?.width ?? 0;
      var height =
          memorySize?.$2 ?? dimensions?.height ?? metadata?.height ?? 0;
      final missing = path != null && !await File(path).exists();
      if (!mounted || _closing) {
        return;
      }
      final screen = MediaQuery.sizeOf(context);
      final ratio = MediaQuery.devicePixelRatioOf(context);
      final image = missing
          ? null
          : path == null
          ? source.getImageProvider()
          : ResizeImage(
              FileImage(File(path)),
              width: math.max(1, (screen.width * ratio * 2).ceil()),
              height: math.max(1, (screen.height * ratio * 2).ceil()),
              policy: ResizeImagePolicy.fit,
            );
      final stat = path == null || missing ? null : await File(path).stat();
      if (!mounted || _closing) {
        return;
      }
      _media[key] = ViewerItem(
        key: key,
        width: width,
        height: height,
        image: image,
        thumb: path == null ? source.getImageProvider() : null,
        missing: missing,
        saved:
            widget.session.mode == ViewerMode.generation &&
            path != null &&
            !missing,
        path: path,
        date:
            widget.session.dates[key] ??
            source.groupDate?.toLocal() ??
            stat?.modified.toLocal(),
        sizeBytes: stat?.size,
      );
      setState(() {});
      if (path != null && !missing) {
        final service = ThumbnailService.instance;
        await service.initialize();
        final thumbnail = await service.getThumbnail(
          path,
          size: ThumbnailSize.micro,
        );
        if (!mounted || _closing || thumbnail == null) {
          return;
        }
        if (width <= 0 || height <= 0) {
          final size = NaiResolutionAdapter.readImageSize(
            await File(thumbnail).readAsBytes(),
          );
          width =
              size?.$1 ??
              math.max(1, ((source.aspectRatio ?? 1) * 100).round());
          height = size?.$2 ?? 100;
        }
        if (!mounted || _closing) {
          return;
        }
        final current = _media[key]!;
        _media[key] = ViewerItem(
          key: key,
          width: width,
          height: height,
          image: current.image,
          thumb: FileImage(File(thumbnail)),
          missing: current.missing,
          saved: current.saved,
          path: path,
          date: current.date,
          sizeBytes: current.sizeBytes,
        );
        setState(() {});
      }
    } finally {
      _mediaLoading.remove(key);
    }
  }

  Future<void> _refreshCollections() async {
    final key = backend.currentKey;
    if (key == null || !mounted) {
      return;
    }
    final request = ++_collectionRequest;
    final collections = await ref
        .read(imageViewerGalleryProvider)
        .collections(key);
    if (mounted && request == _collectionRequest && key == backend.currentKey) {
      setState(() => _collections = collections);
    }
  }

  Future<void> _close({bool keyboard = false}) async {
    if (_closing || !mounted) {
      return;
    }
    if (keyboard &&
        Platform.isWindows &&
        (WindowFocusTracker.isWithinCooldown(
              const Duration(milliseconds: 1200),
            ) ||
            WindowFocusTracker.hadRecentFocusBounce(
              maxSinceFocus: const Duration(seconds: 4),
            ))) {
      return;
    }
    _closing = true;
    try {
      await _window.restore();
    } catch (_) {
      _closing = false;
      rethrow;
    }
    if (_container.read(imageViewerSessionProvider) != widget.session) {
      return;
    }
    if (widget.session.mode == ViewerMode.gallery &&
        backend.currentKey != null) {
      _container
          .read(localGalleryFocusNotifierProvider.notifier)
          .focus(backend.currentKey!);
    }
    _container.read(imageViewerWindowProvider.notifier).state = (
      fullscreen: false,
      captionOverStage: false,
    );
    _container.read(imageViewerSessionProvider.notifier).state = null;
    if (!widget.session.done.isCompleted) {
      widget.session.done.complete();
    }
  }

  Future<void> _action(String key, ViewerAction action) async {
    if (_closing ||
        key != backend.currentKey ||
        !_actionsPending.add('$key:${action.name}')) {
      return;
    }
    try {
      final source = backend.current;
      if (source == null || !source.showCopyButton) {
        return;
      }
      if (action == ViewerAction.save) {
        if (widget.session.save != null && source.showSaveButton) {
          await widget.session.save!(source);
        }
        if (mounted) {
          _media.remove(key);
          _changed();
        }
        return;
      }
      final savedPath = widget.session.mode == ViewerMode.generation
          ? ref
                .read(imageGenerationNotifierProvider)
                .mergedPanelImages
                .where((image) => image.id == key)
                .firstOrNull
                ?.filePath
          : null;
      final actionSource = savedPath == null
          ? source
          : FileImageDetailData(
              filePath: savedPath,
              id: key,
              cachedBytes: source is GeneratedImageDetailData
                  ? source.imageBytes
                  : null,
              initialMetadata: backend.metadata,
            );
      final router = GoRouter.of(context);
      final navigate = await ImageViewerActionHost(
        context,
        ref,
        () => mounted && !_closing && backend.currentKey == key,
      ).perform(actionSource, action, backend.metadata);
      if (!mounted || _closing) {
        return;
      }
      if (navigate) {
        await _close();
        router.go(AppRoutes.home);
      } else if (action == ViewerAction.moveTo ||
          action == ViewerAction.copyTo) {
        _media.remove(key);
        _changed();
      }
    } finally {
      _actionsPending.remove('$key:${action.name}');
    }
  }

  Future<void> _translate(String key, ViewerPart part) async {
    if (key != backend.currentKey ||
        backend.metadataLoading ||
        part.kind == ViewerPartKind.seed ||
        _translations[part]?.busy == true) {
      return;
    }
    if (_translations[part]?.text != null) {
      _translationTokens.remove(part);
      setState(() => _translations.remove(part));
      return;
    }
    final text = viewerPartText(backend.metadata, part);
    if (text == null || text.isEmpty) {
      return;
    }
    final token = Object();
    _translationTokens[part] = token;
    setState(() => _translations[part] = const ViewerTranslation(busy: true));
    try {
      final result = await ref.read(detailPromptTranslatorProvider)(
        PillDocument(text: text, instances: const {}),
        'viewer-$key-$part-${identityHashCode(token)}',
      );
      if (mounted &&
          key == backend.currentKey &&
          identical(_translationTokens[part], token)) {
        setState(
          () => _translations[part] = ViewerTranslation(
            text: viewerTranslationText(result),
          ),
        );
      }
    } catch (error) {
      if (mounted &&
          key == backend.currentKey &&
          identical(_translationTokens[part], token)) {
        setState(
          () =>
              _translations[part] = ViewerTranslation(error: error.toString()),
        );
      }
    }
  }

  Future<void> _copy(String key, ViewerPart part) async {
    if (key != backend.currentKey) {
      return;
    }
    final text = viewerPartText(backend.metadata, part);
    if (text == null || text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppToast.success(
        context,
        part.kind == ViewerPartKind.seed
            ? context.l10n.localGallery_seedCopied
            : context.l10n.localGallery_promptCopied,
      );
    }
  }

  Future<void> _createCollection(String key) async {
    final name = await ThemedInputDialog.show(
      context: context,
      title: context.l10n.localGallery_createCollectionTitle,
    );
    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }
    final collection = await ref
        .read(collectionNotifierProvider.notifier)
        .createCollection(name.trim());
    if (collection == null) {
      throw StateError(
        ref.read(collectionNotifierProvider).error ??
            'Collection creation failed',
      );
    }
    await ref
        .read(imageViewerGalleryProvider)
        .setCollection(key, collection.id, true);
    if (mounted) {
      await _refreshCollections();
    }
  }

  Future<void> _setFullscreen(bool value) async {
    await _window.change(value);
    if (mounted && !_closing) {
      ref.read(imageViewerWindowProvider.notifier).state = (
        fullscreen: value,
        captionOverStage: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final window = ref.watch(imageViewerWindowProvider);
    final settings = ref.watch(shareImageSettingsProvider);
    final highlight = ref.watch(highlightEmphasisSettingsProvider);
    final shortcuts = ref.watch(shortcutConfigNotifierProvider);
    final krita =
        ref.watch(kritaBridgeNotifierProvider).status ==
        KritaBridgeStatus.connected;
    if (widget.session.mode == ViewerMode.gallery) {
      ref.watch(localGalleryNotifierProvider);
    }
    final generated = widget.session.mode == ViewerMode.generation
        ? ref.watch(imageGenerationNotifierProvider).mergedPanelImages
        : <GeneratedImage>[];
    final saved = {
      for (final image in generated)
        if (image.filePath != null && image.filePath!.isNotEmpty)
          image.id: image.filePath!,
    };
    final key = backend.currentKey ?? '';
    final items = [
      for (final source in backend.sources)
        _item(source, saved, settings.effectiveConfirmDangerousActions),
    ];
    final current = backend.current;
    final path =
        saved[key] ?? (current == null ? null : viewerSourcePath(current));
    final actions = <ViewerAction>{};
    if (current?.showCopyButton == true) {
      actions.addAll(
        widget.session.mode == ViewerMode.gallery
            ? ViewerAction.values.where((action) => action != ViewerAction.save)
            : {
                ViewerAction.copyImage,
                ViewerAction.saveAsBlock,
                ViewerAction.reuse,
                ViewerAction.img2img,
                ViewerAction.preciseRef,
                ViewerAction.upscale,
                ViewerAction.copyAllPrompts,
              },
      );
      if (widget.session.mode == ViewerMode.generation &&
          (current!.showSaveButton || path != null)) {
        actions.add(ViewerAction.save);
      }
      if (path == null) {
        actions.removeAll({
          ViewerAction.showInFolder,
          ViewerAction.moveTo,
          ViewerAction.copyTo,
          ViewerAction.copyPath,
        });
      } else {
        actions.addAll({
          ViewerAction.showInFolder,
          ViewerAction.moveTo,
          ViewerAction.copyTo,
          ViewerAction.copyPath,
        });
      }
    }
    final data = ViewerViewData(
      mode: widget.session.mode,
      items: items,
      currentKey: key,
      now: DateTime.now(),
      position: backend.position,
      total: backend.total,
      scope: widget.session.scope,
      detail: viewerDetailOf(
        key,
        backend.metadata,
        path: path,
        loading: backend.metadataLoading,
      ),
      actions: actions,
      infoOpen: _infoOpen,
      fullscreen: window.fullscreen,
      kritaConnected: krita,
      highlight: highlight,
      collections: _collections,
      translations: Map.unmodifiable(_translations),
      undo: backend.undoId == null
          ? null
          : ViewerUndo(
              id: backend.undoId!,
              fileName: p.basename(backend.undoKey!),
            ),
      keys: shortcuts.valueOrNull == null
          ? ViewerKeys.defaults
          : viewerKeysOf(shortcuts.requireValue),
      zoomHintSeen: _zoomHintSeen,
    );
    final galleryBackend = ref.read(imageViewerGalleryProvider);
    return Material(
      type: MaterialType.transparency,
      child: WindowChromePage(
        captionHeight: 61,
        hideCaptions: window.fullscreen,
        captionTheme: window.captionOverStage
            ? Theme.of(context).copyWith(
                brightness: Brightness.dark,
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  brightness: Brightness.dark,
                  surface: const Color(0xff0b0b0b),
                  onSurface: Colors.white,
                ),
              )
            : null,
        showAccessory: false,
        child: ImageViewerPage(
          data: data,
          actions: ViewerActions(
            onClose: ({required keyboard}) =>
                unawaited(_run(() => _close(keyboard: keyboard))),
            onSelect: (key) => unawaited(_run(() => backend.select(key))),
            onStep: (delta) => unawaited(_run(() => backend.step(delta))),
            onJump: ({required last}) =>
                unawaited(_run(() => backend.jump(last: last))),
            onLoadMore: ({required forward}) =>
                unawaited(_run(() => backend.loadMore(forward: forward))),
            onInfoChanged: (value) {
              if (!mounted || _closing) {
                return;
              }
              _infoTouched = true;
              setState(() => _infoOpen = value);
              unawaited(
                _run(() => _platform.setPreference('viewer_info_open', value)),
              );
            },
            onFullscreenChanged: (value) =>
                unawaited(_run(() => _setFullscreen(value))),
            onSetFavorite: (key, value) => unawaited(
              _run(() async {
                await galleryBackend.setFavorite(key, value);
                if (mounted) {
                  setState(() {});
                  await _refreshCollections();
                }
              }),
            ),
            onToggleCollection: (key, id, member) => unawaited(
              _run(() async {
                await galleryBackend.setCollection(key, id, member);
                if (mounted) {
                  await _refreshCollections();
                }
              }),
            ),
            onCreateCollection: (key) =>
                unawaited(_run(() => _createCollection(key))),
            onDelete: (key) => unawaited(
              _run(() async {
                await backend.delete(key);
                if (backend.total == 0 && mounted) {
                  await _close();
                }
              }),
            ),
            onUndoDelete: () => unawaited(_run(backend.undoDelete)),
            onDismissUndo: backend.dismissUndo,
            onAction: (key, action) =>
                unawaited(_run(() => _action(key, action))),
            onCopy: (key, part) => unawaited(_run(() => _copy(key, part))),
            onToggleTranslation: (key, part) =>
                unawaited(_run(() => _translate(key, part))),
            onSaveVibe: (key, index) => unawaited(
              _run(() async {
                final vibes = backend.metadata?.vibeReferences;
                if (key != backend.currentKey ||
                    vibes == null ||
                    index < 0 ||
                    index >= vibes.length) {
                  return;
                }
                await SaveVibeDialog.show(context, vibe: vibes[index]);
              }),
            ),
            onZoomHintSeen: () {
              if (!mounted || _closing) {
                return;
              }
              _zoomTouched = true;
              setState(() => _zoomHintSeen = true);
              unawaited(
                _run(
                  () => _platform.setPreference('viewer_zoom_hint_seen', true),
                ),
              );
            },
            onCaptionOverStage: (value) {
              if (mounted && !_closing) {
                final latest = ref.read(imageViewerWindowProvider);
                ref.read(imageViewerWindowProvider.notifier).state = (
                  fullscreen: latest.fullscreen,
                  captionOverStage: latest.fullscreen ? false : value,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  ViewerItem _item(
    ImageDetailData source,
    Map<String, String> saved,
    bool protected,
  ) {
    final key = source.identifier;
    final media = _media[key];
    final dimensions = widget.session.dimensions[key];
    final metadata = key == backend.currentKey
        ? backend.metadata
        : source.metadata;
    final favorite = widget.session.mode == ViewerMode.gallery
        ? ref
                  .read(localGalleryNotifierProvider.notifier)
                  .cachedRecord(key)
                  ?.isFavorite ??
              source.isFavorite
        : false;
    return ViewerItem(
      key: key,
      width: media != null && media.width > 0
          ? media.width
          : dimensions?.width ?? metadata?.width ?? 0,
      height: media != null && media.height > 0
          ? media.height
          : dimensions?.height ?? metadata?.height ?? 0,
      image: media?.image,
      thumb: media?.thumb,
      date: widget.session.dates[key] ?? media?.date,
      favorite: favorite,
      protected: protected,
      saved: saved.containsKey(key) || media?.saved == true,
      missing: media?.missing ?? false,
      path: saved[key] ?? media?.path ?? viewerSourcePath(source),
      sizeBytes: media?.sizeBytes,
    );
  }

  @override
  void dispose() {
    backend.removeListener(_changed);
    backend.dispose();
    _translationTokens.clear();
    unawaited(
      _window.restore().catchError((Object error) {
        AppLogger.w('Viewer window restoration failed: $error', 'ImageViewer');
      }),
    );
    if (!widget.session.done.isCompleted) {
      widget.session.done.complete();
    }
    super.dispose();
  }
}
