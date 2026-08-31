import 'package:flutter/material.dart';

import '../../../../data/models/character/character_prompt.dart';
import '../../../../data/models/prompt_block/prompt_block_segment.dart';
import '../unified/unified_prompt_config.dart';
import '../unified/unified_prompt_input.dart';
import 'prompt_block_drag_data.dart';

/// 工作区中的普通文本段。
///
/// 块拖入位置由文本控制器的 caret/最后有效 offset 决定，
/// 不依赖 RenderEditable 的像素坐标。
class PromptBlockTextSegment extends StatefulWidget {
  const PromptBlockTextSegment({
    super.key,
    required this.segment,
    required this.controller,
    required this.focusNode,
    required this.sessionId,
    required this.config,
    this.decoration,
    this.onChanged,
    this.onOpenAssistantSettings,
    this.onInsertBlock,
    this.onCaretChanged,
    this.onFocusChanged,
    this.onComfyuiImport,
    this.compact = false,
    this.autoGrow = false,
    this.minLines,
    this.enableAssistant = true,
  });

  final TextSegment segment;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String sessionId;
  final UnifiedPromptConfig config;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenAssistantSettings;
  final void Function(int offset, PromptBlockDragData data)? onInsertBlock;
  final ValueChanged<int>? onCaretChanged;
  final ValueChanged<bool>? onFocusChanged;
  final void Function(String globalPrompt, List<CharacterPrompt> characters)?
  onComfyuiImport;
  final bool compact;
  final bool autoGrow;
  final int? minLines;
  final bool enableAssistant;

  @override
  State<PromptBlockTextSegment> createState() => _PromptBlockTextSegmentState();
}

class _PromptBlockTextSegmentState extends State<PromptBlockTextSegment> {
  late int _lastValidOffset;

  @override
  void initState() {
    super.initState();
    _lastValidOffset = _validOffset(widget.controller.selection);
    widget.controller.addListener(_handleControllerChanged);
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(PromptBlockTextSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _lastValidOffset = _validOffset(widget.controller.selection);
      widget.controller.addListener(_handleControllerChanged);
    }
    if (!identical(oldWidget.focusNode, widget.focusNode)) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<PromptBlockDragData>(
      key: ValueKey('prompt-block-text-segment-${widget.segment.id}'),
      onWillAcceptWithDetails: (details) => widget.onInsertBlock != null,
      onAcceptWithDetails: (details) {
        widget.onInsertBlock?.call(_lastValidOffset, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final child = UnifiedPromptInput(
          key: ValueKey('prompt-block-text-input-${widget.segment.id}'),
          controller: widget.controller,
          focusNode: widget.focusNode,
          sessionId: widget.sessionId,
          config: widget.config,
          decoration: widget.decoration,
          onChanged: widget.onChanged,
          onOpenAssistantSettings: widget.onOpenAssistantSettings,
          enableAssistant: widget.enableAssistant,
          onComfyuiImport: widget.onComfyuiImport,
          maxLines: widget.compact ? 2 : null,
          minLines: widget.minLines ?? (widget.compact ? 1 : 2),
          expands: false,
          fitContent: true,
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: highlighted
                ? Border.all(color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          child: child,
        );
      },
    );
  }

  void _handleControllerChanged() {
    final offset = _validOffset(widget.controller.selection);
    _lastValidOffset = offset;
    widget.onCaretChanged?.call(offset);
  }

  void _handleFocusChanged() {
    widget.onFocusChanged?.call(widget.focusNode.hasFocus);
  }

  int _validOffset(TextSelection selection) {
    if (selection.isValid && selection.extentOffset >= 0) {
      return selection.extentOffset.clamp(0, widget.controller.text.length);
    }
    return widget.controller.text.length;
  }
}
