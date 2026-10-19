import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_scope.dart';

/// 弹层里的一行：34 高、7 圆角、悬停 / 键盘选中灰底。
class AgentPopRow extends StatefulWidget {
  const AgentPopRow({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.height = 34,
  });
  final Widget child;
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
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
    child: AgentEyebrow(text),
  );
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

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
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
    return UiPopoverSurface(
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
                      onChanged: (_) => setState(() {}),
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
                      AgentPopRow(
                        key: Key('agent-chat-${chat.id}'),
                        selected: chat.id == d.chat.id,
                        onTap: () {
                          widget.onClose();
                          if (chat.id != d.chat.id) {
                            s.run(() => a.onSelectChat(chat.id));
                          }
                        },
                        child: Row(
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
                            Text(
                              switch (chat.state) {
                                AgentChatState.waitingUser => l.ag_chatWaiting,
                                AgentChatState.running => l.ag_chatRunning,
                                AgentChatState.idle => agentDay(
                                  chat.createdAt,
                                  d.now,
                                  l.ag_yesterday,
                                ),
                              },
                              style: UiText.mono(
                                11,
                                color: chat.state == AgentChatState.waitingUser
                                    ? c.warn
                                    : c.faint,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                Text(
                  '${agentTokens(u.tokens!)} / ${agentTokens(u.window!)}',
                  style: UiText.mono(11.5, color: c.faint),
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
                _GroupLabel(provider),
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

/// 窄宽时权限三档收成下拉。
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
                  if (mode != s.data.permission) {
                    s.run(() => s.actions.onPermission(mode));
                  }
                },
                child: Row(
                  spacing: 10,
                  children: [
                    AgentIcon(
                      agentPermissionGlyph(mode),
                      size: 15,
                      color: c.ink,
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
                              color: c.ink,
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
  AgentPermissionMode.readonly => AgentGlyphs.eye,
  AgentPermissionMode.ask => AgentGlyphs.shield,
  AgentPermissionMode.auto => AgentGlyphs.bolt,
};

String agentPermissionLabel(BuildContext context, AgentPermissionMode m) {
  final l = context.l10n;
  return switch (m) {
    AgentPermissionMode.readonly => l.ag_modeReadonly,
    AgentPermissionMode.ask => l.ag_modeAsk,
    AgentPermissionMode.auto => l.ag_modeAuto,
  };
}

String agentPermissionHint(BuildContext context, AgentPermissionMode m) {
  final l = context.l10n;
  return switch (m) {
    AgentPermissionMode.readonly => l.ag_modeReadonlyHint,
    AgentPermissionMode.ask => l.ag_modeAskHint,
    AgentPermissionMode.auto => l.ag_modeAutoHint,
  };
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
    this.search,
    this.searchText = '',
  });

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
      final skills = filterSkills(d.skills, query);
      rows.add(_GroupLabel(l.ag_skillsTitle));
      for (final (i, s) in skills.indexed) {
        rows.add(
          AgentPopRow(
            key: Key('agent-skill-${s.name}'),
            height: 44,
            selected: i == index,
            onTap: () => onPick('/skill:${s.name} ', null),
            child: Row(
              spacing: 9,
              children: [
                AgentIcon(AgentGlyphs.book, size: 14, color: c.muted),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: UiText.mono(
                          12,
                          weight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        s.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11, color: c.faint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (skills.isEmpty) rows.add(_empty(context));
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
