import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'online_contract.dart';
import 'online_format.dart';
import 'online_page.dart';
import 'online_parts.dart';
import 'online_popovers.dart';

enum _SidePop { none, source, blacklist }

/// 左栏 240：标题行、来源卡、浏览方式、最近搜索或收藏的子集 / 作者、底部黑名单。
class OnlineSidebar extends StatefulWidget {
  const OnlineSidebar({super.key});

  @override
  State<OnlineSidebar> createState() => _OnlineSidebarState();
}

class _OnlineSidebarState extends State<OnlineSidebar> {
  var _pop = _SidePop.none;
  UiPopoverAnchor? _anchor;

  /// 正在新建（''）或重命名（子集 id）的子集。
  String? _editing;
  String? _dropTarget;

  void _open(_SidePop pop, UiPopoverAnchor anchor) => setState(() {
    _pop = pop;
    _anchor = anchor;
  });

  void _close() => setState(() => _pop = _SidePop.none);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final status = data.status;
    final localFav = data.mode == OnlineMode.favorites && status.favoritesLocal;
    return UiPopover(
      anchor: _pop == _SidePop.none ? null : _anchor,
      onDismiss: _close,
      builder: (context) => _pop == _SidePop.source
          ? _SourcePopover(onClose: _close)
          : const _BlacklistPopover(),
      child: Container(
        key: const Key('online-sidebar'),
        width: 240,
        decoration: BoxDecoration(
          color: c.panel,
          border: Border(right: BorderSide(color: c.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    Text(
                      l10n.online_title,
                      style: UiText.sans(
                        14,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const Spacer(),
                    UiIconBox(
                      glyph: UiGlyphs.doubleLeft,
                      glyphSize: 16,
                      tooltip: l10n.online_collapseSidebar,
                      onTap: () => a.onSidebarChanged(false),
                    ),
                  ],
                ),
              ),
            ),
            Builder(
              builder: (context) => _SourceCard(
                status: status,
                onTap: () => _open(
                  _SidePop.source,
                  UiPopoverAnchor(
                    (context.findRenderObject()! as RenderBox).localToGlobal(
                      const Offset(10, 40),
                    ),
                  ),
                ),
              ),
            ),
            OnlineSectionTitle(children: [Text(l10n.online_sectionBrowse)]),
            _ModeList(data: data, actions: a),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: localFav
                      ? _favorites(context, data, a)
                      : data.mode == OnlineMode.favorites
                      ? const []
                      : _recent(context, data, a),
                ),
              ),
            ),
            Builder(
              builder: (context) => Container(
                key: const Key('online-blacklist'),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: _NavItem(
                  margin: EdgeInsets.zero,
                  glyph: UiGlyphs.ban,
                  label: l10n.online_blacklist,
                  trailing: Text(
                    l10n.online_blacklistCount(data.blacklist.tags.length),
                    style: UiText.sans(11.5, color: c.faint),
                  ),
                  onTap: () {
                    final box = context.findRenderObject()! as RenderBox;
                    _open(
                      _SidePop.blacklist,
                      UiPopoverAnchor(
                        box.localToGlobal(Offset(10, box.size.height - 56)),
                        alignBottom: true,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _recent(
    BuildContext context,
    OnlineViewData data,
    OnlineActions a,
  ) {
    final c = context.ui;
    final l10n = context.l10n;
    if (data.recent.isEmpty) return const [];
    return [
      OnlineSectionTitle(
        children: [
          Text(l10n.online_recentTitle),
          const Spacer(),
          UiPressable(
            onTap: a.onClearRecent,
            builder: (context, hover) => Text(
              l10n.online_recentClear,
              style: UiText.sans(11.5, color: hover ? c.ink : c.faint),
            ),
          ),
        ],
      ),
      for (final (i, r) in data.recent.indexed)
        _NavItem(
          key: Key('online-recent-$i'),
          height: 30,
          glyph: switch (r.kind) {
            OnlineRecentKind.work => UiGlyphs.search,
            OnlineRecentKind.prompt => UiGlyphs.spark,
            OnlineRecentKind.author => UiGlyphs.user,
          },
          glyphSize: 14,
          glyphColor: c.faint,
          label: r.text,
          labelStyle: UiText.mono(12, color: c.muted),
          onTap: () => a.onRecent(r),
        ),
    ];
  }

  List<Widget> _favorites(
    BuildContext context,
    OnlineViewData data,
    OnlineActions a,
  ) {
    final c = context.ui;
    final l10n = context.l10n;
    final fav = data.favorites ?? const OnlineFavorites();
    Widget count(int n) => Text('$n', style: UiText.mono(11.5, color: c.faint));
    Widget collection(String? id, String glyph, String name, int n) {
      final key = id ?? '*';
      final on = fav.authorId == null && fav.collectionId == id;
      final row = _editing == id && id != null && id.isNotEmpty
          ? _NameField(
              initial: name,
              onDone: (v) {
                setState(() => _editing = null);
                if (v != null && v != name) a.onRenameCollection(id, v);
              },
            )
          : _NavItem(
              key: Key('online-collection-$key'),
              glyph: glyph,
              glyphSize: 14,
              label: name,
              selected: on,
              drop: _dropTarget == key,
              trailing: count(n),
              onTap: () => a.onCollectionSelected(id),
              onSecondaryTap: id == null || id.isEmpty
                  ? null
                  : (pos) => OnlineScope.of(context).controller
                        .openMenu(UiPopoverAnchor(pos), [
                          OnlineMenuItem(
                            glyph: UiGlyphs.pencil,
                            label: l10n.online_rename,
                            onTap: () => setState(() => _editing = id),
                          ),
                          OnlineMenuItem(
                            glyph: UiGlyphs.trash,
                            label: l10n.online_deleteCollection,
                            danger: true,
                            onTap: () => a.onDeleteCollection(id),
                          ),
                        ]),
            );
      if (id == null) return row;
      return DragTarget<List<String>>(
        onWillAcceptWithDetails: (_) {
          setState(() => _dropTarget = key);
          return true;
        },
        onLeave: (_) => setState(() => _dropTarget = null),
        onAcceptWithDetails: (d) {
          setState(() => _dropTarget = null);
          a.onMoveToCollection(d.data, id);
        },
        builder: (context, _, _) => row,
      );
    }

    return [
      OnlineSectionTitle(
        children: [
          Text(l10n.online_collections),
          const Spacer(),
          UiPressable(
            onTap: () => setState(() => _editing = ''),
            builder: (context, hover) => Tooltip(
              message: l10n.online_newCollection,
              child: UiGlyph(
                UiGlyphs.plus,
                size: 14,
                color: hover ? c.ink : c.faint,
              ),
            ),
          ),
        ],
      ),
      collection(null, UiGlyphs.grid, l10n.online_all, fav.total),
      collection(
        OnlineFavorites.ungroupedId,
        UiGlyphs.folder,
        l10n.online_ungrouped,
        fav.ungrouped,
      ),
      for (final col in fav.collections)
        collection(col.id, UiGlyphs.folder, col.name, col.count),
      if (_editing == '')
        _NameField(
          initial: '',
          onDone: (v) {
            setState(() => _editing = null);
            if (v != null && v.isNotEmpty) a.onCreateCollection(v);
          },
        ),
      OnlineSectionTitle(
        children: [
          Text(l10n.online_favAuthors),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${fav.authors.length}',
              style: UiText.mono(11, color: c.faint),
            ),
          ),
        ],
      ),
      for (final au in fav.authors)
        _NavItem(
          key: Key('online-author-${au.id}'),
          height: 34,
          leading: OnlineAvatar(name: au.name, image: au.avatar, size: 22),
          label: au.name,
          selected: fav.authorId == au.id,
          trailing: count(au.count),
          onTap: () => a.onAuthorSelected(au.id),
        ),
      const SizedBox(height: 8),
    ];
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.status, required this.onTap});
  final OnlineSourceStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: UiPressable(
        onTap: onTap,
        builder: (context, hover) => Container(
          key: const Key('online-source-card'),
          padding: const EdgeInsets.fromLTRB(9, 8, 8, 8),
          decoration: BoxDecoration(
            color: hover ? c.hover : c.raised,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            spacing: 10,
            children: [
              OnlineSourceMark(status.source),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 19.6,
                      child: Text(
                        OnlineFormat.sourceName(status.source),
                        style: UiText.sans(
                          13.5,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 16.65,
                      child: Text(
                        sourceSubtitle(context, status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11.5, color: c.muted),
                      ),
                    ),
                  ],
                ),
              ),
              UiGlyph(UiGlyphs.chevronDown, size: 15, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 来源卡副标题：AI TAG / Safebooru 固定说明；Danbooru 写账号；Gelbooru 写 Key 状态。
String sourceSubtitle(BuildContext context, OnlineSourceStatus s) {
  final l10n = context.l10n;
  return switch (s.account) {
    OnlineAccountState.signedIn => l10n.online_srcSubSignedIn(
      s.accountName ?? '',
    ),
    OnlineAccountState.signedOut => l10n.online_signedOut,
    OnlineAccountState.keyConfigured => l10n.online_srcSubKeyOk,
    OnlineAccountState.keyInvalid => l10n.online_srcSubKeyInvalid,
    OnlineAccountState.keyMissing => l10n.online_srcSubKeyMissing,
    OnlineAccountState.none =>
      s.promptQuery ? l10n.online_srcSubAiTag : l10n.online_srcSubSafebooru,
  };
}

class _ModeList extends StatelessWidget {
  const _ModeList({required this.data, required this.actions});
  final OnlineViewData data;
  final OnlineActions actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final s = data.status;
    final ai = s.promptQuery;
    Widget item(
      OnlineMode mode,
      String glyph,
      String label, {
      bool enabled = true,
      String? reason,
      Widget? trailing,
    }) {
      final row = _NavItem(
        key: Key('online-mode-${mode.name}'),
        glyph: glyph,
        label: label,
        selected: data.mode == mode,
        disabled: !enabled,
        trailing:
            trailing ??
            (reason == null
                ? null
                : Text(reason, style: UiText.sans(11, color: c.faint))),
        onTap: enabled && data.mode != mode
            ? () => actions.onModeChanged(mode)
            : (enabled ? () {} : null),
      );
      return enabled || reason == null
          ? row
          : Tooltip(message: reason, child: row);
    }

    final favTrailing = s.favoritesLocal
        ? Text(
            '${data.favorites?.total ?? 0}',
            style: UiText.mono(11.5, color: c.faint),
          )
        : !s.favorites
        ? null
        : s.account == OnlineAccountState.signedOut
        ? UiMini(l10n.online_signedOut, tone: UiMiniTone.warn)
        : !s.favoritesWritable
        ? UiMini(l10n.online_readOnly)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        item(OnlineMode.search, UiGlyphs.search, l10n.online_modeSearch),
        item(
          OnlineMode.ranking,
          UiGlyphs.trophy,
          ai ? l10n.online_modeMonthly : l10n.online_modePopular,
          enabled: s.ranking,
          reason: s.ranking ? null : l10n.online_noRanking,
        ),
        item(
          OnlineMode.favorites,
          UiGlyphs.heartLib,
          ai ? l10n.online_modeMyFavorites : l10n.online_modeFavorites,
          enabled: s.favorites,
          reason: s.favorites ? null : l10n.online_noFavorites,
          trailing: favTrailing,
        ),
      ],
    );
  }
}

/// 左栏导航行：32 高、外边距 8、圆角 7、图标 15；选中控件底 + 加粗。
class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.label,
    this.glyph,
    this.glyphSize = 15,
    this.glyphColor,
    this.leading,
    this.labelStyle,
    this.trailing,
    this.selected = false,
    this.disabled = false,
    this.drop = false,
    this.height = 32,
    this.margin = const EdgeInsets.symmetric(horizontal: 8),
    this.onTap,
    this.onSecondaryTap,
  });

  final String label;
  final String? glyph;
  final double glyphSize;
  final Color? glyphColor;
  final Widget? leading;
  final TextStyle? labelStyle;
  final Widget? trailing;
  final bool selected;
  final bool disabled;

  /// 拖卡片悬停在这个子集上。
  final bool drop;
  final double height;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final fg = drop ? c.accent : (disabled ? c.faint : c.ink);
    return Padding(
      padding: margin,
      child: GestureDetector(
        onSecondaryTapUp: onSecondaryTap == null
            ? null
            : (d) => onSecondaryTap!(d.globalPosition),
        child: UiPressable(
          onTap: onTap,
          builder: (context, hover) => Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: drop
                  ? c.accent.withValues(alpha: .10)
                  : selected
                  ? c.control
                  : (hover && !disabled ? c.hover : null),
              borderRadius: BorderRadius.circular(7),
              border: drop ? Border.all(color: c.accent, width: 1.5) : null,
            ),
            child: Row(
              spacing: 9,
              children: [
                if (leading != null)
                  leading!
                else if (glyph != null)
                  UiGlyph(
                    glyph!,
                    size: glyphSize,
                    color: drop ? c.accent : (glyphColor ?? c.muted),
                  ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (labelStyle ?? UiText.sans(13, color: fg)).copyWith(
                      fontWeight: selected ? FontWeight.w600 : null,
                      color: drop ? c.accent : null,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 子集名输入（新建 / 重命名）：回车确认，Esc 或失焦取消。
class _NameField extends StatefulWidget {
  const _NameField({required this.initial, required this.onDone});
  final String initial;
  final ValueChanged<String?> onDone;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _ctrl = TextEditingController(text: widget.initial);
  final _focus = FocusNode();
  var _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish(null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _finish(String? v) {
    if (_done) return;
    _done = true;
    widget.onDone(v?.trim());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: c.accent),
        ),
        child: Row(
          spacing: 9,
          children: [
            UiGlyph(UiGlyphs.folder, size: 14, color: c.muted),
            Expanded(
              child: Focus(
                onKeyEvent: (_, e) {
                  if (e is KeyDownEvent &&
                      e.logicalKey == LogicalKeyboardKey.escape) {
                    _finish(null);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  key: const Key('online-collection-name'),
                  controller: _ctrl,
                  focusNode: _focus,
                  style: UiText.sans(13, color: c.ink),
                  cursorColor: c.accent,
                  cursorHeight: 15,
                  decoration: uiBareDecoration(
                    hintText: context.l10n.online_collectionNameHint,
                    hintStyle: UiText.sans(13, color: c.faint),
                  ),
                  onSubmitted: _finish,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// “换来源”浮层：330 宽，每行写清这个来源能做什么和账号状态。
class _SourcePopover extends StatelessWidget {
  const _SourcePopover({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    return UiPopoverSurface(
      key: const Key('online-source-popover'),
      width: 330,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnlinePopHeader(children: [Text(l10n.online_switchSource)]),
          for (final s in data.sources)
            UiPressable(
              key: Key('online-source-${s.source.name}'),
              onTap: () {
                onClose();
                if (s.source != data.source) {
                  scope.actions.onSourceChanged(s.source);
                }
              },
              builder: (context, hover) => Container(
                color: s.source == data.source || hover ? c.control : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    OnlineSourceMark(s.source),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Row(
                            spacing: 6,
                            children: [
                              Text(
                                OnlineFormat.sourceName(s.source),
                                style: UiText.sans(
                                  13,
                                  weight: FontWeight.w700,
                                  color: c.ink,
                                ),
                              ),
                              _accountMini(context, s),
                            ],
                          ),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final cap in _caps(context, s)) UiMini(cap),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (s.source == data.source)
                      UiGlyph(
                        UiGlyphs.check,
                        size: 16,
                        strokeWidth: 2.4,
                        color: c.accent,
                      ),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: OnlineNote(l10n.online_sourceMemory),
          ),
        ],
      ),
    );
  }

  static Widget _accountMini(BuildContext context, OnlineSourceStatus s) {
    final l10n = context.l10n;
    return switch (s.account) {
      OnlineAccountState.none => UiMini(
        l10n.online_acctNone,
        tone: s.promptQuery ? UiMiniTone.ok : UiMiniTone.plain,
      ),
      OnlineAccountState.signedIn => UiMini(
        l10n.online_acctSignedIn,
        tone: UiMiniTone.ok,
      ),
      OnlineAccountState.signedOut => UiMini(
        l10n.online_signedOut,
        tone: UiMiniTone.warn,
      ),
      OnlineAccountState.keyConfigured => UiMini(
        l10n.online_acctKeyOk,
        tone: UiMiniTone.ok,
      ),
      OnlineAccountState.keyInvalid => UiMini(
        l10n.online_acctKeyInvalid,
        tone: UiMiniTone.warn,
      ),
      OnlineAccountState.keyMissing => UiMini(l10n.online_acctKeyMissing),
    };
  }

  static List<String> _caps(BuildContext context, OnlineSourceStatus s) {
    final l10n = context.l10n;
    return [
      s.promptQuery ? l10n.online_capPromptSearch : l10n.online_capTagSearch,
      if (s.ranking)
        s.promptQuery ? l10n.online_capMonthly : l10n.online_capRankings,
      if (s.favoritesLocal)
        l10n.online_capLocalFav
      else if (s.favorites)
        s.favoritesWritable
            ? l10n.online_capSiteFav
            : l10n.online_capReadOnlyFav,
      if (s.multiMedia) ...[l10n.online_capMultiMedia, l10n.online_capParams],
      if (s.ratings) l10n.online_capRatings,
      if (!s.ratings && !s.promptQuery) l10n.online_capSfwOnly,
      if (!s.ranking) l10n.online_noRanking,
    ];
  }
}

/// 黑名单浮层：360 宽。加 / 删标签；登录 Danbooru 时有账号黑名单同步开关。
class _BlacklistPopover extends StatefulWidget {
  const _BlacklistPopover();

  @override
  State<_BlacklistPopover> createState() => _BlacklistPopoverState();
}

class _BlacklistPopoverState extends State<_BlacklistPopover> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final b = scope.data.blacklist;
    final a = scope.actions;
    final danbooru = scope.data.sources
        .where((s) => s.source == OnlineSource.danbooru)
        .firstOrNull;
    return UiPopoverSurface(
      key: const Key('online-blacklist-popover'),
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnlinePopHeader(
            children: [
              UiGlyph(UiGlyphs.ban, size: 15, color: c.ink),
              Text(l10n.online_blacklist),
              const Spacer(),
              Text(
                l10n.online_blacklistDesc,
                style: UiText.sans(12, color: c.muted),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Container(
                  height: 32,
                  padding: const EdgeInsets.only(left: 11, right: 6),
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      UiGlyph(UiGlyphs.plus, size: 14, color: c.muted),
                      Expanded(
                        child: TextField(
                          key: const Key('online-blacklist-input'),
                          controller: _ctrl,
                          autofocus: true,
                          style: UiText.mono(12.5, color: c.ink),
                          cursorColor: c.accent,
                          cursorHeight: 15,
                          decoration: uiBareDecoration(
                            hintText: l10n.online_blacklistAddHint,
                            hintStyle: UiText.sans(13, color: c.faint),
                          ),
                          onSubmitted: (v) {
                            final t = v.trim();
                            if (t.isNotEmpty) a.onBlacklistAdd(t);
                            _ctrl.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (b.tags.isEmpty)
                  Text(
                    l10n.online_blacklistEmpty,
                    style: UiText.sans(12, color: c.faint),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in b.tags)
                        OnlineToken(
                          key: Key('online-blacklist-tag-$t'),
                          text: t,
                          onRemove: () => a.onBlacklistRemove(t),
                        ),
                    ],
                  ),
                Container(height: 1, color: c.line),
                if (danbooru?.account == OnlineAccountState.signedIn)
                  UiPressable(
                    key: const Key('online-blacklist-sync'),
                    onTap: () => a.onDanbooruSyncChanged(!b.danbooruSync),
                    builder: (context, _) => Row(
                      spacing: 8,
                      children: [
                        const OnlineSourceMark(OnlineSource.danbooru, size: 22),
                        Expanded(
                          child: Text(
                            l10n.online_blacklistSync(b.danbooruCount),
                            style: UiText.sans(12, color: c.ink),
                          ),
                        ),
                        UiSwitch(value: b.danbooruSync, width: 30, height: 18),
                      ],
                    ),
                  ),
                OnlineNote(l10n.online_blacklistScope),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
