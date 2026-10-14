import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/shortcuts/default_shortcuts.dart';
import '../../core/shortcuts/shortcut_manager.dart';
import '../providers/shortcuts_provider.dart';

import '../providers/image_generation_provider.dart';
import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import '../screens/generation/widgets/canvas/generation_canvas_view.dart';
import '../ui/gen/gen_canvas.dart';
import '../ui/gen/gen_contract.dart';
import '../widgets/common/selectable_image_card.dart';
import 'generation_operations.dart';
import 'generation_view_mapping.dart';
import 'tools_generation_wiring.dart';

/// 新页面保留图块和工具条，旧引擎只管理世界坐标、相机与选择联动。
class GenerationCanvasWiring extends ConsumerWidget {
  const GenerationCanvasWiring({super.key, required this.tileBuilder});

  final GenTileBuilder tileBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageGenerationNotifierProvider);
    return GenerationCanvasView(
      generationState: state,
      focusInsets: GenCanvas.pad,
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
          return activator?.accepts(event, HardwareKeyboard.instance) ?? false;
        });
      },
      tileBuilder: (context, item, focused, select, allowTap) {
        final tile = generationCanvasItemView(item, state);
        final slot = item.tile.slot;
        return GenCanvasTileScope(
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
          child: tileBuilder(
            context,
            tile,
            focused: focused && item.group.tiles.length > 1,
          ),
        );
      },
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
