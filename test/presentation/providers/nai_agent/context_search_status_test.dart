import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';

import '../krita/agent_bridge_draft_test.dart'
    show
        MemoryDraftSettings,
        MemoryCharacters,
        EmptyBlocks,
        IdleGeneration,
        OfflineAuth;

class _Settings extends RagSettingsController {
  int builds = 0;
  @override
  RagSettings build() {
    builds++;
    return const RagSettings(
      enabled: true,
      galleryEnabled: true,
      tagsEnabled: true,
      wikiEnabled: true,
      blocksEnabled: true,
    );
  }

  void publish(RagSettings value) => state = value;
}

class _Rag extends RagController {
  int builds = 0;
  bool gpuBusy = false;
  @override
  bool get isGpuBusy => gpuBusy;
  @override
  RagStatus build() {
    builds++;
    return const RagStatus();
  }

  void publish(RagStatus value) => state = value;
}

void main() {
  late Directory root;
  late ProviderContainer container;
  late NaiAgentStudioTools tools;
  late _Settings settings;
  late _Rag rag;
  const ready = RagStatus(indexed: 12, complete: true, phase: 'ready');
  const allReady = RagStatus(
    indexed: 12,
    complete: true,
    phase: 'ready',
    sources: {
      RagSource.gallery: ready,
      RagSource.wiki: ready,
      RagSource.blocks: ready,
    },
  );
  const sources = ['gallery', 'tags', 'wiki', 'blocks'];
  Map<String, String> all(String status) => {
    for (final source in sources) source: status,
  };

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-context-search-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final blocks = PromptBlockStorage(hivePath: root.path);
    await blocks.init();
    settings = _Settings();
    rag = _Rag();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(blocks),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        ragSettingsProvider.overrideWith(() => settings),
        ragControllerProvider.overrideWith(() => rag),
      ],
    );
    tools = container.read(naiAgentStudioFactoryProvider)(root, root, true);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await root.delete(recursive: true);
  });

  Future<Map<String, dynamic>> context([String scope = 'summary']) async {
    final result = await tools.execute('studio_context', {
      'scope': scope,
    }, NaiAgentCancellation());
    return Map<String, dynamic>.from(result['details'] as Map);
  }

  test(
    'summary and draft never create RAG settings or the auto-starting controller',
    () async {
      expect(container.exists(ragSettingsProvider), false);
      expect(container.exists(ragControllerProvider), false);
      final summary = await context();
      final draft = await context('draft');
      expect(summary['search'], all('unknown'));
      expect(draft['search'], summary['search']);
      expect(summary, isNot(contains('draft')));
      expect(draft['draft'], contains('field_versions'));
      expect(container.exists(ragSettingsProvider), false);
      expect(container.exists(ragControllerProvider), false);
      expect(settings.builds, 0);
      expect(rag.builds, 0);
    },
  );

  test(
    'enabled but unread index stays unknown; a disabled source never starts RAG',
    () async {
      container.read(ragSettingsProvider);
      expect((await context())['search'], all('unknown'));
      settings.publish(const RagSettings());
      expect((await context('draft'))['search'], all('disabled'));
      expect(container.exists(ragControllerProvider), false);
      expect(rag.builds, 0);
    },
  );

  test(
    'four compact source states reflect live changes without changing the draft',
    () async {
      container.read(ragSettingsProvider);
      container.read(ragControllerProvider);
      rag.publish(
        const RagStatus(
          indexed: 12,
          complete: true,
          phase: 'ready',
          sources: {
            RagSource.gallery: RagStatus(
              indexed: 3,
              total: 20,
              busy: true,
              phase: 'building',
            ),
            RagSource.wiki: RagStatus(indexKnown: true, phase: 'empty'),
            RagSource.blocks: RagStatus(indexed: 4, error: 'worker_failed'),
          },
        ),
      );
      final before = await context('draft');
      expect(before['search'], {
        'gallery': 'partial',
        'tags': 'ready',
        'wiki': 'not_indexed',
        'blocks': 'error',
      });
      rag.publish(allReady);
      final after = await context('draft');
      expect(after['search'], all('ready'));
      expect(after['draft'], before['draft']);
      expect(after['draft_summary'], before['draft_summary']);
      expect(after['generation'], before['generation']);
      expect(settings.builds, 1);
      expect(rag.builds, 1);
    },
  );

  test(
    'unknown initial state and reconnection are not reported as an empty index',
    () async {
      container.read(ragSettingsProvider);
      container.read(ragControllerProvider);
      expect((await context())['search'], all('unknown'));
      rag.publish(allReady.copyWith(initializing: true));
      expect((await context())['search'], all('unknown'));
      rag.publish(
        const RagStatus(
          indexKnown: true,
          sources: {
            RagSource.gallery: RagStatus(indexKnown: true),
            RagSource.wiki: RagStatus(indexKnown: true),
            RagSource.blocks: RagStatus(indexKnown: true),
          },
        ),
      );
      expect((await context())['search'], all('not_indexed'));
    },
  );

  test(
    'GPU holds and suspension report busy, including before the worker is running',
    () async {
      container.read(ragSettingsProvider);
      container.read(ragControllerProvider);
      rag.gpuBusy = true;
      expect((await context())['search'], all('busy'));
      rag.gpuBusy = false;
      rag.publish(allReady.copyWith(suspended: true));
      expect((await context())['search'], all('busy'));
      rag.publish(allReady);
      expect((await context())['search'], all('ready'));
    },
  );

  test(
    'building indexes distinguish no vectors from a usable partial index',
    () async {
      container.read(ragSettingsProvider);
      container.read(ragControllerProvider);
      rag.publish(
        const RagStatus(
          indexKnown: true,
          busy: true,
          total: 10,
          sources: {
            RagSource.gallery: RagStatus(indexed: 3, partial: true),
            RagSource.wiki: RagStatus(indexed: 3, complete: true, busy: true),
            RagSource.blocks: RagStatus(indexed: 3),
          },
        ),
      );
      expect((await context())['search'], {
        'gallery': 'partial',
        'tags': 'busy',
        'wiki': 'partial',
        'blocks': 'partial',
      });
    },
  );

  test(
    'disabled and resource busy states override old ready counts independently',
    () async {
      container.read(ragSettingsProvider);
      container.read(ragControllerProvider);
      rag.publish(
        allReady.copyWith(
          sources: {
            RagSource.gallery: ready.copyWith(error: 'resource_busy'),
            RagSource.wiki: ready.copyWith(error: 'worker_failed'),
            RagSource.blocks: ready,
          },
        ),
      );
      settings.publish(
        const RagSettings(
          enabled: true,
          galleryEnabled: true,
          tagsEnabled: true,
          wikiEnabled: true,
          blocksEnabled: false,
        ),
      );
      expect((await context())['search'], {
        'gallery': 'busy',
        'tags': 'ready',
        'wiki': 'error',
        'blocks': 'disabled',
      });
    },
  );
}
