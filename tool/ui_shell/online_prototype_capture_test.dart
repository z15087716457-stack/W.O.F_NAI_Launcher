// 在线画廊：和 HTML 原型（.devin/mockups/online/mock.html）同场景、同尺寸（1600 × 1000）的实绘，
// 外加每个场景关键元素的位置（rects.json），供 tool/ui_shell/online_measure.py 出偏差表。
// 运行：flutter test tool/ui_shell/online_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/online/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_shell.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../test/helpers/studio_capture_fonts.dart';

const _assets = '../../mockups/online/assets';

final _images = <String, ImageProvider?>{};

/// 原型的图片键 → 本地原型图；原型里缺的图（t 开头的几张）返回 null，两边都画控件底。
ImageProvider? protoImage(String key) => _images.putIfAbsent(key, () {
  final f = File('$_assets/$key.jpg');
  return f.existsSync() ? MemoryImage(f.readAsBytesSync()) : null;
});

const _keys = [
  'sidebar', 'source-card', 'blacklist', 'mode-search', 'mode-ranking', //
  'mode-favorites', 'toolbar', 'search', 'card-size', 'rank-scale', 'multi',
  'multi-done', 'refresh', 'inspector-toggle', 'rank-date', 'filter-row',
  'author-header', 'nai-only', 'model', 'time-range', 'date-range', 'loaded',
  'jump', 'rank-periods', 'drag-hint', 'inspector', 'insp-preview',
  'insp-author', 'insp-params', 'insp-prompt', 'insp-site-tags', 'insp-tags',
  'insp-footer', 'insp-send', 'source-popover', 'blacklist-popover',
  'send-popover', 'favto-popover', 'selection-bar', 'login', 'viewer',
  'viewer-position', 'viewer-strip', 'viewer-info', 'sort',
];

void main() {
  final out = Directory('.dart_tool/ui-shell/online/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};
  setUpAll(loadStudioCaptureFonts);
  tearDownAll(
    () => File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects)),
  );

  Map<String, List<double>> measure(WidgetTester tester, OnlineViewData d) {
    final m = <String, List<double>>{};
    void put(String name, Finder f, {double inset = 0}) {
      if (f.evaluate().isEmpty) return;
      final r = tester.getRect(f.first);
      m[name] = [r.left + inset, r.top, r.width - 2 * inset, r.height];
    }

    for (final k in _keys) {
      put(
        k,
        find.byKey(Key('online-$k')),
        inset: k.startsWith('mode-') ? 8 : 0,
      );
    }
    for (var i = 0; i < 8; i++) {
      put('recent-$i', find.byKey(Key('online-recent-$i')), inset: 8);
    }
    for (final k in ['*', '', 'style', 'comp', 'color']) {
      put('collection-$k', find.byKey(Key('online-collection-$k')), inset: 8);
    }
    for (var i = 100; i < 107; i++) {
      put('author-$i', find.byKey(Key('online-author-$i')), inset: 8);
    }
    for (final s in OnlineSource.values) {
      put('source-${s.name}', find.byKey(Key('online-source-${s.name}')));
    }
    for (final s in OnlineSendMode.values) {
      put('send-${s.name}', find.byKey(Key('online-send-${s.name}')));
    }
    for (final r in OnlineRating.values) {
      put('rating-${r.name}', find.byKey(Key('online-rating-${r.name}')));
    }
    for (final w in d.list.items) {
      put('card-${w.key}', find.byKey(Key('online-card-${w.key}')));
    }
    return m;
  }

  Future<void> shot(
    WidgetTester tester,
    String name, {
    required OnlineViewData data,
    bool dark = false,
    Future<void> Function()? interact,
  }) async {
    debugDisableShadows = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: WindowChromeScope(
              child: NavShell(
                data: NavFixture.view(current: NavPage.onlineGallery),
                actions: NavActions.none,
                child: OnlineGalleryPage(
                  data: data,
                  actions: OnlineActions.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(OnlineGalleryPage));
      for (final img in _images.values.nonNulls) {
        await precacheImage(img, ctx);
      }
    });
    await tester.pumpAndSettle();
    if (interact != null) {
      await interact();
      await tester.pumpAndSettle();
    }
    final error = tester.takeException();
    if (error != null) {
      fail(error is FlutterError ? error.toStringDeep() : '$error');
    }
    rects[name] = measure(tester, data);
    final png = await tester.runAsync(() async {
      final ro = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture')),
      );
      final img = await ro.toImage();
      return (await img.toByteData(format: ui.ImageByteFormat.png))!;
    });
    File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    debugDisableShadows = true;
  }

  Future<void> hover(WidgetTester tester, Finder f) async {
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    addTearDown(g.removePointer);
    await g.moveTo(tester.getCenter(f));
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> tap(WidgetTester t, String key) async {
    await t.tap(find.byKey(Key(key)));
    await t.pumpAndSettle();
  }

  OnlineViewData v({
    OnlineSource source = OnlineSource.aiTag,
    OnlineMode mode = OnlineMode.search,
    String? selectedKey = 'c03',
    int? authorId,
    List<OnlineSourceStatus>? statuses,
  }) => OnlineFixture.view(
    image: protoImage,
    source: source,
    mode: mode,
    selectedKey: selectedKey,
    authorId: authorId,
    statuses: statuses,
  );

  for (final dark in [false, true]) {
    final t = dark ? '-dark' : '';
    testWidgets(
      'a$t',
      (tester) => shot(
        tester,
        'a$t',
        data: v(),
        dark: dark,
        interact: () => hover(tester, find.byKey(const Key('online-card-c16'))),
      ),
    );
    testWidgets(
      'fav$t',
      (tester) => shot(
        tester,
        'fav$t',
        data: v(mode: OnlineMode.favorites, selectedKey: 'c14'),
        dark: dark,
      ),
    );
  }
  testWidgets(
    'rank',
    (tester) => shot(tester, 'rank', data: v(mode: OnlineMode.ranking)),
  );
  testWidgets(
    'drank',
    (tester) => shot(
      tester,
      'drank',
      data: v(source: OnlineSource.danbooru, mode: OnlineMode.ranking),
    ),
  );
  testWidgets(
    'booru',
    (tester) => shot(tester, 'booru', data: v(source: OnlineSource.danbooru)),
  );
  testWidgets(
    'author',
    (tester) => shot(
      tester,
      'author',
      data: v(mode: OnlineMode.favorites, authorId: 100),
    ),
  );
  testWidgets(
    'sel',
    (tester) => shot(
      tester,
      'sel',
      data: v(),
      interact: () async {
        await tap(tester, 'online-multi');
        for (final k in ['c03', 'c14', 't37', 'c15', 't19']) {
          await tap(tester, 'online-card-$k');
        }
        await tap(tester, 'online-sel-favorite');
      },
    ),
  );
  testWidgets(
    'send',
    (tester) => shot(
      tester,
      'send',
      data: v(),
      interact: () => tap(tester, 'online-insp-send'),
    ),
  );
  testWidgets(
    'src',
    (tester) => shot(
      tester,
      'src',
      data: v(),
      interact: () => tap(tester, 'online-source-card'),
    ),
  );
  testWidgets(
    'black',
    (tester) => shot(
      tester,
      'black',
      data: v(),
      interact: () => tap(tester, 'online-blacklist'),
    ),
  );
  testWidgets(
    'login',
    (tester) => shot(
      tester,
      'login',
      data: v(
        source: OnlineSource.danbooru,
        mode: OnlineMode.favorites,
        statuses: [
          for (final s in OnlineFixture.sources)
            s.source == OnlineSource.danbooru
                ? const OnlineSourceStatus(
                    source: OnlineSource.danbooru,
                    ranking: true,
                    favorites: true,
                    favoritesWritable: true,
                    ratings: true,
                    dateRange: true,
                    fuzzy: true,
                    account: OnlineAccountState.signedOut,
                  )
                : s,
        ],
      ),
    ),
  );
  testWidgets(
    'detail',
    (tester) => shot(
      tester,
      'detail',
      data: v(selectedKey: 'c14'),
      interact: () async {
        final card = find.byKey(const Key('online-card-c14'));
        await tester.tap(card);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(card);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      },
    ),
  );
}
