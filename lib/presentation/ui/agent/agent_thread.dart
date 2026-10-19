import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_preview_image.dart';
import '../kit/ui_text.dart';
import 'agent_cards.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_scope.dart';

/// 对话页：每轮 = 左侧黑线的用户句 + 一张任务卡；最后是待处理卡片。
/// 内容从上往下排；停在底部时跟随最新内容，往上翻就停止跟随，右下角出现
/// 向下箭头，点一下回到底部并恢复跟随。
class AgentThread extends StatefulWidget {
  const AgentThread({super.key});

  /// 离底部多少像素以内算“在底部”。
  static const followSlack = 24.0;

  @override
  State<AgentThread> createState() => _AgentThreadState();
}

class _AgentThreadState extends State<AgentThread> {
  final _scroll = ScrollController();
  var _follow = true;
  var _away = false;
  var _fresh = false;
  var _auto = false;
  var _jumpQueued = false;
  int? _revision;
  String? _chat;

  bool get _atBottom =>
      !_scroll.hasClients ||
      _scroll.position.maxScrollExtent - _scroll.offset <=
          AgentThread.followSlack;

  void _syncAway() {
    final away = !_atBottom;
    if (away != _away || (!away && _fresh)) {
      setState(() {
        _away = away;
        if (!away) _fresh = false;
      });
    }
  }

  void _queueJump() {
    if (_jumpQueued) return;
    _jumpQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpQueued = false;
      if (!mounted || !_follow || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (_scroll.offset != max) {
        _auto = true;
        _scroll.jumpTo(max);
        _auto = false;
      }
      _syncAway();
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    // 用户自己滚（拖动、滚轮、拖滚动条）才改跟随状态；程序跳底不算。
    if (n is ScrollUpdateNotification && !_auto) _follow = _atBottom;
    _syncAway();
    return false;
  }

  bool _onMetrics(ScrollMetricsNotification n) {
    if (n.depth != 0) return false;
    // 内容变高（新消息、流式文字、卡片展开）：跟随中就贴到底。
    if (_follow) {
      _queueJump();
    } else {
      _syncAway();
    }
    return false;
  }

  Future<void> _jumpToLatest() async {
    if (!_scroll.hasClients) return;
    setState(() => _follow = true);
    _auto = true;
    try {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _auto = false;
    }
    // 动画期间可能又来了内容。
    _queueJump();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final d = AgentScope.of(context).data;
    final r = d.revision;
    if (_chat != null && d.chat.id != _chat) {
      // 换了聊天：从最新处开始看。
      _follow = true;
      _fresh = false;
      _queueJump();
    }
    _chat = d.chat.id;
    if (_revision != null && r != _revision) {
      if (_follow) {
        _queueJump();
      } else {
        _fresh = true;
      }
    }
    _revision = r;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data;
    final c = context.ui;
    final items = <Widget>[
      for (final (i, turn) in d.thread.indexed)
        _Turn(
          key: ValueKey('turn-${turn.id}'),
          turn: turn,
          last: i == d.thread.length - 1,
        ),
      for (final p in d.composer.pending)
        AgentPendingCard(key: ValueKey('pending-${p.id}'), pending: p),
      if (d.error != null) _ErrorLine(d.error!),
    ];
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: SelectionArea(
                child: ListView.builder(
                  key: const Key('agent-thread'),
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  itemCount: items.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
                    child: items[i],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_away)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Tooltip(
                message: context.l10n.ag_newContent,
                waitDuration: const Duration(milliseconds: 400),
                child: Material(
                  key: const Key('agent-jump-latest'),
                  color: _fresh ? c.accent : c.bg,
                  shape: CircleBorder(
                    side: BorderSide(color: _fresh ? c.accent : c.border),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _jumpToLatest,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: AgentIcon(
                          AgentGlyphs.chevron,
                          size: 16,
                          color: _fresh ? c.bg : c.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('agent-error'),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.error.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AgentIcon(AgentGlyphs.alert, size: 14, color: c.error),
          ),
          Expanded(
            child: Text(
              text,
              style: UiText.sans(12.5, color: c.ink, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _Turn extends StatelessWidget {
  const _Turn({super.key, required this.turn, required this.last});
  final AgentTurn turn;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final reply = turn.reply;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        _UserLine(message: turn.user),
        if (reply != null && (reply.blocks.isNotEmpty || reply.live))
          _TaskCard(reply: reply, last: last),
      ],
    );
  }
}

/// 用户这一句：左侧 2px 墨线，眉题「你 · 16:40」，悬停出现复制 / 编辑。
class _UserLine extends StatefulWidget {
  const _UserLine({required this.message});
  final AgentUserMessage message;

  @override
  State<_UserLine> createState() => _UserLineState();
}

class _UserLineState extends State<_UserLine> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final m = widget.message;
    final c = context.ui;
    final l = context.l10n;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 2, 4, 0),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.ink, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            SizedBox(
              height: 18,
              child: Row(
                spacing: 6,
                children: [
                  AgentEyebrow(l.ag_you, color: c.ink),
                  Text(
                    agentClock(m.at),
                    style: UiText.mono(11, color: c.faint, height: 1),
                  ),
                  const Spacer(),
                  if (_hover) ...[
                    AgentIconButton(
                      small: true,
                      glyph: AgentGlyphs.copy,
                      tooltip: l.ag_copy,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: m.text));
                        s.toast(l.ag_copied);
                      },
                    ),
                    if (m.entryId != null &&
                        s.data.status == AgentRunStatus.idle)
                      AgentIconButton(
                        small: true,
                        glyph: AgentGlyphs.pen,
                        tooltip: l.ag_edit,
                        onPressed: () =>
                            s.run(() => s.actions.onEditMessage(m.entryId!)),
                      ),
                  ],
                ],
              ),
            ),
            if (m.text.isNotEmpty)
              Text(
                m.text,
                style: UiText.sans(
                  13.5,
                  weight: FontWeight.w500,
                  color: c.ink,
                  height: 1.6,
                ),
              ),
            if (m.images.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final img in m.images)
                    AgentThumb(image: img, width: 72, height: 72),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 任务卡：步骤清单 / 结论 / 提示词改动 / 本次产物，各占一节。
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.reply, required this.last});
  final AgentReply reply;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final l = context.l10n;
    final c = context.ui;
    final sections = <Widget>[];
    for (final b in reply.blocks) {
      sections.add(switch (b) {
        AgentTextBlock(:final markdown) => AgentMarkdown(markdown),
        AgentThinkingBlock() => AgentThinking(block: b),
        AgentStepsBlock(:final steps) => AgentSteps(steps: steps),
        AgentDiffBlock(:final diff) => AgentDiffView(diff: diff),
        AgentImagesBlock() => AgentOutputs(block: b),
      });
    }
    if (reply.live) sections.add(_LiveLine(status: s.data.status));
    return AgentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in sections.indexed)
            AgentSection(
              first: i == 0,
              padding: switch (w) {
                _LiveLine() => const EdgeInsets.fromLTRB(14, 9, 14, 9),
                // 步骤行自带 6px 内边距（悬停底色外扩）。
                AgentSteps() ||
                AgentThinking() => const EdgeInsets.fromLTRB(8, 9, 8, 9),
                _ => const EdgeInsets.fromLTRB(14, 12, 14, 12),
              },
              child: w,
            ),
          if (reply.canRegenerate && last)
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  AgentButton(
                    key: const Key('agent-regenerate'),
                    label: l.ag_regenerate,
                    glyph: AgentGlyphs.refresh,
                    style: AgentButtonStyle.ghost,
                    height: 24,
                    onPressed: () => s.run(s.actions.onRegenerate),
                  ),
                  const Spacer(),
                  AgentIconButton(
                    small: true,
                    glyph: AgentGlyphs.copy,
                    tooltip: l.ag_copy,
                    onPressed: () async {
                      final text = reply.blocks
                          .whereType<AgentTextBlock>()
                          .map((b) => b.markdown)
                          .join('\n\n');
                      await Clipboard.setData(ClipboardData(text: text));
                      s.toast(l.ag_copied);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveLine extends StatelessWidget {
  const _LiveLine({required this.status});
  final AgentRunStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final waiting = status == AgentRunStatus.waitingUser;
    return Row(
      key: const Key('agent-live'),
      spacing: 8,
      children: [
        AgentStepDot(
          kind: waiting ? AgentDotKind.waiting : AgentDotKind.running,
        ),
        Text(
          switch (status) {
            AgentRunStatus.starting => l.ag_starting,
            AgentRunStatus.waitingSlot => l.ag_waitingSlot,
            AgentRunStatus.waitingUser => l.ag_waitingYou,
            _ => l.ag_thinking,
          },
          style: UiText.sans(
            12,
            color: waiting ? c.warn : c.muted,
            weight: waiting ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Markdown 正文：13.5 / 1.72，可选中，链接交给转接层。
class AgentMarkdown extends StatelessWidget {
  const AgentMarkdown(this.markdown, {super.key});
  final String markdown;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final body = UiText.sans(13.5, color: c.ink, height: 1.72);
    return MarkdownBody(
      data: markdown,
      styleSheet: MarkdownStyleSheet(
        p: body,
        a: body.copyWith(
          color: c.accent,
          decoration: TextDecoration.underline,
          decorationColor: c.accent.withValues(alpha: .4),
        ),
        strong: body.copyWith(fontWeight: FontWeight.w600),
        em: body.copyWith(fontStyle: FontStyle.italic),
        h1: UiText.sans(16, weight: FontWeight.w600, color: c.ink, height: 1.5),
        h2: UiText.sans(15, weight: FontWeight.w600, color: c.ink, height: 1.5),
        h3: UiText.sans(14, weight: FontWeight.w600, color: c.ink, height: 1.5),
        h4: body.copyWith(fontWeight: FontWeight.w600),
        listBullet: body.copyWith(color: c.muted),
        blockquote: body.copyWith(color: c.muted),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.border, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: 10),
        code: UiText.mono(
          12,
          color: c.ink,
        ).copyWith(backgroundColor: c.control),
        codeblockPadding: const EdgeInsets.all(10),
        codeblockDecoration: BoxDecoration(
          color: agentSunk(c),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.line),
        ),
        tableBody: UiText.sans(12.5, color: c.ink),
        tableHead: UiText.sans(12.5, weight: FontWeight.w600, color: c.ink),
        tableBorder: TableBorder.all(color: c.border),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        pPadding: EdgeInsets.zero,
        blockSpacing: 8,
      ),
      imageBuilder: (uri, title, alt) => Tooltip(
        message: uri.toString(),
        child: AgentIcon(AgentGlyphs.image, size: 16, color: c.faint),
      ),
      onTapLink: (_, href, _) {
        if (href != null) s.actions.onOpenLink(href);
      },
    );
  }
}

// ─────────────────────────────── 步骤 ───────────────────────────────

/// 步骤清单：状态圈 + 动作名 + 等宽工具名 + 右侧耗时；点一行展开参数 / 结果。超过 6 步折叠。
/// 思考内容：默认一行“已思考 · N 字”，点开看原文；流式中显示“思考中”。
class AgentThinking extends StatefulWidget {
  const AgentThinking({super.key, required this.block});
  final AgentThinkingBlock block;

  @override
  State<AgentThinking> createState() => _AgentThinkingState();
}

class _AgentThinkingState extends State<AgentThinking> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final b = widget.block;
    final chars = b.text.runes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepRow(
          key: const Key('agent-thinking'),
          dot: AgentStepDot(
            kind: b.live ? AgentDotKind.running : AgentDotKind.done,
          ),
          label: b.live ? l.ag_thinkingLive : l.ag_thought,
          subject: chars == 0 ? null : l.ag_thoughtChars(chars),
          muted: true,
          open: _open,
          onTap: b.text.isEmpty ? null : () => setState(() => _open = !_open),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(31, 2, 6, 6),
            child: Container(
              key: const Key('agent-thinking-text'),
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: agentSunk(c),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.line),
              ),
              child: SingleChildScrollView(
                child: Text(
                  b.text,
                  style: UiText.sans(12, color: c.muted, height: 1.6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AgentSteps extends StatefulWidget {
  const AgentSteps({super.key, required this.steps});
  final List<AgentStep> steps;

  @override
  State<AgentSteps> createState() => _AgentStepsState();
}

class _AgentStepsState extends State<AgentSteps> {
  static const _limit = 6;
  var _all = false;
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = widget.steps;
    // 折叠时保留最后几步（正在进行 / 等你处理的总在最后）。
    final hidden = !_all && steps.length > _limit
        ? steps.length - (_limit - 1)
        : 0;
    final shown = hidden > 0 ? steps.sublist(hidden) : steps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        if (hidden > 0)
          _StepRow(
            key: const Key('agent-steps-more'),
            dot: const AgentStepDot(kind: AgentDotKind.done),
            label: l.ag_stepsMore(hidden),
            muted: true,
            onTap: () => setState(() => _all = true),
          ),
        for (final step in shown) ...[
          _StepRow(
            key: Key('agent-step-${step.id}'),
            dot: AgentStepDot(
              kind: switch (step.status) {
                AgentStepStatus.done => AgentDotKind.done,
                AgentStepStatus.running => AgentDotKind.running,
                AgentStepStatus.failed => AgentDotKind.failed,
                AgentStepStatus.waitingUser => AgentDotKind.waiting,
              },
            ),
            label: agentToolLabel(l, step.tool),
            subject: step.subject,
            tool: step.tool,
            trailing: switch (step.status) {
              AgentStepStatus.running => l.ag_stepRunning,
              AgentStepStatus.failed => l.ag_stepFailed,
              _ => step.duration == null ? null : agentDuration(step.duration!),
            },
            strong: step.status == AgentStepStatus.waitingUser,
            error: step.status == AgentStepStatus.failed,
            open: _open.contains(step.id),
            onTap:
                step.arguments == null &&
                    step.result == null &&
                    step.images.isEmpty
                ? null
                : () => setState(
                    () => _open.contains(step.id)
                        ? _open.remove(step.id)
                        : _open.add(step.id),
                  ),
          ),
          if (_open.contains(step.id)) _StepDetail(step: step),
        ],
      ],
    );
  }
}

class _StepRow extends StatefulWidget {
  const _StepRow({
    super.key,
    required this.dot,
    required this.label,
    this.subject,
    this.tool,
    this.trailing,
    this.strong = false,
    this.muted = false,
    this.error = false,
    this.open = false,
    this.onTap,
  });
  final Widget dot;
  final String label;
  final String? subject, tool, trailing;
  final bool strong, muted, error, open;
  final VoidCallback? onTap;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final showTool =
        widget.tool != null &&
        agentToolLabel(context.l10n, widget.tool!) != widget.tool;
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: _hover && widget.onTap != null ? c.hover : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            spacing: 9,
            children: [
              widget.dot,
              Expanded(
                child: Row(
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: widget.label),
                            if (widget.subject != null)
                              TextSpan(
                                text: ' ${widget.subject}',
                                style: TextStyle(color: c.muted),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          12.5,
                          weight: widget.strong
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: widget.muted
                              ? c.muted
                              : widget.error
                              ? c.error
                              : c.ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (showTool)
                      Flexible(
                        child: Text(
                          widget.tool!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.mono(11, color: c.faint, height: 1),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null)
                Text(
                  widget.trailing!,
                  style: UiText.mono(
                    11,
                    color: widget.error ? c.error : c.faint,
                    height: 1,
                  ),
                ),
              if (widget.onTap != null && (_hover || widget.open))
                AnimatedRotation(
                  turns: widget.open ? .5 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: AgentIcon(
                    AgentGlyphs.chevron,
                    size: 12,
                    color: c.faint,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDetail extends StatelessWidget {
  const _StepDetail({required this.step});
  final AgentStep step;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    Widget block(String title, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        AgentEyebrow(title),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
          decoration: BoxDecoration(
            color: agentSunk(c),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.line),
          ),
          child: SingleChildScrollView(
            child: Text(
              text,
              style: UiText.mono(11, color: c.muted, height: 1.55),
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(31, 2, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (step.arguments != null)
            block(l.ag_stepArguments, step.arguments!),
          if (step.result != null) block(l.ag_stepResult, step.result!),
          if (step.images.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final img in step.images)
                  AgentThumb(image: img, width: 64, height: 64),
              ],
            ),
        ],
      ),
    );
  }
}

/// 工具名 → 动作名；未知工具（外部 MCP）返回原名。
String agentToolLabel(AppLocalizations l, String tool) => switch (tool) {
  'studio_context' => l.ag_tool_studio_context,
  'image_read' => l.ag_tool_image_read,
  'prompt_update' => l.ag_tool_prompt_update,
  'snapshot' => l.ag_tool_snapshot,
  'wiki_query' => l.ag_tool_wiki_query,
  'tag_query' => l.ag_tool_tag_query,
  'block_query' => l.ag_tool_block_query,
  'block_manage' => l.ag_tool_block_manage,
  'settings_read' => l.ag_tool_settings_read,
  'settings_update' => l.ag_tool_settings_update,
  'explore_manage' => l.ag_tool_explore_manage,
  'generation_prepare' => l.ag_tool_generation_prepare,
  'generation_run' => l.ag_tool_generation_run,
  'generation_cancel' => l.ag_tool_generation_cancel,
  'gallery_query' => l.ag_tool_gallery_query,
  'gallery_manage' => l.ag_tool_gallery_manage,
  'reference_manage' => l.ag_tool_reference_manage,
  'reference_library' => l.ag_tool_reference_library,
  'image_tool' => l.ag_tool_image_tool,
  'image_generate' => l.ag_tool_image_generate,
  'ask_user' => l.ag_tool_ask_user,
  'read' => l.ag_tool_read,
  'write' => l.ag_tool_write,
  'edit' => l.ag_tool_edit,
  'bash' => l.ag_tool_bash,
  _ => tool,
};

// ─────────────────────────────── 提示词改动 ───────────────────────────────

class AgentDiffView extends StatelessWidget {
  const AgentDiffView({super.key, required this.diff});
  final AgentPromptDiff diff;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    int count(AgentDiffKind k) => diff.segments
        .where((x) => x.kind == k)
        .fold(
          0,
          (n, x) =>
              n + x.text.split(',').where((t) => t.trim().isNotEmpty).length,
        );
    final field = switch (diff.field) {
      AgentPromptField.prompt => l.ag_field_prompt,
      AgentPromptField.negative => l.ag_field_negative,
      AgentPromptField.character => diff.label ?? l.ag_field_character,
      AgentPromptField.characterNegative =>
        diff.label == null
            ? l.ag_field_characterNegative
            : '${diff.label} · ${l.ag_field_characterNegative}',
    };
    final base = UiText.mono(12, color: c.muted, height: 1.75);
    return Column(
      key: Key('agent-diff-${diff.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            spacing: 6,
            children: [
              // 标题和计数一起占满剩余宽度，状态和撤销贴右边。
              // （Flexible + Spacer 会平分空白，右侧留出一截。）
              Expanded(
                child: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        field,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          12,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                    Text(
                      l.ag_diffCounts(
                        count(AgentDiffKind.added),
                        count(AgentDiffKind.removed),
                      ),
                      style: UiText.mono(11.5, color: c.faint),
                    ),
                  ],
                ),
              ),
              switch (diff.state) {
                AgentDiffState.applied => Row(
                  spacing: 4,
                  children: [
                    AgentIcon(AgentGlyphs.check, size: 14, color: c.ok),
                    Text(l.ag_diffApplied, style: UiText.sans(12, color: c.ok)),
                  ],
                ),
                AgentDiffState.undone => Text(
                  l.ag_diffUndone,
                  style: UiText.sans(12, color: c.faint),
                ),
                AgentDiffState.locked => Tooltip(
                  message: l.ag_diffLocked,
                  child: Row(
                    key: Key('agent-diff-state-${diff.id}'),
                    spacing: 4,
                    children: [
                      AgentIcon(AgentGlyphs.check, size: 14, color: c.faint),
                      Text(
                        l.ag_diffApplied,
                        style: UiText.sans(12, color: c.faint),
                      ),
                    ],
                  ),
                ),
              },
              if (diff.state == AgentDiffState.applied)
                AgentButton(
                  key: Key('agent-diff-undo-${diff.id}'),
                  label: l.ag_diffUndo,
                  glyph: AgentGlyphs.undo,
                  style: AgentButtonStyle.ghost,
                  height: 24,
                  onPressed: () => s.run(() => s.actions.onUndoDiff(diff.id)),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
          decoration: BoxDecoration(
            color: agentSunk(c),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: c.line),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                for (final seg in diff.segments)
                  TextSpan(
                    text: seg.text,
                    style: switch (seg.kind) {
                      AgentDiffKind.same => null,
                      AgentDiffKind.added => TextStyle(
                        color: c.ok,
                        backgroundColor: c.ok.withValues(alpha: .13),
                      ),
                      AgentDiffKind.removed => TextStyle(
                        color: c.error,
                        backgroundColor: c.error.withValues(alpha: .09),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: c.error,
                      ),
                    },
                  ),
              ],
            ),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: diff.state == AgentDiffState.undone
                ? base.copyWith(color: c.faint)
                : base,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── 产物 ───────────────────────────────

class AgentOutputs extends StatelessWidget {
  const AgentOutputs({super.key, required this.block});
  final AgentImagesBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final expected = block.expected;
    final waiting = expected == null
        ? 0
        : (expected - block.images.length).clamp(0, 99);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 6,
          children: [
            Text(
              l.ag_outputs,
              style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
            ),
            if (expected != null)
              Text(
                '${block.images.length} / $expected',
                style: UiText.mono(11.5, color: c.faint),
              ),
            const Spacer(),
            if (block.anlasSpent != null)
              Text(
                l.ag_anlasSpent(agentNumber(block.anlasSpent!)),
                style: UiText.sans(11, color: c.faint),
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) {
            const gap = 6.0;
            final cols = box.maxWidth < 300 ? 3 : 4;
            final w = (box.maxWidth - gap * (cols - 1)) / cols;
            double h(AgentImage? i) =>
                i?.width != null && i?.height != null && i!.width! > 0
                ? w * i.height! / i.width!
                : w * 1216 / 832;
            final ratio = block.images.isEmpty
                ? w * 1216 / 832
                : h(block.images.first);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final img in block.images)
                  AgentThumb(
                    image: img,
                    width: w,
                    height: ratio.clamp(w * .5, w * 2),
                    badge: true,
                  ),
                for (var i = 0; i < waiting; i++)
                  Container(
                    width: w,
                    height: ratio.clamp(w * .5, w * 2),
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const AgentStepDot(kind: AgentDotKind.running),
                  ),
              ],
            );
          },
        ),
        if (expected != null && expected > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: block.images.length / expected,
              minHeight: 3,
              backgroundColor: c.control,
              color: c.accent,
            ),
          ),
      ],
    );
  }
}

/// 一张缩略图：点放大、右键菜单（放大 / 附到输入框 / 在历史中显示）、可拖出。
class AgentThumb extends StatefulWidget {
  const AgentThumb({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    this.badge = false,
    this.source,
  });
  final AgentImage image;
  final double width, height;

  /// 显示左下角编号 / 星标。
  final bool badge;

  /// 产物页左上角来源标签。
  final String? source;

  @override
  State<AgentThumb> createState() => _AgentThumbState();
}

class _AgentThumbState extends State<AgentThumb> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final img = widget.image;
    final label = [if (img.starred) '★', ?img.label].join(' ');
    Widget thumb = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => s.zoom(img),
        onSecondaryTapUp: (e) =>
            showAgentImageMenu(context, e.globalPosition, img),
        child: Container(
          key: Key('agent-image-${img.id}'),
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(8),
            border: _hover ? Border.all(color: c.strong) : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              UiPreviewImage(image: img.image),
              if (widget.badge && label.isNotEmpty)
                Positioned(left: 5, bottom: 5, child: _ImageTag(label)),
              if (widget.source != null)
                Positioned(left: 5, top: 5, child: _ImageTag(widget.source!)),
            ],
          ),
        ),
      ),
    );
    final drag = s.slots.imageDrag;
    if (drag != null && img.historyId != null) {
      thumb = drag(context, img, thumb);
    }
    return thumb;
  }
}

class _ImageTag extends StatelessWidget {
  const _ImageTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 16,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0x80000000),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: UiText.mono(
        10,
        weight: FontWeight.w500,
        color: Colors.white,
        height: 1,
      ),
    ),
  );
}

/// 图片右键菜单。
Future<void> showAgentImageMenu(
  BuildContext context,
  Offset at,
  AgentImage img,
) async {
  final s = AgentScope.of(context);
  final l = context.l10n;
  final c = context.ui;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(at);
  PopupMenuItem<String> item(String value, String glyph, String label) =>
      PopupMenuItem(
        value: value,
        height: 34,
        child: Row(
          spacing: 9,
          children: [
            AgentIcon(glyph, size: 14, color: c.muted),
            Text(label, style: UiText.sans(12.5, color: c.ink)),
          ],
        ),
      );
  final picked = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      local.dx,
      local.dy,
      overlay.size.width - local.dx,
      overlay.size.height - local.dy,
    ),
    color: c.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: c.border),
    ),
    items: [
      item('zoom', AgentGlyphs.zoom, l.ag_imageZoom),
      item('attach', AgentGlyphs.clip, l.ag_imageAttach),
      if (img.historyId != null)
        item('reveal', AgentGlyphs.clock, l.ag_imageReveal),
    ],
  );
  switch (picked) {
    case 'zoom':
      s.zoom(img);
    case 'attach':
      await s.run(() => s.actions.onAttachImage(img.id));
    case 'reveal':
      s.actions.onRevealImage(img.id);
  }
}
