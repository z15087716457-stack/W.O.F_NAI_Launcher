import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_thread_navigation.dart';

class AgentHistory extends StatefulWidget {
  const AgentHistory({
    super.key,
    required this.entries,
    required this.navigation,
    required this.onJump,
    required this.onClose,
  });
  final List<AgentHistoryEntry> entries;
  final AgentThreadNavigation navigation;
  final ValueChanged<AgentHistoryEntry> onJump;
  final VoidCallback onClose;
  @override
  State<AgentHistory> createState() => _AgentHistoryState();
}

class _CompactionHistoryLine extends StatelessWidget {
  const _CompactionHistoryLine({required this.entry, required this.time});
  final AgentHistoryEntry entry;
  final String time;
  @override
  Widget build(BuildContext context) {
    final c = context.ui, l = context.l10n;
    return Row(
      spacing: 6,
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _HistoryDashes(c.border),
          ),
        ),
        AgentIcon(AgentGlyphs.layers, size: 12, color: c.faint),
        Flexible(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 3,
            children: [
              Text(
                '$time ${entry.auto ? l.ag_historyAuto : l.ag_historyManual}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(11, color: c.faint),
              ),
              Text(
                l.ag_compactedTokens(
                  entry.tokensBefore == null
                      ? '?'
                      : '${(entry.tokensBefore! / 1000).round()}k',
                ),
                style: UiText.sans(10.5, color: c.faint),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _HistoryDashes(c.border),
          ),
        ),
      ],
    );
  }
}

class _HistoryDashes extends CustomPainter {
  const _HistoryDashes(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + 3).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HistoryDashes oldDelegate) => oldDelegate.color != color;
}

class _AgentHistoryState extends State<AgentHistory> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  AgentHistoryKind? _kind;
  int _index = 0;
  List<AgentHistoryEntry> get _entries => widget.entries
      .where(
        (e) =>
            (_kind == null || e.kind == _kind) &&
            '${e.title}\n${e.subtitle}'.toLowerCase().contains(
              _search.text.trim().toLowerCase(),
            ),
      )
      .toList();
  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final entries = _entries;
    if (entries.isEmpty) return;
    setState(() => _index = (_index + delta).clamp(0, entries.length - 1));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        (_index * 80.0).clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, c = context.ui;
    final entries = _entries;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (entries.isNotEmpty) {
            widget.onJump(entries[_index.clamp(0, entries.length - 1)]);
          }
        },
      },
      child: Material(
        key: const Key('agent-history'),
        color: c.bg,
        elevation: 10,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(side: BorderSide(color: c.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
              child: Row(
                spacing: 7,
                children: [
                  AgentIcon(AgentGlyphs.clock, size: 16, color: c.muted),
                  Expanded(
                    child: Text(
                      l.ag_historyTitle,
                      style: UiText.sans(
                        14,
                        color: c.ink,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.entries.length}',
                    style: UiText.mono(11, color: c.faint),
                  ),
                  AgentIconButton(
                    key: const Key('agent-history-close'),
                    glyph: AgentGlyphs.close,
                    tooltip: l.ag_close,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                key: const Key('agent-history-search'),
                controller: _search,
                autofocus: true,
                style: UiText.sans(12, color: c.ink),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.ag_historySearch,
                  prefixIcon: Icon(Icons.search, size: 16, color: c.faint),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
                onChanged: (_) => setState(() => _index = 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  for (final kind in [
                    null,
                    AgentHistoryKind.user,
                    AgentHistoryKind.card,
                    AgentHistoryKind.questions,
                  ])
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _kind = kind;
                          _index = 0;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _kind == kind ? c.control : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            switch (kind) {
                              AgentHistoryKind.user => l.ag_historyMine,
                              AgentHistoryKind.card => l.ag_historyCards,
                              AgentHistoryKind.questions =>
                                l.ag_historyQuestions,
                              _ => l.ag_historyAll,
                            },
                            maxLines: 1,
                            style: UiText.sans(
                              11.5,
                              color: _kind == kind ? c.ink : c.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                        itemExtent: 80,
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          final e = entries[i],
                              compact = e.kind == AgentHistoryKind.compaction;
                          final time = e.at == null
                              ? ''
                              : '${e.at!.hour.toString().padLeft(2, '0')}:${e.at!.minute.toString().padLeft(2, '0')}';
                          return InkWell(
                            key: Key('agent-history-entry-${e.id}'),
                            onTap: () {
                              setState(() => _index = i);
                              widget.onJump(e);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _index == i ? c.hover : null,
                                border: Border(
                                  right: BorderSide(
                                    color: visible.contains(e.id)
                                        ? c.accent
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: compact
                                  ? _CompactionHistoryLine(entry: e, time: time)
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 9,
                                      children: [
                                        Container(
                                          width: 23,
                                          height: 23,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: c.control,
                                            shape: BoxShape.circle,
                                          ),
                                          child: AgentIcon(
                                            switch (e.kind) {
                                              AgentHistoryKind.user =>
                                                AgentGlyphs.at,
                                              AgentHistoryKind.questions =>
                                                AgentGlyphs.help,
                                              AgentHistoryKind.compaction =>
                                                AgentGlyphs.layers,
                                              _ => AgentGlyphs.psGrid,
                                            },
                                            size: 13,
                                            color: c.muted,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            spacing: 3,
                                            children: [
                                              Text(
                                                compact
                                                    ? '$time ${e.auto ? l.ag_historyAuto : l.ag_historyManual}'
                                                    : e.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: UiText.sans(
                                                  12,
                                                  color: compact
                                                      ? c.faint
                                                      : c.ink,
                                                  height: 1.4,
                                                  weight:
                                                      e.kind ==
                                                          AgentHistoryKind.card
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              Text(
                                                compact
                                                    ? l.ag_compactedTokens(
                                                        e.tokensBefore == null
                                                            ? '?'
                                                            : '${(e.tokensBefore! / 1000).round()}k',
                                                      )
                                                    : e.kind ==
                                                          AgentHistoryKind.user
                                                    ? '$time · #${e.number}'
                                                    : e.subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: UiText.sans(
                                                  10.5,
                                                  color: c.faint,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Text(
                l.ag_historyKeys,
                textAlign: TextAlign.center,
                style: UiText.sans(10.5, color: c.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
