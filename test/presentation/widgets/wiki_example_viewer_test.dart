import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_example_viewer.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../../helpers/wiki_image_fixtures.dart';

class _Fixture {
  final draft = TextEditingController(text: 'keep this draft');
  final focus = FocusNode();
  final boundary = GlobalKey();
  late BuildContext context;
  late WikiImageFixtureCache cache;
  final examples = [
    for (final (id, kind) in [
      (11, WikiImageKind.post),
      (12, WikiImageKind.asset),
    ])
      WikiExample(
        reference: WikiExampleReference(
          id,
          'Caption $id',
          kind: kind,
          occurrence: id,
        ),
        thumbnailUrl: 'https://cdn.donmai.us/thumb/$id.jpg',
        largeUrl: 'https://cdn.donmai.us/large/$id.jpg',
      ),
  ];

  Future<void> mount(WidgetTester t, {bool failImage = false}) async {
    cache = await WikiImageFixtureCache.load();
    if (failImage) cache = _RetryCache(cache.bytes);
    addTearDown(draft.dispose);
    addTearDown(focus.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppStyle.geist, Brightness.dark),
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) =>
            RepaintBoundary(key: boundary, child: child!),
        home: Builder(
          builder: (context) {
            this.context = context;
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: TextField(controller: draft, focusNode: focus),
                ),
              ),
            );
          },
        ),
      ),
    );
    focus.requestFocus();
    draft.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
    await t.pump();
  }

  Future<void> open() => showWikiExampleViewer(
    context,
    examples: examples,
    initial: 0,
    cache: cache,
  );

  Future<void> capture(String name) async {
    if (Platform.environment['CAPTURE_WIKI_VIEWER_CLICK'] != '1') return;
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('.dart_tool/wiki-viewer-click-20261116/captures')
      ..createSync(recursive: true);
    File(
      '${folder.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  }
}

class _RetryCache extends WikiImageFixtureCache {
  _RetryCache(super.bytes);
  var failed = false;
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    if (!failed && url.contains('/large/')) {
      failed = true;
      throw StateError('offline image');
    }
    yield* super.getFileStream(
      url,
      key: key,
      headers: headers,
      withProgress: withProgress,
    );
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets(
    'repeated opens share one preview and one click restores the draft and focus',
    (t) async {
      final f = _Fixture();
      await f.mount(t);
      final first = f.open();
      for (var i = 0; i < 8; i++) {
        expect(identical(f.open(), first), isTrue);
      }
      await settleWikiImageFixtures(t);
      expect(
        find.byKey(const Key('wiki-viewer'), skipOffstage: false),
        findsOneWidget,
      );
      expect(identical(f.open(), first), isTrue);
      await t.runAsync(() => f.capture('open'));
      await t.tap(find.byKey(const Key('wiki-example-large-post:11:11')));
      await settleWikiImageFixtures(t);
      await first;
      expect(
        find.byKey(const Key('wiki-viewer'), skipOffstage: false),
        findsNothing,
      );
      expect(f.draft.text, 'keep this draft');
      expect(
        f.draft.selection,
        const TextSelection(baseOffset: 1, extentOffset: 4),
      );
      expect(f.focus.hasFocus, isTrue);
      final reopened = f.open();
      expect(identical(reopened, first), isFalse);
      await settleWikiImageFixtures(t);
      await t.tap(find.byKey(const Key('wiki-viewer-close')));
      await settleWikiImageFixtures(t);
      await reopened;
      expect(find.byKey(const Key('wiki-viewer')), findsNothing);
    },
  );

  testWidgets('repeated close callbacks do not pop the host page', (t) async {
    final f = _Fixture();
    await f.mount(t);
    final navigator = Navigator.of(f.context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Keep this page')),
      ),
    );
    await t.pumpAndSettle();
    final opened = f.open();
    await settleWikiImageFixtures(t);
    final close = t
        .widget<WikiExampleViewer>(find.byType(WikiExampleViewer))
        .onClose;
    close();
    close();
    close();
    await settleWikiImageFixtures(t);
    await opened;
    expect(find.text('Keep this page'), findsOneWidget);
    expect(navigator.canPop(), isTrue);
    expect(find.byKey(const Key('wiki-viewer')), findsNothing);
  });

  testWidgets(
    'wheel zoom and drag keep the preview open, and arrows and thumbnails still switch images',
    (t) async {
      final f = _Fixture();
      await f.mount(t);
      f.open();
      await settleWikiImageFixtures(t);
      final image = find.byKey(const Key('wiki-viewer-zoom-post:11:11'));
      final zoom = t.widget<InteractiveViewer>(image).transformationController!;
      final point = t.getCenter(image);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await t.sendEventToBinding(pointer.hover(point));
      await t.sendEventToBinding(pointer.scroll(const Offset(0, -150)));
      await t.pumpAndSettle();
      expect(zoom.value.getMaxScaleOnAxis(), greaterThan(1));
      await t.drag(image, const Offset(80, 40));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('wiki-viewer')), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settleWikiImageFixtures(t);
      expect(
        find.byKey(const Key('wiki-example-large-asset:12:12')),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('wiki-viewer-thumb-post:11:11')));
      await settleWikiImageFixtures(t);
      expect(
        find.byKey(const Key('wiki-example-large-post:11:11')),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('wiki-viewer-next')));
      await settleWikiImageFixtures(t);
      expect(
        find.byKey(const Key('wiki-example-large-asset:12:12')),
        findsOneWidget,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleWikiImageFixtures(t);
      expect(find.byKey(const Key('wiki-viewer')), findsNothing);
    },
  );

  testWidgets('retry button consumes its tap instead of closing the image', (
    t,
  ) async {
    final f = _Fixture();
    await f.mount(t, failImage: true);
    f.open();
    await settleWikiImageFixtures(t);
    expect(find.byKey(const Key('wiki-viewer-retry')), findsOneWidget);
    await t.tap(find.byKey(const Key('wiki-viewer-retry')));
    await settleWikiImageFixtures(t);
    expect(find.byKey(const Key('wiki-viewer')), findsOneWidget);
    expect(find.byKey(const Key('wiki-viewer-retry')), findsNothing);
    await t.tap(find.byKey(const Key('wiki-viewer-close')));
    await settleWikiImageFixtures(t);
    expect(find.byKey(const Key('wiki-viewer')), findsNothing);
  });

  testWidgets(
    'embedded preview preserves focus and zoom across caption updates',
    (t) async {
      final f = _Fixture();
      await f.mount(t);
      var items = f.examples, index = 0;
      var open = true;
      late OverlayEntry entry;
      void close() {
        open = false;
        entry.remove();
        entry.dispose();
      }

      addTearDown(() {
        if (open) close();
      });
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: 330,
          top: 10,
          width: 440,
          height: 550,
          child: WikiExampleViewer(
            embedded: true,
            examples: items,
            initial: index,
            cache: f.cache,
            onClose: close,
            onChanged: (next) {
              index = next;
              entry.markNeedsBuild();
            },
          ),
        ),
      );
      Overlay.of(f.context, rootOverlay: true).insert(entry);
      await settleWikiImageFixtures(t);
      expect(f.focus.hasFocus, isTrue);
      final viewer = find.byKey(const Key('wiki-image-preview-panel'));
      final image = find.byKey(const Key('wiki-viewer-zoom-post:11:11'));
      final zoom = t.widget<InteractiveViewer>(image).transformationController!;
      final pointer = TestPointer(4, PointerDeviceKind.mouse);
      await t.sendEventToBinding(pointer.hover(t.getCenter(image)));
      await t.sendEventToBinding(pointer.scroll(const Offset(0, -150)));
      await t.pumpAndSettle();
      final scale = zoom.value.getMaxScaleOnAxis();
      expect(scale, greaterThan(1));
      items = [
        WikiExample(
          reference: const WikiExampleReference(
            11,
            'Updated caption',
            occurrence: 11,
          ),
          thumbnailUrl: items.first.thumbnailUrl,
          largeUrl: items.first.largeUrl,
        ),
        items.last,
      ];
      entry.markNeedsBuild();
      await settleWikiImageFixtures(t);
      expect(find.text('Updated caption'), findsOneWidget);
      expect(zoom.value.getMaxScaleOnAxis(), scale);
      await t.drag(image, const Offset(30, 15));
      await t.pumpAndSettle();
      expect(viewer, findsOneWidget);
      await t.tap(find.byKey(const Key('wiki-viewer-reset-zoom')));
      await t.pumpAndSettle();
      expect(zoom.value.getMaxScaleOnAxis(), 1);
      await t.tap(find.byKey(const Key('wiki-example-large-post:11:11')));
      await t.pump();
      expect(viewer, findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settleWikiImageFixtures(t);
      expect(
        find.byKey(const Key('wiki-example-large-asset:12:12')),
        findsOneWidget,
      );
      expect(viewer, findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(viewer, findsNothing);
      expect(f.draft.text, 'keep this draft');
      expect(
        f.draft.selection,
        const TextSelection(baseOffset: 1, extentOffset: 4),
      );
    },
  );
}
