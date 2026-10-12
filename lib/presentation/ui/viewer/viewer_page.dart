import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kit/ui_dialog.dart';
import '../kit/ui_popover.dart';
import 'viewer_contract.dart';
import 'viewer_info.dart';
import 'viewer_menus.dart';
import 'viewer_parts.dart';
import 'viewer_stage.dart';
import 'viewer_zoom.dart';

/// 页面级的界面状态和命令，舞台、胶片条、信息栏通过 [ViewerPageScope] 拿到。
abstract class ViewerController {
  ViewerZoom get zoom;

  /// 窗口窄（页面宽 < 1152，约等于窗口 < 1200）：信息栏变成盖在图上的抽屉。
  bool get narrow;

  /// 信息栏现在看得见（宽窗口停靠，或抽屉拉开）。
  bool get infoVisible;
  void toggleInfo();
  void closeDrawer();

  /// 执行一个快捷键命令（按钮也走这里，行为和按键一致）。
  void run(ViewerCommand command);

  /// 删除当前张：受保护的先确认。
  void requestDelete();

  void openMore(UiPopoverAnchor anchor);

  /// “更多”菜单（含收藏集子菜单）开着：按钮显示按下态。
  bool get moreOpen;
  void openCollections(UiPopoverAnchor anchor);
  void openZoomMenu(UiPopoverAnchor anchor);
  void closePopover();

  /// 全屏时控件（角标、胶片条）是否显示：鼠标静止 2 秒自动藏。
  bool get chromeVisible;

  /// 全屏时鼠标在底部：显示胶片条。
  bool get filmstripPeek;

  /// 第一次放大的操作提示正在显示。
  bool get zoomHint;
}

class ViewerPageScope extends InheritedWidget {
  const ViewerPageScope({
    super.key,
    required this.data,
    required this.actions,
    required this.controller,
    required super.child,
  });

  final ViewerViewData data;
  final ViewerActions actions;
  final ViewerController controller;

  static ViewerPageScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewerPageScope>()!;

  @override
  bool updateShouldNotify(ViewerPageScope old) => true;
}

enum _Pop { none, more, collections, zoom }

enum _Dialog { none, help, delete }

/// 大图查看器：黑底舞台（顶栏 61 · 大图 · 胶片条 82）│ 信息栏 340。
/// 页面宽 < 1152 时信息栏变抽屉；全屏时只剩大图和角标。
class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    super.key,
    required this.data,
    required this.actions,
    this.infoBuilder,
  });

  final ViewerViewData data;
  final ViewerActions actions;

  /// 换掉右侧信息栏（画风探索的大图用自己的“本张抽到”信息栏）；[drawer] 同 [ViewerInfoPanel.drawer]。
  /// 在 [ViewerPageScope] 里面构建，可以拿到当前张和控制器。
  final Widget Function(BuildContext context, bool drawer)? infoBuilder;

  static const infoWidth = 340.0;
  static const narrowWidth = 1152.0;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage>
    implements ViewerController {
  final _focus = FocusNode(debugLabel: 'image-viewer');
  @override
  final zoom = ViewerZoom();
  var _narrow = false;
  var _drawer = false;
  var _pop = _Pop.none;
  UiPopoverAnchor? _anchor;
  var _dialog = _Dialog.none;
  String? _deleteKey;
  Timer? _undoTimer;
  Timer? _hintTimer;
  Timer? _idleTimer;
  var _hint = false;
  var _chrome = true;
  var _peek = false;
  bool? _captionOverStage;

  ViewerViewData get _data => widget.data;
  ViewerActions get _actions => widget.actions;
  ViewerItem? get _current => _data.current;

  @override
  void initState() {
    super.initState();
    zoom.addListener(_onZoom);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
      _precache();
    });
    _syncUndo(null);
  }

  @override
  void didUpdateWidget(covariant ImageViewerPage old) {
    super.didUpdateWidget(old);
    if (old.data.currentKey != _data.currentKey) {
      zoom.reset();
      _pop = _Pop.none;
      WidgetsBinding.instance.addPostFrameCallback((_) => _precache());
    }
    if (old.data.fullscreen != _data.fullscreen) {
      _drawer = false;
      _wake();
    }
    _syncUndo(old.data.undo);
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _hintTimer?.cancel();
    _idleTimer?.cancel();
    zoom
      ..removeListener(_onZoom)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  /// 预读前后各一张原图，翻页不黑一下。
  void _precache() {
    if (!mounted) return;
    final items = _data.items;
    final i = items.indexWhere((e) => e.key == _data.currentKey);
    for (final j in [i - 1, i + 1]) {
      final img = j >= 0 && j < items.length ? items[j].image : null;
      if (img != null) {
        unawaited(precacheImage(img, context, onError: (_, _) {}));
      }
    }
  }

  void _syncUndo(ViewerUndo? old) {
    final u = _data.undo;
    if (u?.id == old?.id) return;
    _undoTimer?.cancel();
    if (u != null) {
      _undoTimer = Timer(const Duration(seconds: 6), _actions.onDismissUndo);
    }
  }

  void _onZoom() {
    if (zoom.zoomedOnce &&
        !_data.zoomHintSeen &&
        !_hint &&
        _hintTimer == null) {
      setState(() => _hint = true);
      _hintTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() => _hint = false);
        _actions.onZoomHintSeen();
      });
    }
  }

  /// 全屏：动一下鼠标显示控件，静止 2 秒藏起来。
  void _wake([Offset? pointer, double? height]) {
    _idleTimer?.cancel();
    final peek = pointer != null && height != null && pointer.dy > height - 110;
    if (!_chrome || peek != _peek) {
      setState(() {
        _chrome = true;
        _peek = peek;
      });
    }
    if (!_data.fullscreen) return;
    _idleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_drawer) {
        setState(() {
          _chrome = false;
          _peek = false;
        });
      }
    });
  }

  @override
  bool get narrow => _narrow;

  @override
  bool get infoVisible =>
      _narrow || _data.fullscreen ? _drawer : _data.infoOpen;

  @override
  bool get chromeVisible => _chrome;

  @override
  bool get filmstripPeek => _peek;

  @override
  bool get zoomHint => _hint;

  @override
  void toggleInfo() {
    if (_narrow || _data.fullscreen) {
      setState(() => _drawer = !_drawer);
    } else {
      _actions.onInfoChanged(!_data.infoOpen);
    }
  }

  @override
  void closeDrawer() => setState(() => _drawer = false);

  @override
  void openMore(UiPopoverAnchor anchor) => setState(() {
    _pop = _Pop.more;
    _anchor = anchor;
  });

  @override
  bool get moreOpen => _pop == _Pop.more;

  @override
  void openCollections(UiPopoverAnchor anchor) => setState(() {
    _pop = _Pop.collections;
    _anchor = anchor;
  });

  @override
  void openZoomMenu(UiPopoverAnchor anchor) => setState(() {
    _pop = _Pop.zoom;
    _anchor = anchor;
  });

  @override
  void closePopover() {
    if (_pop == _Pop.none) return;
    setState(() => _pop = _Pop.none);
    _focus.requestFocus();
  }

  void _closeDialog() {
    setState(() => _dialog = _Dialog.none);
    _focus.requestFocus();
  }

  bool get _gallery => _data.mode == ViewerMode.gallery;

  bool _can(ViewerAction a) => _data.actions.contains(a);

  @override
  void run(ViewerCommand command) {
    final item = _current;
    final key = _data.currentKey;
    switch (command) {
      case ViewerCommand.previous:
        _actions.onStep(-1);
      case ViewerCommand.next:
        _actions.onStep(1);
      case ViewerCommand.first:
        _actions.onJump(last: false);
      case ViewerCommand.last:
        _actions.onJump(last: true);
      case ViewerCommand.toggleInfo:
        toggleInfo();
      case ViewerCommand.fullscreen:
        _actions.onFullscreenChanged(!_data.fullscreen);
      case ViewerCommand.close:
        if (_dialog != _Dialog.none) {
          _closeDialog();
        } else if (_drawer) {
          closeDrawer();
        } else if (_data.fullscreen) {
          _actions.onFullscreenChanged(false);
        } else {
          _actions.onClose(keyboard: true);
        }
      case ViewerCommand.zoomIn:
        zoom.zoomBy(ViewerZoom.step);
      case ViewerCommand.zoomOut:
        zoom.zoomBy(1 / ViewerZoom.step);
      case ViewerCommand.zoomFit:
        zoom.reset();
      case ViewerCommand.zoomActual:
        zoom.setScale(1);
      case ViewerCommand.reuse:
        if (_can(ViewerAction.reuse) &&
            _data.detail?.status == ViewerMetaStatus.ready) {
          _actions.onAction(key, ViewerAction.reuse);
        }
      case ViewerCommand.copyPrompt:
        if (_data.detail?.status == ViewerMetaStatus.ready) {
          _actions.onCopy(key, ViewerPart.prompt);
        }
      case ViewerCommand.favorite:
        if (_gallery && item != null) {
          _actions.onSetFavorite(key, !item.favorite);
        }
      case ViewerCommand.delete:
        if (_gallery && item != null) requestDelete();
      case ViewerCommand.undo:
        if (_data.undo != null) _actions.onUndoDelete();
      case ViewerCommand.save:
        if (_can(ViewerAction.save) && item != null && !item.saved) {
          _actions.onAction(key, ViewerAction.save);
        }
      case ViewerCommand.help:
        setState(
          () => _dialog = _dialog == _Dialog.help ? _Dialog.none : _Dialog.help,
        );
    }
  }

  @override
  void requestDelete() {
    final item = _current;
    if (item == null) return;
    if (item.protected) {
      setState(() {
        _dialog = _Dialog.delete;
        _deleteKey = item.key;
      });
    } else {
      _actions.onDelete(item.key);
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final repeatable = {
      ViewerCommand.previous,
      ViewerCommand.next,
      ViewerCommand.zoomIn,
      ViewerCommand.zoomOut,
    };
    for (final MapEntry(key: command, value: list) in _keys.entries) {
      for (final a in list) {
        if (a.accepts(e, HardwareKeyboard.instance)) {
          if (e is KeyRepeatEvent && !repeatable.contains(command)) {
            return KeyEventResult.handled;
          }
          run(command);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  Map<ViewerCommand, List<SingleActivator>> get _keys => {
    ...ViewerKeys.defaults,
    ..._data.keys,
  };

  Widget _drawerPanel({required double top}) => Positioned(
    right: 0,
    top: top,
    bottom: 0,
    child: Container(
      key: const Key('viewer-drawer'),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 50,
            offset: Offset(-24, 0),
          ),
        ],
      ),
      child: Builder(
        builder: (context) =>
            widget.infoBuilder?.call(context, true) ??
            const ViewerInfoPanel(drawer: true),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final full = data.fullscreen;
    final body = LayoutBuilder(
      builder: (context, box) {
        _narrow = box.maxWidth < ImageViewerPage.narrowWidth;
        final over = !full && (_narrow || !data.infoOpen);
        if (over != _captionOverStage) {
          _captionOverStage = over;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _actions.onCaptionOverStage(over),
          );
        }
        if (full) {
          return MouseRegion(
            onHover: (e) => _wake(e.localPosition, box.maxHeight),
            child: Stack(
              children: [
                const Positioned.fill(child: ViewerStage(fullscreen: true)),
                if (_drawer) _drawerPanel(top: 0),
              ],
            ),
          );
        }
        if (_narrow) {
          return Stack(
            children: [
              const Positioned.fill(child: ViewerStage()),
              if (_drawer) _drawerPanel(top: ViewerStage.topHeight),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(child: ViewerStage()),
            if (data.infoOpen)
              widget.infoBuilder?.call(context, false) ??
                  const ViewerInfoPanel(),
          ],
        );
      },
    );

    return ViewerPageScope(
      data: data,
      actions: _actions,
      controller: this,
      child: UiModal(
        dialog: switch (_dialog) {
          _Dialog.none => null,
          _Dialog.help => (_) => ViewerHelpDialog(onClose: _closeDialog),
          _Dialog.delete => (_) => ViewerDeleteDialog(
            onCancel: _closeDialog,
            onConfirm: () {
              final k = _deleteKey;
              _closeDialog();
              if (k != null) _actions.onDelete(k);
            },
          ),
        },
        onDismiss: _closeDialog,
        child: UiPopover(
          anchor: _pop == _Pop.none ? null : _anchor,
          onDismiss: closePopover,
          builder: (context) => ViewerPageScope(
            data: _data,
            actions: _actions,
            controller: this,
            child: switch (_pop) {
              _Pop.more => const ViewerMoreMenu(),
              _Pop.collections => const ViewerCollectionsMenu(),
              _Pop.zoom => const ViewerZoomMenu(),
              _Pop.none => const SizedBox.shrink(),
            },
          ),
          child: Focus(
            focusNode: _focus,
            onKeyEvent: _onKey,
            child: Material(
              key: const Key('image-viewer'),
              color: ViewerInk.stage,
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
