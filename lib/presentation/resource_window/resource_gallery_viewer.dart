import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../core/services/resource_window_host.dart';
import '../../core/shortcuts/shortcut_config.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../data/models/gallery/local_image_record.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../ui/kit/ui_resource_kind.dart';
import '../ui/viewer/viewer_contract.dart';
import '../ui/viewer/viewer_page.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import '../widgets/common/themed_input_dialog.dart';
import '../wiring/image_viewer_backend.dart';
import '../wiring/image_viewer_mapping.dart';
import 'resource_window_controller.dart';

/// Uses the same viewer UI/backend as the local gallery. Only data and explicit
/// library/workflow actions cross IPC; browsing never opens the primary viewer.
class ResourceGalleryViewer extends StatefulWidget {
  const ResourceGalleryViewer({
    super.key,
    required this.controller,
    required this.initialId,
  });
  final ResourceWindowController controller;
  final String initialId;
  @override
  State<ResourceGalleryViewer> createState() => _ResourceGalleryViewerState();
}

class _ResourceGalleryViewerState extends State<ResourceGalleryViewer> {
  late final ImageViewerBackend _backend;
  final _media = <String, ViewerItem>{};
  final _loading = <String>{};
  final _favorites = <String, bool>{};
  final _translations = <ViewerPart, ViewerTranslation>{};
  final _translationTokens = <ViewerPart, Object>{};
  List<ViewerCollection>? _collections;
  String? _selection;
  bool _infoOpen = true, _fullscreen = false, _zoomHintSeen = false;
  bool _confirmDangerous = true, _loadingMore = false;
  bool _highlight = true, _kritaConnected = false;
  Map<ViewerCommand, List<SingleActivator>> _keys = ViewerKeys.defaults;

  Future<Object?> _request(String operation, Map<String, Object?> values) =>
      widget.controller.call('gallery.viewer', {
        'operation': operation,
        ...values,
      });

  @override
  void initState() {
    super.initState();
    _backend = ImageViewerBackend(
      keys: widget.controller.data.items.map((item) => item.id).toList(),
      initialKey: widget.initialId,
      pageSize: 12,
      load: (keys) async {
        final result = resourceMap(await _request('records', {'ids': keys}));
        _confirmDangerous = result['confirmDangerousActions'] as bool;
        _highlight = result['highlight'] as bool? ?? true;
        _kritaConnected = result['kritaConnected'] as bool? ?? false;
        final shortcuts = result['shortcuts'] as String?;
        _keys = shortcuts == null
            ? ViewerKeys.defaults
            : viewerKeysOf(
                ShortcutConfig.fromJson(resourceMap(jsonDecode(shortcuts))),
              );
        final sources = <ImageDetailData>[];
        for (final value in (result['records'] as List).map(resourceMap)) {
          sources.add(
            LocalImageDetailData(
              LocalImageRecord(
                path: resourceString(value, 'path'),
                size: value['size'] as int,
                modifiedAt: DateTime.fromMillisecondsSinceEpoch(
                  value['modifiedAt'] as int,
                ),
                isFavorite: value['favorite'] as bool,
              ),
            ),
          );
        }
        return sources;
      },
      readMetadata: (source) async {
        final json = await _request('metadata', {'id': source.identifier});
        return json == null
            ? null
            : NaiImageMetadata.fromJson(
                resourceMap(jsonDecode(json as String)),
              );
      },
      deleteImage: (key) async => await _request('delete', {'id': key}) as bool,
      restoreImage: (key) async {
        await _request('restore', {'id': key});
      },
    )..addListener(_changed);
    unawaited(widget.controller.runViewer(_backend.initialize));
  }

  @override
  void dispose() {
    _backend
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (_selection != _backend.currentKey) {
      _selection = _backend.currentKey;
      _collections = null;
      _translations.clear();
      _translationTokens.clear();
      if (_selection != null) {
        unawaited(widget.controller.runViewer(_refreshCollections));
      }
    }
    setState(() {});
    for (final source in _backend.sources) {
      if (_media.containsKey(source.identifier) ||
          !_loading.add(source.identifier)) {
        continue;
      }
      unawaited(
        widget.controller.runViewer(
          () => _loadMedia(source as LocalImageDetailData),
        ),
      );
    }
  }

  Future<void> _loadMedia(LocalImageDetailData source) async {
    final record = source.record;
    try {
      final file = File(record.path);
      final missing = !await file.exists();
      final header = missing
          ? null
          : await file
                .openRead(0, 65536)
                .fold(
                  BytesBuilder(copy: false),
                  (buffer, chunk) => buffer..add(chunk),
                );
      final dimensions = header == null
          ? null
          : NaiResolutionAdapter.readImageSize(header.takeBytes());
      if (!mounted) return;
      final screen = MediaQuery.sizeOf(context);
      final ratio = MediaQuery.devicePixelRatioOf(context);
      _media[record.path] = ViewerItem(
        key: record.path,
        width: dimensions?.$1 ?? 0,
        height: dimensions?.$2 ?? 0,
        image: missing
            ? null
            : ResizeImage(
                FileImage(file),
                width: math.max(1, (screen.width * ratio * 2).ceil()),
                height: math.max(1, (screen.height * ratio * 2).ceil()),
                policy: ResizeImagePolicy.fit,
              ),
        thumb: ResourceWindowImage(
          FloatingResourceKind.gallery,
          record.path,
          '${record.size}:${record.modifiedAt.microsecondsSinceEpoch}',
          widget.controller.call,
        ),
        missing: missing,
        path: record.path,
        date: record.modifiedAt.toLocal(),
        sizeBytes: record.size,
      );
      setState(() {});
    } finally {
      _loading.remove(record.path);
    }
  }

  Future<void> _refreshCollections() async {
    final key = _backend.currentKey;
    if (key == null) return;
    final result = await _request('collections', {'id': key}) as List;
    if (!mounted || key != _backend.currentKey) return;
    setState(() {
      _collections = [
        for (final value in result.map(resourceMap))
          ViewerCollection(
            id: value['id'] as String,
            name: value['name'] as String,
            member: value['member'] as bool,
            depth: value['depth'] as int,
          ),
      ];
    });
  }

  Future<void> _loadMore({required bool forward}) async {
    if (_loadingMore) return;
    _loadingMore = true;
    try {
      if (forward &&
          (widget.controller.data.hasMore ||
              _backend.total < widget.controller.data.total)) {
        final more = widget.controller.data.hasMore;
        await widget.controller.refresh(
          more: more,
          retain: more ? null : widget.controller.data.items.length,
        );
        if (!mounted) return;
        _backend.appendKeys(
          widget.controller.data.items.map((item) => item.id),
        );
      }
      await _backend.loadMore(forward: forward);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _step(int delta) async {
    if (_backend.position + delta >= _backend.total && delta > 0) {
      await _loadMore(forward: true);
    }
    if (mounted) await _backend.step(delta);
  }

  Future<void> _jump({required bool last}) async {
    while (last &&
        mounted &&
        (widget.controller.data.hasMore ||
            _backend.total < widget.controller.data.total)) {
      final previous = _backend.total;
      final hadMore = widget.controller.data.hasMore;
      await _loadMore(forward: true);
      if (_backend.total == previous &&
          widget.controller.data.hasMore == hadMore)
        break;
    }
    if (mounted) await _backend.jump(last: last);
  }

  Future<void> _translate(String key, ViewerPart part) async {
    if (_backend.metadataLoading || _translations[part]?.busy == true) return;
    if (_translations[part]?.text != null) {
      _translationTokens.remove(part);
      setState(() => _translations.remove(part));
      return;
    }
    final token = Object();
    _translationTokens[part] = token;
    setState(() => _translations[part] = const ViewerTranslation(busy: true));
    String? text;
    await widget.controller.runViewer(() async {
      text =
          await _request('translate', {
                'id': key,
                'part': part.kind.name,
                'index': part.index,
                'session':
                    'resource-viewer-$key-$part-${identityHashCode(token)}',
              })
              as String?;
    });
    if (!mounted ||
        key != _backend.currentKey ||
        !identical(_translationTokens[part], token)) {
      return;
    }
    setState(() {
      if (text == null) {
        _translations.remove(part);
      } else {
        _translations[part] = ViewerTranslation(text: text);
      }
    });
  }

  Future<void> _copy(ViewerPart part) async {
    final text = viewerPartText(_backend.metadata, part);
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  Future<void> _action(String key, ViewerAction action) async {
    if (action == ViewerAction.copyPath) {
      await Clipboard.setData(ClipboardData(text: key));
    } else if (action == ViewerAction.copyAllPrompts) {
      final prompt = _backend.metadata?.fullPrompt;
      if (prompt != null) await Clipboard.setData(ClipboardData(text: prompt));
    } else {
      await _request('action', {'id': key, 'action': action.name});
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = _backend.currentKey ?? widget.initialId;
    return ImageViewerPage(
      data: ViewerViewData(
        mode: ViewerMode.gallery,
        currentKey: key,
        now: DateTime.now(),
        position: _backend.position,
        total: math.max(_backend.total, widget.controller.data.total),
        items: [
          for (final source in _backend.sources)
            if (_media[source.identifier] case final media?)
              ViewerItem(
                key: media.key,
                width: media.width,
                height: media.height,
                image: media.image,
                thumb: media.thumb,
                missing: media.missing,
                path: media.path,
                date: media.date,
                sizeBytes: media.sizeBytes,
                favorite: _favorites[media.key] ?? source.isFavorite,
                protected: _confirmDangerous,
              ),
        ],
        detail: viewerDetailOf(
          key,
          _backend.metadata,
          path: key,
          loading: _backend.metadataLoading,
        ),
        actions: ViewerAction.values
            .where((action) => action != ViewerAction.save)
            .toSet(),
        infoOpen: _infoOpen,
        highlight: _highlight,
        kritaConnected: _kritaConnected,
        keys: _keys,
        fullscreen: _fullscreen,
        zoomHintSeen: _zoomHintSeen,
        collections: _collections,
        translations: Map.unmodifiable(_translations),
        undo: _backend.undoId == null
            ? null
            : ViewerUndo(
                id: _backend.undoId!,
                fileName: p.basename(_backend.undoKey!),
              ),
      ),
      actions: ViewerActions(
        onClose: ({required keyboard}) => widget.controller.closeViewer(),
        onSelect: (key) =>
            unawaited(widget.controller.runViewer(() => _backend.select(key))),
        onStep: (delta) =>
            unawaited(widget.controller.runViewer(() => _step(delta))),
        onJump: ({required last}) =>
            unawaited(widget.controller.runViewer(() => _jump(last: last))),
        onLoadMore: ({required forward}) => unawaited(
          widget.controller.runViewer(() => _loadMore(forward: forward)),
        ),
        onInfoChanged: (value) => setState(() => _infoOpen = value),
        onFullscreenChanged: (value) => setState(() => _fullscreen = value),
        onSetFavorite: (key, value) => unawaited(
          widget.controller.runViewer(() async {
            await _request('favorite', {'id': key, 'value': value});
            if (!mounted) return;
            setState(() => _favorites[key] = value);
            await _refreshCollections();
          }),
        ),
        onToggleCollection: (key, id, member) => unawaited(
          widget.controller.runViewer(() async {
            await _request('setCollection', {
              'id': key,
              'collectionId': id,
              'member': member,
            });
            if (mounted) await _refreshCollections();
          }),
        ),
        onCreateCollection: (key) => unawaited(
          widget.controller.runViewer(() async {
            final name = await ThemedInputDialog.show(
              context: context,
              title: context.l10n.localGallery_createCollectionTitle,
            );
            if (!mounted || name == null || name.trim().isEmpty) return;
            await _request('createCollection', {
              'id': key,
              'name': name.trim(),
            });
            if (mounted) await _refreshCollections();
          }),
        ),
        onDelete: (key) => unawaited(
          widget.controller.runViewer(() async {
            await _backend.delete(key);
            if (mounted && _backend.total == 0) widget.controller.closeViewer();
          }),
        ),
        onUndoDelete: () =>
            unawaited(widget.controller.runViewer(_backend.undoDelete)),
        onDismissUndo: _backend.dismissUndo,
        onAction: (key, action) =>
            unawaited(widget.controller.runViewer(() => _action(key, action))),
        onCopy: (key, part) =>
            unawaited(widget.controller.runViewer(() => _copy(part))),
        onToggleTranslation: (key, part) => unawaited(_translate(key, part)),
        onSaveVibe: (key, index) => unawaited(
          widget.controller.runViewer(() async {
            await _request('saveVibe', {'id': key, 'index': index});
          }),
        ),
        onZoomHintSeen: () => _zoomHintSeen = true,
        onCaptionOverStage: (_) {},
      ),
    );
  }
}
