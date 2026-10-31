import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/cooccurrence_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/database/datasources/cooccurrence_data_source.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_knowledge_tools.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';

import '../../../helpers/fetch_test_server.dart';

class _Catalog extends TagCatalogRepository {
  final records = {
    for (final name in [
      'rain',
      'holding_umbrella',
      'umbrella',
      'wet',
      'solo',
      'some_character',
    ])
      name: TagCatalogRecord(
        canonicalTag: name,
        category: name == 'some_character'
            ? TagCategory.character
            : TagCategory.general,
        postCount: name == 'solo' ? 10000000 : 10000,
      ),
  };
  @override
  Future<Map<String, TagCatalogRecord>> recordsByCanonicalTag(
    Iterable<String> tags,
  ) async => {
    for (final tag in tags)
      if (records[tag] case final record?) tag: record,
  };
  @override
  Future<Map<String, CompletionCandidate>> exactAliases(
    Iterable<String> tags,
  ) async => {
    if (tags.contains('old_rain'))
      'old_rain': const CompletionCandidate(
        canonicalTag: 'rain',
        category: TagCategory.general,
        postCount: 10000,
        matchKind: CompletionMatchKind.aliasExact,
        sources: {CompletionSourceKind.base},
      ),
  };
}

class _Edges extends CooccurrenceDataSource {
  bool? complete;
  @override
  Future<Map<String, List<RelatedTag>>> getRelatedTagsBatch(
    List<String> tags, {
    int? limit = 10,
  }) async {
    complete = limit == null;
    return {
      for (final tag in tags)
        tag: [
          const RelatedTag(tag: 'solo', count: 9000),
          RelatedTag(tag: 'umbrella', count: tag == 'rain' ? 6000 : 8000),
          const RelatedTag(tag: 'wet', count: 3000),
          const RelatedTag(tag: 'some_character', count: 1000),
        ],
    };
  }
}

class _Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => null;
}

class _Cache extends VisibleTagTranslationCache {
  @override
  Future<Map<String, CachedVisibleTagTranslation>> chineseTerms(
    Iterable<String> tags,
  ) async => {
    if (tags.contains('umbrella'))
      'umbrella': const CachedVisibleTagTranslation(nameZh: '雨伞'),
  };
}

void main() {
  late ProviderContainer container;
  late _Edges edges;
  setUp(() {
    edges = _Edges();
    final catalog = _Catalog();
    container = ProviderContainer(
      overrides: [
        tagCatalogRepositoryProvider.overrideWithValue(catalog),
        cooccurrenceCompletionSourceProvider.overrideWithValue(
          CooccurrenceCompletionSource(edges, catalog: catalog),
        ),
        tagWikiRepositoryProvider.overrideWithValue(_Wiki()),
        visibleTagTranslationCacheProvider.overrideWithValue(_Cache()),
      ],
    );
  });
  tearDown(() => container.dispose());
  Future<Map<String, dynamic>> run(
    Map<String, dynamic> args, [
    NaiAgentCancellation? token,
  ]) async =>
      (await container.read(
            Provider((ref) => naiAgentKnowledgeTools(ref)),
          )['tag_related']!(
            'tag_related',
            args,
            token ?? NaiAgentCancellation(),
          ))['details']
          as Map<String, dynamic>;

  test(
    'normalizes aliases, ranks full adjacency, explains support without creating RAG',
    () async {
      final result = await run({
        'tags': ['Old Rain', 'holding_umbrella', 'rain', 'unknown'],
        'limit': 1,
      });
      expect(result['network_requests'], 0);
      expect(result['unknown'], ['unknown']);
      expect((result['resolved'] as List).first, {
        'input': 'Old Rain',
        'tag': 'rain',
      });
      final item = (result['items'] as List).single;
      expect(item['tag'], 'umbrella');
      expect(item['translation'], '雨伞');
      expect(item['sources'], ['rain', 'holding_umbrella']);
      expect(item['support'], 2);
      expect(edges.complete, true);
      expect(container.exists(ragControllerProvider), false);
      expect(container.exists(ragSettingsProvider), false);
    },
  );
  test(
    'exclusion and category apply before limit, unknown tags do not query edges',
    () async {
      final result = await run({
        'tags': ['rain'],
        'exclude': ['Umbrella'],
        'categories': ['character'],
      });
      expect((result['items'] as List).single['tag'], 'some_character');
      edges.complete = null;
      expect(
        (await run({
          'tags': ['unknown'],
        }))['items'],
        isEmpty,
      );
      expect(edges.complete, isNull);
    },
  );
  test('rejects invalid fields and cancellation at the boundary', () async {
    for (final args in [
      {'tags': []},
      {
        'tags': ['rain'],
        'limit': 51,
      },
      {
        'tags': [42],
      },
      {
        'tags': ['rain'],
        'categories': ['invalid'],
      },
      {
        'tags': ['rain'],
        'unknown': true,
      },
    ]) {
      await expectLater(run(args), throwsA(isA<NaiAgentToolError>()));
    }
    final token = NaiAgentCancellation()..cancel();
    await expectLater(
      run({
        'tags': ['rain'],
      }, token),
      throwsA(isA<NaiAgentToolError>()),
    );
  });
  test(
    'official Pi discovers and calls the Dart tool through CodeMode',
    () async {
      final root = await Directory.systemTemp.createTemp('tag-related-wire-');
      final requests = <Map<String, dynamic>>[];
      final calls = <String>[];
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        requests.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        final first = requests.length == 1;
        final delta = first
            ? {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'related-script',
                    'type': 'function',
                    'function': {
                      'name': 'codemode',
                      'arguments': jsonEncode({
                        'code': '''
text(await searchTools('tag_related'));
const result = await tools.mcp__nai_studio__tag_related({tags:['Old Rain','holding_umbrella'],limit:1});
text(result.structuredContent);
''',
                      }),
                    },
                  },
                ],
              }
            : {'role': 'assistant', 'content': 'done'};
        request.response.headers.set('content-type', 'text/event-stream');
        request.response.write(
          'data: ${jsonEncode({
            'id': 'related-test',
            'object': 'chat.completion.chunk',
            'model': 'test',
            'choices': [
              {'index': 0, 'delta': delta, 'finish_reason': first ? 'tool_calls' : 'stop'},
            ],
          })}\n\ndata: [DONE]\n\n',
        );
        await request.response.close();
      });
      PiHostClient? client;
      try {
        final tools = container.read(
          Provider((ref) => naiAgentKnowledgeTools(ref)),
        );
        client = await PiHostClient.start(
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          workspaceId: 'related-test',
          workspaceDirectory: root,
          agentDirectory: Directory('${root.path}/agent'),
          systemPrompt: 'Synthetic related tags test',
          privateModelConfig: {
            'providerId': 'synthetic',
            'modelId': 'test',
            'protocol': 'openaiChatCompletions',
            'tools': true,
            'baseUrl': 'http://127.0.0.1:${server.port}',
          },
          extraToolNames: const ['tag_related', 'ask_user'],
          executeTool: (name, args, token) {
            calls.add(name);
            return tools[name]!(name, args, token);
          },
        );
        await client.prompt('find related tags');
        expect(requests, hasLength(2));
        expect(calls, ['tag_related']);
        expect(
          (requests.first['tools'] as List).map(
            (tool) => tool['function']['name'],
          ),
          unorderedEquals([
            'read',
            'write',
            'edit',
            'bash',
            'studio_context',
            'ask_user',
            'codemode',
          ]),
        );
        final raw = (requests.last['messages'] as List).lastWhere(
          (message) => message['role'] == 'tool',
        )['content'];
        final output = raw is String ? raw : jsonEncode(raw);
        expect(output, contains('local_cooccurrence'));
        expect(output, contains('umbrella'));
        expect(output, contains('雨伞'));
        expect(container.exists(ragControllerProvider), false);
        expect(container.exists(ragSettingsProvider), false);
      } finally {
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
        await root.delete(recursive: true);
      }
    },
  );
}
