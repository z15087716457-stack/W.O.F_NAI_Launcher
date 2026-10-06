import 'dart:ui' as ui;

import 'package:flutter/gestures.dart'
    show kBackMouseButton, kForwardMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/cooccurrence_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/wiki_bookmark_store.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_edit_dialog.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_linked_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tags = [
  for (final row in const [
    ('1girl', '1个女孩', 6000000, TagCategory.general),
    ('solo', '单人', 5000000, TagCategory.general),
    ('1boy', '1个男孩', 1400000, TagCategory.general),
    ('blue_eyes', '蓝眼睛', 1800000, TagCategory.general),
    ('safebooru', null, 9000000, TagCategory.meta),
  ])
    CompletionCandidate(
      canonicalTag: row.$1,
      translation: row.$2,
      postCount: row.$3,
      category: row.$4,
      matchKind: CompletionMatchKind.englishExact,
      sources: const {CompletionSourceKind.base},
    ),
];

class _Tags extends UnifiedTagRepository {
  _Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async => throw StateError('not used'),
      );

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

  @override
  Future<List<CompletionCandidate>> byNames(Iterable<String> names) async =>
      tags.where((item) => names.contains(item.canonicalTag)).toList();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => tags;

  @override
  Future<List<CompletionCandidate>> searchContains(
    String input, {
    int limit = 20,
  }) async => const [];
}

class _Wiki implements TagWikiRepository {
  _Wiki([this.body = 'A simple body.']);
  final String body;
  @override
  Future<TagWikiEntry?> find(String tag) async =>
      TagWikiEntry(tag: tag, body: body, sourceUrl: '');
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
  _Params([this.initial = '']);
  final String initial;
  @override
  ImageParams build() => ImageParams(prompt: initial);
  @override
  void updatePromptImmediately(String prompt) {
    if (state.prompt == prompt) return;
    state = state.copyWith(prompt: prompt);
  }
}

class _Blocks extends PromptBlockLibraryNotifier {
  final folders = [PromptBlockFolder.create(id: 'wiki-folder', name: '百科')];
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: folders);
  @override
  Future<PromptBlock> createBlock({
    required String title,
    required String content,
    String? folderId,
    String color = '#FF607D8B',
    String appearance = 'classic',
    String? readingTranslationZh,
    List<Map<String, dynamic>>? readingTranslationMarks,
    bool readingTranslationNeedsReview = false,
    String readingTranslationLanguageCode = 'zh',
    bool readingTranslationEdited = false,
    String? iconName,
    String? thumbnail,
    double thumbnailOffsetX = 0.0,
    double thumbnailOffsetY = 0.0,
    double thumbnailScale = 1.0,
    int? sortOrder,
    List<String>? atoms,
    String negativeContent = '',
    List<String>? negativeAtoms,
    PromptBlockGenerationSettings? generationSettings,
    List<PromptBlockTag> tags = const [],
  }) async {
    final block = PromptBlock.create(
      title: title,
      content: content,
      folderId: folderId,
      atoms: atoms,
      negativeContent: negativeContent,
      negativeAtoms: negativeAtoms,
      generationSettings: generationSettings,
    );
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: [...?state.valueOrNull?.blocks, block],
        folders: folders,
      ),
    );
    return block;
  }
}

class _Auto extends ChangeNotifier implements AutoTagTranslationController {
  String? bodyOverride;
  @override
  String? wikiFor(String tag) => bodyOverride;
  @override
  String? nameFor(String tag) =>
      tags.where((item) => item.canonicalTag == tag).firstOrNull?.translation;
  @override
  bool get enabled => false;
  @override
  int get activeRequests => 0;
  @override
  bool isWikiTranslating(String tag) => false;
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

const _directory = WikiDirectory(
  roots: [
    WikiDirectoryNode(
      label: 'Visual characteristics',
      children: [
        WikiDirectoryNode(label: 'Blue tags', group: 'blue', children: []),
      ],
    ),
  ],
  groups: {
    'blue': WikiDirectoryGroup(
      title: 'Blue tags',
      members: ['blue_eyes'],
      children: [],
      sourceUrl: '',
    ),
  },
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String? initialTag,
  _Params? params,
  _Auto? auto,
  _Wiki? wiki,
  List<CompletionCandidate>? related,
  double width = 1600,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        autoTagTranslationProvider.overrideWith((_) => auto ?? _Auto()),
        unifiedTagRepositoryProvider.overrideWith((_) => _Tags()),
        tagWikiRepositoryProvider.overrideWithValue(wiki ?? _Wiki()),
        cooccurrenceCompletionSourceProvider.overrideWithValue(
          _Cooccurrence(related ?? const []),
        ),
        generationParamsNotifierProvider.overrideWith(
          () => params ?? _Params(),
        ),
        wikiTagLinksProvider.overrideWithValue(
          WikiTagLinks(
            exactLookup: (names) async => {
              for (final item in tags)
                if (names.contains(item.canonicalTag)) item.canonicalTag: item,
            },
          ),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TagWikiScreen(initialTag: initialTag, directory: _directory),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(TagWikiScreen)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'article saves a tag to the chosen block folder without editing drafts',
    (tester) async {
      final container = await _pump(
        tester,
        initialTag: '1girl',
        params: _Params('solo'),
      );
      await tester.tap(find.byKey(const Key('wiki-add-to-block')));
      await tester.pumpAndSettle();
      final dialog = tester.widget<PromptBlockEditDialog>(
        find.byType(PromptBlockEditDialog),
      );
      expect(dialog.initialContent, '1girl');
      expect(dialog.initialTitle, '1个女孩');
      expect(container.read(generationParamsNotifierProvider).prompt, 'solo');
      expect(find.byType(SnackBar), findsNothing);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new user draft');
      await tester.tap(
        find
            .descendant(
              of: find.byType(PromptBlockEditDialog),
              matching: find.byType(DropdownButtonFormField<String>),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('百科').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();
      final block = container
          .read(promptBlockLibraryNotifierProvider)
          .value!
          .blocks
          .single;
      expect(block.content, '1girl');
      expect(block.folderId, 'wiki-folder');
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'new user draft',
      );
      expect(find.byType(PromptBlockEditDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('已保存到块库'), findsNothing);
    },
  );

  testWidgets('cancelled block saving preserves the library and draft', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      initialTag: '1girl',
      params: _Params('solo, 1girl'),
    );
    await tester.tap(find.byKey(const Key('wiki-add-to-block')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();
    expect(
      container.read(promptBlockLibraryNotifierProvider).value!.blocks,
      isEmpty,
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'solo, 1girl',
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('co-occurrence section filters meta, sorts, opens and adds', (
    tester,
  ) async {
    final params = _Params();
    final container = await _pump(
      tester,
      initialTag: '1girl',
      params: params,
      related: [
        for (final tag in tags.where((item) => item.canonicalTag != '1girl'))
          CompletionCandidate(
            canonicalTag: tag.canonicalTag,
            category: tag.category,
            postCount: tag.postCount,
            translation: tag.translation,
            cooccurrenceCount: switch (tag.canonicalTag) {
              'solo' => 4000000,
              '1boy' => 300000,
              'blue_eyes' => 2000000,
              _ => 8000000,
            },
            matchKind: CompletionMatchKind.related,
            sources: const {CompletionSourceKind.cooccurrence},
          ),
      ],
    );
    await tester.pumpAndSettle();
    final section = find.byKey(const Key('wiki-related-section'));
    expect(section, findsOneWidget);
    // Meta tags never enter the grid.
    expect(find.byKey(const Key('wiki-related-safebooru')), findsNothing);
    expect(find.byKey(const Key('wiki-related-solo')), findsOneWidget);
    expect(find.byKey(const Key('wiki-outline-related')), findsOneWidget);
    // Share = count / 6M: solo 67%, blue_eyes 33%, 1boy 5% — descending.
    final soloTop = tester
        .getRect(find.byKey(const Key('wiki-related-solo')))
        .top;
    final eyesTop = tester
        .getRect(find.byKey(const Key('wiki-related-blue_eyes')))
        .top;
    expect(soloTop, lessThanOrEqualTo(eyesTop));
    final eyesCell = tester.getRect(
      find.byKey(const Key('wiki-related-blue_eyes')),
    );
    final boyCell = tester.getRect(find.byKey(const Key('wiki-related-1boy')));
    expect(eyesCell.left + eyesCell.top, lessThan(boyCell.left + boyCell.top));

    // Plain tap opens the tag; a new visit is remembered.
    await tester.tap(find.byKey(const Key('wiki-related-blue_eyes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
    // Directory section shows the real group path for blue_eyes.
    expect(find.byKey(const Key('wiki-directory-paths')), findsOneWidget);
    expect(find.textContaining('Blue tags'), findsWidgets);

    // Shift+click opens block saving instead of navigating.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const Key('wiki-related-solo')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(container.read(generationParamsNotifierProvider).prompt, '');
    expect(
      tester
          .widget<PromptBlockEditDialog>(find.byType(PromptBlockEditDialog))
          .initialContent,
      'solo',
    );
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
  });

  testWidgets('empty co-occurrence hides the section and its outline entry', (
    tester,
  ) async {
    await _pump(tester, initialTag: '1girl');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-related-section')), findsNothing);
    expect(find.byKey(const Key('wiki-outline-related')), findsNothing);
    // blue_eyes still has a directory path once selected.
    tester
        .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
        .onTagTap(tags[3]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-directory-paths')), findsOneWidget);
  });

  testWidgets('pure link lists render as chips only when eligible', (
    tester,
  ) async {
    // Lists must be separated by real paragraphs — adjacent bullet lists
    // merge into a single <ul> per CommonMark.
    const body =
        '说明。\n\n- [1boy](wof-tag:1boy)\n- [blue_eyes](wof-tag:blue_eyes)\n'
        '- [solo](wof-tag:solo)\n\n对比：\n\n'
        '- [1girl](wof-tag:1girl) 与 [1boy](wof-tag:1boy)\n'
        '- [blue eyes](wof-tag:blue_eyes)\n- [solo](wof-tag:solo)\n\n'
        '两个：\n\n'
        '- [1girl](wof-tag:1girl)\n- [solo](wof-tag:solo)\n\n'
        '外链：\n\n'
        '- [safe](https://safebooru.example/a)\n- [1boy](wof-tag:1boy)\n'
        '- [solo](wof-tag:solo)';
    await _pump(
      tester,
      initialTag: '1girl',
      auto: _Auto()..bodyOverride = body,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-1girl')), findsOneWidget);
    // Only the first list is a pure >=3 link list and becomes chips.
    expect(find.byKey(const Key('wiki-chip-1boy')), findsOneWidget);
    expect(find.byKey(const Key('wiki-chip-blue_eyes')), findsOneWidget);
    expect(find.byKey(const Key('wiki-chip-solo')), findsOneWidget);
    // The "与" list and the two-item list keep bullet rendering; 1girl never
    // becomes a chip.
    expect(find.byKey(const Key('wiki-chip-1girl')), findsNothing);
    expect(find.textContaining('与', findRichText: true), findsOneWidget);
    // External links keep the whole list unconverted.
    expect(find.text('safe', findRichText: true), findsOneWidget);
  });

  testWidgets('forward history and mouse side buttons navigate visits', (
    tester,
  ) async {
    await _pump(tester, initialTag: '1girl');
    tester
        .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
        .onTagTap(tags[1]);
    await tester.pumpAndSettle();
    tester
        .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
        .onTagTap(tags[2]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-1boy')), findsOneWidget);

    await tester.tap(find.byKey(const Key('wiki-history-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-solo')), findsOneWidget);
    // Mouse forward button goes forward again.
    final pointer = TestPointer(
      1,
      ui.PointerDeviceKind.mouse,
      1,
      kForwardMouseButton,
    );
    await tester.sendEventToBinding(pointer.down(const Offset(800, 400)));
    await tester.sendEventToBinding(pointer.up());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-1boy')), findsOneWidget);
    // Mouse back button goes back.
    final backPointer = TestPointer(
      1,
      ui.PointerDeviceKind.mouse,
      1,
      kBackMouseButton,
    );
    await tester.sendEventToBinding(backPointer.down(const Offset(800, 400)));
    await tester.sendEventToBinding(backPointer.up());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-solo')), findsOneWidget);

    // A fresh navigation clears the forward stack.
    tester
        .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
        .onTagTap(tags[3]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('wiki-history-forward')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keyboard shortcuts move focus, selection, bookmark and block saving',
    (tester) async {
      final params = _Params();
      final container = await _pump(
        tester,
        initialTag: '1girl',
        params: params,
      );
      String prompt() =>
          container.read(generationParamsNotifierProvider).prompt;

      // "/" focuses the search field.
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const Key('wiki-search')),
      );
      expect(field.focusNode!.hasFocus, isTrue);

      // Arrows still move the list selection while the field is focused.
      // The list is sorted by post count: safebooru, 1girl, solo, blue_eyes…
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-body-solo')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);

      // Typing in the field must not trigger the B/Enter shortcuts.
      final bookmarks = container.read(wikiBookmarkStoreProvider);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump();
      expect(bookmarks.contains('blue_eyes'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(prompt(), '');

      // Clearing the search switches to the unfiltered browse list whose first
      // entry is 1girl.
      await tester.enterText(find.byKey(const Key('wiki-search')), '');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-body-1girl')), findsOneWidget);

      // Enter outside editable fields opens block saving for the selected tag.
      Focus.of(
        tester.element(find.byKey(const Key('wiki-add-to-block'))),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(prompt(), '');
      expect(
        tester
            .widget<PromptBlockEditDialog>(find.byType(PromptBlockEditDialog))
            .initialContent,
        '1girl',
      );
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();
      Focus.of(
        tester.element(find.byKey(const Key('wiki-add-to-block'))),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump();
      expect(bookmarks.contains('1girl'), isTrue);
    },
  );

  testWidgets('article TOC shows at 1440 beside a clamped reading column', (
    tester,
  ) async {
    await _pump(
      tester,
      initialTag: '1girl',
      width: 1440,
      wiki: _Wiki('简介。\n\n## 用法\n\n正文内容。'),
    );
    await tester.pumpAndSettle();
    // Article area is 1440 - 216 - 300 = 924 >= 560 + 168 + 48, so the
    // contents rail appears next to a column clamped to <= 760.
    expect(find.byKey(const Key('wiki-outline-intro')), findsOneWidget);
    final column = tester.getRect(find.byKey(const Key('wiki-reading-column')));
    expect(column.width, lessThanOrEqualTo(760));
    expect(column.width, greaterThanOrEqualTo(560));
    expect(
      tester.getRect(find.byKey(const Key('wiki-outline-intro'))).left,
      greaterThanOrEqualTo(column.right),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow selection is not remembered and modifiers are ignored', (
    tester,
  ) async {
    final container = await _pump(tester, initialTag: '1girl', width: 1600);
    final bookmarks = container.read(wikiBookmarkStoreProvider);
    // A real list tap lands in history; keyboard moves after it must not.
    await tester.tap(find.byKey(const Key('wiki-row-blue_eyes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-blue_eyes')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('wiki-history-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-body-1girl')), findsOneWidget);

    // Ctrl+B must not toggle the bookmark shortcut.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(bookmarks.contains('1girl'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
