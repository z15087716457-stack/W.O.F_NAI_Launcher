import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_create.dart';
import 'settings_format.dart';
import 'settings_intel.dart';
import 'settings_kit.dart';
import 'settings_models.dart';
import 'settings_overview.dart';
import 'settings_personal.dart';
import 'settings_scope.dart';
import 'settings_search.dart';
import 'settings_system.dart';

/// 设置页（新界面）。只吃 [SettingsViewData]、只调 [SettingsActions]，见 `settings_contract.dart`。
///
/// 左目录 248（搜索、6 组 17 页、版本）+ 右主区（顶栏面包屑与本页操作、页面、底部“已保存 · 撤销”）。
/// 界面自己管：搜索词与结果选择、搜索跳转后的高亮、确认框、Agent 指令的未保存保护、底部提示的显示时长。
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.data,
    required this.actions,
    this.initialQuery = '',
  });

  final SettingsViewData data;
  final SettingsActions actions;

  /// 打开时就在搜索（例如从命令面板“搜索设置”进来）。
  final String initialQuery;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _Confirm {
  const _Confirm(
    this.title,
    this.body,
    this.confirm,
    this.danger,
    this.onConfirm,
  );
  final String title;
  final String body;
  final String confirm;
  final bool danger;
  final VoidCallback onConfirm;
}

class _SettingsPageState extends State<SettingsPage> {
  late var _query = widget.initialQuery;
  String? _highlight;
  Timer? _highlightTimer;
  _Confirm? _confirm;
  var _dirty = false;
  SettingsChange? _toast;
  Timer? _toastTimer;
  late final _searchFocus = FocusNode(
    debugLabel: 'settings-search',
    onKeyEvent: _onSearchKey,
  );
  var _sel = 0;
  var _hits = const <SettingsHit>[];
  final _rootFocus = FocusNode(debugLabel: 'settings');

  @override
  void initState() {
    super.initState();
    final c = widget.data.lastChange;
    if (c != null && widget.data.now.difference(c.at).inSeconds.abs() < 10) {
      _showToast(c);
    }
  }

  @override
  void didUpdateWidget(covariant SettingsPage old) {
    super.didUpdateWidget(old);
    final c = widget.data.lastChange;
    if (c != null && c.id != old.data.lastChange?.id) _showToast(c);
    if (widget.data.page != old.data.page) _dirty = false;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _highlightTimer?.cancel();
    _searchFocus.dispose();
    _rootFocus.dispose();
    super.dispose();
  }

  void _showToast(SettingsChange c) {
    _toastTimer?.cancel();
    _toast = c;
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _guard(VoidCallback go) {
    if (!_dirty) return go();
    final l = context.l10n;
    _ask(
      title: l.set_leaveTitle,
      body: widget.data.page == SettingsPageId.models
          ? l.mp_leaveBody
          : l.set_leaveBody,
      confirm: l.set_discard,
      danger: true,
      onConfirm: () {
        _dirty = false;
        go();
      },
    );
  }

  void _open(SettingsPageId page, {String? anchor}) => _guard(() {
    _highlightTimer?.cancel();
    setState(() {
      _query = '';
      _highlight = anchor;
    });
    if (anchor != null) {
      _highlightTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _highlight = null);
      });
    }
    if (page != widget.data.page) widget.actions.onOpenPage(page);
  });

  void _ask({
    required String title,
    required String body,
    required String confirm,
    bool danger = false,
    required VoidCallback onConfirm,
  }) => setState(
    () => _confirm = _Confirm(title, body, confirm, danger, onConfirm),
  );

  /// 搜索框里：↑↓ 选结果，Enter 跳过去。
  KeyEventResult _onSearchKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_query.trim().isEmpty || _hits.isEmpty) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowUp) {
      final d = k == LogicalKeyboardKey.arrowDown ? 1 : -1;
      setState(() => _sel = (_sel + d).clamp(0, _hits.length - 1));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      final h = _hits[_sel.clamp(0, _hits.length - 1)];
      _open(h.page, anchor: h.anchor);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (ctrl && e.logicalKey == LogicalKeyboardKey.keyF) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (ctrl &&
        e.logicalKey == LogicalKeyboardKey.keyZ &&
        _toast != null &&
        _toast!.undoable) {
      widget.actions.onUndo(_toast!.id);
      setState(() => _toast = null);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.escape && _query.isNotEmpty) {
      setState(() => _query = '');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final data = widget.data;
    final searching = _query.trim().isNotEmpty;
    final page = searching
        ? SettingsSearchResults(
            query: _query.trim(),
            selected: _sel,
            onHits: (h) => _hits = h,
            onJump: (p, anchor) => _open(p, anchor: anchor),
          )
        : KeyedSubtree(key: ValueKey(data.page), child: _pageOf(data.page));
    return SettingsScope(
      data: data,
      actions: widget.actions,
      highlight: _highlight,
      confirm: _ask,
      jump: _open,
      reportDirty: (v) => _dirty = v,
      child: UiModal(
        dialog: _confirm == null
            ? null
            : (_) => _ConfirmDialog(
                confirm: _confirm!,
                onClose: () => setState(() => _confirm = null),
              ),
        onDismiss: () => setState(() => _confirm = null),
        child: Focus(
          focusNode: _rootFocus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: ColoredBox(
            color: c.page,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sidebar = constraints.maxWidth < 1000 ? 208.0 : 248.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: sidebar,
                      child: _Sidebar(
                        query: _query,
                        focus: _searchFocus,
                        onQuery: (q) => setState(() {
                          _query = q;
                          _sel = 0;
                        }),
                        onOpen: _open,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(searching: searching),
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(child: page),
                                if (_toast != null && !searching)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 22,
                                    child: Center(
                                      child: _ToastDock(
                                        change: _toast!,
                                        onUndo: () {
                                          widget.actions.onUndo(_toast!.id);
                                          setState(() => _toast = null);
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageOf(SettingsPageId p) => switch (p) {
    SettingsPageId.overview => const SettingsOverviewPage(),
    SettingsPageId.account => const SettingsAccountPage(),
    SettingsPageId.appearance => const SettingsAppearancePage(),
    SettingsPageId.canvas => const SettingsCanvasPage(),
    SettingsPageId.shortcuts => const SettingsShortcutsPage(),
    SettingsPageId.generation => const SettingsGenerationPage(),
    SettingsPageId.storage => const SettingsStoragePage(),
    SettingsPageId.dictionaries => const SettingsDictionaryPage(),
    SettingsPageId.models => const SettingsModelsPage(),
    SettingsPageId.agent => const SettingsAgentPage(),
    SettingsPageId.rag => const SettingsRagPage(),
    SettingsPageId.upscale => const SettingsUpscalePage(),
    SettingsPageId.bridges => const SettingsBridgesPage(),
    SettingsPageId.network => const SettingsNetworkPage(),
    SettingsPageId.privacy => const SettingsPrivacyPage(),
    SettingsPageId.backup => const SettingsBackupPage(),
    SettingsPageId.about => const SettingsAboutPage(),
  };
}

// ───────────────────────────── 目录 ─────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.query,
    required this.focus,
    required this.onQuery,
    required this.onOpen,
  });

  final String query;
  final FocusNode focus;
  final ValueChanged<String> onQuery;
  final void Function(SettingsPageId page, {String? anchor}) onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final data = s.data;
    final searching = query.trim().isNotEmpty;
    final items = <Widget>[];
    SettingsGroup? last;
    for (final p in SettingsPageId.values) {
      if (p.group != last && p.group != SettingsGroup.none) {
        items.add(
          Padding(
            // 原型 .gl 上 14，加上前一项被折叠掉的 1px 下外边距。
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
            child: Text(
              SettingsFormat.group(context, p.group),
              style: UiText.sans(
                11,
                weight: FontWeight.w500,
                color: c.faint,
                letterSpacing: .44,
                height: 1.45,
              ),
            ),
          ),
        );
      }
      last = p.group;
      items.add(
        _NavItem(
          page: p,
          selected: !searching && data.page == p,
          meta: _meta(context, p),
          onTap: () => onOpen(p),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WindowHeader(
            enabled: false,
            dragBackground: true,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 16),
                child: Row(
                  children: [
                    Text(
                      l.set_title,
                      style: UiText.sans(
                        15,
                        weight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const Spacer(),
                    const SettingsKeys(['Ctrl', ',']),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: _SearchBox(value: query, focus: focus, onChanged: onQuery),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                children: items,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    data.version,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.mono(12, color: c.faint),
                  ),
                ),
                if (data.about.update == SettingsUpdateState.available)
                  UiPressable(
                    key: const Key('settings-update-badge'),
                    onTap: () => onOpen(SettingsPageId.about),
                    builder: (context, _) =>
                        UiMini(l.set_hasUpdate, tone: UiMiniTone.error),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 目录项右侧的小读数 / 状态点。
  Widget? _meta(BuildContext context, SettingsPageId p) {
    final c = context.ui;
    final d = SettingsScope.of(context).data;
    Widget text(String s) => Text(s, style: UiText.mono(11, color: c.faint));
    switch (p) {
      case SettingsPageId.account:
        final t = d.account.current?.tier;
        return t == null || t == SettingsTier.none
            ? null
            : text(SettingsFormat.tier(t));
      case SettingsPageId.shortcuts:
        final n = d.shortcuts.shortcuts.length;
        return n == 0 ? null : text('$n');
      case SettingsPageId.storage:
        final b = d.storage.totalBytes;
        return b == 0 ? null : text('${(b / (1 << 30)).round()} GB');
      case SettingsPageId.models:
        final on = d.models.providers.where((p) => p.enabled).toList();
        if (on.isEmpty) return null;
        final tone = on.any((p) => p.status == SettingsTone.error)
            ? SettingsTone.error
            : SettingsTone.ok;
        return SettingsDot(tone);
      case SettingsPageId.rag:
        if (!d.values.flag(SettingKey.ragEnabled) ||
            d.rag.sources.isEmpty ||
            !d.rag.progressKnown) {
          return null;
        }
        final v = d.rag.overall;
        return v >= 1 ? null : text(SettingsFormat.percent(v));
      case SettingsPageId.bridges:
        final b = d.bridges;
        final comfyDown =
            d.values.flag(SettingKey.comfyEnabled) &&
            b.comfyTone == SettingsTone.error;
        if (comfyDown) return const SettingsDot(SettingsTone.warn);
        return b.kritaConnected || b.agentClients > 0
            ? const SettingsDot(SettingsTone.ok)
            : null;
      case SettingsPageId.about:
        return d.about.update == SettingsUpdateState.available
            ? const SettingsDot(SettingsTone.error)
            : null;
      default:
        return null;
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.page,
    required this.selected,
    required this.meta,
    required this.onTap,
  });

  final SettingsPageId page;
  final bool selected;
  final Widget? meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final icon = SettingsFormat.icon(page);
    return UiPressable(
      key: Key('settings-nav-${page.name}'),
      onTap: onTap,
      builder: (context, hover) {
        final ink = selected ? c.accent : c.muted;
        return Container(
          height: 32,
          margin: const EdgeInsets.fromLTRB(8, 1, 8, 0),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(c.accent.withValues(alpha: .09), c.bg)
                : hover
                ? c.hover
                : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            spacing: 10,
            children: [
              SizedBox(
                width: 18,
                child: Center(
                  child: icon.icon != null
                      ? Icon(icon.icon, size: 17, color: ink)
                      : UiGlyph(icon.glyph!, size: 16, color: ink),
                ),
              ),
              Expanded(
                child: Text(
                  SettingsFormat.page(context, page),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    13,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: c.ink,
                  ),
                ),
              ),
              ?meta,
            ],
          ),
        );
      },
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({
    required this.value,
    required this.focus,
    required this.onChanged,
  });
  final String value;
  final FocusNode focus;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final _ctrl = TextEditingController(text: widget.value);

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void didUpdateWidget(covariant _SearchBox old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    widget.focus.removeListener(_rebuild);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final on = widget.focus.hasFocus || widget.value.isNotEmpty;
    return Container(
      key: const Key('settings-search'),
      height: 32,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: on ? c.card : c.sunk,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: on ? c.accent : c.border),
        boxShadow: on
            ? [
                BoxShadow(
                  color: c.accent.withValues(alpha: .16),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Row(
        spacing: 8,
        children: [
          UiGlyph(UiGlyphs.search, size: 15, color: c.faint),
          Expanded(
            child: TextField(
              key: const Key('settings-search-input'),
              controller: _ctrl,
              focusNode: widget.focus,
              style: UiText.sans(12.5, color: c.ink, height: 1.2),
              cursorColor: c.accent,
              cursorHeight: 14,
              decoration: uiBareDecoration(
                hintText: l.set_search,
                hintStyle: UiText.sans(12.5, color: c.faint, height: 1.2),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          if (widget.value.isNotEmpty)
            UiIconBox(
              glyph: UiGlyphs.close,
              size: 22,
              glyphSize: 13,
              onTap: () {
                _ctrl.clear();
                widget.onChanged('');
              },
            )
          else
            const SettingsKeys(['Ctrl', 'F']),
        ],
      ),
    );
  }
}

// ───────────────────────────── 顶栏 ─────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.searching});
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final p = s.data.page;
    final chrome = WindowChromeScope.activeOf(context);
    final crumbs = <String>[
      l.set_title,
      if (searching)
        l.set_searchResults
      else ...[
        if (p.group != SettingsGroup.none)
          SettingsFormat.group(context, p.group),
        SettingsFormat.page(context, p),
      ],
    ];
    return WindowHeader(
      dragBackground: true,
      inlineDragWidth: 12,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 55,
          child: Padding(
            padding: EdgeInsets.only(
              left: constraints.maxWidth < 760 ? 24 : 48,
              right: chrome ? 0 : 24,
            ),
            child: Row(
              spacing: 10,
              children: [
                Flexible(
                  child: Row(
                    spacing: 6,
                    children: [
                      for (final (i, t) in crumbs.indexed) ...[
                        if (i > 0)
                          UiGlyph(
                            UiGlyphs.chevronRight,
                            size: 13,
                            color: c.muted,
                          ),
                        Flexible(
                          child: Text(
                            t,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(
                              13,
                              weight: i == crumbs.length - 1
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: i == crumbs.length - 1 ? c.ink : c.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (!searching) ..._actions(context, p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, SettingsPageId p) {
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final a = s.actions;
    Widget resetPage() {
      final changed = s.data.modified
          .where((k) => SettingSpec.of(k).page == p)
          .length;
      return SettingsBtn(
        key: const Key('settings-reset-page'),
        label: l.set_resetPage,
        glyph: SettingsGlyphs.undo,
        small: true,
        tone: SettingsBtnTone.ghost,
        onTap: changed == 0
            ? null
            : () => s.confirm(
                title: l.set_resetPageTitle(SettingsFormat.page(context, p)),
                body: l.set_resetPageBody('$changed'),
                confirm: l.set_resetDefault,
                danger: true,
                onConfirm: () => a.onResetPage(p),
              ),
      );
    }

    return switch (p) {
      SettingsPageId.account => [
        SettingsBtn(
          label: l.set_accAdd,
          glyph: UiGlyphs.plus,
          small: true,
          onTap: a.onAddAccount,
        ),
      ],
      SettingsPageId.appearance ||
      SettingsPageId.canvas ||
      SettingsPageId.generation => [resetPage()],
      SettingsPageId.shortcuts => [
        SettingsBtn(
          label: l.set_scHelp,
          glyph: SettingsGlyphs.key,
          small: true,
          tone: SettingsBtnTone.ghost,
          onTap: a.onShowShortcutHelp,
        ),
      ],
      SettingsPageId.models => [
        SettingsBtn(
          label: l.set_mdImport,
          glyph: UiGlyphs.download,
          small: true,
          tone: SettingsBtnTone.ghost,
          onTap: a.onImportModelConfig,
        ),
        if (s.data.models.workbench != null)
          MediaQuery.sizeOf(context).width < 1100
              ? SettingsIconBtn(
                  key: const Key('models-copy-config'),
                  glyph: SettingsGlyphs.copy,
                  tooltip: l.set_bkCopyConfig,
                  onTap: a.onCopyModelConfig,
                )
              : SettingsBtn(
                  key: const Key('models-copy-config'),
                  label: l.set_bkCopyConfig,
                  glyph: SettingsGlyphs.copy,
                  small: true,
                  tone: SettingsBtnTone.ghost,
                  onTap: a.onCopyModelConfig,
                ),
        SettingsBtn(
          label: l.set_mdAddProvider,
          glyph: UiGlyphs.plus,
          small: true,
          // 新工作台：在页面里开添加弹窗（借搜索跳转的高亮通道传给模型页）。
          onTap: () => s.jump(SettingsPageId.models, anchor: 'provider-add'),
        ),
      ],
      SettingsPageId.agent => [
        SettingsBtn(
          label: l.set_agOpen,
          glyph: SettingsGlyphs.external,
          small: true,
          tone: SettingsBtnTone.ghost,
          onTap: a.onOpenAgent,
        ),
      ],
      SettingsPageId.about => [
        SettingsBtn(
          label: l.set_abCheck,
          glyph: UiGlyphs.refresh,
          small: true,
          onTap: s.data.about.update == SettingsUpdateState.checking
              ? null
              : a.onCheckUpdate,
        ),
      ],
      _ => const [],
    };
  }
}

// ───────────────────────────── 浮层 ─────────────────────────────

/// 底部“已保存 · 撤销”（原型 `.dock`）。
class _ToastDock extends StatelessWidget {
  const _ToastDock({required this.change, required this.onUndo});
  final SettingsChange change;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return SettingsDockBar(
      key: const Key('settings-toast'),
      children: [
        UiGlyph(UiGlyphs.check, size: 15, color: c.ok),
        Flexible(
          child: Text(
            l.set_savedChange(change.title, change.from, change.to),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(12.5, color: c.tipInk),
          ),
        ),
        if (change.undoable) ...[
          SettingsDockButton(label: l.set_undo, onTap: onUndo),
          Text(
            'Ctrl+Z',
            style: UiText.mono(
              10.5,
              weight: FontWeight.w500,
              color: c.tipInk.withValues(alpha: .55),
            ),
          ),
        ],
      ],
    );
  }
}

/// 深色浮条：圆角 12、内边距 8 8 8 16、间距 12。
class SettingsDockBar extends StatelessWidget {
  const SettingsDockBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.tipBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 36,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: children,
      ),
    );
  }
}

class SettingsDockButton extends StatelessWidget {
  const SettingsDockButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      key: Key('dock-$label'),
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? c.brand
              : (hover ? c.tipInk.withValues(alpha: .08) : null),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: primary ? c.brand : c.tipInk.withValues(alpha: .22),
          ),
        ),
        child: Text(
          label,
          style: UiText.sans(
            12,
            weight: FontWeight.w500,
            color: primary ? c.onBrand : c.tipInk,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.confirm, required this.onClose});
  final _Confirm confirm;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('settings-confirm'),
      width: 400,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  confirm.title,
                  style: UiText.sans(15, weight: FontWeight.w600, color: c.ink),
                ),
                Text(
                  confirm.body,
                  style: UiText.sans(12.5, color: c.muted, height: 1.6),
                ),
              ],
            ),
          ),
          UiDialogFooter(
            children: [
              const Spacer(),
              SettingsBtn(
                key: const Key('confirm-cancel'),
                label: l.set_cancel,
                onTap: onClose,
              ),
              SettingsBtn(
                key: const Key('confirm-ok'),
                label: confirm.confirm,
                tone: confirm.danger
                    ? SettingsBtnTone.danger
                    : SettingsBtnTone.primary,
                onTap: () {
                  onClose();
                  confirm.onConfirm();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
