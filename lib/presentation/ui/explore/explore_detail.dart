import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import '../viewer/viewer_contract.dart';
import '../viewer/viewer_page.dart';
import 'explore_format.dart';
import 'explore_page.dart';
import 'explore_parts.dart';

/// 候选大图：直接用本地画廊的大图查看器（缩放、平移、小地图、胶片条、全屏都一样），
/// 右侧换成探索自己的信息栏（操作 · 本张抽到 · 完整提示词 · 分组 · 参数 · 删除）。
/// 查看器的 0 / 1（适应 / 原始大小）让给分组快捷键，Ctrl+C 让给“复制画师串”。
class ExploreDetail extends StatefulWidget {
  const ExploreDetail({
    super.key,
    required this.currentKey,
    required this.keys,
    required this.onClose,
    required this.onStep,
    required this.onCaptionOverStage,
  });
  final String currentKey;

  /// 可以左右翻的候选（当前筛选下已生成的）。
  final List<String> keys;
  final VoidCallback onClose;
  final ValueChanged<String> onStep;
  final ValueChanged<bool> onCaptionOverStage;

  @override
  State<ExploreDetail> createState() => _ExploreDetailState();
}

class _ExploreDetailState extends State<ExploreDetail> {
  var _info = true;
  var _hintSeen = false;

  static final _keys = <ViewerCommand, List<SingleActivator>>{
    ...ViewerKeys.defaults,
    ViewerCommand.zoomFit: const [],
    ViewerCommand.zoomActual: const [],
    ViewerCommand.copyPrompt: const [],
    ViewerCommand.reuse: const [],
    ViewerCommand.undo: const [],
    ViewerCommand.save: const [],
  };

  void _go(int index) {
    final k = widget.keys;
    if (k.isEmpty) return;
    widget.onStep(k[index.clamp(0, k.length - 1)]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final run = scope.data.run!;
    final a = scope.actions;
    final keys = widget.keys;
    final index = keys.indexOf(widget.currentKey);
    final data = ViewerViewData(
      mode: ViewerMode.gallery,
      now: scope.data.now,
      currentKey: widget.currentKey,
      position: index < 0 ? 0 : index,
      total: keys.length,
      scope: ViewerScope(name: run.name),
      backLabel: l.explore_back,
      items: [
        for (final k in keys)
          if (run.candidate(k) case final x?)
            ViewerItem(
              key: x.key,
              width: x.width,
              height: x.height,
              thumb: x.thumb ?? x.image,
              image: x.image ?? x.thumb,
              date: x.createdAt,
              favorite: x.favorite,
            ),
      ],
      infoOpen: _info,
      fullscreen: scope.data.fullscreen,
      keys: _keys,
      zoomHintSeen: _hintSeen,
    );
    final actions = ViewerActions(
      onClose: ({required keyboard}) => widget.onClose(),
      onSelect: widget.onStep,
      onStep: (d) => _go(index + d),
      onJump: ({required last}) => _go(last ? keys.length - 1 : 0),
      onLoadMore: ({required forward}) {},
      onInfoChanged: (v) => setState(() => _info = v),
      onFullscreenChanged: a.onFullscreenChanged,
      onSetFavorite: (k, v) => a.onSetFavorite([k], v),
      onToggleCollection: (_, _, _) {},
      onCreateCollection: (_) {},
      onDelete: (k) => a.onDeleteCandidates([k]),
      onUndoDelete: a.onUndoDelete,
      onDismissUndo: a.onDismissUndo,
      onAction: (_, _) {},
      onCopy: (_, _) {},
      onToggleTranslation: (_, _) {},
      onSaveVibe: (_, _) {},
      onZoomHintSeen: () => setState(() => _hintSeen = true),
      onCaptionOverStage: widget.onCaptionOverStage,
    );
    return ImageViewerPage(
      key: const Key('explore-detail'),
      data: data,
      actions: actions,
      infoBuilder: (context, drawer) =>
          _DetailInfo(candidateKey: widget.currentKey, drawer: drawer),
    );
  }
}

/// 大图右侧信息栏 340：头部 61（#27 · 第 3 轮 · 18:54）· 2 × 2 操作 · 本张抽到 · 完整提示词（高亮，可展开）·
/// 负面（展开）· 分组（键帽 1–9）· 参数 —— 底部“删除这张”。
class _DetailInfo extends StatefulWidget {
  const _DetailInfo({required this.candidateKey, required this.drawer});
  final String candidateKey;
  final bool drawer;

  @override
  State<_DetailInfo> createState() => _DetailInfoState();
}

class _DetailInfoState extends State<_DetailInfo> {
  var _full = false;
  var _neg = false;

  @override
  void didUpdateWidget(covariant _DetailInfo old) {
    super.didUpdateWidget(old);
    if (old.candidateKey != widget.candidateKey) {
      _full = false;
      _neg = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final run = scope.data.run!;
    final a = scope.actions;
    final ctrl = scope.controller;
    final x = run.candidate(widget.candidateKey);
    if (x == null) return const SizedBox(width: 340);
    final round = run.rounds.where((r) => r.id == x.roundId).firstOrNull;
    final child = x.op != null;
    final chrome = WindowChromeScope.activeOf(context);

    final kv = <(String, String)>[
      if (x.model != null) (l.explore_model, x.model!),
      (
        l.explore_params,
        [
          '${x.width}×${x.height}',
          if (x.steps != null) l.explore_steps(x.steps!),
          if (x.scale != null) 'CFG ${ExploreFormat.scale(x.scale!)}',
          ?x.sampler,
        ].join(' · '),
      ),
      if (x.seed != null) (l.explore_seed, '${x.seed}'),
      if (x.elapsed != null)
        (l.explore_elapsed, ExploreFormat.seconds(x.elapsed!)),
    ];

    return Container(
      key: const Key('explore-detail-info'),
      width: 340,
      decoration: BoxDecoration(
        color: c.panel,
        border: widget.drawer ? null : Border(left: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WindowHeader(
            enabled: !widget.drawer,
            minimumInlineWidth: 0,
            inlineDragWidth: 8,
            dragBackground: !widget.drawer,
            decoration: const BoxDecoration(),
            child: Container(
              height: 61,
              padding: EdgeInsets.only(
                left: 18,
                right: !widget.drawer && chrome ? 0 : 12,
              ),
              child: Row(
                spacing: 8,
                children: [
                  Text(
                    child ? l.explore_childN(x.number) : '#${x.number}',
                    style: UiText.sans(
                      14,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  if (child)
                    ExplorePill(
                      l.explore_genOp(
                        x.generation ?? 1,
                        ExploreFormat.opLabel(l, x.op!),
                      ),
                      tone: ExplorePillTone.evo,
                    )
                  else if (round != null)
                    Text(
                      '${l.explore_round(round.number)} · ${ExploreFormat.clock(x.createdAt ?? round.createdAt)}',
                      style: UiText.sans(12, color: c.muted),
                    ),
                  const Spacer(),
                  if (widget.drawer)
                    UiIconBox(
                      glyph: UiGlyphs.close,
                      size: 28,
                      tooltip: l.explore_hideInspector,
                      onTap: () => _closeDrawer(context),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('explore-detail-scroll'),
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _grid([
                    ExploreActTile(
                      key: const Key('explore-detail-favorite'),
                      glyph: UiGlyphs.heartLib,
                      filled: x.favorite,
                      on: x.favorite,
                      label: x.favorite
                          ? l.explore_favorited
                          : l.explore_favorite,
                      keyLabel: 'F',
                      onTap: () => a.onSetFavorite([x.key], !x.favorite),
                    ),
                    ExploreActTile(
                      key: const Key('explore-detail-evolution'),
                      glyph: UiGlyphs.evo,
                      color: c.evo,
                      label: l.explore_addToEvolution,
                      keyLabel: 'E',
                      onTap: () => ctrl.startEvolution([x.key]),
                    ),
                    ExploreActTile(
                      key: const Key('explore-detail-block'),
                      glyph: UiGlyphs.archive,
                      label: l.explore_saveBlock,
                      onTap: () => ctrl.saveBlock([x.key]),
                    ),
                    ExploreActTile(
                      key: const Key('explore-detail-apply'),
                      glyph: UiGlyphs.enter,
                      label: l.explore_applyToEditor,
                      onTap: () => a.onApplyToEditor(x.key),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ExploreSect(
                    l.explore_drawn,
                    trailing: ExploreLink(
                      label: l.explore_copyArtists,
                      glyph: UiGlyphs.copy,
                      onTap: () => a.onCopyArtists([x.key]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final d in x.draws) ...[
                    ExploreDrawBox(d),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 10),
                  ExploreSect(
                    l.explore_fullPrompt,
                    trailing: ExploreLink(
                      label: l.explore_copy,
                      glyph: UiGlyphs.copy,
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: x.prompt)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _Fold(
                    key: const Key('explore-detail-prompt'),
                    open: _full,
                    onToggle: () => setState(() => _full = !_full),
                    child: ExplorePromptText(text: x.prompt, hits: x.hits),
                  ),
                  if (x.negative.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    UiPressable(
                      key: const Key('explore-detail-negative-toggle'),
                      onTap: () => setState(() => _neg = !_neg),
                      builder: (context, hover) => ExploreSect(
                        l.explore_negative,
                        color: hover ? c.ink : null,
                        trailing: UiGlyph(
                          _neg ? UiGlyphs.chevronUp : UiGlyphs.chevronDown,
                          size: 13,
                          color: c.muted,
                        ),
                      ),
                    ),
                    if (_neg) ...[
                      const SizedBox(height: 6),
                      Text(
                        x.negative,
                        style: UiText.sans(12, color: c.muted, height: 1.6),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  ExploreSect(l.explore_groups),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (i, g) in run.groups.indexed)
                        _GroupKey(
                          key: Key('explore-detail-group-${g.id}'),
                          label: g.name,
                          keyLabel: i < 9 ? '${i + 1}' : null,
                          on: x.groupId == g.id,
                          onTap: () => a.onAssignGroup([
                            x.key,
                          ], x.groupId == g.id ? null : g.id),
                        ),
                      _GroupKey(
                        label: l.explore_ungroup,
                        keyLabel: '0',
                        on: x.groupId == null,
                        onTap: () => a.onAssignGroup([x.key], null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final (k, v) in kv)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              k,
                              style: UiText.sans(12, color: c.muted),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              v,
                              style: UiText.mono(12, color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: UiBtn(
              key: const Key('explore-detail-delete'),
              expand: true,
              color: c.error,
              onTap: () => a.onDeleteCandidates([x.key]),
              children: [
                UiGlyph(UiGlyphs.trash, size: 14, color: c.error),
                Text(l.explore_deleteThis),
                const UiKeycap('Del'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _closeDrawer(BuildContext context) {
    ViewerPageScope.of(context).controller.closeDrawer();
  }

  static Widget _grid(List<Widget> children) => Column(
    spacing: 6,
    children: [
      for (var i = 0; i < children.length; i += 2)
        Row(
          spacing: 6,
          children: [
            Expanded(child: children[i]),
            Expanded(child: children[i + 1]),
          ],
        ),
    ],
  );
}

/// 提示词框：最多 150 高，超出底部渐隐 + “展开全部”。
class _Fold extends StatelessWidget {
  const _Fold({
    super.key,
    required this.open,
    required this.onToggle,
    required this.child,
  });
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (open)
            child
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Colors.transparent],
                  stops: [0, .7, 1],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: child,
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: ExploreLink(
              key: const Key('explore-detail-prompt-toggle'),
              label: open ? l.explore_collapse : l.explore_expandAll,
              onTap: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

/// 分组胶囊（大图里带键帽）：26 高、圆角 13。
class _GroupKey extends StatelessWidget {
  const _GroupKey({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    this.keyLabel,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;
  final String? keyLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 26,
        padding: const EdgeInsets.only(left: 9, right: 5),
        decoration: BoxDecoration(
          color: on
              ? Color.alphaBlend(c.accent.withValues(alpha: .07), c.raised)
              : (hover ? c.hover : c.raised),
          border: Border.all(color: on ? c.accent : c.line),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Text(
              label,
              style: UiText.sans(
                12,
                weight: on ? FontWeight.w600 : FontWeight.w400,
                color: on ? c.accent : c.muted,
              ),
            ),
            if (keyLabel != null) UiKeycap(keyLabel!),
          ],
        ),
      ),
    );
  }
}
