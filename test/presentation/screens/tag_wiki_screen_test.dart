import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/tag_translation_lookup.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/autocomplete/zh_dictionary_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_linked_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<List<CompletionCandidate>> byNames(Iterable<String> names) async =>
      entries.where((item) => names.contains(item.canonicalTag)).toList();
}

class _Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => TagWikiEntry(
    tag: tag,
    body: 'Blue eyes are visible.',
    sourceUrl: 'https://safebooru.donmai.us/wiki_pages/$tag',
  );
}

class _Translation extends TagTranslationLookup {
  _Translation() : super(ZhDictionaryService());

  @override
  Future<String?> translate(String tag) async => '蓝眼睛';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'desktop Wiki renders directory, results, article and reading rail',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auto = _Auto();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoTagTranslationProvider.overrideWith((ref) => auto),
            unifiedTagRepositoryProvider.overrideWith((ref) => _Tags()),
            wikiTagLinksProvider.overrideWithValue(
              WikiTagLinks(
                exactLookup: (names) async => {
                  for (final item in _Tags.entries)
                    if (names.contains(item.canonicalTag))
                      item.canonicalTag: item,
                },
                chineseLookup: (_) async => [],
              ),
            ),
            tagWikiRepositoryProvider.overrideWith((ref) => _Wiki()),
            tagTranslationLookupProvider.overrideWith((ref) => _Translation()),
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
      expect(find.text('阅读设置'), findsOneWidget);
      expect(find.byKey(const Key('wiki-untranslated')), findsOneWidget);
      auto.translations['blue_eyes'] = '蓝眼睛清晰可见。';
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('蓝眼睛清晰可见。'), findsOneWidget);
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

      for (var i = 0; i < 8; i++) {
        tester
            .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
            .onTagTap(_Tags.entries[(i + 1) % 2]);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byKey(const Key('wiki-article-back')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('wiki-article-back')), findsNothing);
      expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
      expect(find.text('Blue eyes are visible.'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'wiki_show_translation',
        ),
        isFalse,
      );

      tester.view.physicalSize = const Size(900, 780);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('阅读设置'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<bool>>(
              find.byKey(const Key('wiki-reading-language')),
            )
            .selected,
        {false},
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
      await tester.tap(find.text('隐藏').last);
      await tester.pumpAndSettle();
    },
  );
}
