import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/services/resource_window_protocol.dart';
import '../../core/services/resource_window_host.dart';
import '../../core/constants/model_spec.dart';
import '../../core/services/resource_window_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../../data/services/gallery/unified_gallery_service.dart';
import 'blocks_preferences.dart';
import '../providers/collection_provider.dart';
import '../providers/floating_resource_windows_provider.dart';
import '../providers/font_provider.dart';
import '../providers/gallery_category_provider.dart';
import '../providers/gallery_scan_progress_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/pill_workspace_provider.dart' show PillScopes;
import '../providers/share_image_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/vibe_library_category_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../router/app_router.dart';
import '../ui/viewer/viewer_contract.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import '../utils/local_gallery_metadata_resolver.dart';
import 'blocks_actions.dart';
import 'image_viewer_actions.dart';
import 'image_viewer_backend.dart';
import 'image_viewer_session.dart';
import 'refs_entry_drop_target.dart';
import 'refs_preferences.dart';
import 'floating_resource_drag.dart';
import '../ui/refs/refs_contract.dart';
import 'resource_window_backend.dart';

final nativeResourceWindowsProvider = Provider<bool>(
  (ref) => Platform.isWindows,
);
final resourceWindowServiceProvider = Provider(
  (ref) => ResourceWindowService.instance,
);
final resourceWindowOpenerProvider = Provider(ResourceWindowOpener.new);
final resourceRefsEditRequestProvider =
    StateProvider<({FloatingResourceKind kind, String id})?>((ref) => null);

class ResourceWindowOpener {
  ResourceWindowOpener(this.ref);
  final Ref ref;
  bool _attached = false;

  void _attach() {
    if (_attached) return;
    _attached = true;
    final service = ref.read(resourceWindowServiceProvider);
    final backend = ref.read(resourceWindowBackendProvider);
    service.host.backend = backend;
    service.onAllClosed = backend.dispose;
    service.onKind = (id, kind) => backend.windowKinds[id] = kind;
    service.onClosed = backend.windowKinds.remove;
    service.argumentsFor = (kind) async {
      final saved = ref
          .read(localStorageServiceProvider)
          .getSetting<Map>('resource_window_${kind.name}_layout');
      return ResourceWindowArguments(
        kind: kind,
        brightness: ref.read(themeNotifierProvider).name,
        locale: ref.read(localeNotifierProvider).toLanguageTag(),
        fontKey: ref.read(fontNotifierProvider).key,
        rect: saved?['rect'] == null
            ? null
            : Map<String, Object?>.from(saved!['rect'] as Map),
        alwaysOnTop: saved?['alwaysOnTop'] as bool? ?? false,
      );
    };
    void watch<T>(ProviderListenable<T> provider, FloatingResourceKind kind) {
      ref.listen(provider, (_, __) => unawaited(service.changed(kind)));
    }

    watch(
      localGalleryNotifierProvider.select((s) => s.contentRevision),
      FloatingResourceKind.gallery,
    );
    ref.listen(galleryServiceProvider, (previous, next) {
      if (!identical(previous, next)) {
        unawaited(service.changed(FloatingResourceKind.gallery));
      }
    });
    ref.listen(galleryScanProgressProvider.select((s) => s.isScanning), (
      previous,
      next,
    ) {
      if (previous == true && !next) {
        unawaited(service.changed(FloatingResourceKind.gallery));
      }
    });
    ref.listen(localGalleryNotifierProvider.select((s) => s.viewMode), (
      _,
      next,
    ) {
      unawaited(service.viewChanged(FloatingResourceKind.gallery, next.name));
    });
    ref.listen(blocksPreferencesProvider.select((s) => s.valueOrNull?.view), (
      _,
      next,
    ) {
      if (next != null) {
        unawaited(service.viewChanged(FloatingResourceKind.blocks, next.name));
      }
    });
    watch(
      galleryCategoryNotifierProvider.select((s) => (s.categories, s.error)),
      FloatingResourceKind.gallery,
    );
    watch(
      blocksPreferencesProvider.select((s) {
        final p = s.valueOrNull;
        return (p?.sort, p?.descending, p?.expanded, p?.recentIds);
      }),
      FloatingResourceKind.blocks,
    );
    watch(
      collectionNotifierProvider.select((s) => (s.collections, s.error)),
      FloatingResourceKind.gallery,
    );
    watch(promptBlockLibraryNotifierProvider, FloatingResourceKind.blocks);
    watch(refsSortChangedProvider(RefsKind.vibe), FloatingResourceKind.vibe);
    watch(
      refsSortChangedProvider(RefsKind.precise),
      FloatingResourceKind.precise,
    );
    watch(
      vibeLibraryNotifierProvider.select((s) => (s.entries, s.error)),
      FloatingResourceKind.vibe,
    );
    watch(
      vibeLibraryCategoryNotifierProvider.select(
        (s) => (s.categories, s.error),
      ),
      FloatingResourceKind.vibe,
    );
    watch(
      preciseRefLibraryNotifierProvider.select((s) => (s.entries, s.error)),
      FloatingResourceKind.precise,
    );
    ref.listen(
      generationParamsNotifierProvider.select(
        (p) => (p.model, p.vibeReferencesV4, p.preciseReferences),
      ),
      (_, __) {
        unawaited(service.changed(FloatingResourceKind.vibe));
        unawaited(service.changed(FloatingResourceKind.precise));
      },
    );
    ref.listen(
      shareImageSettingsProvider,
      (_, __) => unawaited(service.changed(FloatingResourceKind.gallery)),
    );
    ref.onDispose(() {
      service.host.backend = null;
      service.argumentsFor = null;
      service.onAllClosed = null;
      service.onKind = null;
      service.onClosed = null;
      unawaited(backend.dispose());
    });
  }

  Future<void> open(FloatingResourceKind kind, {bool newWindow = false}) async {
    if (!ref.read(nativeResourceWindowsProvider)) {
      ref.read(floatingResourceWindowsProvider.notifier).open(kind);
      return;
    }
    _attach();
    await ref
        .read(resourceWindowServiceProvider)
        .openKind(kind, newWindow: newWindow);
  }
}

/// Non-visual primary-engine callback installation. Reuses action hosts with
/// their confirmation, backup, capability and post-await draft checks intact.
class ResourceWindowBridge extends ConsumerStatefulWidget {
  const ResourceWindowBridge({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ResourceWindowBridge> createState() =>
      _ResourceWindowBridgeState();
}

class _ResourceWindowBridgeState extends ConsumerState<ResourceWindowBridge> {
  late ResourceMainActions _mainActions;
  bool alive() => mounted;
  @override
  void initState() {
    super.initState();
    _mainActions = ref.read(resourceMainActionsProvider);
    _mainActions.perform = perform;
  }

  @override
  void dispose() {
    _mainActions.perform = null;
    super.dispose();
  }

  Future<void> perform(
    FloatingResourceKind kind,
    String id,
    String action,
  ) async {
    if (!mounted) resourceError('not_ready');
    final backend = ref.read(resourceWindowBackendProvider);
    final actionContext = ref
        .read(appRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentState
        ?.overlay
        ?.context;
    if (actionContext == null) resourceError('not_ready');
    // Windows can deny foreground activation while the child owns focus.
    // This must not abort the actual resource operation.
    for (final activate in [windowManager.show, windowManager.focus]) {
      try {
        await activate();
      } on PlatformException {
        // Best effort activation, not a data/action failure.
      }
    }
    if (!mounted || !actionContext.mounted) return;
    if (kind == FloatingResourceKind.gallery) {
      // Read the current record before navigating or changing the draft.
      if (action == 'vibe' &&
          !ModelSpecs.of(
            ref.read(generationParamsNotifierProvider).model,
          ).vibetransfer) {
        resourceError('unsupported', 'Model does not support Vibe');
      }
      final record = await backend.galleryRecord(id);
      if (!mounted || !actionContext.mounted) return;
      if (action == 'open') {
        // MainShell clears the current viewer on branch transitions. Let any
        // pending route frame (including cleanup microtasks) finish before
        // installing this external request. The host wraps every shell branch.
        if (ref
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path ==
            AppRoutes.login) {
          ref.read(appRouterProvider).go(AppRoutes.generation);
        }
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !actionContext.mounted) resourceError('not_ready');
        ref
            .read(imageViewerSessionProvider.notifier)
            .state = ImageViewerSession(
          backend: ImageViewerBackend(
            keys: [record.path],
            initialKey: record.path,
            load: (keys) async => [
              for (final r in await backend.gallery.getLibraryRecordsForPaths(
                keys,
              ))
                LocalImageDetailData(r),
            ],
            readMetadata: (source) =>
                (source as LocalImageDetailData).getMetadataAsync(),
          ),
          mode: ViewerMode.gallery,
        );
      } else {
        if (action != 'copy') {
          ref.read(appRouterProvider).go(AppRoutes.generation);
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || !actionContext.mounted) resourceError('not_ready');
        }
        final metadata = await resolveLocalGalleryMetadata(record);
        if (!mounted || !actionContext.mounted) return;
        await ImageViewerActionHost(actionContext, ref, alive).perform(
          LocalImageDetailData(record),
          switch (action) {
            'reuse' => ViewerAction.reuse,
            'img2img' => ViewerAction.img2img,
            'vibe' => ViewerAction.styleTransfer,
            'copy' => ViewerAction.copyImage,
            _ => throw ArgumentError.value(action),
          },
          metadata,
        );
      }
    } else if (kind == FloatingResourceKind.blocks) {
      final actions = BlocksActions(ref, actionContext, alive);
      if (action == 'edit') {
        await actions.edit(id: id);
      } else {
        // Explicit lanes, not a stale focused editor in the primary window.
        if (action == 'negative' &&
            !ModelSpecs.of(
              ref.read(generationParamsNotifierProvider).model,
            ).customNegativePrompt) {
          resourceError(
            'unsupported',
            'Model does not use custom negative prompt',
          );
        }
        final scope = action == 'negative'
            ? PillScopes.negative
            : PillScopes.main;
        ref.read(appRouterProvider).go(AppRoutes.generation);
        await actions.insert([id], targetScope: scope, propagateErrors: true);
      }
    } else if (action == 'edit') {
      ref.read(resourceRefsEditRequestProvider.notifier).state = (
        kind: kind,
        id: id,
      );
      ref
          .read(appRouterProvider)
          .go(
            kind == FloatingResourceKind.vibe
                ? AppRoutes.vibeLibrary
                : AppRoutes.preciseRefLibrary,
          );
    } else {
      final refsKind = kind == FloatingResourceKind.vibe
          ? RefsKind.vibe
          : RefsKind.precise;
      if (!ref.read(refsEntryDropActionsProvider).supports(refsKind)) {
        resourceError('unsupported', 'Model does not support ${refsKind.name}');
      }
      final result = await ref
          .read(refsEntryDropActionsProvider)
          .drop(
            refsKind,
            RefsEntryDragData(kind: refsKind, keys: [id]),
            alive: alive,
          );
      if (result.count == 0) resourceError('cancelled');
      ref.read(appRouterProvider).go(AppRoutes.generation);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
