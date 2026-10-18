import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_preview_image.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_scope.dart';
import 'agent_thread.dart' show agentToolLabel;

/// 对话流最后的待处理卡片。
class AgentPendingCard extends StatelessWidget {
  const AgentPendingCard({super.key, required this.pending});
  final AgentPending pending;

  @override
  Widget build(BuildContext context) => switch (pending) {
    final AgentAsk p => AgentAskCard(key: ValueKey(p.id), ask: p),
    final AgentApproval p => _ApprovalCard(approval: p),
    final AgentGate p => AgentGateCard(key: ValueKey(p.id), gate: p),
  };
}

// ─────────────────────────────── 提问 ───────────────────────────────

/// 提问卡：编号选项（按 1–N 直接选）、「其他想法…」自填、回答 / 跳过。多题依次显示在同一张卡里。
class AgentAskCard extends StatefulWidget {
  const AgentAskCard({super.key, required this.ask});
  final AgentAsk ask;

  @override
  State<AgentAskCard> createState() => _AgentAskCardState();
}

class _AgentAskCardState extends State<AgentAskCard> {
  late final Map<String, String> _answers = {
    for (final q in widget.ask.questions) q.id: q.prefill,
  };
  late final Map<String, TextEditingController> _custom = {
    for (final q in widget.ask.questions)
      q.id: TextEditingController(
        text: q.options.contains(q.prefill) ? '' : q.prefill,
      ),
  };
  final _focus = FocusNode(debugLabel: 'agent-ask');
  var _active = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          FocusManager.instance.primaryFocus?.context?.widget
              is! EditableText) {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _custom.values) {
      c.dispose();
    }
    _focus.dispose();
    super.dispose();
  }

  bool get _ready =>
      widget.ask.questions.every((q) => q.accepts(_answers[q.id] ?? ''));

  void _pick(int qi, String option) {
    final q = widget.ask.questions[qi];
    setState(() {
      _answers[q.id] = option;
      _custom[q.id]!.clear();
      _active = (qi + 1).clamp(0, widget.ask.questions.length - 1);
    });
  }

  void _submit() {
    if (!_ready) return;
    AgentScope.of(context).actions.onAnswer(widget.ask.id, Map.of(_answers));
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    final qs = widget.ask.questions;
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final q = qs[_active];
        final digit = int.tryParse(e.character ?? '');
        if (digit != null && digit >= 1 && digit <= q.options.length) {
          _pick(_active, q.options[digit - 1]);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.enter && _ready) {
          _submit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AgentCard(
        key: Key('agent-ask-${widget.ask.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              if (widget.ask.title != null)
                Text(widget.ask.title!, style: UiText.sans(12, color: c.muted)),
              for (final (qi, q) in qs.indexed) _question(qi, q),
              Row(
                spacing: 8,
                children: [
                  AgentButton(
                    key: const Key('agent-ask-skip'),
                    label: l.ag_askSkip,
                    style: AgentButtonStyle.ghost,
                    height: 32,
                    onPressed: () => s.actions.onCancelAsk(widget.ask.id),
                  ),
                  const Spacer(),
                  AgentButton(
                    key: const Key('agent-ask-submit'),
                    label: l.ag_askSubmit,
                    style: AgentButtonStyle.primary,
                    height: 32,
                    onPressed: _ready ? _submit : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _question(int qi, AgentQuestion q) {
    final c = context.ui;
    final l = context.l10n;
    final answer = _answers[q.id] ?? '';
    final custom = _custom[q.id]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                q.text,
                style: UiText.sans(
                  13,
                  weight: FontWeight.w600,
                  color: c.ink,
                  height: 1.5,
                ),
              ),
            ),
            if (q.options.length > 1 && qi == _active)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: AgentEyebrow(l.ag_askHint(q.options.length.clamp(1, 9))),
              ),
          ],
        ),
        for (final (i, o) in q.options.indexed)
          _Option(
            key: Key('agent-ask-option-${q.id}-$i'),
            index: i + 1,
            label: o,
            selected: answer == o && custom.text.isEmpty,
            onTap: () => _pick(qi, o),
          ),
        if (q.allowCustom || q.options.isEmpty)
          Container(
            constraints: BoxConstraints(minHeight: q.multiline ? 72 : 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: custom.text.isEmpty ? c.strong : c.ink,
                width: custom.text.isEmpty ? 1 : 1.5,
              ),
            ),
            child: TextField(
              key: Key('agent-ask-custom-${q.id}'),
              controller: custom,
              minLines: q.multiline ? 3 : 1,
              maxLines: q.multiline ? 8 : 3,
              onChanged: (v) => setState(() {
                _answers[q.id] = v;
                _active = qi;
              }),
              onSubmitted: q.multiline ? null : (_) => _submit(),
              style: UiText.sans(12.5, color: c.ink, height: 1.4),
              cursorColor: c.accent,
              decoration: agentBareInput(
                hint: q.placeholder ?? l.ag_askOther,
                hintStyle: UiText.sans(12.5, color: c.faint, height: 1.4),
              ),
            ),
          ),
      ],
    );
  }
}

class _Option extends StatefulWidget {
  const _Option({
    super.key,
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hover && !on ? c.hover : c.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? c.ink : c.border, width: on ? 2 : 1),
          ),
          child: Row(
            spacing: 10,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? c.ink : c.control,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.index <= 9 ? '${widget.index}' : '·',
                  style: UiText.mono(
                    11,
                    weight: FontWeight.w500,
                    color: on ? c.bg : c.muted,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.label,
                  style: UiText.sans(13, color: c.ink, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── 审批 ───────────────────────────────

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.approval});
  final AgentApproval approval;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    final options = approval.options;
    return AgentCard(
      key: Key('agent-approval-${approval.id}'),
      borderColor: c.warn,
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            color: c.warn.withValues(alpha: .1),
            child: Row(
              spacing: 8,
              children: [
                AgentIcon(AgentGlyphs.shield, size: 14, color: c.warn),
                Expanded(
                  child: Text(
                    l.ag_approvalTitle(agentToolLabel(l, approval.tool)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      12.5,
                      weight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ),
                AgentIconButton(
                  small: true,
                  glyph: AgentGlyphs.close,
                  tooltip: l.ag_cancel,
                  onPressed: () => s.actions.onCancelApproval(approval.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: agentSunk(c),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.line),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  approval.preview,
                  style: UiText.mono(11.5, color: c.muted, height: 1.55),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                for (final (i, o) in options.indexed)
                  AgentButton(
                    key: Key('agent-approval-option-$i'),
                    label: o,
                    height: 30,
                    style: i == 0
                        ? AgentButtonStyle.primary
                        : i == options.length - 1
                        ? AgentButtonStyle.ghost
                        : AgentButtonStyle.outline,
                    onPressed: () => s.actions.onApprove(approval.id, o),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── 付费确认 ───────────────────────────────

/// 黑色确认闸：倒计时、原图、逐项明细、合计 Anlas。确认键只在 Studio 复核通过时可点。
class AgentGateCard extends StatefulWidget {
  const AgentGateCard({super.key, required this.gate});
  final AgentGate gate;

  @override
  State<AgentGateCard> createState() => _AgentGateCardState();
}

class _AgentGateCardState extends State<AgentGateCard> {
  Timer? _timer;
  var _ticks = 0;
  DateTime? _base;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = AgentScope.of(context).data.now;
    if (_base != now) {
      _base = now;
      _ticks = 0;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _ticks++);
      if (_left <= Duration.zero) _timer?.cancel();
    });
  }

  Duration get _left =>
      widget.gate.expiresAt.difference(_base!.add(Duration(seconds: _ticks)));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    final g = widget.gate;
    final left = _left;
    final expired = left <= Duration.zero;
    final count = (g.requests ?? 1) * (g.batch ?? 1);
    final action = switch (g.kind) {
      AgentGateKind.text2img => l.ag_gateText2img(count),
      AgentGateKind.img2img => l.ag_gateImg2img(count),
      AgentGateKind.inpaint => l.ag_gateInpaint(count),
      AgentGateKind.variations => l.ag_gateVariations(count),
      AgentGateKind.enhance => l.ag_gateEnhance,
      AgentGateKind.imageTool => g.title ?? l.ag_gateConfirmTool,
    };
    final canConfirm = g.ready && !g.changed && !expired;
    final secs = left.inSeconds.clamp(0, 5999);
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(k, style: UiText.sans(12, color: c.muted, height: 1.4)),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.mono(12, color: c.ink, height: 1.4),
            ),
          ),
        ],
      ),
    );
    final size = g.width != null && g.height != null
        ? '${g.width}×${g.height}'
        : null;
    return Container(
      key: Key('agent-gate-${g.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: c.ink,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              spacing: 8,
              children: [
                AgentIcon(AgentGlyphs.gen, size: 14, color: c.bg),
                Expanded(
                  child: Text(
                    l.ag_gateTitle(action),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      12.5,
                      weight: FontWeight.w500,
                      color: c.bg,
                      height: 1.2,
                    ),
                  ),
                ),
                Text(
                  expired
                      ? l.ag_gateExpired
                      : '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                  style: UiText.mono(
                    12,
                    color: c.bg.withValues(alpha: .7),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                if (g.source != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 64,
                      height: 94,
                      child: UiPreviewImage(image: g.source!),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (g.model != null || size != null)
                        row(l.ag_gateModelSize, [?g.model, ?size].join(' · ')),
                      if (g.requests != null)
                        row(
                          l.ag_gateRequests,
                          l.ag_gateRequestsValue(g.requests!, g.batch ?? 1),
                        ),
                      if (g.unitAnlas != null)
                        row(
                          l.ag_gateUnit,
                          '${agentNumber(g.unitAnlas!)} Anlas',
                        ),
                      if (g.encodingAnlas != null && g.encodingAnlas! > 0)
                        row(
                          l.ag_gateEncoding,
                          '${agentNumber(g.encodingAnlas!)} Anlas',
                        ),
                      if (g.account != null) row(l.ag_gateAccount, g.account!),
                      if (g.extra != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            g.extra!,
                            style: UiText.sans(
                              11.5,
                              color: c.muted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.border)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                g.balanceAnlas == null
                                    ? l.ag_gateTotalNoBalance
                                    : l.ag_gateTotal(
                                        agentNumber(g.balanceAnlas!),
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(12, color: c.muted),
                              ),
                            ),
                            AgentAnlas(size: 14, color: c.ink),
                            const SizedBox(width: 4),
                            Text(
                              g.totalAnlas == null
                                  ? '—'
                                  : agentNumber(g.totalAnlas!),
                              style: UiText.mono(
                                17,
                                weight: FontWeight.w600,
                                color: c.ink,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l.ag_gateEstimate,
                          textAlign: TextAlign.right,
                          style: UiText.sans(10.5, color: c.faint, height: 1.3),
                        ),
                      ),
                      if (g.changed || expired)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            g.changed ? l.ag_gateChanged : l.ag_gateExpired,
                            style: UiText.sans(
                              11.5,
                              color: c.warn,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              spacing: 8,
              children: [
                AgentButton(
                  key: const Key('agent-gate-cancel'),
                  label: l.ag_cancel,
                  height: 32,
                  onPressed: () => s.actions.onDecideGate(g.id, confirm: false),
                ),
                Expanded(
                  child: AgentButton(
                    key: const Key('agent-gate-confirm'),
                    label: g.kind == AgentGateKind.imageTool
                        ? l.ag_gateConfirmTool
                        : l.ag_gateConfirm,
                    style: AgentButtonStyle.primary,
                    height: 32,
                    expand: true,
                    onPressed: canConfirm
                        ? () => s.actions.onDecideGate(g.id, confirm: true)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
