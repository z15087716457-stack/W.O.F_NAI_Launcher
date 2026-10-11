// 大图查看器预览：一个本地模拟器，按契约回调改假数据，让每个按钮在预览里都“真的”起作用。
// 只给 preview_main.dart 用，不进应用。
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_fixture.dart';

/// 预设状态（预览顶栏切换）。
enum ViewerScene { gallery, nometa, generation, loading, missing, protected }

final _images = <String, ImageProvider>{};

/// 优先用原型图（.devin/mockups/viewer/assets：s = 大图、t = 缩略图），没有大图就用缩略图，都没有用渐变图。
ImageProvider? viewerPreviewImage(String key, bool thumb) =>
    _images.putIfAbsent('$key$thumb', () {
      for (final name in [if (!thumb) 's$key', 't$key']) {
        final f = File('../../mockups/viewer/assets/$name.jpg');
        if (f.existsSync()) return FileImage(f);
      }
      return UiFixtureImage.gradient('v$key');
    });

class ViewerPreviewSim extends ChangeNotifier {
  ViewerPreviewSim({required this.log});

  final ValueChanged<String> log;

  var _scene = ViewerScene.gallery;
  late var _keys = ViewerFixture.order;
  var current = '08';
  var _base = 1284 - 1 - 1;
  final _favorites = <String>{'08'};
  final _members = <String, Set<String>>{
    '08': {'wof', 'normal'},
  };
  final _collections = [...ViewerFixture.collections];
  final _saved = <String>{};
  final _translations = <ViewerPart, ViewerTranslation>{};
  final _trash = <(int, String)>[];
  var _undoId = 0;
  ViewerUndo? _undo;
  var infoOpen = true;
  var fullscreen = false;
  var _hintSeen = false;
  var _loading = false;

  /// 关闭时预览切回别的页面。
  VoidCallback? onClose;

  ViewerScene get scene => _scene;
  set scene(ViewerScene s) {
    _scene = s;
    _translations.clear();
    _undo = null;
    _trash.clear();
    _loading = false;
    switch (s) {
      case ViewerScene.nometa:
        _keys = [...ViewerFixture.nometaList];
        current = '04';
        _base = 38015 - 2;
      case ViewerScene.generation:
        _keys = [...ViewerFixture.batch];
        current = '16';
        _base = 0;
      default:
        _keys = ViewerFixture.order;
        current = s == ViewerScene.gallery || s == ViewerScene.protected
            ? '08'
            : '16';
        _base = 1284 - 1 - _keys.indexOf('08');
        if (s == ViewerScene.loading) _simulateLoad();
    }
    notifyListeners();
  }

  void _simulateLoad() {
    _loading = true;
    Timer(const Duration(milliseconds: 1600), () {
      _loading = false;
      notifyListeners();
    });
  }

  bool get _gen => _scene == ViewerScene.generation;

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  ViewerViewData get data {
    final base = _gen
        ? ViewerFixture.generation(images: viewerPreviewImage, current: current)
        : ViewerFixture.gallery(
            current: current,
            list: _keys,
            position: _base + _keys.indexOf(current),
            total:
                (_scene == ViewerScene.nometa ? 45550 : 45550) - _trash.length,
            scope: _scene == ViewerScene.nometa
                ? const ViewerScope(name: '氛围图', sort: ViewerSort.modified)
                : const ViewerScope(sort: ViewerSort.modified),
            images: viewerPreviewImage,
            favorite: false,
          );
    final items = [
      for (final i in base.items)
        ViewerItem(
          key: i.key,
          width: i.width,
          height: i.height,
          thumb: i.thumb,
          image: _loading && i.key == current ? null : i.image,
          date: i.date,
          favorite: _favorites.contains(i.key),
          missing: _scene == ViewerScene.missing && i.key == current,
          protected: _scene == ViewerScene.protected,
          saved: _saved.contains(i.key),
          path: i.path,
          sizeBytes: i.sizeBytes,
        ),
    ];
    final members = _members[current] ?? const {};
    return ViewerViewData(
      mode: base.mode,
      items: items,
      currentKey: current,
      now: base.now,
      position: base.position,
      total: base.total,
      scope: base.scope,
      detail: _loading
          ? ViewerDetail(key: current, status: ViewerMetaStatus.loading)
          : base.detail,
      actions: base.actions,
      infoOpen: infoOpen,
      fullscreen: fullscreen,
      collections: [
        for (final c in _collections)
          ViewerCollection(
            id: c.id,
            name: c.name,
            depth: c.depth,
            member: members.contains(c.id),
          ),
      ],
      translations: Map.of(_translations),
      undo: _undo,
      zoomHintSeen: _hintSeen,
    );
  }

  void _go(int i) {
    if (i < 0 || i >= _keys.length) return;
    _set(() {
      current = _keys[i];
      _translations.clear();
    });
  }

  ViewerActions get actions => ViewerActions(
    onClose: ({required keyboard}) {
      log('onClose(keyboard: $keyboard)');
      onClose?.call();
    },
    onSelect: (k) => _go(_keys.indexOf(k)),
    onStep: (d) => _go(_keys.indexOf(current) + d),
    onJump: ({required last}) => _go(last ? _keys.length - 1 : 0),
    onLoadMore: ({required forward}) => log('onLoadMore(forward: $forward)'),
    onInfoChanged: (v) => _set(() => infoOpen = v),
    onFullscreenChanged: (v) => _set(() => fullscreen = v),
    onSetFavorite: (k, v) =>
        _set(() => v ? _favorites.add(k) : _favorites.remove(k)),
    onToggleCollection: (k, id, v) => _set(() {
      final s = _members.putIfAbsent(k, () => {});
      v ? s.add(id) : s.remove(id);
    }),
    onCreateCollection: (k) => _set(() {
      final id = 'c${_collections.length}';
      _collections.add(
        ViewerCollection(id: id, name: '新收藏集 ${_collections.length - 3}'),
      );
      _members.putIfAbsent(k, () => {}).add(id);
    }),
    onDelete: (k) => _set(() {
      final i = _keys.indexOf(k);
      _keys = [..._keys]..removeAt(i);
      _trash.add((i, k));
      _undo = ViewerUndo(id: '${_undoId++}', fileName: '$k.png');
      if (_keys.isEmpty) {
        onClose?.call();
        return;
      }
      current = _keys[i.clamp(0, _keys.length - 1)];
    }),
    onUndoDelete: () => _set(() {
      if (_trash.isEmpty) return;
      final (i, k) = _trash.removeLast();
      _keys = [..._keys]..insert(i, k);
      current = k;
      _undo = null;
    }),
    onDismissUndo: () => _set(() => _undo = null),
    onAction: (k, a) {
      log('onAction($k, ${a.name})');
      if (a == ViewerAction.save) _set(() => _saved.add(k));
    },
    onCopy: (k, p) => log('onCopy($k, $p)'),
    onToggleTranslation: (k, p) {
      if (_translations[p]?.text != null) {
        _set(() => _translations.remove(p));
        return;
      }
      _set(() => _translations[p] = const ViewerTranslation(busy: true));
      Timer(const Duration(milliseconds: 900), () {
        _set(
          () => _translations[p] = const ViewerTranslation(
            text: '（模拟译文）画师串保持原样，其余标签翻成中文：官方插画、视觉小说 CG、动画上色、赛璐璐阴影、干净线稿……',
          ),
        );
      });
    },
    onSaveVibe: (k, i) => log('onSaveVibe($k, $i)'),
    onZoomHintSeen: () => _set(() => _hintSeen = true),
    onCaptionOverStage: (v) => log('onCaptionOverStage($v)'),
  );
}
