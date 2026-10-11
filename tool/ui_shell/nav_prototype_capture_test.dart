// 主导航：和 HTML 原型（.devin/mockups/nav/mock.html）同场景、同尺寸（1600 × 1000）的实绘，
// 外加每个场景关键元素的位置（rects.json），供 tool/ui_shell/nav_measure.py 出偏差表。
// 运行：flutter test tool/ui_shell/nav_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/nav/flutter/，不进仓库。
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
import 'package:nai_launcher/presentation/ui/nav/nav_tips.dart';

import '../../test/helpers/studio_capture_fonts.dart';

const _mock = '../../mockups';

void main() {
  final out = Directory('.dart_tool/ui-shell/nav/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};
  setUpAll(loadStudioCaptureFonts);
  tearDownAll(
    () => File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects)),
  );

  Map<String, List<double>> measure(WidgetTester tester) {
    final m = <String, List<double>>{};
    void put(String name, Finder f, {bool plate = false, double inset = 0}) {
      if (f.evaluate().isEmpty) return;
      var r = tester.getRect(f.first);
      if (plate) r = Rect.fromCenter(center: r.center, width: 36, height: 36);
      if (inset > 0) {
        r = Rect.fromLTRB(r.left, r.top + inset, r.right, r.bottom - inset);
      }
      m[name] = [r.left, r.top, r.width, r.height];
    }

    for (final p in NavPage.values) {
      put('nv-${p.name}', find.byKey(Key('main-nav-${p.name}')), plate: true);
      put('nx-${p.name}', find.byKey(Key('main-nav-panel-${p.name}')));
      put('cr-${p.name}', find.byKey(ValueKey('main-nav-customize-${p.name}')));
    }
    put('nv-toggle', find.byKey(const Key('main-nav-toggle')), plate: true);
    put('nv-tasks', find.byKey(const Key('main-nav-tasks')), plate: true);
    put('av', find.byKey(const Key('main-nav-avatar')), plate: true);
    if (m['av'] case final a?) m['av'] = [a[0] + 3, a[1] + 3, 30, 30];
    for (var i = 1; i < 4; i++) {
      put('gsep-$i', find.byKey(Key('main-nav-line-$i')), inset: 9);
    }
    for (var i = 0; i < 4; i++) {
      put('gh-$i', find.byKey(Key('main-nav-panel-group-$i')));
    }
    put('xp', find.byKey(const Key('main-nav-panel')));
    put('xh', find.byKey(const Key('main-nav-panel-account')));
    put('nx-pin', find.byKey(const Key('main-nav-panel-pin')));
    put('nx-collapse', find.byKey(const Key('main-nav-panel-collapse')));
    put('tip', find.byType(NavTipBubble));
    put('acct', find.byKey(const Key('account-popover')));
    put('anlas', find.byKey(const Key('account-popover-anlas')));
    put('add', find.byKey(const Key('account-popover-add')));
    put('tasks', find.byKey(const Key('main-nav-tasks-popover')));
    put('tr-gen', find.byKey(const Key('main-nav-task-generation')));
    for (final t in NavFixture.tasks) {
      put('tr-${t.id}', find.byKey(ValueKey('main-nav-task-${t.id}')));
    }
    put('custom', find.byKey(const Key('main-nav-customize')));
    put('custom-ctrl', find.byKey(const Key('main-nav-customize-ctrl')));
    put('hint', find.byKey(const Key('main-nav-ctrl-hint')));
    return m;
  }

  Future<void> shot(
    WidgetTester tester,
    String name, {
    required NavViewData data,
    bool dark = false,
    String bg = 'gallery',
    Future<void> Function()? interact,
  }) async {
    debugDisableShadows = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = File(
      '$_mock/nav/assets/bg-$bg${dark ? '-d' : ''}.jpg',
    ).readAsBytesSync();
    final image = MemoryImage(bytes);
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
            body: NavShell(
              data: data,
              actions: NavActions.none,
              child: Image(image: image, fit: BoxFit.fill),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(image, tester.element(find.byType(NavShell)));
      if (data.generation.preview case final p?) {
        await precacheImage(p, tester.element(find.byType(NavShell)));
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
    rects[name] = measure(tester);
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

  Future<TestGesture> hover(WidgetTester tester, Finder f) async {
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    addTearDown(g.removePointer);
    await g.moveTo(tester.getCenter(f));
    await tester.pump(const Duration(milliseconds: 400));
    return g;
  }

  for (final dark in [false, true]) {
    final t = dark ? '-dark' : '';
    testWidgets(
      'a$t',
      (tester) => shot(tester, 'a$t', data: NavFixture.view(), dark: dark),
    );
    testWidgets(
      'expand$t',
      (tester) => shot(
        tester,
        'expand$t',
        data: NavFixture.view(),
        dark: dark,
        interact: () => tester.tap(find.byKey(const Key('main-nav-toggle'))),
      ),
    );
    testWidgets(
      'gen$t',
      (tester) => shot(
        tester,
        'gen$t',
        data: NavFixture.view(
          generation: NavFixture.running,
          preview: MemoryImage(
            File('$_mock/viewer/assets/t53.jpg').readAsBytesSync(),
          ),
        ),
        dark: dark,
        interact: () =>
            hover(tester, find.byKey(const Key('main-nav-generation'))),
      ),
    );
    testWidgets(
      'acct$t',
      (tester) => shot(
        tester,
        'acct$t',
        data: NavFixture.view(),
        dark: dark,
        interact: () => tester.tap(find.byKey(const Key('main-nav-avatar'))),
      ),
    );
  }
  testWidgets(
    'tip',
    (tester) => shot(
      tester,
      'tip',
      data: NavFixture.view(
        account: NavAccountData(
          current: NavFixture.account.current == null
              ? null
              : const NavAccount(id: 'main', name: '鹈鹕'),
        ),
      ),
      interact: () =>
          hover(tester, find.byKey(const Key('main-nav-onlineGallery'))),
    ),
  );
  testWidgets(
    'keys',
    (tester) => shot(
      tester,
      'keys',
      data: NavFixture.view(
        ctrlHintSeen: false,
        account: const NavAccountData(
          current: NavAccount(id: 'main', name: '鹈鹕'),
        ),
      ),
      interact: () async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump(const Duration(milliseconds: 500));
      },
    ),
  );
  testWidgets(
    'tasks',
    (tester) => shot(
      tester,
      'tasks',
      data: NavFixture.view(
        generation: NavFixture.running,
        tasks: NavFixture.tasks,
        account: const NavAccountData(
          current: NavAccount(id: 'main', name: '鹈鹕'),
        ),
      ),
      interact: () => tester.tap(find.byKey(const Key('main-nav-tasks'))),
    ),
  );
  testWidgets(
    'custom',
    (tester) => shot(
      tester,
      'custom',
      data: NavFixture.view(
        hidden: const {NavPage.tagWiki, NavPage.statistics},
        account: const NavAccountData(
          current: NavAccount(id: 'main', name: '鹈鹕'),
        ),
      ),
      interact: () async {
        await tester.tapAt(const Offset(24, 190), buttons: kSecondaryButton);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('main-nav-customize-menu')));
      },
    ),
  );
}
