import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/shortcuts/default_shortcuts.dart';
import '../../core/shortcuts/shortcut_manager.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/tips_provider.dart';

import '../providers/image_generation_provider.dart';
import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageGenerationNotifierProvider);
    final pins = ref.watch(canvasPinnedNotifierProvider);
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
          GenScope.of(context).data.canvas.info?.canCompareOriginal == true,
        ),
        deferKeyEvent: (event) {
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
        tileBuilder: (context, item, focused, select, allowTap) {
          final tile = generationCanvasItemView(item, state);
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
            preview:
                slot?.inpaintPreviewPlacement == null || tile.preview == null
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
                      () =>
                          ref.read(tipDeckProvider).draw(TipSurface.generating),
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
            child: widget.tileBuilder(
              context,
              tile,
              focused: focused && item.group.tiles.length > 1,
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
        },
      ),
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
