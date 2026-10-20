import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_gallery_search.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_gallery_binding.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_search_binding.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import '../../../helpers/fake_local_gallery_service.dart';

class _Source extends Mock implements GalleryDataSource {}

class _Settings extends RagSettingsController {
  _Settings([this.initial]);
  final RagSettings? initial;
  @override
  RagSettings build() =>
      initial ??
      const RagSettings(
        enabled: true,
        wikiEnabled: true,
        blocksEnabled: true,
        galleryEnabled: true,
      );
  @override
  Future<void> update(RagSettings value) async => state = value;
}

/// No Python process or model: exercise the real controller's wire mapping.
class _Client extends Fake implements RagClient {
  bool fallback = true;
  @override
  bool isClosed = false;
  @override
  Stream<Map<String, dynamic>> get events => const Stream.empty();
  @override
  Future<Map<String, dynamic>> configure(
    Map<String, dynamic> params, {
    RagCancellation? cancellation,
    Duration timeout = const Duration(minutes: 15),
    Duration idleTimeout = const Duration(minutes: 2),
    void Function(Map<String, dynamic>)? onProgress,
  }) async => {
    'sources': {
      for (final source in params['sources'] as List)
        source: {'indexed': 10, 'total': 10, 'complete': true},
    },
    'jobs': [],
  };
  @override
  Future<Map<String, dynamic>> request(
    String op, [
    Map<String, dynamic> params = const {},
    RagCancellation? cancellation,
    Duration timeout = const Duration(seconds: 60),
  ]) async {
    if (op != 'search' && op != 'text_search') {
      throw StateError('Unexpected operation: $op');
    }
    return {'items': [], if (fallback) 'fallback': 'resource_busy'};
  }

  @override
  Future<void> close() async => isClosed = true;
}

class _Rag extends RagController {
  int calls = 0;
  String? image, query;
  List<String>? allowed;
  RagGalleryMode? mode;
  RagTextQuery? textQuery;
  RagCancellation? cancellation;
  Object? failure;
  Future<void> Function()? onSearch;
  List<RagGalleryHit> gallery = [];
  @override
  RagStatus build() => const RagStatus(
    indexed: 10,
    phase: 'ready',
    complete: true,
    sources: {
      RagSource.gallery: RagStatus(indexed: 10, phase: 'ready', complete: true),
      RagSource.blocks: RagStatus(indexed: 10, phase: 'ready', complete: true),
      RagSource.wiki: RagStatus(indexed: 10, phase: 'ready', complete: true),
    },
  );
  void status(RagStatus value) => state = value;
  Future<void> _search(RagCancellation token) async {
    calls++;
    cancellation = token;
    await onSearch?.call();
    if (failure != null) throw failure!;
  }

  @override
  Future<List<RagGalleryHit>> searchGallery({
    required String query,
    required List<String> allowed,
    required RagCancellation cancellation,
    String image = '',
    RagGalleryMode mode = RagGalleryMode.mixed,
  }) async {
    this.query = query;
    this.image = image;
    this.allowed = allowed;
    this.mode = mode;
    await _search(cancellation);
    return gallery;
  }

  @override
  Future<List<RagSearchHit>> searchText(
    RagTextQuery query, {
    required RagCancellation cancellation,
  }) async {
    textQuery = query;
    await _search(cancellation);
    return [
      RagSearchHit(
        id: query.source == RagSource.blocks ? 'block-uuid' : 'blue_eyes',
        title: 'Blue eyes',
        snippet: 'Saved local passage',
        section: 'article',
      ),
    ];
  }

  @override
  Future<List<CompletionCandidate>> recommend({
    required String text,
    required int cursor,
    required Set<String> existing,
    required List<CompletionCandidate> lexical,
    required RagCancellation cancellation,
    bool negative = false,
    String keyword = '',
    int limit = 40,
  }) async {
    expect(text, '');
    expect(cursor, 0);
    expect(existing, isEmpty);
    expect(lexical, isEmpty);
    query = keyword;
    await _search(cancellation);
    return const [
      CompletionCandidate(
        canonicalTag: 'blue_eyes',
        category: TagCategory.general,
        postCount: 123,
        aliases: ['blue_eye'],
        translation: '蓝眼',
        score: .9,
        retrievalOrigins: ['semantic'],
        matchKind: CompletionMatchKind.related,
        sources: {CompletionSourceKind.base},
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root, library;
  late ProviderContainer container;
  late NaiAgentSearchBinding binding;
  late NaiAgentStudioTools studio;
  late _Rag rag;
  late _Source source;
  late FakeLocalGalleryService service;
  late List<LocalImageRecord> records;
  late Uint8List png;
  late bool alive;
  late int imageLoads;

  Future<Map<String, dynamic>> search(
    Map<String, dynamic> params, [
    NaiAgentCancellation? token,
  ]) async =>
      (await binding.search(params, token ?? NaiAgentCancellation()))['details']
          as Map<String, dynamic>;
  Matcher error(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-search-');
    library = await Directory(p.join(root.path, 'library')).create();
    png = Uint8List.fromList(img.encodePng(img.Image(width: 7, height: 5)));
    alive = true;
    imageLoads = 0;
    records = [];
    for (var i = 0; i < 3; i++) {
      final file = await File(p.join(library.path, '$i.png')).writeAsBytes(png);
      records.add(
        LocalImageRecord(
          path: file.path,
          size: png.length,
          modifiedAt: DateTime(2026, 10, 19 + i, 12),
          isFavorite: i < 2,
          metadata: const NaiImageMetadata(
            model: 'nai-diffusion-4',
            width: 7,
            height: 5,
          ),
        ),
      );
    }
    service = FakeLocalGalleryService(records);
    source = _Source();
    when(() => source.getImageIdsByPaths(any())).thenAnswer(
      (_) async => {
        for (var i = 0; i < records.length; i++) records[i].path: i + 1,
      },
    );
    when(() => source.getImageById(1)).thenAnswer(
      (_) async => GalleryImageRecord(
        id: 1,
        filePath: records[0].path,
        fileName: '0.png',
        fileSize: png.length,
        createdAt: records[0].modifiedAt,
        modifiedAt: records[0].modifiedAt,
        indexedAt: records[0].modifiedAt,
        dateYmd: 20261019,
      ),
    );
    rag = _Rag();
    final provider = Provider(
      (ref) => NaiAgentSearchBinding(ref, root, (params, token) async {
        imageLoads++;
        return studio.loadImage(params, token);
      }, () => alive),
    );
    container = ProviderContainer(
      overrides: [
        ragSettingsProvider.overrideWith(_Settings.new),
        ragControllerProvider.overrideWith(() => rag),
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
        ),
        naiAgentGalleryDataSourceProvider.overrideWithValue(source),
        ragGalleryRootsProvider.overrideWithValue(() async => [library.path]),
      ],
    );
    studio = NaiAgentStudioTools(
      workspaceDirectory: root,
      allowsImages: false,
      readDraft: () => BridgeDraftSnapshot(fields: {}, documents: {}),
      readSummary: () => {},
      isGenerating: () => false,
      backupDraft: (_) async => '',
      writeDraft: (_) => [],
      readImage: (id) => {'selected', 'draft:source', 'history-id'}.contains(id)
          ? NaiAgentImage(id: id, bytes: png)
          : null,
      loadImageById: (id, token) async =>
          id == 'gallery:1' ? NaiAgentImage(id: id, bytes: png) : null,
    );
    binding = container.read(provider);
    rag.gallery = [
      RagGalleryHit(id: '2', path: records[1].path, channel: 'mixed'),
      RagGalleryHit(id: '1', path: records[0].path, channel: 'visual'),
    ];
  });
  tearDown(() async {
    container.dispose();
    await root.delete(recursive: true);
  });

  test(
    'gallery scopes first, preserves semantic rank, metadata and limit without changing UI',
    () async {
      final result = await search({
        'source': 'gallery',
        'query': 'rain',
        'favorites': true,
        'date_start': '2026-10-19',
        'date_end': '2026-10-19',
        'limit': 1,
      });
      expect(result['status'], 'ok');
      expect(rag.allowed, [records[0].path]);
      expect(rag.mode, RagGalleryMode.mixed);
      final item = (result['items'] as List).single as Map;
      expect(item, containsPair('image_id', 'gallery:1'));
      expect(item, containsPair('path', records[0].path));
      expect(item, containsPair('rank', 1));
      expect(item, containsPair('model', 'nai-diffusion-4'));
      expect(item, containsPair('favorite', true));
      expect(item, containsPair('width', 7));
      expect(
        item,
        containsPair('modified_at', records[0].modifiedAt.toIso8601String()),
      );
      expect(service.applyFilterCount, 0);
      expect(service.setSortCount, 0);
      expect(service.refreshCount, 0);
      expect(imageLoads, 0);
    },
  );

  for (final s in ['blocks', 'wiki']) {
    test('$s returns owner ID usable by native detail query', () async {
      final result = await search({'source': s, 'query': 'blue eyes'});
      expect(rag.textQuery!.source.name, s);
      expect(rag.textQuery!.query, 'blue eyes');
      expect((result['items'] as List).single, {
        'id': s == 'blocks' ? 'block-uuid' : 'blue_eyes',
        'title': 'Blue eyes',
        'snippet': 'Saved local passage',
        'section': 'article',
      });
    });
  }

  test(
    'tags uses recommend keyword/manual tag_search, returns canonical tag evidence',
    () async {
      final result = await search({'source': 'tags', 'query': '蓝色眼睛'});
      expect(rag.query, '蓝色眼睛');
      expect((result['items'] as List).single, {
        'name': 'blue_eyes',
        'category': 'general',
        'post_count': 123,
        'aliases': ['blue_eye'],
        'translation': '蓝眼',
        'score': .9,
        'origins': ['semantic'],
      });
    },
  );

  test('gallery ID uses original disk path without a temporary copy', () async {
    await search({'source': 'gallery', 'image_id': 'gallery:1'});
    expect(rag.image, await File(records[0].path).resolveSymbolicLinks());
    expect(rag.mode, RagGalleryMode.visual);
    expect(
      await Directory(p.join(root.path, '.agent', 'search-images')).exists(),
      false,
    );
  });

  test('attachment uses original safe disk path and explicit mode', () async {
    final file = await File(
      p.join(root.path, 'attachment.png'),
    ).writeAsBytes(png);
    await search({
      'source': 'gallery',
      'path': 'attachment.png',
      'mode': 'parameters',
    });
    expect(rag.image, await file.resolveSymbolicLinks());
    expect(rag.mode, RagGalleryMode.parameters);
    expect(await file.exists(), true);
  });

  for (final id in ['selected', 'draft:source', 'history-id']) {
    test('$id is materialized as PNG then removed', () async {
      rag.onSearch = () async {
        expect(
          p.basename(rag.image!),
          matches(RegExp(r'^[a-f0-9-]{36}\.png$')),
        );
        expect(
          p.isWithin(
            p.join(
              await root.resolveSymbolicLinks(),
              '.agent',
              'search-images',
            ),
            rag.image!,
          ),
          true,
        );
        final decoded = img.decodePng(await File(rag.image!).readAsBytes())!;
        expect((decoded.width, decoded.height), (7, 5));
      };
      await search({'source': 'gallery', 'image_id': id});
      expect(await File(rag.image!).exists(), false);
    });
  }

  test('temporary image is removed on worker busy failure', () async {
    rag.failure = const RagException('resource_busy');
    final result = await search({'source': 'gallery', 'image_id': 'selected'});
    expect(result['status'], 'busy');
    expect(await File(rag.image!).exists(), false);
  });

  test('cancellation propagates to RAG and removes temporary image', () async {
    final token = NaiAgentCancellation();
    rag.onSearch = () async {
      token.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(rag.cancellation!.isCancelled, true);
    };
    await expectLater(
      search({'source': 'gallery', 'image_id': 'selected'}, token),
      error('cancelled'),
    );
    expect(await File(rag.image!).exists(), false);
  });

  test(
    'disabled does not initialize controller, gallery or load image',
    () async {
      await container
          .read(ragSettingsProvider.notifier)
          .update(const RagSettings());
      expect(container.exists(ragControllerProvider), false);
      final result = await search({
        'source': 'gallery',
        'image_id': 'selected',
      });
      expect(result['status'], 'disabled');
      expect(result['message'], contains('Settings > Semantic Search'));
      expect(container.exists(ragControllerProvider), false);
      expect(imageLoads, 0);
    },
  );

  test('source disabled and zero vectors both return not_indexed', () async {
    await container
        .read(ragSettingsProvider.notifier)
        .update(const RagSettings(enabled: true));
    expect(
      (await search({'source': 'wiki', 'query': 'rain'}))['status'],
      'not_indexed',
    );
    await container
        .read(ragSettingsProvider.notifier)
        .update(const RagSettings(enabled: true, wikiEnabled: true));
    container.read(ragControllerProvider);
    rag.status(const RagStatus());
    expect(
      (await search({'source': 'wiki', 'query': 'rain'}))['status'],
      'not_indexed',
    );
    expect(rag.calls, 0);
  });

  test(
    'GPU hold before worker startup reports busy even without suspended status',
    () async {
      container.read(ragControllerProvider);
      await rag.suspendForGpu();
      expect(container.read(ragControllerProvider).suspended, false);
      for (final s in ['gallery', 'blocks', 'wiki', 'tags']) {
        expect(
          (await search({'source': s, 'query': 'rain'}))['status'],
          'busy',
        );
      }
      expect(rag.calls, 0);
      await rag.releaseGpu();
    },
  );

  for (final s in ['gallery', 'blocks', 'wiki', 'tags']) {
    test('$s worker resource_busy is a status, not empty success', () async {
      rag.failure = const RagException('resource_busy');
      expect((await search({'source': s, 'query': 'rain'}))['status'], 'busy');
    });
  }

  test(
    'partially built usable index returns results with partial true',
    () async {
      container.read(ragControllerProvider);
      rag.status(
        const RagStatus(
          sources: {
            RagSource.blocks: RagStatus(
              indexed: 3,
              phase: 'building',
              busy: true,
            ),
          },
        ),
      );
      final result = await search({'source': 'blocks', 'query': 'rain'});
      expect(result['status'], 'ok');
      expect(result['partial'], true);
      expect(result['items'], isNotEmpty);
    },
  );

  test(
    'rechecks live membership and IDs; excludes stale/out-of-scope hits',
    () async {
      rag.gallery = [
        RagGalleryHit(id: 'wrong-id', path: records[0].path, channel: 'visual'),
        RagGalleryHit(
          id: '999',
          path: p.join(root.path, 'private.png'),
          channel: 'visual',
        ),
        RagGalleryHit(id: '2', path: records[1].path, channel: 'visual'),
      ];
      final result = await search({'source': 'gallery', 'query': 'rain'});
      expect((result['items'] as List).single['image_id'], 'gallery:2');
    },
  );

  test('attachment traversal follows image_read containment rules', () async {
    final outside = await File(
      p.join(root.parent.path, '${p.basename(root.path)}-outside.png'),
    ).writeAsBytes(png);
    try {
      await expectLater(
        search({'source': 'gallery', 'path': '../${p.basename(outside.path)}'}),
        error('path_outside_workspace'),
      );
      expect(rag.calls, 0);
    } finally {
      await outside.delete();
    }
  });

  for (final s in ['wiki', 'tags']) {
    test(
      'real controller propagates $s worker fallback without poisoning later searches',
      () async {
        container.dispose();
        final client = _Client();
        final python = await File(
          p.join(root.path, 'fake-python'),
        ).writeAsString('not executable');
        final provider = Provider(
          (ref) =>
              NaiAgentSearchBinding(ref, root, studio.loadImage, () => true),
        );
        container = ProviderContainer(
          overrides: [
            ragSettingsProvider.overrideWith(
              () => _Settings(
                RagSettings(
                  enabled: true,
                  wikiEnabled: true,
                  embedding: 'injected',
                  reranker: 'injected',
                  python: python.path,
                ),
              ),
            ),
            ragDirectoryProvider.overrideWithValue(() async => root),
            ragSourcePathsProvider.overrideWithValue(
              () async => (catalog: '', runtime: '', wiki: ''),
            ),
            ragTagSemanticsPathsProvider.overrideWithValue(
              () async => (base: '', supplements: ''),
            ),
            ragWikiTranslationsPathProvider.overrideWithValue(() async => ''),
            ragClientStarterProvider.overrideWithValue(
              ({required String python, required Directory directory}) async =>
                  client,
            ),
          ],
        );
        final controller = container.read(ragControllerProvider.notifier);
        await controller.refresh();
        binding = container.read(provider);
        expect(
          (await search({'source': s, 'query': 'rain'}))['status'],
          'busy',
        );
        expect(
          container
              .read(ragControllerProvider)
              .forSource(s == 'wiki' ? RagSource.wiki : RagSource.tags)
              .error,
          isNull,
        );
        client.fallback = false;
        expect((await search({'source': s, 'query': 'rain'}))['status'], 'ok');
      },
    );
  }

  for (final params in <Map<String, dynamic>>[
    {'source': 'gallery'},
    {'source': 'gallery', 'query': '   '},
    {'source': 'blocks', 'image_id': 'selected'},
    {'source': 'wiki', 'query': 'rain', 'path': 'attachment.png'},
    {'source': 'tags', 'query': 'rain', 'mode': 'mixed'},
    {
      'source': 'gallery',
      'query': 'rain',
      'image_id': 'selected',
      'path': 'a.png',
    },
    {'source': 'unknown', 'query': 'rain'},
    {'source': 'gallery', 'query': 'x' * 501},
    {'source': 'gallery', 'query': 'rain', 'limit': 0},
    {'source': 'gallery', 'query': 'rain', 'limit': 51},
    {'source': 'gallery', 'query': 'rain', 'limit': 1.5},
    {'source': 'gallery', 'query': 'rain', 'favorites': 'true'},
    {'source': 'gallery', 'query': 'rain', 'date_start': '2026-02-30'},
    {
      'source': 'gallery',
      'query': 'rain',
      'date_start': '2026-10-20',
      'date_end': '2026-10-19',
    },
    {'source': 'gallery', 'query': 'rain', 'mode': 'other'},
    {'source': 'gallery', 'query': null},
  ]) {
    test('invalid parameters rejected before RAG: $params', () async {
      await expectLater(search(params), error('invalid_query'));
      expect(rag.calls, 0);
      expect(imageLoads, 0);
    });
  }
}
