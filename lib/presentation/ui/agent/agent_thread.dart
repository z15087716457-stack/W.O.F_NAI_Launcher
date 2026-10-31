import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_preview_image.dart';
import '../kit/ui_text.dart';
import 'agent_activity.dart';
import 'agent_answered_questions.dart';
import 'agent_cards.dart';
import 'agent_contract.dart';
import 'agent_prompt_set_card.dart';
import 'agent_position_board.dart';
import 'agent_tag_window.dart';
export 'agent_tag_window.dart' show agentDiffWindow;
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_scope.dart';
import 'agent_stream_reveal.dart';
import 'agent_thread_navigation.dart';

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
  AgentThreadNavigation? _navigation;
  var _navigationEpoch = 0;
  final _turnViews = <String, (Object, bool, Widget)>{};

  void _reportVisible() {
    final nav = _navigation;
    if (nav == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_navigation, nav)) return;
      final viewport = context.findRenderObject() as RenderBox?;
      if (viewport == null || !viewport.hasSize) return;
      final rect = viewport.localToGlobal(Offset.zero) & viewport.size;
      final visible = <String>{};
      for (final e in AgentScope.of(context).data.history) {
        final turn = AgentScope.of(
          context,
        ).data.thread.where((t) => t.id == e.turnId).firstOrNull;
        final block = e.blockIndex == null
            ? null
            : turn?.reply?.blocks.elementAtOrNull(e.blockIndex!);
        final box =
            (block == null
                        ? nav.users[e.turnId]
                        : nav.blocks[(e.turnId, e.blockIndex!)])
                    ?.currentContext
                    ?.findRenderObject()
                as RenderBox?;
        if (box != null &&
            box.attached &&
            box.hasSize &&
            rect.overlaps(box.localToGlobal(Offset.zero) & box.size)) {
          visible.add(e.id);
        }
      }
      if (!setEquals(nav.visible.value, visible)) nav.visible.value = visible;
    });
  }

  Future<bool> _jumpHistory(AgentHistoryEntry entry) async {
    final epoch = ++_navigationEpoch;
    final d = AgentScope.of(context).data;
    final index = d.thread.indexWhere((t) => t.id == entry.turnId);
    final nav = _navigation;
    if (index < 0 || nav == null || !_scroll.hasClients) return false;
    _follow = false;
    // Walk viewport-sized chunks through the lazy list until the target mounts.
    // Unlike estimated index offsets, this also handles very tall mixed cards.
    while (mounted &&
        epoch == _navigationEpoch &&
        nav.turns[entry.turnId]?.currentContext == null) {
      final built = [
        for (final (i, t) in d.thread.indexed)
          if (nav.turns[t.id]?.currentContext != null) i,
      ];
      final forward = built.isEmpty || index > built.last;
      final position = _scroll.position;
      final next =
          (_scroll.offset +
                  (forward ? 1 : -1) * position.viewportDimension * .85)
              .clamp(0.0, position.maxScrollExtent);
      if (next == _scroll.offset) return false;
      _auto = true;
      _scroll.jumpTo(next);
      _auto = false;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted || epoch != _navigationEpoch) return false;
    final block = entry.blockIndex == null
        ? null
        : d.thread[index].reply?.blocks.elementAtOrNull(entry.blockIndex!);
    final Object target = block == null
        ? entry.turnId
        : (entry.turnId, entry.blockIndex!);
    final anchor = block == null
        ? nav.users[entry.turnId]
        : nav.blocks[(entry.turnId, entry.blockIndex!)];
    final targetContext = anchor?.currentContext;
    if (targetContext == null || !targetContext.mounted) return false;
    _auto = true;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: .12,
      duration: const Duration(milliseconds: 180),
    );
    _auto = false;
    if (!mounted || epoch != _navigationEpoch) return false;
    nav.highlight.value = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && epoch == _navigationEpoch) nav.highlight.value = null;
    });
    _reportVisible();
    return true;
  }

  /// 打开 / 换聊天后的第一帧不做进场动画（已有内容直接显示），之后新内容才动。
  var _armed = false;

  void _arm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_armed) setState(() => _armed = true);
    });
  }

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
    _reportVisible();
    return false;
  }

  bool _onMetrics(ScrollMetricsNotification n) {
    if (n.depth != 0) return false;
    _reportVisible();
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
    _navigation = AgentNavigationScope.of(context);
    _navigation?.jump = _jumpHistory;
    _reportVisible();
    final r = d.revision;
    if (_chat != null && d.chat.id != _chat) {
      _navigationEpoch++;
      // 换了聊天：从最新处开始看。
      _follow = true;
      _fresh = false;
      _armed = false;
      _queueJump();
    }
    if (!_armed) _arm();
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
    _navigationEpoch++;
    _navigation?.jump = null;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data;
    final c = context.ui;
    final ids = d.thread.map((t) => t.id).toSet();
    _turnViews.removeWhere((id, _) => !ids.contains(id));
    Widget turnView(AgentTurn turn, bool last) {
      final key = turn.renderKey;
      final cached = _turnViews[turn.id];
      if (key != null &&
          cached != null &&
          cached.$1 == key &&
          cached.$2 == last) {
        return cached.$3;
      }
      final view = _Turn(
        key: ValueKey('turn-${turn.id}'),
        turn: turn,
        last: last,
      );
      if (key != null) _turnViews[turn.id] = (key, last, view);
      return view;
    }

    final items = <Widget>[
      for (final (i, turn) in d.thread.indexed)
        if (_navigation case final nav?)
          KeyedSubtree(
            key: nav.turns.putIfAbsent(turn.id, GlobalKey.new),
            child: turnView(turn, i == d.thread.length - 1),
          )
        else
          turnView(turn, i == d.thread.length - 1),
      for (final p in d.composer.pending)
        AgentAppear(
          key: ValueKey('pending-${p.id}'),
          id: '${d.chat.id}/pending/${p.id}',
          child: AgentPendingCard(pending: p),
        ),
      if (d.runLimit != null)
        AgentAppear(
          key: const ValueKey('limit'),
          id: '${d.chat.id}/limit/${d.thread.lastOrNull?.id}',
          child: _LimitCard(
            limit: d.runLimit!,
            busy: d.status != AgentRunStatus.idle,
          ),
        ),
      if (d.error != null)
        AgentAppear(
          key: const ValueKey('error'),
          id: '${d.chat.id}/error/${d.thread.lastOrNull?.id}/${d.error}',
          child: _ErrorLine(
            d.error!,
            onRetry: d.status == AgentRunStatus.idle && d.thread.isNotEmpty
                ? () => s.run(s.actions.onRegenerate)
                : null,
          ),
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
                child: AgentAppearScope(
                  armed: _armed,
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

/// 单次任务步数到上限：不是出错，用中性的灰卡。「继续」接着原来的进度做，
/// 「调整上限」去设置里改「单次任务最多请求」。
class _LimitCard extends StatelessWidget {
  const _LimitCard({required this.limit, required this.busy});
  final int limit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('agent-limit'),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: agentSunk(c),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: c.control, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size.square(10),
              painter: _PausePainter(c.ink),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  l.ag_limitTitle(limit),
                  style: UiText.sans(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.ink,
                    height: 1.45,
                  ),
                ),
                Text(
                  l.ag_limitBody,
                  style: UiText.sans(11.5, color: c.muted, height: 1.6),
                ),
                const SizedBox(height: 7),
                Row(
                  spacing: 6,
                  children: [
                    AgentButton(
                      key: const Key('agent-limit-continue'),
                      label: l.ag_limitContinue,
                      style: AgentButtonStyle.primary,
                      height: 26,
                      onPressed: busy
                          ? null
                          : () => s.run(s.actions.onContinue),
                    ),
                    AgentButton(
                      key: const Key('agent-limit-adjust'),
                      label: l.ag_limitAdjust,
                      style: AgentButtonStyle.ghost,
                      height: 26,
                      onPressed: s.actions.onAdjustLimit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PausePainter extends CustomPainter {
  const _PausePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    for (final x in [.2, .6]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, w * .15, w * .2, w * .7),
          Radius.circular(w * .06),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PausePainter old) => old.color != color;
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

Widget _userAnchor(BuildContext context, AgentTurn turn) {
  final nav = AgentNavigationScope.of(context);
  final child = _UserLine(message: turn.user);
  return nav == null
      ? child
      : AgentNavigationAnchor(
          navigation: nav,
          target: turn.id,
          anchor: nav.users.putIfAbsent(turn.id, GlobalKey.new),
          child: child,
        );
}

class _Turn extends StatelessWidget {
  const _Turn({super.key, required this.turn, required this.last});
  final AgentTurn turn;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final reply = turn.reply;
    return AgentTurnNavigationScope(
      turnId: turn.id,
      blocks: reply?.blocks ?? const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (turn.user.entryId != null ||
              turn.user.text.isNotEmpty ||
              turn.user.images.isNotEmpty)
            AgentAppear(
              id: '${turn.id}/user',
              enabled: last,
              child: _userAnchor(context, turn),
            ),
          if (reply != null && (reply.blocks.isNotEmpty || reply.live))
            AgentAppear(
              id: '${turn.id}/card',
              enabled: last,
              child: _TaskCard(
                turnId: turn.id,
                reply: reply,
                last: last,
                since: turn.user.at,
              ),
            ),
        ],
      ),
    );
  }
}

/// 用户这一句：左侧 2px 墨线，眉题「你 · 16:40」，悬停出现复制 / 编辑。
/// 编辑在原地进行（双击文字也能进）：改文字、去掉图，「发送」后从这句重新开始，
/// 它之后的对话被新回答替换；「取消」/ Esc 什么都不动。
class _UserLine extends StatefulWidget {
  const _UserLine({required this.message});
  final AgentUserMessage message;

  @override
  State<_UserLine> createState() => _UserLineState();
}

class _UserLineState extends State<_UserLine> {
  var _hover = false;
  var _editing = false;
  var _sending = false;
  TextEditingController? _text;
  final _focus = FocusNode();
  var _keep = <String>[];

  @override
  void dispose() {
    _text?.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _canEdit(AgentScope s) =>
      widget.message.entryId != null && s.data.status == AgentRunStatus.idle;

  void _startEdit() {
    final m = widget.message;
    _text?.dispose();
    _text = TextEditingController(text: m.text);
    _keep = [for (final i in m.images) i.id];
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _text!.selection = TextSelection.collapsed(offset: _text!.text.length);
    });
  }

  void _cancel() => setState(() => _editing = false);

  bool get _canSend =>
      !_sending && (_text!.text.trim().isNotEmpty || _keep.isNotEmpty);

  Future<void> _send(AgentScope s) async {
    if (!_canSend) return;
    setState(() => _sending = true);
    var ok = false;
    await s.run(() async {
      ok = await s.actions.onResendFrom(
        widget.message.entryId!,
        _text!.text.trim(),
        List.of(_keep),
      );
      return ok;
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.controlsOf(context);
    final m = widget.message;
    final c = context.ui;
    final l = context.l10n;
    final editable = _canEdit(s);
    // 运行起来了（别处发了消息）就退出编辑，免得在跑的时候改历史。
    if (_editing && !editable && !_sending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editing) setState(() => _editing = false);
      });
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        key: Key('agent-user-${m.entryId ?? m.at.millisecondsSinceEpoch}'),
        padding: const EdgeInsets.fromLTRB(14, 2, 4, 0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: _editing ? c.accent : c.ink, width: 2),
          ),
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
                  if (_hover && !_editing) ...[
                    AgentIconButton(
                      small: true,
                      glyph: AgentGlyphs.copy,
                      tooltip: l.ag_copy,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: m.text));
                        s.toast(l.ag_copied);
                      },
                    ),
                    if (editable)
                      AgentIconButton(
                        key: Key('agent-edit-${m.entryId}'),
                        small: true,
                        glyph: AgentGlyphs.pen,
                        tooltip: l.ag_edit,
                        onPressed: _startEdit,
                      ),
                  ],
                ],
              ),
            ),
            if (_editing) _editor(s) else ..._view(s, editable),
          ],
        ),
      ),
    );
  }

  List<Widget> _view(AgentScope s, bool editable) {
    final m = widget.message;
    final c = context.ui;
    return [
      if (m.text.isNotEmpty)
        GestureDetector(
          onDoubleTap: editable ? _startEdit : null,
          child: Text(
            m.text,
            style: UiText.sans(
              13.5,
              weight: FontWeight.w500,
              color: c.ink,
              height: 1.6,
            ),
          ),
        ),
      if (m.images.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final img in m.images)
              AgentThumb(image: img, width: 72, height: 72, group: m.images),
          ],
        ),
    ];
  }

  Widget _editor(AgentScope s) {
    final m = widget.message;
    final c = context.ui;
    final l = context.l10n;
    final kept = [
      for (final i in m.images)
        if (_keep.contains(i.id)) i,
    ];
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 2),
      child: Container(
        key: Key('agent-edit-box-${m.entryId}'),
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.strong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): _cancel,
                const SingleActivator(
                  LogicalKeyboardKey.enter,
                  control: true,
                ): () =>
                    _send(s),
              },
              child: TextField(
                key: Key('agent-edit-text-${m.entryId}'),
                controller: _text,
                focusNode: _focus,
                minLines: 1,
                maxLines: 10,
                onChanged: (_) => setState(() {}),
                style: UiText.sans(13.5, color: c.ink, height: 1.6),
                decoration: agentBareInput(),
              ),
            ),
            if (kept.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final img in kept)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AgentThumb(image: img, width: 56, height: 56),
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Tooltip(
                            message: l.ag_editRemoveImage,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                key: Key('agent-edit-remove-${img.id}'),
                                onTap: () =>
                                    setState(() => _keep.remove(img.id)),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: c.ink,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: c.card, width: 2),
                                  ),
                                  child: AgentIcon(
                                    AgentGlyphs.close,
                                    size: 9,
                                    color: c.card,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            Row(
              spacing: 6,
              children: [
                Expanded(
                  child: AgentOverflowText(
                    l.ag_editHint,
                    style: UiText.sans(11.5, color: c.faint, height: 1.3),
                  ),
                ),
                AgentButton(
                  key: Key('agent-edit-cancel-${m.entryId}'),
                  label: l.ag_cancel,
                  style: AgentButtonStyle.ghost,
                  height: 26,
                  onPressed: _sending ? null : _cancel,
                ),
                Tooltip(
                  message: 'Ctrl + Enter',
                  waitDuration: const Duration(milliseconds: 600),
                  child: AgentButton(
                    key: Key('agent-edit-send-${m.entryId}'),
                    label: l.ag_editResend,
                    glyph: AgentGlyphs.send,
                    style: AgentButtonStyle.primary,
                    height: 26,
                    onPressed: _canSend ? () => _send(s) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 任务卡：过程 / 结论 / 提示词改动 / 本次产物，各占一节。每出现一段结果，
/// 它前面那串过程就收成一行「已处理 …」，点开看全部；正在进行、等你处理、
/// 出错的那段保持展开；一轮结束后最后一串过程也收起。
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.turnId,
    required this.reply,
    required this.last,
    this.since,
    this.copyBlocks,
  });
  final String turnId;
  final AgentReply reply;
  final bool last;

  /// 这一轮开始的时间（用户这句的时间），工作中提示行的用时从这里算。
  final DateTime? since;
  // 分开显示的回复仍由末尾按钮复制整轮正文，仅在点击时组装文本。
  final List<AgentBlock>? copyBlocks;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.controlsOf(context);
    final l = context.l10n;
    final c = context.ui;
    // Standalone blocks keep their place without inheriting the task shell.
    final hasCompaction = reply.blocks.any((b) => b is AgentCompactionBlock);
    if (hasCompaction ||
        reply.blocks.any(
          (block) =>
              block is AgentPromptSetBlock ||
              block is AgentAnsweredQuestionsBlock,
        )) {
      final groups = <Widget>[];
      var ordinary = <AgentBlock>[];
      final compactionTail =
          !reply.live && reply.blocks.lastOrNull is AgentCompactionBlock
          ? reply.blocks.lastIndexWhere((b) => b is! AgentCompactionBlock) + 1
          : null;
      final liveAfterCompaction =
          reply.live && reply.blocks.lastOrNull is AgentCompactionBlock;
      void flush({bool tail = false}) {
        if (ordinary.isEmpty && !tail) return;
        if (ordinary.isEmpty &&
            reply.summary == null &&
            !reply.canRegenerate &&
            !(tail && liveAfterCompaction)) {
          return;
        }
        groups.add(
          _TaskCard(
            turnId: '$turnId/part-${groups.length}',
            last: last && tail,
            since: since,
            copyBlocks: copyBlocks ?? (hasCompaction ? reply.blocks : null),
            reply: AgentReply(
              blocks: List.of(ordinary),
              live: reply.live && tail,
              summary: tail ? reply.summary : null,
              canRegenerate: tail && reply.canRegenerate,
            ),
          ),
        );
        ordinary = [];
      }

      for (final (i, block) in reply.blocks.indexed) {
        if (block is AgentPromptSetBlock) {
          flush();
          groups.add(
            agentBlockAnchor(context, block, _promptSetView(context, block)),
          );
        } else if (block is AgentAnsweredQuestionsBlock) {
          flush();
          groups.add(
            agentBlockAnchor(
              context,
              block,
              AgentAnsweredQuestionsView(block: block),
            ),
          );
        } else if (block is AgentCompactionBlock) {
          flush(tail: i == compactionTail);
          groups.add(
            agentBlockAnchor(
              context,
              block,
              AgentCompactionView(key: ValueKey('compaction-$i'), block: block),
            ),
          );
        } else {
          ordinary.add(block);
        }
      }
      if (compactionTail == null) flush(tail: true);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: groups,
      );
    }
    final segs = _segments(reply.blocks);
    final finalText = !reply.live && segs.lastOrNull is _OutSeg
        ? (segs.last as _OutSeg).item is AgentTextBlock
        : false;
    const proc = EdgeInsets.fromLTRB(8, 9, 8, 9);
    final sections = <(String, Widget, EdgeInsets)>[];
    for (final (i, seg) in segs.indexed) {
      switch (seg) {
        case _ProcSeg(:final items):
          final tail = i == segs.length - 1;
          final next = segs.elementAtOrNull(i + 1);
          sections.add((
            'seg-$i-proc',
            _Process(
              key: ValueKey('proc-$i'),
              index: i,
              scope: turnId,
              items: items,
              live: reply.live,
              foldable:
                  items.length > 2 &&
                  items.every(_settled) &&
                  (!tail || !reply.live),
              took: _took(items, next is _OutSeg ? next.item : null),
            ),
            proc,
          ));
        case _OutSeg(:final item):
          final isLast = i == segs.length - 1;
          sections.add((
            'seg-$i-${switch (item) {
              AgentTextBlock() => 'text',
              _ReadGroup() => 'read',
              AgentImagesBlock() => 'images',
              _ => 'card',
            }}',
            agentBlockAnchor(
              context,
              item is AgentBlock ? item : null,
              switch (item) {
                _ReadGroup() => _ReadGroupView(
                  key: ValueKey('read-$i'),
                  group: item,
                ),
                AgentTextBlock(:final markdown) => AgentMarkdown(markdown),
                AgentPromptSetBlock() => _promptSetView(context, item),
                AgentAnsweredQuestionsBlock() => AgentAnsweredQuestionsView(
                  block: item,
                ),
                AgentDiffBlock(:final diff) => AgentDiffView(diff: diff),
                AgentPositionBlock() => AgentPositionView(block: item),
                AgentParamBlock() => AgentParamView(block: item),
                AgentSettingsBlock() => AgentSettingsView(block: item),
                AgentGalleryBlock() => AgentGalleryView(block: item),
                AgentChangeSummaryBlock() => AgentChangeSummaryView(
                  block: item,
                ),
                AgentImagesBlock() => AgentOutputs(block: item),
                _ => const SizedBox.shrink(),
              },
            ),
            item is _ReadGroup
                ? proc
                : isLast && finalText
                // 结论多留一点呼吸。
                ? const EdgeInsets.fromLTRB(14, 15, 14, 14)
                : const EdgeInsets.fromLTRB(14, 12, 14, 12),
          ));
      }
    }
    if (reply.live) {
      final tail = segs.lastOrNull;
      final current = tail is _ProcSeg
          ? tail.items.where((x) => !_settled(x)).lastOrNull
          : null;
      sections.add((
        'live',
        _LiveLine(
          status: s.data.status,
          kind: current == null ? null : _kindOf(current),
          since: since,
        ),
        const EdgeInsets.fromLTRB(14, 9, 14, 9),
      ));
    }
    final summary = reply.live ? null : reply.summary;
    final bar = (reply.canRegenerate && last) || summary != null;
    return AgentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (key, w, padding)) in sections.indexed)
            AgentAppear(
              key: ValueKey(key),
              id: '$turnId/$key',
              // 只有最后一轮会长出新内容；卡片刚出现时整张一起进场，第一节不再单独动。
              enabled: last && i > 0,
              child: AgentSection(first: i == 0, padding: padding, child: w),
            ),
          if (bar)
            AgentAppear(
              id: '$turnId/bar',
              enabled: last,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: SizedBox(
                  height: 24,
                  child: Row(
                    spacing: 6,
                    children: [
                      if (reply.canRegenerate && last)
                        AgentButton(
                          key: const Key('agent-regenerate'),
                          label: l.ag_regenerate,
                          glyph: AgentGlyphs.refresh,
                          style: AgentButtonStyle.ghost,
                          height: 24,
                          onPressed: () => s.run(s.actions.onRegenerate),
                        ),
                      Expanded(
                        child: summary == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: EdgeInsets.only(
                                  left: reply.canRegenerate && last ? 0 : 6,
                                ),
                                child: _TurnSummary(
                                  key: Key('agent-turn-summary-$turnId'),
                                  summary: summary,
                                ),
                              ),
                      ),
                      if (reply.canRegenerate && last)
                        AgentIconButton(
                          small: true,
                          glyph: AgentGlyphs.copy,
                          tooltip: l.ag_copy,
                          onPressed: () async {
                            final text = (copyBlocks ?? reply.blocks)
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
              ),
            ),
        ],
      ),
    );
  }
}

Widget _promptSetView(BuildContext context, AgentPromptSetBlock block) =>
    AgentPromptSetCard(
      key: ValueKey('prompt-set-${block.setId}'),
      data: block.data,
      onAction: (index, action) async {
        final scope = AgentScope.controlsOf(context),
            callback = AgentScope.controlsOf(context).actions.onPromptSetAction;
        if (callback != null) {
          await scope.run(() => callback(block.setId, index, action));
        }
      },
      onEdit: (text) => AgentScope.controlsOf(context).insert(text),
      onImage: (image, group) =>
          AgentScope.controlsOf(context).zoom(image, group: group),
    );

/// 一轮小结：淡色一行「用时 1m 12s · 48 Anlas · 改动 5 处」，悬停看明细（含工具次数、token）。
class _TurnSummary extends StatelessWidget {
  const _TurnSummary({super.key, required this.summary});
  final AgentTurnSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final x = summary;
    final parts = [
      if (x.took != null) l.ag_turnTook(agentDuration(x.took!)),
      if ((x.anlas ?? 0) > 0) l.ag_turnAnlas(agentNumber(x.anlas!)),
      if (x.changes > 0) l.ag_turnChanges(x.changes),
    ];
    final detail = [
      ...parts,
      if (x.toolCalls > 0) l.ag_turnTools(x.toolCalls),
      if (x.inputTokens != null || x.outputTokens != null)
        l.ag_turnTokens(
          agentTokens(x.inputTokens ?? 0),
          agentTokens(x.outputTokens ?? 0),
        ),
    ];
    if (parts.isEmpty && detail.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: detail.join('\n'),
        waitDuration: const Duration(milliseconds: 500),
        child: Text(
          (parts.isEmpty ? detail : parts).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiText.mono(11, color: c.faint, height: 1.2),
        ),
      ),
    );
  }
}

class _LiveLine extends StatelessWidget {
  const _LiveLine({required this.status, this.kind, this.since});
  final AgentRunStatus status;
  final AgentActivityKind? kind;
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    // 真实状态（开聊天 / 排队 / 等你）照实说；其余时候是工作中提示行。
    final fixed = switch (status) {
      AgentRunStatus.starting => l.ag_starting,
      AgentRunStatus.waitingSlot => l.ag_waitingSlot,
      AgentRunStatus.waitingUser => l.ag_waitingYou,
      _ => null,
    };
    if (fixed == null) return AgentWorkingLine(kind: kind, since: since);
    final waiting = status == AgentRunStatus.waitingUser;
    return Row(
      key: const Key('agent-live'),
      spacing: 8,
      children: [
        AgentActivityIcon(
          kind: waiting ? AgentActivityKind.ask : AgentActivityKind.external,
          state: waiting
              ? AgentActivityState.waiting
              : AgentActivityState.running,
        ),
        Text(
          fixed,
          style: UiText.sans(
            12.5,
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
  const AgentMarkdown(this.markdown, {super.key, this.onOpenLink});
  final String markdown;
  final ValueChanged<String>? onOpenLink;

  @override
  Widget build(BuildContext context) {
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
        // 行内代码底色半透明，框选时不盖住选区（10-24 反馈）。
        code: UiText.mono(
          12,
          color: c.ink,
        ).copyWith(backgroundColor: uiSelectableTint(c.control, c.panel)),
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
      builders: {'pre': _AgentCodeBlockBuilder(c)},
      imageBuilder: (uri, title, alt) => Tooltip(
        message: uri.toString(),
        child: AgentIcon(AgentGlyphs.image, size: 16, color: c.faint),
      ),
      onTapLink: (_, href, _) {
        if (href != null) {
          (onOpenLink ?? AgentScope.controlsOf(context).actions.onOpenLink)(
            href,
          );
        }
      },
    );
  }
}

/// 围栏代码块：自动换行（不再横向滚动）+ 右上角单块复制。
/// 复制的是块内原文（不含围栏、语言名），软换行不插入换行符。
class _AgentCodeBlockBuilder extends MarkdownElementBuilder {
  _AgentCodeBlockBuilder(this.c);
  final UiColors c;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.children?.firstOrNull;
    final lang = code is md.Element
        ? (code.attributes['class'] ?? '').replaceFirst('language-', '')
        : '';
    var text = element.textContent;
    if (text.endsWith('\n')) {
      text = text.substring(0, text.length - 1);
    }
    return AgentCodeBlock(text: text, language: lang);
  }
}

class AgentCodeBlock extends StatefulWidget {
  const AgentCodeBlock({super.key, required this.text, this.language = ''});
  final String text;
  final String language;

  @override
  State<AgentCodeBlock> createState() => _AgentCodeBlockState();
}

class _AgentCodeBlockState extends State<AgentCodeBlock> {
  var _copied = false;
  var _serial = 0;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    final serial = ++_serial;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted && serial == _serial) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final lang = widget.language;
    return Container(
      key: const Key('agent-code-block'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: agentSunk(c),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.line),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 34, 10),
            child: Text(
              widget.text,
              softWrap: true,
              style: UiText.mono(12, color: c.ink, height: 1.55),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: AgentIconButton(
              key: const Key('agent-code-copy'),
              small: true,
              glyph: _copied ? AgentGlyphs.check : AgentGlyphs.copy,
              color: _copied ? c.ok : null,
              tooltip: _copied
                  ? l.ag_copied
                  : lang.isEmpty
                  ? l.ag_copy
                  : '${l.ag_copy} · $lang',
              onPressed: _copy,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── 过程 ───────────────────────────────

/// 一轮回答按顺序切成若干段：连续的过程（思考 + 工具步骤）合成一段，
/// 文字、改动卡、产物各自一段；连续几次带缩略图的看图合成一组。
sealed class _Seg {}

final class _ProcSeg extends _Seg {
  final items = <Object>[]; // AgentThinkingBlock | AgentStep
}

final class _OutSeg extends _Seg {
  _OutSeg(this.item);
  final Object item; // AgentBlock | _ReadGroup
}

/// 连续几次看图（都已完成、都带图）合成一组；失败 / 进行中的单独一组、不再并入。
final class _ReadGroup {
  _ReadGroup(AgentStep first)
    : mergeable = first.status == AgentStepStatus.done {
    steps.add(first);
  }
  final steps = <AgentStep>[];
  final bool mergeable;

  List<AgentImage> get images => [for (final s in steps) ...s.images];
}

List<_Seg> _segments(List<AgentBlock> blocks) {
  final out = <_Seg>[];
  _ProcSeg proc() {
    if (out.lastOrNull case final _ProcSeg p) return p;
    final p = _ProcSeg();
    out.add(p);
    return p;
  }

  for (final b in blocks) {
    switch (b) {
      case AgentThinkingBlock():
        proc().items.add(b);
      case AgentStepsBlock(:final steps):
        for (final st in steps) {
          if (st.tool == 'image_read' && st.images.isNotEmpty) {
            final last = out.lastOrNull;
            if (st.status == AgentStepStatus.done &&
                last is _OutSeg &&
                last.item is _ReadGroup &&
                (last.item as _ReadGroup).mergeable) {
              (last.item as _ReadGroup).steps.add(st);
            } else {
              out.add(_OutSeg(_ReadGroup(st)));
            }
          } else {
            proc().items.add(st);
          }
        }
      default:
        out.add(_OutSeg(b));
    }
  }
  return out;
}

bool _settled(Object item) => switch (item) {
  AgentThinkingBlock(:final live) => !live,
  AgentStep(:final status) => status == AgentStepStatus.done,
  _ => true,
};

DateTime? _at(Object item) => switch (item) {
  AgentThinkingBlock(:final at) => at,
  AgentTextBlock(:final at) => at,
  AgentStep(:final at) => at,
  _ReadGroup(:final steps) => steps.first.at,
  _ => null,
};

/// 一段过程的大致用时：第一条的时间 → 下一段开始（或最后一步结束）。
Duration? _took(List<Object> items, Object? next) {
  final start = items.map(_at).nonNulls.firstOrNull;
  if (start == null) return null;
  var end = next == null ? null : _at(next);
  if (end == null) {
    for (final it in items) {
      final at = _at(it);
      if (at == null) continue;
      final e = it is AgentStep && it.duration != null
          ? at.add(it.duration!)
          : at;
      if (end == null || e.isAfter(end)) end = e;
    }
  }
  if (end == null || !end.isAfter(start)) return null;
  return end.difference(start);
}

AgentActivityKind _kindOf(Object item) =>
    item is AgentStep ? agentActivityKind(item.tool) : AgentActivityKind.think;

/// 一段过程：时间线（图标之间细竖线串起来）；收起时只剩一行
/// 「已处理 · 思考 13 次 · 运行命令 12 次 · 1m 20s」，点开看全部。
class _Process extends StatefulWidget {
  const _Process({
    super.key,
    required this.index,
    required this.scope,
    required this.items,
    required this.foldable,
    required this.live,
    this.took,
  });
  final int index;

  /// 所在这一轮的 id（记「出现过」用）。
  final String scope;
  final List<Object> items;
  final bool foldable, live;
  final Duration? took;

  @override
  State<_Process> createState() => _ProcessState();
}

class _ProcessState extends State<_Process> {
  static const _limit = 6;
  var _open = false;
  var _all = false;
  final _detail = <String>{};

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final Widget content;
    if (!widget.foldable) {
      content = _timeline(context, all: _all);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FoldRow(
            key: Key('agent-fold-${widget.index}'),
            items: widget.items,
            took: widget.took,
            open: _open,
            onTap: () => setState(() => _open = !_open),
          ),
          if (still)
            ?_body()
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _body() ?? const SizedBox(width: double.infinity),
            ),
        ],
      );
    }
    if (still) return content;
    // 一段过程收起 / 展开成时间线时：旧样子淡出、新样子淡入，高度一起变。
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        layoutBuilder: (current, previous) => Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final p in previous)
              Positioned(top: 0, left: 0, right: 0, child: p),
            ?current,
          ],
        ),
        child: KeyedSubtree(key: ValueKey(widget.foldable), child: content),
      ),
    );
  }

  Widget? _body() => _open
      ? Padding(
          key: Key('agent-fold-body-${widget.index}'),
          padding: const EdgeInsets.only(top: 2),
          child: _timeline(context, all: true),
        )
      : null;

  Widget _timeline(BuildContext context, {required bool all}) {
    final l = context.l10n;
    final items = widget.items;
    // 进行中的长段只留最后几步（正在做 / 等你处理的总在最后）。
    final hidden = !all && items.length > _limit
        ? items.length - (_limit - 1)
        : 0;
    final shown = hidden > 0 ? items.sublist(hidden) : items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        if (hidden > 0)
          _StepRow(
            key: const Key('agent-steps-more'),
            dot: const SizedBox.square(dimension: 16),
            label: l.ag_stepsMore(hidden),
            muted: true,
            rail: true,
            onTap: () => setState(() => _all = true),
          ),
        for (final (i, item) in shown.indexed)
          AgentAppear(
            key: ValueKey(
              item is AgentStep ? 'step-${item.id}' : 'think-${hidden + i}',
            ),
            id: '${widget.scope}/${item is AgentStep ? 'step-${item.id}' : 'think-${widget.index}-${hidden + i}'}',
            enabled: widget.live,
            // 高度交给外层的 AnimatedSize 平滑，这里只淡入上浮。
            grow: false,
            child: switch (item) {
              AgentThinkingBlock() => AgentThinking(
                block: item,
                rail: i < shown.length - 1,
              ),
              AgentStep() => _step(context, item, rail: i < shown.length - 1),
              _ => const SizedBox.shrink(),
            },
          ),
      ],
    );
  }

  Widget _step(BuildContext context, AgentStep step, {required bool rail}) {
    final open = _detail.contains(step.id);
    final expandable =
        step.arguments != null || step.result != null || step.images.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgentStepRow(
          step: step,
          rail: rail && !open,
          open: open,
          onTap: expandable
              ? () => setState(
                  () => open ? _detail.remove(step.id) : _detail.add(step.id),
                )
              : null,
        ),
        if (step.tags.isNotEmpty && step.status == AgentStepStatus.done)
          _TagHits(step: step),
        if (open) _StepDetail(step: step),
      ],
    );
  }
}

/// 收起的过程：类型小图标簇 + 「已处理」+ 汇总 + 用时 + 箭头。
class _FoldRow extends StatefulWidget {
  const _FoldRow({
    super.key,
    required this.items,
    required this.took,
    required this.open,
    required this.onTap,
  });
  final List<Object> items;
  final Duration? took;
  final bool open;
  final VoidCallback onTap;

  @override
  State<_FoldRow> createState() => _FoldRowState();
}

class _FoldRowState extends State<_FoldRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final counts = <AgentActivityKind, int>{};
    for (final it in widget.items) {
      counts.update(_kindOf(it), (n) => n + 1, ifAbsent: () => 1);
    }
    final summary = [
      for (final e in counts.entries)
        l.ag_foldTimes(agentActivityLabel(l, e.key), e.value),
    ].join(' · ');
    final still = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: _hover ? c.hover : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            spacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  for (final k in counts.keys.take(4))
                    AgentActivityGlyph(k, size: 12, color: c.muted),
                ],
              ),
              Expanded(
                child: AgentOverflowText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l.ag_foldDone,
                        style: TextStyle(color: c.ink.withValues(alpha: .72)),
                      ),
                      TextSpan(text: '   $summary'),
                    ],
                  ),
                  tooltip: [
                    for (final e in counts.entries)
                      l.ag_foldTimes(agentActivityLabel(l, e.key), e.value),
                    if (widget.took != null) agentDuration(widget.took!),
                  ].join('\n'),
                  style: UiText.sans(12, color: c.muted, height: 1.2),
                ),
              ),
              if (widget.took != null)
                Text(
                  agentDuration(widget.took!),
                  style: UiText.mono(11, color: c.faint, height: 1),
                ),
              AnimatedRotation(
                turns: widget.open ? .25 : 0,
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: AgentIcon(
                  AgentGlyphs.chevronRight,
                  size: 12,
                  color: _hover || widget.open ? c.muted : c.faint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 思考内容：默认一行「已思考 · N 字」，点开看原文；流式中「思考中 · N 字」带流光。
class AgentThinking extends StatefulWidget {
  const AgentThinking({super.key, required this.block, this.rail = false});
  final AgentThinkingBlock block;

  /// 下面还有一步：图标下画一段细竖线连到下一行。
  final bool rail;

  @override
  State<AgentThinking> createState() => _AgentThinkingState();
}

class _AgentThinkingState extends State<AgentThinking>
    with SingleTickerProviderStateMixin {
  var _open = false;
  var _still = true;
  late final _progress = AgentStreamProgress(this, widget.block.text);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) _progress.finish();
  }

  @override
  void didUpdateWidget(covariant AgentThinking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.text != widget.block.text) {
      _progress.update(
        widget.block.text,
        animate: widget.block.live && !_still,
      );
    }
    if (!widget.block.live) _progress.finish();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final b = widget.block;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: _progress,
          builder: (context, _) => _StepRow(
            key: const Key('agent-thinking'),
            dot: AgentActivityIcon(
              kind: AgentActivityKind.think,
              state: b.live
                  ? AgentActivityState.running
                  : AgentActivityState.done,
            ),
            label: b.live ? l.ag_thinkingLive : l.ag_thought,
            subject: _progress.visibleCharacters == 0
                ? null
                : l.ag_thoughtChars(_progress.visibleCharacters),
            muted: true,
            shimmer: b.live,
            rail: widget.rail && !_open,
            open: _open,
            onTap: b.text.isEmpty
                ? null
                : () => setState(() {
                    _progress.finish();
                    _open = !_open;
                  }),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 2, 6, 8),
            child: Container(
              key: const Key('agent-thinking-text'),
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.fromLTRB(17, 2, 4, 2),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: c.border, width: 1)),
              ),
              child: SingleChildScrollView(
                child: Listener(
                  onPointerDown: (_) => _progress.finish(),
                  child: AgentStreamReveal(
                    progress: _progress,
                    child: Text(
                      b.text,
                      style: UiText.sans(11.5, color: c.muted, height: 1.65),
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

/// 一个工具步骤的行：类型图标 + 动作名 + 等宽工具名 + 右侧耗时。
class AgentStepRow extends StatelessWidget {
  const AgentStepRow({
    super.key,
    required this.step,
    this.rail = false,
    this.open = false,
    this.onTap,
  });
  final AgentStep step;
  final bool rail, open;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = step.duration;
    return _StepRow(
      key: Key('agent-step-${step.id}'),
      dot: AgentActivityIcon(
        kind: agentActivityKind(step.tool),
        state: switch (step.status) {
          AgentStepStatus.done => AgentActivityState.done,
          AgentStepStatus.running => AgentActivityState.running,
          AgentStepStatus.failed => AgentActivityState.failed,
          AgentStepStatus.waitingUser => AgentActivityState.waiting,
        },
      ),
      label: agentToolLabel(l, step.tool),
      subject: step.subject,
      tool: step.tool,
      trailing: switch (step.status) {
        AgentStepStatus.running => null,
        AgentStepStatus.failed => l.ag_stepFailed,
        _ => d == null ? null : agentDuration(d),
      },
      quiet: d != null && d.inMilliseconds < 1000,
      shimmer: step.status == AgentStepStatus.running,
      strong: step.status == AgentStepStatus.waitingUser,
      error: step.status == AgentStepStatus.failed,
      rail: rail,
      open: open,
      onTap: onTap,
    );
  }
}

/// 看图：连续几次合成一组，一行「查看图片 · 4 张」+ 总用时，下面缩略图排开（多了换行加高）。
/// 点缩略图放大、组内左右切换；点标题行展开每次的参数。只有一次时和普通步骤行一样。
class _ReadGroupView extends StatefulWidget {
  const _ReadGroupView({super.key, required this.group});
  final _ReadGroup group;

  @override
  State<_ReadGroupView> createState() => _ReadGroupViewState();
}

class _ReadGroupViewState extends State<_ReadGroupView> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final steps = widget.group.steps;
    final first = steps.first;
    final single = steps.length == 1;
    final images = widget.group.images;
    final expandable = steps.any(
      (s) => s.arguments != null || s.result != null,
    );
    var total = Duration.zero;
    var known = true;
    for (final s in steps) {
      if (s.duration == null) {
        known = false;
      } else {
        total += s.duration!;
      }
    }
    final toggle = expandable ? () => setState(() => _open = !_open) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (single)
          AgentStepRow(step: first, open: _open, onTap: toggle)
        else
          _StepRow(
            key: Key('agent-read-group-${first.id}'),
            dot: const AgentActivityIcon(
              kind: AgentActivityKind.image,
              state: AgentActivityState.done,
            ),
            label: l.ag_readImages(steps.length),
            tool: 'image_read',
            trailing: known ? agentDuration(total) : null,
            quiet: known && total.inMilliseconds < 1000,
            open: _open,
            onTap: toggle,
          ),
        Padding(
          key: Key('agent-step-images-${first.id}'),
          padding: const EdgeInsets.fromLTRB(31, 4, 6, 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in steps)
                for (final img in s.images)
                  AgentThumb(
                    image: img,
                    width: 64,
                    height: 64,
                    group: images,
                    tooltip: [
                      ?s.subject,
                      if (s.duration != null) agentDuration(s.duration!),
                    ].join(' · '),
                  ),
            ],
          ),
        ),
        if (_open)
          for (final s in steps) ...[
            if (!single)
              Padding(
                padding: const EdgeInsets.fromLTRB(31, 4, 6, 0),
                child: AgentOverflowText(
                  [
                    ?s.subject,
                    if (s.duration != null) agentDuration(s.duration!),
                  ].join(' · '),
                  style: UiText.mono(11, color: c.faint, height: 1.4),
                ),
              ),
            _StepDetail(step: s),
          ],
      ],
    );
  }
}

/// 查询类步骤查到的标签：一排小标签（颜色 = 类别），悬停看译名 / 热度 / 简介，点一下复制。
class _TagHits extends StatefulWidget {
  const _TagHits({required this.step});
  final AgentStep step;

  @override
  State<_TagHits> createState() => _TagHitsState();
}

class _TagHitsState extends State<_TagHits> {
  static const _limit = 12;
  var _all = false;

  static Color color(UiColors c, AgentTagCategory k) => switch ((k, c.dark)) {
    (AgentTagCategory.general, true) => const Color(0xff62b9f0),
    (AgentTagCategory.general, false) => const Color(0xff176d9f),
    (AgentTagCategory.artist, true) => const Color(0xffff7b78),
    (AgentTagCategory.artist, false) => const Color(0xffb52c2a),
    (AgentTagCategory.copyright, true) => const Color(0xffd083e0),
    (AgentTagCategory.copyright, false) => const Color(0xff7b4389),
    (AgentTagCategory.character, true) => const Color(0xff7bd27e),
    (AgentTagCategory.character, false) => const Color(0xff2b7834),
    (AgentTagCategory.meta, true) => const Color(0xffffb85c),
    (AgentTagCategory.meta, false) => const Color(0xff925b08),
    (AgentTagCategory.other, _) => c.muted,
  };

  static String category(AppLocalizations l, AgentTagCategory k) => switch (k) {
    AgentTagCategory.general => l.autocomplete_categoryGeneral,
    AgentTagCategory.artist => l.autocomplete_categoryArtist,
    AgentTagCategory.copyright => l.autocomplete_categoryCopyright,
    AgentTagCategory.character => l.autocomplete_categoryCharacter,
    AgentTagCategory.meta => l.autocomplete_categoryMeta,
    AgentTagCategory.other => '',
  };

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.controlsOf(context);
    final c = context.ui;
    final l = context.l10n;
    final step = widget.step;
    final tags = step.tags;
    final shown = _all || tags.length <= _limit
        ? tags
        : tags.sublist(0, _limit - 1);
    Widget chip(AgentTagHit t) {
      final tint = color(c, t.category);
      final tip = [
        [
          t.tag,
          if (t.translation != null && t.translation!.isNotEmpty)
            t.translation!,
        ].join(' · '),
        [
          category(l, t.category),
          if (t.count != null) l.ag_tagCount(agentNumber(t.count!)),
        ].where((x) => x.isNotEmpty).join(' · '),
        if (t.summary != null && t.summary!.isNotEmpty) t.summary!,
      ].where((x) => x.isNotEmpty).join('\n');
      return Tooltip(
        message: tip,
        waitDuration: const Duration(milliseconds: 450),
        constraints: const BoxConstraints(maxWidth: 320),
        child: _Chip(
          key: Key('agent-tag-${step.id}-${t.tag}'),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: t.tag));
            s.toast(l.ag_tagCopied(t.tag));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  t.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(11, color: c.ink, height: 1.2),
                ),
              ),
              if (t.count != null)
                Text(
                  agentTokens(t.count!),
                  style: UiText.mono(10, color: c.faint, height: 1.2),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      key: Key('agent-step-tags-${step.id}'),
      padding: const EdgeInsets.fromLTRB(31, 2, 6, 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final t in shown) chip(t),
          if (shown.length < tags.length)
            _Chip(
              key: Key('agent-tags-more-${step.id}'),
              onTap: () => setState(() => _all = true),
              child: Text(
                l.ag_galleryMore(tags.length - shown.length),
                style: UiText.mono(11, color: c.muted, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: _hover ? c.hover : agentSunk(c),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _hover ? c.border : c.line),
          ),
          child: widget.child,
        ),
      ),
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
    this.rail = false,
    this.shimmer = false,
    this.quiet = false,
    this.onTap,
  });
  final Widget dot;
  final String label;
  final String? subject, tool, trailing;
  final bool strong, muted, error, open;

  /// 下面还有一行：图标下画细竖线连过去（时间线）。
  final bool rail;

  /// 正在进行：文字带流光。
  final bool shimmer;

  /// 不到 1 秒的耗时用更淡的字色。
  final bool quiet;
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
              SizedBox.square(
                dimension: 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (widget.rail)
                      Positioned(
                        left: 7.5,
                        top: 20,
                        child: Container(width: 1, height: 12, color: c.line),
                      ),
                    widget.dot,
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  spacing: 8,
                  children: [
                    Flexible(
                      child: AgentShimmer(
                        enabled: widget.shimmer,
                        child: AgentOverflowText.rich(
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
                    ),
                    if (showTool)
                      Flexible(
                        child: AgentOverflowText(
                          widget.tool!,
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
                    color: widget.error
                        ? c.error
                        : widget.quiet
                        ? c.faint.withValues(alpha: .6)
                        : c.faint,
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
          if (step.images.isNotEmpty && step.tool != 'image_read')
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
  'prompt_set' => l.ag_tool_prompt_set,
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

/// 提示词改动卡的正文窗口：按逗号切成 tag，只留改动附近（前后各 [context] 个），
/// 两处改动中间隔太远、开头结尾没改的长段都换成「…」。

class AgentDiffView extends StatefulWidget {
  const AgentDiffView({super.key, required this.diff});
  final AgentPromptDiff diff;

  /// 收起时正文最多几行。
  static const maxLines = 14;

  @override
  State<AgentDiffView> createState() => _AgentDiffViewState();
}

class _AgentDiffViewState extends State<AgentDiffView> {
  var _all = false;
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  void _expand() => setState(() => _all = true);

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.controlsOf(context);
    final c = context.ui;
    final l = context.l10n;
    final diff = widget.diff;
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
    final style = diff.state == AgentDiffState.undone
        ? base.copyWith(color: c.faint)
        : base;
    final window = agentDiffWindow(diff.segments);
    final trimmed = window.contains(null);
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    TextStyle? kindStyle(AgentDiffKind k) => switch (k) {
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
    };
    TapGestureRecognizer tap() {
      final t = TapGestureRecognizer()..onTap = _expand;
      _taps.add(t);
      return t;
    }

    final shown = _all ? diff.segments : window;
    final span = TextSpan(
      children: [
        for (final seg in shown)
          if (seg == null)
            TextSpan(
              text: ' … ',
              style: TextStyle(color: c.faint, fontWeight: FontWeight.w600),
              mouseCursor: SystemMouseCursors.click,
              recognizer: tap(),
            )
          else
            TextSpan(text: seg.text, style: kindStyle(seg.kind)),
      ],
    );
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
                      child: AgentOverflowText(
                        field,
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
          child: LayoutBuilder(
            builder: (context, box) {
              var over = false;
              if (!_all) {
                final tp = TextPainter(
                  text: TextSpan(style: style, children: [span]),
                  maxLines: AgentDiffView.maxLines,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: box.maxWidth);
                over = tp.didExceedMaxLines;
                tp.dispose();
              }
              final more = _all || trimmed || over;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    span,
                    key: Key('agent-diff-text-${diff.id}'),
                    maxLines: _all ? null : AgentDiffView.maxLines,
                    overflow: _all ? null : TextOverflow.ellipsis,
                    style: style,
                  ),
                  if (more)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: AgentButton(
                          key: Key('agent-diff-more-${diff.id}'),
                          label: _all ? l.ag_diffCollapse : l.ag_diffExpand,
                          style: AgentButtonStyle.ghost,
                          height: 22,
                          onPressed: () => setState(() => _all = !_all),
                        ),
                      ),
                    ),
                ],
              );
            },
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
    final s = AgentScope.controlsOf(context);
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

// ─────────────────────────────── 设置 / 画廊 / 压缩 ───────────────────────────────

/// 应用设置改动卡：每行「设置项  旧值 → 新值」+「去设置」，整张一起撤销。
class AgentSettingsView extends StatelessWidget {
  const AgentSettingsView({super.key, required this.block});
  final AgentSettingsBlock block;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.controlsOf(context);
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
      key: Key('agent-settings-${block.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            spacing: 6,
            children: [
              AgentIcon(AgentGlyphs.gear, size: 14, color: c.muted),
              Expanded(
                child: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: AgentOverflowText(
                        l.ag_settingsTitle,
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
          padding: const EdgeInsets.fromLTRB(11, 6, 6, 6),
          decoration: BoxDecoration(
            color: agentSunk(c),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              for (final ch in block.changes)
                SizedBox(
                  key: Key('agent-setting-${block.id}-${ch.key}'),
                  height: 26,
                  child: Row(
                    spacing: 8,
                    children: [
                      SizedBox(
                        width: 104,
                        child: AgentOverflowText(
                          ch.label,
                          style: UiText.sans(12, color: c.muted, height: 1.4),
                        ),
                      ),
                      Expanded(
                        child: AgentOverflowText.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: ch.before,
                                style: old.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: c.faint,
                                ),
                              ),
                              TextSpan(text: '  →  ', style: old),
                              TextSpan(text: ch.after, style: now),
                            ],
                          ),
                        ),
                      ),
                      if (ch.anchor != null)
                        AgentIconButton(
                          key: Key('agent-setting-go-${block.id}-${ch.key}'),
                          small: true,
                          glyph: AgentGlyphs.chevronRight,
                          tooltip: l.ag_settingsGo,
                          onPressed: () => s.actions.onOpenSettingAt(
                            ch.anchor!.section,
                            ch.anchor!.anchor,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 画廊操作卡：一句话「已收藏 3 张」+ 缩略图；能撤销的带撤销。
class AgentGalleryView extends StatelessWidget {
  const AgentGalleryView({super.key, required this.block});
  final AgentGalleryBlock block;

  static const _thumbs = 8;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.controlsOf(context);
    final c = context.ui;
    final l = context.l10n;
    final n = block.count > 0 ? block.count : block.images.length;
    final target = block.target ?? '—';
    final text = switch (block.action) {
      AgentGalleryAction.favorite => l.ag_galleryFavorite(n),
      AgentGalleryAction.unfavorite => l.ag_galleryUnfavorite(n),
      AgentGalleryAction.tags => l.ag_galleryTags(n),
      AgentGalleryAction.move => l.ag_galleryMove(n, target),
      AgentGalleryAction.copy => l.ag_galleryCopy(n, target),
      AgentGalleryAction.delete => l.ag_galleryDelete(n),
      AgentGalleryAction.restore => l.ag_galleryRestore(n),
      AgentGalleryAction.collectionAdd => l.ag_galleryCollectionAdd(n, target),
      AgentGalleryAction.collectionRemove => l.ag_galleryCollectionRemove(
        n,
        target,
      ),
      AgentGalleryAction.export => l.ag_galleryExport(n),
    };
    final glyph = switch (block.action) {
      AgentGalleryAction.favorite ||
      AgentGalleryAction.unfavorite => AgentGlyphs.star,
      AgentGalleryAction.delete => AgentGlyphs.trash,
      AgentGalleryAction.restore => AgentGlyphs.undo,
      AgentGalleryAction.move ||
      AgentGalleryAction.copy ||
      AgentGalleryAction.export => AgentGlyphs.folder,
      AgentGalleryAction.tags ||
      AgentGalleryAction.collectionAdd ||
      AgentGalleryAction.collectionRemove => AgentGlyphs.layers,
    };
    final shown = block.images.take(_thumbs).toList();
    final extra = n - shown.length;
    return Column(
      key: Key('agent-gallery-${block.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            spacing: 6,
            children: [
              AgentIcon(glyph, size: 14, color: c.muted),
              Expanded(
                child: AgentOverflowText(
                  text,
                  style: UiText.sans(
                    12,
                    weight: FontWeight.w600,
                    color: block.state == AgentDiffState.undone
                        ? c.faint
                        : c.ink,
                  ),
                ),
              ),
              if (block.undoable || block.state == AgentDiffState.undone)
                _DiffStatus(
                  id: block.id,
                  state: block.state,
                  onUndo: () => s.actions.onUndoDiff(block.id),
                ),
            ],
          ),
        ),
        if (shown.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final img in shown)
                AgentThumb(
                  image: img,
                  width: 56,
                  height: 56,
                  group: block.images,
                ),
              if (extra > 0)
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.ag_galleryMore(extra),
                    style: UiText.mono(12, color: c.muted),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// 上下文压缩分隔线：「之前的对话已压缩」，点开看压缩后留下的摘要。
class AgentCompactionView extends StatefulWidget {
  const AgentCompactionView({super.key, required this.block});
  final AgentCompactionBlock block;

  @override
  State<AgentCompactionView> createState() => _AgentCompactionViewState();
}

class _AgentCompactionViewState extends State<AgentCompactionView> {
  var _open = false;
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final b = widget.block;
    final still = MediaQuery.disableAnimationsOf(context);
    final line = Expanded(child: Container(height: 1, color: c.line));
    final body = _open
        ? Container(
            key: const Key('agent-compaction-summary'),
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.border)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  if (b.tokensBefore != null)
                    Text(
                      l.ag_compactedTokens(agentTokens(b.tokensBefore!)),
                      style: UiText.mono(11, color: c.faint, height: 1.4),
                    ),
                  Text(
                    b.summary,
                    style: UiText.sans(11.5, color: c.muted, height: 1.65),
                  ),
                ],
              ),
            ),
          )
        : null;
    return Column(
      key: const Key('agent-compaction'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tooltip(
          message: b.summary.isEmpty
              ? ''
              : _open
              ? l.ag_compactedHide
              : l.ag_compactedShow,
          waitDuration: const Duration(milliseconds: 600),
          child: MouseRegion(
            cursor: b.summary.isEmpty
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: b.summary.isEmpty
                  ? null
                  : () => setState(() => _open = !_open),
              child: SizedBox(
                height: 22,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    line,
                    AgentIcon(AgentGlyphs.layers, size: 12, color: c.faint),
                    Flexible(
                      flex: 6,
                      child: Text(
                        b.auto ? l.ag_compactedAuto : l.ag_compacted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          11.5,
                          color: _hover ? c.muted : c.faint,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (b.summary.isNotEmpty)
                      AnimatedRotation(
                        turns: _open ? .5 : 0,
                        duration: still
                            ? Duration.zero
                            : const Duration(milliseconds: 160),
                        child: AgentIcon(
                          AgentGlyphs.chevron,
                          size: 12,
                          color: _hover ? c.muted : c.faint,
                        ),
                      ),
                    line,
                  ],
                ),
              ),
            ),
          ),
        ),
        if (still)
          ?body
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: body ?? const SizedBox(width: double.infinity),
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
    final s = AgentScope.controlsOf(context);
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
    final s = AgentScope.controlsOf(context);
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
  static const palette = AgentPositionBoard.palette;

  static Color colorOf(int index) => AgentPositionBoard.colorOf(index);

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
              AgentPositionBoard(block: block),
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
          AgentPositionDot(index: m.index, size: 16),
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
                    group: block.images,
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
    this.group,
    this.tooltip,
  });
  final AgentImage image;
  final double width, height;

  /// 同一组的图：放大后可以左右切换。
  final List<AgentImage>? group;

  /// 悬停说明（看图组：图片 id · 用时）。
  final String? tooltip;

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
    final s = AgentScope.controlsOf(context);
    final c = context.ui;
    final img = widget.image;
    final label = [if (img.starred) '★', ?img.label].join(' ');
    Widget thumb = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => s.zoom(img, group: widget.group),
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
    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      thumb = Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: thumb,
      );
    }
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
  final s = AgentScope.controlsOf(context);
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
  final s = AgentScope.controlsOf(context);
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
