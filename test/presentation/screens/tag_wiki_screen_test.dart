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
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedTagRepositoryProvider.overrideWith((ref) => _Tags()),
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

      tester.view.physicalSize = const Size(900, 780);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
