import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_example_gallery.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_linked_body.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/studio_capture_fonts.dart';

class _Cache extends Fake implements BaseCacheManager {
  _Cache(this.bytes);
  final Uint8List bytes;
  final fetched = <String>[];
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    fetched.add(url);
    yield FileInfo(
      MemoryFileSystem().file('fixture.png')..writeAsBytesSync(bytes),
      FileSource.Cache,
      DateTime(2030),
      url,
    );
  }

  @override
  Future<void> removeFile(String key) async {}
}

WikiExampleRepository _repo({
  required void Function() requested,
  bool fail = false,
  Completer<Map<String, dynamic>?>? pending,
}) => WikiExampleRepository(
  fetchWiki: (tag, {cancelToken}) async {
    requested();
    if (fail) throw StateError('offline');
    if (pending != null) return pending.future;
    return {
      'body':
          'h4. Examples\n* !post #11: [[1girl]] [[solo]]\n'
          '* !post #22: [[1girl]] with [[1boy]]\n'
          '* !post #33: [[multiple_views]]',
    };
  },
  fetchPosts: (ids, {cancelToken}) async => [
    for (final id in ids)
      {
        'id': id,
        'media_asset': {
          'variants': [
            {'type': '360x360', 'url': 'https://cdn.donmai.us/360x360/$id.jpg'},
            {
              'type': '720x720',
              'url': 'https://cdn.donmai.us/720x720/$id.webp',
            },
          ],
        },
      },
  ],
);

Future<void> _mount(
  WidgetTester tester, {
  required WikiExampleRepository repo,
  required _Cache cache,
  ScrollController? scroll,
  double before = 0,
  String tag = '1girl',
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wikiExampleRepositoryProvider.overrideWithValue(repo),
        wikiExampleImageCacheProvider.overrideWithValue(cache),
        wikiTagLinksProvider.overrideWithValue(
          WikiTagLinks(
            exactLookup: (names) async => {
              for (final name in names)
                name: CompletionCandidate(
                  canonicalTag: name,
                  category: TagCategory.general,
                  postCount: 1,
                  translation: name,
                  matchKind: CompletionMatchKind.englishExact,
                  sources: const {CompletionSourceKind.base},
                ),
            },
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getTheme(AppStyle.geist, brightness),
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('capture'),
            child: Material(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: before),
                    Text(locale.languageCode == 'zh' ? '示例' : 'Examples'),
                    const SizedBox(height: 12),
                    WikiExampleGallery(
                      key: const ValueKey('gallery'),
                      tag: tag,
                      fallback: const Text('Local example description'),
                      captionBuilder: (text) => WikiLinkedBody(
                        body: text,
                        onTagTap: (_) {},
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _settleImages(tester);
}

Future<void> _settleImages(WidgetTester tester) async {
  // File reads and the image codec run outside the widget test's fake clock.
  for (var step = 0; step < 6; step++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List file;
  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 120, 160),
      Paint()..color = const Color(0xffa6c5d6),
    );
    canvas.drawCircle(
      const Offset(60, 68),
      32,
      Paint()..color = const Color(0xffeef5e6),
    );
    canvas.drawRect(
      const Rect.fromLTWH(25, 120, 70, 24),
      Paint()..color = const Color(0xff779765),
    );
    final image = await recorder.endRecording().toImage(120, 160);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    file = bytes!.buffer.asUint8List();
    image.dispose();
    if (Platform.environment['CAPTURE_WIKI_EXAMPLES'] == '1') {
      await loadStudioCaptureFonts();
    }
  });
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets(
    'offscreen examples request nothing; visible thumbnails load and large image waits for click',
    (tester) async {
      tester.view.physicalSize = const Size(750, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var requested = 0;
      final cache = _Cache(file);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _mount(
        tester,
        repo: _repo(requested: () => requested++),
        cache: cache,
        scroll: scroll,
        before: 700,
      );
      expect(requested, 0);
      expect(cache.fetched, isEmpty);
      scroll.jumpTo(700);
      await _settleImages(tester);
      expect(requested, 1);
      expect(
        find.byKey(const ValueKey('wiki-example-card-11')),
        findsOneWidget,
      );
      expect(cache.fetched.where((u) => u.contains('360x360')), hasLength(3));
      expect(cache.fetched.any((u) => u.contains('720x720')), isFalse);
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .where((w) => w.image != null),
        hasLength(3),
      );
      await tester.tap(find.byKey(const ValueKey('wiki-example-open-11')));
      await _settleImages(tester);
      expect(
        find.byKey(const ValueKey('wiki-example-large-11')),
        findsOneWidget,
      );
      expect(cache.fetched.where((u) => u.contains('720x720')), hasLength(1));
      // 灯箱：序号、说明（DText 转纯文本）、→ 切到下一张、缩略图条跳转。
      expect(find.byKey(const Key('wiki-viewer')), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('wiki-viewer-caption'))).data,
        '1girl solo',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settleImages(tester);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('wiki-example-large-22')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('wiki-viewer-thumb-33')));
      await _settleImages(tester);
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('wiki-viewer-next')));
      await _settleImages(tester);
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('wiki-viewer-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wiki-viewer')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('灯箱 Esc 关闭', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(
      tester,
      repo: _repo(requested: () {}),
      cache: _Cache(file),
    );
    await _settleImages(tester);
    await tester.tap(find.byKey(const ValueKey('wiki-example-open-22')));
    await _settleImages(tester);
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-viewer')), findsNothing);
  });

  testWidgets(
    'offline metadata keeps local text and offers an explicit retry',
    (tester) async {
      var requested = 0;
      final cache = _Cache(file);
      await _mount(
        tester,
        repo: _repo(requested: () => requested++, fail: true),
        cache: cache,
      );
      expect(requested, 1);
      expect(find.text('Local example description'), findsOneWidget);
      expect(find.text('示例图片暂时无法加载'), findsOneWidget);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(requested, 2);
      expect(cache.fetched, isEmpty);
    },
  );

  testWidgets(
    'leaving an unfinished example section cancels its request and ignores the late result',
    (tester) async {
      var requested = 0;
      final pending = Completer<Map<String, dynamic>?>();
      final cache = _Cache(file);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final repo = _repo(requested: () => requested++, pending: pending);
      await _mount(
        tester,
        repo: repo,
        cache: cache,
        scroll: scroll,
        before: 700,
      );
      scroll.jumpTo(700);
      await tester.pumpAndSettle();
      expect(requested, 1);
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      pending.complete({'body': 'h4. Examples\n* !post #11: old'});
      await tester.pumpAndSettle();
      expect(cache.fetched, isEmpty);
      expect(find.text('示例图片暂时无法加载'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  if (Platform.environment['CAPTURE_WIKI_EXAMPLES'] == '1') {
    testWidgets('viewer capture', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        repo: _repo(requested: () {}),
        cache: _Cache(file),
      );
      await _settleImages(tester);
      await tester.tap(find.byKey(const ValueKey('wiki-example-open-22')));
      await _settleImages(tester);
      await tester.runAsync(() async {
        final layer = tester.binding.renderViews.first.debugLayer!;
        final image = await (layer as OffsetLayer).toImage(
          Offset.zero & const Size(1200, 800),
        );
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('.dart_tool/wiki-examples-20261006/captures');
        await folder.create(recursive: true);
        await File(
          '${folder.path}/viewer.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
    for (final locale in ['zh', 'zh-TW', 'en', 'ja', 'ko']) {
      for (final brightness in Brightness.values) {
        for (final width in [350.0, 750.0]) {
          testWidgets('examples capture $locale ${brightness.name} $width', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width, 850);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final parts = locale.split('-');
            await _mount(
              tester,
              repo: _repo(requested: () {}),
              cache: _Cache(file),
              locale: Locale(parts[0], parts.length > 1 ? parts[1] : null),
              brightness: brightness,
            );
            await tester.runAsync(
              () async =>
                  Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('capture')),
              );
              final image = await boundary.toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final folder = Directory(
                '.dart_tool/wiki-examples-20261006/captures',
              );
              await folder.create(recursive: true);
              await File(
                '${folder.path}/$locale-${brightness.name}-$width.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
