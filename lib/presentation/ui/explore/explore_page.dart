import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/common/drag_preview_divider.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import 'explore_contract.dart';
import 'explore_detail.dart';
import 'explore_dialogs.dart';
import 'explore_editor.dart';
import 'explore_evolution.dart';
import 'explore_inspector.dart';
import 'explore_popovers.dart';
import 'explore_stage.dart';
import 'explore_wall.dart';

enum ExploreTab { candidates, evolution }

enum ExploreFilterKind { all, favorites, ungrouped, group }

/// 候选页签的筛选（界面自己的状态）。
@immutable
class ExploreFilter {
  const ExploreFilter._(this.kind, [this.groupId]);
  static const all = ExploreFilter._(ExploreFilterKind.all);
  static const favorites = ExploreFilter._(ExploreFilterKind.favorites);
  static const ungrouped = ExploreFilter._(ExploreFilterKind.ungrouped);
  const ExploreFilter.group(String id) : this._(ExploreFilterKind.group, id);

  final ExploreFilterKind kind;
  final String? groupId;

  bool accepts(ExploreCandidate c) => switch (kind) {
    ExploreFilterKind.all => true,
    ExploreFilterKind.favorites => c.favorite,
    ExploreFilterKind.ungrouped => c.groupId == null,
    ExploreFilterKind.group => c.groupId == groupId,
  };

  @override
  bool operator ==(Object other) =>
      other is ExploreFilter && other.kind == kind && other.groupId == groupId;
  @override
  int get hashCode => Object.hash(kind, groupId);
}

/// 页面级的界面状态和命令，舞台、候选墙、检查器、进化页签通过 [ExploreScope] 拿到。
abstract class ExploreController {
  ExploreTab get tab;
  void setTab(ExploreTab tab);

  ExploreFilter get filter;
  void setFilter(ExploreFilter filter);

  /// 轮按新到旧排（默认）。
  bool get newestFirst;
  void toggleOrder();

  /// 多选模式：候选页签勾候选，进化页签勾子代。
  bool get selecting;
  List<String> get selected;
  void setSelecting(bool value);
  void toggleSelect(String key);

  /// Shift + 单击：从上一次点的到这张整段勾上。
  void selectRange(String key);
  void setSelected(Iterable<String> keys);

  /// 检查器正在看的那张。
  String? get focusKey;
  void focus(String key);

  /// 进化页签当前看的进化线。
  String? get lineId;
  void setLine(String id);

  /// 候选页签当前筛选下的候选，按显示顺序（含排队 / 失败）。
  List<String> get visibleKeys;

  /// 候选墙每行几张（方向键上下跳一行）。
  set columns(int value);

  /// 快捷键 / 批量操作的对象：多选时是勾上的，否则是正在看的那张。
  List<String> get targets;

  void openDetail(String key);
  void openRunMenu(UiPopoverAnchor anchor);
  bool get runMenuOpen;
  void openMenu(UiPopoverAnchor anchor, List<UiMenuItem> items);
  void closePopover();

  void startEvolution(List<String> keys);
  void saveBlock(List<String> keys);
  void compare(String lineId);
  void confirmDeleteRun(String runId);
  void confirmDeleteLine(String lineId);
  void delete(List<String> keys);

  /// 分组行尾 “+ 分组” 正在输入（[keys] 建好后放进去）。
  bool get addingGroup;
  List<String> get addingGroupKeys;
  void beginAddGroup(List<String> keys);
  void endAddGroup();

  bool get renamingRun;
  void setRenamingRun(bool value);

  /// 检查器停靠在右边（宽窗口且打开）；窄窗口时抽屉拉开。
  bool get inspectorDocked;
  bool get inspectorVisible;
  bool get narrow;
  void toggleInspector();
  void closeDrawer();
}

class ExploreScope extends InheritedWidget {
  const ExploreScope({
    super.key,
    required this.data,
    required this.actions,
    required this.controller,
    required super.child,
  });

  final ExploreViewData data;
  final ExploreActions actions;
  final ExploreController controller;

  static ExploreScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExploreScope>()!;

  @override
  bool updateShouldNotify(ExploreScope old) => true;
}

/// 画风探索：编辑列 384（352–560）│ 舞台（顶栏 61 · 页签 46 · 候选墙 / 进化）│ 检查器 340。
/// 舞台放不下 480 时检查器变成盖在舞台上的抽屉（不回调，不改用户设置）。
class StyleExplorePage extends StatefulWidget {
  const StyleExplorePage({
    super.key,
    required this.data,
    required this.actions,
    required this.editor,
    this.dock,
  });

  final ExploreViewData data;
  final ExploreActions actions;
  final ExploreEditorBuilder editor;

  /// 块库侧栏（和生图页同一个）：非空时贴在编辑列右边、整高，舞台跟着让位。
  final Widget? dock;

  static const inspectorWidth = 340.0;
  static const dockWidth = 300.0;
  static const minEditor = 352.0;
  static const maxEditor = 560.0;
  static const minStage = 480.0;

  @override
  State<StyleExplorePage> createState() => _StyleExplorePageState();
}

enum _Dialog { none, evolution, block, compare, deleteRun, deleteLine }

class _StyleExplorePageState extends State<StyleExplorePage>
    implements ExploreController {
  final _focusNode = FocusNode(debugLabel: 'style-explore');
  var _tab = ExploreTab.candidates;
  var _filter = ExploreFilter.all;
  var _newestFirst = true;
  var _selecting = false;
  final _selected = <String>[];
  String? _anchor;
  String? _focus;
  String? _line;
  var _columns = 4;
  var _addingGroup = false;
  var _addingKeys = const <String>[];
  var _renamingRun = false;
  var _narrow = false;
  var _drawer = false;
  double? _committedWidth;
  final _widthPreview = DragPreviewController();

  UiPopoverAnchor? _popAnchor;
  var _runMenu = false;
  List<UiMenuItem> _menu = const [];

  var _dialog = _Dialog.none;
  var _dialogKeys = const <String>[];
  String? _dialogId;

  String? _detailKey;
  var _detailHistory = false;
  var _detailIndex = 0;
  Timer? _undoTimer;
  bool? _captionOver;

  ExploreViewData get _data => widget.data;
  ExploreActions get _actions => widget.actions;
  ExploreRunView? get _run => _data.run;

  @override
  void initState() {
    super.initState();
    _syncUndo(null);
  }

  @override
  void didUpdateWidget(covariant StyleExplorePage old) {
    super.didUpdateWidget(old);
    final hadDetail = _detailKey != null;
    if (old.data.editorWidth != _data.editorWidth) _committedWidth = null;
    final run = _run;
    if (old.data.run?.id != run?.id) {
      _selecting = false;
      _selected.clear();
      _focus = null;
      _line = null;
      _filter = ExploreFilter.all;
      _detailKey = null;
      _dialog = _Dialog.none;
      _renamingRun = false;
    } else if (run != null) {
      // 刚建的进化线：切到进化页签看它；培育出新一代：清掉上一代的勾选。
      final before = {
        for (final l in old.data.run?.lines ?? const <ExploreLine>[])
          l.id: l.generations.length,
      };
      final added = run.lines.where((l) => !before.containsKey(l.id));
      if (added.isNotEmpty) {
        _line = added.last.id;
        _tab = ExploreTab.evolution;
        _selecting = false;
        _selected.clear();
        _focus = null;
      } else if (_activeLine case final l?
          when (before[l.id] ?? 0) < l.generations.length) {
        _selecting = false;
        _selected.clear();
      }
    }
    final keys = {for (final c in run?.candidates ?? const []) c.key};
    _selected.removeWhere((k) => !keys.contains(k));
    if (_focus != null && !keys.contains(_focus)) _focus = null;
    if (_filter.kind == ExploreFilterKind.group &&
        !(run?.groups.any((g) => g.id == _filter.groupId) ?? false)) {
      _filter = ExploreFilter.all;
    }
    if (_detailKey != null && !keys.contains(_detailKey)) {
      final list = _detailList;
      _detailKey = list.isEmpty
          ? null
          : list[_detailIndex.clamp(0, list.length - 1)];
    }
    if (hadDetail && _detailKey == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _detailKey == null) _closeDetail();
      });
    }
    _syncUndo(old.data.undo);
  }

  @override
  void dispose() {
    _widthPreview.dispose();
    _undoTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncUndo(ExploreUndo? old) {
    final u = _data.undo;
    if (u?.id == old?.id) return;
    _undoTimer?.cancel();
    if (u != null) {
      _undoTimer = Timer(const Duration(seconds: 6), _actions.onDismissUndo);
    }
  }

  // ---------- 状态 ----------

  @override
  ExploreTab get tab => _tab;
  @override
  void setTab(ExploreTab tab) => setState(() {
    if (_tab == tab) return;
    _tab = tab;
    _selecting = false;
    _selected.clear();
  });

  @override
  ExploreFilter get filter => _filter;
  @override
  void setFilter(ExploreFilter f) => setState(() => _filter = f);

  @override
  bool get newestFirst => _newestFirst;
  @override
  void toggleOrder() => setState(() => _newestFirst = !_newestFirst);

  @override
  bool get selecting => _selecting;
  @override
  List<String> get selected => _selected;

  @override
  void setSelecting(bool value) => setState(() {
    _selecting = value;
    if (!value) _selected.clear();
  });

  @override
  void toggleSelect(String key) => setState(() {
    _selecting = true;
    if (!_selected.remove(key)) _selected.add(key);
    _anchor = key;
  });

  @override
  void selectRange(String key) {
    final list = _tab == ExploreTab.candidates ? visibleKeys : _kidKeys;
    final from = list.indexOf(_anchor ?? _focus ?? key);
    final to = list.indexOf(key);
    if (from < 0 || to < 0) return toggleSelect(key);
    setState(() {
      _selecting = true;
      final (a, b) = from <= to ? (from, to) : (to, from);
      for (final k in list.sublist(a, b + 1)) {
        if (!_selected.contains(k) && _isDone(k)) _selected.add(k);
      }
    });
  }

  @override
  void setSelected(Iterable<String> keys) => setState(() {
    _selecting = true;
    _selected
      ..clear()
      ..addAll(keys);
  });

  bool _isDone(String key) => _run?.candidate(key)?.done ?? false;

  @override
  String? get focusKey => _focus ?? _defaultFocus;

  String? get _defaultFocus {
    if (_tab == ExploreTab.evolution) {
      return _kidKeys.where(_isDone).firstOrNull;
    }
    return visibleKeys.where(_isDone).firstOrNull ?? visibleKeys.firstOrNull;
  }

  @override
  void focus(String key) => setState(() {
    _focus = key;
    _anchor = key;
  });

  @override
  String? get lineId {
    final lines = _run?.lines ?? const [];
    if (lines.any((l) => l.id == _line)) return _line;
    return lines.firstOrNull?.id;
  }

  @override
  void setLine(String id) => setState(() {
    _line = id;
    _selecting = false;
    _selected.clear();
    _focus = null;
  });

  ExploreLine? get _activeLine =>
      _run?.lines.where((l) => l.id == lineId).firstOrNull;

  List<String> get _kidKeys => _activeLine?.current.childKeys ?? const [];

  @override
  List<String> get visibleKeys {
    final run = _run;
    if (run == null) return const [];
    final rounds = [
      for (final r in run.rounds)
        if (r.kind == ExploreRoundKind.basic) r,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final ordered = _newestFirst ? rounds.reversed : rounds;
    final byKey = {for (final c in run.candidates) c.key: c};
    return [
      for (final r in ordered)
        for (final k in r.keys)
          if (byKey[k] case final c? when _filter.accepts(c)) k,
    ];
  }

  @override
  set columns(int value) => _columns = value;

  @override
  List<String> get targets {
    if (_detailKey != null) return [_detailKey!];
    if (_selecting) return [..._selected];
    final f = focusKey;
    return f != null && _isDone(f) ? [f] : const [];
  }

  // ---------- 弹层 / 弹窗 / 大图 ----------

  List<String> get _detailList {
    final List<String> source;
    if (_tab == ExploreTab.candidates) {
      source = visibleKeys;
    } else if (_detailHistory) {
      source = [
        for (final generation
            in _activeLine?.generations ?? <ExploreGeneration>[]) ...[
          for (final parent in generation.parents) ?parent.candidateKey,
          ...generation.childKeys,
        ],
      ];
    } else {
      source = _kidKeys;
    }
    return [
      for (final k in source.toSet())
        if (_isDone(k)) k,
    ];
  }

  @override
  void openDetail(String key) {
    if (!_isDone(key)) return;
    setState(() {
      _focus = key;
      _detailKey = key;
      _detailHistory = _tab == ExploreTab.evolution && !_kidKeys.contains(key);
      _detailIndex = _detailList.indexOf(key);
      _popAnchor = null;
    });
  }

  void _closeDetail() {
    setState(() => _detailKey = null);
    if (_data.fullscreen) _actions.onFullscreenChanged(false);
    _reportCaption(false);
    _focusNode.requestFocus();
  }

  void _stepDetail(String key) => setState(() {
    _detailKey = key;
    _focus = key;
    _detailIndex = _detailList.indexOf(key);
  });

  void _reportCaption(bool over) {
    if (_captionOver == over) return;
    _captionOver = over;
    _actions.onCaptionOverStage(over);
  }

  @override
  void openRunMenu(UiPopoverAnchor anchor) => setState(() {
    _popAnchor = anchor;
    _runMenu = true;
  });

  @override
  bool get runMenuOpen => _popAnchor != null && _runMenu;

  @override
  void openMenu(UiPopoverAnchor anchor, List<UiMenuItem> items) => setState(() {
    _popAnchor = anchor;
    _runMenu = false;
    _menu = items;
  });

  @override
  void closePopover() {
    if (_popAnchor == null) return;
    setState(() => _popAnchor = null);
    _focusNode.requestFocus();
  }

  void _openDialog(_Dialog d, {List<String> keys = const [], String? id}) =>
      setState(() {
        _popAnchor = null;
        _dialog = d;
        _dialogKeys = keys;
        _dialogId = id;
      });

  void _closeDialog() {
    setState(() => _dialog = _Dialog.none);
    _focusNode.requestFocus();
  }

  @override
  void startEvolution(List<String> keys) {
    final done = [
      for (final k in keys)
        if (_isDone(k)) k,
    ];
    if (done.isEmpty) return;
    _openDialog(_Dialog.evolution, keys: done);
  }

  @override
  void saveBlock(List<String> keys) {
    final done = [
      for (final k in keys)
        if (_isDone(k)) k,
    ];
    if (done.isEmpty) return;
    _openDialog(_Dialog.block, keys: done);
  }

  @override
  void compare(String lineId) => _openDialog(_Dialog.compare, id: lineId);

  @override
  void confirmDeleteRun(String runId) =>
      _openDialog(_Dialog.deleteRun, id: runId);

  @override
  void confirmDeleteLine(String lineId) =>
      _openDialog(_Dialog.deleteLine, id: lineId);

  @override
  void delete(List<String> keys) {
    if (keys.isEmpty) return;
    _actions.onDeleteCandidates(keys);
    if (_selecting) setSelecting(false);
  }

  @override
  bool get addingGroup => _addingGroup;
  @override
  List<String> get addingGroupKeys => _addingKeys;

  @override
  void beginAddGroup(List<String> keys) => setState(() {
    _addingGroup = true;
    _addingKeys = keys;
    _popAnchor = null;
  });

  @override
  void endAddGroup() {
    setState(() => _addingGroup = false);
    _focusNode.requestFocus();
  }

  @override
  bool get renamingRun => _renamingRun;
  @override
  void setRenamingRun(bool value) => setState(() => _renamingRun = value);

  @override
  bool get narrow => _narrow;

  bool get _hasRun => _run != null;

  @override
  bool get inspectorDocked => !_narrow && _data.inspectorOpen && _hasRun;

  @override
  bool get inspectorVisible => _narrow ? _drawer : inspectorDocked;

  @override
  void toggleInspector() {
    if (_narrow) {
      setState(() => _drawer = !_drawer);
    } else {
      _actions.onInspectorChanged(!_data.inspectorOpen);
    }
  }

  @override
  void closeDrawer() => setState(() => _drawer = false);

  // ---------- 键盘 ----------

  bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null &&
        (ctx.widget is EditableText ||
            ctx.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final run = _run;
    if (run == null || _typing() || _dialog != _Dialog.none) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    final hw = HardwareKeyboard.instance;
    final ctrl = hw.isControlPressed || hw.isMetaPressed;
    final detail = _detailKey != null;
    if (!detail && k == LogicalKeyboardKey.escape) {
      if (_drawer) {
        closeDrawer();
        return KeyEventResult.handled;
      }
      if (_selecting) {
        setSelecting(false);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final list = _tab == ExploreTab.candidates ? visibleKeys : _kidKeys;
    if (!detail && ctrl && k == LogicalKeyboardKey.keyA) {
      setSelected(list.where(_isDone));
      return KeyEventResult.handled;
    }
    if (!detail) {
      final dir = switch (k) {
        LogicalKeyboardKey.arrowLeft => -1,
        LogicalKeyboardKey.arrowRight => 1,
        LogicalKeyboardKey.arrowUp => -_columns,
        LogicalKeyboardKey.arrowDown => _columns,
        _ => 0,
      };
      if (dir != 0 && list.isNotEmpty) {
        final i = list.indexOf(focusKey ?? '');
        final next = i < 0 ? 0 : (i + dir).clamp(0, list.length - 1);
        focus(list[next]);
        return KeyEventResult.handled;
      }
      final f = focusKey;
      if (f != null &&
          (k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.numpadEnter)) {
        openDetail(f);
        return KeyEventResult.handled;
      }
      if (f != null && k == LogicalKeyboardKey.space && _isDone(f)) {
        toggleSelect(f);
        return KeyEventResult.handled;
      }
    }
    final t = targets;
    if (t.isEmpty || ctrl && k != LogicalKeyboardKey.keyC) {
      return KeyEventResult.ignored;
    }
    if (ctrl && k == LogicalKeyboardKey.keyC) {
      _actions.onCopyArtists(t);
    } else if (k == LogicalKeyboardKey.keyF && !detail) {
      final all = t.every((x) => run.candidate(x)?.favorite ?? false);
      _actions.onSetFavorite(t, !all);
    } else if (k == LogicalKeyboardKey.keyE) {
      startEvolution(t);
    } else if (k == LogicalKeyboardKey.delete && !detail) {
      delete(t);
    } else if (_digit(k) case final d?) {
      if (d == 0) {
        _actions.onAssignGroup(t, null);
      } else if (d <= run.groups.length) {
        final g = run.groups[d - 1].id;
        final all = t.every((x) => run.candidate(x)?.groupId == g);
        _actions.onAssignGroup(t, all ? null : g);
      } else {
        return KeyEventResult.ignored;
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  static int? _digit(LogicalKeyboardKey k) {
    const keys = [
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    final i = keys.indexOf(k);
    return i < 0 ? null : i;
  }

  // ---------- 构建 ----------

  WidgetBuilder? get _dialogBuilder {
    final run = _run;
    if (run == null) return null;
    return switch (_dialog) {
      _Dialog.none => null,
      _Dialog.evolution => (_) => ExploreEvolutionDialog(
        keys: _dialogKeys,
        lineId: _tab == ExploreTab.evolution ? lineId : null,
        onClose: _closeDialog,
        onConfirm: (plan) {
          _closeDialog();
          _actions.onStartEvolution(plan);
          if (_selecting) setSelecting(false);
        },
      ),
      _Dialog.block => (_) => ExploreBlockDialog(
        keys: _dialogKeys,
        onClose: _closeDialog,
        onConfirm: (draft) {
          _closeDialog();
          _actions.onSaveBlock(draft);
        },
      ),
      _Dialog.compare => (_) => ExploreCompareDialog(
        lineId: _dialogId!,
        onClose: _closeDialog,
      ),
      _Dialog.deleteRun => (_) => ExploreConfirmDialog.deleteRun(
        runId: _dialogId!,
        onCancel: _closeDialog,
        onConfirm: () {
          _closeDialog();
          _actions.onDeleteRun(_dialogId!);
        },
      ),
      _Dialog.deleteLine => (_) => ExploreConfirmDialog.deleteLine(
        lineId: _dialogId!,
        onCancel: _closeDialog,
        onConfirm: () {
          _closeDialog();
          _actions.onDeleteLine(_dialogId!);
        },
      ),
    };
  }

  Widget _editorColumn(double width) {
    final c = context.ui;
    return Container(
      key: const Key('explore-editor'),
      width: width,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: Builder(
        builder: (context) => widget.editor(
          context,
          const ExploreEditorParts(
            randomVariables: ExploreRandomVariables(),
            generateBar: ExploreGenerateBar(),
          ),
        ),
      ),
    );
  }

  Widget _stage() {
    if (_data.loading) return const ExploreLoadingStage();
    final run = _run;
    if (run == null) return const ExploreOnboarding();
    final basic = run.rounds.any(
      (r) => r.kind == ExploreRoundKind.basic && r.keys.isNotEmpty,
    );
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ExploreStageHeader(),
            if (!basic && run.lines.isEmpty)
              const Expanded(child: ExploreOnboarding(compact: true))
            else ...[
              const ExploreTabsRow(),
              Expanded(
                child: _tab == ExploreTab.candidates
                    ? const ExploreWall()
                    : const ExploreEvolutionBody(),
              ),
            ],
          ],
        ),
        if (_selecting && _tab == ExploreTab.candidates)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(child: ExploreSelectionBar()),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final data = _data;
    return ExploreScope(
      data: data,
      actions: _actions,
      controller: this,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: UiModal(
          dialog: _dialogBuilder,
          onDismiss: _closeDialog,
          child: UiPopover(
            anchor: _popAnchor,
            onDismiss: closePopover,
            builder: (_) => ExploreScope(
              data: _data,
              actions: _actions,
              controller: this,
              child: _runMenu
                  ? const ExploreRunMenu()
                  : UiMenu(items: _menu, onClose: closePopover, width: 220),
            ),
            child: ColoredBox(
              color: c.bg,
              child: LayoutBuilder(
                builder: (context, box) {
                  final dock = widget.dock == null
                      ? 0.0
                      : StyleExplorePage.dockWidth;
                  final w = box.maxWidth - dock;
                  final want = (_committedWidth ?? data.editorWidth).clamp(
                    StyleExplorePage.minEditor,
                    StyleExplorePage.maxEditor,
                  );
                  final editor = math.max(
                    StyleExplorePage.minEditor,
                    math.min(want, w - StyleExplorePage.minStage),
                  );
                  _narrow =
                      w - editor - StyleExplorePage.inspectorWidth <
                      StyleExplorePage.minStage;
                  if (!_narrow) _drawer = false;
                  final docked = inspectorDocked;
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      if (!_typing()) _focusNode.requestFocus();
                    },
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _editorColumn(editor),
                            if (widget.dock case final d?)
                              Container(
                                key: const Key('explore-dock'),
                                width: dock,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: c.line),
                                  ),
                                ),
                                child: d,
                              ),
                            Expanded(child: _stage()),
                            if (docked) const ExploreInspector(),
                          ],
                        ),
                        Positioned(
                          left: editor - 4,
                          top: 0,
                          bottom: 0,
                          width: 8,
                          child: _ResizeHandle(
                            onStart: () => _widthPreview.start(editor, editor),
                            onDrag: (dx) => _widthPreview.move(
                              dx,
                              resolve: (v) => math.max(
                                StyleExplorePage.minEditor,
                                math.min(
                                  v.clamp(
                                    StyleExplorePage.minEditor,
                                    StyleExplorePage.maxEditor,
                                  ),
                                  w - StyleExplorePage.minStage,
                                ),
                              ),
                              position: (v) => v,
                            ),
                            onCancel: _widthPreview.cancel,
                            onEnd: () {
                              final v = _widthPreview.finish();
                              if (v == null) return;
                              setState(() => _committedWidth = v);
                              _actions.onEditorWidthChanged(v);
                            },
                          ),
                        ),
                        DragPreviewDivider(
                          key: const Key('explore-editor-resize-preview'),
                          controller: _widthPreview,
                          color: c.accent,
                        ),
                        if (_narrow && _drawer && _hasRun)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              key: const Key('explore-drawer'),
                              decoration: const BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    blurRadius: 24,
                                    offset: Offset(-6, 0),
                                  ),
                                ],
                              ),
                              child: const ExploreInspector(drawer: true),
                            ),
                          ),
                        if (_detailKey != null)
                          Positioned.fill(
                            child: ExploreDetail(
                              currentKey: _detailKey!,
                              keys: _detailList,
                              onClose: _closeDetail,
                              onStep: _stepDetail,
                              onCaptionOverStage: _reportCaption,
                            ),
                          ),
                        if (data.undo case final u?)
                          Positioned(
                            left: _detailKey != null || !_hasRun
                                ? 0
                                : editor + dock,
                            right: _detailKey == null && docked
                                ? StyleExplorePage.inspectorWidth
                                : 0,
                            bottom: _selecting ? 76 : 18,
                            child: Center(child: ExploreUndoToast(undo: u)),
                          ),
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

/// 编辑列右缘的拖动条：8 宽，悬停 / 拖动时显示 2px 强调色线。
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.onDrag,
    required this.onEnd,
    required this.onStart,
    required this.onCancel,
  });
  final ValueChanged<double> onDrag;
  final VoidCallback onStart, onEnd, onCancel;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  var _hover = false;
  var _drag = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Listener(
      onPointerCancel: (_) => widget.onCancel(),
      child: MouseRegion(
        key: const Key('explore-editor-resize'),
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            setState(() => _drag = true);
            widget.onStart();
          },
          onHorizontalDragCancel: () {
            setState(() => _drag = false);
            widget.onCancel();
          },
          onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
          onHorizontalDragEnd: (_) {
            setState(() => _drag = false);
            widget.onEnd();
          },
          child: Center(
            child: Container(
              width: 2,
              color: _hover || _drag
                  ? c.accent.withValues(alpha: .6)
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
