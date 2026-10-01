import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/tag_translation_lookup.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/autocomplete/zh_dictionary_service.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_linked_body.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_candidate_title.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/studio_capture_fonts.dart';

const longTag = 'artoria_pendragon_(swimsuit_ruler)_(first_ascension)_(fate)';
final tags = [
  for (final name in [
    'fate_testarossa',
    longTag,
    'saber_(fate)',
    'blue_eyes',
    'artist_name',
    'fate_(series)',
  ])
    CompletionCandidate(
      canonicalTag: name,
      category: switch (name) {
        'blue_eyes' => TagCategory.general,
        'artist_name' => TagCategory.artist,
        'fate_(series)' => TagCategory.copyright,
        _ => TagCategory.character,
      },
      postCount: 1300,
      translation: name == longTag ? '阿尔托莉雅·潘德拉贡（泳装 Ruler）（第一阶段）（Fate）' : null,
      matchKind: CompletionMatchKind.englishExact,
      sources: const {CompletionSourceKind.base},
    ),
];

class _Tags extends UnifiedTagRepository {
  _Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async => throw StateError('unused'),
      );
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => tags;
  @override
  Future<List<CompletionCandidate>> searchContains(
    String input, {
    int limit = 20,
  }) async => [];
  @override
  Future<List<CompletionCandidate>> browse({
    TagCategory? category,
    bool? hasWiki,
    bool alphabetical = false,
    int offset = 0,
    int limit = 80,
  }) async => tags.skip(offset).take(limit).toList();
  @override
  Future<int> count({TagCategory? category, bool? hasWiki}) async =>
      tags.length;
}

class _Wiki implements TagWikiRepository {
  final pending = <String, Future<TagWikiEntry?>>{};
  @override
  Future<TagWikiEntry?> find(String tag) =>
      pending[tag] ??
      Future.value(
        TagWikiEntry(
          tag: tag,
          body:
              'See [saber_(fate)](https://danbooru.donmai.us/wiki_pages/saber_%28fate%29) and [blue_eyes](https://danbooru.donmai.us/wiki_pages/blue_eyes).',
          sourceUrl: '',
        ),
      );
}

class _Names extends TagTranslationLookup implements TranslationResolver {
  _Names() : super(ZhDictionaryService());
  @override
  Future<String?> translate(String tag) async => null;
  @override
  Future<Map<String, String>> resolve(
    List<String> tags, {
    required String locale,
  }) async => {};
}

class _Source implements CompletionSource {
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => [];
}

class _Auto extends ChangeNotifier implements AutoTagTranslationController {
  int busy = 0;
  bool cachedBodies = true;
  String? bodyOverride;
  String? originalOverride;
  @override
  String? wikiOriginalFor(String tag) => cachedBodies ? originalOverride : null;
  @override
  bool get enabled => true;
  @override
  int get activeRequests => busy;
  @override
  String? get lastError => null;
  @override
  String? wikiFor(String tag) => !cachedBodies
      ? null
      : bodyOverride ??
            '这是角色的外观说明，相关标签如下：\n\n- [saber_(fate)](wof-tag:saber_%28fate%29)\n- [blue_eyes](wof-tag:blue_eyes)\n\n保留原始标签，点击蓝字可以继续查阅。';
  @override
  String? nameFor(String tag) =>
      tags.where((item) => item.canonicalTag == tag).firstOrNull?.translation;
  @override
  bool isWikiTranslating(String tag) => busy > 0;
  @override
  String? wikiErrorFor(String tag) => null;
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Blocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: <PromptBlock>[], folders: []);
}

final boundary = GlobalKey();
WikiTagLinks get links => WikiTagLinks(
  exactLookup: (names) async => {
    for (final tag in tags)
      if (names.contains(tag.canonicalTag)) tag.canonicalTag: tag,
  },
  chineseLookup: (_) async => [],
);

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_TAG_WIKI'] != '1') return;
  debugDisableShadows = false;
  for (final render
      in tester.allRenderObjects.whereType<RenderPhysicalShape>()) {
    render.markNeedsPaint();
  }
  await tester.pump();
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('.dart_tool/tag-wiki-captures')
      ..createSync(recursive: true);
    File(
      '${folder.path}/$name-${Platform.environment['STUDIO_APPEARANCE'] ?? 'light'}.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  debugDisableShadows = true;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  _Auto auto, {
  double scale = 1,
  TagWikiRepository? wiki,
}) async {
  final names = _Names();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        autoTagTranslationProvider.overrideWith((_) => auto),
        wikiTagLinksProvider.overrideWithValue(links),
        tagWikiRepositoryProvider.overrideWithValue(wiki ?? _Wiki()),
        unifiedTagRepositoryProvider.overrideWith((_) => _Tags()),
        tagTranslationLookupProvider.overrideWithValue(names),
        promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
        localTagExpansionServiceProvider.overrideWithValue(
          LocalTagExpansionService(
            catalog: _Tags(),
            chineseDictionary: _Source(),
            relatedTags: _Source(),
            translations: names,
            substringSearch: (_, {limit = 20}) async => [],
            popularSearch: ({limit = 12}) async => tags,
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getTheme(
          AppStyle.geist,
          Platform.environment['STUDIO_APPEARANCE'] == 'dark'
              ? Brightness.dark
              : Brightness.light,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: boundary, child: child!),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    if (Platform.environment['CAPTURE_TAG_WIKI'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'formatted original keeps current-article links, list layout and a compact centered preview header',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final editor = TextEditingController();
      addTearDown(editor.dispose);
      final auto = _Auto()
        ..bodyOverride =
            '示例\n\n- [菲特](wof-tag:fate_testarossa)\n- [蓝眼](wof-tag:blue_eyes)'
        ..originalOverride =
            'Examples\n\n- [Fate Testarossa](wof-tag:fate_testarossa)\n- [Blue eyes](wof-tag:blue_eyes)';
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 400,
            child: TagExpansionWrapper(
              controller: editor,
              child: TextField(key: const Key('host'), controller: editor),
            ),
          ),
        ),
        auto,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('host')));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('fate testarossa'));
      await tester.pumpAndSettle();
      final panel = find.byKey(const Key('tag-expansion-wiki-panel'));
      final title = find.descendant(
        of: panel,
        matching: find.textContaining('标签小百科 ·'),
      );
      final icon = find.descendant(
        of: panel,
        matching: find.byIcon(Icons.open_in_new),
      );
      expect(
        tester.getCenter(title).dy,
        closeTo(tester.getCenter(icon).dy, .1),
      );
      expect(tester.getSize(panel).height, lessThan(230));
      expect(
        tester.getSize(find.byKey(const Key('tag-expansion-search'))).height,
        36,
      );
      await tester.tap(
        find.byKey(const Key('wiki-reading-toggle-fate_testarossa')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        auto.originalOverride,
      );
      expect(find.text('Fate Testarossa', findRichText: true), findsOneWidget);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('tag-expansion-wiki-scroll')),
      );
      expect(scroll.controller!.position.maxScrollExtent, lessThan(1));
      expect(find.text('Blue eyes', findRichText: true), findsOneWidget);
      final document = await links.resolve(auto.originalOverride!);
      expect(document.links.map((link) => link.candidate.canonicalTag), [
        'fate_testarossa',
        'blue_eyes',
      ]);
      await capture(tester, 'paired-original');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'full Wiki uses the same formatted original after switching reading mode',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto()
        ..originalOverride =
            'Examples\n\n- [Fate Testarossa](wof-tag:fate_testarossa)\n- [Blue eyes](wof-tag:blue_eyes)';
      await _pump(
        tester,
        TagWikiScreen(
          initialTag: 'fate_testarossa',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
      );
      await tester.tap(
        find.byKey(const Key('wiki-reading-toggle-fate_testarossa')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        auto.originalOverride,
      );
      expect(find.text('Fate Testarossa', findRichText: true), findsOneWidget);
      await capture(tester, 'wiki-paired-original');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Studio preview has wrapping title, link history, retry footer and busy tooltip',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final auto = _Auto();
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 400,
            child: TagExpansionWrapper(
              controller: controller,
              child: TextField(key: const Key('host'), controller: controller),
            ),
          ),
        ),
        auto,
        scale: 1.3,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('host')));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'fate',
      );
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pumpAndSettle();
      await tester.tap(find.text('fate testarossa'));
      await tester.pumpAndSettle();
      tester
          .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
          .onTagTap(tags[1]);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tag-expansion-back')), findsOneWidget);
      expect(
        find.byKey(const Key('tag-expansion-header-separator')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('wiki-retranslate-$longTag')),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.textContaining('标签小百科 ·')).maxLines,
        isNull,
      );
      final toggle = find.byKey(const ValueKey('wiki-reading-toggle-$longTag'));
      expect(
        find.descendant(of: toggle, matching: find.text('译文')),
        findsOneWidget,
      );
      final retry = find.byKey(const ValueKey('wiki-retranslate-$longTag'));
      expect(
        tester.getRect(toggle).right,
        lessThan(tester.getRect(retry).left),
      );
      expect(tester.getCenter(toggle).dy, tester.getCenter(retry).dy);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: toggle, matching: find.text('原文')),
        findsOneWidget,
      );
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        startsWith('See '),
      );
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        startsWith('See '),
      );
      // A new article inherits the reading choice; going back restores the
      // version saved with the visit even if it changed on the new article.
      tester
          .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
          .onTagTap(tags[3]);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('wiki-reading-toggle-blue_eyes')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tag-expansion-back')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: toggle, matching: find.text('原文')),
        findsOneWidget,
      );
      await capture(tester, 'preview-original');
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        auto.wikiFor(longTag),
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'preview');
      auto.busy = 1;
      auto.notifyListeners();
      await tester.pump();
      final tooltip = tester
          .widget<IconButton>(
            find.byKey(const Key('tag-expansion-auto-translate')),
          )
          .tooltip;
      expect(tooltip, '正在翻译中');
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('wiki-retranslate-$longTag')),
            )
            .onPressed,
        isNull,
      );
      auto.busy = 0;
      auto.notifyListeners();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('saber_(fate)', findRichText: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('saber_(fate)', findRichText: true));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
            .controller!
            .text,
        'saber (fate)',
      );
      expect(find.textContaining('标签小百科 · saber (fate)'), findsOneWidget);
    },
  );

  testWidgets(
    'Studio Wiki renders clickable formatted lists and retry at lower right',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(
        tester,
        const TagWikiScreen(
          directory: WikiDirectory(roots: [], groups: {}),
          initialTag: longTag,
        ),
        _Auto(),
      );
      expect(
        find.byKey(const ValueKey('wiki-retranslate-$longTag')),
        findsOneWidget,
      );
      final toggle = find.byKey(const ValueKey('wiki-reading-toggle-$longTag'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        startsWith('See '),
      );
      expect(
        tester
            .widget<SegmentedButton<bool>>(
              find.byKey(const Key('wiki-reading-language')),
            )
            .selected,
        {false},
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'wiki_show_translation',
        ),
        isFalse,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<bool>>(
              find.byKey(const Key('wiki-reading-language')),
            )
            .selected,
        {true},
      );
      expect(tester.takeException(), isNull);
      final longTitle = find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is TagCandidateTitle &&
              widget.title ==
                  'artoria pendragon (swimsuit ruler) (first ascension) (fate)',
        ),
        matching: find.byType(Text),
      );
      final longIcon = find.byKey(
        const ValueKey('wiki-category-character-$longTag'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: longTitle, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      final titleRect = tester.getRect(longTitle);
      final iconRect = tester.getRect(longIcon);
      expect(iconRect.left - titleRect.right, closeTo(3, .01));
      expect(
        iconRect.right,
        lessThan(tester.getRect(find.text('1.3k').at(1)).left),
      );
      final shortRect = tester.getRect(find.text('fate testarossa'));
      final shortIcon = tester.getRect(
        find.byKey(const ValueKey('wiki-category-character-fate_testarossa')),
      );
      expect(shortIcon.left - shortRect.right, closeTo(3, .01));
      expect(
        find.byKey(const ValueKey('wiki-category-general-blue_eyes')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('wiki-category-artist-artist_name')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('wiki-category-copyright-fate_(series)')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'wiki');
      await tester.tap(find.text('blue_eyes', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
      expect(find.byKey(const Key('wiki-article-back')), findsOneWidget);
    },
  );

  testWidgets(
    'only selected links are blue, and repeated example links stay clickable',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto()
        ..bodyOverride = '''帽子以及 visor 是普通说明。[blue_eyes](wof-tag:blue_eyes)。

示例
- [blue_eyes](wof-tag:blue_eyes)

[未知](wof-tag:unknown)''';
      await _pump(
        tester,
        const TagWikiScreen(
          directory: WikiDirectory(roots: [], groups: {}),
          initialTag: longTag,
        ),
        auto,
      );
      final body = find.byType(WikiLinkedBody);
      final labels = <String>[];
      for (final text in tester.widgetList<SelectableText>(
        find.descendant(of: body, matching: find.byType(SelectableText)),
      )) {
        text.textSpan?.visitChildren((span) {
          if (span is TextSpan && span.recognizer != null) {
            labels.add(span.toPlainText());
          }
          return true;
        });
      }
      expect(labels, ['blue_eyes', 'blue_eyes']);
      expect(
        find.textContaining('帽子以及 visor', findRichText: true),
        findsOneWidget,
      );
      await capture(tester, 'model-links');
      await tester.tap(find.text('blue_eyes', findRichText: true).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
      expect(find.byKey(const Key('wiki-article-back')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fast preview jumps reject an old article and can return through its loading visit',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final wiki = _Wiki();
      final pending = Completer<TagWikiEntry?>();
      wiki.pending['saber_(fate)'] = pending.future;
      final auto = _Auto()..cachedBodies = false;
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 400,
            child: TagExpansionWrapper(
              controller: controller,
              child: TextField(key: const Key('host'), controller: controller),
            ),
          ),
        ),
        auto,
        wiki: wiki,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('host')));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'fate',
      );
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pumpAndSettle();
      await tester.tap(find.text('fate testarossa'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wiki-reading-toggle-fate_testarossa')),
        findsNothing,
      );
      final navigate = tester
          .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
          .onTagTap;
      navigate(tags[2]);
      navigate(tags[3]);
      await tester.pumpAndSettle();
      expect(find.textContaining('标签小百科 · blue eyes'), findsOneWidget);
      pending.complete(
        const TagWikiEntry(
          tag: 'saber_(fate)',
          body: 'Old slow article.',
          sourceUrl: '',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        isNot('Old slow article.'),
      );
      await tester.tap(find.byKey(const Key('tag-expansion-back')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        'Old slow article.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'larger preview stays within a compact viewport at enlarged text size',
    (tester) async {
      tester.view.physicalSize = const Size(420, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final auto = _Auto()
        ..bodyOverride = List.filled(30, '正文说明，保留标签与分段。').join('\n\n');
      await _pump(
        tester,
        Center(
          child: SizedBox(
            width: 300,
            child: TagExpansionWrapper(
              controller: controller,
              child: TextField(key: const Key('host'), controller: controller),
            ),
          ),
        ),
        auto,
        scale: 1.3,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('host')));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('fate testarossa'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find.byKey(const Key('tag-expansion-wiki-panel')),
      );
      expect(panel.height, 280);
      expect(panel.left, greaterThanOrEqualTo(8));
      expect(panel.right, lessThanOrEqualTo(412));
      expect(panel.bottom, lessThanOrEqualTo(612));
      expect(tester.takeException(), isNull);
      await capture(tester, 'preview-compact');
    },
  );

  testWidgets(
    'Wiki back restores scroll after the saved article future rebuilds',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto()
        ..bodyOverride = List.filled(60, '正文段落 blue_eyes。').join('\n\n');
      await _pump(
        tester,
        const TagWikiScreen(
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
      );
      ScrollController articleScroll() => tester
          .widget<SingleChildScrollView>(
            find
                .ancestor(
                  of: find.byType(WikiLinkedBody),
                  matching: find.byType(SingleChildScrollView),
                )
                .first,
          )
          .controller!;
      articleScroll().jumpTo(350);
      await tester.pump();
      tester
          .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
          .onTagTap(tags[2]);
      await tester.pumpAndSettle();
      expect(articleScroll().offset, 0);
      await tester.tap(find.byKey(const Key('wiki-article-back')));
      await tester.pumpAndSettle();
      expect(articleScroll().offset, 350);
      expect(tester.takeException(), isNull);
    },
  );
}
