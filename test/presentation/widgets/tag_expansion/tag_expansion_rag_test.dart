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
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
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
  Source({this.empty = false, this.count = 2});
  final bool empty;
  final int count;
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery q) async => empty
      ? []
      : [
          tag('blue_hair'),
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
          String text,
          String keyword,
          int cursor,
          Set<String> existing,
          bool negative,
          RagCancellation cancellation,
          Completer<List<CompletionCandidate>> result,
        })
      >[];
  @override
  RagStatus build() =>
      const RagStatus(phase: 'partial', indexed: 20, total: 100, partial: true);
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
  }) {
    final result = Completer<List<CompletionCandidate>>();
    requests.add((
      text: text,
      keyword: keyword,
      cursor: cursor,
      existing: Set.of(existing),
      negative: negative,
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
    bool negative = false,
    bool emptyLexical = false,
    bool ragContext = true,
    int idleCount = 2,
  }) async {
    final source = Source(empty: emptyLexical, count: idleCount);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
                    ragContext: ragContext,
                    ragNegative: negative,
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
    'unavailable semantic results restore the full ordinary list without truncating it to the pinned group',
    (tester) async {
      final c = TextEditingController(text: 'rain, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, idleCount: 40);
      rag.requests.single.result.complete([]);
      await tester.pump();
      await tester.pump();
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
    'idle cooccurrence remains in place when semantic suggestions finish',
    (tester) async {
      final c = TextEditingController(text: 'green_theme, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag);
      expect(find.text('blue hair'), findsWidgets);
      rag.requests.single.result.complete([tag('grass'), tag('forest')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('blue hair'), findsWidgets);
      expect(find.text('red hair'), findsWidgets);
      expect(find.text('grass'), findsWidgets);
      expect(find.text('forest'), findsWidgets);
      expect(c.text, 'green_theme, ');
    },
  );

  testWidgets('manual search publishes nonexact results once after reranking', (
    tester,
  ) async {
    final c = TextEditingController(text: 'rain, ');
    final rag = FakeRag();
    addTearDown(c.dispose);
    await pump(tester, c, rag);
    rag.requests.single.result.complete([]);
    await tester.pump();
    await typeQuery(tester, '绿色的植被');
    expect(find.text('blue hair'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    rag.requests.last.result.complete([tag('grass')]);
    await tester.pump();
    await tester.pump();
    expect(find.text('grass'), findsWidgets);
    expect(c.text, 'rain, ');
    await capture(tester, 'stable-manual-results');
  });

  testWidgets(
    'ordinary fields use explicit RAG queries without prompt context',
    (tester) async {
      final c = TextEditingController(text: 'unrelated_query');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, ragContext: false);
      expect(rag.requests, isEmpty);
      await typeQuery(tester, '绿色的植被');
      expect(rag.requests.single.keyword, '绿色的植被');
      expect(rag.requests.single.text, isEmpty);
      expect(rag.requests.single.cursor, 0);
      rag.requests.single.result.complete([tag('grass')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('grass'), findsWidgets);
    },
  );

  testWidgets(
    'manual natural-language search excludes prompt context but retains existing-tag dedup',
    (tester) async {
      final c = TextEditingController(text: '1girl, blue_hair, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, emptyLexical: true);
      rag.requests.single.result.complete([]);
      await tester.pump();
      await typeQuery(tester, '在阳光下奔跑');
      final query = rag.requests.last;
      expect(query.keyword, '在阳光下奔跑');
      expect(query.text, isEmpty);
      expect(query.cursor, 0);
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
    'a manual query can start from an empty editor; empty result appears only after RAG finishes',
    (tester) async {
      final c = TextEditingController();
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, emptyLexical: true);
      rag.requests.single.result.complete([]);
      await tester.pump();
      await typeQuery(tester, '在阳光下奔跑');
      expect(rag.requests.last.keyword, '在阳光下奔跑');
      expect(find.text('No local tags found'), findsNothing);
      rag.requests.last.result.complete([]);
      await tester.pump();
      await tester.pump();
      expect(find.text('No local tags found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(c.text, isEmpty);
    },
  );

  testWidgets(
    'late cancelled search cannot overwrite a new query or clear its loading state',
    (tester) async {
      final c = TextEditingController(text: 'night, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, emptyLexical: true);
      rag.requests.single.result.complete([]);
      await tester.pump();
      await typeQuery(tester, '在阳光下奔跑');
      final old = rag.requests.last;
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
    },
  );

  testWidgets('clearing a manual query restores the original prompt context', (
    tester,
  ) async {
    final c = TextEditingController(text: 'rain, ');
    final rag = FakeRag();
    addTearDown(c.dispose);
    await pump(tester, c, rag, emptyLexical: true, negative: true);
    rag.requests.single.result.complete([]);
    await tester.pump();
    await typeQuery(tester, '在阳光下奔跑');
    rag.requests.last.result.complete([]);
    await tester.pump();
    await typeQuery(tester, '');
    expect(rag.requests.last.keyword, isEmpty);
    expect(rag.requests.last.text, c.text);
    expect(rag.requests.last.negative, isTrue);
    rag.requests.last.result.complete([]);
    await tester.pump();
  });

  testWidgets(
    'semantic results replace idle candidates; queries stay in their own negative field',
    (tester) async {
      final c = TextEditingController(text: 'lowres, blurry, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag, negative: true);
      expect(rag.requests.single.text, c.text);
      expect(rag.requests.single.negative, isTrue);
      rag.requests.single.result.complete([tag('jpeg_artifacts')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('jpeg artifacts'), findsWidgets);
      expect(find.text('RAG'), findsOneWidget);
    },
  );
  testWidgets(
    'keyboard selection freezes a late rerank and insertion refreshes the next query',
    (tester) async {
      final c = TextEditingController(text: 'rain, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag);
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
      expect(rag.requests.length, 2);
      expect(rag.requests.last.text, c.text);
      rag.requests.last.result.complete([]);
      await tester.pump();
    },
  );
  testWidgets(
    'closing an editor cancels its own query and discards late results',
    (tester) async {
      final c = TextEditingController(text: 'night, ');
      final rag = FakeRag();
      addTearDown(c.dispose);
      await pump(tester, c, rag);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(rag.requests.single.cancellation.isCancelled, isTrue);
      rag.requests.single.result.complete([tag('umbrella')]);
      await tester.pump();
      expect(find.text('umbrella'), findsNothing);
      expect(c.text, 'night, ');
    },
  );
}

class EnabledSettings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(enabled: true);
}
