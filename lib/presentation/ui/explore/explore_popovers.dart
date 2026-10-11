import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_format.dart';
import 'explore_page.dart';
import 'explore_parts.dart';

/// 切换探索（原型 `.runpop`，宽 420）：搜索 · 新建探索 · 今天 / 本周 / 更早 · 底部说明。
/// 每行：3 张缩略图拼图 58 × 42 · 名称 + 状态 · 张数 / 收藏 / 进化线；当前那行强调色底 + 勾。
/// 双击名称改名，右侧“更多”可改名或删除。
class ExploreRunMenu extends StatefulWidget {
  const ExploreRunMenu({super.key});

  @override
  State<ExploreRunMenu> createState() => _ExploreRunMenuState();
}

class _ExploreRunMenuState extends State<ExploreRunMenu> {
  var _query = '';
  String? _renaming;
  String? _menuFor;
  final _search = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search.requestFocus();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final q = _query.trim().toLowerCase();
    final runs = [
      for (final r in data.runs)
        if (q.isEmpty || r.name.toLowerCase().contains(q)) r,
    ];
    final sections = <int, List<ExploreRunSummary>>{};
    for (final r in runs) {
      sections
          .putIfAbsent(ExploreFormat.bucket(r.updatedAt, data.now), () => [])
          .add(r);
    }
    final labels = [
      l.explore_sectionToday,
      l.explore_thisWeek,
      l.explore_earlier,
    ];

    Widget item(ExploreRunSummary r) {
      final current = r.id == data.run?.id;
      final meta = [
        l.explore_count(r.total),
        if (r.favorites > 0) l.explore_favoritesCount(r.favorites),
        if (r.lines > 0) l.explore_linesCount(r.lines),
      ].join(' · ');
      final pill = switch (r.state) {
        ExploreRunState.running => ExplorePill(
          l.explore_runRunning(r.done, r.target),
          tone: ExplorePillTone.run,
        ),
        ExploreRunState.paused => ExplorePill(
          l.explore_runPaused(r.done, r.target),
          tone: ExplorePillTone.pause,
        ),
        ExploreRunState.failed => ExplorePill(
          l.explore_runFailed(r.failed),
          tone: ExplorePillTone.error,
        ),
        ExploreRunState.idle => null,
      };
      return UiPressable(
        key: Key('explore-run-${r.id}'),
        onTap: () {
          ctrl.closePopover();
          if (!current) scope.actions.onOpenRun(r.id);
        },
        builder: (context, hover) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: current
                ? c.accent.withValues(alpha: .08)
                : (hover || _menuFor == r.id ? c.hover : null),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            spacing: 10,
            children: [
              _Mosaic(r.thumbs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    if (_renaming == r.id)
                      ExploreInlineInput(
                        key: const Key('explore-run-menu-rename'),
                        initial: r.name,
                        width: 220,
                        height: 24,
                        radius: 6,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                        onSubmit: (v) {
                          setState(() => _renaming = null);
                          scope.actions.onRenameRun(r.id, v);
                        },
                        onCancel: () => setState(() => _renaming = null),
                      )
                    else
                      Row(
                        spacing: 6,
                        children: [
                          Flexible(
                            child: Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(
                                13,
                                weight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ),
                          ?pill,
                        ],
                      ),
                    Text(
                      [
                        ExploreFormat.when(context, r.updatedAt, data.now),
                        meta,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ],
                ),
              ),
              if (current)
                UiGlyph(
                  UiGlyphs.check,
                  size: 16,
                  strokeWidth: 2.4,
                  color: c.accent,
                )
              else if (hover || _menuFor == r.id)
                _RunMore(
                  run: r,
                  open: _menuFor == r.id,
                  onOpen: (v) => setState(() => _menuFor = v ? r.id : null),
                  onRename: () => setState(() {
                    _menuFor = null;
                    _renaming = r.id;
                  }),
                  onDelete: () {
                    setState(() => _menuFor = null);
                    ctrl.confirmDeleteRun(r.id);
                  },
                )
              else if (current)
                SizedBox(
                  width: 26,
                  child: UiGlyph(
                    UiGlyphs.check,
                    size: 16,
                    strokeWidth: 2.4,
                    color: c.accent,
                  ),
                )
              else
                const SizedBox(width: 26),
            ],
          ),
        ),
      );
    }

    return UiPopoverSurface(
      key: const Key('explore-run-menu'),
      width: 420,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: UiSearchField(
                key: const Key('explore-run-search'),
                value: _query,
                hint: l.explore_searchRuns,
                focusNode: _search,
                height: 34,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UiPressable(
                      key: const Key('explore-new-run'),
                      onTap: () {
                        ctrl.closePopover();
                        scope.actions.onNewRun();
                      },
                      builder: (context, hover) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hover ? c.hover : null,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          spacing: 10,
                          children: [
                            Container(
                              width: 58,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.accent.withValues(alpha: .06),
                                border: Border.all(
                                  color: c.accent.withValues(alpha: .5),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: UiGlyph(
                                UiGlyphs.plus,
                                size: 18,
                                color: c.accent,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 3,
                                children: [
                                  Text(
                                    l.explore_newRun,
                                    style: UiText.sans(
                                      13,
                                      weight: FontWeight.w600,
                                      color: c.accent,
                                    ),
                                  ),
                                  Text(
                                    l.explore_newRunHint,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.sans(12, color: c.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (final b in [0, 1, 2])
                      if (sections[b] case final list?) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                          child: Text(
                            labels[b],
                            style: UiText.sans(
                              11,
                              weight: FontWeight.w600,
                              color: c.faint,
                            ),
                          ),
                        ),
                        for (final r in list) item(r),
                      ],
                    if (runs.isEmpty && q.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          l.explore_noRunMatch,
                          textAlign: TextAlign.center,
                          style: UiText.sans(12.5, color: c.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                spacing: 6,
                children: [
                  UiGlyph(UiGlyphs.infoCircle, size: 13, color: c.faint),
                  Expanded(
                    child: Text(
                      l.explore_runMenuHint,
                      style: UiText.sans(12, color: c.muted),
                    ),
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

/// 3 张缩略图拼图（原型 `.mosaic`）：58 × 42、圆角 6、间距 2。
class _Mosaic extends StatelessWidget {
  const _Mosaic(this.thumbs);
  final List<ImageProvider?> thumbs;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 58,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        spacing: 2,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(child: ExploreImage(i < thumbs.length ? thumbs[i] : null)),
        ],
      ),
    );
  }
}

/// 一行右侧的“更多”：就地展开 改名 / 删除 两个小按钮（下拉里再套弹层会被下拉的点外关闭吞掉）。
class _RunMore extends StatelessWidget {
  const _RunMore({
    required this.run,
    required this.open,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });
  final ExploreRunSummary run;
  final bool open;
  final ValueChanged<bool> onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    if (!open) {
      return UiIconBox(
        key: Key('explore-run-more-${run.id}'),
        glyph: UiGlyphs.more,
        size: 26,
        tooltip: l.explore_more,
        onTap: () => onOpen(true),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        UiIconBox(
          key: Key('explore-run-rename-${run.id}'),
          glyph: UiGlyphs.pencil,
          size: 26,
          glyphSize: 14,
          tooltip: l.explore_rename,
          onTap: onRename,
        ),
        UiIconBox(
          key: Key('explore-run-delete-${run.id}'),
          glyph: UiGlyphs.trash,
          size: 26,
          glyphSize: 14,
          color: c.error,
          tooltip: l.explore_deleteRun,
          onTap: onDelete,
        ),
      ],
    );
  }
}
