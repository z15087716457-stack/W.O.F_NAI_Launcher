import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_svg_icon.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_scope.dart';

/// 弹层里的一行：34 高、7 圆角、悬停 / 键盘选中灰底。
class AgentPopRow extends StatefulWidget {
  const AgentPopRow({
    super.key,
    this.child,
    required this.onTap,
    this.selected = false,
    this.height = 34,
    this.builder,
  }) : assert(child != null || builder != null);
  final Widget? child;

  /// 需要随悬停变化的内容（例如悬停才出现的删除按钮）。
  final Widget Function(BuildContext context, bool hover)? builder;
  final VoidCallback? onTap;
  final bool selected;
  final double height;

  @override
  State<AgentPopRow> createState() => _AgentPopRowState();
}

class _AgentPopRowState extends State<AgentPopRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
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
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.selected || _hover ? c.hover : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: DefaultTextStyle.merge(
            style: UiText.sans(12.5, color: c.ink, height: 1.2),
            child: widget.builder?.call(context, _hover) ?? widget.child!,
          ),
        ),
      ),
    );
  }
}

/// 删除聊天：调用方已在原地确认过（列表行内两个按钮 / 菜单项再点一次）→
/// 移进回收区 → 底部可撤销提示。
Future<void> agentDeleteChat(BuildContext context, AgentChatInfo chat) async {
  final s = AgentScope.of(context);
  final l = context.l10n;
  String? token;
  await s.run(() async {
    token = await s.actions.onDeleteChat(chat.id);
    return token != null;
  });
  final t = token;
  if (t != null) {
    s.undoToast(l.ag_chatDeleted(chat.title), () => s.actions.onUndoDelete(t));
  }
}

/// 删除工作区：影响整组聊天，仍用确认弹窗（只盖侧栏）→ 回收区 → 可撤销提示；
/// 只剩一个时调用方已禁用入口。
Future<void> agentDeleteWorkspace(
  BuildContext context,
  AgentWorkspaceInfo workspace,
) async {
  final s = AgentScope.of(context);
  final l = context.l10n;
  final ok = await s.confirm(
    title: l.ag_deleteWorkspaceTitle,
    message: l.ag_deleteWorkspaceBody(workspace.name),
    confirm: l.ag_delete,
    danger: true,
  );
  if (ok == null) return;
  String? token;
  await s.run(() async {
    token = await s.actions.onDeleteWorkspace(workspace.id);
    return token != null;
  });
  final t = token;
  if (t != null) {
    s.undoToast(
      l.ag_workspaceDeleted(workspace.name),
      () => s.actions.onUndoDelete(t),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {this.leading});
  final String text;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
    child: leading == null
        ? AgentEyebrow(text)
        : Row(
            spacing: 6,
            children: [
              leading!,
              Flexible(child: AgentEyebrow(text)),
            ],
          ),
  );
}

/// 模型分组标题前的服务商小图标：预设画品牌 SVG（单色跟随前景），自定义端点画字母块。
class AgentProviderLogo extends StatelessWidget {
  const AgentProviderLogo({
    super.key,
    this.logoAsset,
    this.mark,
    this.size = 13,
  });
  final String? logoAsset, mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    if (logoAsset case final asset?) {
      return UiSvgIcon.asset(
        'assets/icons/providers/$asset.svg',
        size: size,
        colorFilter: ColorFilter.mode(c.muted, BlendMode.srcIn),
        excludeFromSemantics: true,
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(size * .25),
      ),
      child: Text(
        mark ?? '',
        style: UiText.mono(
          size * .5,
          weight: FontWeight.w700,
          color: c.card,
          height: 1,
        ),
      ),
    );
  }
}

/// 聊天列表：搜索 + 当前工作区的聊天 + 切换工作区 + 新建工作区。
class AgentChatsPopover extends StatefulWidget {
  const AgentChatsPopover({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<AgentChatsPopover> createState() => _AgentChatsPopoverState();
}

class _AgentChatsPopoverState extends State<AgentChatsPopover> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  /// 正文命中：(查的词, 结果)；结果为 null = 正在查。
  (String, List<AgentChatHit>?)? _hits;

  /// 正在行内确认删除的聊天（同时只有一行）。
  String? _confirming;

  void _confirmDelete(String? id) {
    setState(() => _confirming = id);
    // 焦点留在列表里（搜索框在 Esc 处理之内），Esc 才先取消确认而不是关列表。
    if (id != null) _focus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String _) {
    _debounce?.cancel();
    final q = _query.text.trim();
    if (q.length < 2) {
      setState(() => _hits = null);
      return;
    }
    setState(() {});
    final search = AgentScope.of(context).actions.onSearchChats;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _hits = (q, null));
      List<AgentChatHit> found;
      try {
        found = await search(q);
      } catch (_) {
        found = const [];
      }
      if (mounted && _query.text.trim() == q) {
        setState(() => _hits = (q, found));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data, a = s.actions;
    final c = context.ui;
    final l = context.l10n;
    final q = _query.text.trim().toLowerCase();
    final chats = d.chats
        .where((x) => q.isEmpty || x.title.toLowerCase().contains(q))
        .toList();
    final others = d.workspaces
        .where(
          (w) =>
              w.id != d.workspace.id &&
              (q.isEmpty || w.name.toLowerCase().contains(q)),
        )
        .toList();
    final width = (MediaQuery.sizeOf(context).width - 24).clamp(240.0, 320.0);
    // 行内确认时 Esc 先取消确认，不关列表。
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, e) {
        if (_confirming != null &&
            e is KeyDownEvent &&
            e.logicalKey == LogicalKeyboardKey.escape) {
          _confirmDelete(null);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: UiPopoverSurface(
        key: const Key('agent-chats-popover'),
        width: width,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.line)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    AgentIcon(AgentGlyphs.search, size: 14, color: c.faint),
                    Expanded(
                      child: TextField(
                        key: const Key('agent-chats-search'),
                        controller: _query,
                        focusNode: _focus,
                        autofocus: true,
                        onChanged: _changed,
                        style: UiText.sans(12.5, color: c.ink),
                        cursorColor: c.accent,
                        cursorWidth: 1.5,
                        decoration: agentBareInput(
                          hint: l.ag_chatsSearch,
                          hintStyle: UiText.sans(12.5, color: c.faint),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GroupLabel(d.workspace.name),
                      if (chats.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                          child: Text(
                            l.ag_chatsNoMatch,
                            style: UiText.sans(12, color: c.faint),
                          ),
                        ),
                      for (final chat in chats)
                        if (_confirming == chat.id)
                          _DeleteConfirmRow(
                            key: Key('agent-chat-${chat.id}'),
                            id: chat.id,
                            title: chat.title,
                            onCancel: () => _confirmDelete(null),
                            // 确认后关列表：列表的遮罩会挡住底部的撤销提示。
                            onDelete: () {
                              widget.onClose();
                              agentDeleteChat(context, chat);
                            },
                          )
                        else
                          AgentPopRow(
                            key: Key('agent-chat-${chat.id}'),
                            selected: chat.id == d.chat.id,
                            onTap: () {
                              if (_confirming != null) {
                                _confirmDelete(null);
                                return;
                              }
                              widget.onClose();
                              if (chat.id != d.chat.id) {
                                s.run(() => a.onSelectChat(chat.id));
                              }
                            },
                            builder: (context, hover) => Row(
                              spacing: 9,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: switch (chat.state) {
                                      AgentChatState.waitingUser => c.warn,
                                      AgentChatState.running => c.accent,
                                      AgentChatState.idle =>
                                        chat.id == d.chat.id
                                            ? c.ink
                                            : Colors.transparent,
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    chat.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.sans(
                                      12.5,
                                      weight: chat.id == d.chat.id
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      color: c.ink,
                                    ),
                                  ),
                                ),
                                if (hover &&
                                    chat.state == AgentChatState.idle &&
                                    !(chat.id == d.chat.id &&
                                        d.status != AgentRunStatus.idle))
                                  AgentIconButton(
                                    key: Key('agent-chat-delete-${chat.id}'),
                                    small: true,
                                    glyph: AgentGlyphs.trash,
                                    tooltip: l.ag_menuDeleteChat,
                                    onPressed: () => _confirmDelete(chat.id),
                                  )
                                else
                                  Text(
                                    switch (chat.state) {
                                      AgentChatState.waitingUser =>
                                        l.ag_chatWaiting,
                                      AgentChatState.running =>
                                        l.ag_chatRunning,
                                      AgentChatState.idle => agentDay(
                                        chat.createdAt,
                                        d.now,
                                        l.ag_yesterday,
                                      ),
                                    },
                                    style: UiText.mono(
                                      11,
                                      color:
                                          chat.state ==
                                              AgentChatState.waitingUser
                                          ? c.warn
                                          : c.faint,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      if (_hits case (
                        final hq,
                        final found,
                      ) when hq == _query.text.trim()) ...[
                        _GroupLabel(l.ag_chatsContent),
                        if (found == null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                            child: Text(
                              l.ag_chatsSearching,
                              style: UiText.sans(12, color: c.faint),
                            ),
                          )
                        else if (found.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                            child: Text(
                              l.ag_chatsNoMatch,
                              style: UiText.sans(12, color: c.faint),
                            ),
                          )
                        else
                          for (final hit in found)
                            AgentPopRow(
                              key: Key('agent-chat-hit-${hit.chatId}'),
                              height: 48,
                              selected: hit.chatId == d.chat.id,
                              onTap: () {
                                widget.onClose();
                                if (hit.chatId != d.chat.id) {
                                  s.run(() => a.onSelectChat(hit.chatId));
                                }
                              },
                              child: Padding(
                                // 和上面聊天行的标题对齐（让出状态点的 7 + 9）。
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 2,
                                  children: [
                                    Text(
                                      hit.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    _Snippet(text: hit.snippet, query: hq),
                                  ],
                                ),
                              ),
                            ),
                      ],

                      if (others.isNotEmpty) ...[
                        _GroupLabel(l.ag_chatsSwitchWorkspace),
                        for (final w in others)
                          AgentPopRow(
                            key: Key('agent-workspace-${w.id}'),
                            onTap: () {
                              widget.onClose();
                              s.run(() => a.onSelectWorkspace(w.id));
                            },
                            child: Row(
                              spacing: 9,
                              children: [
                                AgentIcon(
                                  AgentGlyphs.folder,
                                  size: 14,
                                  color: c.faint,
                                ),
                                Expanded(
                                  child: Text(
                                    w.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (w.chatCount != null)
                                  Text(
                                    '${w.chatCount}',
                                    style: UiText.mono(11, color: c.faint),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Row(
                  children: [
                    AgentButton(
                      key: const Key('agent-new-workspace'),
                      label: l.ag_chatsNewWorkspace,
                      glyph: AgentGlyphs.plus,
                      style: AgentButtonStyle.ghost,
                      height: 26,
                      onPressed: () {
                        widget.onClose();
                        s.rename(
                          title: l.ag_chatsNewWorkspace,
                          value: '',
                          save: a.onCreateWorkspace,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 行内删除确认：这一行泛红，标题照常显示，右侧换成“取消 / 删除”。
class _DeleteConfirmRow extends StatelessWidget {
  const _DeleteConfirmRow({
    super.key,
    required this.id,
    required this.title,
    required this.onCancel,
    required this.onDelete,
  });
  final String id, title;
  final VoidCallback onCancel, onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        spacing: 6,
        children: [
          AgentIcon(AgentGlyphs.trash, size: 13, color: c.error),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12.5, color: c.ink, height: 1.2),
            ),
          ),
          AgentButton(
            key: Key('agent-chat-delete-cancel-$id'),
            label: l.ag_cancel,
            height: 24,
            style: AgentButtonStyle.ghost,
            onPressed: onCancel,
          ),
          AgentButton(
            key: Key('agent-chat-delete-ok-$id'),
            label: l.ag_delete,
            height: 24,
            style: AgentButtonStyle.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// 正文命中片段：命中词加粗。
class _Snippet extends StatelessWidget {
  const _Snippet({required this.text, required this.query});
  final String text, query;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final i = query.isEmpty
        ? -1
        : text.toLowerCase().indexOf(query.toLowerCase());
    return Text.rich(
      i < 0
          ? TextSpan(text: text)
          : TextSpan(
              children: [
                TextSpan(text: text.substring(0, i)),
                TextSpan(
                  text: text.substring(i, i + query.length),
                  style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: text.substring(i + query.length)),
              ],
            ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.sans(11, color: c.faint, height: 1.3),
    );
  }
}

/// 上下文与用量弹层。
class AgentUsagePopover extends StatelessWidget {
  const AgentUsagePopover({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final u = s.data.usage;
    final c = context.ui;
    final l = context.l10n;
    final f = u.fraction;
    Widget row(String label, int? value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: UiText.sans(12, color: c.muted)),
          ),
          Text(
            value == null ? '—' : agentNumber(value),
            style: UiText.mono(12, color: c.ink),
          ),
        ],
      ),
    );
    return UiPopoverSurface(
      key: const Key('agent-usage-popover'),
      width: 272,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.ag_usageTitle,
            style: UiText.sans(13, weight: FontWeight.w600, color: c.ink),
          ),
          const SizedBox(height: 10),
          AgentEyebrow(l.ag_usageContext),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 6,
            children: [
              Text(
                f == null ? '—' : '${(f * 100).toStringAsFixed(1)}%',
                style: UiText.mono(
                  22,
                  weight: FontWeight.w600,
                  color: c.ink,
                  height: 1.1,
                ),
              ),
              if (u.tokens != null && u.window != null)
                Flexible(
                  child: Text(
                    '${agentTokens(u.tokens!)} / ${agentTokens(u.window!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.mono(11.5, color: c.faint),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: c.control)),
                  if (f != null)
                    FractionallySizedBox(
                      widthFactor: f,
                      child: ColoredBox(color: f > .85 ? c.warn : c.accent),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            f == null
                ? l.ag_usageUnknown
                : l.ag_usageRemaining(agentNumber(u.window! - u.tokens!)),
            style: UiText.sans(11.5, color: c.faint),
          ),
          Container(
            height: 1,
            color: c.line,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          AgentEyebrow(l.ag_usageSession),
          const SizedBox(height: 6),
          row(l.ag_usageInput, u.input),
          row(l.ag_usageOutput, u.output),
          row(l.ag_usageCacheRead, u.cacheRead),
          row(l.ag_usageCacheWrite, u.cacheWrite),
          row(l.ag_usageTotal, u.total),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.ag_usageMessages,
                    style: UiText.sans(12, color: c.muted),
                  ),
                ),
                Text(
                  '${u.userMessages ?? '—'} / ${u.assistantMessages ?? '—'} · ${u.toolCalls ?? '—'}',
                  style: UiText.mono(12, color: c.ink),
                ),
              ],
            ),
          ),
          if ((u.anlas ?? 0) > 0)
            Padding(
              key: const Key('agent-usage-anlas'),
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.ag_usageAnlas,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ),
                  Text(
                    '≈ ${u.anlas} Anlas',
                    style: UiText.mono(12, color: c.ink),
                  ),
                ],
              ),
            ),
          if (u.cacheWarming case final w?) ...[
            Container(
              height: 1,
              color: c.line,
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            AgentCacheWarmingSection(data: w),
          ],
          const SizedBox(height: 4),
          Text(l.ag_usageCost, style: UiText.sans(11, color: c.faint)),
          const SizedBox(height: 12),
          AgentButton(
            key: const Key('agent-usage-compact'),
            label: l.ag_usageCompact,
            glyph: AgentGlyphs.layers,
            expand: true,
            onPressed: s.data.status == AgentRunStatus.idle
                ? () {
                    onClose();
                    s.run(s.actions.onCompact);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// 上下文弹窗里的「缓存预热」一节（10-25）：模式 · 状态点 · 下次续期倒计时 / 停止原因。
/// 只显示 Pi 给的状态；价格未知时不显示预计节省。
class AgentCacheWarmingSection extends StatefulWidget {
  const AgentCacheWarmingSection({super.key, required this.data});
  final AgentCacheWarmingData data;

  @override
  State<AgentCacheWarmingSection> createState() =>
      _AgentCacheWarmingSectionState();
}

class _AgentCacheWarmingSectionState extends State<AgentCacheWarmingSection> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant AgentCacheWarmingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final ticking = widget.data.nextWarmAt != null;
    if (ticking && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!ticking) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final w = widget.data;
    final active = w.state == 'scheduled' || w.state == 'refreshing';
    final mode = switch (w.mode) {
      'off' => l.set_agCacheOff,
      'idle' => l.set_agCacheIdle,
      _ => l.set_agCacheStreaming,
    };
    String status;
    if (w.mode == 'off') {
      status = l.ag_cacheWarmOff;
    } else if (w.state == 'refreshing') {
      status = l.ag_cacheWarmRefreshing;
    } else if (w.state == 'scheduled' && w.nextWarmAt != null) {
      final left = w.nextWarmAt!.difference(DateTime.now());
      final sec = left.isNegative ? 0 : left.inSeconds;
      status = l.ag_cacheWarmNext(
        '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}',
      );
    } else {
      status = l.ag_cacheWarmIdle;
    }
    return Column(
      key: const Key('agent-usage-cache-warming'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 5,
      children: [
        Row(
          children: [
            Expanded(child: AgentEyebrow(l.ag_cacheWarmTitle)),
            Text(mode, style: UiText.sans(11.5, color: c.muted)),
          ],
        ),
        Row(
          spacing: 7,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? c.ok : c.faint.withValues(alpha: .6),
              ),
            ),
            Expanded(
              child: Text(
                status,
                style: UiText.sans(12, color: active ? c.ink : c.muted),
              ),
            ),
            if (w.expectedSavings case final saving?)
              Text(
                '\$${saving.toStringAsFixed(3)}',
                style: UiText.mono(11.5, color: c.faint),
              ),
          ],
        ),
        if (w.warmCount > 0 || w.ttlSeconds != null)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              [
                if (w.warmCount > 0) l.ag_cacheWarmCount(w.warmCount),
                if (w.lastWarmAt case final at?)
                  l.ag_cacheWarmLast(
                    '${at.hour.toString().padLeft(2, '0')}:'
                    '${at.minute.toString().padLeft(2, '0')}',
                  ),
                if (w.ttlSeconds case final ttl?)
                  l.ag_cacheWarmTtl((ttl / 60).round()),
              ].join(' · '),
              key: const Key('agent-usage-cache-warming-stats'),
              style: UiText.sans(11, color: c.faint),
            ),
          ),
      ],
    );
  }
}

/// 模型 + 思考档位弹层。
class AgentModelPopover extends StatelessWidget {
  const AgentModelPopover({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data, a = s.actions;
    final c = context.ui;
    final l = context.l10n;
    final groups = <String, List<AgentModelOption>>{};
    for (final m in d.models) {
      groups.putIfAbsent(m.provider, () => []).add(m);
    }
    final t = d.thinking;
    return UiPopoverSurface(
      key: const Key('agent-model-popover'),
      width: 260,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final MapEntry(key: provider, value: models)
                  in groups.entries) ...[
                _GroupLabel(
                  provider,
                  leading:
                      models.first.logoAsset == null &&
                          models.first.mark == null
                      ? null
                      : AgentProviderLogo(
                          key: Key('agent-model-logo-$provider'),
                          logoAsset: models.first.logoAsset,
                          mark: models.first.mark,
                        ),
                ),
                for (final m in models)
                  AgentPopRow(
                    key: Key('agent-model-${m.providerId}-${m.modelId}'),
                    onTap: () {
                      onClose();
                      if (!m.selected) {
                        s.run(() => a.onSelectModel(m.providerId, m.modelId));
                      }
                    },
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(
                            m.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (m.selected)
                          AgentIcon(
                            AgentGlyphs.check,
                            size: 14,
                            color: c.accent,
                          ),
                      ],
                    ),
                  ),
              ],
              AgentPopRow(
                onTap: () {
                  onClose();
                  a.onOpenModelSettings();
                },
                child: Row(
                  spacing: 8,
                  children: [
                    AgentIcon(AgentGlyphs.sliders, size: 14, color: c.muted),
                    Text(
                      l.ag_modelSettings,
                      style: UiText.sans(12.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: c.line,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
              _GroupLabel(l.ag_thinkingTitle),
              if (t.options.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                  child: Text(
                    l.ag_thinkingUnsupported,
                    style: UiText.sans(12, color: c.faint),
                  ),
                )
              else ...[
                AgentPopRow(
                  key: const Key('agent-thinking-default'),
                  onTap: () {
                    onClose();
                    s.run(() => a.onThinking(null));
                  },
                  child: Row(
                    children: [
                      Expanded(child: Text(l.ag_thinkingFollow)),
                      if (t.followsModel)
                        AgentIcon(AgentGlyphs.check, size: 14, color: c.accent),
                    ],
                  ),
                ),
                for (final (id, label) in t.options)
                  AgentPopRow(
                    key: Key('agent-thinking-$id'),
                    onTap: () {
                      onClose();
                      s.run(() => a.onThinking(id));
                    },
                    child: Row(
                      children: [
                        Expanded(child: Text(label)),
                        if (!t.followsModel && t.selected == id)
                          AgentIcon(
                            AgentGlyphs.check,
                            size: 14,
                            color: c.accent,
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 切换权限档；切到完全权限先确认一次风险（勾过「不再提醒」就不问）。
Future<void> agentSwitchPermission(
  BuildContext context,
  AgentPermissionMode mode,
) async {
  final s = AgentScope.of(context);
  final l = context.l10n;
  if (mode == s.data.permission) return;
  if (mode == AgentPermissionMode.bypass && !s.data.bypassWarned) {
    final picked = await s.confirm(
      title: l.ag_bypassConfirmTitle,
      message: l.ag_bypassConfirmBody,
      confirm: l.ag_bypassConfirmOk,
      danger: true,
      optOut: l.ag_bypassConfirmSilence,
    );
    if (picked == null) return;
    if (picked.$1) await s.run(s.actions.onSilenceBypass);
  }
  await s.run(() => s.actions.onPermission(mode));
}

/// 权限四档下拉。
class AgentPermissionPopover extends StatelessWidget {
  const AgentPermissionPopover({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    return UiPopoverSurface(
      key: const Key('agent-permission-popover'),
      width: 260,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in AgentPermissionMode.values)
              AgentPopRow(
                key: Key('agent-permission-${mode.name}'),
                height: 50,
                onTap: () {
                  onClose();
                  agentSwitchPermission(context, mode);
                },
                child: Row(
                  spacing: 10,
                  children: [
                    AgentIcon(
                      agentPermissionGlyph(mode),
                      size: 15,
                      color: mode == AgentPermissionMode.bypass
                          ? c.error
                          : c.ink,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agentPermissionLabel(context, mode),
                            style: UiText.sans(
                              12.5,
                              weight: FontWeight.w500,
                              color: mode == AgentPermissionMode.bypass
                                  ? c.error
                                  : c.ink,
                            ),
                          ),
                          Text(
                            agentPermissionHint(context, mode),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(11, color: c.faint, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    if (mode == s.data.permission)
                      AgentIcon(AgentGlyphs.check, size: 14, color: c.accent),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String agentPermissionGlyph(AgentPermissionMode m) => switch (m) {
  AgentPermissionMode.bypass => AgentGlyphs.alert,
  AgentPermissionMode.readonly => AgentGlyphs.eye,
  AgentPermissionMode.ask => AgentGlyphs.shield,
  AgentPermissionMode.auto => AgentGlyphs.bolt,
};

String agentPermissionLabel(BuildContext context, AgentPermissionMode m) {
  final l = context.l10n;
  return switch (m) {
    AgentPermissionMode.bypass => l.ag_modeBypass,
    AgentPermissionMode.readonly => l.ag_modeReadonly,
    AgentPermissionMode.ask => l.ag_modeAsk,
    AgentPermissionMode.auto => l.ag_modeAuto,
  };
}

String agentPermissionHint(BuildContext context, AgentPermissionMode m) {
  final l = context.l10n;
  return switch (m) {
    AgentPermissionMode.bypass => l.ag_modeBypassHint,
    AgentPermissionMode.readonly => l.ag_modeReadonlyHint,
    AgentPermissionMode.ask => l.ag_modeAskHint,
    AgentPermissionMode.auto => l.ag_modeAutoHint,
  };
}

/// `/` 命令的一行：类型图标 │ `/名称` + 参数提示 │ 说明；模板标注来源。
class AgentSlashRow extends StatelessWidget {
  const AgentSlashRow({
    super.key,
    required this.command,
    required this.selected,
    required this.onTap,
  });
  final AgentSlashCommand command;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final cmd = command;
    final name = cmd.kind == AgentSlashCommandKind.skill
        ? 'skill:${cmd.name}'
        : cmd.name;
    return AgentPopRow(
      key: Key(
        cmd.kind == AgentSlashCommandKind.skill
            ? 'agent-skill-${cmd.name}'
            : 'agent-slash-${cmd.kind.name}-${cmd.name}',
      ),
      height: 44,
      selected: selected,
      onTap: onTap,
      child: Row(
        spacing: 9,
        children: [
          AgentIcon(
            switch (cmd.kind) {
              AgentSlashCommandKind.skill => AgentGlyphs.book,
              AgentSlashCommandKind.template => AgentGlyphs.file,
              AgentSlashCommandKind.builtin => AgentGlyphs.terminal,
            },
            size: 14,
            color: c.muted,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '/$name',
                        style: UiText.mono(
                          12,
                          weight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                      if (cmd.argumentHint case final hint?)
                        TextSpan(
                          text: ' $hint',
                          style: UiText.mono(11.5, color: c.faint),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  cmd.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(11, color: c.faint),
                ),
              ],
            ),
          ),
          if (cmd.source case final source?)
            Text(source, style: UiText.mono(10.5, color: c.faint)),
        ],
      ),
    );
  }
}

/// `@` 引用 / `/` 技能候选面板，贴在输入框上方。键盘：↑↓ 选、Enter / Tab 插入、Esc 关。
class AgentMentionPanel extends StatelessWidget {
  const AgentMentionPanel({
    super.key,
    required this.query,
    required this.slash,
    required this.index,
    required this.category,
    required this.onCategory,
    required this.onPick,
    required this.onCommand,
    this.search,
    this.searchText = '',
  });

  /// 选中一条 `/` 命令（插入、或无参 Studio 命令直接执行由输入框决定）。
  final ValueChanged<AgentSlashCommand> onCommand;

  /// 积木搜索框当前文字（与 [search] 配套）。
  final String searchText;

  /// 积木分类下的搜索框（由输入框持有 controller / focus，便于键盘导航）。
  final Widget? search;

  final String query;
  final bool slash;
  final int index;
  final AgentMentionKind? category;
  final ValueChanged<AgentMentionKind?> onCategory;
  final void Function(String insert, String? imageId) onPick;

  static List<AgentMention> filter(
    List<AgentMention> all,
    String query,
    AgentMentionKind? category, {
    String search = '',
  }) {
    final q = query.toLowerCase();
    final extra = search.trim().toLowerCase();
    return [
      for (final m in all)
        if ((category == null || _group(m.kind) == _group(category)) &&
            (q.isEmpty || m.label.toLowerCase().contains(q)) &&
            (extra.isEmpty || m.label.toLowerCase().contains(extra)))
          m,
    ];
  }

  static List<AgentSkillOption> filterSkills(
    List<AgentSkillOption> all,
    String query,
  ) {
    final q = query.toLowerCase();
    return [
      for (final s in all)
        if (q.isEmpty || s.name.toLowerCase().contains(q)) s,
    ];
  }

  /// `/` 候选：Skill / 提示词模板 / Studio 命令三组，按名称或说明过滤，组内保持来源顺序。
  /// 接线方没给 [AgentViewData.slashCommands] 时退回只列 Skill。
  static List<AgentSlashCommand> filterCommands(AgentViewData d, String query) {
    final all = d.slashCommands.isNotEmpty
        ? d.slashCommands
        : [
            for (final s in d.skills)
              AgentSlashCommand(
                kind: AgentSlashCommandKind.skill,
                name: s.name,
                description: s.description,
              ),
          ];
    final q = query.toLowerCase();
    final hit = [
      for (final c in all)
        if (q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            (q.startsWith('skill:') &&
                c.kind == AgentSlashCommandKind.skill &&
                c.name.toLowerCase().contains(q.substring(6))))
          c,
    ];
    return [
      for (final k in AgentSlashCommandKind.values)
        ...hit.where((c) => c.kind == k),
    ];
  }

  static int _group(AgentMentionKind k) => switch (k) {
    AgentMentionKind.prompt ||
    AgentMentionKind.negative ||
    AgentMentionKind.character => 0,
    AgentMentionKind.image => 1,
    AgentMentionKind.block => 2,
  };

  @override
  Widget build(BuildContext context) {
    final d = AgentScope.of(context).data;
    final c = context.ui;
    final l = context.l10n;
    final rows = <Widget>[];
    if (slash) {
      final list = filterCommands(d, query);
      AgentSlashCommandKind? group;
      for (final (i, cmd) in list.indexed) {
        if (cmd.kind != group) {
          group = cmd.kind;
          rows.add(
            _GroupLabel(switch (cmd.kind) {
              AgentSlashCommandKind.skill => l.ag_slashGroupSkills,
              AgentSlashCommandKind.template => l.ag_slashGroupTemplates,
              AgentSlashCommandKind.builtin => l.ag_slashGroupBuiltin,
            }),
          );
        }
        rows.add(
          AgentSlashRow(
            command: cmd,
            selected: i == index,
            onTap: () => onCommand(cmd),
          ),
        );
      }
      if (list.isEmpty) rows.add(_empty(context));
    } else {
      final list = filter(d.mentions, query, category, search: searchText);
      var group = -1;
      for (final (i, m) in list.indexed) {
        final g = _group(m.kind);
        if (g != group) {
          group = g;
          rows.add(
            _GroupLabel(
              [l.ag_mentionDraft, l.ag_mentionImages, l.ag_mentionBlocks][g],
            ),
          );
        }
        rows.add(
          AgentPopRow(
            key: Key('agent-mention-${m.id}'),
            height: 32,
            selected: i == index,
            onTap: () => onPick(
              '@${m.label} ',
              m.kind == AgentMentionKind.image ? m.id : null,
            ),
            child: Row(
              spacing: 9,
              children: [
                if (m.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image(
                      image: m.image!,
                      width: 18,
                      height: 18,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  AgentIcon(
                    switch (m.kind) {
                      AgentMentionKind.character => AgentGlyphs.hand,
                      AgentMentionKind.block => AgentGlyphs.layers,
                      AgentMentionKind.image => AgentGlyphs.image,
                      _ => AgentGlyphs.pen,
                    },
                    size: 14,
                    color: c.muted,
                  ),
                Expanded(
                  child: Text(
                    m.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (m.detail != null)
                  Text(m.detail!, style: UiText.mono(11, color: c.faint)),
              ],
            ),
          ),
        );
      }
      if (list.isEmpty) rows.add(_empty(context));
    }
    return UiPopoverSurface(
      key: const Key('agent-mention-panel'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!slash)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 2),
              child: Row(
                spacing: 6,
                children: [
                  Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '@',
                      style: UiText.mono(
                        12,
                        weight: FontWeight.w600,
                        color: c.accent,
                        height: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l.ag_mentionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ),
                  AgentSegments<AgentMentionKind?>(
                    values: const [
                      null,
                      AgentMentionKind.prompt,
                      AgentMentionKind.image,
                      AgentMentionKind.block,
                    ],
                    selected: category,
                    label: (v) => switch (v) {
                      null => l.ag_mentionAll,
                      AgentMentionKind.image => l.ag_mentionImages,
                      AgentMentionKind.block => l.ag_mentionBlocks,
                      _ => l.ag_mentionDraft,
                    },
                    onChanged: onCategory,
                  ),
                ],
              ),
            ),
          if (!slash && search != null) search!,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: DefaultTextStyle.merge(
              style: UiText.sans(11, color: c.faint),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _hint('↑↓', l.ag_keySelect),
                  _hint('↵', l.ag_keyInsert),
                  if (!slash) _hint('Tab', l.ag_keyCategory),
                  _hint('Esc', l.ag_keyClose),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
    child: Text(
      context.l10n.ag_mentionEmpty,
      style: UiText.sans(12, color: context.ui.faint),
    ),
  );

  Widget _hint(String key, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [AgentKey(key), Text(label)],
  );
}

/// 键盘导航用：把方向键 / Enter / Tab / Esc 交给 [onKey]。
KeyEventResult agentPanelKeys(
  KeyEvent event, {
  required VoidCallback up,
  required VoidCallback down,
  required VoidCallback pick,
  required VoidCallback tab,
  required VoidCallback close,
}) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  final k = event.logicalKey;
  if (k == LogicalKeyboardKey.arrowUp) {
    up();
  } else if (k == LogicalKeyboardKey.arrowDown) {
    down();
  } else if (k == LogicalKeyboardKey.enter ||
      k == LogicalKeyboardKey.numpadEnter) {
    pick();
  } else if (k == LogicalKeyboardKey.tab) {
    tab();
  } else if (k == LogicalKeyboardKey.escape) {
    close();
  } else {
    return KeyEventResult.ignored;
  }
  return KeyEventResult.handled;
}
