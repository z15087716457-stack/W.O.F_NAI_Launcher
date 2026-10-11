// Vibe / 精准参考库：和 HTML 原型（.devin/mockups/refs/mock.html）同场景、同尺寸（1600 × 1000）的实绘，
// 外加每个场景关键元素的位置（rects.json），供 tool/ui_shell/refs_measure.py 出偏差表。
// 运行：flutter test tool/ui_shell/refs_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/refs/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_slider.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_shell.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_page.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_picker.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../test/helpers/studio_capture_fonts.dart';

const _assets = '../../mockups/refs/assets';

final _images = <String, ImageProvider?>{};

ImageProvider? protoImage(String key) => _images.putIfAbsent(key, () {
  final f = File('$_assets/$key.jpg');
  return f.existsSync() ? MemoryImage(f.readAsBytesSync()) : null;
});

const _keys = [
  'sidebar',
  'view-all',
  'view-favorites',
  'view-recent',
  'view-inGeneration',
  'new-category',
  'folder',
  'precise-footer',
  'import-type',
  'toolbar',
  'search',
  'sort',
  'card-size',
  'model',
  'multi',
  'multi-done',
  'import',
  'more',
  'inspector-toggle',
  'banner',
  'filter-row',
  'count',
  'tray',
  'tray-hint',
  'tray-add',
  'conflict',
  'go-generation',
  'inspector',
  'insp-preview',
  'insp-add',
  'insp-actions',
  'insp-params',
  'encoding',
  'insp-organize',
  'insp-kv',
  'insp-footer',
  'insp-type',
  'changed',
  'selection-bar',
  'multi-stack',
  'multi-summary',
  'multi-unify',
  'multi-organize',
  'empty',
  'empty-actions',
  'empty-entries',
  'empty-help',
  'drop',
  'detail',
  'detail-stage',
  'bundle',
  'bundle-toolbar',
  'bundle-grid',
  'bundle-note',
  'import-dialog',
  'import-options',
  'import-summary',
  'export',
  'export-list',
  'export-formats',
  'export-options',
  'export-folder',
  'picker',
  'picker-search',
  'picker-chips',
  'picker-recent',
  'picker-grid',
  'picker-summary',
];

void main() {
  final out = Directory('.dart_tool/ui-shell/refs/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};
  setUpAll(loadStudioCaptureFonts);
  tearDownAll(
    () => File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects)),
  );

  Map<String, List<double>> measure(WidgetTester tester, List<RefsEntry> es) {
    final m = <String, List<double>>{};
    void put(String name, Finder f, {double inset = 0}) {
      if (f.evaluate().isEmpty) return;
      final r = tester.getRect(f.first);
      m[name] = [r.left + inset, r.top, r.width - 2 * inset, r.height];
    }

    for (final k in _keys) {
      put(k, find.byKey(Key('refs-$k')), inset: k.startsWith('view-') ? 8 : 0);
    }
    for (final c in RefsFixture.categories) {
      put('cat-${c.id}', find.byKey(Key('refs-cat-${c.id}')), inset: 8);
    }
    put(
      'cat-uncategorized',
      find.byKey(const Key('refs-cat-uncategorized')),
      inset: 8,
    );
    for (final s in RefsVibeSource.values) {
      put('src-${s.name}', find.byKey(Key('refs-src-${s.name}')), inset: 8);
    }
    for (final t in RefsPreciseType.values) {
      put('type-${t.name}', find.byKey(Key('refs-type-${t.name}')), inset: 8);
    }
    for (final e in es) {
      put('card-${e.key}', find.byKey(Key('refs-card-${e.key}')));
    }
    return m;
  }

  Future<void> shot(
    WidgetTester tester,
    String name, {
    required RefsViewData data,
    bool dark = false,
    bool picker = false,
    Future<void> Function()? interact,
  }) async {
    debugDisableShadows = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vibe = data.kind == RefsKind.vibe;
    Widget page = RefsLibraryPage(data: data, actions: RefsActions.none);
    if (picker) {
      page = Stack(
        children: [
          ColoredBox(color: dark ? const Color(0xFF111111) : Colors.white),
          Positioned(
            left: 440 - 48,
            top: 120,
            child: RefsPicker(
              data: RefsFixture.vibePicker(protoImage),
              actions: RefsPickerActions(
                onConfirm: (_, {required replace}) {},
                onClose: () {},
                onOpenLibrary: () {},
              ),
            ),
          ),
        ],
      );
    }
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
                data: NavFixture.view(
                  current: picker
                      ? NavPage.generation
                      : vibe
                      ? NavPage.vibeLibrary
                      : NavPage.preciseRef,
                ),
                actions: NavActions.none,
                child: page,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(NavShell));
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
    rects[name] = measure(tester, data.entries);
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

  RefsViewData vibe({
    RefsModel model = RefsFixture.v45,
    String? selectedKey = 'c03',
    bool empty = false,
    RefsDropSummary? drop,
    RefsImportDraft? importDraft,
  }) => RefsFixture.vibe(
    image: protoImage,
    model: model,
    selectedKey: selectedKey,
    empty: empty,
    drop: drop,
    importDraft: importDraft,
  );

  RefsViewData precise({String? selectedKey = 'c20', bool empty = false}) =>
      RefsFixture.preciseView(
        image: protoImage,
        selectedKey: selectedKey,
        empty: empty,
      );

  for (final dark in [false, true]) {
    final t = dark ? '-dark' : '';
    testWidgets(
      'a$t',
      (tester) => shot(
        tester,
        'a$t',
        data: vibe(),
        dark: dark,
        interact: () async {
          // 原型里检查器的强度改成了 0.72（演示“只用于这次发送”）。
          await tester.tap(
            find.descendant(
              of: find.byKey(const Key('refs-strength')),
              matching: find.byType(UiNumBox),
            ),
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.descendant(
              of: find.byKey(const Key('refs-strength')),
              matching: find.byType(EditableText),
            ),
            '0.72',
          );
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          await hover(tester, find.byKey(const Key('refs-card-c13')));
        },
      ),
    );
    testWidgets(
      'a-prec$t',
      (tester) => shot(
        tester,
        'a-prec$t',
        data: precise(),
        dark: dark,
        interact: () => hover(tester, find.byKey(const Key('refs-card-c12'))),
      ),
    );
  }
  testWidgets(
    'a-sel',
    (tester) => shot(
      tester,
      'a-sel',
      data: vibe(),
      interact: () async {
        await tap(tester, 'refs-multi');
        for (final k in ['c03', 'c15', 'c11', 'c13']) {
          await tap(tester, 'refs-card-$k');
        }
      },
    ),
  );
  testWidgets(
    'a-v5',
    (tester) => shot(tester, 'a-v5', data: vibe(model: RefsFixture.v5)),
  );
  testWidgets(
    'detail',
    (tester) => shot(
      tester,
      'detail',
      data: vibe(selectedKey: 'c11'),
      interact: () => tap(tester, 'refs-insp-preview'),
    ),
  );
  testWidgets(
    'pdetail',
    (tester) => shot(
      tester,
      'pdetail',
      data: precise(),
      interact: () => tap(tester, 'refs-insp-preview'),
    ),
  );
  testWidgets(
    'bundle',
    (tester) => shot(
      tester,
      'bundle',
      data: vibe(selectedKey: 'c14'),
      interact: () => tap(tester, 'refs-insp-open-bundle'),
    ),
  );
  testWidgets(
    'import',
    (tester) => shot(
      tester,
      'import',
      data: vibe(importDraft: RefsFixture.importDraft(protoImage)),
    ),
  );
  testWidgets(
    'drop',
    (tester) => shot(tester, 'drop', data: vibe(drop: RefsFixture.drop)),
  );
  testWidgets(
    'export',
    (tester) => shot(
      tester,
      'export',
      data: vibe(),
      interact: () async {
        await tap(tester, 'refs-multi');
        for (final k in ['c03', 'c15', 'c11', 'c13']) {
          await tap(tester, 'refs-card-$k');
        }
        await tap(tester, 'refs-sel-export');
      },
    ),
  );
  testWidgets(
    'picker',
    (tester) => shot(
      tester,
      'picker',
      data: vibe(),
      picker: true,
      interact: () async {
        await tap(tester, 'refs-picker-card-c11');
        await tap(tester, 'refs-picker-card-u1');
      },
    ),
  );
  testWidgets(
    'empty',
    (tester) => shot(tester, 'empty', data: vibe(empty: true)),
  );
  testWidgets(
    'empty-prec',
    (tester) => shot(tester, 'empty-prec', data: precise(empty: true)),
  );
}
