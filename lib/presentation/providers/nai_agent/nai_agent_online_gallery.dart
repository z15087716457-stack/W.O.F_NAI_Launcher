import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/api_constants.dart';
import '../../utils/metadata_import_applier.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/attachment_image.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/utils/gallery_path_utils.dart';
import '../../../data/datasources/remote/online_gallery/gallery_source_adapter.dart';
import '../../../data/models/online_gallery/gallery_item.dart';
import '../../../data/models/online_gallery/gallery_source.dart';
import '../../../data/repositories/gallery_folder_repository.dart';
import '../../../data/services/gallery/online_gallery_download_service.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../local_gallery_provider.dart';
import '../online_gallery_blacklist_provider.dart';
import '../online_gallery_media_provider.dart';
import '../online_gallery_provider.dart';

final onlineGalleryLibraryDirectoryProvider =
    Provider<Future<Directory> Function()>(
      (ref) => () async {
        final repo = GalleryFolderRepository.instance;
        final output = await repo.getRootPath();
        final sources = await repo.getSourcePaths();
        if (output != null &&
            sources.any((root) => galleryPathIsWithin(root, output))) {
          return Directory(output).create(recursive: true);
        }
        for (final root in sources) {
          final directory = Directory(root);
          if (await directory.exists()) return directory;
        }
        throw const NaiAgentToolError(
          'library_unavailable',
          'Configure an available local gallery folder or use workspace.',
        );
      },
    );

typedef _OnlinePage = ({GalleryDetail detail, int page});

class NaiAgentOnlineGallery {
  NaiAgentOnlineGallery(this.ref, Directory workspace, this.alive)
    : files = AgentWorkspaceFiles(workspace);
  final Ref ref;
  final AgentWorkspaceFiles files;
  final bool Function() alive;
  List<GalleryItem> _lastResults = const [];

  OnlineGalleryNotifier get gallery =>
      ref.read(onlineGalleryNotifierProvider.notifier);
  OnlineGalleryDownloadService get downloads =>
      ref.read(onlineGalleryDownloadServiceProvider);

  void _check(NaiAgentCancellation token) {
    token.check();
    if (!alive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
  }

  GallerySourceId _source(Object? value) =>
      GallerySourceId.values.where((s) => s.key == value).firstOrNull ??
      (throw const NaiAgentToolError(
        'invalid_source',
        'Unknown online gallery source',
      ));

  Future<Set<String>> _blacklist(NaiAgentCancellation token) async {
    await ref
        .read(onlineGalleryBlacklistNotifierProvider.notifier)
        .ensureInitialized();
    _check(token);
    return ref.read(onlineGalleryBlacklistNotifierProvider).effectiveTags;
  }

  Map<String, dynamic> _work(GalleryItem item, int page) => {
    'image_id': 'online:${item.stableKey}:$page',
    'source': item.sourceId.key,
    'source_url': item.postUrl,
    'page': page,
    'page_count': item.mediaCount,
    if (item.title != null) 'title': item.title,
    if (item.author != null) 'author': item.author,
    if (item.aiType != null) 'ai_type': item.aiType,
    if (item.rating != null && item.sourceId.capabilities.supportsRatings)
      'rating': item.rating,
  };

  Map<String, dynamic> _metadata(_OnlinePage work) {
    final (:detail, :page) = work;
    final media = detail.media[page - 1];
    final parameters = media.naiMetadata;
    final model = parameters == null
        ? null
        : MetadataImportApplier.resolveImportableModel(parameters);
    final generation = <String, dynamic>{
      if (parameters != null) ...{
        if (model != null) 'model': model,
        if (parameters.width ?? (media.width > 0 ? media.width : null)
            case final n?)
          'width': n,
        if (parameters.height ?? (media.height > 0 ? media.height : null)
            case final n?)
          'height': n,
        if (parameters.seed case final n?) 'seed': n,
        if (parameters.steps case final n?) 'steps': n,
        if (parameters.scale case final n?) 'cfg_scale': n,
        if (parameters.sampler case final s?) 'sampler': s,
        if (parameters.noiseSchedule case final s?) 'noise_schedule': s,
        if (parameters.cfgRescale case final n?) 'cfg_rescale': n,
        if (parameters.varietyPlus case final b?) 'variety_plus': b,
        if (parameters.smea != null || parameters.smeaDyn != null)
          'smea_auto': false,
        if (parameters.smea case final b?) 'smea': b,
        if (parameters.smeaDyn case final b?) 'smea_dyn': b,
        if (MetadataImportApplier.recordedQualityPreset(parameters)
            case final p?)
          'quality_preset': p.bridgeValue,
        if (MetadataImportApplier.recordedUcPreset(parameters) case final p?)
          'uc_preset': UcPresets.toApiValue(p),
      },
    };
    return {
      ..._work(detail.item, page),
      'page_count': detail.media.length,
      'tags': detail.item.tags,
      if (detail.description != null) 'description': detail.description,
      if (media.width > 0) 'width': media.width,
      if (media.height > 0) 'height': media.height,
      if (media.prompt != null) 'prompt': media.prompt,
      if (media.negativePrompt != null) 'negative_prompt': media.negativePrompt,
      if (parameters != null && parameters.characterPrompts.isNotEmpty)
        'character_prompts': parameters.characterPrompts,
      if (parameters != null && parameters.characterNegativePrompts.isNotEmpty)
        'character_negative_prompts': parameters.characterNegativePrompts,
      ...media.metadata,
      if (detail.item.sourceId == GallerySourceId.aiTag ||
          parameters?.characterUseCoords != null)
        'use_coords': parameters?.characterUseCoords,
      if (parameters != null && parameters.characterUseCoords == true)
        'positions': [
          for (var j = 0; j < parameters.characterPrompts.length; j++)
            if (parameters.characterInfos.elementAtOrNull(j) case final info?
                when info.centerX != null && info.centerY != null)
              {'x': info.centerX, 'y': info.centerY}
            else
              null,
        ],
      if (generation.isNotEmpty) 'generation': generation,
      if (model != null &&
          parameters != null &&
          generation.containsKey('quality_preset'))
        'editable_prompt': MetadataImportApplier.resolveImportedPrompt(
          parameters,
          importQualityPreset: true,
          currentModel: model,
        ),
      if (model != null &&
          parameters != null &&
          generation.containsKey('uc_preset'))
        'editable_negative_prompt':
            MetadataImportApplier.resolveImportedNegativePrompt(
              parameters,
              importUcPreset: true,
              currentModel: model,
            ),
    };
  }

  Future<_OnlinePage> _resolve(
    Object? id,
    Object? requestedPage,
    NaiAgentCancellation token,
  ) async {
    GalleryItem item;
    int page;
    if (id == null) {
      final selection = ref.read(onlineGallerySelectionProvider);
      item =
          selection.item ??
          (throw const NaiAgentToolError(
            'no_selection',
            'Select a work in the online gallery or search first.',
          ));
      page = selection.page;
    } else {
      final match = id is String
          ? RegExp(
              r'^online:([a-z_]+):([1-9][0-9]*):([1-9][0-9]*)$',
            ).firstMatch(id)
          : null;
      final workId = int.tryParse(match?[2] ?? '');
      final number = int.tryParse(match?[3] ?? '');
      if (match == null || workId == null || number == null) {
        throw const NaiAgentToolError(
          'invalid_image',
          'Use an image_id returned by online_gallery.',
        );
      }
      final source = _source(match[1]);
      item =
          _lastResults
              .where((work) => work.id == workId && work.sourceId == source)
              .firstOrNull ??
          GalleryItem(id: workId, sourceId: source);
      page = number;
    }
    if (requestedPage != null) {
      if (requestedPage is! int || requestedPage < 1) {
        throw const NaiAgentToolError('invalid_page', 'Pages start at 1.');
      }
      page = requestedPage;
    }
    final blacklist = await _blacklist(token);
    final detail = await gallery.loadDetail(item);
    _check(token);
    if (detail.item.tags.any(
      (tag) =>
          blacklist.contains(tag.trim().toLowerCase().replaceAll(' ', '_')),
    )) {
      throw const NaiAgentToolError(
        'filtered',
        'This work is excluded by the gallery blacklist.',
      );
    }
    if (page > detail.media.length) {
      throw const NaiAgentToolError(
        'invalid_page',
        'No such page in this work.',
      );
    }
    return (detail: detail, page: page);
  }

  Future<Map<String, dynamic>> _search(
    Map<String, dynamic> args,
    NaiAgentCancellation token,
  ) async {
    final source = args['source'] == null
        ? ref.read(onlineGalleryNotifierProvider).currentSourceId
        : _source(args['source']);
    final query = args['query'] ?? '';
    final prompt = args['prompt'] ?? '';
    final limit = args['limit'] ?? 8;
    final cursor = args['cursor'] ?? '1';
    final match = cursor is String
        ? RegExp(r'^([ab]?[1-9][0-9]*)(?:/([0-9]+))?$').firstMatch(cursor)
        : null;
    final offset = int.tryParse(match?[2] ?? '0');
    if (match == null ||
        offset == null ||
        limit is! int ||
        limit < 1 ||
        limit > 20 ||
        query is! String ||
        prompt is! String ||
        query.length > 500 ||
        prompt.length > 500) {
      throw const NaiAgentToolError(
        'invalid_search',
        'Use a returned cursor, limit 1..20 and text up to 500 characters.',
      );
    }
    if (prompt.isNotEmpty && !source.capabilities.supportsPromptQuery) {
      throw const NaiAgentToolError(
        'unsupported_filter',
        'Prompt search is available on AI TAG.',
      );
    }
    final sourceCursor = match[1]!;
    final blacklist = await _blacklist(token);
    final cancel = CancelToken();
    var finished = false;
    token.whenCancelled.then((_) {
      if (!finished) cancel.cancel();
    });
    late final GalleryPage page;
    try {
      page = await gallery.searchPage(
        source: source,
        query: query,
        prompt: prompt,
        cursor: sourceCursor,
        blacklist: blacklist,
        cancelToken: cancel,
      );
    } finally {
      finished = true;
      _check(token);
    }
    final items = page.items.skip(offset).take(limit).toList();
    _lastResults = items;
    final end = offset + items.length;
    return {
      'source': source.key,
      'items': [
        for (final item in items)
          {..._work(item, 1), 'tags': item.tags.take(16).toList()},
      ],
      'next_cursor': end < page.items.length
          ? '$sourceCursor/$end'
          : page.hasMore && page.nextCursor != sourceCursor
          ? page.nextCursor
          : null,
    };
  }

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> args,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    try {
      switch (args['action']) {
        case 'search':
          return naiAgentTextResult(await _search(args, token));
        case 'current':
          return naiAgentTextResult(
            _metadata(await _resolve(null, null, token)),
          );
        case 'detail':
          return naiAgentTextResult(
            _metadata(await _resolve(args['image_id'], args['page'], token)),
          );
        case 'download':
          final target = args['destination'] ?? 'workspace';
          if (target != 'workspace' && target != 'library') {
            throw const NaiAgentToolError(
              'invalid_destination',
              'Choose workspace or library.',
            );
          }
          final work = await _resolve(args['image_id'], args['page'], token);
          return naiAgentTextResult(
            await _download(
              work,
              target == 'library',
              args['all_pages'] == true,
              token,
            ),
          );
        default:
          throw const NaiAgentToolError(
            'invalid_action',
            'Choose current, search, detail or download.',
          );
      }
    } on GallerySourceException catch (error) {
      throw NaiAgentToolError(
        error.code.name,
        'Online gallery request failed: ${error.code.name}',
      );
    }
  }

  String _originalUrl(GalleryItem item, GalleryMedia media) {
    final url = item.sourceId == GallerySourceId.aiTag
        ? media.downloadUrl
        : item.fileUrl;
    if (item.isVideo || url == null || url.isEmpty) {
      throw const NaiAgentToolError(
        'original_unavailable',
        'The source has no downloadable original image.',
      );
    }
    return url;
  }

  Future<NaiAgentImage> loadImage(
    String id,
    NaiAgentCancellation token, {
    required bool preview,
  }) async {
    final work = await _resolve(id, null, token);
    final item = work.detail.item;
    final media = work.detail.media[work.page - 1];
    final url = !preview
        ? _originalUrl(item, media)
        : item.isVideo
        ? media.previewUrl
        : [
            media.displayUrl,
            media.previewUrl,
            media.downloadUrl,
          ].firstWhere((u) => u.isNotEmpty, orElse: () => '');
    if (url.isEmpty) {
      throw const NaiAgentToolError(
        'image_unavailable',
        'No preview is available.',
      );
    }
    final bytes = await downloads.bytesForUrl(url);
    _check(token);
    return NaiAgentImage(
      id: id,
      bytes: bytes,
      metadata: {
        ..._metadata(work),
        'representation': preview ? 'online_preview' : 'original',
      },
    );
  }

  Future<Map<String, dynamic>> _download(
    _OnlinePage work,
    bool library,
    bool all,
    NaiAgentCancellation token,
  ) async {
    final detail = work.detail;
    final item = detail.item;
    final directory = library
        ? await ref.read(onlineGalleryLibraryDirectoryProvider)()
        : null;
    final saved = <Map<String, dynamic>>[];
    final failures = <Map<String, dynamic>>[];
    final first = all ? 1 : work.page;
    final last = all ? detail.media.length : work.page;
    int? indexed;
    try {
      for (var page = first; page <= last; page++) {
        _check(token);
        final media = detail.media[page - 1];
        try {
          final bytes = await downloads.bytesForUrl(_originalUrl(item, media));
          _check(token);
          final mime = agentImageMime(bytes);
          if (mime == null) {
            throw const NaiAgentToolError(
              'invalid_image',
              'Source did not return a supported image.',
            );
          }
          final extension = mime == 'image/jpeg' ? 'jpg' : mime.substring(6);
          final name = p.setExtension(
            OnlineGalleryDownloadService.fileName(item, media, page - 1),
            '.$extension',
          );
          if (library && !isGalleryIndexableImage(name)) {
            throw const NaiAgentToolError(
              'unsupported_format',
              'Use workspace for this image format.',
            );
          }
          final path = directory == null
              ? await files.export(name, bytes, () => _check(token))
              : await downloads.saveBytes(bytes, directory.path, name);
          saved.add({
            'page': page,
            'image_id': 'online:${item.stableKey}:$page',
            'path': path,
          });
        } on NaiAgentToolError catch (e) {
          _check(token);
          failures.add({'page': page, 'code': e.code, 'message': e.message});
        } on Exception {
          _check(token);
          failures.add({'page': page, 'code': 'download_failed'});
        }
      }
    } finally {
      if (library && saved.isNotEmpty && alive()) {
        indexed = await ref
            .read(localGalleryNotifierProvider.notifier)
            .addNewlySavedImages([
              for (final row in saved) row['path'] as String,
            ]);
      }
    }
    return {
      'ok': failures.isEmpty,
      'source_url': item.postUrl,
      'destination': library ? 'library' : 'workspace',
      'files': saved,
      'failures': failures,
      if (indexed != null) 'indexed': indexed,
    };
  }
}
