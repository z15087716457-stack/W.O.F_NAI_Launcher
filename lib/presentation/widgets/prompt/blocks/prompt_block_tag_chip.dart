import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/prompt_block/prompt_block.dart';
import 'prompt_block_colors.dart';

/// 标签颜色只点在图标、边框与淡底上，文字保持当前主题对比度。
class PromptBlockTagChip extends StatelessWidget {
  const PromptBlockTagChip({
    super.key,
    required this.tag,
    this.onTap,
    this.compact = false,
    this.maxWidth,
  });

  final PromptBlockTag tag;
  final VoidCallback? onTap;
  final bool compact;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = promptBlockColorFromString(tag.color);
    return Tooltip(
      message: tag.name,
      child: Material(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            constraints: maxWidth == null
                ? null
                : BoxConstraints(maxWidth: maxWidth!),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 7,
              vertical: compact ? 2 : 3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: color.withValues(alpha: .42)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: compact ? 10 : 12,
                  color: color,
                ),
                const SizedBox(width: 3),
                if (maxWidth == null)
                  _tagName(theme)
                else
                  Flexible(child: _tagName(theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagName(ThemeData theme) => Text(
    tag.name,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.labelSmall?.copyWith(
      fontSize: compact ? 10 : 11,
      color: theme.colorScheme.onSurface,
    ),
  );
}

/// 实例浮卡标题右侧的标签条：从右侧起排，溢出时竖线分隔、滚轮横移。
class PromptBlockTagStrip extends StatefulWidget {
  const PromptBlockTagStrip({super.key, required this.tags});

  final List<PromptBlockTag> tags;

  @override
  State<PromptBlockTagStrip> createState() => _PromptBlockTagStripState();
}

class _PromptBlockTagStripState extends State<PromptBlockTagStrip> {
  final ScrollController _scrollController = ScrollController();
  bool _overflow = false;

  @override
  void initState() {
    super.initState();
    _scheduleExtentCheck();
  }

  @override
  void didUpdateWidget(covariant PromptBlockTagStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags) _scheduleExtentCheck();
  }

  void _scheduleExtentCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final next = _scrollController.position.maxScrollExtent > 0;
      if (next != _overflow) setState(() => _overflow = next);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_overflow) ...[
          Container(
            key: const Key('block-tag-overflow-divider'),
            width: 1,
            height: 16,
            color: theme.colorScheme.outline.withValues(alpha: .85),
          ),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Listener(
            key: const Key('block-tag-scroll-area'),
            onPointerSignal: (event) {
              if (event is! PointerScrollEvent ||
                  !_scrollController.hasClients) {
                return;
              }
              final delta = event.scrollDelta.dy != 0
                  ? event.scrollDelta.dy
                  : event.scrollDelta.dx;
              final position = _scrollController.position;
              _scrollController.jumpTo(
                (position.pixels + delta).clamp(
                  position.minScrollExtent,
                  position.maxScrollExtent,
                ),
              );
            },
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: _overflow
                    ? const [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ]
                    : const [Colors.white, Colors.white],
                stops: _overflow ? const [0, .08, .92, 1] : null,
              ).createShader(bounds),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final tag in widget.tags.reversed) ...[
                      PromptBlockTagChip(tag: tag, compact: true),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
