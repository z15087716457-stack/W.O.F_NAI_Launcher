import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_example_gallery.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_image_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_example_viewer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../../helpers/wiki_image_fixtures.dart';

final _captureBoundary = GlobalKey();

Future<void> _pump(
  WidgetTester tester,
  WikiExampleRepository repo,
  List<WikiExampleReference> refs, {
  ValueNotifier<List<WikiExampleReference>>? changing,
  ScrollController? outer,
  bool settle = true,
  double scale = 1,
}) async {
  final cache = await WikiImageFixtureCache.load();
  final values = changing ?? ValueNotifier(refs);
  final selection = ValueNotifier<WikiImageSelection?>(null);
  addTearDown(selection.dispose);
  if (changing == null) addTearDown(values.dispose);
  Widget panel = ValueListenableBuilder<List<WikiExampleReference>>(
    valueListenable: values,
    builder: (context, value, _) => ValueListenableBuilder<WikiImageSelection?>(
      valueListenable: selection,
      builder: (context, selected, _) => LayoutBuilder(
        builder: (context, viewport) => SizedBox(
          width: viewport.maxWidth,
          height: viewport.hasBoundedHeight ? viewport.maxHeight : 330,
          child: Stack(
            children: [
              SizedBox(
                width: 240,
                height: 330,
                child: WikiImagePanel(
                  tag: 'solo',
                  references: value,
                  onClose: () {},
                  selectedKey:
                      selected?.items[selected.index].reference.occurrenceKey,
                  onPreview: (next) {
                    selection.value =
                        next == null ||
                            next.items[next.index].reference.occurrenceKey ==
                                selected
                                    ?.items[selected.index]
                                    .reference
                                    .occurrenceKey
                        ? null
                        : next;
                  },
                ),
              ),
              if (selected != null)
                Positioned(
                  left: viewport.maxWidth >= 560 ? 243 : 0,
                  top: viewport.maxWidth >= 560 ? 0 : 333,
                  width: viewport.maxWidth >= 560
                      ? viewport.maxWidth - 243
                      : viewport.maxWidth,
                  height: 330,
                  child: WikiExampleViewer(
                    embedded: true,
                    examples: selected.items,
                    initial: selected.index,
                    cache: cache,
                    onClose: () => selection.value = null,
                    onChanged: (index) =>
                        selection.value = (items: selected.items, index: index),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  if (outer != null) {
    panel = SingleChildScrollView(
      controller: outer,
      child: Column(children: [panel, const SizedBox(height: 1200)]),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wikiExampleRepositoryProvider.overrideWithValue(repo),
        wikiExampleImageCacheProvider.overrideWithValue(cache),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.getTheme(AppStyle.geist, Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: _captureBoundary, child: child!),
        ),
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: panel),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  if (settle) await settleWikiImageFixtures(tester);
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );
  tearDown(
    () => VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    ),
  );

  testWidgets(
    'translated sections and assets share cards; section change closes the preview',
    (t) async {
      final batches = <String>[];
      final repo = WikiExampleRepository(
        fetchWiki: (_, {cancelToken}) async =>
            throw StateError('no remote Wiki request'),
        fetchPosts: (ids, {cancelToken}) async {
          batches.add('posts:$ids');
          return ids.map((id) => wikiImageMetadata(id)).toList();
        },
        fetchAssets: (ids, {cancelToken}) async {
          batches.add('assets:$ids');
          return ids.map((id) => wikiImageMetadata(id, asset: true)).toList();
        },
      );
      final refs = WikiImageDocument.parse(
        wikiImageSource,
      ).project(wikiImageTranslation).references;
      await _pump(t, repo, refs);
      expect(batches, hasLength(2));
      expect(find.text('场景中的单个人物'), findsOneWidget);
      await t.tap(find.byKey(const Key('wiki-example-open-11')));
      await settleWikiImageFixtures(t);
      expect(find.byKey(const Key('wiki-image-preview-panel')), findsOneWidget);
      expect(find.text('示例'), findsWidgets);
      await t.tap(find.text('非示例 1'));
      await settleWikiImageFixtures(t);
      expect(find.byKey(const Key('wiki-image-preview-panel')), findsNothing);
      expect(find.text('画面中还有其他人物'), findsOneWidget);
      expect(batches.last, contains('13'));
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'long section names use a dropdown and remain selectable at large text scale',
    (t) async {
      final repo = WikiExampleRepository(
        fetchWiki: (_, {cancelToken}) async => null,
        fetchPosts: (ids, {cancelToken}) async =>
            ids.map((id) => wikiImageMetadata(id)).toList(),
      );
      final refs = WikiImageDocument.parse(
        'h4. Appearance and official character illustrations\n* !post #21: First\n'
        'h4. Alternate costumes\n* !post #22: Second\n'
        'h4. Non-examples and similar characters\n* !post #23: Third',
      ).references;
      await _pump(t, repo, refs, scale: 1.5);
      await t.tap(find.byKey(const Key('wiki-image-group')));
      await t.pumpAndSettle();
      await t.tap(find.text('Non-examples and similar characters 1').last);
      await settleWikiImageFixtures(t);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('First'), findsNothing);
      expect(t.takeException(), isNull);
      await captureWikiImageLayout(
        t,
        _captureBoundary,
        'dark-long-section-dropdown',
      );
    },
  );

  testWidgets(
    'preview preserves repeated contexts and post versus asset identities without truncating captions',
    (t) async {
      final batches = <String>[];
      final repo = WikiExampleRepository(
        fetchWiki: (_, {cancelToken}) async => null,
        fetchPosts: (ids, {cancelToken}) async {
          batches.add('post:$ids');
          return ids.map((id) => wikiImageMetadata(id)).toList();
        },
        fetchAssets: (ids, {cancelToken}) async {
          batches.add('asset:$ids');
          return ids.map((id) => wikiImageMetadata(id, asset: true)).toList();
        },
      );
      final longCaption = ('A complete caption with details. ' * 30).trim();
      final refs = WikiImageDocument.parse(
        '* !post #11: $longCaption\n* !asset #11: Independent asset\n* !post #11: Another context',
      ).references;
      await _pump(t, repo, refs);
      expect(batches, ['post:[11]', 'asset:[11]']);
      expect(find.byKey(const Key('wiki-image-group')), findsNothing);
      final first = find.byKey(const Key('wiki-image-card-post:11:0'));
      await t.tap(
        find.descendant(
          of: first,
          matching: find.byKey(const Key('wiki-example-open-11')),
        ),
      );
      await settleWikiImageFixtures(t);
      expect(find.text(longCaption), findsWidgets);
      expect(
        find.byKey(const Key('wiki-example-large-post:11:0')),
        findsOneWidget,
      );
      await captureWikiImageLayout(
        t,
        _captureBoundary,
        'dark-lightbox-long-caption',
      );
      await t.tap(find.byKey(const Key('wiki-example-large-post:11:0')));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settleWikiImageFixtures(t);
      expect(
        find.byKey(const Key('wiki-example-large-asset:11:1')),
        findsOneWidget,
      );
      expect(find.text('Independent asset'), findsWidgets);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settleWikiImageFixtures(t);
      expect(
        find.byKey(const Key('wiki-example-large-post:11:2')),
        findsOneWidget,
      );
      expect(find.text('Another context'), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('asset preview fits a narrow window at enlarged text size', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 850);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final repo = WikiExampleRepository(
      fetchWiki: (_, {cancelToken}) async => null,
      fetchPosts: (ids, {cancelToken}) async => [],
      fetchAssets: (ids, {cancelToken}) async =>
          ids.map((id) => wikiImageMetadata(id, asset: true)).toList(),
    );
    await _pump(t, repo, const [
      WikiExampleReference(
        22435242,
        'A full description',
        kind: WikiImageKind.asset,
      ),
    ], scale: 1.5);
    await t.tap(find.byKey(const Key('wiki-example-open-22435242')));
    await settleWikiImageFixtures(t);
    expect(find.byKey(const Key('wiki-image-preview-panel')), findsOneWidget);
    expect(t.takeException(), isNull);
    await captureWikiImageLayout(
      t,
      _captureBoundary,
      'dark-lightbox-320-scale150',
    );
  });

  testWidgets(
    'large group requests 64 then continues, without eagerly building all cards',
    (t) async {
      final sizes = <int>[];
      final repo = WikiExampleRepository(
        fetchWiki: (_, {cancelToken}) async => null,
        fetchPosts: (ids, {cancelToken}) async {
          sizes.add(ids.length);
          return ids.map((id) => wikiImageMetadata(id)).toList();
        },
      );
      final refs = WikiImageDocument.parse(
        'h4. Costumes\n${List.generate(70, (i) => '* !post #${i + 1}: Outfit ${i + 1}').join('\n')}',
      ).references;
      await _pump(t, repo, refs);
      expect(sizes, [64]);
      expect(find.byType(WikiExampleCard).evaluate().length, lessThan(10));
      final list = t.widget<ListView>(find.byKey(const Key('wiki-image-list')));
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await settleWikiImageFixtures(t);
      await t.ensureVisible(find.text('加载更多（64/70）'));
      await t.tap(find.text('加载更多（64/70）'));
      await settleWikiImageFixtures(t);
      expect(sizes, [64, 6]);
      expect(find.text('加载更多（64/70）'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('metadata failure keeps captions and explicit retry recovers', (
    t,
  ) async {
    var calls = 0;
    final repo = WikiExampleRepository(
      fetchWiki: (_, {cancelToken}) async => null,
      fetchPosts: (ids, {cancelToken}) async {
        if (calls++ == 0) throw StateError('offline');
        return ids.map((id) => wikiImageMetadata(id)).toList();
      },
    );
    await _pump(t, repo, [const WikiExampleReference(1, 'Keep this caption')]);
    expect(find.text('配图暂时无法读取'), findsOneWidget);
    expect(find.text('Keep this caption'), findsOneWidget);
    await t.tap(find.text('重试'));
    await settleWikiImageFixtures(t);
    expect(calls, 2);
    expect(find.text('配图暂时无法读取'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('a late old article cannot replace the current article images', (
    t,
  ) async {
    final pending = Completer<List<Map<String, dynamic>>>();
    final changing = ValueNotifier([const WikiExampleReference(1, 'old')]);
    addTearDown(changing.dispose);
    final repo = WikiExampleRepository(
      fetchWiki: (_, {cancelToken}) async => null,
      fetchPosts: (ids, {cancelToken}) => ids.contains(1)
          ? pending.future
          : Future.value(ids.map((id) => wikiImageMetadata(id)).toList()),
    );
    // Pending metadata shows a progress indicator, so do not settle it.
    await _pump(t, repo, changing.value, changing: changing, settle: false);
    changing.value = [const WikiExampleReference(2, 'new')];
    pending.complete([wikiImageMetadata(1)]);
    await settleWikiImageFixtures(t);
    expect(find.text('new'), findsOneWidget);
    expect(find.text('old'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'wheel stays in the image pane and does not move its outer editor',
    (t) async {
      final outer = ScrollController();
      addTearDown(outer.dispose);
      final repo = WikiExampleRepository(
        fetchWiki: (_, {cancelToken}) async => null,
        fetchPosts: (ids, {cancelToken}) async =>
            ids.map((id) => wikiImageMetadata(id)).toList(),
      );
      await _pump(
        t,
        repo,
        List.generate(6, (i) => WikiExampleReference(i + 1, 'Caption $i')),
        outer: outer,
      );
      final list = find.byKey(const Key('wiki-image-list'));
      final scroll = t.widget<ListView>(list).controller!;
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await t.sendEventToBinding(pointer.hover(t.getCenter(list)));
      await t.sendEventToBinding(pointer.scroll(const Offset(0, 100)));
      await t.pump();
      expect(scroll.offset, greaterThan(0));
      expect(outer.offset, 0);
      expect(t.takeException(), isNull);
    },
  );
}
