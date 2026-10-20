import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/rag/rag_client.dart';
import '../../../core/rag/rag_gallery_search.dart';
import '../../../core/rag/rag_settings.dart';
import '../../../core/rag/rag_text_search.dart';
import '../../../data/services/gallery/gallery_filter_service.dart';
import '../../../data/services/gallery/unified_gallery_service.dart';
import '../rag_provider.dart';
import 'nai_agent_gallery_binding.dart';

/// Read-only adapter over existing vectors. Never enables RAG or builds an index.
class NaiAgentSearchBinding {
  NaiAgentSearchBinding(this.ref, this.workspace, this.loadImage, this.isAlive);

  final Ref ref;
  final Directory workspace;
  final Future<NaiAgentImage> Function(
    Map<String, dynamic>,
    NaiAgentCancellation,
  )
  loadImage;
  final bool Function() isAlive;

  void _check(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
  }

  Map<String, dynamic>? _unavailable(RagSource source) {
    final settings = ref.read(ragSettingsProvider);
    if (!settings.enabled) {
      return {
        'status': 'disabled',
        'message':
            'Local semantic search is off. Enable it in Settings > Semantic Search.',
      };
    }
    if (!settings.enabledFor(source)) {
      return {
        'status': 'not_indexed',
        'message':
            'This source is not enabled in Settings > Semantic Search. No index was created.',
      };
    }
    final controller = ref.read(ragControllerProvider.notifier);
    final status = ref.read(ragControllerProvider).forSource(source);
    if (controller.isGpuBusy ||
        status.suspended ||
        status.error == 'resource_busy') {
      return {
        'status': 'busy',
        'message': 'Local semantic search resources are busy. Retry later.',
      };
    }
    if (status.indexed == 0) {
      return {
        'status': 'not_indexed',
        'message':
            'This source has no vectors. Build its index in Settings > Semantic Search first.',
      };
    }
    return null;
  }

  Future<Map<String, dynamic>> search(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    final request = _SearchRequest.parse(params);
    Map<String, dynamic> result(Map<String, dynamic> value) =>
        naiAgentTextResult({'source': request.source.name, ...value});
    final unavailable = _unavailable(request.source);
    if (unavailable != null) return result(unavailable);
    final before = ref.read(ragControllerProvider).forSource(request.source);
    final controller = ref.read(ragControllerProvider.notifier);
    final cancellation = RagCancellation();
    var finished = false;
    // NaiAgentCancellation has a completion rather than a removable listener.
    // Guard it so completed calls do not retain an active RAG request.
    token.whenCancelled.then((_) {
      if (!finished) cancellation.cancel();
    });
    try {
      final List<Map<String, dynamic>> items;
      switch (request.source) {
        case RagSource.gallery:
          items = await _gallery(request, controller, cancellation, token);
        case RagSource.blocks:
        case RagSource.wiki:
          final hits = await controller.searchText(
            RagTextQuery(source: request.source, query: request.query),
            cancellation: cancellation,
          );
          // Python returns owner IDs, not passage keys: block UUIDs and
          // canonical Wiki tags already match block_query / wiki_query(tags).
          items = [
            for (final hit in hits.take(request.limit))
              {
                'id': hit.id,
                'title': hit.title,
                'snippet': hit.snippet,
                'section': hit.section,
              },
          ];
        case RagSource.tags:
          final hits = await controller.recommend(
            text: '',
            cursor: 0,
            keyword: request.query,
            existing: const {},
            lexical: const [],
            limit: request.limit,
            cancellation: cancellation,
          );
          items = [
            for (final hit in hits.take(request.limit))
              {
                'name': hit.canonicalTag,
                'category': hit.category.name,
                'post_count': hit.postCount,
                'aliases': hit.aliases,
                if (hit.translation != null) 'translation': hit.translation,
                'score': hit.score,
                'origins': hit.retrievalOrigins,
              },
          ];
      }
      _check(token);
      final changed = _unavailable(request.source);
      if (changed != null) return result(changed);
      final after = ref.read(ragControllerProvider).forSource(request.source);
      // Text/tag APIs deliberately swallow worker failures; do not present
      // those failures to the model as successful empty search results.
      if (items.isEmpty && after.error != null) {
        return result({
          'status': 'error',
          'message': 'Local semantic search failed: ${after.error}.',
        });
      }
      return result({
        'status': 'ok',
        'items': items,
        if (before.partial || before.busy || after.partial || after.busy)
          'partial': true,
      });
    } on RagException catch (error) {
      _check(token);
      final changed = _unavailable(request.source);
      return result(
        changed ??
            {
              'status': error.code == 'resource_busy' ? 'busy' : 'error',
              'message':
                  'Local semantic search could not complete: ${error.code}.',
            },
      );
    } finally {
      finished = true;
      cancellation.cancel();
    }
  }

  Future<LocalGalleryService> _service(NaiAgentCancellation token) async {
    // Same native service as gallery_query; do not initialize the screen or
    // modify its visible filters, selection or dataset.
    for (var i = 0; i < 100; i++) {
      _check(token);
      final service = ref.read(galleryServiceProvider);
      if (service is ErrorGalleryService) break;
      if (service.isInitialized) return service;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw const NaiAgentToolError(
      'gallery_unavailable',
      'Gallery is not ready; retry later',
    );
  }

  Future<List<Map<String, dynamic>>> _gallery(
    _SearchRequest request,
    RagController controller,
    RagCancellation cancellation,
    NaiAgentCancellation token,
  ) async {
    final service = await _service(token);
    final scope = await service.getTimelineForFilter(
      FilterCriteria(
        showFavoritesOnly: request.favorites,
        dateStart: request.start,
        dateEnd: request.end,
      ),
    );
    _check(token);
    final allowed = {for (final entry in scope) entry.path: entry};
    File? temporary;
    try {
      var imagePath = '';
      if (request.image.isNotEmpty) {
        // Reuse image_read's original-image validation and ID resolution.
        final image = await loadImage(request.image, token);
        _check(token);
        final relative = request.image['path'];
        final id = request.image['image_id'];
        if (relative is String) {
          imagePath = await _workspacePath(relative);
        } else if (id is String && id.startsWith('gallery:')) {
          final match = RegExp(r'^gallery:([1-9]\d*)$').firstMatch(id);
          final number = match == null ? null : int.tryParse(match[1]!);
          final row = number == null
              ? null
              : await ref
                    .read(naiAgentGalleryDataSourceProvider)
                    .getImageById(number);
          if (row == null ||
              row.isDeleted ||
              (await service.getLibraryRecordsForPaths([
                row.filePath,
              ])).isEmpty) {
            throw const NaiAgentToolError(
              'image_missing',
              'Image is no longer in the library',
            );
          }
          imagePath = await File(row.filePath).resolveSymbolicLinks();
          final roots = await ref.read(ragGalleryRootsProvider)();
          var within = false;
          for (final root in roots) {
            if (p.isWithin(
              await Directory(root).resolveSymbolicLinks(),
              imagePath,
            )) {
              within = true;
              break;
            }
          }
          if (!within) {
            throw const NaiAgentToolError(
              'image_outside_library',
              'Image resolves outside configured library roots',
            );
          }
        } else {
          // Preserve pixels/aspect ratio, unlike precise-reference normalization.
          final bytes = image.bytes;
          final png = await Isolate.run(() {
            final decoded = img.decodeImage(bytes);
            if (decoded == null) {
              throw const NaiAgentToolError(
                'invalid_image',
                'Unable to decode search image',
              );
            }
            return Uint8List.fromList(img.encodePng(decoded));
          });
          _check(token);
          final directory = await _temporaryDirectory();
          final target = File(p.join(directory, '${const Uuid().v4()}.png'));
          await target.create(exclusive: true);
          temporary =
              target; // Only clean up a file this call actually created.
          await temporary.writeAsBytes(png, flush: true);
          imagePath = temporary.path;
        }
      }
      _check(token);
      if (allowed.isEmpty) return [];
      final hits = await controller.searchGallery(
        query: request.query,
        allowed: allowed.keys.toList(),
        image: imagePath,
        mode: request.mode,
        cancellation: cancellation,
      );
      _check(token);
      // Recheck current native membership after IO: deleted/off-root files
      // must not leak out through stale vectors or an old search scope.
      final paths = hits
          .where((h) => allowed.containsKey(h.path))
          .map((h) => h.path)
          .toSet()
          .toList();
      final records = {
        for (final record in await service.getLibraryRecordsForPaths(paths))
          record.path: record,
      };
      final ids = paths.isEmpty
          ? <String, int>{}
          : await ref
                .read(naiAgentGalleryDataSourceProvider)
                .getImageIdsByPaths(paths);
      _check(token);
      final items = <Map<String, dynamic>>[];
      for (final hit in hits) {
        final entry = allowed[hit.path], record = records[hit.path];
        if (entry == null ||
            record == null ||
            ids[hit.path]?.toString() != hit.id ||
            !await File(hit.path).exists()) {
          continue;
        }
        items.add({
          'image_id': 'gallery:${hit.id}',
          'path': hit.path,
          'channel': hit.channel,
          'rank': items.length + 1,
          'source': 'library',
          'file_path': hit.path,
          'bytes': record.size,
          'modified_at': record.modifiedAt.toIso8601String(),
          'favorite': record.isFavorite,
          'model': record.metadata?.model,
          'width': entry.width ?? record.metadata?.width,
          'height': entry.height ?? record.metadata?.height,
        });
        if (items.length == request.limit) break;
      }
      _check(token);
      return items;
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<String> _workspacePath(String relative) async {
    if (p.isAbsolute(relative)) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'Expected workspace-relative path',
      );
    }
    final root = await workspace.resolveSymbolicLinks();
    final resolved = await File(p.join(root, relative)).resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'Image path leaves this workspace',
      );
    }
    return resolved;
  }

  Future<String> _temporaryDirectory() async {
    final root = await workspace.resolveSymbolicLinks();
    var parent = root;
    for (final name in ['.agent', 'search-images']) {
      final directory = Directory(p.join(parent, name));
      if (await FileSystemEntity.type(directory.path, followLinks: false) !=
              FileSystemEntityType.notFound &&
          !p.isWithin(root, await directory.resolveSymbolicLinks())) {
        throw const NaiAgentToolError(
          'path_outside_workspace',
          'Search directory leaves workspace',
        );
      }
      await directory.create();
      parent = await directory.resolveSymbolicLinks();
      if (!p.isWithin(root, parent)) {
        throw const NaiAgentToolError(
          'path_outside_workspace',
          'Search directory leaves workspace',
        );
      }
    }
    return parent;
  }
}

class _SearchRequest {
  const _SearchRequest(
    this.source,
    this.query,
    this.image,
    this.mode,
    this.favorites,
    this.start,
    this.end,
    this.limit,
  );
  final RagSource source;
  final String query;
  final Map<String, dynamic> image;
  final RagGalleryMode mode;
  final bool favorites;
  final DateTime? start, end;
  final int limit;

  static _SearchRequest parse(Map<String, dynamic> params) {
    Never invalid(String message) =>
        throw NaiAgentToolError('invalid_query', message);
    const keys = {
      'source',
      'query',
      'image_id',
      'path',
      'mode',
      'favorites',
      'date_start',
      'date_end',
      'limit',
    };
    if (params.keys.any((key) => !keys.contains(key))) {
      invalid('Unknown search field');
    }
    final source = RagSource.values
        .where((s) => s.name == params['source'])
        .firstOrNull;
    if (source == null) {
      invalid('Expected source gallery, blocks, wiki or tags');
    }
    final query = params.containsKey('query') ? params['query'] : '';
    if (query is! String || query.length > 500) {
      invalid('Expected query of at most 500 characters');
    }
    final image = <String, dynamic>{};
    for (final key in ['image_id', 'path']) {
      if (!params.containsKey(key)) continue;
      final value = params[key];
      if (value is! String || value.trim().isEmpty) {
        invalid('Expected nonempty $key');
      }
      image[key] = value;
    }
    if (image.length > 1) invalid('Provide only one image_id or path');
    if (query.trim().isEmpty && image.isEmpty) {
      invalid('Provide a query or image');
    }
    if (source != RagSource.gallery &&
        params.keys.any(
          (k) => {
            'image_id',
            'path',
            'mode',
            'favorites',
            'date_start',
            'date_end',
          }.contains(k),
        )) {
      invalid('Images and gallery filters/mode require source=gallery');
    }
    final modeName = params.containsKey('mode')
        ? params['mode']
        : (image.isEmpty ? 'mixed' : 'visual');
    final mode = RagGalleryMode.values
        .where((m) => m.name == modeName)
        .firstOrNull;
    if (mode == null) invalid('Expected mode mixed, visual or parameters');
    final favorites = params.containsKey('favorites')
        ? params['favorites']
        : false;
    if (favorites is! bool) invalid('Expected boolean favorites');
    DateTime? date(String key) {
      if (!params.containsKey(key)) return null;
      final value = params[key];
      if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
        invalid('Expected YYYY-MM-DD for $key');
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null ||
          parsed.toIso8601String().substring(0, 10) != value) {
        invalid('Invalid calendar date for $key');
      }
      return parsed;
    }

    final start = date('date_start'), end = date('date_end');
    if (start != null && end != null && start.isAfter(end)) {
      invalid('date_start exceeds date_end');
    }
    final limit = params.containsKey('limit') ? params['limit'] : 20;
    if (limit is! int || limit < 1 || limit > 50) {
      invalid('Expected limit 1..50');
    }
    return _SearchRequest(
      source,
      query.trim(),
      image,
      mode,
      favorites,
      start,
      end,
      limit,
    );
  }
}
