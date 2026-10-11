import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';
import 'refs_page.dart';

UiPopoverAnchor anchorBelow(BuildContext ctx, {bool right = false}) {
  final box = ctx.findRenderObject()! as RenderBox;
  return UiPopoverAnchor(
    box.localToGlobal(
      right
          ? box.size.bottomRight(const Offset(0, 6))
          : box.size.bottomLeft(const Offset(0, 6)),
    ),
    alignRight: right,
  );
}

/// 工具栏 62：搜索 300 · 排序 · 卡片大小 ┊ 当前模型 · 多选 · 导入 · 更多 · 检查器开关。
class RefsToolbar extends StatelessWidget {
  const RefsToolbar({
    super.key,
    required this.inspectorShown,
    required this.sidebarShown,
  });

  final bool inspectorShown;
  final bool sidebarShown;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final f = data.filter;
    final vibe = data.kind == RefsKind.vibe;
    final empty = data.libraryEmpty;

    List<UiMenuItem> sortMenu() => [
      for (final s in RefsSort.values)
        UiMenuItem(
          key: Key('refs-sort-${s.name}'),
          label: RefsFormat.sort(context, s),
          checked: f.sort == s,
          onTap: () => a.onFilterChanged(f.copyWith(sort: s)),
        ),
      UiMenuItem(
        glyph: f.descending ? UiGlyphs.chevronDown : UiGlyphs.chevronUp,
        label: f.descending ? l10n.refs_sortDesc : l10n.refs_sortAsc,
        divider: true,
        onTap: () => a.onFilterChanged(f.copyWith(descending: !f.descending)),
      ),
    ];

    List<UiMenuItem> importMenu() => [
      if (vibe)
        UiMenuItem(
          glyph: UiGlyphs.file,
          label: l10n.refs_importFiles,
          trailing: 'Ctrl I',
          onTap: () => a.onImport(RefsImportSource.files),
        ),
      UiMenuItem(
        glyph: UiGlyphs.picture,
        label: l10n.refs_importImages,
        trailing: vibe ? null : 'Ctrl I',
        onTap: () => a.onImport(RefsImportSource.images),
      ),
      UiMenuItem(
        glyph: UiGlyphs.clipboard,
        label: l10n.refs_importClipboard,
        trailing: 'Ctrl V',
        onTap: () => a.onImport(RefsImportSource.clipboard),
      ),
    ];

    List<UiMenuItem> moreMenu() => [
      if (vibe) ...[
        UiMenuItem(
          glyph: UiGlyphs.upload,
          label: l10n.refs_exportAll,
          enabled: !empty,
          onTap: a.onExportAll,
        ),
        UiMenuItem(
          glyph: UiGlyphs.folder,
          label: l10n.refs_openLibraryFolder,
          onTap: () => a.onOpenFolder(null),
        ),
      ],
      UiMenuItem(
        glyph: UiGlyphs.refresh,
        label: vibe ? l10n.refs_rescan : l10n.refs_reload,
        divider: vibe,
        onTap: a.onRescan,
      ),
    ];

    // 检查器收起时，窗口按钮落在工具栏右上角：让出位置，空白处可以拖动窗口。
    final reserve = !inspectorShown;
    final chrome = WindowChromeScope.activeOf(context);
    return WindowHeader(
      key: const Key('refs-toolbar'),
      enabled: reserve,
      minimumInlineWidth: 0,
      inlineDragWidth: 12,
      dragBackground: true,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Container(
        height: 61,
        padding: EdgeInsets.only(
          left: sidebarShown ? 18 : 12,
          right: reserve && chrome ? 0 : 16,
        ),
        // 窄了先把排序、多选收成图标、模型胶囊去掉“当前模型”，再窄就收起模型胶囊和卡片大小。
        child: LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxWidth < 900;
            final tight = box.maxWidth < 640;
            return Row(
              spacing: 8,
              children: [
                if (!sidebarShown)
                  UiIconBox(
                    key: const Key('refs-expand-sidebar'),
                    glyph: UiGlyphs.doubleRight,
                    tooltip: l10n.refs_expandSidebar,
                    onTap: () => a.onSidebarChanged(true),
                  ),
                // 原型里搜索组后面是“8 间距 + 弹性留白 + 8 间距”：右侧多留 8。
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: _SearchBox(
                              key: const Key('refs-search'),
                              enabled: !empty,
                              hint: vibe
                                  ? l10n.refs_searchVibe
                                  : l10n.refs_searchPrecise,
                            ),
                          ),
                        ),
                        if (!empty) ...[
                          Builder(
                            builder: (ctx) => compact
                                ? UiIconBox(
                                    key: const Key('refs-sort'),
                                    glyph: UiGlyphs.sort,
                                    tone: UiIconBoxTone.bordered,
                                    tooltip: RefsFormat.sort(context, f.sort),
                                    onTap: () => ctrl.openMenu(
                                      anchorBelow(ctx),
                                      sortMenu(),
                                    ),
                                  )
                                : UiDropChip(
                                    key: const Key('refs-sort'),
                                    glyph: UiGlyphs.sort,
                                    label: RefsFormat.sort(context, f.sort),
                                    onTap: () => ctrl.openMenu(
                                      anchorBelow(ctx),
                                      sortMenu(),
                                    ),
                                  ),
                          ),
                          if (!tight)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: UiSeg<RefsCardSize>(
                                key: const Key('refs-card-size'),
                                values: RefsCardSize.values,
                                selected: data.cardSize,
                                onChanged: a.onCardSizeChanged,
                                labelOf: (s) => switch (s) {
                                  RefsCardSize.small => '',
                                  RefsCardSize.medium => l10n.refs_sizeMedium,
                                  RefsCardSize.large => l10n.refs_sizeLarge,
                                },
                                glyphOf: (s) => s == RefsCardSize.small
                                    ? UiGlyphs.sizes
                                    : null,
                                tooltipOf: (s) => switch (s) {
                                  RefsCardSize.small => l10n.refs_sizeSmall,
                                  RefsCardSize.medium => l10n.refs_sizeMedium,
                                  RefsCardSize.large => l10n.refs_sizeLarge,
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!empty) ...[
                  if (!tight) RefsModelCapsule(showLabel: !compact),
                  UiBtn(
                    key: Key(ctrl.picking ? 'refs-multi-done' : 'refs-multi'),
                    tone: ctrl.picking ? UiBtnTone.accent : UiBtnTone.normal,
                    tooltip: compact
                        ? (ctrl.picking ? l10n.refs_multiDone : l10n.refs_multi)
                        : null,
                    padding: compact
                        ? const EdgeInsets.symmetric(horizontal: 7)
                        : null,
                    onTap: () => ctrl.setPicking(!ctrl.picking),
                    children: [
                      const UiGlyph(UiGlyphs.check, size: 14, strokeWidth: 2.2),
                      if (!compact)
                        Text(
                          ctrl.picking ? l10n.refs_multiDone : l10n.refs_multi,
                        ),
                    ],
                  ),
                ],
                _SplitButton(
                  onTap: () => a.onImport(
                    vibe ? RefsImportSource.files : RefsImportSource.images,
                  ),
                  onMenu: (ctx) => ctrl.openMenu(
                    anchorBelow(ctx, right: true),
                    importMenu(),
                  ),
                  label: l10n.refs_import,
                ),
                Builder(
                  builder: (ctx) => UiIconBox(
                    key: const Key('refs-more'),
                    glyph: UiGlyphs.more,
                    glyphSize: 16,
                    tooltip: l10n.refs_more,
                    onTap: () => ctrl.openMenu(
                      anchorBelow(ctx, right: true),
                      moreMenu(),
                    ),
                  ),
                ),
                if (!empty)
                  UiIconBox(
                    key: const Key('refs-inspector-toggle'),
                    glyph: UiGlyphs.panel,
                    tone: inspectorShown
                        ? UiIconBoxTone.on
                        : UiIconBoxTone.plain,
                    tooltip: inspectorShown
                        ? l10n.refs_hideInspector
                        : l10n.refs_showInspector,
                    onTap: () => a.onInspectorChanged(!data.inspectorOpen),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 主按钮 + 竖线 + 箭头（“导入 ▾”）。
class _SplitButton extends StatelessWidget {
  const _SplitButton({
    required this.onTap,
    required this.onMenu,
    required this.label,
  });
  final VoidCallback onTap;
  final void Function(BuildContext) onMenu;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget part(Widget child, VoidCallback tap, EdgeInsets pad, Key key) =>
        UiPressable(
          key: key,
          onTap: tap,
          builder: (context, hover) => Container(
            height: 30,
            padding: pad,
            color: hover ? Colors.black.withValues(alpha: .08) : null,
            child: child,
          ),
        );
    return Container(
      height: 30,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          part(
            Row(
              spacing: 6,
              children: [
                const UiGlyph(UiGlyphs.plus, size: 14, color: Colors.white),
                Text(
                  label,
                  style: UiText.sans(
                    12.5,
                    weight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            onTap,
            const EdgeInsets.only(left: 12, right: 8),
            const Key('refs-import'),
          ),
          Container(
            width: 1,
            height: 18,
            color: Colors.white.withValues(alpha: .35),
          ),
          Builder(
            builder: (ctx) => part(
              const Center(
                widthFactor: 1,
                child: UiGlyph(
                  UiGlyphs.chevronDown,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              () => onMenu(ctx),
              const EdgeInsets.only(left: 3, right: 12),
              const Key('refs-import-menu'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 当前模型胶囊：30 高、圆角 15、控件底；“当前模型 V4.5 Full ✓可用”。
class RefsModelCapsule extends StatelessWidget {
  const RefsModelCapsule({
    super.key,
    this.model,
    this.kind,
    this.showLabel = true,
  });
  final RefsModel? model;

  /// 窄工具栏里去掉“当前模型”几个字。
  final bool showLabel;
  final RefsKind? kind;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = model == null ? RefsScope.of(context) : null;
    final m = model ?? scope!.data.model;
    final k = kind ?? scope!.data.kind;
    final ok = k == RefsKind.vibe ? m.vibeUsable : m.preciseUsable;
    return Container(
      key: const Key('refs-model'),
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (showLabel)
            Text(
              l10n.refs_currentModel,
              style: UiText.sans(12, color: c.muted),
            ),
          Text(
            m.name,
            style: UiText.sans(12, weight: FontWeight.w700, color: c.ink),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: UiMini(
              ok ? l10n.refs_usable : l10n.refs_unusable,
              tone: ok ? UiMiniTone.ok : UiMiniTone.warn,
              glyph: ok ? UiGlyphs.check : UiGlyphs.ban,
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索框 36：控件底、圆角 9；聚焦时抬起底 + 强调色环。停 300ms 回调；有字时尾部是清除。
class _SearchBox extends StatefulWidget {
  const _SearchBox({super.key, required this.hint, required this.enabled});
  final String hint;
  final bool enabled;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  var _synced = '';
  RefsFilter? _filter;
  ValueChanged<RefsFilter>? _onChanged;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = RefsScope.of(context);
    _filter = scope.data.filter;
    _onChanged = scope.actions.onFilterChanged;
    final q = scope.data.filter.query;
    if (q != _synced && _debounce?.isActive != true) {
      _synced = q;
      if (_ctrl.text != q) _ctrl.text = q;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _changed(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _submit(v));
  }

  void _submit(String v) {
    _debounce?.cancel();
    _synced = v.trim();
    _onChanged?.call(_filter!.copyWith(query: v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final focus = RefsScope.of(context).controller.searchFocus;
    return ListenableBuilder(
      listenable: focus,
      builder: (context, _) {
        final on = focus.hasFocus;
        return Container(
          height: 36,
          padding: const EdgeInsets.only(left: 11, right: 6),
          decoration: BoxDecoration(
            color: on ? c.raised : c.control,
            borderRadius: BorderRadius.circular(9),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: .14),
                      spreadRadius: 4,
                    ),
                    BoxShadow(color: c.accent, spreadRadius: 1),
                  ]
                : null,
          ),
          child: Row(
            spacing: 8,
            children: [
              UiGlyph(UiGlyphs.search, size: 15, color: c.faint),
              Expanded(
                child: Focus(
                  onKeyEvent: (_, e) {
                    if (e is KeyDownEvent &&
                        e.logicalKey == LogicalKeyboardKey.escape) {
                      if (_ctrl.text.isNotEmpty) {
                        _ctrl.clear();
                        _submit('');
                      } else {
                        focus.unfocus();
                      }
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _ctrl,
                    focusNode: focus,
                    enabled: widget.enabled,
                    style: UiText.sans(13, color: c.ink),
                    cursorColor: c.accent,
                    cursorHeight: 15,
                    decoration: uiBareDecoration(
                      hintText: widget.hint,
                      hintStyle: UiText.sans(13, color: c.faint),
                    ),
                    onChanged: _changed,
                    onSubmitted: _submit,
                  ),
                ),
              ),
              if (_ctrl.text.isNotEmpty)
                UiIconBox(
                  glyph: UiGlyphs.close,
                  size: 24,
                  glyphSize: 13,
                  onTap: () {
                    _ctrl.clear();
                    _submit('');
                  },
                )
              else if (!on)
                const UiKeycap('/'),
            ],
          ),
        );
      },
    );
  }
}

/// 当前模型不能用这种参考时的横幅（V5）：说清楚还能做什么，给“切到 …”。
class RefsModelBanner extends StatelessWidget {
  const RefsModelBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final m = data.model;
    final vibe = data.kind == RefsKind.vibe;
    return Container(
      key: const Key('refs-banner'),
      padding: const EdgeInsets.fromLTRB(18, 10, 16, 10),
      decoration: BoxDecoration(
        color: c.warnBg,
        border: Border(bottom: BorderSide(color: c.warn.withValues(alpha: .3))),
      ),
      child: Row(
        spacing: 10,
        children: [
          UiGlyph(UiGlyphs.alert, size: 15, color: c.warn),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: vibe
                        ? l10n.refs_bannerVibeLead(m.shortName)
                        : l10n.refs_bannerPreciseLead(m.shortName),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: vibe
                        ? l10n.refs_bannerVibeBody
                        : l10n.refs_bannerPreciseBody,
                  ),
                ],
              ),
              style: UiText.sans(12.5, color: c.ink, height: 1.5),
            ),
          ),
          if (m.switchTarget case final t?)
            UiBtn(
              key: const Key('refs-switch-model'),
              size: UiBtnSize.small,
              onTap: scope.actions.onSwitchModel,
              children: [Text(l10n.refs_switchTo(t))],
            ),
        ],
      ),
    );
  }
}

/// 快速筛选行 46：Vibe 全部 / 收藏 / 有原图 / 需要编码 / 组合包，精准参考 全部 / 收藏 / 没用过；右边计数。
class RefsFilterRow extends StatelessWidget {
  const RefsFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final f = data.filter;
    final vibe = data.kind == RefsKind.vibe;
    final n = data.counts;
    Widget chip(RefsQuick q, String label, [int? count]) => UiFilterChip(
      key: Key('refs-quick-${q.name}'),
      label: label,
      count: count,
      gap: 5,
      selected: f.quick == q,
      onTap: () => scope.actions.onFilterChanged(f.copyWith(quick: q)),
    );
    final inGen = n.inGeneration;
    return Container(
      key: const Key('refs-filter-row'),
      height: 46,
      padding: const EdgeInsets.only(left: 18, right: 16),
      child: Row(
        spacing: 8,
        children: [
          chip(RefsQuick.all, l10n.refs_quickAll, n.all),
          chip(RefsQuick.favorites, l10n.refs_quickFavorites),
          if (vibe) ...[
            chip(RefsQuick.hasRaw, l10n.refs_quickHasRaw),
            chip(
              RefsQuick.needsEncoding,
              l10n.refs_quickNeedsEncoding,
              n.needsEncoding,
            ),
            chip(RefsQuick.bundles, l10n.refs_quickBundles),
          ] else
            chip(RefsQuick.unused, l10n.refs_quickUnused),
          const Spacer(),
          Text(
            vibe
                ? l10n.refs_countVibe(data.entries.length, inGen)
                : l10n.refs_countPrecise(data.entries.length, inGen),
            key: const Key('refs-count'),
            style: UiText.mono(11.5, color: c.faint),
          ),
        ],
      ),
    );
  }
}
