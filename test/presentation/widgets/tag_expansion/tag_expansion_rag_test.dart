import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_meaning.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_tag_search.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';
import '../../../helpers/studio_capture_fonts.dart';

CompletionCandidate tag(String name) => CompletionCandidate(
  canonicalTag: name,
  category: TagCategory.general,
  postCount: 100,
  matchKind: CompletionMatchKind.englishPrefix,
  sources: const {CompletionSourceKind.base},
);

class Source implements CompletionSource {
  Source({
    this.empty = false,
    this.count = 2,
    this.exact = false,
    this.prefixName,
  });
  final bool empty;
  final int count;
  final bool exact;
  final String? prefixName;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery q) async => empty
      ? []
      : [
          prefixName != null
              ? tag(prefixName!)
              : exact
              ? tag(
                  'blue_hair',
                ).copyWith(matchKind: CompletionMatchKind.englishExact)
              : tag('blue_hair'),
          tag('red_hair'),
          for (var i = 2; i < count; i++) tag('fixture_$i'),
        ];
}

class Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => null;
}

class FakeRag extends RagController {
  final requests =
      <
        ({
          String query,
          int limit,
          Set<String> existing,
          RagCancellation cancellation,
          Completer<List<CompletionCandidate>> result,
        })
      >[];
  @override
  RagStatus build() =>
      const RagStatus(phase: 'partial', indexed: 20, total: 100, partial: true);
  @override
  Future<List<CompletionCandidate>> searchTags({
    required String query,
    required Set<String> existing,
    required RagCancellation cancellation,
    int limit = 40,
    RagTagSearchOptions tagOptions = const RagTagSearchOptions(),
  }) {
    final result = Completer<List<CompletionCandidate>>();
    requests.add((
      query: query,
      limit: limit,
      existing: Set.of(existing),
      cancellation: cancellation,
      result: result,
    ));
    return result.future;
  }
}

void main() {
  final captureKey = GlobalKey();
  final capturePath = Platform.environment['TAG_RAG_CAPTURE'];
  setUpAll(() async {
    if (capturePath != null) {
      await loadStudioCaptureFonts();
    }
  });
  Future<void> capture(WidgetTester tester, String name) async {
    if (capturePath == null) return;
    final boundary =
        captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      void repaint(RenderObject object) {
        object.markNeedsPaint();
        object.visitChildren(repaint);
      }

      repaint(boundary);
      await tester.pump(const Duration(milliseconds: 180));
      await tester.runAsync(() async {
        final bitmap = await boundary.toImage(pixelRatio: 1);
        try {
          final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
          await Directory(capturePath).create(recursive: true);
          await File(
            '$capturePath/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
        } finally {
          bitmap.dispose();
        }
      });
    } finally {
      debugDisableShadows = shadows;
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
  });
  tearDown(Hive.close);
  Future<void> pump(
    WidgetTester tester,
    TextEditingController controller,
    FakeRag rag, {
    bool emptyLexical = false,
    bool relatedFromPrompt = true,
    int idleCount = 2,
    bool exactLexical = false,
    String? prefixName,
  }) async {
    final source = Source(
      empty: emptyLexical,
      count: idleCount,
      exact: exactLexical,
      prefixName: prefixName,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagMeaningProfileProvider.overrideWith((_, tag) async => null),
          ragControllerProvider.overrideWith(() => rag),
          ragSettingsProvider.overrideWith(EnabledSettings.new),
          localTagExpansionServiceProvider.overrideWithValue(
            LocalTagExpansionService(
              catalog: source,
              relatedTags: source,
              substringSearch: (s, {limit = 20}) async => [],
              popularSearch: ({limit = 12}) async => [
                tag('blue_hair'),
                tag('red_hair'),
              ],
            ),
          ),
          tagWikiRepositoryProvider.overrideWithValue(Wiki()),
          wikiTagLinksProvider.overrideWithValue(
            WikiTagLinks(exactLookup: (_) async => {}),
          ),
        ],
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: capturePath == null
                ? null
                : ThemeData(
                    fontFamily: 'Geist',
                    fontFamilyFallback: const ['HarmonyOS Sans SC'],
                  ),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 80,
                  child: TagExpansionWrapper(
                    relatedFromPrompt: relatedFromPrompt,
                    controller: controller,
                    child: TextField(
                      key: const Key('editor'),
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('editor')));
    await tester.idle();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  Future<void> typeQuery(WidgetTester tester, String query) async {
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      query,
    );
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
  }

  testWidgets(
    'idle keeps the full local list without starting semantic search',
    (tester) async {
      final c = TextEditingController(text: 'rain, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, idleCount: 40);
      expect(rag.requests, isEmpty);
      await tester.drag(
        find.byKey(const ValueKey('tag-expansion-results')),
        const Offset(0, -2000),
      );
      await tester.pump();
      expect(find.text('fixture 39'), findsWidgets);
      expect(c.text, 'rain, ');
    },
  );

  testWidgets(
    'local matches appear immediately; the core owns final ordering',
    (tester) async {
      final c = TextEditingController(text: 'rain, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag);
      await typeQuery(tester, 'hair');
      expect(find.text('blue hair'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      rag.requests.single.result.complete([tag('grass')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('grass'), findsWidgets);
      expect(find.text('blue hair'), findsNothing);
      expect(c.text, 'rain, ');
      await capture(tester, 'stable-manual-results');
    },
  );

  testWidgets('a genuine local name prefix remains with semantic results', (
    tester,
  ) async {
    final c = TextEditingController(text: 'rain, ');
    final rag = FakeRag();
    addTearDown(c.dispose);
    await pump(tester, c, rag, prefixName: 'watercolor_effect');
    await typeQuery(tester, 'watercolor');
    rag.requests.single.result.complete([tag('grass')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('watercolor effect'), findsWidgets);
    expect(find.text('grass'), findsWidgets);
    expect(find.text('red hair'), findsNothing);
    expect(c.text, 'rain, ');
    await capture(tester, 'name-prefix-with-semantic-results');
  });

  testWidgets('saved result count reaches semantic retrieval', (tester) async {
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.tagExpansionResultLimit, 80);
    final c = TextEditingController(text: 'rain, ');
    final rag = FakeRag();
    addTearDown(c.dispose);
    await pump(tester, c, rag);
    await typeQuery(tester, '独立袖子');
    expect(rag.requests.single.limit, 80);
    rag.requests.single.result.complete([tag('detached_sleeves')]);
    await tester.pump();
  });

  testWidgets('ordinary fields use explicit queries without prompt context', (
    tester,
  ) async {
    final c = TextEditingController(text: 'unrelated_query');
    final rag = FakeRag();
    addTearDown(c.dispose);
    await pump(tester, c, rag, relatedFromPrompt: false);
    expect(rag.requests, isEmpty);
    await typeQuery(tester, '绿色的植被');
    expect(rag.requests.single.query, '绿色的植被');
    rag.requests.single.result.complete([tag('grass')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('grass'), findsWidgets);
  });

  testWidgets(
    'an exact local name survives semantic completion without duplicates',
    (tester) async {
      final c = TextEditingController(text: 'rain, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, exactLexical: true);
      await typeQuery(tester, 'blue_hair');
      rag.requests.single.result.complete([tag('grass'), tag('blue_hair')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('blue hair'), findsWidgets);
      expect(find.text('grass'), findsWidgets);
      expect(find.text('red hair'), findsNothing);
      expect(c.text, 'rain, ');
      await capture(tester, 'exact-name-with-semantic-results');
    },
  );

  testWidgets(
    'natural-language queries preserve existing-tag exclusion and the draft',
    (tester) async {
      final c = TextEditingController(text: '1girl, blue_hair, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, emptyLexical: true);
      await typeQuery(tester, '在阳光下奔跑');
      final query = rag.requests.single;
      expect(query.query, '在阳光下奔跑');
      expect(query.existing, contains('blue_hair'));
      expect(find.text('No local tags found'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await capture(tester, 'natural-query-loading');
      query.result.complete([tag('running'), tag('sunlight')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('running'), findsWidgets);
      expect(find.text('sunlight'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(c.text, '1girl, blue_hair, ');
      await capture(tester, 'natural-query-results');
    },
  );

  testWidgets(
    'an empty result appears only after explicit semantic search finishes',
    (tester) async {
      final c = TextEditingController();
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, emptyLexical: true);
      await typeQuery(tester, '在阳光下奔跑');
      expect(rag.requests.single.query, '在阳光下奔跑');
      expect(find.text('No local tags found'), findsNothing);
      rag.requests.single.result.complete([]);
      await tester.pump();
      await tester.pump();
      expect(find.text('No local tags found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(c.text, isEmpty);
    },
  );

  testWidgets('late cancelled results cannot overwrite a newer query', (
    tester,
  ) async {
    final c = TextEditingController(text: 'night, ');
    final rag = FakeRag();
    addTearDown(c.dispose);
    await pump(tester, c, rag, emptyLexical: true);
    await typeQuery(tester, '在阳光下奔跑');
    final old = rag.requests.single;
    await typeQuery(tester, '在雨中跳舞');
    final current = rag.requests.last;
    expect(old.cancellation.isCancelled, isTrue);
    old.result.complete([tag('old_result')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('old result'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    current.result.complete([tag('dancing')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('dancing'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'clearing a query returns to local cooccurrence without another model call',
    (tester) async {
      final c = TextEditingController(text: 'rain, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag);
      await typeQuery(tester, '在阳光下奔跑');
      final pending = rag.requests.single;
      await typeQuery(tester, '');
      expect(pending.cancellation.isCancelled, isTrue);
      expect(rag.requests.length, 1);
      pending.result.complete([tag('running')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('blue hair'), findsWidgets);
      expect(find.text('running'), findsNothing);
    },
  );

  testWidgets(
    'negative fields keep their own exclusions during explicit search',
    (tester) async {
      final c = TextEditingController(text: 'lowres, blurry, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag);
      expect(rag.requests, isEmpty);
      await typeQuery(tester, '压缩失真');
      expect(rag.requests.single.existing, contains('blurry'));
      rag.requests.single.result.complete([tag('jpeg_artifacts')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('jpeg artifacts'), findsWidgets);
    },
  );

  testWidgets(
    'keyboard selection stays stable when semantic results arrive late',
    (tester) async {
      final c = TextEditingController(text: 'rain, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag);
      await typeQuery(tester, 'hair');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      rag.requests.single.result.complete([tag('umbrella')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('umbrella'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(c.text, contains('red hair'));
      expect(find.byKey(const ValueKey('tag-expansion-popup')), findsOneWidget);
      expect(rag.requests.length, 1);
    },
  );

  testWidgets('closing the popup cancels its query and discards late results', (
    tester,
  ) async {
    final c = TextEditingController(text: 'night, ');
    final rag = FakeRag();
    addTearDown(c.dispose);
    await pump(tester, c, rag);
    await typeQuery(tester, '伞');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(rag.requests.single.cancellation.isCancelled, isTrue);
    rag.requests.single.result.complete([tag('umbrella')]);
    await tester.pump();
    expect(find.text('umbrella'), findsNothing);
    expect(c.text, 'night, ');
  });
}

class EnabledSettings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(enabled: true);
}
