import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'online_contract.dart';
import 'online_format.dart';
import 'online_page.dart';
import 'online_parts.dart';
import 'online_popovers.dart';

/// 工具栏 62：搜索框（弹性宽）、卡片大小、多选、刷新、检查器开关。
/// 没有检查器时自己给窗口按钮让位（右侧 150）。
class OnlineToolbar extends StatelessWidget {
  const OnlineToolbar({
    super.key,
    required this.inspectorShown,
    required this.sidebarShown,
    required this.login,
  });

  final bool inspectorShown;
  final bool sidebarShown;

  /// 收藏未登录：只留搜索框。
  final bool login;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final s = data.status;
    final chrome = WindowChromeScope.activeOf(context);
    final booruRank = data.mode == OnlineMode.ranking && !s.promptQuery;
    final fav = data.mode == OnlineMode.favorites;

    final children = <Widget>[
      if (!sidebarShown)
        UiIconBox(
          glyph: UiGlyphs.doubleRight,
          glyphSize: 16,
          tooltip: l10n.online_expandSidebar,
          onTap: () => a.onSidebarChanged(true),
        ),
      if (booruRank && !ctrl.picking) ...[
        const _RankScaleNav(),
        const Spacer(),
      ] else
        const Expanded(child: OnlineSearchBox()),
      if (login)
        ...const <Widget>[]
      else if (ctrl.picking)
        UiBtn(
          key: const Key('online-multi-done'),
          tone: UiBtnTone.accent,
          onTap: () => ctrl.setPicking(false),
          children: [
            const UiGlyph(UiGlyphs.check, size: 14, strokeWidth: 2.4),
            Text(l10n.online_doneMultiSelect),
          ],
        )
      else ...[
        UiSeg<OnlineCardSize>(
          key: const Key('online-card-size'),
          glyphSize: 16,
          values: OnlineCardSize.values,
          selected: data.cardSize,
          onChanged: a.onCardSizeChanged,
          glyphOf: (v) => switch (v) {
            OnlineCardSize.small => UiGlyphs.masonrySmall,
            OnlineCardSize.medium => UiGlyphs.masonryMedium,
            OnlineCardSize.large => UiGlyphs.masonryLarge,
          },
          tooltipOf: (v) => switch (v) {
            OnlineCardSize.small => l10n.online_sizeSmall,
            OnlineCardSize.medium => l10n.online_sizeMedium,
            OnlineCardSize.large => l10n.online_sizeLarge,
          },
        ),
        UiBtn(
          key: const Key('online-multi'),
          onTap: () => ctrl.setPicking(true),
          children: [
            const UiGlyph(UiGlyphs.select, size: 14),
            Text(l10n.online_multiSelect),
          ],
        ),
        if (!fav && !booruRank)
          UiIconBox(
            key: const Key('online-refresh'),
            glyph: UiGlyphs.refresh,
            tone: UiIconBoxTone.bordered,
            tooltip: l10n.online_refresh,
            onTap: a.onRefresh,
          ),
        UiIconBox(
          key: const Key('online-inspector-toggle'),
          glyph: UiGlyphs.panel,
          tone: data.inspectorOpen ? UiIconBoxTone.on : UiIconBoxTone.plain,
          tooltip: l10n.online_inspector,
          onTap: () => a.onInspectorChanged(!data.inspectorOpen),
        ),
      ],
    ];
    final reserve = !inspectorShown;
    return WindowHeader(
      key: const Key('online-toolbar'),
      enabled: reserve,
      minimumInlineWidth: 0,
      inlineDragWidth: 12,
      dragBackground: true,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: SizedBox(
        height: 61,
        child: Padding(
          padding: EdgeInsets.only(left: 18, right: reserve && chrome ? 0 : 16),
          child: Row(spacing: 8, children: children),
        ),
      ),
    );
  }
}

/// Danbooru 系热门的工具栏左半：日 / 周 / 月 + 日期翻页 + 今天。
class _RankScaleNav extends StatelessWidget {
  const _RankScaleNav();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final r = scope.data.ranking;
    final a = scope.actions;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = r.date ?? today;
    final step = switch (r.scale) {
      OnlineRankScale.day => const Duration(days: 1),
      OnlineRankScale.week => const Duration(days: 7),
      OnlineRankScale.month => const Duration(days: 30),
    };
    final canNext = date.add(step).isBefore(today.add(const Duration(days: 1)));
    return Row(
      spacing: 8,
      children: [
        UiSeg<OnlineRankScale>(
          key: const Key('online-rank-scale'),
          small: false,
          values: OnlineRankScale.values,
          selected: r.scale,
          onChanged: a.onRankScaleChanged,
          labelOf: (v) => switch (v) {
            OnlineRankScale.day => l10n.online_rankDay,
            OnlineRankScale.week => l10n.online_rankWeek,
            OnlineRankScale.month => l10n.online_rankMonth,
          },
        ),
        Container(
          key: const Key('online-rank-date'),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: c.raised,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            spacing: 2,
            children: [
              UiIconBox(
                glyph: UiGlyphs.chevronLeft,
                size: 26,
                tooltip: l10n.online_previous,
                onTap: () => a.onRankDateChanged(date.subtract(step)),
              ),
              UiPressable(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2005),
                    lastDate: today,
                  );
                  if (picked != null) a.onRankDateChanged(picked);
                },
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    OnlineFormat.date(date),
                    style: UiText.mono(
                      12,
                      weight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
              UiIconBox(
                glyph: UiGlyphs.chevronRight,
                size: 26,
                tooltip: l10n.online_next,
                onTap: canNext
                    ? () => a.onRankDateChanged(date.add(step))
                    : null,
              ),
            ],
          ),
        ),
        UiBtn(
          size: UiBtnSize.small,
          tone: UiBtnTone.ghost,
          onTap: () => a.onRankDateChanged(today),
          children: [Text(l10n.online_today)],
        ),
      ],
    );
  }
}

/// 搜索框（36 高、圆角 9）：AI TAG 是作品 + Prompt 两段；Danbooru 系是标签块 + 模糊匹配；
/// 收藏是“在收藏里找”。Ctrl+F 聚焦。
class OnlineSearchBox extends StatefulWidget {
  const OnlineSearchBox({super.key});

  @override
  State<OnlineSearchBox> createState() => _OnlineSearchBoxState();
}

class _OnlineSearchBoxState extends State<OnlineSearchBox> {
  final _work = TextEditingController();
  final _prompt = TextEditingController();
  final _tag = TextEditingController();
  final _promptFocus = FocusNode();
  var _tags = <String>[];
  OnlineQuery? _synced;
  var _focused = false;

  final _link = LayerLink();
  final _portal = OverlayPortalController();
  List<OnlineSuggestion> _suggestions = const [];
  var _active = 0;
  TextEditingController? _suggestFor;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    for (final c in [_work, _prompt, _tag]) {
      c.addListener(() => _onEdit(c));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = OnlineScope.of(context);
    final focus = scope.controller.searchFocus;
    if (!_listening.contains(focus)) {
      _listening.add(focus);
      focus.addListener(_onFocus);
    }
    if (!_listening.contains(_promptFocus)) {
      _listening.add(_promptFocus);
      _promptFocus.addListener(_onFocus);
    }
    _sync(scope.data);
  }

  final _listening = <FocusNode>{};

  void _onFocus() {
    final f = OnlineScope.of(context).controller.searchFocus;
    final now = f.hasFocus || _promptFocus.hasFocus;
    if (now != _focused) setState(() => _focused = now);
    if (!now) _hideSuggest();
  }

  void _sync(OnlineViewData data) {
    final q = data.query;
    if (_synced == q) return;
    final fav = data.mode == OnlineMode.favorites;
    _set(_work, fav ? q.favoritesFilter : q.work);
    _set(_prompt, q.prompt);
    _tags = [...q.tags];
    _synced = q;
  }

  // 外部数据回填输入框（构建期间）时不当作用户输入：不提交、不碰补全浮层。
  var _syncing = false;

  void _set(TextEditingController c, String v) {
    if (c.text == v) return;
    _syncing = true;
    c.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
    _syncing = false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final f in _listening) {
      f.removeListener(_onFocus);
    }
    _work.dispose();
    _prompt.dispose();
    _tag.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  OnlineScope get _scope => OnlineScope.of(context);

  void _submit() {
    final d = _scope.data;
    _hideSuggest();
    final q = d.query;
    final next = d.mode == OnlineMode.favorites && d.status.favoritesLocal
        ? OnlineQuery(
            work: q.work,
            prompt: q.prompt,
            tags: q.tags,
            fuzzy: q.fuzzy,
            favoritesFilter: _work.text.trim(),
          )
        : d.status.promptQuery
        ? OnlineQuery(
            work: _work.text.trim(),
            prompt: _prompt.text.trim(),
            fuzzy: q.fuzzy,
          )
        : OnlineQuery(tags: [..._tags], fuzzy: q.fuzzy);
    _synced = next;
    _scope.actions.onSearch(next);
  }

  void _onEdit(TextEditingController c) {
    if (_syncing) return;
    final d = _scope.data;
    if (c == _work &&
        d.mode == OnlineMode.favorites &&
        d.status.favoritesLocal) {
      if (_work.text.trim() != d.query.favoritesFilter) _submit();
      return;
    }
    if (c == _tag && _tag.text.endsWith(' ')) {
      final t = _tag.text.trim();
      _tag.clear();
      if (t.isNotEmpty) setState(() => _tags.add(t));
      _hideSuggest();
      return;
    }
    _debounce?.cancel();
    final frag = _fragment(c);
    if (frag.length < 2) {
      _hideSuggest();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 160), () async {
      final list = await _scope.actions.onSuggest(frag, prompt: c == _prompt);
      if (!mounted || _fragment(c) != frag) return;
      setState(() {
        _suggestions = list.take(8).toList();
        _active = 0;
        _suggestFor = c;
      });
      if (_suggestions.isEmpty) {
        _portal.hide();
      } else {
        _portal.show();
      }
    });
  }

  String _fragment(TextEditingController c) {
    final t = c.text.substring(
      0,
      c.selection.baseOffset < 0 ? c.text.length : c.selection.baseOffset,
    );
    final parts = t.split(c == _prompt ? ',' : RegExp(r'\s'));
    return parts.last.trim().replaceFirst(RegExp(r'^-'), '');
  }

  void _hideSuggest() {
    _debounce?.cancel();
    if (_portal.isShowing) _portal.hide();
    _suggestions = const [];
  }

  void _accept(OnlineSuggestion s) {
    final c = _suggestFor;
    if (c == null) return;
    if (c == _tag) {
      final neg = _tag.text.trimLeft().startsWith('-');
      setState(() => _tags.add('${neg ? '-' : ''}${s.tag}'));
      _tag.clear();
    } else {
      final prompt = c == _prompt;
      final cut = c.selection.baseOffset < 0
          ? c.text.length
          : c.selection.baseOffset;
      final head = c.text.substring(0, cut);
      final sep = prompt ? ',' : ' ';
      final start = head.lastIndexOf(sep) + 1;
      final lead = prompt && start > 0 ? ' ' : '';
      final text =
          '${head.substring(0, start)}$lead${s.tag}${prompt ? ', ' : ' '}';
      c.value = TextEditingValue(
        text: text + c.text.substring(cut),
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    _hideSuggest();
    setState(() {});
  }

  KeyEventResult _keys(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    if (_portal.isShowing && _suggestions.isNotEmpty) {
      if (k == LogicalKeyboardKey.arrowDown ||
          k == LogicalKeyboardKey.arrowUp) {
        setState(() {
          final n = _suggestions.length;
          _active =
              (_active + (k == LogicalKeyboardKey.arrowDown ? 1 : -1)) % n;
          if (_active < 0) _active += n;
        });
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.tab || k == LogicalKeyboardKey.enter) {
        _accept(_suggestions[_active]);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.escape) {
        _hideSuggest();
        setState(() {});
        return KeyEventResult.handled;
      }
    }
    if (k == LogicalKeyboardKey.backspace &&
        node == _scope.controller.searchFocus &&
        _tag.text.isEmpty &&
        _tags.isNotEmpty &&
        !_scope.data.status.promptQuery) {
      setState(() => _tags.removeLast());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _box(context, box.maxWidth));

  Widget _box(BuildContext context, double width) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    _sync(scope.data);
    final data = scope.data;
    final s = data.status;
    final focus = scope.controller.searchFocus;
    final fav = data.mode == OnlineMode.favorites;
    final localFav = fav && s.favoritesLocal;

    TextStyle hint([double size = 13]) => UiText.sans(size, color: c.faint);
    Widget field(
      TextEditingController ctrl,
      FocusNode node,
      String hintText, {
      bool mono = false,
      Key? key,
    }) => Focus(
      onKeyEvent: _keys,
      skipTraversal: true,
      child: TextField(
        key: key,
        controller: ctrl,
        focusNode: node,
        maxLines: 1,
        style: mono
            ? UiText.mono(12, color: c.ink, height: 1.45)
            : UiText.sans(13, color: c.ink),
        cursorColor: c.accent,
        cursorHeight: 16,
        decoration: uiBareDecoration(hintText: hintText, hintStyle: hint()),
        onSubmitted: (_) {
          if (ctrl == _tag && _tag.text.trim().isNotEmpty) {
            setState(() => _tags.add(_tag.text.trim()));
            _tag.clear();
          }
          _submit();
        },
      ),
    );

    final hasText =
        _work.text.isNotEmpty || _prompt.text.isNotEmpty || _tags.isNotEmpty;
    const keys = UiKeycaps(['Ctrl', 'F'], gap: 4);
    // 左右内边距 17、搜索图标 16、间距、模糊匹配开关约 92、按键约 46、输入框至少 120。
    final tokenRoom = width - 17 - 16 - 8 * 4 - (s.fuzzy ? 92 : 0) - 46 - 120;
    final List<Widget> inner;
    if (localFav) {
      inner = [
        UiGlyph(UiGlyphs.search, size: 16, color: c.muted),
        Expanded(
          child: field(
            _work,
            focus,
            l10n.online_searchFavHint,
            key: const Key('online-search-work'),
          ),
        ),
        if (width >= 180) keys,
      ];
    } else if (s.promptQuery) {
      inner = [
        UiGlyph(UiGlyphs.search, size: 16, color: c.muted),
        Expanded(
          child: field(
            _work,
            focus,
            l10n.online_searchWorkHint,
            key: const Key('online-search-work'),
          ),
        ),
        const UiVSep(),
        UiGlyph(
          UiGlyphs.spark,
          size: 15,
          color: _prompt.text.isNotEmpty ? c.accent : c.faint,
        ),
        Expanded(
          child: field(
            _prompt,
            _promptFocus,
            l10n.online_searchPromptHint,
            mono: _prompt.text.isNotEmpty,
            key: const Key('online-search-prompt'),
          ),
        ),
        if (hasText)
          UiPressable(
            onTap: () {
              _work.clear();
              _prompt.clear();
              _submit();
            },
            builder: (context, hover) => Tooltip(
              message: l10n.online_clearSearch,
              child: UiGlyph(
                UiGlyphs.close,
                size: 14,
                color: hover ? c.ink : c.faint,
              ),
            ),
          ),
        if (width >= 180) keys,
      ];
    } else {
      inner = [
        UiGlyph(UiGlyphs.search, size: 16, color: c.muted),
        if (_tags.isNotEmpty)
          // 标签块最多占到只给输入框留 120；再多就横向滚动，停在最后一个。
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: math.max(0, tokenRoom)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                spacing: 8,
                children: [
                  for (final (i, t) in _tags.indexed)
                    OnlineToken(
                      key: Key('online-tag-$i'),
                      text: t,
                      onRemove: () {
                        setState(() => _tags.removeAt(i));
                        _submit();
                      },
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: field(
            _tag,
            focus,
            l10n.online_searchTagHint,
            key: const Key('online-search-tags'),
          ),
        ),
        if (s.fuzzy)
          UiPressable(
            key: const Key('online-fuzzy'),
            onTap: () => scope.actions.onSearch(
              OnlineQuery(tags: [..._tags], fuzzy: !data.query.fuzzy),
            ),
            builder: (context, _) => Row(
              spacing: 6,
              children: [
                Text(l10n.online_fuzzy, style: UiText.sans(12, color: c.muted)),
                UiSwitch(value: data.query.fuzzy, width: 30, height: 18),
              ],
            ),
          ),
        if (width >= 180) keys,
      ];
    }

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          offset: const Offset(0, 6),
          child: _SuggestList(
            items: _suggestions,
            active: _active,
            onPick: _accept,
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: Container(
          key: const Key('online-search'),
          height: 36,
          padding: const EdgeInsets.only(left: 11, right: 6),
          decoration: BoxDecoration(
            color: _focused ? c.raised : c.control,
            borderRadius: BorderRadius.circular(9),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: .14),
                      spreadRadius: 4,
                    ),
                    BoxShadow(color: c.accent, spreadRadius: 1),
                  ]
                : null,
          ),
          child: Row(spacing: 8, children: inner),
        ),
      ),
    );
  }
}

class _SuggestList extends StatelessWidget {
  const _SuggestList({
    required this.items,
    required this.active,
    required this.onPick,
  });
  final List<OnlineSuggestion> items;
  final int active;
  final ValueChanged<OnlineSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPopoverSurface(
      key: const Key('online-suggest'),
      width: 340,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, s) in items.indexed)
            UiPressable(
              onTap: () => onPick(s),
              builder: (context, hover) => Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: i == active || hover ? c.control : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Text(s.tag, style: UiText.mono(12.5, color: c.ink)),
                    if (s.translation != null)
                      Expanded(
                        child: Text(
                          s.translation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(12, color: c.muted),
                        ),
                      )
                    else
                      const Spacer(),
                    if (s.count != null)
                      Text(
                        OnlineFormat.count(s.count!),
                        style: UiText.mono(11, color: c.faint),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _RowPop { none, time, archive, jump, date }

/// 筛选行 46（只看一个作者时是 76 的作者头部）。
class OnlineFilterRow extends StatefulWidget {
  const OnlineFilterRow({super.key});

  @override
  State<OnlineFilterRow> createState() => _OnlineFilterRowState();
}

class _OnlineFilterRowState extends State<OnlineFilterRow> {
  var _pop = _RowPop.none;
  UiPopoverAnchor? _anchor;

  void _open(BuildContext ctx, _RowPop pop, {bool right = false}) {
    final box = ctx.findRenderObject()! as RenderBox;
    setState(() {
      _pop = pop;
      _anchor = UiPopoverAnchor(
        box.localToGlobal(
          right
              ? box.size.bottomRight(const Offset(-200, 6))
              : box.size.bottomLeft(const Offset(0, 6)),
        ),
      );
    });
  }

  void _close() => setState(() => _pop = _RowPop.none);

  @override
  Widget build(BuildContext context) {
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final fav = data.favorites;
    final author =
        data.mode == OnlineMode.favorites && data.status.favoritesLocal
        ? fav?.author
        : null;
    return UiPopover(
      anchor: _pop == _RowPop.none ? null : _anchor,
      onDismiss: _close,
      builder: _popover,
      child: author != null
          ? _AuthorHeader(author: author)
          : SizedBox(
              key: const Key('online-filter-row'),
              height: 46,
              child: Padding(
                padding: const EdgeInsets.only(left: 18, right: 16),
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: box.maxWidth),
                      child: IntrinsicWidth(
                        child: Row(spacing: 8, children: _children(context)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _popover(BuildContext context) {
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    switch (_pop) {
      case _RowPop.time:
        return OnlineMenu(
          width: 180,
          onClose: _close,
          items: [
            for (final id in data.filters.timeRanges)
              OnlineMenuItem(
                label: OnlineFormat.timeRange(context, id),
                checked: id == data.filters.timeRange,
                onTap: () => a.onTimeRangeChanged(id),
              ),
          ],
        );
      case _RowPop.archive:
        return OnlineMenu(
          width: 160,
          onClose: _close,
          items: [
            for (final m in data.ranking.months.skip(4))
              OnlineMenuItem(
                label: m,
                checked: m == data.ranking.period,
                onTap: () => a.onRankPeriodChanged(m),
              ),
          ],
        );
      case _RowPop.jump:
        return OnlineJumpPopover(
          initial: data.list.pages + 1,
          onJump: (p) {
            _close();
            a.onJumpToPage(p);
          },
        );
      case _RowPop.date:
        return OnlineMenu(
          width: 180,
          onClose: _close,
          items: [
            OnlineMenuItem(
              label: l10n.online_dateRange,
              glyph: UiGlyphs.calendar,
              onTap: () async {
                final r = await showDateRangePicker(
                  context: this.context,
                  firstDate: DateTime(2005),
                  lastDate: DateTime.now(),
                  initialDateRange: data.filters.dateRange,
                );
                if (r != null) a.onDateRangeChanged(r);
              },
            ),
            if (data.filters.dateRange != null)
              OnlineMenuItem(
                label: l10n.online_clearDateRange,
                glyph: UiGlyphs.close,
                onTap: () => a.onDateRangeChanged(null),
              ),
          ],
        );
      case _RowPop.none:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _children(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final s = data.status;
    final f = data.filters;
    final list = data.list;
    // 计数靠右、放不下时省略（窄窗口下先让它让位）。
    final count = Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          data.mode == OnlineMode.ranking && s.promptQuery
              ? l10n.online_rankLoaded(list.items.length)
              : l10n.online_loaded(list.items.length, list.pages),
          key: const Key('online-loaded'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiText.mono(12, color: c.faint),
        ),
      ),
    );
    final jump = Builder(
      builder: (ctx) => UiBtn(
        key: const Key('online-jump'),
        size: UiBtnSize.small,
        tone: UiBtnTone.ghost,
        onTap: () => _open(ctx, _RowPop.jump, right: true),
        children: [Text(l10n.online_jumpToPage)],
      ),
    );
    final naiChip = UiFilterChip(
      key: const Key('online-nai-only'),
      label: l10n.online_naiOnly,
      selected: f.naiOnly,
      showCheck: true,
      onTap: () => a.onNaiOnlyChanged(!f.naiOnly),
    );
    final back = data.canReturn
        ? [
            UiBtn(
              key: const Key('online-return'),
              size: UiBtnSize.small,
              tone: UiBtnTone.ghost,
              onTap: a.onReturn,
              children: [
                const UiGlyph(UiGlyphs.chevronLeft, size: 13),
                Text(l10n.online_returnPrev),
              ],
            ),
          ]
        : const <Widget>[];

    if (data.mode == OnlineMode.favorites) {
      if (s.favoritesLocal) {
        final fav = data.favorites ?? const OnlineFavorites();
        final name = switch (fav.collectionId) {
          null => l10n.online_favAll,
          OnlineFavorites.ungroupedId => l10n.online_ungrouped,
          final id =>
            fav.collections.where((x) => x.id == id).firstOrNull?.name ?? '',
        };
        return [
          Text(
            name,
            style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
          ),
          Text(
            l10n.online_countImages(list.items.length),
            key: const Key('online-loaded'),
            style: UiText.mono(12, color: c.faint),
          ),
          const Spacer(),
          UiDropChip(
            key: const Key('online-sort'),
            prefix: l10n.online_sort,
            label: l10n.online_sortFavTime,
          ),
        ];
      }
      return [
        if (!s.favoritesWritable)
          Expanded(child: OnlineNote(l10n.online_readOnlyNote)),
        count,
      ];
    }

    if (s.promptQuery) {
      if (data.mode == OnlineMode.ranking) {
        final months = data.ranking.months;
        final archived = months.skip(4).contains(data.ranking.period);
        return [
          Row(
            key: const Key('online-rank-periods'),
            spacing: 6,
            children: [
              UiFilterChip(
                label: l10n.online_rankCurrent,
                selected: data.ranking.period == 'current',
                onTap: () => a.onRankPeriodChanged('current'),
              ),
              for (final m in months.take(4))
                UiFilterChip(
                  label: m,
                  selected: data.ranking.period == m,
                  onTap: () => a.onRankPeriodChanged(m),
                ),
              if (months.length > 4)
                Builder(
                  builder: (ctx) => UiDropChip(
                    label: archived
                        ? data.ranking.period
                        : l10n.online_timeOlder,
                    onTap: () => _open(ctx, _RowPop.archive),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: UiVSep(),
          ),
          naiChip,
          count,
          ...back,
        ];
      }
      return [
        naiChip,
        Row(
          spacing: 6,
          children: [
            Text(l10n.online_model, style: UiText.sans(12, color: c.muted)),
            UiSeg<OnlineModel?>(
              key: const Key('online-model'),
              values: const [null, ...OnlineModel.values],
              selected: f.model,
              onChanged: a.onModelChanged,
              labelOf: (m) =>
                  m == null ? l10n.online_modelAll : OnlineFormat.model(m),
            ),
          ],
        ),
        Builder(
          builder: (ctx) => UiDropChip(
            key: const Key('online-time-range'),
            glyph: UiGlyphs.clock,
            label: OnlineFormat.timeRange(context, f.timeRange),
            onTap: () => _open(ctx, _RowPop.time),
          ),
        ),
        count,
        ...back,
        jump,
      ];
    }

    final ratings = s.ratings
        ? [
            Text(
              l10n.online_ratingLabel,
              style: UiText.sans(12, color: c.muted),
            ),
            for (final r in OnlineRating.values)
              UiFilterChip(
                key: Key('online-rating-${r.name}'),
                label: OnlineFormat.ratingLabel(context, r),
                selected: f.ratings.contains(r),
                padding: const EdgeInsets.only(left: 5, right: 9),
                gap: 5,
                leading: OnlineRatingBadge(r),
                onTap: () {
                  final next = {...f.ratings};
                  if (!next.remove(r)) next.add(r);
                  if (next.isNotEmpty) a.onRatingsChanged(next);
                },
              ),
          ]
        : const <Widget>[];
    if (data.mode == OnlineMode.ranking) {
      return [...ratings, count, jump];
    }
    final range = f.dateRange;
    return [
      ...ratings,
      if (s.ratings && s.dateRange)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: UiVSep(),
        ),
      if (s.dateRange)
        Builder(
          builder: (ctx) => UiDropChip(
            key: const Key('online-date-range'),
            glyph: UiGlyphs.calendar,
            label: range == null
                ? l10n.online_dateRange
                : '${OnlineFormat.date(range.start)} – ${OnlineFormat.date(range.end)}',
            onTap: () => _open(ctx, _RowPop.date),
          ),
        ),
      count,
      jump,
    ];
  }
}

/// 只看一个收藏作者时的作者头部：76 高。
class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({required this.author});
  final OnlineFavoriteAuthor author;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final a = OnlineScope.of(context).actions;
    return Container(
      key: const Key('online-author-header'),
      height: 76,
      padding: const EdgeInsets.only(left: 18, right: 16),
      child: Row(
        spacing: 12,
        children: [
          OnlineAvatar(name: author.name, image: author.avatar, size: 48),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
                ),
                Text(
                  l10n.online_authorSaved(
                    author.count,
                    author.savedAt == null
                        ? '—'
                        : OnlineFormat.date(author.savedAt!),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: c.muted),
                ),
              ],
            ),
          ),
          UiBtn(
            key: const Key('online-author-works'),
            onTap: () => a.onAuthorWorks(author.id),
            children: [
              const UiGlyph(UiGlyphs.search, size: 14),
              Text(l10n.online_authorAllWorks),
            ],
          ),
          UiBtn(
            key: const Key('online-author-unfav'),
            onTap: () => a.onUnfavoriteAuthor(author.id),
            children: [
              const UiGlyph(UiGlyphs.close, size: 14),
              Text(l10n.online_unfavAuthor),
            ],
          ),
        ],
      ),
    );
  }
}
