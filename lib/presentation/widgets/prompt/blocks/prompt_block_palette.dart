import 'dart:async';
import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/studio_animated_icon.dart';
import '../../common/studio_icons.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../providers/generation/generation_params_notifier.dart';
import '../../../providers/generation/generation_settings_notifiers.dart';
import '../../../providers/prompt_block_palette_provider.dart';
import '../../../utils/translation_palette_drop.dart';
import 'prompt_block_pill.dart';
import 'prompt_block_hover_preview.dart';
import 'prompt_block_drag_data.dart';
import 'prompt_block_colors.dart';
import '../../../ui/kit/ui_block_pill.dart';
import '../../../wiring/blocks_actions.dart';

/// 积木按钮（生成页提示词卡头部右侧，原颜料板重命名归来）。
///
/// 点击 = 开/关积木悬浮窗；把块拖上按钮 = 直接收纳进板。
class PromptBlockPaletteButton extends ConsumerStatefulWidget {
  const PromptBlockPaletteButton({super.key, this.onInsert});
  final Future<void> Function(String id)? onInsert;

  static Future<void> showAt(BuildContext context, Rect anchor) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => _PromptBlockPaletteOverlay(
          anchor: null,
          anchorRect: anchor,
          progress: const AlwaysStoppedAnimation(1),
          onClose: () => Navigator.of(context).pop(),
        ),
      );

  @override
  ConsumerState<PromptBlockPaletteButton> createState() =>
      _PromptBlockPaletteButtonState();
}

class _PromptBlockPaletteButtonState
    extends ConsumerState<PromptBlockPaletteButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late final AnimationController _animation;
  late final CurvedAnimation _progress;
  bool _closing = false;
  bool _dragHover = false;
  int _motionTrigger = 0;

  bool get _isOpen => _overlayEntry != null && !_closing;
  bool get _reducedMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      !TickerMode.valuesOf(context).enabled;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _progress = CurvedAnimation(
      parent: _animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_overlayEntry != null && _reducedMotion) {
      // 悬浮层与按钮位于不同构建分支，动画值更新要等当前帧结束。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _overlayEntry == null || !_reducedMotion) return;
        if (_closing) _removeOverlay();
        _animation.value = 1;
      });
    }
  }

  @override
  void dispose() {
    // dispose 期间 mounted 仍为 true，不能走 _close 的 setState。
    _removeOverlay(notify: false);
    _progress.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _toggle() {
    _isOpen ? unawaited(_close()) : _open();
  }

  void _open() {
    if (_isOpen) return;
    final resuming = _overlayEntry != null;
    _closing = false;
    if (!resuming) {
      final anchor = context.findRenderObject() as RenderBox?;
      _overlayEntry = OverlayEntry(
        builder: (_) => IgnorePointer(
          // 已开始关闭便释放点击；快速再开可从当前进度恢复。
          ignoring: _closing,
          child: _PromptBlockPaletteOverlay(
            anchor: anchor,
            progress: _progress,
            onClose: () => unawaited(_close()),
            onInsert: widget.onInsert,
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
    _overlayEntry!.markNeedsBuild();
    setState(() => _motionTrigger++);
    if (_reducedMotion) {
      _animation.value = 1;
    } else {
      _animation.forward(from: resuming ? null : 0);
    }
  }

  Future<void> _close() async {
    final entry = _overlayEntry;
    if (entry == null || _closing) return;
    setState(() {
      _closing = true;
      _motionTrigger++;
    });
    entry.markNeedsBuild();
    if (!_reducedMotion) {
      try {
        await _animation.reverse().orCancel;
      } on TickerCanceled {
        // 快速再开或宿主销毁时，旧关闭请求不能移除新窗口。
        return;
      }
    }
    if (mounted && _closing && identical(entry, _overlayEntry)) {
      _removeOverlay();
    }
  }

  void _removeOverlay({bool notify = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;
    _closing = false;
    entry?.remove();
    entry?.dispose();
    if (notify && mounted) setState(() {});
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
        unawaited(acceptPaletteDrag(ref, details.data));
      },
      builder: (context, _, _) => Tooltip(
        message: context.l10n.promptBlockPalette_tooltip,
        waitDuration: const Duration(milliseconds: 300),
        verticalOffset: 18,
        child: IconButton(
          key: const Key('prompt-block-palette-toggle'),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            hoverColor: Colors.transparent,
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            backgroundColor: _dragHover
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            foregroundColor: _dragHover
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: _toggle,
          icon: StudioAnimatedIcon(
            icon: StudioIcons.promptBlockPalette,
            trigger: _motionTrigger,
          ),
        ),
      ),
    );
  }
}

/// 悬浮层：半透明屏障（点击窗外关闭）+ 可拖动卡片。
class _PromptBlockPaletteOverlay extends StatefulWidget {
  const _PromptBlockPaletteOverlay({
    required this.anchor,
    required this.progress,
    required this.onClose,
    this.anchorRect,
    this.onInsert,
  });

  final Rect? anchorRect;
  final RenderBox? anchor;
  final Animation<double> progress;
  final VoidCallback onClose;
  final Future<void> Function(String id)? onInsert;

  @override
  State<_PromptBlockPaletteOverlay> createState() =>
      _PromptBlockPaletteOverlayState();
}

class _PromptBlockPaletteOverlayState
    extends State<_PromptBlockPaletteOverlay> {
  /// 方形悬浮窗边长：空窗/稀疏也有默认块头（图观感≈大方块），
  /// 内容超过上限后列表内部滚动。
  static const double _windowWidth = 400;
  static const double _windowMinHeight = 340;
  static const double _windowMaxHeight = 400;

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
    final rect = widget.anchorRect;
    if (rect != null) return _clamp(Offset(rect.left, rect.bottom + 8), screen);
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
    offset.dy.clamp(8.0, math.max(8.0, screen.height - _windowMaxHeight - 8)),
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
          child: FadeTransition(
            key: const Key('prompt-block-palette-fade'),
            opacity: widget.progress,
            child: ScaleTransition(
              key: const Key('prompt-block-palette-scale'),
              scale: Tween<double>(begin: .94, end: 1).animate(widget.progress),
              alignment: Alignment.topLeft,
              child: GestureDetector(
                // 卡片自身吃掉点击，避免触发屏障关闭
                onTap: () {},
                child: _PromptBlockPaletteCard(
                  width: _windowWidth,
                  minHeight: _windowMinHeight,
                  maxHeight: _windowMaxHeight,
                  onClose: widget.onClose,
                  onInsert: widget.onInsert,
                  onPanUpdate: (delta) => setState(() {
                    _offset = _clamp(_offset! + delta, screen);
                    _lastOffset = _offset;
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 悬浮窗本体：标题栏（拖拽柄 + 多选 + 清空 + X）+ 块列表 + 空态提示。
class _PromptBlockPaletteCard extends ConsumerStatefulWidget {
  const _PromptBlockPaletteCard({
    required this.width,
    required this.minHeight,
    required this.maxHeight,
    required this.onClose,
    this.onInsert,
    required this.onPanUpdate,
  });

  final double width;
  final double minHeight;
  final double maxHeight;
  final VoidCallback onClose;
  final Future<void> Function(String id)? onInsert;
  final ValueChanged<Offset> onPanUpdate;

  @override
  ConsumerState<_PromptBlockPaletteCard> createState() =>
      _PromptBlockPaletteCardState();
}

class _PromptBlockPaletteCardState
    extends ConsumerState<_PromptBlockPaletteCard> {
  /// 多选模式：点芯片切换选中，拖放与插入停用。
  bool _multiSelectMode = false;
  final Set<String> _multiSelectedIds = <String>{};

  /// 「清空」需要连点两次才生效（armed 状态由图标颜色表达），
  /// 避免误触把辛苦收纳的板子一键清光。armed 3 秒后自动解除。
  bool _clearArmed = false;
  Timer? _clearArmTimer;

  @override
  void dispose() {
    _clearArmTimer?.cancel();
    super.dispose();
  }

  void _disarmClear() {
    _clearArmTimer?.cancel();
    _clearArmTimer = null;
    _clearArmed = false;
  }

  void _toggleMultiSelect() => setState(() {
    _multiSelectMode = !_multiSelectMode;
    _multiSelectedIds.clear();
    _disarmClear();
  });

  void _toggleSelected(String blockId) => setState(() {
    if (!_multiSelectedIds.remove(blockId)) {
      _multiSelectedIds.add(blockId);
    }
  });

  Future<void> _removeSelected() async {
    final ids = Set<String>.of(_multiSelectedIds);
    setState(() => _multiSelectedIds.clear());
    await ref
        .read(promptBlockPaletteNotifierProvider.notifier)
        .removeBlocks(ids);
  }

  /// 连点两次确认清空；armed 图标变红，3 秒无第二击自动解除。
  void _onClearAllPressed() {
    if (!_clearArmed) {
      setState(() => _clearArmed = true);
      _clearArmTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(_disarmClear);
      });
      return;
    }
    setState(_disarmClear);
    ref.read(promptBlockPaletteNotifierProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = ref.watch(promptBlockPaletteNotifierProvider).valueOrNull;
    final blocks = palette?.blocks ?? const <PromptBlock>[];
    final folders = palette?.folders ?? const <PromptBlockFolder>[];
    // 块被移除/清库后自动把失效 id 从选中集里剔除（有效选中，state 不脏）。
    final selectedIds = _multiSelectedIds
        .where((id) => blocks.any((block) => block.id == id))
        .toSet();
    final maxHeight = math.min(
      widget.maxHeight,
      math.max(160.0, MediaQuery.sizeOf(context).height - 16),
    );
    final minHeight = math.min(widget.minHeight, maxHeight);

    return Material(
      key: const Key('prompt-block-palette-card'),
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.width,
          maxWidth: widget.width,
          minHeight: minHeight,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏：拖拽柄 + 多选 + 清空 + X
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => widget.onPanUpdate(details.delta),
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    children: [
                      Icon(
                        StudioIcons.promptBlockPalette,
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
                        key: const Key('prompt-block-palette-multi-select'),
                        iconSize: 15,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        isSelected: _multiSelectMode,
                        tooltip: _multiSelectMode
                            ? l10n.promptBlockLibrary_exitMultiSelect
                            : l10n.promptBlockLibrary_multiSelect,
                        onPressed: _toggleMultiSelect,
                        icon: const Icon(Icons.checklist),
                      ),
                      IconButton(
                        key: const Key('prompt-block-palette-clear'),
                        iconSize: 15,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip: _clearArmed
                            ? l10n.promptBlockPalette_clearAllArmed
                            : l10n.promptBlockPalette_clearAll,
                        onPressed: blocks.isEmpty ? null : _onClearAllPressed,
                        icon: Icon(
                          Icons.delete_sweep_outlined,
                          color: _clearArmed ? theme.colorScheme.error : null,
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
                        onPressed: widget.onClose,
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
            // 多选操作条：计数 + 全选 + 取消选择 + 移除选中（与块库多选条同款）
            if (_multiSelectMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.promptBlockLibrary_selectedCount(
                          selectedIds.length,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('prompt-block-palette-select-all'),
                      iconSize: 15,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: l10n.promptBlockLibrary_selectAllVisible,
                      onPressed: selectedIds.length == blocks.length
                          ? null
                          : () => setState(
                              () => _multiSelectedIds.addAll(
                                blocks.map((block) => block.id),
                              ),
                            ),
                      icon: const Icon(Icons.select_all),
                    ),
                    IconButton(
                      key: const Key('prompt-block-palette-deselect'),
                      iconSize: 15,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: l10n.promptBlockLibrary_clearSelection,
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () => setState(_multiSelectedIds.clear),
                      icon: const Icon(Icons.deselect),
                    ),
                    IconButton(
                      key: const Key('prompt-block-palette-remove-selected'),
                      iconSize: 15,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: l10n.promptBlockPalette_removeSelected(
                        selectedIds.length,
                      ),
                      onPressed: selectedIds.isEmpty ? null : _removeSelected,
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            // 列表区：拖到空白处 = 追加到末尾（多选模式下拖放整体停用）
            Flexible(
              child: DragTarget<PromptBlockDragData>(
                onWillAcceptWithDetails: (_) => !_multiSelectMode,
                onAcceptWithDetails: (details) {
                  final notifier = ref.read(
                    promptBlockPaletteNotifierProvider.notifier,
                  );
                  final paletteIndex = details.data.paletteIndex;
                  if (paletteIndex != null) {
                    notifier.move(paletteIndex, blocks.length - 1);
                  } else {
                    unawaited(acceptPaletteDrag(ref, details.data));
                  }
                },
                builder: (context, _, _) => LayoutBuilder(
                  builder: (context, listConstraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: ConstrainedBox(
                      // 内容不足时占满列表区，让空态/稀疏内容垂直居中，
                      // 窗口保持方块观感而非一条窄带。
                      constraints: BoxConstraints(
                        minHeight: math.max(0, listConstraints.maxHeight - 16),
                      ),
                      child: blocks.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  l10n.promptBlockPalette_emptyHint,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            )
                          // 流式排布：一行摆不下整块就自动换到下一行。
                          : Align(
                              alignment: Alignment.topLeft,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                runAlignment: WrapAlignment.start,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (var i = 0; i < blocks.length; i++)
                                    _PaletteChipRow(
                                      block: blocks[i],
                                      index: i,
                                      folders: folders,
                                      onInsert: widget.onInsert,
                                      multiSelectMode: _multiSelectMode,
                                      selected: selectedIds.contains(
                                        blocks[i].id,
                                      ),
                                      onToggleSelected: _multiSelectMode
                                          ? () => _toggleSelected(blocks[i].id)
                                          : null,
                                    ),
                                ],
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
    required this.multiSelectMode,
    required this.selected,
    this.onToggleSelected,
    this.onInsert,
  });

  final PromptBlock block;
  final int index;
  final List<PromptBlockFolder> folders;

  /// 多选模式下点芯片 = 切换选中；拖放、插入与悬停 X 都停用。
  final bool multiSelectMode;
  final bool selected;
  final VoidCallback? onToggleSelected;
  final Future<void> Function(String id)? onInsert;

  @override
  ConsumerState<_PaletteChipRow> createState() => _PaletteChipRowState();
}

class _PaletteChipRowState extends ConsumerState<_PaletteChipRow> {
  bool _hovering = false;
  bool _dropHover = false;

  /// 点击插入：与块库面板同一路由——最近聚焦的药丸框光标处，
  /// 从未聚焦过时回退主提示词末尾。
  void _insertAtCaret() {
    if (widget.onInsert != null) {
      unawaited(widget.onInsert!(widget.block.id));
      return;
    }
    BlocksActions(ref, context, () => mounted).insert([widget.block.id]);
  }

  void _remove() => ref
      .read(promptBlockPaletteNotifierProvider.notifier)
      .removeBlock(widget.block.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;
    final title = block.readingTranslationZh?.trim().isNotEmpty == true
        ? block.readingTranslationZh!
        : block.title.trim().isEmpty
        ? block.content
        : block.title;
    final highlightEnabled = ref.watch(highlightEmphasisSettingsProvider);
    final numericEmphasisEnabled = ImageModels.isV4Model(
      ref.watch(
        generationParamsNotifierProvider.select((params) => params.model),
      ),
    );

    final chip =
        block.readingTranslationZh != null || block.appearance == 'translation'
        ? PromptBlockPill(
            block: block,
            displayTitle: title,
            maxWidth: 374,
            paletteStyle: true,
            highlightEnabled: highlightEnabled,
            numericEmphasisEnabled: numericEmphasisEnabled,
            multiSelected: widget.selected,
            onTap: widget.onToggleSelected ?? _insertAtCaret,
          )
        : GestureDetector(
            key: ValueKey('prompt-block-pill-body-${block.id}'),
            onTap: widget.onToggleSelected ?? _insertAtCaret,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 374),
              child: UiBlockPill(
                label: title,
                color: promptBlockColorFromString(block.color),
                icon: block.iconName,
                look:
                    BlockAppearance.values.asNameMap()[block.appearance] ??
                    BlockAppearance.classic,
                focused: widget.selected,
              ),
            ),
          );

    return DragTarget<PromptBlockDragData>(
      onWillAcceptWithDetails: (details) =>
          !widget.multiSelectMode && details.data.paletteIndex != widget.index,
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
          unawaited(acceptPaletteDrag(ref, details.data, index: widget.index));
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
              borderRadius: BorderRadius.circular(6),
              border: _dropHover
                  ? Border.all(color: theme.colorScheme.primary, width: 1.4)
                  : null,
            ),
            child: Stack(
              // 流式排布下收缩到芯片尺寸，别吃满 Wrap 给的宽松宽。
              fit: StackFit.loose,
              children: [
                Draggable<PromptBlockDragData>(
                  data: PromptBlockDragData(
                    blockId: block.id,
                    paletteIndex: widget.index,
                  ),
                  rootOverlay: true,
                  maxSimultaneousDrags: widget.multiSelectMode ? 0 : 1,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Opacity(opacity: 0.9, child: chip),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.35, child: chip),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: chip,
                  ),
                ),
                if (_hovering && !widget.multiSelectMode)
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
