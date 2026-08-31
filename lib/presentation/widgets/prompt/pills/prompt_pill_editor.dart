import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/character/character_prompt.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../blocks/prompt_block_colors.dart';
import '../blocks/prompt_block_drag_data.dart';
import '../blocks/prompt_block_icons.dart';
import '../unified/unified_prompt_config.dart';
import '../unified/unified_prompt_input.dart';
import 'prompt_pill.dart';

/// 药丸块编辑器：单个完整输入框 + 内联药丸。
///
/// 与旧段式 `PromptBlockEditor` 平行存在，仅服务生成页正向主提示词。
/// 底层文本里块 = 1 个私有区标记字符，实例数据在
/// [pillWorkspaceNotifierProvider]，渲染钩子经 [UnifiedPromptConfig.pillBuilder]
/// 注入 `NaiSyntaxController` 的 span 构建链。
///
/// 块库入口不在本编辑器内（旧侧签/模态抽屉已拆除），由生成页页面级的
/// 块库面板承担；本编辑器只负责拖放落点与文内拖动排序。
class PromptPillEditor extends ConsumerStatefulWidget {
  const PromptPillEditor({
    super.key,
    required this.config,
    this.decoration,
    this.compact = false,
    this.autoGrow = false,
    this.minLines,
    this.sessionId,
    this.onChanged,
    this.onOpenAssistantSettings,
    this.onComfyuiImport,
  });

  final UnifiedPromptConfig config;
  final InputDecoration? decoration;
  final bool compact;
  final bool autoGrow;
  final int? minLines;
  final String? sessionId;

  /// 投影（块已展开的完整提示词）变化回调，接旧生成参数链路。
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenAssistantSettings;
  final void Function(String globalPrompt, List<CharacterPrompt> characters)?
  onComfyuiImport;

  @override
  ConsumerState<PromptPillEditor> createState() => _PromptPillEditorState();
}

class _PromptPillEditorState extends ConsumerState<PromptPillEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final GlobalKey _fieldAreaKey = GlobalKey();

  bool _applyingExternal = false;
  int _lastValidOffset = 0;
  String? _lastEmittedProjection;

  @override
  void initState() {
    super.initState();
    final document = ref.read(pillWorkspaceNotifierProvider).document;
    _controller = TextEditingController(text: document.text)
      ..addListener(_handleControllerChanged);
    _focusNode = FocusNode();
    _lastValidOffset = document.text.length;
    // 挂载即对齐一次投影（库内容可能在停机构间被编辑过）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitProjectionIfChanged(ref.read(pillWorkspaceNotifierProvider));
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 块库就绪/内容变化 → 重算投影（块内容经 resolver 实时解析进投影）
    ref.listen(promptBlockLibraryNotifierProvider, (_, __) {
      ref.read(pillWorkspaceNotifierProvider.notifier).refreshProjection();
    });

    final workspace = ref.watch(pillWorkspaceNotifierProvider);
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;

    // provider 驱动的文本变化（插入/移动/外部重建）回写 controller
    if (!_applyingExternal && _controller.text != workspace.document.text) {
      final oldSelection = _controller.selection;
      final offset = oldSelection.isValid
          ? oldSelection.extentOffset.clamp(0, workspace.document.text.length)
          : workspace.document.text.length;
      _applyingExternal = true;
      _controller.value = TextEditingValue(
        text: workspace.document.text,
        selection: TextSelection.collapsed(offset: offset),
      );
      _applyingExternal = false;
      _lastValidOffset = offset;
    }
    _emitProjectionIfChanged(workspace);

    final effectiveConfig = widget.config.copyWith(
      pillBuilder: _buildPillSpan,
      pillVisualsSignature: _pillSignature(workspace, library),
    );

    return DragTarget<PromptBlockDragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _handleDrop(details.data, details.offset),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: highlighted
                ? Border.all(color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          child: KeyedSubtree(
            key: _fieldAreaKey,
            child: UnifiedPromptInput(
              controller: _controller,
              focusNode: _focusNode,
              sessionId: widget.sessionId,
              config: effectiveConfig,
              decoration: widget.decoration,
              enableAssistant: true,
              onOpenAssistantSettings: widget.onOpenAssistantSettings,
              onComfyuiImport: widget.onComfyuiImport == null
                  ? null
                  : _handleComfyuiImport,
              maxLines: widget.compact ? 2 : null,
              minLines: widget.minLines ?? (widget.compact ? 1 : 2),
              expands: false,
              fitContent: true,
            ),
          ),
        );
      },
    );
  }

  // ==================== 药丸渲染 ====================

  /// 药丸视觉签名：实例启用态与被引用块的标题/颜色/存亡都参与，
  /// 文本本身的变化由 controller 文本缓存键覆盖，无需进签名。
  int _pillSignature(
    PillWorkspaceState workspace,
    PromptBlockLibraryState? library,
  ) {
    final parts = <Object>[];
    workspace.document.instances.forEach((marker, instance) {
      final block = library?.blockById(instance.blockId);
      parts.add(
        Object.hash(
          marker,
          instance.enabled,
          block?.title ?? '',
          block?.color ?? '',
          block?.iconName ?? '',
          block == null,
        ),
      );
    });
    parts.add(library == null);
    return Object.hashAll(parts);
  }

  InlineSpan? _buildPillSpan(
    BuildContext context,
    String marker,
    int occurrence,
  ) {
    final workspace = ref.read(pillWorkspaceNotifierProvider);
    final library = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    final instance = workspace.document.instances[marker];

    if (instance == null) {
      // 未知标记（外来粘贴的私用区字符）：点击清除
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => ref
              .read(pillWorkspaceNotifierProvider.notifier)
              .removeMarker(marker),
          child: PromptPill(
            title: context.l10n.promptBlockPill_unknown,
            color: Theme.of(context).colorScheme.outline,
            variant: PromptPillVariant.unknown,
          ),
        ),
      );
    }

    final block = library?.blockById(instance.blockId);
    if (block == null) {
      if (library == null) {
        // 库未就绪：中性占位，库到达后签名变化自动重渲染
        return const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: PromptPill(
            title: '…',
            color: Colors.grey,
            variant: PromptPillVariant.unknown,
          ),
        );
      }
      // 块已被从库中删除：红色警示，点击清除
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => ref
              .read(pillWorkspaceNotifierProvider.notifier)
              .removeMarker(marker),
          child: PromptPill(
            title: context.l10n.promptBlockPill_missing,
            color: Theme.of(context).colorScheme.error,
            variant: PromptPillVariant.missing,
          ),
        ),
      );
    }

    final title = block.title.trim().isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    final pill = PromptPill(
      title: title,
      color: promptBlockColorFromString(block.color),
      enabled: instance.enabled,
      icon: promptBlockIconFromName(block.iconName),
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      // 即按即拖（不用长按：长按手势不可发现，用户会以为不能拖）；
      // 立即拖拽与点击开关不冲突——快按快放归 tap，移动归 drag。
      // feedback 以指针为中心：默认 childDragAnchorStrategy 把 feedback
      // 左上角对准指针，用户以药丸视觉中心瞄准 → 落点系统性偏上一行。
      child: Draggable<PromptBlockDragData>(
        data: PromptBlockDragData(
          blockId: block.id,
          instanceMarker: PillInstanceDragRef(
            marker: marker,
            occurrence: occurrence,
          ),
        ),
        // feedback 必须有界宽（PromptPill 内 Row+Flexible 在 overlay 的
        // 无界约束下会直接布局异常），并投到根 overlay 避免被裁剪。
        rootOverlay: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: pill,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: pill),
        child: GestureDetector(
          onTap: () => ref
              .read(pillWorkspaceNotifierProvider.notifier)
              .toggleEnabled(marker),
          child: pill,
        ),
      ),
    );
  }

  // ==================== 拖放 ====================

  void _handleDrop(PromptBlockDragData data, Offset globalPosition) {
    final offset = _offsetForGlobalPosition(globalPosition);
    final dragRef = data.instanceMarker;
    if (dragRef == null) {
      ref
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: offset, blockId: data.blockId);
      _placeCaretAfter(offset + 1);
    } else {
      ref
          .read(pillWorkspaceNotifierProvider.notifier)
          .moveMarker(
            marker: dragRef.marker,
            occurrence: dragRef.occurrence,
            newOffset: offset,
          );
    }
  }

  /// 指针全局坐标 → 文本 offset。
  ///
  /// `getPositionForPoint` 收的是**全局坐标**（内部自行 globalToLocal +
  /// 滚动补偿），别再预先换算，否则双重减偏移、落点系统性偏上。
  /// 文本下方空白区落点 clamp 归末尾（可接受语义）。
  int _offsetForGlobalPosition(Offset global) {
    final editable = _findRenderEditable();
    if (editable == null) return _controller.text.length;
    final position = editable.getPositionForPoint(global);
    return position.offset.clamp(0, _controller.text.length);
  }

  RenderEditable? _findRenderEditable() {
    final root = _fieldAreaKey.currentContext?.findRenderObject();
    if (root == null) return null;
    RenderEditable? found;
    void visit(RenderObject object) {
      if (found != null) return;
      if (object is RenderEditable) {
        found = object;
        return;
      }
      object.visitChildren(visit);
    }

    visit(root);
    return found;
  }

  /// 插入后把光标放到新标记之后并聚焦，方便继续输入。
  void _placeCaretAfter(int offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      final clamped = offset.clamp(0, _controller.text.length);
      _controller.selection = TextSelection.collapsed(offset: clamped);
      _lastValidOffset = clamped;
      ref.read(pillMainCaretOffsetProvider.notifier).state = clamped;
    });
  }

  // ==================== 文本与投影同步 ====================

  void _handleControllerChanged() {
    final selection = _controller.selection;
    if (selection.isValid && selection.extentOffset >= 0) {
      _lastValidOffset = selection.extentOffset.clamp(
        0,
        _controller.text.length,
      );
      _syncCaretOffset(_lastValidOffset);
    }
    if (_applyingExternal) return;
    ref.read(pillWorkspaceNotifierProvider.notifier).setText(_controller.text);
  }

  /// 把最近光标位置同步给块库面板（点击插入的定位依据）。
  ///
  /// 本回调可能在 build 期间由 `_applyingExternal` 回写触发，
  /// 写 provider 必须延后到帧末。
  void _syncCaretOffset(int offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pillMainCaretOffsetProvider.notifier).state = offset;
    });
  }

  void _emitProjectionIfChanged(PillWorkspaceState workspace) {
    if (_lastEmittedProjection == workspace.projection) return;
    _lastEmittedProjection = workspace.projection;
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onChanged(workspace.projection);
    });
  }

  void _handleComfyuiImport(String globalPrompt, List<CharacterPrompt> chars) {
    ref
        .read(pillWorkspaceNotifierProvider.notifier)
        .replaceWithPlainText(globalPrompt);
    widget.onComfyuiImport?.call(globalPrompt, chars);
  }
}
