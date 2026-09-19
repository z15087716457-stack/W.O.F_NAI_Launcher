import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_palette_provider.dart';
import '../../../screens/prompt_block_library/widgets/prompt_block_card.dart';
import '../../../screens/prompt_block_library/widgets/prompt_block_detail.dart';
import 'prompt_block_drag_data.dart';

/// 积木按钮（生成页提示词卡头部右侧，原颜料板重命名归来）。
///
/// 点击 = 开/关积木悬浮窗；把块拖上按钮 = 直接收纳进板。
class PromptBlockPaletteButton extends ConsumerStatefulWidget {
  const PromptBlockPaletteButton({super.key});

  @override
  ConsumerState<PromptBlockPaletteButton> createState() =>
      _PromptBlockPaletteButtonState();
}

class _PromptBlockPaletteButtonState
    extends ConsumerState<PromptBlockPaletteButton> {
  OverlayEntry? _overlayEntry;
  bool _dragHover = false;

  bool get _isOpen => _overlayEntry != null;

  @override
  void dispose() {
    // dispose 期间 mounted 仍为 true，不能走 _close 的 setState。
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    if (_overlayEntry != null) return;
    final anchor = context.findRenderObject() as RenderBox?;
    _overlayEntry = OverlayEntry(
      builder: (_) =>
          _PromptBlockPaletteOverlay(anchor: anchor, onClose: _close),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<PromptBlockDragData>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (_) {
        if (!_dragHover) setState(() => _dragHover = true);
      },
      onLeave: (_) {
        if (_dragHover) setState(() => _dragHover = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _dragHover = false);
        ref
            .read(promptBlockPaletteNotifierProvider.notifier)
            .addBlock(details.data.blockId);
      },
      builder: (context, _, _) => Tooltip(
        message: context.l10n.promptBlockPalette_tooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: IconButton(
          key: const Key('prompt-block-palette-toggle'),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: _isOpen || _dragHover
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            foregroundColor: _isOpen || _dragHover
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: _toggle,
          icon: const Icon(Icons.category_outlined),
        ),
      ),
    );
  }
}

/// 悬浮层：半透明屏障（点击窗外关闭）+ 可拖动卡片。
class _PromptBlockPaletteOverlay extends StatefulWidget {
  const _PromptBlockPaletteOverlay({
    required this.anchor,
    required this.onClose,
  });

  final RenderBox? anchor;
  final VoidCallback onClose;

  @override
  State<_PromptBlockPaletteOverlay> createState() =>
      _PromptBlockPaletteOverlayState();
}

class _PromptBlockPaletteOverlayState
    extends State<_PromptBlockPaletteOverlay> {
  static const double _windowWidth = 272;

  /// 会话内记住上次拖动到的位置。
  static Offset? _lastOffset;

  Offset? _offset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery 依赖 inherited widget，只能从这里读，不能进 initState。
    _offset ??= _lastOffset ?? _initialOffset();
  }

  Offset _initialOffset() {
    final anchor = widget.anchor;
    final screen = MediaQuery.sizeOf(context);
    if (anchor == null || !anchor.attached) {
      return Offset(screen.width - _windowWidth - 24, 120);
    }
    final origin = anchor.localToGlobal(Offset.zero);
    return _clamp(
      Offset(origin.dx, origin.dy + anchor.size.height + 8),
      screen,
    );
  }

  Offset _clamp(Offset offset, Size screen) => Offset(
    offset.dx.clamp(8.0, math.max(8.0, screen.width - _windowWidth - 8)),
    offset.dy.clamp(8.0, math.max(8.0, screen.height - 120)),
  );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onClose,
          ),
        ),
        Positioned(
          left: _offset!.dx,
          top: _offset!.dy,
          child: GestureDetector(
            // 卡片自身吃掉点击，避免触发屏障关闭
            onTap: () {},
            child: _PromptBlockPaletteCard(
              width: _windowWidth,
              onClose: widget.onClose,
              onPanUpdate: (delta) => setState(() {
                _offset = _clamp(_offset! + delta, screen);
                _lastOffset = _offset;
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// 悬浮窗本体：标题栏（拖拽柄 + X）+ 块列表 + 空态提示。
class _PromptBlockPaletteCard extends ConsumerWidget {
  const _PromptBlockPaletteCard({
    required this.width,
    required this.onClose,
    required this.onPanUpdate,
  });

  final double width;
  final VoidCallback onClose;
  final ValueChanged<Offset> onPanUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = ref.watch(promptBlockPaletteNotifierProvider).valueOrNull;
    final blocks = palette?.blocks ?? const <PromptBlock>[];
    final folders = palette?.folders ?? const <PromptBlockFolder>[];
    final maxHeight = math.min(420.0, MediaQuery.sizeOf(context).height * 0.6);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width,
          maxWidth: width,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏：拖拽柄 + X（窗内唯一常驻控制钮）
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => onPanUpdate(details.delta),
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.promptBlockPalette_tooltip,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('prompt-block-palette-close'),
                        iconSize: 15,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            // 列表区：拖到空白处 = 追加到末尾
            Flexible(
              child: DragTarget<PromptBlockDragData>(
                onAcceptWithDetails: (details) {
                  final notifier = ref.read(
                    promptBlockPaletteNotifierProvider.notifier,
                  );
                  final paletteIndex = details.data.paletteIndex;
                  if (paletteIndex != null) {
                    notifier.move(paletteIndex, blocks.length - 1);
                  } else {
                    notifier.addBlock(details.data.blockId);
                  }
                },
                builder: (context, _, _) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < blocks.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _PaletteChipRow(
                            block: blocks[i],
                            index: i,
                            folders: folders,
                          ),
                        ),
                      if (blocks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                          child: Text(
                            l10n.promptBlockPalette_emptyHint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 板内一行：可拖出插入提示词、点击插到光标处、拖到另一行上换位、
/// 悬停浮现 X 移除（非常驻）。
class _PaletteChipRow extends ConsumerStatefulWidget {
  const _PaletteChipRow({
    required this.block,
    required this.index,
    required this.folders,
  });

  final PromptBlock block;
  final int index;
  final List<PromptBlockFolder> folders;

  @override
  ConsumerState<_PaletteChipRow> createState() => _PaletteChipRowState();
}

class _PaletteChipRowState extends ConsumerState<_PaletteChipRow> {
  bool _hovering = false;
  bool _dropHover = false;

  /// 点击插入：与块库面板同一路由——最近聚焦的药丸框光标处，
  /// 从未聚焦过时回退主提示词末尾。
  void _insertAtCaret() {
    final target = ref.read(pillActiveEditorTargetProvider);
    final lane = pillWorkspaceProvider(target?.scope ?? PillScopes.main);
    final document = ref.read(lane).document;
    final offset = (target?.caret ?? document.text.length).clamp(
      0,
      document.text.length,
    );
    ref
        .read(lane.notifier)
        .insertBlockAt(offset: offset, blockId: widget.block.id);
  }

  void _remove() => ref
      .read(promptBlockPaletteNotifierProvider.notifier)
      .removeBlock(widget.block.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;
    final title = block.title.trim().isEmpty ? block.content : block.title;

    final chip = PromptBlockPill(
      block: block,
      displayTitle: title,
      maxWidth: 240,
      onTap: _insertAtCaret,
    );

    return DragTarget<PromptBlockDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.paletteIndex != widget.index,
      onMove: (_) {
        if (!_dropHover) setState(() => _dropHover = true);
      },
      onLeave: (_) {
        if (_dropHover) setState(() => _dropHover = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _dropHover = false);
        final notifier = ref.read(promptBlockPaletteNotifierProvider.notifier);
        final fromIndex = details.data.paletteIndex;
        if (fromIndex != null) {
          notifier.move(fromIndex, widget.index);
        } else {
          notifier.insertBlock(details.data.blockId, widget.index);
        }
      },
      builder: (context, _, _) => MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: PromptBlockHoverPreview(
          key: ValueKey('palette-preview-${block.id}'),
          block: block,
          folders: widget.folders,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: _dropHover
                ? Border.all(color: theme.colorScheme.primary, width: 1.4)
                : null,
          ),
          child: Stack(
            children: [
              Draggable<PromptBlockDragData>(
                data: PromptBlockDragData(
                  blockId: block.id,
                  paletteIndex: widget.index,
                ),
                rootOverlay: true,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Opacity(opacity: 0.9, child: chip),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: chip),
                child: Align(alignment: Alignment.centerLeft, child: chip),
              ),
              if (_hovering)
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: Tooltip(
                        message: context.l10n.promptBlockPalette_remove,
                        child: InkWell(
                          key: ValueKey(
                            'prompt-block-palette-remove-${block.id}',
                          ),
                          onTap: _remove,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
