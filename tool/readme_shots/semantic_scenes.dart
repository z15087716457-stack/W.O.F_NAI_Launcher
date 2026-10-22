import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/cooccurrence_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';

import 'readme_data.dart';

const genericTags = [
  'starry_sky',
  'long_hair',
  'glowing',
  'night',
  'flower',
  'moonlight',
  'blue_theme',
  'soft_lighting',
  'depth_of_field',
];
CompletionCandidate tag(String name, {bool semantic = false}) =>
    CompletionCandidate(
      canonicalTag: name,
      category: TagCategory.general,
      postCount: 180000,
      matchKind: CompletionMatchKind.englishPrefix,
      sources: const {CompletionSourceKind.base},
    );

class Tags extends UnifiedTagRepository implements CompletionSource {
  Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async =>
            throw StateError('No real database in README capture'),
      );
  @override
  Future<List<CompletionCandidate>> browse({
    TagCategory? category,
    bool? hasWiki,
    bool alphabetical = false,
    int offset = 0,
    int limit = 80,
  }) async => genericTags.map(tag).skip(offset).take(limit).toList();
  @override
  Future<int> count({TagCategory? category, bool? hasWiki}) async =>
      genericTags.length;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      genericTags.where((t) => t.contains(query.token)).map(tag).toList();
  @override
  Future<List<CompletionCandidate>> searchContains(
    String input, {
    int limit = 20,
  }) async =>
      genericTags.where((t) => t.contains(input)).map(tag).take(limit).toList();
  @override
  Future<List<CompletionCandidate>> byNames(Iterable<String> names) async =>
      genericTags.where(names.contains).map(tag).toList();
}

class Wiki implements TagWikiRepository {
  Wiki(this.d);
  final ReadmeData d;
  @override
  Future<TagWikiEntry?> find(String name) async => TagWikiEntry(
    tag: name,
    sourceUrl: 'https://example.com/wiki/$name',
    body: d.tr(
      '## 星空\n\n画面中有许多可见的星星，常用于表现晴朗的夜空。\n\n### 使用建议\n\n可搭配 [night](wiki:night)、[moonlight](wiki:moonlight) 与 [glowing](wiki:glowing)，表现柔和的冷色光影。\n\n### 相关标签\n\n* [night](wiki:night)\n* [moonlight](wiki:moonlight)\n* [blue theme](wiki:blue_theme)\n* [soft lighting](wiki:soft_lighting)',
      '## Starry sky\n\nA sky filled with visible stars, usually in a clear nighttime scene.\n\n### Usage\n\nCombine with [night](wiki:night), [moonlight](wiki:moonlight) and [glowing](wiki:glowing) for soft, cool lighting.\n\n### Related tags\n\n* [night](wiki:night)\n* [moonlight](wiki:moonlight)\n* [blue theme](wiki:blue_theme)\n* [soft lighting](wiki:soft_lighting)',
    ),
  );
}

class Cooccurrence extends CooccurrenceCompletionSource {
  Cooccurrence()
    : super.withLoader(
        () async => throw StateError('No real cooccurrence database'),
        catalog: TagCatalogRepository(),
      );
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      const [];
}

class Blocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: <PromptBlock>[], folders: []);
}

class Auto extends ChangeNotifier implements AutoTagTranslationController {
  @override
  String? wikiFor(String tag) => null;
  @override
  bool get enabled => false;
  @override
  int get activeRequests => 0;
  @override
  bool isWikiTranslating(String tag) => false;
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class EnabledSettings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(enabled: true, wikiEnabled: true);
}

class FakeRag extends RagController {
  @override
  RagStatus build() => const RagStatus(
    phase: 'ready',
    indexed: 53860,
    total: 53860,
    sources: {
      RagSource.wiki: RagStatus(phase: 'ready', indexed: 240, total: 240),
    },
  );
  @override
  Future<List<RagSearchHit>> searchText(
    RagTextQuery query, {
    required RagCancellation cancellation,
  }) async => const [
    RagSearchHit(
      id: 'starry_sky',
      title: 'Starry sky',
      snippet: 'A clear sky filled with stars.',
      section: 'article',
    ),
  ];
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
  }) async => [
    for (final t in genericTags.skip(2))
      tag(t).copyWith(retrievalOrigins: const ['rag:semantic'], score: .92),
  ];
}

List<Override> overrides(ReadmeData d) => [
  ragSettingsProvider.overrideWith(EnabledSettings.new),
  ragControllerProvider.overrideWith(FakeRag.new),
  unifiedTagRepositoryProvider.overrideWith((ref) => Tags()),
  tagWikiRepositoryProvider.overrideWith((ref) => Wiki(d)),
  cooccurrenceCompletionSourceProvider.overrideWithValue(Cooccurrence()),
  autoTagTranslationProvider.overrideWith((ref) => Auto()),
  wikiTagLinksProvider.overrideWithValue(
    WikiTagLinks(exactLookup: (_) async => {}),
  ),
  wikiExampleRepositoryProvider.overrideWithValue(
    WikiExampleRepository(
      fetchWiki: (tag, {cancelToken}) async => null,
      fetchPosts: (ids, {cancelToken}) async => [],
    ),
  ),
  promptBlockLibraryNotifierProvider.overrideWith(Blocks.new),
  localTagExpansionServiceProvider.overrideWithValue(
    LocalTagExpansionService(
      catalog: Tags(),
      relatedTags: Tags(),
      substringSearch: (s, {limit = 20}) =>
          Tags().searchContains(s, limit: limit),
      popularSearch: ({limit = 12}) async =>
          genericTags.take(limit).map(tag).toList(),
    ),
  ),
];

void setUpSemanticFakes() {
  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      StorageKeys.hasSeenLocalGalleryTip: true,
    });
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
  });
  tearDown(Hive.close);
}

Widget wikiScene(ReadmeData d) => ProviderScope(
  overrides: overrides(d),
  child: TagWikiScreen(
    directory: WikiDirectory(
      roots: [
        WikiDirectoryNode(
          label: d.tr('场景与光影', 'Scenes & lighting'),
          group: 'scenes',
          children: const [],
        ),
      ],
      groups: {
        'scenes': WikiDirectoryGroup(
          title: d.tr('场景与光影', 'Scenes & lighting'),
          members: genericTags,
          children: const [],
          sourceUrl: 'https://example.com',
        ),
      },
    ),
  ),
);

Future<void> prepareWiki(WidgetTester t) async {
  await t.enterText(find.byKey(const Key('wiki-search')), 'sky');
  await t.pump(const Duration(milliseconds: 300));
  for (var i = 0; i < 8; i++) {
    await t.pump();
  }
  await t.tap(find.byKey(const Key('wiki-row-starry_sky')));
  await t.pumpAndSettle();
  expect(find.byKey(const Key('rag-badge-wiki')), findsWidgets);
}

class ExpansionHost extends StatefulWidget {
  const ExpansionHost({super.key, required this.d});
  final ReadmeData d;
  @override
  State<ExpansionHost> createState() => _ExpansionHostState();
}

class _ExpansionHostState extends State<ExpansionHost> {
  final controller = TextEditingController(text: 'starry sky');
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: SizedBox(
        width: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.d.tr(
                '标签扩展 · 本地语义推荐',
                'Tag expansion · Local semantic search',
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TagExpansionWrapper(
              controller: controller,
              ragContext: true,
              child: TextField(
                key: const Key('sample-editor'),
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget expansionScene(ReadmeData d) => ProviderScope(
  overrides: overrides(d),
  child: ExpansionHost(d: d),
);
Future<void> prepareExpansion(WidgetTester t) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await t.tap(find.byKey(const Key('sample-editor')));
  await t.pump();
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await t.pump(const Duration(milliseconds: 300));
  await t.enterText(find.byKey(const Key('tag-expansion-search')), 'night sky');
  await t.pump(const Duration(milliseconds: 400));
  for (var i = 0; i < 10; i++) {
    await t.pump();
  }
}
