import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_popovers.dart';
import 'agent_scope.dart';

/// 顶栏两层：标志 + 「工作区 / 编号 · 聊天名 ▾」+ 新聊天 / 更多 / 收起；下面 对话 / 产物 / 指令 + 上下文。
class AgentHeader extends StatefulWidget {
  const AgentHeader({
    super.key,
    required this.tab,
    required this.onTab,
    this.historyOpen = false,
    this.onHistory,
    this.onClose,
  });
  final bool historyOpen;
  final VoidCallback? onHistory, onClose;
  final AgentTab tab;
  final ValueChanged<AgentTab> onTab;

  static const height = 46.0 + 34;

  @override
  State<AgentHeader> createState() => _AgentHeaderState();
}

class _AgentHeaderState extends State<AgentHeader> {
  UiPopoverAnchor? _chats, _more, _usage;
  var _compact = false;

  /// “⋯”菜单里删除对话分两步：第一次点把这一项变成“再点一次删除”，第二次才删；
  /// 移开或关菜单作废。删除工作区影响整组聊天，仍走侧栏内的确认弹窗。
  String? _arming;

  void _closeMore() => setState(() {
    _more = null;
    _arming = null;
  });

  UiPopoverAnchor _below(BuildContext context, {bool right = false}) {
    final box = context.findRenderObject()! as RenderBox;
    final corner = right
        ? box.size.bottomRight(const Offset(0, 6))
        : box.size.bottomLeft(const Offset(0, 6));
    return UiPopoverAnchor(box.localToGlobal(corner), alignRight: right);
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data, a = s.actions;
    final c = context.ui;
    final l = context.l10n;
    final index = d.chats.indexWhere((x) => x.id == d.chat.id);
    final number = index < 0
        ? ''
        : ' / ${(d.chats.length - index).toString().padLeft(2, '0')}';
    return Container(
      key: const Key('agent-header'),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: WindowPanelHeader(
              headerHeight: 46,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: LayoutBuilder(
                  builder: (context, box) {
                    // 窗口按钮占右上 138px；窄时「新聊天」收进更多菜单。
                    final compact = box.maxWidth < 240;
                    return Row(
                      children: [
                        Semantics(
                          label: l.ag_toggle,
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.ink,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: AgentMark(
                              size: 16,
                              color: c.bg,
                              stroke: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: UiPopover(
                              anchor: _chats,
                              onDismiss: () => setState(() => _chats = null),
                              builder: (_) => AgentChatsPopover(
                                onClose: () => setState(() => _chats = null),
                              ),
                              child: Builder(
                                builder: (context) => _Title(
                                  key: const Key('agent-chats'),
                                  open: _chats != null,
                                  eyebrow: '${d.workspace.name}$number',
                                  title: d.chat.title,
                                  onTap: () =>
                                      setState(() => _chats = _below(context)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!compact)
                          AgentIconButton(
                            key: const Key('agent-new-chat'),
                            glyph: AgentGlyphs.plus,
                            tooltip: l.ag_newChat,
                            onPressed: () => s.run(a.onNewChat),
                          ),
                        UiPopover(
                          anchor: _more,
                          onDismiss: _closeMore,
                          builder: (_) => _moreMenu(context),
                          child: Builder(
                            builder: (context) => AgentIconButton(
                              key: const Key('agent-more'),
                              glyph: AgentGlyphs.more,
                              tooltip: l.ag_more,
                              active: _more != null,
                              onPressed: () => setState(() {
                                _compact = compact;
                                _more = _below(context, right: true);
                              }),
                            ),
                          ),
                        ),
                        AgentIconButton(
                          key: const Key('agent-close'),
                          glyph: AgentGlyphs.side,
                          tooltip: l.ag_close,
                          onPressed: widget.onClose ?? a.onClose,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Tab(
                    key: const Key('agent-tab-chat'),
                    label: l.ag_tabChat,
                    on: widget.tab == AgentTab.chat,
                    onTap: () => widget.onTab(AgentTab.chat),
                  ),
                  const SizedBox(width: 18),
                  _Tab(
                    key: const Key('agent-tab-shelf'),
                    label: l.ag_tabShelf,
                    count: d.shelf.count,
                    on: widget.tab == AgentTab.shelf,
                    onTap: () => widget.onTab(AgentTab.shelf),
                  ),
                  if (d.memory != null) ...[
                    const SizedBox(width: 18),
                    _Tab(
                      key: const Key('agent-tab-memory'),
                      label: l.ag_tabMemory,
                      on: widget.tab == AgentTab.memory,
                      onTap: () => widget.onTab(AgentTab.memory),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _HistoryButton(
                        on: widget.historyOpen,
                        label: l.ag_historyButton,
                        tooltip: l.ag_historyTitle,
                        onTap: widget.onHistory,
                      ),
                    ),
                  ),
                  UiPopover(
                    anchor: _usage,
                    onDismiss: () => setState(() => _usage = null),
                    builder: (_) => AgentUsagePopover(
                      onClose: () => setState(() => _usage = null),
                    ),
                    child: Builder(
                      builder: (context) => _UsageButton(
                        open: _usage != null,
                        onTap: () async {
                          final anchor = _below(context, right: true);
                          await a.onRefreshUsage();
                          if (mounted) setState(() => _usage = anchor);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreMenu(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data, a = s.actions;
    final l = context.l10n;
    final busy = d.status != AgentRunStatus.idle;
    void arm(String? v) {
      if (_arming != v) setState(() => _arming = v);
    }

    // 构建时定下：第二次点击时菜单先关（_arming 被清空）再执行 onTap。
    final chatArmed = _arming == 'chat';

    return UiMenu(
      width: 220,
      onClose: _closeMore,
      items: [
        if (_compact)
          UiMenuItem(
            key: const Key('agent-menu-new-chat'),
            label: l.ag_newChat,
            glyph: AgentGlyphs.plus,
            onTap: () => s.run(a.onNewChat),
          ),
        UiMenuItem(
          key: const Key('agent-menu-rename'),
          divider: _compact,
          label: l.ag_menuRenameChat,
          glyph: AgentGlyphs.pen,
          onTap: () => s.rename(
            title: l.ag_menuRenameChat,
            value: d.chat.title,
            save: (v) => a.onRenameChat(d.chat.id, v),
          ),
        ),
        UiMenuItem(
          label: l.ag_menuRenameWorkspace,
          glyph: AgentGlyphs.pen,
          onTap: () => s.rename(
            title: l.ag_menuRenameWorkspace,
            value: d.workspace.name,
            save: (v) => a.onRenameWorkspace(d.workspace.id, v),
          ),
        ),
        UiMenuItem(
          label: l.ag_menuOpenFolder,
          glyph: AgentGlyphs.folder,
          onTap: a.onOpenWorkspaceFolder,
        ),
        UiMenuItem(
          key: const Key('agent-menu-compact'),
          divider: true,
          label: l.ag_menuCompact,
          glyph: AgentGlyphs.layers,
          enabled: !busy,
          onTap: () => s.run(a.onCompact),
        ),
        UiMenuItem(
          key: const Key('agent-menu-export'),
          label: l.ag_menuExport,
          glyph: AgentGlyphs.file,
          enabled: !busy && d.chat.canExport,
          onTap: () => s.run(a.onExport),
        ),
        UiMenuItem(
          key: const Key('agent-menu-settings'),
          divider: true,
          label: l.ag_menuSettings,
          glyph: AgentGlyphs.sliders,
          onTap: a.onOpenSettings,
        ),
        UiMenuItem(
          key: const Key('agent-menu-delete-chat'),
          divider: true,
          danger: true,
          label: chatArmed ? l.ag_deleteAgain : l.ag_menuDeleteChat,
          glyph: AgentGlyphs.trash,
          enabled: !busy,
          keepOpen: !chatArmed,
          onExit: () => arm(null),
          onTap: () =>
              chatArmed ? agentDeleteChat(context, d.chat) : arm('chat'),
        ),
        UiMenuItem(
          key: const Key('agent-menu-delete-workspace'),
          danger: true,
          label: l.ag_menuDeleteWorkspace,
          glyph: AgentGlyphs.trash,
          enabled:
              !busy &&
              d.workspaces.length > 1 &&
              d.chats.every((x) => x.state == AgentChatState.idle),
          onTap: () => agentDeleteWorkspace(context, d.workspace),
        ),
      ],
    );
  }
}

class _Title extends StatefulWidget {
  const _Title({
    super.key,
    required this.open,
    required this.eyebrow,
    required this.title,
    required this.onTap,
  });
  final bool open;
  final String eyebrow, title;
  final VoidCallback onTap;

  @override
  State<_Title> createState() => _TitleState();
}

class _TitleState extends State<_Title> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: widget.open || _hover ? c.hover : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.mono(
                  10.5,
                  color: c.faint,
                  letterSpacing: .4,
                  height: 1.25,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w600,
                        color: c.ink,
                        height: 1.25,
                      ),
                    ),
                  ),
                  AgentIcon(AgentGlyphs.chevron, size: 12, color: c.faint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    this.count,
  });
  final String label;
  final bool on;
  final int? count;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ink = widget.on || _hover ? c.ink : c.muted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.on ? c.ink : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            spacing: 6,
            children: [
              Text(
                widget.label,
                style: UiText.sans(
                  12.5,
                  weight: widget.on ? FontWeight.w500 : FontWeight.w400,
                  color: ink,
                  height: 1.2,
                ),
              ),
              if (widget.count != null && widget.count! > 0)
                AgentCount(widget.count!),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageButton extends StatefulWidget {
  const _UsageButton({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  State<_UsageButton> createState() => _UsageButtonState();
}

class _UsageButtonState extends State<_UsageButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final usage = AgentScope.of(context).data.usage;
    final f = usage.fraction;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: const Key('agent-usage'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: widget.open || _hover ? c.hover : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            spacing: 6,
            children: [
              AgentRing(fraction: f),
              Text(
                f == null ? '—' : '${(f * 100).round()}%',
                style: UiText.mono(11, color: c.faint, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「指令」右边的「历史」：高 28、圆角 7，开着时控件底 + 墨色加粗（原型 `.hbtn`）。
class _HistoryButton extends StatelessWidget {
  const _HistoryButton({
    required this.on,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });
  final bool on;
  final String label, tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: on,
        child: LayoutBuilder(
          builder: (context, box) => UiPressable(
            key: const Key('agent-history-toggle'),
            onTap: onTap,
            builder: (context, hover) {
              // Narrow panels (long tab labels) keep only the clock icon.
              final iconOnly = box.maxWidth < 64;
              final fg = on || hover ? c.ink : c.muted;
              return Container(
                height: 28,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: on ? c.control : (hover ? c.hover : null),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    AgentIcon(AgentGlyphs.clock, size: 15, color: fg),
                    if (!iconOnly)
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: UiText.sans(
                            12.5,
                            color: fg,
                            weight: on ? FontWeight.w600 : FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
