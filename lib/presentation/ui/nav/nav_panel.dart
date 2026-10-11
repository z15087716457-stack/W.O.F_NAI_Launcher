import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_text.dart';
import 'nav_contract.dart';
import 'nav_labels.dart';
import 'nav_rail.dart';

/// 展开导航：236 宽。不钉住时是盖在页面上的浮层（带投影）；钉住时是常驻栏（推开页面，没有投影）。
class NavPanel extends StatelessWidget {
  const NavPanel({
    super.key,
    required this.data,
    required this.onOpenPage,
    required this.onAccount,
    required this.onPinnedChanged,
    required this.onCollapse,
  });

  static const width = 236.0;

  final NavViewData data;
  final ValueChanged<NavPage> onOpenPage;
  final ValueChanged<BuildContext> onAccount;
  final ValueChanged<bool> onPinnedChanged;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final account = data.account;
    final anlas = account.anlas == null
        ? null
        : 'Anlas ${NumberFormat('#,##0').format(account.anlas)}';
    final second = [?account.plan, ?anlas].join(' · ');
    List<String>? keys(NavPage p) => data.shortcuts[p];

    Widget page(NavPage p, {bool inList = true}) => _PanelRow(
      rowKey: Key('main-nav-panel-${p.name}'),
      inList: inList,
      selected: data.current == p,
      leading: Icon(
        p.icon,
        size: p == NavPage.settings ? 18 : 19,
        color: data.current == p ? c.accent : c.ink.withValues(alpha: .7),
      ),
      label: p.label(context),
      trailing: keys(p) == null
          ? null
          : UiKeycaps(keys(p)!, style: UiKeycapStyle.compact),
      onTap: () => onOpenPage(p),
    );

    return Container(
      key: const Key('main-nav-panel'),
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(right: BorderSide(color: c.line)),
        boxShadow: data.pinned
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: c.dark ? .5 : .14),
                  blurRadius: 30,
                  offset: const Offset(10, 0),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) => _Hoverable(
              key: const Key('main-nav-panel-account'),
              radius: 9,
              onTap: () => onAccount(context),
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 6, 0),
                  child: Row(
                    spacing: 10,
                    children: [
                      NavAvatar(
                        account: account.current,
                        size: 30,
                        showSubscriptionDot: false,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.current?.name ??
                                  l.navShell_accountNotSignedIn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(
                                13,
                                weight: FontWeight.w700,
                                height: 1.3,
                                color: c.ink,
                              ),
                            ),
                            if (second.isNotEmpty)
                              Text(
                                second,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(
                                  11,
                                  height: 1.3,
                                  color: c.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      UiGlyph(UiGlyphs.chevronDown, size: 15, color: c.faint),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(6, 0, 6, 2),
            color: c.line,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final g in data.visibleGroups) ...[
                    Padding(
                      key: Key(
                        'main-nav-panel-group-${navGroups.indexOf(_full(g))}',
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      child: Text(
                        navGroupLabel(context, navGroups.indexOf(_full(g))),
                        style: UiText.sans(
                          11,
                          weight: FontWeight.w600,
                          letterSpacing: .3,
                          color: c.faint,
                        ),
                      ),
                    ),
                    for (final p in g) page(p),
                    const SizedBox(height: 1),
                  ],
                ],
              ),
            ),
          ),
          _PanelRow(
            rowKey: const Key('main-nav-panel-pin'),
            leading: UiGlyph(UiGlyphs.pin, size: 17, color: c.muted),
            label: l.navShell_pin,
            labelColor: c.muted,
            trailing: UiSwitch(value: data.pinned),
            onTap: () => onPinnedChanged(!data.pinned),
          ),
          _PanelRow(
            rowKey: const Key('main-nav-panel-collapse'),
            leading: UiGlyph(UiGlyphs.doubleLeft, size: 17, color: c.muted),
            label: l.navShell_collapse,
            labelColor: c.muted,
            trailing: data.pinned
                ? null
                : const UiKeycaps(['Esc'], style: UiKeycapStyle.compact),
            onTap: onCollapse,
          ),
          page(NavPage.settings, inList: false),
        ],
      ),
    );
  }

  /// 可见分组是原分组的子集，找回它在 [navGroups] 里是第几组。
  static List<NavPage> _full(List<NavPage> visible) =>
      navGroups.firstWhere((g) => g.contains(visible.first));
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    this.rowKey,
    this.inList = false,
    required this.leading,
    required this.label,
    required this.onTap,
    this.trailing,
    this.selected = false,
    this.labelColor,
  });

  final Key? rowKey;

  /// 分组列表里的行：上下相邻的 1px 间距合并（和原型的块级外边距折叠一致），行距 37。
  final bool inList;
  final Widget leading;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool selected;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: inList
          ? const EdgeInsets.only(top: 1)
          : const EdgeInsets.symmetric(vertical: 1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Hoverable(
            key: rowKey,
            radius: 8,
            selected: selected,
            onTap: onTap,
            child: SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                child: Row(
                  spacing: 10,
                  children: [
                    SizedBox(width: 22, child: Center(child: leading)),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          13,
                          weight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? c.accent : labelColor ?? c.ink,
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
          if (selected)
            const Positioned(left: -8, top: 10, child: NavSelectedBar()),
        ],
      ),
    );
  }
}

/// 可聚焦的悬停块：悬停 = 悬停底；选中 = 强调色 10%（悬停 16%）。
class _Hoverable extends StatefulWidget {
  const _Hoverable({
    super.key,
    required this.child,
    required this.onTap,
    required this.radius,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;
  final bool selected;

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  var _hover = false;
  var _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final bg = widget.selected
        ? c.accent.withValues(alpha: _hover ? .16 : .10)
        : _hover
        ? c.hover
        : null;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            foregroundDecoration: _focus
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(color: c.accent, width: 1.5),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
