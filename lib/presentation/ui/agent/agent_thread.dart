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
      if (d.error != null)
        _ErrorLine(
          d.error!,
          onRetry: d.status == AgentRunStatus.idle && d.thread.isNotEmpty
              ? () => s.run(s.actions.onRegenerate)
              : null,
        ),
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
  const _ErrorLine(this.text, {this.onRetry});
  final String text;

  /// 非 null 时右侧给「重试」（重新回答最后一轮）。
  final VoidCallback? onRetry;

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
          if (onRetry != null)
            AgentButton(
              key: const Key('agent-error-retry'),
              label: context.l10n.ag_retry,
              glyph: AgentGlyphs.refresh,
              style: AgentButtonStyle.ghost,
              height: 24,
              onPressed: onRetry,
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
        AgentPositionBlock() => AgentPositionView(block: b),
        AgentParamBlock() => AgentParamView(block: b),
        AgentChangeSummaryBlock() => AgentChangeSummaryView(block: b),
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
  'studio_search' => l.ag_tool_studio_search,
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
    // 角色没起名时用「角色 N」，免得标题空着或只剩「· 角色负面」。
    final who = (diff.label?.trim().isNotEmpty ?? false)
        ? diff.label!.trim()
        : diff.characterIndex == null
        ? null
        : l.gen_characterN(diff.characterIndex! + 1);
    final field = switch (diff.field) {
      AgentPromptField.prompt => l.ag_field_prompt,
      AgentPromptField.negative => l.ag_field_negative,
      AgentPromptField.character => who ?? l.ag_field_character,
      AgentPromptField.characterNegative =>
        who == null
            ? l.ag_field_characterNegative
            : '$who · ${l.ag_field_characterNegative}',
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
              _DiffStatus(
                id: diff.id,
                state: diff.state,
                onUndo: () => s.actions.onUndoDiff(diff.id),
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

// ─────────────────────────────── 参数改动 ───────────────────────────────

/// 改动卡右上角：已写入 / 已撤销 / 已写入（灰，草稿已变）+ 撤销按钮。
class _DiffStatus extends StatelessWidget {
  const _DiffStatus({
    required this.id,
    required this.state,
    required this.onUndo,
    this.undoLabel,
  });
  final String id;
  final AgentDiffState state;
  final Future<bool> Function() onUndo;
  final String? undoLabel;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        switch (state) {
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
              key: Key('agent-diff-state-$id'),
              spacing: 4,
              children: [
                AgentIcon(AgentGlyphs.check, size: 14, color: c.faint),
                Text(l.ag_diffApplied, style: UiText.sans(12, color: c.faint)),
              ],
            ),
          ),
        },
        if (state == AgentDiffState.applied)
          AgentButton(
            key: Key('agent-diff-undo-$id'),
            label: undoLabel ?? l.ag_diffUndo,
            glyph: AgentGlyphs.undo,
            style: AgentButtonStyle.ghost,
            height: 24,
            onPressed: () => s.run(onUndo),
          ),
      ],
    );
  }
}

/// 一次改动出了几张卡时的汇总行：「本次改动 · 5 处  +21 −7」+ 全部撤销。
class AgentChangeSummaryView extends StatelessWidget {
  const AgentChangeSummaryView({super.key, required this.block});
  final AgentChangeSummaryBlock block;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    return SizedBox(
      key: Key('agent-change-${block.id}'),
      height: 24,
      child: Row(
        spacing: 6,
        children: [
          AgentIcon(AgentGlyphs.pen, size: 14, color: c.muted),
          Expanded(
            child: Row(
              spacing: 6,
              children: [
                Flexible(
                  child: Text(
                    l.ag_changeSummary(block.ids.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
                if (block.added + block.removed > 0)
                  Text(
                    l.ag_diffCounts(block.added, block.removed),
                    style: UiText.mono(11.5, color: c.faint),
                  ),
              ],
            ),
          ),
          _DiffStatus(
            id: block.id,
            state: block.state,
            undoLabel: l.ag_diffUndoAll,
            onUndo: () => s.actions.onUndoDiffs(block.ids),
          ),
        ],
      ),
    );
  }
}

/// 生图参数改动卡：每行「名称  旧值 → 新值」，整张一起撤销。
class AgentParamView extends StatelessWidget {
  const AgentParamView({super.key, required this.block});
  final AgentParamBlock block;

  static String label(AppLocalizations l, AgentParam p) => switch (p) {
    AgentParam.model => l.generation_model,
    AgentParam.size => l.ag_paramSize,
    AgentParam.steps => l.gen_steps,
    AgentParam.guidance => l.gen_guidance,
    AgentParam.rescale => l.gen_cfgRescale,
    AgentParam.sampler => l.gen_sampler,
    AgentParam.noiseSchedule => l.gen_noiseSchedule,
    AgentParam.seed => l.gen_seed,
    AgentParam.count => l.gen_count,
    AgentParam.variety => 'Variety+',
    AgentParam.smea => 'SMEA',
    AgentParam.qualityPreset => l.gen_qualityPreset,
    AgentParam.ucPreset => l.gen_ucPreset,
    AgentParam.transparent => l.ag_paramTransparent,
  };

  static String value(AppLocalizations l, AgentParamValue v) =>
      v.text ??
      switch (v.word!) {
        AgentParamWord.random => l.gen_random,
        AgentParamWord.on => l.set_on,
        AgentParamWord.off => l.set_off,
        AgentParamWord.none => l.ag_paramNone,
      };

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    final undone = block.state == AgentDiffState.undone;
    final old = UiText.mono(12, color: c.faint, height: 1.4);
    final now = UiText.mono(
      12,
      weight: FontWeight.w600,
      color: undone ? c.faint : c.ok,
      height: 1.4,
    );
    return Column(
      key: Key('agent-params-${block.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            spacing: 6,
            children: [
              AgentIcon(AgentGlyphs.sliders, size: 14, color: c.muted),
              Expanded(
                child: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        l.ag_paramTitle,
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
                      l.ag_paramCount(block.changes.length),
                      style: UiText.mono(11.5, color: c.faint),
                    ),
                  ],
                ),
              ),
              _DiffStatus(
                id: block.id,
                state: block.state,
                onUndo: () => s.actions.onUndoDiff(block.id),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
          decoration: BoxDecoration(
            color: agentSunk(c),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              for (final ch in block.changes)
                Row(
                  key: Key('agent-param-${block.id}-${ch.param.name}'),
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        label(l, ch.param),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(12, color: c.muted, height: 1.4),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: value(l, ch.before),
                              style: old.copyWith(
                                decoration: TextDecoration.lineThrough,
                                decorationColor: c.faint,
                              ),
                            ),
                            TextSpan(text: '  →  ', style: old),
                            TextSpan(text: value(l, ch.after), style: now),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 角色位置改动卡：左边按画面比例的迷你板（V4 起为无极定位，不画格子；虚线圈 = 原位置，
/// 箭头指向新位置），右边只列动过的角色，其余合成一行。AI 选择时坐标不生效，不画板。
/// 只提示，不撤销。
class AgentPositionView extends StatelessWidget {
  const AgentPositionView({super.key, required this.block});
  final AgentPositionBlock block;

  /// 与生成页定位板 `GenPositionBoard.palette` 一致：同一角色在两处颜色相同。
  /// 人多时颜色循环，靠圆点里的编号区分。
  static const palette = [
    Color(0xFFE5484D),
    Color(0xFF0090FF),
    Color(0xFF30A46C),
    Color(0xFFF76B15),
    Color(0xFF8E4EC6),
    Color(0xFF12A594),
    Color(0xFFD6409F),
    Color(0xFFAD7F58),
  ];

  static Color colorOf(int index) => palette[index % palette.length];

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    String mode(bool custom) =>
        custom ? l.characterCanvas_custom : l.characterCanvas_aiChoice;
    final ai = block.customAfter == false;
    final moved = block.moved.toList();
    final rest = block.marks.length - moved.length;
    return Column(
      key: Key('agent-position-${block.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            spacing: 6,
            children: [
              AgentIcon(AgentGlyphs.hand, size: 14, color: c.muted),
              Expanded(
                child: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        l.ag_positionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          12,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                    if (block.customAfter != null)
                      _ModePill(
                        key: Key('agent-position-mode-${block.id}'),
                        text: block.modeChanged
                            ? '${mode(block.customBefore!)} → ${mode(block.customAfter!)}'
                            : mode(block.customAfter!),
                        highlight: block.modeChanged,
                      ),
                  ],
                ),
              ),
              AgentIcon(AgentGlyphs.check, size: 14, color: c.ok),
              Text(l.ag_positionApplied, style: UiText.sans(12, color: c.ok)),
            ],
          ),
        ),
        if (ai)
          Text(
            l.ag_positionAiHint,
            style: UiText.sans(11.5, color: c.faint, height: 1.45),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              _MiniBoard(block: block),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 7,
                    children: [
                      for (final m in moved) _Legend(mark: m),
                      if (rest > 0)
                        Text(
                          moved.isEmpty
                              ? l.ag_positionAllSame(rest)
                              : l.ag_positionRestSame(rest),
                          key: Key('agent-position-rest-${block.id}'),
                          style: UiText.sans(11.5, color: c.faint, height: 1.3),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({super.key, required this.text, required this.highlight});
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final tone = highlight ? c.accent : c.muted;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: highlight ? .11 : .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: UiText.sans(11, weight: FontWeight.w500, color: tone, height: 1),
      ),
    );
  }
}

/// 迷你定位板：按画面比例，最长边 150（7 人以上 180）；人越多圆点越小，
/// 挨得太近的圆点互相推开一点，保证编号看得清。
class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.block});
  final AgentPositionBlock block;

  static double dotFor(int count) => count <= 6
      ? 18
      : count <= 12
      ? 15
      : 13;

  /// 把落点互相推开到至少 [gap]（几轮简单松弛，夹在板内）。
  static List<Offset> spread(List<Offset> points, Size size, double gap) {
    final p = [...points];
    final half = gap / 2;
    for (var round = 0; round < 8; round++) {
      var moved = false;
      for (var i = 0; i < p.length; i++) {
        for (var j = i + 1; j < p.length; j++) {
          final d = p[j] - p[i];
          final dist = d.distance;
          if (dist >= gap) continue;
          final u = dist < .01
              ? Offset(1, (i + j).isEven ? .3 : -.3)
              : d / dist;
          final push = u * ((gap - dist) / 2 + .1);
          p[i] -= push;
          p[j] += push;
          moved = true;
        }
      }
      for (var i = 0; i < p.length; i++) {
        p[i] = Offset(
          p[i].dx.clamp(half, size.width - half),
          p[i].dy.clamp(half, size.height - half),
        );
      }
      if (!moved) break;
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final aspect = (block.aspect ?? 2 / 3).clamp(.5, 2.0);
    final placed = block.marks.where((m) => m.after != null).toList();
    final long = placed.length > 6 ? 180.0 : 150.0;
    final size = aspect >= 1
        ? Size(long, long / aspect)
        : Size(long * aspect, long);
    final dot = dotFor(placed.length);
    final centers = spread(
      [
        for (final m in placed)
          Offset(m.after!.dx * size.width, m.after!.dy * size.height),
      ],
      size,
      dot + 1,
    );
    return Container(
      key: Key('agent-position-board-${block.id}'),
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: agentSunk(c),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniBoardPainter(line: c.line, marks: block.marks),
            ),
          ),
          // 没动的先画、动过的后画，动过的在上面。
          for (final (i, m) in placed.indexed.where((e) => !e.$2.moved))
            _place(m, centers[i], dot),
          for (final (i, m) in placed.indexed.where((e) => e.$2.moved))
            _place(m, centers[i], dot),
        ],
      ),
    );
  }

  Widget _place(AgentPositionMark m, Offset center, double dot) => Positioned(
    left: center.dx - dot / 2,
    top: center.dy - dot / 2,
    child: _Dot(
      key: Key('agent-position-dot-${m.index}'),
      index: m.index,
      size: dot,
      dim: !m.moved,
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({
    super.key,
    required this.index,
    required this.size,
    this.dim = false,
  });
  final int index;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final color = AgentPositionView.colorOf(index);
    final label = '${index + 1}';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dim ? Color.lerp(color, Colors.white, .5) : color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: dim
            ? null
            : const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Text(
        label,
        style: UiText.mono(
          size * (label.length > 1 ? .48 : .55),
          weight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// 板上只画淡淡的中线作参照（无极定位不分格），以及动过的角色的原位置虚线圈和箭头。
class _MiniBoardPainter extends CustomPainter {
  _MiniBoardPainter({required this.line, required this.marks});
  final Color line;
  final List<AgentPositionMark> marks;

  static const _pi = 3.141592653589793;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = line.withValues(alpha: .7)
      ..strokeWidth = 1;
    void dashed(Offset a, Offset b) {
      final d = b - a, len = d.distance, u = d / len;
      for (var t = 0.0; t < len; t += 7) {
        canvas.drawLine(a + u * t, a + u * (t + 3.5).clamp(0, len), guide);
      }
    }

    dashed(Offset(size.width / 2, 0), Offset(size.width / 2, size.height));
    dashed(Offset(0, size.height / 2), Offset(size.width, size.height / 2));
    for (final m in marks) {
      final from = m.before, to = m.after;
      if (!m.moved || from == null) continue;
      final color = AgentPositionView.colorOf(m.index);
      final a = Offset(from.dx * size.width, from.dy * size.height);
      // 原位置：虚线圈。
      final ring = Paint()
        ..color = color.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      const r = 7.0;
      for (var k = 0; k < 12; k += 2) {
        canvas.drawArc(
          Rect.fromCircle(center: a, radius: r),
          k * _pi / 6,
          _pi / 6,
          false,
          ring,
        );
      }
      if (to == null) continue;
      final b = Offset(to.dx * size.width, to.dy * size.height);
      final d = b - a;
      final len = d.distance;
      if (len < 22) continue;
      final u = d / len;
      final start = a + u * (r + 2), end = b - u * 10;
      final paint = Paint()
        ..color = color.withValues(alpha: .85)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
      final n = Offset(-u.dy, u.dx);
      final tip = end + u;
      final back = end - u * 5;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(back.dx + n.dx * 3.5, back.dy + n.dy * 3.5)
          ..lineTo(back.dx - n.dx * 3.5, back.dy - n.dy * 3.5)
          ..close(),
        Paint()..color = color.withValues(alpha: .85),
      );
    }
  }

  @override
  bool shouldRepaint(_MiniBoardPainter old) =>
      old.line != line || old.marks != marks;
}

/// 图例一行：彩色编号点 + 名字 + 方位变化（「左上 → 中下」）；同一方位里微调时
/// 写「正中 · 微调」。悬停看精确坐标。
class _Legend extends StatelessWidget {
  const _Legend({required this.mark});
  final AgentPositionMark mark;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final m = mark;
    final mono = UiText.sans(11.5, color: c.faint, height: 1.2);
    String coords(Offset p) =>
        '${p.dx.toStringAsFixed(2)}, ${p.dy.toStringAsFixed(2)}';
    String place(Offset? p) => p == null
        ? l.ag_positionNone
        : agentPositionRegion(l, AgentPositionMark.region(p));
    final nudge =
        m.before != null &&
        m.after != null &&
        AgentPositionMark.region(m.before!) ==
            AgentPositionMark.region(m.after!);
    final tip = [
      if (m.before != null) coords(m.before!),
      if (m.after != null) coords(m.after!),
    ].join(' → ');
    final now = UiText.sans(
      11.5,
      weight: FontWeight.w600,
      color: c.ok,
      height: 1.2,
    );
    return Tooltip(
      message: tip,
      child: Row(
        key: Key('agent-position-legend-${m.index}'),
        spacing: 7,
        children: [
          _Dot(index: m.index, size: 16),
          Expanded(
            child: Text(
              (m.name?.trim().isNotEmpty ?? false)
                  ? m.name!.trim()
                  : l.gen_characterN(m.index + 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.ink, height: 1.2),
            ),
          ),
          if (nudge)
            Text('${place(m.after)} · ${l.ag_positionNudge}', style: now)
          else ...[
            if (m.added)
              Text(l.ag_positionNew, style: mono)
            else ...[
              Text(
                place(m.before),
                style: mono.copyWith(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: c.faint,
                ),
              ),
              Text('→', style: mono),
            ],
            Text(place(m.after), style: now),
          ],
        ],
      ),
    );
  }
}

/// 九宫方位名（只用于文字说明，定位本身是连续坐标）。
String agentPositionRegion(AppLocalizations l, int region) => switch (region) {
  0 => l.ag_posTopLeft,
  1 => l.ag_posTop,
  2 => l.ag_posTopRight,
  3 => l.ag_posLeft,
  4 => l.ag_posCenter,
  5 => l.ag_posRight,
  6 => l.ag_posBottomLeft,
  7 => l.ag_posBottom,
  _ => l.ag_posBottomRight,
};

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
              if (_hover &&
                  img.source != AgentImageSource.attachment &&
                  widget.width >= 72 &&
                  widget.height >= 56)
                Positioned(right: 4, top: 4, child: _ThumbActions(image: img)),
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

/// 缩略图悬停时右上角的一排快捷按钮。
class _ThumbActions extends StatelessWidget {
  const _ThumbActions({required this.image});
  final AgentImage image;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget button(AgentImageAction action, String glyph, String tip) => Tooltip(
      message: tip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: Key('agent-image-action-${action.name}-${image.id}'),
          onTap: () => agentImageAction(context, image, action),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(5),
            ),
            child: AgentIcon(glyph, size: 12, color: Colors.white),
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        button(AgentImageAction.vibe, AgentGlyphs.wand, l.ag_imageVibe),
        button(AgentImageAction.params, AgentGlyphs.sliders, l.ag_imageParams),
        if (image.path != null)
          button(AgentImageAction.folder, AgentGlyphs.folder, l.ag_imageFolder),
      ],
    );
  }
}

/// 执行图片快捷动作；成功给一句轻提示（打开文件夹不提示）。
Future<void> agentImageAction(
  BuildContext context,
  AgentImage image,
  AgentImageAction action,
) async {
  final s = AgentScope.of(context);
  final l = context.l10n;
  var ok = false;
  await s.run(() async {
    ok = await s.actions.onImageAction(image.id, action);
    return ok;
  });
  if (!ok) return;
  switch (action) {
    case AgentImageAction.vibe:
      s.toast(l.ag_imageVibeDone);
    case AgentImageAction.reference:
      s.toast(l.ag_imageReferenceDone);
    case AgentImageAction.params:
      s.toast(l.ag_imageParamsDone);
    case AgentImageAction.folder:
      break;
  }
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
      if (img.source != AgentImageSource.attachment) ...[
        const PopupMenuDivider(height: 9),
        item('vibe', AgentGlyphs.wand, l.ag_imageVibe),
        item('reference', AgentGlyphs.image, l.ag_imageReference),
        item('params', AgentGlyphs.sliders, l.ag_imageParams),
      ],
      if (img.path != null)
        item('folder', AgentGlyphs.folder, l.ag_imageFolder),
    ],
  );
  if (!context.mounted) return;
  switch (picked) {
    case 'zoom':
      s.zoom(img);
    case 'attach':
      await s.run(() => s.actions.onAttachImage(img.id));
    case 'reveal':
      s.actions.onRevealImage(img.id);
    case 'vibe':
      await agentImageAction(context, img, AgentImageAction.vibe);
    case 'reference':
      await agentImageAction(context, img, AgentImageAction.reference);
    case 'params':
      await agentImageAction(context, img, AgentImageAction.params);
    case 'folder':
      await agentImageAction(context, img, AgentImageAction.folder);
  }
}
