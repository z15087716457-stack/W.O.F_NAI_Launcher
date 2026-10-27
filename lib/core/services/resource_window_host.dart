import 'package:flutter/services.dart';
import '../exceptions/gallery_exceptions.dart';
import '../../data/services/gallery/gallery_filter_service.dart'
    show FilterCancelledException;

import '../../data/models/resources/floating_window_data.dart';

/// All implementations live in the primary engine. Values crossing this
/// boundary must be StandardMethodCodec values, never library/provider objects.
abstract class ResourceWindowBackend {
  Future<Map<String, Object?>> query(ResourceQuery request);
  Future<Map<String, int>> counts() async => {};
  Future<Uint8List?> thumbnail(
    FloatingResourceKind kind,
    String id,
    int revision,
  );
  Future<Map<String, Object?>> detail(FloatingResourceKind kind, String id);
  Future<void> action(FloatingResourceKind kind, String id, String actionId);
  Future<void> favorite(FloatingResourceKind kind, String id);
  Future<void> open(FloatingResourceKind kind, String id);
  Future<Uri> exportGallery(String id);
  Future<List<Map<String, Object?>>> galleryRecords(List<String> ids) async =>
      resourceError('unsupported');
  void changed(FloatingResourceKind kind) {}
  Future<Object?> galleryViewer(Map<String, Object?> arguments) async =>
      resourceError('unsupported');
  Future<void> layout(String windowId, Map<String, Object?> values);
  Future<void> preferences(
    FloatingResourceKind kind,
    Map<String, Object?> values,
  );
  Future<void> confirmSearch(String query);
}

Never resourceError(String code, [String? message]) =>
    throw PlatformException(code: code, message: message ?? code);

Map<String, Object?> resourceMap(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    resourceError('invalid_arguments');
  }
  return Map<String, Object?>.from(value);
}

String resourceString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    resourceError('invalid_arguments', key);
  }
  return value;
}

FloatingResourceKind resourceKind(Map<String, Object?> map) {
  final kind = FloatingResourceKind.values.asNameMap()[map['kind']];
  if (kind == null) resourceError('invalid_arguments', 'kind');
  return kind;
}

class ResourceQuery {
  ResourceQuery(Map<String, Object?> values)
    : windowId = resourceString(values, 'windowId'),
      kind = resourceKind(values),
      requestId = _int(values, 'requestId'),
      offset = _int(values, 'offset'),
      limit = _int(values, 'limit'),
      groupId = values['groupId'] as String?,
      query = values['query'] as String? ?? '',
      sortId = values['sortId'] as String?,
      descending = values['descending'] as bool?,
      chips = _chips(values['chips']) {
    if (requestId < 0 || offset < 0 || limit < 1 || limit > 60) {
      resourceError('invalid_arguments', 'pagination');
    }
  }
  final String windowId;
  final FloatingResourceKind kind;
  final int requestId, offset, limit;
  final String? groupId, sortId;
  final bool? descending;
  final String query;
  final Set<String> chips;

  static int _int(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! int) resourceError('invalid_arguments', key);
    return value;
  }

  static Set<String> _chips(Object? value) {
    if (value == null) return {};
    if (value is! List || value.any((e) => e is! String)) {
      resourceError('invalid_arguments', 'chips');
    }
    return value.cast<String>().toSet();
  }
}

/// Protocol dispatcher separated from channels so races and failures can be
/// exercised without a second engine or access to real user storage.
class ResourceWindowHost {
  ResourceWindowBackend? backend;
  final revisions = {for (final kind in FloatingResourceKind.values) kind: 0};
  final _latest = <String, int>{};

  void changed(FloatingResourceKind kind) {
    revisions[kind] = revisions[kind]! + 1;
    backend?.changed(kind);
  }

  void closed(String id) => _latest.remove(id);

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'ready') {
      final args = resourceMap(call.arguments);
      resourceString(args, 'windowId');
      resourceKind(args);
      if (args['version'] != null && args['version'] != 1) {
        resourceError('unsupported_version');
      }
      return {'version': 1};
    }
    final source = backend;
    if (source == null) resourceError('not_ready');
    try {
      final args = resourceMap(call.arguments);
      if (args['version'] != null && args['version'] != 1) {
        resourceError('unsupported_version');
      }
      if (call.method == 'resources.query') {
        final request = ResourceQuery(args);
        final previous = _latest[request.windowId];
        if (previous != null && request.requestId <= previous) {
          resourceError('cancelled');
        }
        _latest[request.windowId] = request.requestId;
        final revision = revisions[request.kind]!;
        final result = await source.query(request);
        if (_latest[request.windowId] != request.requestId ||
            revisions[request.kind] != revision) {
          resourceError('cancelled');
        }
        return {
          ...result,
          'requestId': request.requestId,
          'revision': revision,
        };
      }
      switch (call.method) {
        case 'gallery.records':
          final ids = (args['ids'] as List).cast<String>();
          if (ids.length > 60) resourceError('invalid_arguments', 'ids');
          final revision = args['revision'] as int;
          if (revision != revisions[FloatingResourceKind.gallery]) {
            resourceError('cancelled');
          }
          final records = await source.galleryRecords(ids);
          if (revision != revisions[FloatingResourceKind.gallery]) {
            resourceError('cancelled');
          }
          return records;
        case 'gallery.viewer':
          return await source.galleryViewer(args);
        case 'resources.counts':
          return await source.counts();
        case 'resources.layout':
          await source.layout(resourceString(args, 'windowId'), args);
          return null;
        case 'resources.preferences':
          await source.preferences(resourceKind(args), args);
          return null;
        case 'resources.searchConfirmed':
          await source.confirmSearch(args['query'] as String);
          return null;
        case 'gallery.export':
          return {
            'uri': (await source.exportGallery(
              resourceString(args, 'id'),
            )).toString(),
          };
        case 'resources.thumbnail':
          final kind = resourceKind(args);
          // Thumbnail identity is per item, independent of query revisions.
          final revision = revisions[kind]!;
          final bytes = await source.thumbnail(
            kind,
            resourceString(args, 'id'),
            revision,
          );
          return bytes;
        case 'resources.detail':
          return await source.detail(
            resourceKind(args),
            resourceString(args, 'id'),
          );
        case 'resources.action':
          await source.action(
            resourceKind(args),
            resourceString(args, 'id'),
            resourceString(args, 'actionId'),
          );
          return null;
        case 'resources.favorite':
          await source.favorite(resourceKind(args), resourceString(args, 'id'));
          return null;
        case 'resources.open':
          await source.open(resourceKind(args), resourceString(args, 'id'));
          return null;
        default:
          resourceError('invalid_arguments', call.method);
      }
    } on GalleryNotInitializedException {
      resourceError('not_ready');
    } on FilterCancelledException {
      resourceError('cancelled');
    } on TypeError {
      resourceError('invalid_arguments');
    } on PlatformException {
      rethrow;
    } catch (error) {
      resourceError('failed', error.toString());
    }
  }
}
