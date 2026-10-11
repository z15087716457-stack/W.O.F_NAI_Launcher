// Vibe 库 / 精准参考库预览：一个本地模拟器，按契约回调改假数据，让每个按钮在预览里都“真的”起作用。
// 只给 preview_main.dart 用，不进应用。
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';

/// 预设状态（预览顶栏切换）。
enum RefsScene { ready, loading, empty, v5, drop, import }

final _images = <String, ImageProvider>{};

/// 优先用原型图（.devin/mockups/refs/assets），没有就用生成的渐变图。
ImageProvider refsPreviewImage(String key) => _images.putIfAbsent(key, () {
  final f = File('../../mockups/refs/assets/$key.jpg');
  return f.existsSync() ? FileImage(f) : UiFixtureImage.gradient(key);
});

class RefsPreviewSim extends ChangeNotifier {
  RefsPreviewSim({required this.log});

  final ValueChanged<String> log;

  var scene = RefsScene.ready;
  var kind = RefsKind.vibe;
  var vibes = RefsFixture.vibes(refsPreviewImage);
  var precise = RefsFixture.precise(refsPreviewImage);
  var categories = [...RefsFixture.categories];
  final _filters = <RefsKind, RefsFilter>{};
  final _selected = <RefsKind, String?>{
    RefsKind.vibe: 'c03',
    RefsKind.precise: 'c20',
  };
  var cardSize = RefsCardSize.medium;
  var sidebar = true;
  var inspector = true;
  var paused = false;
  var _importOpen = false;
  final _covers = <String, int>{};
  late final _tray = <RefsKind, List<String>>{
    RefsKind.vibe: [
      for (final e in vibes)
        if (e.inGeneration) e.key,
    ],
    RefsKind.precise: [
      for (final e in precise)
        if (e.inGeneration) e.key,
    ],
  };

  RefsFilter get filter => _filters[kind] ?? const RefsFilter();

  List<RefsEntry> get _all => kind == RefsKind.vibe ? vibes : precise;

  set _all(List<RefsEntry> v) =>
      kind == RefsKind.vibe ? vibes = v : precise = v;

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  void _update(Iterable<String> keys, RefsEntry Function(RefsEntry) f) {
    final s = keys.toSet();
    _all = [for (final e in _all) s.contains(e.key) ? f(e) : e];
  }

  bool _match(RefsEntry e, RefsFilter f) {
    final q = f.query.toLowerCase();
    if (q.isNotEmpty &&
        !e.name.toLowerCase().contains(q) &&
        !e.tags.any((t) => t.toLowerCase().contains(q))) {
      return false;
    }
    final inGen = _tray[kind]!.contains(e.key);
    final view = switch (f.view) {
      RefsView.all => true,
      RefsView.favorites => e.favorite,
      RefsView.recent => e.lastUsed != null,
      RefsView.inGeneration => inGen,
    };
    if (!view) return false;
    if (f.categoryId case final c?) {
      if (c == RefsCategory.uncategorized) {
        if (e.categoryId != null) return false;
      } else {
        final ids = {c, ..._descendants(c)};
        if (!ids.contains(e.categoryId)) return false;
      }
    }
    if (f.source != null && e.source != f.source) return false;
    if (f.type != null && e.type != f.type) return false;
    return switch (f.quick) {
      RefsQuick.all => true,
      RefsQuick.favorites => e.favorite,
      RefsQuick.hasRaw => e.hasRaw ?? false,
      RefsQuick.needsEncoding =>
        e.encoding == RefsEncoding.encodeOnUse ||
            e.encoding == RefsEncoding.reencode,
      RefsQuick.bundles => e.isBundle,
      RefsQuick.unused => e.usedCount == 0,
    };
  }

  Iterable<String> _descendants(String id) sync* {
    for (final c in categories.where((c) => c.parentId == id)) {
      yield c.id;
      yield* _descendants(c.id);
    }
  }

  RefsViewData get data {
    final f = filter;
    final model = scene == RefsScene.v5 ? RefsFixture.v5 : RefsFixture.v45;
    final empty = scene == RefsScene.empty;
    final tray = _tray[kind]!;
    final all = [
      for (final e in empty ? const <RefsEntry>[] : _all)
        e.copyWith(inGeneration: tray.contains(e.key)),
    ];
    final list = scene == RefsScene.loading
        ? <RefsEntry>[]
        : (all.where((e) => _match(e, f)).toList()..sort((a, b) {
            final r = switch (f.sort) {
              RefsSort.lastUsed => (a.lastUsed ?? DateTime(2000)).compareTo(
                b.lastUsed ?? DateTime(2000),
              ),
              RefsSort.createdAt => (a.createdAt ?? DateTime(2000)).compareTo(
                b.createdAt ?? DateTime(2000),
              ),
              RefsSort.usedCount => a.usedCount.compareTo(b.usedCount),
              RefsSort.name => b.name.compareTo(a.name),
            };
            return f.descending ? -r : r;
          }));
    final selected = _selected[kind];
    final sel = all.where((e) => e.key == selected).firstOrNull;
    final byKey = {for (final e in all) e.key: e};
    final counts = RefsCounts(
      all: all.length,
      favorites: all.where((e) => e.favorite).length,
      inGeneration: tray.length,
      uncategorized: all.where((e) => e.categoryId == null).length,
      needsEncoding: all
          .where(
            (e) =>
                e.encoding == RefsEncoding.encodeOnUse ||
                e.encoding == RefsEncoding.reencode,
          )
          .length,
      sources: {
        for (final s in RefsVibeSource.values)
          s: all.where((e) => e.source == s).length,
      },
      types: {
        for (final t in RefsPreciseType.values)
          t: all.where((e) => e.type == t).length,
      },
    );
    final detail = sel == null
        ? null
        : RefsDetail(
            key: sel.key,
            image: sel.thumb,
            bundle: sel.isBundle
                ? RefsFixture.bundle(refsPreviewImage)
                : const [],
            coverIndex: _covers[sel.key] ?? 0,
            bundleEncodedFor: sel.isBundle ? 'V4.5' : null,
          );
    return RefsViewData(
      kind: kind,
      now: RefsFixture.now,
      model: model,
      entries: list,
      counts: counts,
      categories: kind == RefsKind.vibe && !empty
          ? [
              for (final c in categories)
                RefsCategory(
                  id: c.id,
                  name: c.name,
                  parentId: c.parentId,
                  count: all
                      .where(
                        (e) =>
                            e.categoryId == c.id ||
                            _descendants(c.id).contains(e.categoryId),
                      )
                      .length,
                ),
            ]
          : const [],
      filter: f,
      selectedKey: sel?.key,
      detail: detail,
      tray: RefsTray(
        items: [
          for (final k in tray)
            if (byKey[k] case final e?)
              RefsTrayItem(
                id: 'gen-$k',
                entryKey: k,
                thumb: e.thumb,
                value: e.strength,
                enabled: kind == RefsKind.vibe ? !paused : true,
              ),
        ],
        otherVibes: kind == RefsKind.precise ? _tray[RefsKind.vibe]!.length : 0,
        vibesPaused: paused,
      ),
      cardSize: cardSize,
      sidebarOpen: sidebar,
      inspectorOpen: inspector,
      folderPath: r'E:\A.I\NovelAI\NAI\vibes',
      exportFolder: r'E:\A.I\NovelAI\导出\vibes',
      importType: f.type ?? RefsPreciseType.both,
      loading: scene == RefsScene.loading,
      drop: scene == RefsScene.drop ? RefsFixture.drop : null,
      importDraft: scene == RefsScene.import || _importOpen
          ? RefsFixture.importDraft(refsPreviewImage)
          : null,
    );
  }

  void _add(List<String> keys, {bool replace = false}) {
    final t = _tray[kind]!;
    if (replace) t.clear();
    for (final k in keys) {
      if (!t.contains(k) && (kind == RefsKind.precise || t.length < 16)) {
        t.add(k);
      }
    }
    _update(
      keys,
      (e) => e.copyWith(usedCount: e.usedCount + 1, lastUsed: DateTime.now()),
    );
  }

  RefsActions get actions => RefsActions(
    onFilterChanged: (f) => _set(() => _filters[kind] = f),
    onCardSizeChanged: (s) => _set(() => cardSize = s),
    onSidebarChanged: (v) => _set(() => sidebar = v),
    onInspectorChanged: (v) => _set(() => inspector = v),
    onSelect: (k) => _set(() => _selected[kind] = k),
    onAddToGeneration: (keys, {replace = false, overrides = const {}}) {
      log(
        'onAddToGeneration($keys, replace: $replace, overrides: ${overrides.length})',
      );
      _set(() => _add(keys, replace: replace));
    },
    onAddBundle: (key, {indexes, overrides = const {}, replace = false}) {
      log('onAddBundle($key, indexes: $indexes)');
      _set(() => _add([key], replace: replace));
    },
    onSendImg2Img: (k) => log('onSendImg2Img($k)'),
    onSaveAsVibe: (k) => log('onSaveAsVibe($k)'),
    onSetFavorite: (keys, v) =>
        _set(() => _update(keys, (e) => e.copyWith(favorite: v))),
    onRename: (k, name) =>
        _set(() => _update([k], (e) => e.copyWith(name: name))),
    onUpdateParams: (k, p) => _set(
      () => _update(
        [k],
        (e) => e.copyWith(
          strength: p.strength,
          infoExtracted: p.infoExtracted,
          fidelity: p.fidelity,
          type: p.type,
        ),
      ),
    ),
    onSetStrengthMany: (keys, v) =>
        _set(() => _update(keys, (e) => e.copyWith(strength: v))),
    onSetTypeMany: (keys, t) =>
        _set(() => _update(keys, (e) => e.copyWith(type: t))),
    onSaveBundle: (k, v) => log('onSaveBundle($k, ${v.keys.toList()})'),
    onSplitBundle: (k) => log('onSplitBundle($k)'),
    onSetBundleCover: (k, i) => _set(() => _covers[k] = i),
    onPackBundle: (keys) => log('onPackBundle($keys)'),
    onEncodeNow: (k) => _set(
      () => _update([
        k,
      ], (e) => e.copyWith(encoding: RefsEncoding.ready, encodedFor: 'V4.5')),
    ),
    onMoveToCategory: (keys, id) =>
        _set(() => _update(keys, (e) => e.copyWith(categoryId: () => id))),
    onAddTags: (keys, tags) => _set(
      () => _update(
        keys,
        (e) => e.copyWith(
          tags: [
            ...e.tags,
            for (final t in tags)
              if (!e.tags.contains(t)) t,
          ],
        ),
      ),
    ),
    onRemoveTag: (k, t) => _set(
      () => _update([k], (e) => e.copyWith(tags: [...e.tags]..remove(t))),
    ),
    onCreateCategory: (name, {parentId}) async {
      final id = 'cat${DateTime.now().microsecondsSinceEpoch}';
      _set(() {
        final c = RefsCategory(
          id: id,
          name: name,
          count: 0,
          parentId: parentId,
        );
        if (parentId == null) {
          categories.add(c);
        } else {
          final i = categories.lastIndexWhere(
            (x) => x.id == parentId || x.parentId == parentId,
          );
          categories.insert(i + 1, c);
        }
      });
      return id;
    },
    onRenameCategory: (id, name) => _set(() {
      categories = [
        for (final c in categories)
          c.id == id
              ? RefsCategory(
                  id: c.id,
                  name: name,
                  count: 0,
                  parentId: c.parentId,
                )
              : c,
      ];
    }),
    onDeleteCategory: (id) => _set(() {
      final gone = {id, ..._descendants(id)};
      categories = [
        for (final c in categories)
          if (!gone.contains(c.id)) c,
      ];
      _all = [
        for (final e in _all)
          gone.contains(e.categoryId) ? e.copyWith(categoryId: () => null) : e,
      ];
    }),
    onMoveCategory: (id, parent) => _set(() {
      categories = [
        for (final c in categories)
          c.id == id
              ? RefsCategory(id: c.id, name: c.name, count: 0, parentId: parent)
              : c,
      ];
    }),
    onImport: (s) {
      log('onImport(${s.name})');
      if (kind == RefsKind.vibe) _set(() => _importOpen = true);
    },
    onImportConfirm: (p) {
      log('onImportConfirm(${p.rows.length} rows, encodeNow: ${p.encodeNow})');
      _set(() {
        _importOpen = false;
        if (scene == RefsScene.import) scene = RefsScene.ready;
      });
    },
    onImportCancel: () => _set(() {
      _importOpen = false;
      if (scene == RefsScene.import) scene = RefsScene.ready;
    }),
    onExport: (p) =>
        log('onExport(${p.keys.length}, ${p.format.name}, zip: ${p.zip})'),
    onPickExportFolder: () async => r'D:\导出\vibes',
    onExportAll: () => log('onExportAll'),
    onRescan: () {
      _set(() => scene = RefsScene.loading);
      Timer(const Duration(milliseconds: 900), () {
        if (scene == RefsScene.loading) _set(() => scene = RefsScene.ready);
      });
    },
    onOpenFolder: (k) => log('onOpenFolder($k)'),
    onReplacePreview: (k) => log('onReplacePreview($k)'),
    onCopyImage: (k) => log('onCopyImage($k)'),
    onDelete: (keys) => _set(() {
      _all = [
        for (final e in _all)
          if (!keys.contains(e.key)) e,
      ];
      _tray[kind]!.removeWhere(keys.contains);
    }),
    onTrayRemove: (id) =>
        _set(() => _tray[kind]!.remove(id.replaceFirst('gen-', ''))),
    onTrayClear: () => _set(() => _tray[kind]!.clear()),
    onPauseVibes: (v) => _set(() => paused = v),
    onGoGeneration: () => log('onGoGeneration'),
    onSwitchModel: () => _set(() => scene = RefsScene.ready),
  );
}
