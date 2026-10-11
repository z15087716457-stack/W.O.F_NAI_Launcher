import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import 'refs_contract.dart';
import 'refs_dialogs.dart';
import 'refs_import.dart';
import 'refs_inspector.dart';
import 'refs_sidebar.dart';
import 'refs_toolbar.dart';
import 'refs_tray.dart';
import 'refs_wall.dart';

/// 页面级的界面状态和命令，左栏、卡片、检查器、托盘通过 [RefsScope] 拿到。
abstract class RefsController {
  bool get picking;

  /// 勾选的卡片，按勾选顺序。
  Set<String> get picked;
  void setPicking(bool value);
  void togglePick(String key);
  void setPicked(Iterable<String> keys);

  /// Shift+单击：从上一次单击的卡片到这张整段勾上。
  void pickRange(String key);

  /// 检查器里改过、还没“存为默认”的参数（只影响这次发送）。
  RefsSendOverride? overrideOf(String key);
  void setOverride(String key, RefsSendOverride? value);

  /// 加入生图页：带上改过的参数。
  void add(List<String> keys, {bool replace = false});

  void openMenu(UiPopoverAnchor anchor, List<UiMenuItem> items);
  void closePopover();

  /// 大图详情（Vibe / 精准参考）；组合包打开组合包详情。
  void openDetail(String key);
  void openExport(List<String> keys);

  /// 删除前确认。
  void confirmDelete(List<String> keys);

  /// 选中某条（同时记下 Shift 范围选的锚点）。
  void select(String key);

  FocusNode get searchFocus;
}

class RefsScope extends InheritedWidget {
  const RefsScope({
    super.key,
    required this.data,
    required this.actions,
    required this.controller,
    required super.child,
  });

  final RefsViewData data;
  final RefsActions actions;
  final RefsController controller;

  static RefsScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RefsScope>()!;

  @override
  bool updateShouldNotify(RefsScope old) => true;
}

/// Vibe 库 / 精准参考库：左栏 240 │ 卡片墙（≥ 560）+ 底部托盘 │ 检查器 340。
/// 窗口不够宽时先临时收起检查器，再收起左栏（不回调，不改用户设置）。
class RefsLibraryPage extends StatefulWidget {
  const RefsLibraryPage({super.key, required this.data, required this.actions});

  final RefsViewData data;
  final RefsActions actions;

  static const sidebarWidth = 240.0;
  static const inspectorWidth = 340.0;
  static const minWall = 560.0;

  @override
  State<RefsLibraryPage> createState() => _RefsLibraryPageState();
}

enum _Dialog { none, detail, bundle, export, delete }

class _RefsLibraryPageState extends State<RefsLibraryPage>
    implements RefsController {
  var _picking = false;
  final _picked = <String>{};
  String? _anchorKey;
  final _overrides = <String, RefsSendOverride>{};
  final _focus = FocusNode(debugLabel: 'refs-library');
  final _searchFocus = FocusNode(debugLabel: 'refs-search');

  UiPopoverAnchor? _menuAnchor;
  List<UiMenuItem> _menu = const [];

  var _dialog = _Dialog.none;
  String? _dialogKey;
  List<String> _dialogKeys = const [];

  RefsViewData get _data => widget.data;
  RefsActions get _actions => widget.actions;

  @override
  void didUpdateWidget(covariant RefsLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keys = {for (final e in _data.entries) e.key};
    _picked.removeWhere((k) => !keys.contains(k));
    if (oldWidget.data.kind != _data.kind) {
      _picking = false;
      _picked.clear();
      _overrides.clear();
      _dialog = _Dialog.none;
    }
    if ((_dialog == _Dialog.detail || _dialog == _Dialog.bundle) &&
        !keys.contains(_dialogKey)) {
      _dialog = _Dialog.none;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  bool get picking => _picking;

  @override
  Set<String> get picked => _picked;

  @override
  FocusNode get searchFocus => _searchFocus;

  @override
  void setPicking(bool value) => setState(() {
    _picking = value;
    if (!value) _picked.clear();
  });

  @override
  void togglePick(String key) => setState(() {
    _picking = true;
    if (!_picked.remove(key)) _picked.add(key);
    _anchorKey = key;
  });

  @override
  void setPicked(Iterable<String> keys) => setState(() {
    _picking = true;
    _picked
      ..clear()
      ..addAll(keys);
  });

  @override
  void pickRange(String key) {
    final list = [for (final e in _data.entries) e.key];
    final from = list.indexOf(_anchorKey ?? _data.selectedKey ?? key);
    final to = list.indexOf(key);
    if (from < 0 || to < 0) return togglePick(key);
    setState(() {
      _picking = true;
      final (a, b) = from <= to ? (from, to) : (to, from);
      _picked.addAll(list.sublist(a, b + 1));
    });
  }

  @override
  void select(String key) {
    _anchorKey = key;
    if (_data.selectedKey != key) _actions.onSelect(key);
  }

  @override
  RefsSendOverride? overrideOf(String key) => _overrides[key];

  @override
  void setOverride(String key, RefsSendOverride? value) => setState(() {
    if (value == null) {
      _overrides.remove(key);
    } else {
      _overrides[key] = value;
    }
  });

  bool get _usable => _data.kind == RefsKind.vibe
      ? _data.model.vibeUsable
      : _data.model.preciseUsable;

  @override
  void add(List<String> keys, {bool replace = false}) {
    if (!_usable || keys.isEmpty) return;
    _actions.onAddToGeneration(
      keys,
      replace: replace,
      overrides: {
        for (final k in keys)
          if (_overrides[k] case final o?) k: o,
      },
    );
  }

  @override
  void openMenu(UiPopoverAnchor anchor, List<UiMenuItem> items) => setState(() {
    _menuAnchor = anchor;
    _menu = items;
  });

  @override
  void closePopover() {
    if (_menuAnchor == null) return;
    setState(() => _menuAnchor = null);
  }

  @override
  void openDetail(String key) {
    final e = _data.entries.where((x) => x.key == key).firstOrNull;
    if (e == null) return;
    select(key);
    setState(() {
      _dialog = e.isBundle ? _Dialog.bundle : _Dialog.detail;
      _dialogKey = key;
    });
  }

  @override
  void openExport(List<String> keys) {
    if (keys.isEmpty) return;
    setState(() {
      _dialog = _Dialog.export;
      _dialogKeys = keys;
    });
  }

  @override
  void confirmDelete(List<String> keys) {
    if (keys.isEmpty) return;
    setState(() {
      _dialog = _Dialog.delete;
      _dialogKeys = keys;
    });
  }

  void _closeDialog() {
    setState(() => _dialog = _Dialog.none);
    _focus.requestFocus();
  }

  bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null &&
        (ctx.widget is EditableText ||
            ctx.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  List<String> get _targets =>
      _picking ? _picked.toList() : [if (_data.selectedKey case final k?) k];

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    final hw = HardwareKeyboard.instance;
    final ctrl = hw.isControlPressed || hw.isMetaPressed;
    final shift = hw.isShiftPressed;
    if (ctrl && k == LogicalKeyboardKey.keyF) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (_typing() || _dialog != _Dialog.none || _data.importDraft != null) {
      return KeyEventResult.ignored;
    }
    if (k == LogicalKeyboardKey.slash && !ctrl) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (ctrl && k == LogicalKeyboardKey.keyI) {
      _actions.onImport(RefsImportSource.files);
      return KeyEventResult.handled;
    }
    if (ctrl && k == LogicalKeyboardKey.keyE && _data.kind == RefsKind.vibe) {
      openExport(_targets);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape && _picking) {
      setPicking(false);
      return KeyEventResult.handled;
    }
    final items = _data.entries;
    if (items.isEmpty) return KeyEventResult.ignored;
    if (ctrl && k == LogicalKeyboardKey.keyA) {
      setPicked(items.map((x) => x.key));
      return KeyEventResult.handled;
    }
    final sel = _data.selectedKey;
    final dir = switch (k) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -RefsWall.columnsOf(context),
      LogicalKeyboardKey.arrowDown => RefsWall.columnsOf(context),
      _ => 0,
    };
    if (dir != 0) {
      final i = items.indexWhere((x) => x.key == sel);
      final next = i < 0 ? 0 : (i + dir).clamp(0, items.length - 1);
      select(items[next].key);
      return KeyEventResult.handled;
    }
    final targets = _targets;
    if (targets.isEmpty) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      add(targets, replace: shift);
    } else if (k == LogicalKeyboardKey.space && !_picking) {
      openDetail(targets.first);
    } else if (k == LogicalKeyboardKey.keyF && !ctrl) {
      final all = targets.every(
        (t) => items.firstWhere((x) => x.key == t).favorite,
      );
      _actions.onSetFavorite(targets, !all);
    } else if (k == LogicalKeyboardKey.delete) {
      confirmDelete(targets);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  WidgetBuilder? get _dialogBuilder {
    if (_data.importDraft case final draft?) {
      return (_) => RefsImportDialog(
        key: ValueKey(draft),
        draft: draft,
        onClose: _actions.onImportCancel,
      );
    }
    return switch (_dialog) {
      _Dialog.none => null,
      _Dialog.detail => (_) => RefsDetailDialog(
        entryKey: _dialogKey!,
        onClose: _closeDialog,
        onNavigate: (k) => openDetail(k),
      ),
      _Dialog.bundle => (_) => RefsBundleDialog(
        entryKey: _dialogKey!,
        onClose: _closeDialog,
      ),
      _Dialog.export => (_) => RefsExportDialog(
        keys: _dialogKeys,
        onClose: _closeDialog,
      ),
      _Dialog.delete => (_) => RefsDeleteDialog(
        keys: _dialogKeys,
        onClose: _closeDialog,
        onConfirm: () {
          _closeDialog();
          _actions.onDelete(_dialogKeys);
          if (_picking) setPicking(false);
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final data = _data;
    final empty = data.libraryEmpty;
    // 弹窗里的内容也要能拿到页面状态：弹窗宿主放在 RefsScope 里面。
    return RefsScope(
      data: data,
      actions: _actions,
      controller: this,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: UiModal(
          dialog: _dialogBuilder,
          barrierDismissible: data.importDraft == null,
          onDismiss: data.importDraft != null
              ? _actions.onImportCancel
              : _closeDialog,
          child: UiPopover(
            anchor: _menuAnchor,
            onDismiss: closePopover,
            builder: (_) => UiMenu(items: _menu, onClose: closePopover),
            child: ColoredBox(
              color: c.bg,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  var sidebar = data.sidebarOpen;
                  var inspector = data.inspectorOpen && !empty;
                  if (inspector &&
                      w -
                              (sidebar ? RefsLibraryPage.sidebarWidth : 0) -
                              RefsLibraryPage.inspectorWidth <
                          RefsLibraryPage.minWall) {
                    inspector = false;
                  }
                  if (sidebar &&
                      w - RefsLibraryPage.sidebarWidth <
                          RefsLibraryPage.minWall) {
                    sidebar = false;
                  }
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      if (!_typing()) _focus.requestFocus();
                    },
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (sidebar) const RefsSidebar(),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  RefsToolbar(
                                    inspectorShown: inspector,
                                    sidebarShown: sidebar,
                                  ),
                                  if (!_usable) const RefsModelBanner(),
                                  if (empty)
                                    const Expanded(child: RefsEmptyState())
                                  else ...[
                                    const RefsFilterRow(),
                                    const Expanded(child: RefsWallArea()),
                                    const RefsTrayBar(),
                                  ],
                                ],
                              ),
                            ),
                            if (inspector) const RefsInspector(),
                          ],
                        ),
                        if (data.drop case final d?)
                          Positioned.fill(child: RefsDropOverlay(summary: d)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
