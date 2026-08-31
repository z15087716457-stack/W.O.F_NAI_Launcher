import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/character/character_prompt.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_document.dart';
import '../../../../data/models/prompt_block/prompt_block_segment.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/prompt_block_workspace_provider.dart';
import '../nai_syntax_controller.dart';
import '../unified/unified_prompt_config.dart';
import 'prompt_block_chip.dart';
import 'prompt_block_drawer.dart';
import 'prompt_block_drag_data.dart';
import 'prompt_block_text_segment.dart';

/// Prompt 块工作区编辑器。
///
/// 文档是唯一的结构化真相；每个文本段只拥有一个稳定的文本控制器，
/// 纯文本投影通过 [onChanged] 提供给旧生成参数链路。
///
/// 默认挂到生成页的全局工作区；[workspaceProvider] 可传入其他
/// 工作区实例（如画风探索页），同一编辑器组件在不同实例间复用。
class PromptBlockEditor extends ConsumerStatefulWidget {
  const PromptBlockEditor({
    super.key,
    required this.lane,
    required this.config,
    this.workspaceProvider,
    this.decoration,
    this.compact = false,
    this.autoGrow = false,
    this.minLines,
    this.sessionId,
    this.onChanged,
    this.onOpenAssistantSettings,
    this.onComfyuiImport,
  });

  final PromptBlockLane lane;

  /// 目标工作区 provider；null 表示生成页全局工作区。
  final NotifierProvider<
    PromptBlockWorkspaceNotifier,
    PromptBlockWorkspaceState
  >?
  workspaceProvider;
  final UnifiedPromptConfig config;
  final InputDecoration? decoration;
  final bool compact;
  final bool autoGrow;
  final int? minLines;
  final String? sessionId;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenAssistantSettings;
  final void Function(String globalPrompt, List<CharacterPrompt> characters)?
  onComfyuiImport;

  @override
  ConsumerState<PromptBlockEditor> createState() => _PromptBlockEditorState();
}

class _PromptBlockEditorState extends ConsumerState<PromptBlockEditor> {
  final Map<String, NaiSyntaxController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, int> _lastOffsets = {};
  String? _activeTextSegmentId;
  bool _drawerExpanded = false;
  bool _syncing = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  NotifierProvider<PromptBlockWorkspaceNotifier, PromptBlockWorkspaceState>
  get _workspace =>
      widget.workspaceProvider ?? promptBlockWorkspaceNotifierProvider;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(_workspace);
    final document = workspace.documentFor(widget.lane);
    _syncCaches(document);

    final editor = _buildSegmentList(document);
    return LayoutBuilder(
      builder: (context, constraints) {
        final showOverlayDrawer =
            !widget.compact && constraints.maxWidth >= 640;
        if (showOverlayDrawer) {
          return _buildWideLayout(context, editor);
        }

        return _buildModalSideTabLayout(context, editor);
      },
    );
  }

  Widget _buildModalSideTabLayout(BuildContext context, Widget editor) {
    return Row(
      crossAxisAlignment: widget.autoGrow
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        Expanded(child: editor),
        SizedBox(
          width: 38,
          height: 48,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: IconButton(
              key: const Key('prompt-block-open-drawer'),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: () => _showDrawerModal(context),
              icon: const Icon(Icons.view_module_outlined),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, Widget editor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: widget.autoGrow
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.stretch,
          children: [
            Expanded(child: editor),
            SizedBox(
              width: 38,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: IconButton(
                  key: const Key('prompt-block-open-drawer'),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).openAppDrawerTooltip,
                  onPressed: _toggleDrawer,
                  icon: Icon(
                    _drawerExpanded
                        ? Icons.keyboard_double_arrow_right
                        : Icons.view_module_outlined,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_drawerExpanded)
          Positioned(
            top: 0,
            right: 0,
            bottom: widget.autoGrow ? null : 0,
            width: 248,
            height: widget.autoGrow ? 280 : null,
            child: TapRegion(
              onTapOutside: (_) => _closeDrawer(),
              child: KeyedSubtree(
                key: const Key('prompt-block-drawer-overlay'),
                child: _buildDrawer(context, compact: false),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSegmentList(PromptBlockDocument document) {
    final shrinkWrap = widget.compact || widget.autoGrow;
    return ReorderableListView.builder(
      key: const Key('prompt-block-editor-segments'),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: document.segments.length,
      onReorderItem: (oldIndex, newIndex) =>
          _reorder(document, oldIndex: oldIndex, newIndex: newIndex),
      itemBuilder: (context, index) {
        final segment = document.segments[index];
        final handle = segment is BlockSegment
            ? ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(left: 3, top: 10),
                  child: Icon(
                    Icons.drag_handle,
                    size: 19,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : const SizedBox(width: 22);
        return Container(
          key: ValueKey(_cacheKey(segment.id)),
          margin: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSegment(context, segment)),
              handle,
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(BuildContext context, PromptBlockSegment segment) {
    if (segment is TextSegment) {
      final id = segment.id;
      final controller = _controllers[_cacheKey(id)]!;
      final focusNode = _focusNodes[_cacheKey(id)]!;
      return PromptBlockTextSegment(
        segment: segment,
        controller: controller,
        focusNode: focusNode,
        sessionId: _sessionFor(id),
        config: widget.config,
        decoration: widget.decoration,
        compact: widget.compact,
        autoGrow: widget.autoGrow,
        minLines: widget.minLines,
        enableAssistant: id == _activeTextSegmentId,
        onOpenAssistantSettings: widget.onOpenAssistantSettings,
        onChanged: (text) => _updateText(id, text),
        onCaretChanged: (offset) => _setActiveTextSegment(id, offset),
        onFocusChanged: (focused) {
          if (focused) _setActiveTextSegment(id, _lastOffsets[_cacheKey(id)]);
        },
        onInsertBlock: (offset, data) => _insertDraggedBlock(id, offset, data),
        onComfyuiImport: widget.onComfyuiImport == null
            ? null
            : (globalPrompt, characters) =>
                  _handleComfyuiImport(globalPrompt, characters),
      );
    }
    final block = segment as BlockSegment;
    return PromptBlockChip(
      segment: block,
      onToggleEnabled: () => _toggleBlock(block.id),
      onDelete: () => _removeSegment(block.id),
      onExpand: () => _expandBlock(block.id),
    );
  }

  Widget _buildDrawer(BuildContext context, {required bool compact}) {
    return PromptBlockDrawer(
      compact: compact,
      onClose: compact ? () => Navigator.of(context).pop() : _closeDrawer,
      onInsertBlock: (block) =>
          _insertFromDrawer(context, block, compact: compact),
    );
  }

  void _toggleDrawer() {
    setState(() => _drawerExpanded = !_drawerExpanded);
  }

  void _closeDrawer() {
    if (!mounted || !_drawerExpanded) return;
    setState(() => _drawerExpanded = false);
  }

  NaiSyntaxController _createController(TextSegment segment) {
    final lane = widget.lane;
    final segmentId = segment.id;
    final controller = NaiSyntaxController(
      text: segment.text,
      highlightEnabled: widget.config.enableSyntaxHighlight,
      numericEmphasisEnabled: widget.config.numericEmphasisEnabled,
    );
    controller.addListener(
      () => _onCachedControllerChanged(lane, segmentId, controller),
    );
    return controller;
  }

  void _onCachedControllerChanged(
    PromptBlockLane lane,
    String segmentId,
    NaiSyntaxController controller,
  ) {
    if (!mounted) return;
    final document = ref.read(_workspace).documentFor(lane);
    final segment = document.segments
        .where((item) => item.id == segmentId)
        .firstOrNull;
    if (segment is! TextSegment || segment.text == controller.text) return;

    _syncing = true;
    try {
      ref
          .read(_workspace.notifier)
          .updateText(lane, segmentId: segmentId, text: controller.text);
      _emitProjection(lane);
    } finally {
      _syncing = false;
    }
  }

  void _syncCaches(PromptBlockDocument document) {
    final liveTextKeys = <String>{};
    for (final segment in document.segments) {
      if (segment is! TextSegment) continue;
      final key = _cacheKey(segment.id);
      liveTextKeys.add(key);
      final controller = _controllers.putIfAbsent(
        key,
        () => _createController(segment),
      );
      controller.highlightEnabled = widget.config.enableSyntaxHighlight;
      controller.numericEmphasisEnabled = widget.config.numericEmphasisEnabled;
      if (controller.text != segment.text) {
        final oldSelection = controller.selection;
        final offset = oldSelection.isValid
            ? oldSelection.baseOffset.clamp(0, segment.text.length)
            : segment.text.length;
        controller.value = TextEditingValue(
          text: segment.text,
          selection: TextSelection.collapsed(offset: offset),
        );
      }
      _focusNodes.putIfAbsent(key, FocusNode.new);
      _lastOffsets[key] = (_lastOffsets[key] ?? controller.text.length).clamp(
        0,
        controller.text.length,
      );
    }

    final staleKeys = _controllers.keys
        .where((key) => !liveTextKeys.contains(key))
        .toList();
    for (final key in staleKeys) {
      _controllers.remove(key)?.dispose();
      _focusNodes.remove(key)?.dispose();
      _lastOffsets.remove(key);
    }

    final activeExists = document.segments.any(
      (segment) => segment is TextSegment && segment.id == _activeTextSegmentId,
    );
    if (!activeExists) {
      _activeTextSegmentId = document.segments
          .whereType<TextSegment>()
          .firstOrNull
          ?.id;
    }
  }

  void _updateText(String segmentId, String text) {
    if (_syncing) return;
    final document = ref.read(_workspace).documentFor(widget.lane);
    final segment = document.segments
        .where((item) => item.id == segmentId)
        .firstOrNull;
    if (segment is! TextSegment || segment.text == text) return;

    _syncing = true;
    try {
      ref
          .read(_workspace.notifier)
          .updateText(widget.lane, segmentId: segmentId, text: text);
      _emitProjection();
    } finally {
      _syncing = false;
    }
  }

  void _insertDraggedBlock(
    String textSegmentId,
    int offset,
    PromptBlockDragData data,
  ) {
    final block = ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(data.blockId);
    if (block == null) return;
    _insertAt(textSegmentId, offset, block);
  }

  void _insertFromDrawer(
    BuildContext context,
    PromptBlock block, {
    required bool compact,
  }) {
    final document = ref.read(_workspace).documentFor(widget.lane);
    final textSegments = document.segments.whereType<TextSegment>().toList();
    if (textSegments.isEmpty) return;

    final focused = textSegments.where((segment) {
      return _focusNodes[_cacheKey(segment.id)]?.hasFocus ?? false;
    }).firstOrNull;
    final segment =
        focused ??
        textSegments.firstWhere(
          (item) => item.id == _activeTextSegmentId,
          orElse: () => textSegments.first,
        );
    final key = _cacheKey(segment.id);
    final offset = (_lastOffsets[key] ?? _controllers[key]!.text.length).clamp(
      0,
      segment.text.length,
    );
    _insertAt(segment.id, offset, block);
    if (compact && context.mounted) Navigator.of(context).pop();
  }

  void _insertAt(String textSegmentId, int offset, PromptBlock block) {
    final before = ref.read(_workspace).documentFor(widget.lane);
    final beforeIds = before.segments.map((segment) => segment.id).toSet();
    ref
        .read(_workspace.notifier)
        .insertBlockAtTextOffset(
          widget.lane,
          textSegmentId: textSegmentId,
          offset: offset,
          block: block,
        );
    final after = ref.read(_workspace).documentFor(widget.lane);
    _emitProjection();

    final newBlockIndex = after.segments.indexWhere(
      (segment) => segment is BlockSegment && !beforeIds.contains(segment.id),
    );
    if (newBlockIndex < 0) return;
    final nextText = newBlockIndex + 1 < after.segments.length
        ? after.segments[newBlockIndex + 1]
        : null;
    final previousText = newBlockIndex > 0
        ? after.segments[newBlockIndex - 1]
        : null;
    final target = nextText is TextSegment
        ? nextText
        : previousText is TextSegment
        ? previousText
        : null;
    if (target == null) return;

    final targetKey = _cacheKey(target.id);
    final targetOffset = identical(target, nextText) ? 0 : target.text.length;
    _activeTextSegmentId = target.id;
    _lastOffsets[targetKey] = targetOffset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _controllers[targetKey];
      final focusNode = _focusNodes[targetKey];
      if (controller == null || focusNode == null) return;
      focusNode.requestFocus();
      controller.selection = TextSelection.collapsed(
        offset: targetOffset.clamp(0, controller.text.length),
      );
    });
  }

  void _toggleBlock(String segmentId) {
    ref
        .read(_workspace.notifier)
        .toggleBlockEnabled(widget.lane, segmentId: segmentId);
    _emitProjection();
  }

  void _removeSegment(String segmentId) {
    ref
        .read(_workspace.notifier)
        .removeSegment(widget.lane, segmentId: segmentId);
    _emitProjection();
  }

  void _expandBlock(String segmentId) {
    ref
        .read(_workspace.notifier)
        .expandBlock(widget.lane, segmentId: segmentId);
    _emitProjection();
  }

  void _reorder(
    PromptBlockDocument document, {
    required int oldIndex,
    required int newIndex,
  }) {
    final orderedIds = document.segments.map((segment) => segment.id).toList();
    final moved = orderedIds.removeAt(oldIndex);
    orderedIds.insert(newIndex, moved);
    ref.read(_workspace.notifier).reorderSegments(widget.lane, orderedIds);
    _emitProjection();
  }

  void _handleComfyuiImport(
    String globalPrompt,
    List<CharacterPrompt> characters,
  ) {
    ref.read(_workspace.notifier).replacePlainText(widget.lane, globalPrompt);
    _emitProjection();
    widget.onComfyuiImport?.call(globalPrompt, characters);
  }

  void _emitProjection([PromptBlockLane? lane]) {
    widget.onChanged?.call(
      ref.read(_workspace.notifier).plainTextFor(lane ?? widget.lane),
    );
  }

  void _setActiveTextSegment(String id, int? offset) {
    final changed = _activeTextSegmentId != id;
    _activeTextSegmentId = id;
    if (offset != null) _lastOffsets[_cacheKey(id)] = offset;
    if (!changed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _activeTextSegmentId == id) setState(() {});
    });
  }

  void _showDrawerModal(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height;
    final drawerHeight = (availableHeight * 0.65).clamp(240.0, 480.0);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 420,
          height: drawerHeight,
          child: _buildDrawer(dialogContext, compact: true),
        ),
      ),
    );
  }

  String _cacheKey(String segmentId) => '${widget.lane.name}:$segmentId';

  String _sessionFor(String segmentId) {
    final base = widget.sessionId?.trim();
    final session = base == null || base.isEmpty ? 'prompt' : base;
    final document = ref.read(_workspace).documentFor(widget.lane);
    if (document.segments.length == 1 &&
        document.segments.single is TextSegment) {
      return session;
    }
    return '$session:${widget.lane.name}:$segmentId';
  }
}
