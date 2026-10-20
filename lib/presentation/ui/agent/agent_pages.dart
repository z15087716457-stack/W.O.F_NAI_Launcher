import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_preview_image.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_scope.dart';
import 'agent_thread.dart' show AgentThumb;

/// 新聊天的欢迎页：问候 / 当前草稿 / 四个任务块 / 最近聊天。
class AgentWelcome extends StatelessWidget {
  const AgentWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data;
    final c = context.ui;
    final l = context.l10n;
    final hour = d.now.hour;
    final greet = hour < 12
        ? l.ag_greetMorning
        : hour < 18
        ? l.ag_greetAfternoon
        : l.ag_greetEvening;
    final recent = d.chats.where((x) => x.id != d.chat.id).take(3).toList();
    final tasks = (d.quick ?? agentDefaultQuick(l)).take(6).toList();
    return SingleChildScrollView(
      key: const Key('agent-welcome'),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            greet,
            style: UiText.sans(
              18,
              weight: FontWeight.w600,
              color: c.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(l.ag_greetHint, style: UiText.sans(12, color: c.muted)),
          if (d.draft != null) ...[
            const SizedBox(height: 18),
            _DraftCard(draft: d.draft!),
          ],
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                AgentEyebrow(l.ag_quickTitle),
                const Spacer(),
                AgentIconButton(
                  key: const Key('agent-quick-edit'),
                  glyph: AgentGlyphs.sliders,
                  tooltip: l.ag_quickEdit,
                  small: true,
                  onPressed: () =>
                      s.actions.onEditMemory(AgentMemoryTarget.quick),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, t) in tasks.indexed)
                      SizedBox(
                        width: w,
                        child: _Tile(
                          key: Key('agent-task-$i'),
                          glyph: agentQuickGlyph(t.glyph),
                          title: t.title,
                          hint: t.hint,
                          send: t.send,
                          onTap: () async {
                            s.insert(t.prompt, replace: true);
                            if (!t.send) return;
                            // 等输入框把文字交给转接层（onComposerChanged）再发。
                            await Future<void>.delayed(Duration.zero);
                            s.run(() => s.actions.onSend(steer: false));
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(children: [AgentEyebrow(l.ag_recent), const Spacer()]),
            const SizedBox(height: 4),
            for (final (i, chat) in recent.indexed)
              _RecentRow(chat: chat, last: i == recent.length - 1),
          ],
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});
  final AgentDraftSummary draft;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final size = draft.width != null && draft.height != null
        ? ' · ${draft.width}×${draft.height}'
        : '';
    return Container(
      key: const Key('agent-draft'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 54,
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(8),
            ),
            child: draft.image == null
                ? Center(
                    child: AgentIcon(
                      AgentGlyphs.image,
                      size: 18,
                      color: c.faint,
                    ),
                  )
                : UiPreviewImage(image: draft.image!),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                AgentEyebrow(l.ag_draftEyebrow),
                Text(
                  '${draft.model}$size',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    13,
                    weight: FontWeight.w500,
                    color: c.ink,
                    height: 1.3,
                  ),
                ),
                Text(
                  draft.prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: c.muted, height: 1.3),
                ),
                Text(
                  l.ag_draftCounts(
                    draft.characters,
                    draft.blocks,
                    draft.references,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(11, color: c.faint, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    super.key,
    required this.glyph,
    required this.title,
    required this.hint,
    required this.onTap,
    this.send = false,
  });
  final String glyph, title, hint;
  final VoidCallback onTap;

  /// 点了直接发送：右上角画一个小箭头。
  final bool send;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hover ? c.strong : c.border),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: c.dark ? .4 : .06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AgentIcon(widget.glyph, size: 16, color: c.ink),
                  ),
                  const Spacer(),
                  if (widget.send)
                    Tooltip(
                      message: context.l10n.ag_quickSends,
                      child: AgentIcon(
                        AgentGlyphs.send,
                        size: 13,
                        color: c.faint,
                      ),
                    ),
                ],
              ),
              Text(
                widget.title,
                style: UiText.sans(
                  13,
                  weight: FontWeight.w500,
                  color: c.ink,
                  height: 1.3,
                ),
              ),
              if (widget.hint.isNotEmpty)
                Text(
                  widget.hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: c.muted, height: 1.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatefulWidget {
  const _RecentRow({required this.chat, required this.last});
  final AgentChatInfo chat;
  final bool last;

  @override
  State<_RecentRow> createState() => _RecentRowState();
}

class _RecentRowState extends State<_RecentRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: Key('agent-recent-${widget.chat.id}'),
        onTap: () => s.run(() => s.actions.onSelectChat(widget.chat.id)),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _hover ? c.hover : null,
            borderRadius: _hover ? BorderRadius.circular(6) : null,
            border: widget.last || _hover
                ? null
                : Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            spacing: 10,
            children: [
              AgentIcon(AgentGlyphs.clock, size: 14, color: c.faint),
              Expanded(
                child: Text(
                  widget.chat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12.5, color: c.ink),
                ),
              ),
              Text(
                agentDay(
                  widget.chat.createdAt,
                  s.data.now,
                  context.l10n.ag_yesterday,
                ),
                style: UiText.mono(11, color: c.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── 产物 ───────────────────────────────

enum _ShelfFilter { all, generated, attachments, files }

class AgentShelf extends StatefulWidget {
  const AgentShelf({super.key});

  @override
  State<AgentShelf> createState() => _AgentShelfState();
}

class _AgentShelfState extends State<AgentShelf> {
  var _filter = _ShelfFilter.all;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final shelf = s.data.shelf;
    final c = context.ui;
    final l = context.l10n;
    if (shelf.count == 0) {
      return Center(
        key: const Key('agent-shelf-empty'),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              AgentIcon(AgentGlyphs.image, size: 22, color: c.faint),
              Text(
                l.ag_shelfEmpty,
                style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
              ),
              Text(
                l.ag_shelfEmptyHint,
                textAlign: TextAlign.center,
                style: UiText.sans(12, color: c.muted),
              ),
            ],
          ),
        ),
      );
    }
    int count(AgentImageSource src) => shelf.groups.fold(
      0,
      (n, g) => n + g.images.where((i) => i.source == src).length,
    );
    final generated =
        count(AgentImageSource.generated) + count(AgentImageSource.tool);
    final attachments = count(AgentImageSource.attachment);
    bool keep(AgentImage i) => switch (_filter) {
      _ShelfFilter.all => true,
      _ShelfFilter.generated => i.source != AgentImageSource.attachment,
      _ShelfFilter.attachments => i.source == AgentImageSource.attachment,
      _ShelfFilter.files => false,
    };
    final groups = [
      for (final g in shelf.groups)
        if (g.images.any(keep)) (g, g.images.where(keep).toList()),
    ];
    final showFiles =
        (_filter == _ShelfFilter.all || _filter == _ShelfFilter.files) &&
        shelf.files.isNotEmpty;
    return ListView(
      key: const Key('agent-shelf'),
      padding: const EdgeInsets.all(14),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 6,
            children: [
              _Chip(
                label: l.ag_shelfAll(shelf.count),
                on: _filter == _ShelfFilter.all,
                onTap: () => setState(() => _filter = _ShelfFilter.all),
              ),
              if (generated > 0)
                _Chip(
                  label: l.ag_shelfGenerated(generated),
                  on: _filter == _ShelfFilter.generated,
                  onTap: () => setState(() => _filter = _ShelfFilter.generated),
                ),
              if (attachments > 0)
                _Chip(
                  label: l.ag_shelfAttachments(attachments),
                  on: _filter == _ShelfFilter.attachments,
                  onTap: () =>
                      setState(() => _filter = _ShelfFilter.attachments),
                ),
              if (shelf.files.isNotEmpty)
                _Chip(
                  label: l.ag_shelfFiles(shelf.files.length),
                  on: _filter == _ShelfFilter.files,
                  onTap: () => setState(() => _filter = _ShelfFilter.files),
                ),
            ],
          ),
        ),
        for (final (i, (g, images)) in groups.indexed) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AgentEyebrow('${agentClock(g.at)} · ${g.title}')),
              if (i == 0)
                Text(l.ag_shelfHint, style: UiText.sans(11, color: c.faint)),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 6.0;
              final cols = box.maxWidth >= 420 ? 4 : 3;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final img in images)
                    AgentThumb(
                      key: ValueKey('shelf-${img.id}'),
                      image: img,
                      width: w,
                      height: w * 1216 / 832,
                      source: img.source == AgentImageSource.attachment
                          ? l.ag_attachmentTag
                          : [
                              if (img.starred) '★',
                              ?img.label,
                            ].join(' ').trim().isEmpty
                          ? null
                          : [if (img.starred) '★', ?img.label].join(' '),
                    ),
                ],
              );
            },
          ),
        ],
        if (showFiles) ...[
          const SizedBox(height: 16),
          AgentEyebrow(l.ag_shelfFilesTitle),
          const SizedBox(height: 8),
          for (final f in shelf.files)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _FileRow(file: f),
            ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.ink : c.card,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: on ? c.ink : c.border),
          ),
          child: Text(
            label,
            style: UiText.sans(12, color: on ? c.bg : c.muted, height: 1.2),
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatefulWidget {
  const _FileRow({required this.file});
  final AgentFile file;

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final f = widget.file;
    final size = f.bytes == null
        ? null
        : f.bytes! < 1024
        ? '${f.bytes} B'
        : f.bytes! < 1024 * 1024
        ? '${(f.bytes! / 1024).toStringAsFixed(1)} KB'
        : '${(f.bytes! / 1024 / 1024).toStringAsFixed(1)} MB';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: Key('agent-file-${f.id}'),
        onTap: () => s.actions.onOpenFile(f.id),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hover ? c.hover : c.card,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: c.border),
          ),
          child: Row(
            spacing: 10,
            children: [
              AgentIcon(AgentGlyphs.file, size: 14, color: c.muted),
              Expanded(
                child: Text(
                  f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12.5, color: c.ink),
                ),
              ),
              Text(
                f.note ?? size ?? '',
                style: UiText.mono(11, color: c.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── 记忆 ───────────────────────────────

class AgentMemory extends StatelessWidget {
  const AgentMemory({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final m = s.data.memory!;
    final c = context.ui;
    final l = context.l10n;
    Widget card(
      Key key,
      String title,
      String body,
      AgentMemoryTarget target, {
      List<String>? chips,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgentCard(
        key: key,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: UiText.sans(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ),
                  AgentButton(
                    label: l.ag_memoryEdit,
                    glyph: AgentGlyphs.pen,
                    style: AgentButtonStyle.ghost,
                    height: 24,
                    onPressed: () => s.actions.onEditMemory(target),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: chips != null
                    ? (chips.isEmpty
                          ? Text(
                              l.ag_memoryEmpty,
                              style: UiText.sans(12, color: c.faint),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final name in chips)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.control,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      name,
                                      style: UiText.mono(
                                        11,
                                        color: c.ink,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ))
                    : Text(
                        body.trim().isEmpty ? l.ag_memoryEmpty : body.trim(),
                        maxLines: 8,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          12,
                          color: body.trim().isEmpty ? c.faint : c.muted,
                          height: 1.6,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    return ListView(
      key: const Key('agent-memory'),
      padding: const EdgeInsets.all(14),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            l.ag_memoryHint,
            style: UiText.sans(12, color: c.muted, height: 1.5),
          ),
        ),
        card(
          const Key('agent-memory-global'),
          l.ag_memoryGlobal,
          m.globalInstructions,
          AgentMemoryTarget.global,
        ),
        card(
          const Key('agent-memory-workspace'),
          l.ag_memoryWorkspace,
          m.workspaceRules,
          AgentMemoryTarget.workspace,
        ),
        card(
          const Key('agent-memory-skills'),
          l.ag_memorySkills,
          '',
          AgentMemoryTarget.skills,
          chips: m.activeSkills,
        ),
      ],
    );
  }
}

/// 内置四条快捷信息（按界面语言）；转接层没给自定义列表时用它。
List<AgentQuickItem> agentDefaultQuick(AppLocalizations l) => [
  AgentQuickItem(
    id: 'builtin-review',
    glyph: 'eye',
    title: l.ag_taskReview,
    hint: l.ag_taskReviewHint,
    prompt: l.ag_taskReviewPrompt,
  ),
  AgentQuickItem(
    id: 'builtin-analyze',
    glyph: 'image',
    title: l.ag_taskAnalyze,
    hint: l.ag_taskAnalyzeHint,
    prompt: l.ag_taskAnalyzePrompt,
  ),
  AgentQuickItem(
    id: 'builtin-variants',
    glyph: 'spark',
    title: l.ag_taskVariants,
    hint: l.ag_taskVariantsHint,
    prompt: l.ag_taskVariantsPrompt,
  ),
  AgentQuickItem(
    id: 'builtin-blocks',
    glyph: 'layers',
    title: l.ag_taskBlocks,
    hint: l.ag_taskBlocksHint,
    prompt: l.ag_taskBlocksPrompt,
  ),
];
