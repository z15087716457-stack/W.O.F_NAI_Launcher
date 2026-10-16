import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/cooccurrence_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/database/dictionary_revision.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_linked_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import '../../helpers/studio_capture_fonts.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

class _Tags extends UnifiedTagRepository {
  _Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async => throw StateError('not used'),
      );

  static const entries = [
    CompletionCandidate(
      canonicalTag: 'blue_eyes',
      category: TagCategory.general,
      postCount: 100,
      matchKind: CompletionMatchKind.englishExact,
      sources: {CompletionSourceKind.base},
    ),
    CompletionCandidate(
      canonicalTag: 'short_hair',
      category: TagCategory.general,
      postCount: 50,
      matchKind: CompletionMatchKind.englishPrefix,
      sources: {CompletionSourceKind.base},
    ),
  ];

  @override
  Future<List<CompletionCandidate>> browse({
    TagCategory? category,
    bool? hasWiki,
    bool alphabetical = false,
    int offset = 0,
    int limit = 80,
  }) async => entries.skip(offset).take(limit).toList();

  @override
  Future<int> count({TagCategory? category, bool? hasWiki}) async =>
      entries.length;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      entries.where((e) => e.canonicalTag.startsWith(query.token)).toList();
  @override
  Future<List<CompletionCandidate>> searchContains(
    String input, {
    int limit = 20,
  }) async => entries.where((e) => e.canonicalTag.contains(input)).toList();

  @override
  Future<List<CompletionCandidate>> byNames(Iterable<String> names) async =>
      entries.where((item) => names.contains(item.canonicalTag)).toList();
}

class _Wiki implements TagWikiRepository {
  String body = 'Blue eyes are visible.';
  @override
  Future<TagWikiEntry?> find(String tag) async => TagWikiEntry(
    tag: tag,
    body: body,
    sourceUrl: 'https://safebooru.donmai.us/wiki_pages/$tag',
  );
}

class _Cooccurrence extends CooccurrenceCompletionSource {
  _Cooccurrence()
    : super.withLoader(
        () async => throw StateError('unused'),
        catalog: TagCatalogRepository(),
      );

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      const [];
}

class _Blocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: <PromptBlock>[], folders: []);
}

class _Auto extends ChangeNotifier implements AutoTagTranslationController {
  final Map<String, String> translations = {};
  @override
  String? wikiFor(String tag) => translations[tag];
  @override
  bool get enabled => false;
  @override
  int get activeRequests => 0;
  @override
  bool isWikiTranslating(String tag) => false;
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _RagSettings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(enabled: true, wikiEnabled: true);
}

class _Rag extends RagController {
  bool deferred = false;
  final requests =
      <
        ({
          RagTextQuery query,
          RagCancellation cancellation,
          Completer<List<RagSearchHit>> result,
        })
      >[];
  @override
  RagStatus build() => const RagStatus(
    sources: {
      RagSource.wiki: RagStatus(
        phase: 'partial',
        indexed: 8,
        total: 10,
        partial: true,
      ),
    },
  );
  @override
  Future<List<RagSearchHit>> searchText(
    RagTextQuery query, {
    required RagCancellation cancellation,
  }) {
    final result = Completer<List<RagSearchHit>>();
    requests.add((query: query, cancellation: cancellation, result: result));
    if (!deferred) {
      result.complete(const [
        RagSearchHit(
          id: 'short_hair',
          title: 'Short hair',
          snippet: 'A short cut.',
          section: 'article',
        ),
      ]);
    }
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> ragPage(
    WidgetTester tester,
    _Rag rag, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
    double width = 1200,
    GlobalKey? capture,
    _Wiki? wiki,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ragSettingsProvider.overrideWith(_RagSettings.new),
          ragControllerProvider.overrideWith(() => rag),
          unifiedTagRepositoryProvider.overrideWith((ref) => _Tags()),
          tagWikiRepositoryProvider.overrideWith((ref) => wiki ?? _Wiki()),
          cooccurrenceCompletionSourceProvider.overrideWithValue(
            _Cooccurrence(),
          ),
          autoTagTranslationProvider.overrideWith((ref) => _Auto()),
          wikiTagLinksProvider.overrideWithValue(
            WikiTagLinks(exactLookup: (_) async => {}),
          ),
          wikiExampleRepositoryProvider.overrideWithValue(
            WikiExampleRepository(
              fetchWiki: (tag, {cancelToken}) async => null,
              fetchPosts: (ids, {cancelToken}) async => [],
            ),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: brightness == Brightness.dark
              ? GeistTheme.dark
              : GeistTheme.light,
          home: RepaintBoundary(
            key: capture,
            child: const Scaffold(
              body: TagWikiScreen(
                directory: WikiDirectory(
                  roots: [
                    WikiDirectoryNode(
                      label: 'Traits',
                      group: 'traits',
                      children: [],
                    ),
                  ],
                  groups: {
                    'traits': WikiDirectoryGroup(
                      title: 'Traits',
                      members: ['blue_eyes'],
                      children: [],
                      sourceUrl: 'https://example.test',
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('wiki-search')), text);
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  testWidgets(
    'a completed dictionary update refreshes the selected Wiki article in place',
    (tester) async {
      final wiki = _Wiki();
      await ragPage(tester, _Rag(), wiki: wiki);
      await tester.tap(find.byKey(const Key('wiki-row-blue_eyes')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Blue eyes are visible.'), findsWidgets);
      wiki.body = 'Fresh article after local supplement.';
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TagWikiScreen)),
      );
      container.read(dictionaryRevisionProvider.notifier).state++;
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Fresh article after local supplement.'),
        findsWidgets,
      );
      expect(find.textContaining('Blue eyes are visible.'), findsNothing);
    },
  );

  testWidgets(
    'Wiki semantic matches supplement names and preserve folder scope',
    (tester) async {
      final rag = _Rag();
      await ragPage(tester, rag);
      await search(tester, 'weather');
      expect(rag.requests.single.query.source, RagSource.wiki);
      expect(find.byKey(const Key('wiki-body-short_hair')), findsOneWidget);
      expect(find.byKey(const Key('rag-badge-wiki')), findsOneWidget);
      await tester.tap(find.text('Traits').first);
      await tester.pumpAndSettle();
      expect(rag.requests.last.query.allowed, ['blue_eyes']);
      expect(find.byKey(const Key('wiki-body-short_hair')), findsNothing);
    },
  );
  testWidgets('Wiki discards cancelled results after the query changes', (
    tester,
  ) async {
    final rag = _Rag()..deferred = true;
    await ragPage(tester, rag);
    await search(tester, 'weather');
    final old = rag.requests.single;
    await search(tester, 'ocean');
    expect(old.cancellation.isCancelled, isTrue);
    old.result.complete(const [
      RagSearchHit(
        id: 'short_hair',
        title: 'Old',
        snippet: 'old',
        section: 'article',
      ),
    ]);
    rag.requests.last.result.complete([]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-short_hair')), findsNothing);
  });
  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      for (final width in [360.0, 1200.0]) {
        testWidgets(
          'Wiki RAG ${locale.toLanguageTag()} ${brightness.name} $width',
          (tester) async {
            final key = GlobalKey();
            final rag = _Rag();
            await ragPage(
              tester,
              rag,
              locale: locale,
              brightness: brightness,
              width: width,
              capture: key,
            );
            await search(tester, 'weather');
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.runAsync(() async {
              final directory = Directory(
                '.dart_tool/rag-text-20261015/captures',
              );
              await directory.create(recursive: true);
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              await File(
                '${directory.path}/wiki-${locale.toLanguageTag()}-${brightness.name}-${width.toInt()}.png',
              ).writeAsBytes(data!.buffer.asUint8List());
            });
          },
        );
      }
    }
  }

  testWidgets(
    'desktop Wiki renders directory, results, article and reading popover',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auto = _Auto();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wikiExampleRepositoryProvider.overrideWithValue(
              WikiExampleRepository(
                fetchWiki: (tag, {cancelToken}) async => null,
                fetchPosts: (ids, {cancelToken}) async => [],
              ),
            ),
            autoTagTranslationProvider.overrideWith((ref) => auto),
            unifiedTagRepositoryProvider.overrideWith((ref) => _Tags()),
            wikiTagLinksProvider.overrideWithValue(
              WikiTagLinks(
                exactLookup: (names) async => {
                  for (final item in _Tags.entries)
                    if (names.contains(item.canonicalTag))
                      item.canonicalTag: item,
                },
              ),
            ),
            tagWikiRepositoryProvider.overrideWith((ref) => _Wiki()),
            cooccurrenceCompletionSourceProvider.overrideWithValue(
              _Cooccurrence(),
            ),
            promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TagWikiScreen(
                directory: WikiDirectory(
                  roots: [
                    WikiDirectoryNode(
                      label: 'Visual characteristics',
                      children: [],
                    ),
                  ],
                  groups: {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('官方目录'), findsOneWidget);
      expect(find.text('视觉特征'), findsOneWidget);
      expect(find.text('blue eyes'), findsWidgets);
      expect(find.text('Blue eyes are visible.'), findsOneWidget);
      expect(find.byKey(const Key('wiki-untranslated')), findsOneWidget);
      auto.translations['blue_eyes'] = '蓝眼睛清晰可见。';
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('蓝眼睛清晰可见。'), findsOneWidget);
      // The Aa reading popover hosts the translation switch.
      await tester.tap(find.byKey(const Key('wiki-reading-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('原文'));
      await tester.pumpAndSettle();
      expect(find.text('Blue eyes are visible.'), findsOneWidget);
      expect(find.text('蓝眼睛清晰可见。'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'wiki_show_translation',
        ),
        isFalse,
      );
      auto.translations['blue_eyes'] = '重新翻译的中文';
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Blue eyes are visible.'), findsOneWidget);
      // Close the popover before continuing.
      await tester.tapAt(const Offset(20, 600));
      await tester.pumpAndSettle();

      for (var i = 0; i < 8; i++) {
        tester
            .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
            .onTagTap(_Tags.entries[(i + 1) % 2]);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byKey(const Key('wiki-history-back')));
        await tester.pumpAndSettle();
      }
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('wiki-history-back')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
      expect(find.text('Blue eyes are visible.'), findsOneWidget);
      // Forward returns to the tag that was navigated away from.
      await tester.tap(find.byKey(const Key('wiki-history-forward')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-body-short_hair')), findsOneWidget);
      await tester.tap(find.byKey(const Key('wiki-history-back')));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'wiki_show_translation',
        ),
        isFalse,
      );

      tester.view.physicalSize = const Size(900, 780);
      await tester.pump();
      expect(tester.takeException(), isNull);
      // In the narrower window the same Aa button opens the popover.
      await tester.tap(find.byKey(const Key('wiki-reading-button')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<WikiReadingMode>>(
              find.byKey(const Key('wiki-reading-language')),
            )
            .selected,
        {WikiReadingMode.original},
      );
      await tester.tap(find.text('译文'));
      await tester.pumpAndSettle();
      expect(find.text('重新翻译的中文'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'wiki_show_translation',
        ),
        isTrue,
      );
      await tester.tapAt(const Offset(20, 700));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-reading-language')), findsNothing);
    },
  );
}
