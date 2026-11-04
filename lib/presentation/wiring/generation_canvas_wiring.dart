import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/shortcuts/default_shortcuts.dart';
import '../../core/shortcuts/shortcut_manager.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/tips_provider.dart';

import '../providers/canvas_image_residency_provider.dart';
import '../providers/image_generation_provider.dart';
import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import '../screens/generation/widgets/canvas/generation_canvas_controller.dart'
    show generationCanvasViewportProvider;
import '../screens/generation/widgets/canvas/generation_canvas_view.dart';
import '../ui/gen/gen_canvas.dart';
import '../ui/gen/gen_contract.dart';
import '../ui/gen/gen_page.dart';
import '../widgets/common/selectable_image_card.dart';
import 'generation_operations.dart';
import 'generation_view_mapping.dart';
import 'tools_generation_wiring.dart';

/// 新页面保留图块和工具条，旧引擎只管理世界坐标、相机与选择联动。
class GenerationCanvasWiring extends ConsumerStatefulWidget {
  const GenerationCanvasWiring({super.key, required this.tileBuilder});

  final GenTileBuilder tileBuilder;

  @override
  ConsumerState<GenerationCanvasWiring> createState() =>
      _GenerationCanvasWiringState();
}

class _GenerationCanvasWiringState
    extends ConsumerState<GenerationCanvasWiring> {
  final _tips = <String, Tip>{};
  late var _tileBuilder = _buildTile;

  @override
  void didUpdateWidget(GenerationCanvasWiring oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tileBuilder != widget.tileBuilder) {
      _tileBuilder = (context, item, focused, select, allowTap) =>
          _buildTile(context, item, focused, select, allowTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      imageGenerationNotifierProvider.select(
        (s) => (
          s.currentImages,
          s.history,
          s.displayImages,
          s.status,
          s.generationRunId,
          s.totalImages,
          s.batchWidth,
          s.batchHeight,
          s.displayWidth,
          s.displayHeight,
          s.errorMessage,
          s.isGenerating
              ? (
                  s.currentImage,
                  s.progress,
                  s.streamPreview,
                  s.streamPreviewSlots,
                  s.inpaintPreviewPlacement,
                )
              : null,
        ),
      ),
    );
    final state = ref.read(imageGenerationNotifierProvider);
    ref.watch(canvasPinnedNotifierProvider);
    final run = state.generationRunId == null
        ? 'inflight'
        : 'run:${state.generationRunId}';
    _tips.removeWhere(
      (key, _) => !state.isGenerating || !key.startsWith('$run:'),
    );
    return LayoutBuilder(
      builder: (context, constraints) => GenerationCanvasView(
        generationState: state,
        visualChannel: true,
        focusInsets: GenCanvas.focusPadding(
          constraints.maxWidth,
          GenScope.of(
                context,
                GenAspect.canvas,
              ).data.canvas.info?.canCompareOriginal ==
              true,
        ),
        deferKeyEvent: (event) {
          if (event.logicalKey == LogicalKeyboardKey.escape &&
              GenScope.read(context).controller.selection.active) {
            return true;
          }
          final config = ref.read(shortcutConfigNotifierProvider).valueOrNull;
          if (config == null || !config.enableShortcuts) return false;
          return config.bindings.values.any((binding) {
            if (!binding.enabled ||
                (binding.context != ShortcutContext.generation &&
                    binding.context != ShortcutContext.global)) {
              return false;
            }
            final activator = AppShortcutManager.parseActivator(
              binding.effectiveShortcut,
            );
            return activator?.accepts(event, HardwareKeyboard.instance) ??
                false;
          });
        },
        tileBuilder: _tileBuilder,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    CanvasFeedItem item,
    bool focused,
    VoidCallback select,
    bool Function() allowTap,
  ) {
    final state = ref.read(imageGenerationNotifierProvider);
    final pins = ref.read(canvasPinnedNotifierProvider);

    final tile = generationCanvasItemView(item, state);
    final image = item.image;
    Widget buildTile(BuildContext context, GenTile tile) => widget.tileBuilder(
      context,
      tile,
      focused: focused && item.group.tiles.length > 1,
    );
    final slot = item.tile.slot;
    final content = GenCanvasTileScope(
      allowTap: allowTap,
      onFocus: () {
        if (ref.read(toolsSheetProvider) == null) {
          select();
          return;
        }
        final operations = GenerationOperations(
          ref,
          context,
          () => context.mounted,
        );
        operations.run(() async {
          await operations.closeToolSheet();
          if (context.mounted) select();
        });
      },
      preview: slot?.inpaintPreviewPlacement == null || tile.preview == null
          ? null
          : buildStreamPreviewImage(
              bytes: slot!.previewBytes!,
              placement: slot.inpaintPreviewPlacement,
            ),
      generating: slot == null
          ? null
          : CanvasGeneratingContent(
              tip: _tips.putIfAbsent(
                '${item.group.key}:${slot.imageNumber}',
                () => ref.read(tipDeckProvider).draw(TipSurface.generating),
              ),
            ),
      failedPreview: item.image?.isFailedStreamSnapshot == true
          ? Image(
              image: tile.image!,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            )
          : null,
      child: image == null || image.isFailedStreamSnapshot
          ? buildTile(context, tile)
          : CanvasResidentTile(
              image: image,
              worldRect: item.worldRect,
              builder: (context, display) => buildTile(
                context,
                generationTileView(image, display: display),
              ),
            ),
    );
    return buildCanvasTilePresentation(
      item: item,
      focused: focused,
      pinned: item.image != null && pins.contains(item.image!.id),
      onSelect: select,
      child: item.image == null
          ? content
          : Tooltip(
              message: item.image!.isFailedStreamSnapshot
                  ? context.l10n.generation_failedStreamSnapshotHint
                  : '',
              child: content,
            ),
    );
  }
}

final _canvasDecodeViewProvider = Provider(
  (ref) => (
    camera: ref.watch(generationCanvasCameraProvider),
    viewport:
        ref.watch(generationCanvasViewportProvider) ??
        ref.read(generationCanvasCameraProvider.notifier).viewportSize,
  ),
);

/// A finished image on the canvas: at full resolution while it is resident
/// (among the newest, selected, or looked at in the last few minutes), else
/// decoded at the size the camera shows it, so old images do not each hold a
/// full decode. Rebuilds only when that size changes.
class CanvasResidentTile extends ConsumerStatefulWidget {
  const CanvasResidentTile({
    super.key,
    required this.image,
    required this.worldRect,
    required this.builder,
  });

  final GeneratedImage image;

  /// Where the tile sits in the world (native image pixels).
  final Rect worldRect;

  final Widget Function(BuildContext context, ImageProvider display) builder;

  @override
  ConsumerState<CanvasResidentTile> createState() => _CanvasResidentTileState();
}

class _CanvasResidentTileState extends ConsumerState<CanvasResidentTile> {
  late final CanvasImageResidencyNotifier _residency;

  @override
  void initState() {
    super.initState();
    _residency = ref.read(canvasImageResidencyProvider.notifier)..attach();
  }

  @override
  void dispose() {
    _residency.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final clock = ref.read(canvasResidencyClockProvider);
    final resident = ref.watch(
      canvasImageResidencyProvider.select(
        (residency) => residency.keepsFullResolution(image.id, at: clock()),
      ),
    );
    int? width;
    if (!resident) {
      final ratio = MediaQuery.devicePixelRatioOf(context);
      width = ref.watch(
        _canvasDecodeViewProvider.select(
          (view) => canvasTileDecodeWidth(
            tileRect: widget.worldRect,
            nativeWidth: image.width,
            camera: view.camera,
            viewport: view.viewport,
            devicePixelRatio: ratio,
          ),
        ),
      );
    }
    return widget.builder(
      context,
      canvasImageProvider(image, decodeWidth: width),
    );
  }
}

GenTile generationCanvasItemView(
  CanvasFeedItem item,
  ImageGenerationState state,
) {
  if (item.image case final image?) return generationTileView(image);
  final slot = item.tile.slot!;
  final preview = slot.previewBytes;
  final streaming =
      preview?.isNotEmpty == true ||
      slot.progress > 0 ||
      state.currentImage == slot.imageNumber;
  return GenTile(
    id: 'slot:${item.group.key}:${slot.imageNumber - 1}',
    width: item.tile.resolvedWidth.round(),
    height: item.tile.resolvedHeight.round(),
    state: streaming ? GenTileState.streaming : GenTileState.pending,
    preview: preview?.isNotEmpty == true ? MemoryImage(preview!) : null,
    progress: streaming ? slot.progress.clamp(0, 1) : null,
  );
}
