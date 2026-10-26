import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_thread_navigation.dart';

/// 对话历史飞出栏（原型 `.devin/mockups/fix-batch-1024` 场景 agent，`.hist`）：
/// 宽 348，贴在 Agent 面板外侧；标题 + 计数 / 搜索 / 分段筛选 / 时间线列表 / 键位提示。
/// 不挡对话、不加遮罩；点条目只滚动对话到原位，不切分支。
class AgentHistory extends StatefulWidget {
  const AgentHistory({
    super.key,
    required this.entries,
    required this.navigation,
    required this.onJump,
    required this.onClose,
    this.edge = AxisDirection.left,
  });
  final List<AgentHistoryEntry> entries;
  final AgentThreadNavigation navigation;
  final ValueChanged<AgentHistoryEntry> onJump;
  final VoidCallback onClose;

  /// 朝外（背离 Agent 面板）的那一侧：画分隔线、阴影投向这边。栏在面板左边 = left。
  final AxisDirection edge;

  static const width = 348.0;

  @override
  State<AgentHistory> createState() => _AgentHistoryState();
}

class _AgentHistoryState extends State<AgentHistory> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _keys = <String, GlobalKey>{};
  AgentHistoryKind? _kind;
  int _index = -1;

  List<AgentHistoryEntry> get _entries {
    final q = _search.text.trim().toLowerCase();
    return widget.entries
        .where(
          (e) =>
              (_kind == null ||
                  e.kind == _kind ||
                  (e.kind == AgentHistoryKind.compaction && q.isEmpty)) &&
              (q.isEmpty ||
                  '${e.title}\n${e.subtitle}'.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _move(List<AgentHistoryEntry> entries, int delta) {
    final pickable = [
      for (final (i, e) in entries.indexed)
        if (e.kind != AgentHistoryKind.compaction || _kind == null) i,
    ];
    if (pickable.isEmpty) return;
    final at = pickable.indexOf(_index);
    final next = at < 0
        ? (delta > 0 ? pickable.first : pickable.last)
        : pickable[(at + delta).clamp(0, pickable.length - 1)];
    setState(() => _index = next);
    final ctx = _keys[entries[next].id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 120),
        alignmentPolicy: delta > 0
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  void _enter(List<AgentHistoryEntry> entries) {
    if (entries.isEmpty) return;
    widget.onJump(
      entries[_index < 0 ? 0 : _index.clamp(0, entries.length - 1)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final entries = _entries;
    final users = widget.entries
        .where((e) => e.kind == AgentHistoryKind.user)
        .length;
    final cards = widget.entries
        .where((e) => e.kind == AgentHistoryKind.card)
        .length;
    final side = BorderSide(color: c.line);
    final shadowDx = widget.edge == AxisDirection.left ? -18.0 : 18.0;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _move(entries, 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _move(entries, -1),
        const SingleActivator(LogicalKeyboardKey.enter): () => _enter(entries),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
            _enter(entries),
      },
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          key: const Key('agent-history'),
          decoration: BoxDecoration(
            color: c.raised,
            border: widget.edge == AxisDirection.left
                ? Border(left: side)
                : Border(right: side),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: c.dark ? .4 : .14),
                blurRadius: 40,
                spreadRadius: -18,
                offset: Offset(shadowDx, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // `.hh`
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Row(
                  spacing: 8,
                  children: [
                    AgentIcon(AgentGlyphs.clock, size: 17, color: c.ink),
                    Text(
                      l.ag_historyTitle,
                      style: UiText.sans(
                        14,
                        weight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l.ag_historyStats(users, cards),
                        key: const Key('agent-history-stats'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.mono(11, color: c.faint),
                      ),
                    ),
                    _IconBtn(
                      key: const Key('agent-history-close'),
                      glyph: UiGlyphs.close,
                      tooltip: l.ag_close,
                      onTap: widget.onClose,
                    ),
                  ],
                ),
              ),
              // `.hs`
              Container(
                height: 32,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: c.control,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  spacing: 7,
                  children: [
                    UiGlyph(UiGlyphs.search, size: 14, color: c.faint),
                    Expanded(
                      child: TextField(
                        key: const Key('agent-history-search'),
                        controller: _search,
                        focusNode: _focus,
                        style: UiText.sans(12.5, color: c.ink, height: 1.3),
                        cursorColor: c.accent,
                        cursorWidth: 1.5,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: l.ag_historySearch,
                          hintStyle: UiText.sans(
                            12.5,
                            color: c.faint,
                            height: 1.3,
                          ),
                        ),
                        onChanged: (_) => setState(() => _index = -1),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      UiPressable(
                        onTap: () => setState(() {
                          _search.clear();
                          _index = -1;
                        }),
                        builder: (context, hover) => UiGlyph(
                          UiGlyphs.close,
                          size: 12,
                          color: hover ? c.ink : c.faint,
                        ),
                      ),
                  ],
                ),
              ),
              // `.seg`
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Seg(
                    selected: _kind,
                    labelOf: (k) => switch (k) {
                      AgentHistoryKind.user => l.ag_historyMine,
                      AgentHistoryKind.card => l.ag_historyCards,
                      AgentHistoryKind.questions => l.ag_historyQuestions,
                      _ => l.ag_historyAll,
                    },
                    onTap: (k) => setState(() {
                      _kind = k;
                      _index = -1;
                    }),
                  ),
                ),
              ),
              // `.hl`
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          l.ag_historyEmpty,
                          style: UiText.sans(12, color: c.faint),
                        ),
                      )
                    : ValueListenableBuilder<Set<String>>(
                        valueListenable: widget.navigation.visible,
                        builder: (context, visible, _) => ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          itemCount: entries.length,
                          itemBuilder: (context, i) {
                            final e = entries[i];
                            final key = _keys.putIfAbsent(e.id, GlobalKey.new);
                            if (e.kind == AgentHistoryKind.compaction) {
                              return _CompactionRow(
                                key: key,
                                entry: e,
                                onTap: () {
                                  setState(() => _index = i);
                                  widget.onJump(e);
                                },
                              );
                            }
                            return _EntryRow(
                              key: key,
                              entry: e,
                              first: i == 0,
                              last: i == entries.length - 1,
                              selected: _index == i,
                              inView: visible.contains(e.id),
                              onTap: () {
                                setState(() => _index = i);
                                widget.onJump(e);
                              },
                            );
                          },
                        ),
                      ),
              ),
              // `.hf`
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(border: Border(top: side)),
                child: DefaultTextStyle(
                  style: UiText.sans(11.5, color: c.faint),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const UiKeycap('↑↓'),
                      Text(l.ag_historyKeySelect),
                      const SizedBox(width: 4),
                      const UiKeycap('Enter'),
                      Text(l.ag_historyKeyJump),
                      const SizedBox(width: 4),
                      const UiKeycap('Esc'),
                      Text(l.ag_historyKeyClose),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _hm(DateTime? at) => at == null
    ? ''
    : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

/// `.he`：左边 26 宽的时间线节点，右边两行标题 + 一行元信息。
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    super.key,
    required this.entry,
    required this.first,
    required this.last,
    required this.selected,
    required this.inView,
    required this.onTap,
  });
  final AgentHistoryEntry entry;
  final bool first, last, selected, inView;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final e = entry;
    final meta = switch (e.kind) {
      AgentHistoryKind.user => [
        _hm(e.at),
        if (e.number != null) '#${e.number}',
      ],
      _ => [if (e.subtitle.isNotEmpty) e.subtitle],
    };
    final dot = switch (e.kind) {
      AgentHistoryKind.user => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
        child: Text(
          l.ag_you,
          style: UiText.sans(
            10,
            weight: FontWeight.w600,
            color: c.bg,
            height: 1,
          ),
        ),
      ),
      AgentHistoryKind.card => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.accent.withValues(alpha: .4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: AgentIcon(AgentGlyphs.psGrid, size: 11, color: c.accent),
      ),
      _ => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.strong),
          borderRadius: BorderRadius.circular(6),
        ),
        child: AgentIcon(AgentGlyphs.help, size: 12, color: c.muted),
      ),
    };
    return UiPressable(
      key: Key('agent-history-entry-${e.id}'),
      onTap: onTap,
      builder: (context, hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: selected || hover ? c.hover : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 时间线竖线：穿过节点，首条从节点中间开始、末条到节点中间结束。
            Positioned(
              left: 13,
              top: first ? 12 : -8,
              bottom: last ? null : -8,
              height: last ? (first ? 0 : 20) : null,
              child: Container(width: 1, color: c.line),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                SizedBox(
                  width: 26,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Center(child: dot),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            12.5,
                            height: 1.55,
                            color: e.kind == AgentHistoryKind.questions
                                ? c.muted
                                : c.ink,
                            weight: e.kind == AgentHistoryKind.card
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (meta.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              meta.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.mono(
                                11,
                                color: c.faint,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // 蓝竖条 = 当前在对话里可见。
            if (inView)
              Positioned(
                key: Key('agent-history-inview-${e.id}'),
                right: -4,
                top: 3,
                bottom: 3,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.hc`：虚线 · 「10:41 自动压缩 · 原 131k token」胶囊 · 虚线。
class _CompactionRow extends StatelessWidget {
  const _CompactionRow({super.key, required this.entry, required this.onTap});
  final AgentHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final e = entry;
    final tokens = e.tokensBefore == null
        ? null
        : l.ag_compactedTokens('${(e.tokensBefore! / 1000).round()}k');
    final label = [
      _hm(e.at),
      e.auto ? l.ag_historyAuto : l.ag_historyManual,
    ].where((s) => s.isNotEmpty).join(' ');
    Widget dash() => Expanded(
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _Dashes(c.strong),
      ),
    );
    return UiPressable(
      key: Key('agent-history-entry-${e.id}'),
      onTap: onTap,
      builder: (context, hover) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          spacing: 8,
          children: [
            dash(),
            CustomPaint(
              painter: _DashedPill(hover ? c.muted : c.strong),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    AgentIcon(AgentGlyphs.layers, size: 12, color: c.faint),
                    Text(
                      [label, ?tokens].join(' · '),
                      style: UiText.sans(
                        11.5,
                        color: hover ? c.muted : c.faint,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            dash(),
          ],
        ),
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  const _Dashes(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, .5),
        Offset((x + 3).clamp(0, size.width), .5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}

class _DashedPill extends CustomPainter {
  const _DashedPill(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    ).deflate(.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPill old) => old.color != color;
}

/// `.seg`：控件底、内边距 2；选中项抬起底 + 细阴影（深色是悬停底、无阴影）。
class _Seg extends StatelessWidget {
  const _Seg({
    required this.selected,
    required this.labelOf,
    required this.onTap,
  });
  final AgentHistoryKind? selected;
  final String Function(AgentHistoryKind?) labelOf;
  final ValueChanged<AgentHistoryKind?> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final k in const [
            null,
            AgentHistoryKind.user,
            AgentHistoryKind.card,
            AgentHistoryKind.questions,
          ])
            UiPressable(
              key: Key('agent-history-filter-${k?.name ?? 'all'}'),
              onTap: () => onTap(k),
              builder: (context, hover) {
                final on = selected == k;
                return Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? (c.dark ? c.hover : c.raised) : null,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: on && !c.dark
                        ? const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labelOf(k),
                    style: UiText.sans(
                      12,
                      height: 1.2,
                      color: on || hover ? c.ink : c.muted,
                      weight: on ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// `.ib`：28×28、圆角 6。
class _IconBtn extends StatelessWidget {
  const _IconBtn({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });
  final String glyph, tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: tooltip,
      child: UiPressable(
        onTap: onTap,
        builder: (context, hover) => Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hover ? c.hover : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: UiGlyph(glyph, size: 15, color: hover ? c.ink : c.muted),
        ),
      ),
    );
  }
}
