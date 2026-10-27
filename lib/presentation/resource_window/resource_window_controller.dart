import 'dart:async';
import 'dart:ui' as ui;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../core/services/resource_window_host.dart';
import '../../core/services/resource_window_service.dart';
import '../../core/utils/resource_window_drag.dart';
import '../ui/kit/ui_resource_kind.dart';
import '../ui/resource_window/resource_window_contract.dart';

typedef ResourceHostCall =
    Future<Object?> Function(String method, Map<String, Object?> arguments);

class ResourceWindowController extends ChangeNotifier {
  ResourceWindowController({
    required this.windowId,
    required FloatingResourceKind kind,
    ResourceHostCall? invoke,
    Future<void> Function(bool)? setAlwaysOnTop,
    this.onKindChanged,
    bool alwaysOnTop = false,
  }) : _kind = kind,
       _alwaysOnTop = alwaysOnTop,
       invoke =
           invoke ??
           ((method, args) => ResourceWindowService.hostChannel
               .invokeMethod<Object?>(method, args)),
       _setAlwaysOnTop =
           setAlwaysOnTop ??
           ((value) => const MethodChannel(
             'com.nailauncher/resource_window_native',
           ).invokeMethod<void>('setAlwaysOnTop', value));

  final String windowId;
  final ResourceHostCall invoke;
  final Future<void> Function(bool) _setAlwaysOnTop;
  final Future<void> Function(FloatingResourceKind)? onKindChanged;
  FloatingResourceKind _kind;
  String _query = '', _group = 'all';
  String? _sort, _selected;
  final _chips = <String>{};
  final _items = <Map<String, Object?>>[];
  Map<String, Object?> _page = {};
  ResourceDetail? _detail;
  ResourceLayout _layout = ResourceLayout.grid;
  double _cellSize = 132;
  bool _connected = true, _loading = false, _disposed = false, _alwaysOnTop;
  String? _error;
  int _requestId = 0, _epoch = 0, _selectionEpoch = 0, _revision = 0;
  Timer? _debounce, _layoutDebounce;
  final _exportUris = <String, Uri>{};
  final _exportsPending = <String>{};

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  String? _code(Object error) => switch (error) {
    PlatformException() => error.code,
    WindowChannelException() => error.code,
    _ => null,
  };
  Future<Object?> call(String method, Map<String, Object?> args) async {
    try {
      final result = await invoke(method, {'version': 1, ...args});
      if (!_disposed) _connected = true;
      return result;
    } on Object catch (error) {
      if (error is MissingPluginException ||
          (error is WindowChannelException || error is PlatformException) &&
              !const [
                'not_ready',
                'not_found',
                'invalid_arguments',
                'unsupported_version',
                'cancelled',
              ].contains(_code(error))) {
        _connected = false;
        _changed();
      }
      rethrow;
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error) {
      if (!_disposed && _code(error) != 'cancelled') {
        _error = '$error';
        _changed();
      }
    }
  }

  Future<void> initialize() => refresh();
  Future<void> refresh({bool more = false}) async {
    if (_disposed || more && (_loading || _page['hasMore'] != true)) return;
    final epoch = _epoch;
    final id = ++_requestId;
    final offset = more ? _items.length : 0;
    _loading = true;
    _error = null;
    _changed();
    try {
      final result = resourceMap(
        await call('resources.query', {
          'windowId': windowId,
          'requestId': id,
          'kind': _kind.name,
          'groupId': _group,
          'query': _query,
          'chips': _chips.toList(),
          'sortId': _sort,
          'offset': offset,
          'limit': 60,
        }),
      );
      if (_disposed ||
          epoch != _epoch ||
          id != _requestId ||
          result['requestId'] != id) {
        return;
      }
      final revision = result['revision'] as int;
      if (more && revision != _revision) {
        await refresh();
        return;
      }
      _revision = revision;
      final items = (result['items'] as List).map(resourceMap).toList();
      _page = result;
      if (!more) _items.clear();
      final ids = _items.map((i) => i['id']).toSet();
      _items.addAll(items.where((i) => ids.add(i['id'])));
      _sort = result['sortId'] as String?;
      _layout = ResourceLayout.values.byName(result['layout'] as String);
      _cellSize = (result['cellSize'] as num).toDouble();
      if (_selected != null && !_items.any((i) => i['id'] == _selected)) {
        _selected = null;
        _detail = null;
      }
    } catch (error) {
      if (!_disposed &&
          epoch == _epoch &&
          id == _requestId &&
          _code(error) != 'cancelled') {
        _error = '$error';
      }
    } finally {
      if (!_disposed && epoch == _epoch && id == _requestId) {
        _loading = false;
        _changed();
      }
    }
  }

  void _reset() {
    _epoch++;
    _selectionEpoch++;
    _selected = null;
    _detail = null;
    _items.clear();
    _page = {};
    _loading = false;
    _exportUris.clear();
    _exportsPending.clear();
    _debounce?.cancel();
  }

  void kind(FloatingResourceKind value) {
    if (_kind == value) return;
    _reset();
    _kind = value;
    _group = 'all';
    _query = '';
    _sort = null;
    _chips.clear();
    unawaited(
      _run(() async {
        await call('resources.kind', {
          'windowId': windowId,
          'kind': value.name,
        });
        await onKindChanged?.call(value);
        await refresh();
      }),
    );
    _changed();
  }

  void query(String value, {bool submit = false}) {
    _reset();
    _query = value;
    _changed();
    if (submit) {
      if (_kind == FloatingResourceKind.gallery) {
        unawaited(
          _run(() async {
            await call('resources.searchConfirmed', {'query': value});
          }),
        );
      }
      unawaited(refresh());
    } else {
      _debounce = Timer(
        const Duration(milliseconds: 200),
        () => unawaited(refresh()),
      );
    }
  }

  void group(String value) {
    _reset();
    _group = value;
    unawaited(refresh());
  }

  void chip(String value) {
    _reset();
    if (!_chips.remove(value)) _chips.add(value);
    unawaited(refresh());
  }

  void sort(String value) {
    _reset();
    _sort = value;
    unawaited(refresh());
  }

  Future<void> select(String id) async {
    final epoch = ++_selectionEpoch;
    final kind = _kind;
    _selected = id;
    _detail = null;
    _changed();
    unawaited(prepareExport(id));
    await _run(() async {
      final value = resourceMap(
        await call('resources.detail', {'kind': kind.name, 'id': id}),
      );
      if (_disposed ||
          epoch != _selectionEpoch ||
          kind != _kind ||
          _selected != id) {
        return;
      }
      _detail = ResourceDetail(
        itemId: value['itemId'] as String,
        title: value['title'] as String,
        subtitle: value['subtitle'] as String?,
        body: value['body'] as String?,
        negative: value['negative'] as String?,
        actions: [
          for (final a in (value['actions'] as List).map(resourceMap))
            ResourceActionSpec(
              id: a['id'] as String,
              label: a['label'] as String,
              primary: a['primary'] as bool? ?? false,
            ),
        ],
      );
      _changed();
    });
  }

  Future<void> preferences({ResourceLayout? layout, double? size}) =>
      _run(() async {
        final kind = _kind;
        await call('resources.preferences', {
          'kind': kind.name,
          if (layout != null) 'layout': layout.name,
          if (size != null) 'cellSize': size,
        });
        if (!_disposed && kind == _kind) {
          if (layout != null) _layout = layout;
          if (size != null) _cellSize = size;
          _changed();
        }
      });
  Future<void> command(String method, String id, {String? action}) =>
      _run(() async {
        final kind = _kind;
        await call(method, {
          'kind': kind.name,
          'id': id,
          if (action != null) 'actionId': action,
        });
        if (!_disposed && kind == _kind && method == 'resources.favorite') {
          await refresh();
          if (_selected == id) await select(id);
        }
      });
  Future<void> top(bool value) => _run(() async {
    await _setAlwaysOnTop(value);
    _alwaysOnTop = value;
    _changed();
    final rect = await const MethodChannel(
      'com.nailauncher/resource_window_native',
    ).invokeMethod<Object?>('getLayout');
    if (rect != null) await persistLayout(resourceMap(rect));
  });
  Future<void> persistLayout(Map<String, Object?> rect) => _run(() async {
    await call('resources.layout', {
      'windowId': windowId,
      'rect': rect,
      'alwaysOnTop': _alwaysOnTop,
    });
  });
  void nativeLayout(Map<String, Object?> rect) {
    _layoutDebounce?.cancel();
    _layoutDebounce = Timer(
      const Duration(milliseconds: 200),
      () => unawaited(persistLayout(rect)),
    );
  }

  void disconnected() {
    _connected = false;
    _changed();
  }

  void changed(Map<String, Object?> args) {
    if (args['kind'] == _kind.name) {
      final selected = _selected;
      _exportUris.clear();
      _exportsPending.clear();
      _epoch++;
      unawaited(
        _run(() async {
          await refresh();
          if (selected != null && _selected == selected) await select(selected);
        }),
      );
    } else {
      unawaited(refresh());
    }
  }

  Future<void> prepareExport(String id) async {
    if (_kind != FloatingResourceKind.gallery ||
        _exportUris.containsKey(id) ||
        !_exportsPending.add(id)) {
      return;
    }
    final epoch = _epoch;
    await _run(() async {
      try {
        final result = resourceMap(await call('gallery.export', {'id': id}));
        if (!_disposed && epoch == _epoch) {
          _exportUris[id] = Uri.parse(result['uri'] as String);
        }
      } finally {
        if (epoch == _epoch) _exportsPending.remove(id);
      }
    });
  }

  Widget dragWrap(ResourceItem item, Widget child) {
    final kind = _kind;
    return MouseRegion(
      onEnter: (_) => unawaited(prepareExport(item.id)),
      child: Listener(
        onPointerDown: (_) => unawaited(prepareExport(item.id)),
        child: DragItemWidget(
          allowedOperations: () => [DropOperation.copy],
          dragItemProvider: (_) async {
            if (kind == FloatingResourceKind.gallery) {
              // No disk/IPC await during OLE startup. If prewarming is unfinished,
              // this gesture is declined; a later gesture can use the ready URI.
              final uri = _exportUris[item.id];
              return uri == null
                  ? null
                  : ResourceWindowDrag.createGalleryItem(uri);
            }
            return ResourceWindowDrag.createItem(
              ResourceDragReference(switch (kind) {
                FloatingResourceKind.blocks => ResourceDragKind.block,
                FloatingResourceKind.vibe => ResourceDragKind.vibe,
                FloatingResourceKind.precise => ResourceDragKind.precise,
                FloatingResourceKind.gallery => throw StateError('gallery'),
              }, item.id),
            );
          },
          child: DraggableWidget(child: child),
        ),
      ),
    );
  }

  ResourceWindowActions get actions => ResourceWindowActions(
    onKind: kind,
    onGroup: group,
    onQuery: query,
    onChip: chip,
    onSort: sort,
    onLayout: (v) => unawaited(preferences(layout: v)),
    onCellSize: (v) => unawaited(preferences(size: v)),
    onSelect: (id) => unawaited(select(id)),
    onOpen: (id) => unawaited(command('resources.open', id)),
    onAction: (id, a) => unawaited(command('resources.action', id, action: a)),
    onFavorite: (id) => unawaited(command('resources.favorite', id)),
    onLoadMore: () => unawaited(refresh(more: true)),
    onAlwaysOnTop: (v) => unawaited(top(v)),
    onNewWindow: () => unawaited(
      _run(() async {
        await call('resources.newWindow', {'kind': _kind.name});
      }),
    ),
    onRetry: () => unawaited(refresh()),
    dragWrap: dragWrap,
  );

  ResourceWindowViewData get data => ResourceWindowViewData(
    kind: _kind,
    query: _query,
    groupId: _group,
    queryHint: _page['queryHint'] as String? ?? '',
    counts: {
      for (final e in resourceMap(_page['counts'] ?? {}).entries)
        FloatingResourceKind.values.byName(e.key): e.value as int,
    },
    sections: [
      for (final s in ((_page['sections'] as List?) ?? []).map(resourceMap))
        ResourceGroupSection(
          title: s['title'] as String,
          groups: [
            for (final g in (s['groups'] as List).map(resourceMap))
              ResourceGroup(
                id: g['id'] as String,
                label: g['label'] as String,
                count: g['count'] as int?,
                parentId: g['parentId'] as String?,
                color: g['color'] == null ? null : Color(g['color'] as int),
              ),
          ],
        ),
    ],
    chips: [
      for (final c in ((_page['chips'] as List?) ?? []).map(resourceMap))
        ResourceChip(
          id: c['id'] as String,
          label: c['label'] as String,
          on: _chips.contains(c['id']),
        ),
    ],
    sorts: [
      for (final s in ((_page['sorts'] as List?) ?? []).map(resourceMap))
        ResourceOption(id: s['id'] as String, label: s['label'] as String),
    ],
    sortId: _sort,
    layouts: [
      for (final l in (_page['layouts'] as List?) ?? ['grid'])
        ResourceLayout.values.byName(l as String),
    ],
    layout: _layout,
    cellSize: _cellSize,
    items: [
      for (final i in _items)
        ResourceItem(
          id: i['id'] as String,
          title: i['title'] as String,
          meta: i['meta'] as String?,
          aspect: (i['aspect'] as num?)?.toDouble(),
          badge: i['badge'] as String?,
          favorite: i['favorite'] as bool? ?? false,
          color: i['color'] == null ? null : Color(i['color'] as int),
          iconKey: i['iconKey'] as String?,
          positive: i['positive'] as String?,
          negative: i['negative'] as String?,
          folder: i['folder'] as String?,
          date: i['date'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(i['date'] as int),
          thumb: ResourceWindowImage(_kind, i['id'] as String, _revision, call),
        ),
    ],
    total: _page['total'] as int? ?? 0,
    hasMore: _page['hasMore'] as bool? ?? false,
    selectedId: _selected,
    detail: _detail,
    loading: _loading,
    error: _error,
    connected: _connected,
    alwaysOnTop: _alwaysOnTop,
  );
  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _selectionEpoch++;
    _debounce?.cancel();
    _layoutDebounce?.cancel();
    super.dispose();
  }
}

class ResourceWindowImage extends ImageProvider<ResourceWindowImage> {
  const ResourceWindowImage(this.kind, this.id, this.revision, this.invoke);
  final FloatingResourceKind kind;
  final String id;
  final int revision;
  final ResourceHostCall invoke;
  @override
  Future<ResourceWindowImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    ResourceWindowImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);
  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await invoke('resources.thumbnail', {
      'kind': kind.name,
      'id': id,
      'revision': revision,
    });
    if (bytes is! Uint8List || bytes.isEmpty) {
      throw StateError('Resource thumbnail unavailable');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is ResourceWindowImage &&
      other.kind == kind &&
      other.id == id &&
      other.revision == revision;
  @override
  int get hashCode => Object.hash(kind, id, revision);
}
