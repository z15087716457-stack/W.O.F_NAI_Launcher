import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/cooccurrence_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/wiki_sidebar.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/wiki_tag_row.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_linked_body.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_category_visuals.dart';
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
  _Tags({this.entries})
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async => throw StateError('unused'),
      );
  final List<CompletionCandidate>? entries;
  TagCategory? lastCategory;
  bool? lastCoverage;
  List<CompletionCandidate> get values => entries ?? tags;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      values;
  @override
  Future<List<CompletionCandidate>> byNames(Iterable<String> names) async =>
      values.where((item) => names.contains(item.canonicalTag)).toList();
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
  }) async {
    lastCategory = category;
    lastCoverage = hasWiki;
    return values
        .where((item) => category == null || category == item.category)
        .where((item) => hasWiki != false)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<int> count({TagCategory? category, bool? hasWiki}) async => values
      .where((item) => category == null || category == item.category)
      .where((item) => hasWiki != false)
      .length;
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

class _Source implements CompletionSource {
  _Source([this.entries = const []]);
  final List<CompletionCandidate> entries;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      entries;
}

class _Cooccurrence extends CooccurrenceCompletionSource {
  _Cooccurrence([this.results = const []])
    : super.withLoader(
        () async => throw StateError('unused'),
        catalog: TagCatalogRepository(),
      );
  final List<CompletionCandidate> results;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      results;
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();
  @override
  void updatePromptImmediately(String prompt) {
    if (state.prompt == prompt) return;
    state = state.copyWith(prompt: prompt);
  }
}

class _Auto extends ChangeNotifier implements AutoTagTranslationController {
  final nameActivities = <String, TagTranslationActivity>{};
  final wikiActivities = <String, TagTranslationActivity>{};
  final retriedNames = <String>[];
  final retriedArticles = <String>[];
  @override
  TagTranslationActivity? activityFor(String tag, {bool wiki = false}) =>
      (wiki ? wikiActivities[tag] : null) ?? nameActivities[tag];
  @override
  void retranslateName({required String surface, required String tag}) {
    retriedNames.add(tag);
    nameActivities[tag] = const TagTranslationActivity(
      TagTranslationPhase.queued,
    );
    notifyListeners();
  }

  @override
  void retranslateWiki({required String surface, required String tag}) {
    retriedArticles.add(tag);
    wikiActivities[tag] = const TagTranslationActivity(
      TagTranslationPhase.queued,
      wiki: true,
    );
    notifyListeners();
  }

  final visible = <String, Set<String>>{};
  @override
  void observe({
    required String surface,
    required String tag,
    required bool visible,
    String? existingNameZh,
    AutoTagTranslationContext? tagContext,
  }) {
    final tags = this.visible.putIfAbsent(surface, () => {});
    if (visible) {
      tags.add(tag);
    } else {
      tags.remove(tag);
    }
  }

  @override
  void clearSurface(String surface) => visible.remove(surface);
  int busy = 0;
  bool autoEnabled = true;
  String? error;
  bool cachedBodies = true;
  String? bodyOverride;
  String? originalOverride;
  @override
  String? wikiOriginalFor(String tag) => cachedBodies ? originalOverride : null;
  @override
  bool get enabled => autoEnabled;
  @override
  Future<void> setEnabled(bool value) async {
    autoEnabled = value;
    notifyListeners();
  }

  @override
  int get activeRequests => busy;
  @override
  String? get lastError => error;
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
  static int reads = 0;
  @override
  Future<PromptBlockLibraryState> build() async {
    reads++;
    return PromptBlockLibraryState(blocks: <PromptBlock>[], folders: []);
  }
}

final boundary = GlobalKey();
WikiTagLinks get links => WikiTagLinks(
  exactLookup: (names) async => {
    for (final tag in tags)
      if (names.contains(tag.canonicalTag)) tag.canonicalTag: tag,
  },
);

Color? outlineLabelColor(WidgetTester tester, Finder link) => tester
    .widget<Text>(find.descendant(of: link, matching: find.byType(Text)))
    .style
    ?.color;

Future<void> capture(
  WidgetTester tester,
  String name, [
  String? appearance,
]) async {
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
    final redesign = Platform.environment['CAPTURE_WIKI_REDESIGN'] == '1';
    final polish = Platform.environment['CAPTURE_WIKI_POLISH'] == '1';
    final separators = Platform.environment['CAPTURE_WIKI_SEPARATORS'] == '1';
    final feedback = Platform.environment['CAPTURE_WIKI_FEEDBACK'] == '1';
    final alignment = Platform.environment['CAPTURE_WIKI_ALIGNMENT'] == '1';
    final image = await render.toImage(
      pixelRatio: redesign || polish || separators || feedback || alignment
          ? 1
          : 2,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory(
      alignment
          ? '.dart_tool/wiki-alignment-captures'
          : feedback
          ? '.dart_tool/wiki-feedback-captures'
          : separators
          ? '.dart_tool/wiki-separators-captures'
          : polish
          ? '.dart_tool/wiki-polish-captures'
          : redesign
          ? '.dart_tool/wiki-redesign-captures'
          : '.dart_tool/tag-wiki-captures',
    )..createSync(recursive: true);
    File(
      '${folder.path}/$name-${appearance ?? Platform.environment['STUDIO_APPEARANCE'] ?? 'light'}.png',
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
  _Tags? catalog,
  List<CompletionCandidate>? related,
  List<CompletionCandidate> expansionRelated = const [],
  _Params? params,
  Locale locale = const Locale('zh'),
  bool chrome = false,
  Brightness? brightness,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        autoTagTranslationProvider.overrideWith((_) => auto),
        wikiTagLinksProvider.overrideWithValue(
          catalog == null
              ? links
              : WikiTagLinks(
                  exactLookup: (names) async => {
                    for (final item in catalog.values)
                      if (names.contains(item.canonicalTag))
                        item.canonicalTag: item,
                  },
                ),
        ),
        tagWikiRepositoryProvider.overrideWithValue(wiki ?? _Wiki()),
        cooccurrenceCompletionSourceProvider.overrideWithValue(
          _Cooccurrence(related ?? const []),
        ),
        generationParamsNotifierProvider.overrideWith(
          () => params ?? _Params(),
        ),
        unifiedTagRepositoryProvider.overrideWith((_) => catalog ?? _Tags()),
        promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
        localTagExpansionServiceProvider.overrideWithValue(
          LocalTagExpansionService(
            catalog: _Tags(),
            relatedTags: _Source(expansionRelated),
            substringSearch: (_, {limit = 20}) async => [],
            popularSearch: ({limit = 12}) async => tags,
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getTheme(
          AppStyle.geist,
          brightness ??
              (Platform.environment['STUDIO_APPEARANCE'] == 'dark'
                  ? Brightness.dark
                  : Brightness.light),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: boundary, child: child!),
        ),
        home: WindowChromeScope(
          enabled: chrome,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<CompletionCandidate> _uiTags() => [
  for (final row in const [
    ('1girl', '1个女孩', 6000000),
    ('highres', '高分辨率', 5300000),
    ('solo', '单人', 5000000),
    ('long_hair', '长发', 4400000),
    ('looking_at_viewer', '注视观众', 3100000),
    ('blush', '脸红', 2900000),
    ('smile', '微笑', 2900000),
    ('open_mouth', '张嘴', 2400000),
    ('blue_eyes', '蓝眼睛', 1800000),
    ('touhou', '东方Project', 900600),
    ('1boy', '1个男孩', 1400000),
    ('1other', '其他角色', 100000),
    ('2girls', '2个女孩', 1300000),
    ('multiple_girls', '多个女孩', 1500000),
  ])
    CompletionCandidate(
      canonicalTag: row.$1,
      translation: row.$2,
      postCount: row.$3,
      category: row.$1 == 'touhou'
          ? TagCategory.copyright
          : TagCategory.general,
      matchKind: CompletionMatchKind.englishExact,
      sources: const {CompletionSourceKind.base},
    ),
];

const _uiBody =
    '一张包含一名女性角色的图片。只有可见地出现在画面中的活体角色才计入此标签。\n\n'
    '对于仅包含单个角色的图片，请参见 [solo](wof-tag:solo)。\n\n## 示例\n\n'
    '- [1girl](wof-tag:1girl) [solo](wof-tag:solo)\n'
    '- [1girl](wof-tag:1girl) 与 [1boy](wof-tag:1boy)\n\n'
    '## 另见\n\n- [1boy](wof-tag:1boy)\n- [1other](wof-tag:1other)\n'
    '- [2girls](wof-tag:2girls)\n- [multiple girls](wof-tag:multiple_girls)';
const _uiDirectory = WikiDirectory(
  roots: [
    WikiDirectoryNode(
      label: 'Visual characteristics',
      group: 'visual',
      children: [
        WikiDirectoryNode(
          label: 'Composition',
          group: 'composition',
          children: [],
        ),
        WikiDirectoryNode(label: 'Body', group: 'body', children: []),
      ],
    ),
  ],
  groups: {},
);

/// Finds the innermost paragraph/editable render object below [node].
RenderObject? _textRenderUnder(RenderObject node) {
  if (node is RenderParagraph || node is RenderEditable) return node;
  RenderObject? found;
  node.visitChildren((child) {
    found ??= _textRenderUnder(child);
  });
  return found;
}

/// Global center of the glyphs for [needle] inside the rich text found by
/// [paragraphText]. Needed because `find.text` matches a whole selectable
/// paragraph, not the inline link span inside it.
Offset _inlineTextCenter(
  WidgetTester tester,
  String paragraphText,
  String needle,
) {
  final finder = find.textContaining(paragraphText, findRichText: true).first;
  final render = _textRenderUnder(tester.renderObject(finder))!;
  final InlineSpan root = render is RenderParagraph
      ? render.text
      : (render as RenderEditable).text!;
  final plain = root.toPlainText();
  final start = plain.indexOf(needle);
  expect(start, greaterThanOrEqualTo(0));
  final selection = TextSelection(
    baseOffset: start,
    extentOffset: start + needle.length,
  );
  final boxes = render is RenderParagraph
      ? render.getBoxesForSelection(selection)
      : (render as RenderEditable).getBoxesForSelection(selection);
  return (render as RenderBox).localToGlobal(boxes.first.toRect().center);
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
    'Wiki inline translation activity animates, disappears and retries without navigation',
    (tester) async {
      await tester.runAsync(loadStudioCaptureFonts);
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto();
      await _pump(
        tester,
        const TagWikiScreen(initialTag: 'blue_eyes', directory: _uiDirectory),
        auto,
      );
      final row = find.byKey(const ValueKey('wiki-row-blue_eyes'));
      final title = find.descendant(of: row, matching: find.text('blue eyes'));
      final before = tester.getRect(title);
      auto.nameActivities['blue_eyes'] = const TagTranslationActivity(
        TagTranslationPhase.translating,
      );
      auto.notifyListeners();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      final listIcon = find.byKey(
        const ValueKey('tag-translation-name-blue_eyes'),
      );
      final articleIcon = find.byKey(
        const ValueKey('tag-translation-wiki-blue_eyes'),
      );
      expect(listIcon, findsOneWidget);
      expect(articleIcon, findsOneWidget);
      expect(tester.getRect(title), before);
      expect(
        tester.getRect(listIcon).left,
        closeTo(tester.getRect(title).right, 1),
      );
      expect(
        tester
            .widget<TranslationIcon>(
              find.descendant(
                of: listIcon,
                matching: find.byType(TranslationIcon),
              ),
            )
            .busy,
        isTrue,
      );
      await capture(tester, 'inline-wiki-translating');
      auto.nameActivities.clear();
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(listIcon, findsNothing);
      expect(articleIcon, findsNothing);
      expect(tester.getRect(title), before);
      auto.nameActivities['blue_eyes'] = const TagTranslationActivity(
        TagTranslationPhase.failed,
        error: 'name request failed',
      );
      auto.wikiActivities['blue_eyes'] = const TagTranslationActivity(
        TagTranslationPhase.failed,
        wiki: true,
        error: 'body request failed',
      );
      auto.notifyListeners();
      await tester.pumpAndSettle();
      final glyph = tester.widget<TranslationIcon>(
        find.descendant(of: listIcon, matching: find.byType(TranslationIcon)),
      );
      expect(glyph.busy, isFalse);
      expect(glyph.color, Theme.of(tester.element(listIcon)).colorScheme.error);
      await capture(tester, 'inline-wiki-failed');
      await tester.tap(listIcon);
      await tester.pumpAndSettle();
      expect(auto.retriedNames, ['blue_eyes']);
      expect(auto.retriedArticles, isEmpty);
      expect(find.byKey(const ValueKey('wiki-body-blue_eyes')), findsOneWidget);
      await tester.tap(articleIcon);
      await tester.pumpAndSettle();
      expect(auto.retriedArticles, ['blue_eyes']);
      expect(auto.retriedNames, ['blue_eyes']);
      await capture(tester, 'inline-wiki-queued');
      auto.nameActivities.clear();
      auto.wikiActivities.clear();
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tag expansion search, related rows and mini Wiki share inline activity',
    (tester) async {
      await tester.runAsync(loadStudioCaptureFonts);
      tester.view.physicalSize = const Size(1200, 900);
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
        expansionRelated: [tags.first],
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
      await tester.tap(find.text('fate testarossa').first);
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('fate testarossa').first));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('host'))),
      )!;
      await tester.tap(find.byTooltip(l10n.tagExpansion_showRelated).first);
      await tester.pumpAndSettle();
      await mouse.removePointer();
      auto.nameActivities['fate_testarossa'] = const TagTranslationActivity(
        TagTranslationPhase.translating,
      );
      auto.notifyListeners();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      final nameIcons = find.byKey(
        const ValueKey('tag-translation-name-fate_testarossa'),
      );
      final articleIcon = find.byKey(
        const ValueKey('tag-translation-wiki-fate_testarossa'),
      );
      expect(nameIcons, findsNWidgets(2));
      expect(articleIcon, findsOneWidget);
      for (final icon in tester.widgetList<TranslationIcon>(
        find.descendant(of: nameIcons, matching: find.byType(TranslationIcon)),
      )) {
        expect(icon.busy, isTrue);
      }
      await capture(tester, 'inline-expansion-translating');
      auto.nameActivities['fate_testarossa'] = const TagTranslationActivity(
        TagTranslationPhase.failed,
        error: 'name failed',
      );
      auto.notifyListeners();
      await tester.pumpAndSettle();
      await capture(tester, 'inline-expansion-failed');
      await tester.tap(nameIcons.first);
      await tester.pumpAndSettle();
      expect(auto.retriedNames, ['fate_testarossa']);
      expect(controller.text, isEmpty);
      expect(find.byKey(const ValueKey('tag-expansion-popup')), findsOneWidget);
      auto.nameActivities.clear();
      auto.wikiActivities['fate_testarossa'] = const TagTranslationActivity(
        TagTranslationPhase.failed,
        wiki: true,
        error: 'article failed',
      );
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(nameIcons, findsNothing);
      await tester.tap(articleIcon);
      await tester.pumpAndSettle();
      expect(auto.retriedArticles, ['fate_testarossa']);
      expect(controller.text, isEmpty);
      await capture(tester, 'inline-expansion-queued');
      auto.wikiActivities.clear();
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(articleIcon, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reading column remains centered, wider mode persists, and history actions align',
    (tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(
        tester,
        const TagWikiScreen(initialTag: '1girl', directory: _uiDirectory),
        _Auto()..bodyOverride = '$_uiBody\n\n[solo](wof-tag:solo)',
        catalog: _Tags(entries: _uiTags()),
        chrome: true,
      );
      final column = find.byKey(const ValueKey('wiki-reading-column'));
      final header = find.byKey(const ValueKey('wiki-article-header'));
      expect(
        tester.getRect(column).center.dx,
        closeTo(tester.getRect(header).center.dx, .01),
      );
      expect(tester.getSize(column).width, 760);
      // The reading-width choice lives in the Aa popover on the header now.
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      final width = tester.widget<SegmentedButton<bool>>(
        find.byKey(const ValueKey('wiki-reading-width')),
      );
      width.onSelectionChanged!({true});
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(tester.getSize(column).width, 1040);
      expect(
        (await SharedPreferences.getInstance()).getBool('wiki_wide_article'),
        isTrue,
      );
      expect(
        tester.getRect(column).center.dx,
        closeTo(tester.getRect(header).center.dx, .01),
      );
      await capture(tester, 'centered-wide-2k');
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      tester
          .widget<SegmentedButton<bool>>(
            find.byKey(const ValueKey('wiki-reading-width')),
          )
          .onSelectionChanged!({false});
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final body = find.byKey(const ValueKey('wiki-body-1girl'));
      await tester.tap(
        find
            .descendant(
              of: body,
              matching: find.text('solo', findRichText: true),
            )
            .first,
      );
      await tester.pumpAndSettle();
      final title = tester.getRect(
        find.byKey(const ValueKey('wiki-article-title')),
      );
      final copy = tester.getRect(find.byKey(const ValueKey('wiki-copy-tag')));
      // Actions sit on the right at title height; the category pill is above.
      final lastAction = tester.getRect(
        find.byKey(const ValueKey('wiki-reading-button')),
      );
      expect(lastAction.right, closeTo(tester.getRect(header).right, .01));
      expect(copy.center.dy, closeTo(lastAction.center.dy, .01));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('wiki-article-category-icon')))
            .bottom,
        lessThanOrEqualTo(title.top),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('wiki-article-metadata'))).top,
        greaterThan(title.bottom),
      );
      await capture(tester, 'history-header-2k');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reading selections are lighter and translation toggles in content row',
    (tester) async {
      tester.view.physicalSize = const Size(1720, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto()..bodyOverride = _uiBody;
      await _pump(
        tester,
        const TagWikiScreen(initialTag: '1girl', directory: _uiDirectory),
        auto,
        catalog: _Tags(entries: _uiTags()),
      );
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      for (final key in [
        'wiki-text-size',
        'wiki-reading-width',
        'wiki-reading-language',
      ]) {
        final dynamic segment = tester.widget(find.byKey(ValueKey(key)));
        final ButtonStyle style = segment.style;
        final selected = style.backgroundColor!.resolve({
          WidgetState.selected,
        })!;
        final unselected = style.backgroundColor!.resolve({})!;
        expect(
          selected.computeLuminance(),
          greaterThan(unselected.computeLuminance()),
        );
      }
      final button = find.byKey(const ValueKey('wiki-auto-translate'));
      expect(
        find.ancestor(
          of: button,
          matching: find.byKey(const ValueKey('wiki-reading-content-controls')),
        ),
        findsOneWidget,
      );
      final language = find.byKey(const ValueKey('wiki-reading-language'));
      expect(
        tester.getRect(button).left,
        greaterThan(tester.getRect(language).right),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(auto.enabled, isFalse);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(auto.enabled, isTrue);
      auto.busy = 1;
      auto.notifyListeners();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.widget<IconButton>(button).tooltip, contains('正在翻译'));
      auto.busy = 0;
      auto.error = '离线测试错误';
      auto.notifyListeners();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(button).tooltip, contains('离线测试错误'));
      auto.error = null;
      auto.notifyListeners();
      await tester.pumpAndSettle();
      await capture(tester, 'reading-controls');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow reading dialog retains all choices and translation switch',
    (tester) async {
      tester.view.physicalSize = const Size(560, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto()..bodyOverride = _uiBody;
      await _pump(
        tester,
        const TagWikiScreen(initialTag: '1girl', directory: _uiDirectory),
        auto,
        scale: 1.3,
        catalog: _Tags(entries: _uiTags()),
      );
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('wiki-reading-language')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('wiki-auto-translate')));
      await tester.pumpAndSettle();
      expect(auto.enabled, isFalse);
      tester
          .widget<SegmentedButton<bool>>(
            find.byKey(const ValueKey('wiki-reading-width')),
          )
          .onSelectionChanged!({true});
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<bool>>(
              find.byKey(const ValueKey('wiki-reading-width')),
            )
            .selected,
        {true},
      );
      await capture(tester, 'narrow-reading-dialog');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'official directory groups have no separators and original Wiki mark animates once',
    (tester) async {
      tester.view.physicalSize = const Size(1720, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(
        tester,
        TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(
            roots: [
              ..._uiDirectory.roots,
              const WikiDirectoryNode(
                label: 'Copyrights, artists, projects and media',
                group: 'works',
                children: [
                  WikiDirectoryNode(
                    label: 'Artists',
                    group: 'artists',
                    children: [],
                  ),
                ],
              ),
              const WikiDirectoryNode(
                label: 'Metatags',
                group: 'meta',
                children: [
                  WikiDirectoryNode(
                    label: 'Software',
                    group: 'software',
                    children: [],
                  ),
                ],
              ),
            ],
            groups: {},
          ),
        ),
        _Auto()..bodyOverride = _uiBody,
        catalog: _Tags(entries: _uiTags()),
      );
      final mark = find.byKey(const ValueKey('wiki-brand-mark'));
      expect(
        find.descendant(of: mark, matching: find.byIcon(StudioIcons.tagWiki)),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(ExpansionTile).first,
          matching: find.byIcon(Icons.expand_more),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Composition'), findsOneWidget);
      final sectionBottom = tester.getRect(find.text('官方目录')).bottom;
      final dividers = find.descendant(
        of: find.byType(WikiSidebar),
        matching: find.byType(Divider),
      );
      for (final divider in dividers.evaluate()) {
        expect(
          tester.getRect(find.byWidget(divider.widget)).top,
          lessThan(sectionBottom),
        );
      }
      for (final tile in tester.widgetList<ExpansionTile>(
        find.byType(ExpansionTile),
      )) {
        expect(tile.shape, const Border());
        expect(tile.collapsedShape, const Border());
      }
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(mark));
      await tester.pump(const Duration(milliseconds: 160));
      expect(
        find.descendant(
          of: mark,
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is StudioIconPainter,
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: mark, matching: find.byIcon(StudioIcons.tagWiki)),
        findsOneWidget,
      );
      await mouse.removePointer();
      await capture(tester, 'directory-icon');
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in const [
    ('2k', Size(2560, 1440), 1.0, 'zh'),
    ('wide', Size(1720, 940), 1.0, 'zh'),
    ('large', Size(1720, 940), 1.5, 'zh'),
    ('middle', Size(1100, 740), 1.0, 'zh'),
    ('compact', Size(820, 650), 1.5, 'zh'),
    ('narrow', Size(560, 760), 1.3, 'zh'),
    ('short', Size(1720, 420), 1.0, 'zh'),
    ('en', Size(1720, 940), 1.0, 'en'),
    ('ja', Size(1100, 740), 1.3, 'ja'),
  ]) {
    testWidgets(
      'Wiki E/I real layout ${scenario.$1} fits text and caption footprint',
      (tester) async {
        tester.view.physicalSize = scenario.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pump(
          tester,
          const TagWikiScreen(initialTag: '1girl', directory: _uiDirectory),
          _Auto()..bodyOverride = _uiBody,
          catalog: _Tags(entries: _uiTags()),
          scale: scenario.$3,
          locale: Locale(scenario.$4),
          chrome: true,
        );
        expect(tester.takeException(), isNull);
        final copy = find.byKey(const ValueKey('wiki-copy-tag'));
        expect(copy, findsOneWidget);
        final rect = tester.getRect(copy);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(scenario.$2.width));
        if (const ['2k', 'wide', 'short', 'en'].contains(scenario.$1)) {
          // The article header scrolls with the reading column now; the list
          // still begins right below its own toolbar.
          final listTop = tester
              .getRect(find.byKey(const ValueKey('wiki-results-list')))
              .top;
          expect(
            tester
                .getRect(
                  find.byKey(const ValueKey('wiki-official-directory-divider')),
                )
                .bottom,
            closeTo(listTop, .1),
          );
          final header = tester.getRect(
            find.byKey(const ValueKey('wiki-article-header')),
          );
          final readingColumn = tester.getRect(
            find.byKey(const ValueKey('wiki-reading-column')),
          );
          expect(header.left, greaterThanOrEqualTo(readingColumn.left));
          expect(header.right, lessThanOrEqualTo(readingColumn.right));
          expect(header.top, lessThan(listTop));
        }
        if (scenario.$1 == '2k' || scenario.$1 == 'wide') {
          // The article table of contents lives beside the reading column.
          expect(find.byKey(const ValueKey('wiki-outline-0')), findsOneWidget);
          expect(find.byKey(const ValueKey('wiki-reading-rail')), findsNothing);
          final row = find.byKey(const ValueKey('wiki-row-1girl'));
          expect(tester.getSize(row).height, greaterThanOrEqualTo(60));
          expect(
            find.byKey(const ValueKey('wiki-row-bookmark-long_hair')),
            findsNothing,
          );
        }
        await capture(tester, 'redesign-${scenario.$1}');
      },
    );
  }

  testWidgets('filter chips update the catalog and the Aa popover closes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1720, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = _Tags();
    await _pump(
      tester,
      const TagWikiScreen(directory: _uiDirectory),
      _Auto(),
      catalog: catalog,
    );
    // Type filters are chips in the results header now.
    await tester.tap(find.byKey(const ValueKey('wiki-type-copyright')));
    await tester.pumpAndSettle();
    expect(catalog.lastCategory, TagCategory.copyright);
    await tester.tap(find.byKey(const ValueKey('wiki-type-all')));
    await tester.pumpAndSettle();
    expect(catalog.lastCategory, isNull);
    // The extra categories live behind the trailing "more" chip, which may be
    // scrolled out of the single-line horizontally scrollable chip row.
    await tester.ensureVisible(find.byKey(const ValueKey('wiki-type-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wiki-type-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wiki-type-species')));
    await tester.pumpAndSettle();
    expect(catalog.lastCategory, TagCategory.species);
    // The horizontally scrolled chip row may have moved "全部" off-screen.
    await tester.ensureVisible(find.byKey(const ValueKey('wiki-type-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wiki-type-all')));
    await tester.pumpAndSettle();
    expect(catalog.lastCategory, isNull);
    await tester.tap(find.byKey(const ValueKey('wiki-coverage-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暂无释义').last);
    await tester.pumpAndSettle();
    expect(catalog.lastCoverage, isFalse);
    await tester.tap(find.byKey(const ValueKey('wiki-coverage-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部释义').last);
    await tester.pumpAndSettle();
    expect(catalog.lastCoverage, isNull);
    // The reading settings popover opens and dismisses like a menu.
    await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wiki-reading-language')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wiki-reading-language')), findsNothing);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('wiki-directory-header')))
          .bottom,
      tester.getRect(find.byKey(const ValueKey('wiki-results-pane'))).top - 1,
    );
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'Wiki heading and translation icon use their actual row center at $scale scale',
      (tester) async {
        await tester.runAsync(loadStudioCaptureFonts);
        tester.view.physicalSize = const Size(2560, 1440);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auto = _Auto()
          ..wikiActivities['blue_eyes'] = const TagTranslationActivity(
            TagTranslationPhase.queued,
            wiki: true,
          );
        await _pump(
          tester,
          const TagWikiScreen(initialTag: 'blue_eyes', directory: _uiDirectory),
          auto,
          catalog: _Tags(entries: _uiTags()),
          scale: scale,
          chrome: true,
        );
        final header = find.byKey(const ValueKey('wiki-directory-header'));
        final center = tester.getCenter(header).dy;
        expect(
          tester.getCenter(find.byKey(const ValueKey('wiki-brand-mark'))).dy,
          closeTo(center, .5),
        );
        final l = AppLocalizations.of(tester.element(header))!;
        expect(
          tester
              .getCenter(
                find.descendant(of: header, matching: find.text(l.wiki_title)),
              )
              .dy,
          closeTo(center, .5),
        );
        expect(
          tester
              .getCenter(
                find.descendant(
                  of: header,
                  matching: find.byIcon(Icons.create_new_folder_outlined),
                ),
              )
              .dy,
          closeTo(center, .5),
        );
        final article = find.byKey(const ValueKey('wiki-article-header'));
        final icon = find.descendant(
          of: article,
          matching: find.byType(TranslationIcon),
        );
        expect(icon, findsOneWidget);
        expect(
          tester.getCenter(icon).dy,
          closeTo(
            tester
                    .getCenter(find.byKey(const ValueKey('wiki-article-title')))
                    .dy +
                1.5 * scale,
            .5,
          ),
        );
        await capture(tester, 'translation-header-center-$scale');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Wiki feedback toolbar, category and footer align without hover',
    (tester) async {
      tester.view.physicalSize = const Size(1720, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final wiki = _Wiki()
        ..pending['touhou'] = Future.value(
          const TagWikiEntry(
            tag: 'touhou',
            body: _uiBody,
            sourceUrl: 'https://danbooru.donmai.us/wiki_pages/touhou',
          ),
        );
      await _pump(
        tester,
        TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(
            roots: _uiDirectory.roots,
            groups: const {
              'visual': WikiDirectoryGroup(
                title: 'Visual characteristics',
                members: ['touhou', '1girl'],
                children: [],
                sourceUrl: '',
              ),
            },
          ),
        ),
        _Auto()..bodyOverride = _uiBody,
        catalog: _Tags(entries: _uiTags()),
        wiki: wiki,
        chrome: true,
      );
      await tester.tap(find.text('视觉特征').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('wiki-search')),
        'touhou',
      );
      await tester.pumpAndSettle();
      final scope = find.byKey(const ValueKey('wiki-search-scope'));
      final pane = find.byKey(const ValueKey('wiki-results-pane'));
      final label = find.descendant(of: pane, matching: find.text('视觉特征'));
      expect(
        tester.getCenter(scope).dy,
        closeTo(tester.getCenter(label).dy, .1),
      );
      final scopeRect = tester.getRect(scope);
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(scope));
      await tester.pumpAndSettle();
      expect(tester.getRect(scope), scopeRect);
      await capture(tester, 'scope-hover');
      await mouse.removePointer();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is WikiTagRow && widget.candidate.canonicalTag == 'touhou',
        ),
      );
      await tester.pumpAndSettle();
      // The category pill renders as a colored dot now.
      final dot = tester.widget<Icon>(
        find.byKey(const ValueKey('wiki-article-category-icon')),
      );
      final category = find.byKey(
        const ValueKey('wiki-article-category-label'),
      );
      final expectedColor = TagCategoryVisuals.color(
        tester.element(category),
        TagCategory.copyright,
      );
      expect(dot.color, expectedColor);
      expect(dot.icon, TagCategoryVisuals.icon(TagCategory.copyright));
      expect(tester.widget<Text>(category).style!.color, expectedColor);
      final resultsList = tester.getRect(
        find.byKey(const ValueKey('wiki-results-list')),
      );
      final directoryDivider = tester.getRect(
        find.byKey(const ValueKey('wiki-official-directory-divider')),
      );
      final articleHeader = tester.getRect(
        find.byKey(const ValueKey('wiki-article-header')),
      );
      // The header scrolls inside the article pane and starts below the
      // toolbar, like the results list.
      expect(articleHeader.top, lessThan(resultsList.top));
      expect(directoryDivider.bottom, closeTo(resultsList.top, .1));
      final source = find.byKey(const ValueKey('wiki-article-source'));
      final toggle = find.byKey(const ValueKey('wiki-reading-toggle-touhou'));
      final retry = find.byKey(const ValueKey('wiki-retranslate-touhou'));
      expect(
        tester.getCenter(source).dy,
        closeTo(tester.getCenter(toggle).dy, .1),
      );
      expect(
        tester.getCenter(source).dy,
        closeTo(tester.getCenter(retry).dy, .1),
      );
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(32));
      expect(
        find.descendant(of: toggle, matching: find.byIcon(Icons.translate)),
        findsOneWidget,
      );
      expect(
        tester
                .getRect(find.byKey(const ValueKey('wiki-directory-header')))
                .bottom +
            1,
        closeTo(tester.getRect(find.byType(WindowHeader)).bottom, .1),
      );
      // The accepted mark stays at its original center; only the row ends move.
      expect(
        tester.getCenter(find.byKey(const ValueKey('wiki-brand-mark'))).dy,
        tester
            .getCenter(find.byKey(const ValueKey('wiki-directory-header')))
            .dy,
      );
      await capture(tester, 'category-footer-header');
      await tester.tap(scope);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: scope, matching: find.byIcon(Icons.public)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'first completed Wiki translation immediately binds new outline anchors',
    (tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final body =
          '简介。\n\n## 示例\n\n'
          '${List.filled(45, '译文示例。').join('\n\n')}\n\n'
          '## 音乐\n\n${List.filled(45, '音乐资料。').join('\n\n')}';
      final auto = _Auto()
        ..cachedBodies = false
        ..bodyOverride = body;
      await _pump(
        tester,
        const TagWikiScreen(initialTag: '1girl', directory: _uiDirectory),
        auto,
        catalog: _Tags(entries: _uiTags()),
      );
      expect(find.byKey(const ValueKey('wiki-outline-1')), findsNothing);
      auto.cachedBodies = true;
      await auto.setEnabled(true);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('wiki-outline-1')));
      await tester.pumpAndSettle();
      final outline = find.byKey(const ValueKey('wiki-outline-1'));
      expect(
        outlineLabelColor(tester, outline),
        Theme.of(tester.element(outline)).colorScheme.primary,
      );
      final linked = tester.widget<WikiLinkedBody>(
        find.byKey(const ValueKey('wiki-body-1girl')),
      );
      final viewport = find
          .ancestor(
            of: find.byKey(const ValueKey('wiki-body-1girl')),
            matching: find.byType(SingleChildScrollView),
          )
          .first;
      expect(
        tester.getRect(find.byKey(linked.headingAnchors![1])).top,
        closeTo(tester.getRect(viewport).top + 8, .5),
      );
      await capture(tester, 'translation-first-outline');
      auto.bodyOverride = '简介。\n\n## 示例\n\n示例正文。\n\n## 音乐\n\n音乐正文。';
      await auto.setEnabled(true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('wiki-outline-1')));
      await tester.pumpAndSettle();
      final shortOutline = find.byKey(const ValueKey('wiki-outline-1'));
      expect(
        outlineLabelColor(tester, shortOutline),
        Theme.of(tester.element(shortOutline)).colorScheme.primary,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('long outline headings wrap without clipping at scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const title = 'Artoria Caster（泳装 Berserker）（第三阶段）';
      await _pump(
        tester,
        const TagWikiScreen(initialTag: '1girl', directory: _uiDirectory),
        _Auto()..bodyOverride = '## $title\n\n正文。\n\n## Next section\n\n内容。',
        catalog: _Tags(entries: _uiTags()),
        scale: scale,
      );
      final link = find.byKey(const ValueKey('wiki-outline-0'));
      final next = find.byKey(const ValueKey('wiki-outline-1'));
      final text = find.descendant(of: link, matching: find.text(title));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.getRect(text).height, greaterThan(20));
      expect(
        tester.getRect(text).bottom,
        lessThanOrEqualTo(tester.getRect(link).bottom),
      );
      expect(
        tester.getRect(next).top,
        greaterThanOrEqualTo(tester.getRect(link).bottom),
      );
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(
        outlineLabelColor(tester, link),
        Theme.of(tester.element(link)).colorScheme.primary,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'inline-outline-$scale');
    });
  }

  testWidgets(
    'article outline jumps to real headings and preserves linked heading navigation',
    (tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final body =
          '${List.filled(45, '正文段落。').join('\n\n')}\n\n'
          '## 示例\n\n${List.filled(20, '示例正文。').join('\n\n')}\n\n'
          '## [blue eyes](wof-tag:blue_eyes)\n\n'
          '${List.filled(35, '相关正文。').join('\n\n')}';
      await _pump(
        tester,
        const TagWikiScreen(initialTag: '1girl', directory: _uiDirectory),
        _Auto()..bodyOverride = body,
        catalog: _Tags(entries: _uiTags()),
      );
      await tester.tap(find.byKey(const ValueKey('wiki-outline-0')));
      await tester.pumpAndSettle();
      final firstOutline = find.byKey(const ValueKey('wiki-outline-0'));
      expect(
        outlineLabelColor(tester, firstOutline),
        Theme.of(tester.element(firstOutline)).colorScheme.primary,
      );
      final bodyFinder = find.byKey(const ValueKey('wiki-body-1girl'));
      final scroll = tester.widget<SingleChildScrollView>(
        find
            .ancestor(
              of: bodyFinder,
              matching: find.byType(SingleChildScrollView),
            )
            .first,
      );
      expect(scroll.controller!.offset, greaterThan(500));
      final firstOffset = scroll.controller!.offset;
      // Resizing and reading settings reparse Markdown without changing the tag.
      tester.view.physicalSize = const Size(1780, 840);
      await tester.pumpAndSettle();
      // The article header (and its Aa button) scrolls with the column.
      await tester.ensureVisible(
        find.byKey(const ValueKey('wiki-reading-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      tester
          .widget<SegmentedButton<double>>(
            find.byKey(const ValueKey('wiki-text-size')),
          )
          .onSelectionChanged!({17});
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('wiki-outline-1')));
      await tester.pumpAndSettle();
      expect(scroll.controller!.offset, greaterThan(firstOffset + 400));
      final secondOutline = find.byKey(const ValueKey('wiki-outline-1'));
      expect(
        outlineLabelColor(tester, secondOutline),
        Theme.of(tester.element(secondOutline)).colorScheme.primary,
      );
      await capture(tester, 'outline-click-2k');
      scroll.controller!.jumpTo(0);
      await tester.pumpAndSettle();
      final intro = find.byKey(const ValueKey('wiki-outline-intro'));
      expect(
        outlineLabelColor(tester, intro),
        Theme.of(tester.element(intro)).colorScheme.primary,
      );
      await tester.tap(secondOutline);
      await tester.pumpAndSettle();
      final heading = find.descendant(
        of: bodyFinder,
        matching: find.text('blue eyes', findRichText: true),
      );
      await tester.tap(heading);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wiki-body-blue_eyes')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scaled viewport observations follow row extent and hidden compact list clears',
    (tester) async {
      tester.view.physicalSize = const Size(1720, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto();
      final entries = [
        for (var i = 0; i < 50; i++)
          CompletionCandidate(
            canonicalTag: 'visible_$i',
            category: TagCategory.general,
            postCount: 100 - i,
            matchKind: CompletionMatchKind.englishExact,
            sources: const {CompletionSourceKind.base},
          ),
      ];
      await _pump(
        tester,
        const TagWikiScreen(directory: _uiDirectory),
        auto,
        catalog: _Tags(entries: entries),
        scale: 1.5,
      );
      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('wiki-results-list')),
      );
      list.controller!.jumpTo(list.itemExtent! * 12);
      await tester.pumpAndSettle();
      final visible = auto.visible.entries
          .singleWhere((entry) => entry.key.startsWith('tag-wiki-list-'))
          .value;
      expect(visible.contains('visible_12'), isTrue);
      expect(visible.contains('visible_11'), isTrue);
      expect(visible.contains('visible_0'), isFalse);
      expect(visible.length, lessThan(14));
      tester.view.physicalSize = const Size(560, 760);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wiki-results-list')), findsNothing);
      expect(
        auto.visible.keys.any((key) => key.startsWith('tag-wiki-list-')),
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('wiki-article-back')));
      await tester.pumpAndSettle();
      final row = find.byType(WikiTagRow).first;
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wiki-results-list')), findsNothing);
      expect(
        auto.visible.keys.any((key) => key.startsWith('tag-wiki-list-')),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wiki footer copies the selected tag and remains usable after a clipboard failure',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final copied = <String>[];
      var reject = false;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          if (reject) throw PlatformException(code: 'clipboard-unavailable');
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      _Blocks.reads = 0;
      await _pump(
        tester,
        const TagWikiScreen(
          initialTag: 'blue_eyes',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        _Auto(),
      );
      expect(find.text('存为单原子块'), findsNothing);
      final copy = find.byKey(const ValueKey('wiki-copy-tag'));
      await tester.ensureVisible(copy);
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copied, ['blue eyes']);
      expect(find.text('已复制'), findsOneWidget);
      await capture(tester, 'copy-footer');
      reject = true;
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copied, ['blue eyes']);
      expect(tester.widget<OutlinedButton>(copy).onPressed, isNotNull);
      reject = false;
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copied, ['blue eyes', 'blue eyes']);
      expect(_Blocks.reads, 0);
      expect(tester.takeException(), isNull);
    },
  );

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
        const TagWikiScreen(
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
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<WikiReadingMode>>(
              find.byKey(const Key('wiki-reading-language')),
            )
            .selected,
        {WikiReadingMode.original},
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'wiki_show_translation',
        ),
        isFalse,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<WikiReadingMode>>(
              find.byKey(const Key('wiki-reading-language')),
            )
            .selected,
        {WikiReadingMode.translation},
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Rows render a 7px category dot before a plain single-line title.
      final longRow = find.byKey(const ValueKey('wiki-row-$longTag'));
      final longTitle = find.descendant(
        of: longRow,
        matching: find.text(
          'artoria pendragon (swimsuit ruler) (first ascension) (fate)',
        ),
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
      expect(iconRect.right, lessThanOrEqualTo(titleRect.left));
      expect(
        iconRect.right,
        lessThan(tester.getRect(find.text('1.3k').at(1)).left),
      );
      final shortRect = tester.getRect(find.text('fate testarossa'));
      final shortIcon = tester.getRect(
        find.byKey(const ValueKey('wiki-category-character-fate_testarossa')),
      );
      expect(shortIcon.right, lessThanOrEqualTo(shortRect.left));
      expect(
        find.byKey(const ValueKey('wiki-category-general-blue_eyes')),
        findsOneWidget,
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
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('wiki-history-back')))
            .onPressed,
        isNotNull,
      );
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
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('wiki-history-back')))
            .onPressed,
        isNotNull,
      );
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
      await tester.tap(find.byKey(const Key('wiki-history-back')));
      await tester.pumpAndSettle();
      expect(articleScroll().offset, 350);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bilingual mode interleaves muted original blocks under the translation',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'wiki_show_translation': true,
        'wiki_bilingual': true,
      });
      final auto = _Auto()
        ..bodyOverride =
            '一张包含一名女性角色的图片。\n\n'
            '## 示例\n\n'
            '- [1girl](wof-tag:1girl) [solo](wof-tag:solo)\n\n'
            '## 另见\n\n- [1boy](wof-tag:1boy)\n- [1other](wof-tag:1other)'
        ..originalOverride =
            'An image containing a single female character.\n\n'
            '## Examples\n\n'
            '- [1girl](wof-tag:1girl) [solo](wof-tag:solo)\n\n'
            '## See also\n\n- [1boy](wof-tag:1boy)\n- [1other](wof-tag:1other)';
      await _pump(
        tester,
        const TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
        catalog: _Tags(entries: _uiTags()),
      );
      // One translated body per block plus its muted original counterpart.
      expect(
        find.byType(WikiLinkedBody).evaluate().length,
        greaterThanOrEqualTo(6),
      );
      expect(
        find.text(
          'An image containing a single female character.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('一张包含一名女性角色的图片。', findRichText: true), findsOneWidget);
      final scheme = Theme.of(
        tester.element(find.byType(Scaffold).first),
      ).colorScheme;
      final originalBlocks = tester
          .widgetList<WikiLinkedBody>(find.byType(WikiLinkedBody))
          .where((body) => body.body.contains('An image containing'))
          .toList();
      expect(originalBlocks, hasLength(1));
      expect(originalBlocks.single.style?.fontSize, 13);
      expect(originalBlocks.single.style?.color, scheme.onSurfaceVariant);
      // The original heading renders as a small muted line, not in the TOC.
      final originalHeading = find.text('Examples');
      expect(originalHeading, findsOneWidget);
      expect(tester.widget<Text>(originalHeading).style?.fontSize, 13);
      expect(find.byKey(const Key('wiki-bilingual-unavailable')), findsNothing);
      await capture(tester, 'bilingual-1440');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bilingual segment persists and restores across sessions and history',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto()
        ..bodyOverride =
            '译文段落。\n\n## 另见\n\n- [blue_eyes](wof-tag:blue_eyes)\n- [1boy](wof-tag:1boy)\n- [1other](wof-tag:1other)'
        ..originalOverride =
            'Translated paragraph.\n\n## See also\n\n- [blue_eyes](wof-tag:blue_eyes)\n- [1boy](wof-tag:1boy)\n- [1other](wof-tag:1other)';
      await _pump(
        tester,
        const TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
        catalog: _Tags(entries: _uiTags()),
      );
      await tester.tap(find.byKey(const ValueKey('wiki-reading-button')));
      await tester.pumpAndSettle();
      tester
          .widget<SegmentedButton<WikiReadingMode>>(
            find.byKey(const Key('wiki-reading-language')),
          )
          .onSelectionChanged!({WikiReadingMode.bilingual});
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('wiki_bilingual'), isTrue);
      expect(prefs.getBool('wiki_show_translation'), isTrue);
      expect(find.byType(WikiLinkedBody).evaluate().length, greaterThan(1));
      // Follow a tag link, then history back restores the bilingual mode.
      // Both bilingual halves render the cloud, so the chip exists twice.
      await tester.tap(find.byKey(const Key('wiki-chip-blue_eyes')).first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('wiki-article-title')))
            .data,
        'blue eyes',
      );
      await tester.tap(find.byKey(const Key('wiki-history-back')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('wiki-article-title')))
            .data,
        '1girl',
      );
      expect(find.byType(WikiLinkedBody).evaluate().length, greaterThan(1));
      // A fresh session restores the persisted bilingual mode.
      await _pump(
        tester,
        const TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
        catalog: _Tags(entries: _uiTags()),
      );
      expect(find.byType(WikiLinkedBody).evaluate().length, greaterThan(1));
      expect(
        find.text('Translated paragraph.', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bilingual falls back to the translation when no aligned original exists',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'wiki_show_translation': true,
        'wiki_bilingual': true,
      });
      final auto = _Auto()
        ..bodyOverride = '译文段落。\n\n## 另见\n\n- [1boy](wof-tag:1boy)';
      // originalOverride stays null → wikiOriginalFor returns null.
      await _pump(
        tester,
        const TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
      );
      expect(
        find.byKey(const Key('wiki-bilingual-unavailable')),
        findsOneWidget,
      );
      expect(find.byType(WikiLinkedBody), findsOneWidget);
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        auto.bodyOverride,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bilingual outline anchors land on translated headings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'wiki_show_translation': true,
      'wiki_bilingual': true,
    });
    final filler = List.filled(40, '填充段落 filler.').join('\n\n');
    final fillerEn = List.filled(40, 'Filler paragraph.').join('\n\n');
    final auto = _Auto()
      ..bodyOverride =
          '首段。\n\n## 示例\n\n- [1girl](wof-tag:1girl)\n\n$filler\n\n'
          '## 另见\n\n- [1boy](wof-tag:1boy)'
      ..originalOverride =
          'Intro.\n\n## Examples\n\n- [1girl](wof-tag:1girl)\n\n$fillerEn\n\n'
          '## See also\n\n- [1boy](wof-tag:1boy)';
    await _pump(
      tester,
      const TagWikiScreen(
        initialTag: '1girl',
        directory: WikiDirectory(roots: [], groups: {}),
      ),
      auto,
    );
    final scroll = tester
        .widget<SingleChildScrollView>(
          find
              .ancestor(
                of: find.byType(WikiLinkedBody).first,
                matching: find.byType(SingleChildScrollView),
              )
              .first,
        )
        .controller!;
    expect(scroll.offset, 0);
    await tester.tap(find.byKey(const ValueKey('wiki-outline-1')));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'example sections render clickable cards while other lists keep their form',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auto = _Auto()
        ..bodyOverride =
            '引言。\n\n'
            '## 示例\n\n'
            '- [1girl](wof-tag:1girl)\n'
            '- [solo](wof-tag:solo)\n'
            '- [1boy](wof-tag:1boy)\n\n'
            '## 例外\n\n'
            '- 不计入的项甲\n'
            '- 不计入的项乙\n\n'
            '## 用例\n\n'
            '- [1girl](wof-tag:1girl)\n'
            '  - 内层说明\n'
            '- [solo](wof-tag:solo)\n\n'
            '## 另见\n\n'
            '- [1boy](wof-tag:1boy)\n'
            '- [1other](wof-tag:1other)\n'
            '- [2girls](wof-tag:2girls)';
      await _pump(
        tester,
        const TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
        catalog: _Tags(entries: _uiTags()),
      );
      // The pure-link list inside 示例 becomes cards, not a chip cloud.
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('wiki-example-card-$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('wiki-chip-1girl')), findsNothing);
      // 「例外」 is not an example keyword; its list stays a bullet list.
      expect(find.textContaining('不计入的项甲'), findsOneWidget);
      // The nested list under 用例 also keeps default rendering.
      expect(find.textContaining('内层说明'), findsOneWidget);
      // A pure-link list outside an example section is still a chip cloud.
      expect(find.byKey(const Key('wiki-chip-2girls')), findsOneWidget);
      await capture(tester, 'example-cards-1440-zh');
      // Links inside example cards navigate like body links.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('wiki-example-card-1')),
          matching: find.text('solo', findRichText: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-body-solo')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bilingual example sections render cards on both sides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'wiki_show_translation': true,
      'wiki_bilingual': true,
    });
    final auto = _Auto()
      ..bodyOverride =
          '引言。\n\n'
          '## 示例\n\n'
          '- [1girl](wof-tag:1girl)\n'
          '- [solo](wof-tag:solo)\n'
          '- [1boy](wof-tag:1boy)\n\n'
          '## 另见\n\n'
          '- [2girls](wof-tag:2girls)\n'
          '- [1other](wof-tag:1other)\n'
          '- [multiple_girls](wof-tag:multiple_girls)'
      ..originalOverride =
          'Intro.\n\n'
          '## Examples\n\n'
          '- [1girl](wof-tag:1girl)\n'
          '- [solo](wof-tag:solo)\n'
          '- [1boy](wof-tag:1boy)\n\n'
          '## See also\n\n'
          '- [2girls](wof-tag:2girls)\n'
          '- [1other](wof-tag:1other)\n'
          '- [multiple_girls](wof-tag:multiple_girls)';
    await _pump(
      tester,
      const TagWikiScreen(
        initialTag: '1girl',
        directory: WikiDirectory(roots: [], groups: {}),
      ),
      auto,
      catalog: _Tags(entries: _uiTags()),
    );
    // Card keys restart inside each markdown pass, so the translated and
    // the original example list each produce cards 0..2.
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('wiki-example-card-$i')), findsNWidgets(2));
    }
    // The 「另见」 list is not in an example section; it stays a chip cloud
    // on both halves.
    expect(find.byKey(const Key('wiki-chip-2girls')), findsNWidgets(2));
    expect(find.byKey(const Key('wiki-chip-1girl')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('example card keeps inline content on one line', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auto = _Auto()
      ..bodyOverride =
          '引言。\n\n'
          '## 示例\n\n'
          '- [1girl](wof-tag:1girl) 与 [1boy](wof-tag:1boy)\n\n'
          '## 例子\n\n'
          '- [solo](wof-tag:solo) 与 [1boy](wof-tag:1boy)\n\n'
          '- [1girl](wof-tag:1girl) 补充\n';
    await _pump(
      tester,
      const TagWikiScreen(
        initialTag: '1girl',
        directory: WikiDirectory(roots: [], groups: {}),
      ),
      auto,
      catalog: _Tags(entries: _uiTags()),
    );
    // Each mixed li must land in one paragraph inside one card, not split
    // into one block per child node. The 「例子」 list is loose (blank line
    // between items), so its li children arrive wrapped in `p`.
    final inCard = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey &&
          (widget.key! as ValueKey).value.toString().startsWith(
            'wiki-example-card-',
          ),
    );
    for (final text in const ['1girl 与 1boy', 'solo 与 1boy', '1girl 补充']) {
      final line = find.text(text, findRichText: true);
      expect(line, findsOneWidget, reason: '$text should render inline');
      expect(find.ancestor(of: line, matching: inCard), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hovering body links, chips and related cells shows the preview card',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final params = _Params();
      final auto = _Auto()
        ..bodyOverride =
            '一名女性角色的图片。请参见 [solo](wof-tag:solo) 了解更多。\n\n'
            '## 另见\n\n'
            '- [1boy](wof-tag:1boy)\n'
            '- [1other](wof-tag:1other)\n'
            '- [2girls](wof-tag:2girls)';
      await _pump(
        tester,
        const TagWikiScreen(
          initialTag: '1girl',
          directory: WikiDirectory(roots: [], groups: {}),
        ),
        auto,
        catalog: _Tags(entries: _uiTags()),
        params: params,
        related: const [
          CompletionCandidate(
            canonicalTag: 'smile',
            translation: '微笑',
            postCount: 1000,
            cooccurrenceCount: 400,
            category: TagCategory.general,
            matchKind: CompletionMatchKind.englishExact,
            sources: {CompletionSourceKind.base},
          ),
        ],
      );
      final gesture = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      // Plain text does not open the card.
      await gesture.moveTo(_inlineTextCenter(tester, '一名女性角色', '了解更多'));
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byKey(const Key('wiki-preview-open')), findsNothing);
      // Hovering the inline link for 300ms opens it.
      await gesture.moveTo(_inlineTextCenter(tester, '一名女性角色', 'solo'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byKey(const Key('wiki-preview-open')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('wiki-tag-preview-card')),
          matching: find.text('单人'),
        ),
        findsOneWidget,
      );
      await capture(tester, 'hover-card-1440-zh');
      // The pointer can move into the card without it closing.
      await gesture.moveTo(
        tester.getCenter(find.byKey(const Key('wiki-preview-open'))),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('wiki-preview-open')), findsOneWidget);
      // The add button runs the usual add-to-prompt flow.
      await tester.tap(find.byKey(const Key('wiki-preview-add')));
      // Dismissal re-evaluates hover at the resting pointer spot, which may
      // land on another previewable target, so park the pointer first.
      await gesture.moveTo(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(params.state.prompt, contains('solo'));
      expect(find.byKey(const Key('wiki-preview-open')), findsNothing);
      // A chip opens the same card.
      final chip = find.byKey(const Key('wiki-chip-1boy'));
      expect(chip, findsOneWidget);
      await gesture.moveTo(tester.getCenter(chip));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byKey(const Key('wiki-preview-open')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('wiki-tag-preview-card')),
          matching: find.text('1个男孩'),
        ),
        findsOneWidget,
      );
      // Moving onto ordinary space closes it after the leave delay.
      await gesture.moveTo(_inlineTextCenter(tester, '一名女性角色', '了解更多'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('wiki-preview-open')), findsNothing);
      // So does a related-grid cell.
      await tester.ensureVisible(find.byKey(const Key('wiki-related-smile')));
      await gesture.moveTo(
        tester.getCenter(find.byKey(const Key('wiki-related-smile'))),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byKey(const Key('wiki-preview-open')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('wiki-tag-preview-card')),
          matching: find.text('微笑'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  // CAPTURE_WIKI_REDESIGN=1 records the confirmed three-column matrix:
  // five locales × light/dark × 1440/1100/680 (680 is single-column) plus an
  // Aa reading-settings overlay shot per locale/theme at 1440.
  if (Platform.environment['CAPTURE_WIKI_REDESIGN'] == '1') {
    for (final lang in const ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
      for (final brightness in Brightness.values) {
        for (final width in const [1440.0, 1100.0, 680.0]) {
          testWidgets(
            'wiki redesign matrix $lang ${brightness.name} ${width.toInt()}',
            (tester) async {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await _pump(
                tester,
                const TagWikiScreen(
                  initialTag: '1girl',
                  directory: _captureDirectory,
                ),
                _Auto()..bodyOverride = _uiBody,
                catalog: _Tags(entries: _uiTags()),
                related: _captureRelated(),
                locale: lang == 'zh_TW'
                    ? const Locale('zh', 'TW')
                    : Locale(lang),
                brightness: brightness,
                chrome: true,
              );
              expect(tester.takeException(), isNull);
              expect(
                find.byKey(const ValueKey('wiki-related-section')),
                findsOneWidget,
              );
              expect(
                find.byKey(const ValueKey('wiki-directory-paths')),
                findsOneWidget,
              );
              final name = 'matrix-${width.toInt()}-$lang';
              await capture(tester, name, brightness.name);
              if (width == 1440) {
                await tester.tap(
                  find.byKey(const ValueKey('wiki-reading-button')),
                );
                await tester.pumpAndSettle();
                await capture(tester, '$name-aa', brightness.name);
              }
            },
          );
        }
      }
    }
    // Bilingual reading captures: zh/en × light/dark at 1440 plus zh light
    // at 1100 where the outline rail hides.
    const bilingualOriginal =
        'An image containing a single female character. '
        'Only living characters visibly present in the image count toward '
        'this tag.\n\n'
        'For images containing a single character, see [solo](wof-tag:solo).\n\n'
        '## Examples\n\n'
        '- [1girl](wof-tag:1girl) [solo](wof-tag:solo)\n'
        '- [1girl](wof-tag:1girl) and [1boy](wof-tag:1boy)\n\n'
        '## See also\n\n- [1boy](wof-tag:1boy)\n- [1other](wof-tag:1other)\n'
        '- [2girls](wof-tag:2girls)\n- [multiple girls](wof-tag:multiple_girls)';
    for (final lang in const ['zh', 'en']) {
      for (final brightness in Brightness.values) {
        testWidgets('wiki bilingual capture $lang ${brightness.name} 1440', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(1440, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({
            'wiki_show_translation': true,
            'wiki_bilingual': true,
          });
          await _pump(
            tester,
            const TagWikiScreen(
              initialTag: '1girl',
              directory: _captureDirectory,
            ),
            _Auto()
              ..bodyOverride = _uiBody
              ..originalOverride = bilingualOriginal,
            catalog: _Tags(entries: _uiTags()),
            related: _captureRelated(),
            locale: Locale(lang),
            brightness: brightness,
            chrome: true,
          );
          expect(tester.takeException(), isNull);
          await capture(tester, 'bilingual-1440-$lang', brightness.name);
        });
      }
    }
    testWidgets('wiki bilingual capture zh light 1100', (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'wiki_show_translation': true,
        'wiki_bilingual': true,
      });
      await _pump(
        tester,
        const TagWikiScreen(initialTag: '1girl', directory: _captureDirectory),
        _Auto()
          ..bodyOverride = _uiBody
          ..originalOverride = bilingualOriginal,
        catalog: _Tags(entries: _uiTags()),
        related: _captureRelated(),
        brightness: Brightness.light,
        chrome: true,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'bilingual-1100-zh', 'light');
    });
  }
}

const _captureDirectory = WikiDirectory(
  roots: [
    WikiDirectoryNode(
      label: 'Visual characteristics',
      children: [
        WikiDirectoryNode(
          label: 'Image composition and style',
          children: [
            WikiDirectoryNode(
              label: 'Image Composition',
              children: [
                WikiDirectoryNode(
                  label: 'Character Count',
                  group: 'tag_group:character_count',
                  children: [],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    WikiDirectoryNode(label: 'Attire and body accessories', children: []),
  ],
  groups: {
    'tag_group:character_count': WikiDirectoryGroup(
      title: 'tag_group:character_count',
      members: ['1girl', '1boy', '2girls', 'solo', 'multiple_girls'],
      children: [],
      sourceUrl: '',
    ),
  },
);

List<CompletionCandidate> _captureRelated() => [
  for (final row in const [
    ('solo', 3800000),
    ('long_hair', 2600000),
    ('looking_at_viewer', 1900000),
    ('smile', 1500000),
    ('blush', 1400000),
    ('blue_eyes', 1200000),
    ('1boy', 900000),
    ('open_mouth', 800000),
    ('2girls', 600000),
  ])
    CompletionCandidate(
      canonicalTag: row.$1,
      category: TagCategory.general,
      postCount: row.$2,
      cooccurrenceCount: row.$2,
      matchKind: CompletionMatchKind.englishExact,
      sources: const {CompletionSourceKind.base},
    ),
];
