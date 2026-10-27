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
import '../../data/services/gallery/unified_gallery_service.dart'
    show GalleryTimelineEntry;
import '../../data/services/gallery/gallery_group_mode.dart';
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
  Map<FloatingResourceKind, int> _counts = {};
  bool? _descending;
  bool _sortPending = false;
  bool _maximized = false, _loadingMore = false;
  ResourceNotice? _notice;
  int _noticeId = 0;
  static const native = MethodChannel('com.nailauncher/resource_window_native');
  ResourceDetail? _detail;
  ResourceLayout _layout = ResourceLayout.grid;
  double _cellSize = 132;
  bool _connected = true, _loading = false, _disposed = false, _alwaysOnTop;
  String? _error;
  int _requestId = 0, _epoch = 0, _selectionEpoch = 0, _revision = 0;
  Timer? _debounce, _layoutDebounce;
  final _exportUris = <String, Uri>{};
  final _exportsPending = <String>{};
  List<GalleryTimelineEntry> _galleryTimeline = const [];
  final _galleryIndex = <String, int>{};
  final _galleryItems = <String, ({int revision, ResourceItem item})>{};
  final _galleryPending = <String>{};
  List<String> _galleryVisible = const [];
  GalleryGroupMode galleryGroupMode = GalleryGroupMode.day;
  List<GalleryTimelineEntry> get galleryTimeline => _galleryTimeline;
  int get selectedGalleryIndex => _galleryIndex[_selected] ?? -1;
  GalleryGroupMode get effectiveGalleryGroupMode =>
      const ['modifiedAt', 'createdAt'].contains(_sort)
      ? galleryGroupMode
      : GalleryGroupMode.none;

  ResourceItem galleryItem(int index) {
    final entry = _galleryTimeline[index];
    final cached = _galleryItems.remove(entry.path);
    if (cached != null) {
      _galleryItems[entry.path] = cached;
      return cached.item;
    }
    return ResourceItem(
      id: entry.path,
      title:
          '${entry.modifiedAt.hour.toString().padLeft(2, '0')}:${entry.modifiedAt.minute.toString().padLeft(2, '0')}',
      date: entry.modifiedAt,
      aspect: entry.aspectRatio,
      thumb: ResourceWindowImage(
        FloatingResourceKind.gallery,
        entry.path,
        '${entry.size}:${entry.modifiedAt.millisecondsSinceEpoch}',
        call,
      ),
    );
  }

  Future<void> ensureGalleryItems(List<int> indices) async {
    final epoch = _epoch;
    final revision = _revision;
    _galleryVisible = [
      for (final index in indices) _galleryTimeline[index].path,
    ];
    final missing = [
      for (final id in _galleryVisible)
        if (_galleryItems[id]?.revision != revision && _galleryPending.add(id))
          id,
    ];
    await _run(() async {
      try {
        for (var start = 0; start < missing.length; start += 60) {
          final ids = missing.skip(start).take(60).toList();
          final result =
              await call('gallery.records', {'ids': ids, 'revision': revision})
                  as List;
          if (_disposed || epoch != _epoch) return;
          for (final value in result.map(resourceMap)) {
            final item = _decodeItem(value);
            _galleryItems.remove(item.id);
            _galleryItems[item.id] = (revision: revision, item: item);
          }
          while (_galleryItems.length > 6000) {
            _galleryItems.remove(_galleryItems.keys.first);
          }
          _changed();
        }
      } finally {
        if (epoch == _epoch) _galleryPending.removeAll(missing);
      }
    });
  }

  String? _viewerId;
  String? get viewerId => _viewerId;

  void open(String id) {
    if (_kind == FloatingResourceKind.gallery) {
      _viewerId = id;
      _changed();
    } else {
      unawaited(command('resources.open', id));
    }
  }

  void closeViewer() {
    _viewerId = null;
    _changed();
  }

  Future<void> runViewer(Future<void> Function() operation) => _run(operation);

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
          const [
            'CHANNEL_NOT_FOUND',
            'CHANNEL_UNREGISTERED',
            'CHANNEL_CLOSED',
            'channel-error',
            'disconnected',
          ].contains(_code(error))) {
        _connected = false;
        _changed();
      }
      rethrow;
    }
  }

  Future<void> _run(
    Future<void> Function() operation, {
    bool query = false,
  }) async {
    try {
      await operation();
    } catch (error) {
      if (!_disposed && _code(error) != 'cancelled') {
        if (query) {
          _error = '$error';
          _changed();
          return;
        }
        final raw = _code(error);
        final message = switch (error) {
          PlatformException() => error.message,
          WindowChannelException() => error.message,
          _ => error.toString(),
        };
        final capability =
            raw == 'invalid_arguments' &&
            RegExp(
              'not support|does not use|unsupported',
              caseSensitive: false,
            ).hasMatch(message ?? '');
        _notice = ResourceNotice(
          id: ++_noticeId,
          code: !_connected
              ? 'disconnected'
              : capability
              ? 'unsupported'
              : const ['not_found', 'not_ready', 'unsupported'].contains(raw)
              ? raw!
              : 'failed',
          message: message,
        );
        _changed();
      }
    }
  }

  Future<void> initialize() => refresh();
  Future<void> refresh({bool more = false, int? retain}) async {
    if (_kind == FloatingResourceKind.gallery && more) return;
    if (_disposed || more && (_loading || _page['hasMore'] != true)) return;
    final epoch = _epoch;
    var id = _requestId;
    final collected = <Map<String, Object?>>[];
    var offset = more ? _items.length : 0;
    final target = retain == null || retain < 60 ? 60 : retain;
    _loading = true;
    _loadingMore = more;
    _error = null;
    _changed();
    try {
      late Map<String, Object?> result;
      int? snapshot;
      do {
        id = ++_requestId;
        result = resourceMap(
          await call('resources.query', {
            'windowId': windowId,
            'requestId': id,
            'kind': _kind.name,
            'groupId': _group,
            'query': _query,
            'chips': _chips.toList(),
            'sortId': _sortPending ? _sort : null,
            'descending': _sortPending ? _descending : null,
            'offset': offset,
            'limit': more || retain == null
                ? 60
                : (target - offset).clamp(1, 60),
          }),
        );
        if (_disposed ||
            epoch != _epoch ||
            id != _requestId ||
            result['requestId'] != id) {
          return;
        }
        final revision = result['revision'] as int;
        if ((more && revision != _revision) ||
            (snapshot != null && snapshot != revision)) {
          await refresh(retain: _items.length);
          return;
        }
        snapshot = revision;
        final items = (result['items'] as List).map(resourceMap).toList();
        collected.addAll(items);
        offset += items.length;
        if (more ||
            retain == null ||
            items.isEmpty ||
            result['hasMore'] != true) {
          break;
        }
      } while (offset < target);
      _revision = snapshot;
      _page = result;
      if (_kind == FloatingResourceKind.gallery) {
        _galleryTimeline = [
          for (final value in result['timeline'] as List)
            GalleryTimelineEntry(
              path: (value as List)[0] as String,
              modifiedAt: DateTime.fromMillisecondsSinceEpoch(value[1] as int),
              width: value[2] as int?,
              height: value[3] as int?,
              size: value[4] as int?,
            ),
        ];
        _galleryIndex.clear();
        for (var i = 0; i < _galleryTimeline.length; i++) {
          _galleryIndex[_galleryTimeline[i].path] = i;
        }
        galleryGroupMode = GalleryGroupMode.values.byName(
          result['groupMode'] as String,
        );
      }
      _updateCounts(result['counts']);
      if (!more) _items.clear();
      final ids = _items.map((i) => i['id']).toSet();
      _items.addAll(collected.where((i) => ids.add(i['id'])));
      _sort = result['sortId'] as String?;
      _descending = result['descending'] as bool? ?? true;
      _sortPending = false;
      _layout = ResourceLayout.values.byName(result['layout'] as String);
      _cellSize = (result['cellSize'] as num).toDouble();
      if (_selected != null &&
          (_kind == FloatingResourceKind.gallery
              ? !_galleryIndex.containsKey(_selected)
              : !_items.any((i) => i['id'] == _selected))) {
        _selectionEpoch++;
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
        _loadingMore = false;
        _changed();
      }
    }
  }

  void _reset() {
    _viewerId = null;
    _epoch++;
    _selectionEpoch++;
    _selected = null;
    _detail = null;
    _items.clear();
    _galleryTimeline = const [];
    _galleryIndex.clear();
    _galleryVisible = const [];
    _galleryPending.clear();
    _page = {};
    _loading = false;
    _sortPending = false;
    _loadingMore = false;
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
    _descending = null;
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
    _descending = null;
    _sortPending = true;
    unawaited(refresh());
  }

  void sortDirection(bool value) {
    _reset();
    _descending = value;
    _sortPending = true;
    unawaited(refresh());
  }

  void maximized(bool value) {
    _maximized = value;
    _changed();
  }

  Future<void> nativeCommand(String method) => _run(() async {
    final result = await native.invokeMethod<Object?>(method);
    if (result is bool) maximized(result);
  });

  void _updateCounts(Object? value) {
    if (value == null) return;
    _counts = {
      for (final e in resourceMap(value).entries)
        FloatingResourceKind.values.byName(e.key): e.value as int,
    };
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
    }, query: true);
  }

  Future<void> preferences({
    ResourceLayout? layout,
    double? size,
    GalleryGroupMode? groupMode,
  }) => _run(() async {
    final kind = _kind;
    await call('resources.preferences', {
      'kind': kind.name,
      if (layout != null) 'layout': layout.name,
      if (size != null) 'cellSize': size,
      if (groupMode != null) 'groupMode': groupMode.name,
    });
    if (!_disposed && kind == _kind) {
      if (layout != null) _layout = layout;
      if (size != null) _cellSize = size;
      if (groupMode != null) galleryGroupMode = groupMode;
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
          await refresh(retain: _items.length);
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

  void viewChanged(Map<String, Object?> args) {
    if (args['kind'] != _kind.name) return;
    _layout = ResourceLayout.values.byName(args['layout'] as String);
    if (args['groupMode'] case final String mode) {
      galleryGroupMode = GalleryGroupMode.values.byName(mode);
    }
    _changed();
  }

  void disconnected() {
    _connected = false;
    _changed();
  }

  void changed(Map<String, Object?> args) {
    if (args['kind'] == _kind.name) {
      final selected = _selected;
      final retain = _items.length;
      final resumeMore = _loadingMore;
      _exportUris.clear();
      _exportsPending.clear();
      _epoch++;
      _galleryPending.clear();
      unawaited(
        _run(() async {
          final epoch = _epoch;
          await refresh(retain: retain);
          if (_disposed || epoch != _epoch) return;
          if (resumeMore && _error == null) await refresh(more: true);
          if (_disposed || epoch != _epoch) return;
          if (selected != null && _selected == selected) await select(selected);
        }),
      );
    } else {
      unawaited(
        _run(() async {
          _updateCounts(await call('resources.counts', {}));
          _changed();
        }, query: true),
      );
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
    onMove: _kind != FloatingResourceKind.gallery
        ? null
        : (delta) {
            if (_galleryTimeline.isEmpty) return;
            final current = _galleryIndex[_selected] ?? -1;
            final next = (current < 0 ? 0 : current + delta).clamp(
              0,
              _galleryTimeline.length - 1,
            );
            unawaited(select(_galleryTimeline[next].path));
          },
    onKind: kind,
    onGroup: group,
    onQuery: query,
    onChip: chip,
    onSort: sort,
    onSortDirection: sortDirection,
    onDragRegion: (height, exclusions) => unawaited(
      _run(() async {
        await native.invokeMethod<void>('setDragRegion', {
          'height': height,
          'exclusions': [
            for (final rect in exclusions)
              {
                'left': rect.left,
                'top': rect.top,
                'width': rect.width,
                'height': rect.height,
              },
          ],
        });
      }),
    ),
    onClose: () => unawaited(nativeCommand('close')),
    onStartDrag: () => unawaited(nativeCommand('startDrag')),
    onToggleMaximize: () => unawaited(nativeCommand('toggleMaximize')),
    onLayout: (v) => unawaited(preferences(layout: v)),
    onCellSize: (v) => unawaited(preferences(size: v)),
    onSelect: (id) => unawaited(select(id)),
    onOpen: open,
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

  ResourceItem _decodeItem(Map<String, Object?> i) => ResourceItem(
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
    thumb: i['hasThumb'] == false
        ? null
        : ResourceWindowImage(
            _kind,
            i['id'] as String,
            i['thumbVersion'] ?? '',
            call,
          ),
    crop: i['crop'] == null
        ? null
        : ResourceThumbCrop(
            offsetX: (resourceMap(i['crop'])['offsetX'] as num).toDouble(),
            offsetY: (resourceMap(i['crop'])['offsetY'] as num).toDouble(),
            scale: (resourceMap(i['crop'])['scale'] as num).toDouble(),
          ),
    itemCount: i['itemCount'] as int?,
    useCount: i['useCount'] as int?,
    hasParams: i['hasParams'] as bool? ?? false,
    strength: (i['strength'] as num?)?.toDouble(),
    secondary: (i['secondary'] as num?)?.toDouble(),
    inGeneration: i['inGeneration'] as bool? ?? false,
    bundleCount: i['bundleCount'] as int? ?? 0,
  );

  ResourceWindowViewData get data => ResourceWindowViewData(
    kind: _kind,
    query: _query,
    groupId: _group,
    queryHint: _page['queryHint'] as String? ?? '',
    counts: _counts,
    descending: _descending ?? true,
    notice: _notice,
    maximized: _maximized,
    sections: [
      for (final s in ((_page['sections'] as List?) ?? []).map(resourceMap))
        ResourceGroupSection(
          id: s['id'] as String? ?? '',
          title: s['title'] as String,
          groups: [
            for (final g in (s['groups'] as List).map(resourceMap))
              ResourceGroup(
                id: g['id'] as String,
                label: g['label'] as String,
                count: g['count'] as int?,
                parentId: g['parentId'] as String?,
                icon: ResourceGroupIcon.values.asNameMap()[g['icon']],
                expanded: g['expanded'] as bool? ?? false,
                dim: g['dim'] as bool? ?? false,
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
        ResourceOption(
          id: s['id'] as String,
          label: s['label'] as String,
          directional: s['directional'] as bool? ?? true,
        ),
    ],
    sortId: _sort,
    layouts: [
      for (final l in (_page['layouts'] as List?) ?? ['grid'])
        ResourceLayout.values.byName(l as String),
    ],
    layout: _layout,
    cellSize: _cellSize,
    items: _kind == FloatingResourceKind.gallery
        ? [
            for (final id in {
              ..._galleryVisible,
              if (_selected != null) _selected!,
            })
              if (_galleryIndex[id] case final index?) galleryItem(index),
          ]
        : [for (final i in _items) _decodeItem(i)],
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
  const ResourceWindowImage(this.kind, this.id, this.thumbVersion, this.invoke);
  final FloatingResourceKind kind;
  final String id;
  final Object thumbVersion;
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
      'thumbVersion': thumbVersion,
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
      other.thumbVersion == thumbVersion;
  @override
  int get hashCode => Object.hash(kind, id, thumbVersion);
}
