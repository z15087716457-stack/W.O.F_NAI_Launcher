import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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

CompletionCandidate tag(String name) => CompletionCandidate(
  canonicalTag: name,
  category: TagCategory.general,
  postCount: 100,
  matchKind: CompletionMatchKind.englishPrefix,
  sources: const {CompletionSourceKind.base},
);

class Source implements CompletionSource {
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery q) async => [
    tag('blue_hair'),
    tag('red_hair'),
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
      negative: negative,
      cancellation: cancellation,
      result: result,
    ));
    return result.future;
  }
}

void main() {
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
  });
  tearDown(Hive.close);
  Future<void> pump(
    WidgetTester tester,
    TextEditingController controller,
    FakeRag rag, {
    bool negative = false,
  }) async {
    final source = Source();
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
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 80,
                child: TagExpansionWrapper(
                  ragContext: true,
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
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('editor')));
    await tester.idle();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

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
