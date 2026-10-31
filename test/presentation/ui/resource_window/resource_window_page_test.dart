import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/gallery_group_mode.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_contract.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_fixture.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_page.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_filter_bar.dart';

import '../../../helpers/studio_capture_fonts.dart';

Future<List<String>> _pump(
  WidgetTester t,
  ResourceWindowViewData data, {
  double width = 1040,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 680);
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final log = <String>[];
  await t.pumpWidget(
    MaterialApp(
      theme: GeistTheme.light,
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ResourceWindowPage(
          data: data,
          actions: ResourceWindowActions.logging(log.add),
        ),
      ),
    ),
  );
  await t.pump();
  // 列表末尾的加载行一出现就要下一页；交互断言只看用户操作。
  log.removeWhere((e) => e == 'more');
  return log;
}

ResourceWindowViewData _view(FloatingResourceKind k, [ResourceLayout? l]) =>
    ResourceWindowFixture.view(
      k,
      layout: l,
      image: (i) => UiFixtureImage.gradient('rw$i'),
    );

void main() {
  testWidgets('trash stays in the gallery and purge requires confirmation', (
    t,
  ) async {
    await t.runAsync(loadStudioCaptureFonts);
    final base = _view(FloatingResourceKind.gallery);
    final log = await _pump(
      t,
      ResourceWindowViewData(
        kind: base.kind,
        sections: base.sections,
        items: base.items,
        groupId: 'trash',
        total: 2,
        trashPaths: const ['a', 'b'],
        detail: const ResourceDetail(
          itemId: 'a',
          title: 'A',
          actions: [
            ResourceActionSpec(id: 'restore', label: '恢复', primary: true),
            ResourceActionSpec(id: 'purge', label: '彻底删除'),
          ],
        ),
      ),
    );
    final context = t.element(find.byKey(const Key('rw-trash-purge-all')));
    final l = AppLocalizations.of(context)!;
    await t.tap(find.byKey(const Key('rw-trash-purge-all')));
    await t.pumpAndSettle();
    expect(log, isEmpty);
    await t.tap(find.text(l.common_cancel));
    await t.pumpAndSettle();
    expect(log, isEmpty);
    await t.tap(find.byKey(const Key('rw-trash-purge-all')));
    await t.pumpAndSettle();
    await t.tap(find.text(l.localGallery_deleteForever).last);
    await t.pumpAndSettle();
    expect(log, ['trash:purge:a,b']);
    log.clear();
    await t.tap(find.byKey(const Key('rw-act-restore')));
    await t.pumpAndSettle();
    expect(log, ['trash:restore:a']);
    expect(t.takeException(), isNull);
  });

  testWidgets('gallery navigation labels are centered in the actual row', (
    t,
  ) async {
    await t.runAsync(loadStudioCaptureFonts);
    await _pump(t, _view(FloatingResourceKind.gallery));
    final row = find.byKey(const Key('rw-group-all'));
    final label = find.descendant(of: row, matching: find.text('全部图片'));
    expect(t.getRect(row).height, 30);
    expect(t.getRect(label).center.dy, closeTo(t.getRect(row).center.dy, .1));
  });
  testWidgets('gallery grouping stays at the right edge with a short title', (
    t,
  ) async {
    await t.runAsync(loadStudioCaptureFonts);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    for (final width in [620.0, 1040.0]) {
      for (final dark in [false, true]) {
        t.view.physicalSize = Size(width, 680);
        final changes = <GalleryGroupMode>[];
        await t.pumpWidget(
          MaterialApp(
            theme: dark ? GeistTheme.dark : GeistTheme.light,
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ResourceWindowPage(
              data: _view(FloatingResourceKind.gallery),
              actions: ResourceWindowActions.logging((_) {}),
              galleryBuilder: (_, _) => const SizedBox(),
              galleryHeaderTrailing: GalleryGroupModeButton(
                value: GalleryGroupMode.day,
                onChanged: changes.add,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final button = find.byKey(const Key('gallery-filter-group-mode'));
        expect(
          t.getRect(button).right,
          closeTo(width - 14, .1),
          reason: 'width=$width, dark=$dark',
        );
        await t.tap(button);
        await t.pumpAndSettle();
        final l10n = AppLocalizations.of(t.element(button))!;
        await t.tap(find.text(l10n.localGallery_groupByMonth));
        await t.pumpAndSettle();
        expect(changes, [GalleryGroupMode.month]);
        expect(t.takeException(), isNull);
      }
    }
  });

  testWidgets(
    'in-window viewer preserves library scroll and selection and suspends hidden library shortcuts',
    (t) async {
      final data = _view(FloatingResourceKind.gallery);
      final overlay = ValueNotifier<Widget?>(null);
      addTearDown(overlay.dispose);
      final log = <String>[];
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1040, 680);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          theme: GeistTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ValueListenableBuilder<Widget?>(
            valueListenable: overlay,
            builder: (_, viewer, _) => ResourceWindowPage(
              data: data,
              actions: ResourceWindowActions.logging(log.add),
              viewer: viewer,
            ),
          ),
        ),
      );
      await t.pump();
      final wall = t
          .widget<CustomScrollView>(find.byKey(const Key('rw-wall')))
          .controller!;
      wall.jumpTo(200);
      await t.pump();
      final offset = wall.offset;
      final selected = data.selectedId;
      log.clear();
      overlay.value = const Material(
        child: Focus(autofocus: true, child: Text('viewer overlay')),
      );
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(log, isEmpty);
      expect(
        t.getRect(find.text('viewer overlay')).top,
        greaterThanOrEqualTo(ResourceWindowPage.topBarHeight),
      );
      expect(find.byKey(const Key('rw-close')), findsOneWidget);
      overlay.value = null;
      await t.pump();
      await t.pump();
      expect(wall.offset, offset);
      expect(data.selectedId, selected);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(log.single, startsWith('action:'));
    },
  );
  for (final kind in FloatingResourceKind.values) {
    testWidgets('${kind.name}: tabs, groups, detail and primary action', (
      t,
    ) async {
      final data = _view(kind);
      final log = await _pump(t, data);
      expect(t.takeException(), isNull);
      for (final k in FloatingResourceKind.values) {
        expect(find.byKey(Key('rw-tab-${k.name}')), findsOne);
      }
      expect(find.byKey(const Key('rw-detail')), findsOne);
      final other = FloatingResourceKind.values.firstWhere((k) => k != kind);
      await t.tap(find.byKey(Key('rw-tab-${other.name}')));
      await t.tap(
        find.byKey(Key('rw-group-${data.sections.last.groups.first.id}')),
      );
      await t.tap(find.byKey(Key('rw-item-${data.items.first.id}')));
      await t.pump(const Duration(milliseconds: 400));
      final primary = data.detail!.actions.firstWhere((a) => a.primary);
      await t.tap(find.byKey(Key('rw-act-${primary.id}')));
      log.removeWhere((e) => e == 'more');
      expect(log, [
        'kind:${other.name}',
        'group:${data.sections.last.groups.first.id}',
        'select:${data.items.first.id}',
        'action:${data.detail!.itemId}:${primary.id}',
      ]);
      // Enter 也触发主操作。
      log.clear();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(log, ['action:${data.detail!.itemId}:${primary.id}']);
    });
  }

  testWidgets(
    'layouts follow the resource; size slider only where it applies',
    (t) async {
      var log = await _pump(t, _view(FloatingResourceKind.gallery));
      expect(find.byKey(const Key('rw-size')), findsOne);
      await t.tap(
        find.descendant(
          of: find.byKey(const Key('rw-layout')),
          matching: find.byKey(const ValueKey(ResourceLayout.grid)),
        ),
      );
      expect(log.where((e) => e != 'more'), ['layout:grid']);
      for (final l in [ResourceLayout.masonry, ResourceLayout.grid]) {
        await _pump(t, _view(FloatingResourceKind.gallery, l));
        expect(t.takeException(), isNull);
      }
      log = await _pump(t, _view(FloatingResourceKind.blocks));
      expect(find.byKey(const Key('rw-size')), findsNothing);
      for (final l in ResourceLayout.values.where(
        (l) => l != ResourceLayout.justified,
      )) {
        await _pump(t, _view(FloatingResourceKind.blocks, l));
        expect(t.takeException(), isNull);
      }
      await _pump(t, _view(FloatingResourceKind.vibe, ResourceLayout.list));
      expect(find.byKey(const Key('rw-size')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('narrow window collapses the side bar and secondary actions', (
    t,
  ) async {
    final data = _view(FloatingResourceKind.gallery);
    await _pump(t, data, width: 640);
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byKey(const Key('rw-side'))).width, 56);
    expect(find.byKey(const Key('rw-sort')), findsNothing);
    final secondary = data.detail!.actions.where((a) => !a.primary);
    for (final a in secondary) {
      expect(find.byKey(Key('rw-act-${a.id}')), findsNothing);
    }
    await _pump(t, data);
    expect(t.getSize(find.byKey(const Key('rw-side'))).width, 224);
  });

  testWidgets('window controls stay flush in narrow and wide windows', (
    t,
  ) async {
    for (final width in [640.0, 1040.0, 1600.0]) {
      for (final kind in FloatingResourceKind.values) {
        await _pump(t, _view(kind), width: width);
        expect(t.takeException(), isNull);
        final bar = t.getRect(find.byKey(const Key('rw-topbar')));
        final close = t.getRect(find.byKey(const Key('rw-close')));
        expect(close.right, bar.right, reason: '$kind at width $width');
        expect(close.width, 46);
      }
    }
  });

  testWidgets('pin, new window and favorite report through actions', (t) async {
    final data = _view(FloatingResourceKind.vibe);
    final log = await _pump(t, data);
    await t.tap(find.byKey(const Key('rw-pin')));
    await t.tap(find.byKey(const Key('rw-new')));
    final fav = data.items.firstWhere((i) => i.favorite);
    await t.tap(find.byKey(Key('rw-fav-${fav.id}')));
    // 卡片有双击手势：单击要等过了双击判定时间才落定。
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byKey(const Key('rw-close')));
    expect(log.where((e) => e != 'more'), [
      'top:true',
      'new',
      'favorite:${fav.id}',
      'close',
    ]);
  });

  testWidgets('disconnected main window shows in the status row', (t) async {
    await _pump(
      t,
      ResourceWindowFixture.view(FloatingResourceKind.blocks, connected: false),
    );
    expect(find.text('主窗口未连接'), findsOne);
  });

  testWidgets('group tree: children follow expanded state, toggles locally', (
    t,
  ) async {
    final log = await _pump(t, _view(FloatingResourceKind.gallery));
    // 01_图库（展开）→ NAI 3（展开）→ R18 可见；NAI 4（收起）的 R18 不可见。
    expect(find.byKey(const Key('rw-group-folder:n3r')), findsOne);
    expect(find.byKey(const Key('rw-group-folder:n4r')), findsNothing);
    await t.tap(find.byKey(const Key('rw-toggle-folder:n4')));
    await t.pump();
    await t.scrollUntilVisible(
      find.byKey(const Key('rw-group-folder:n4r')),
      60,
      scrollable: find.descendant(
        of: find.byKey(const Key('rw-side-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('rw-group-folder:n4r')), findsOne);
    await t.tap(find.byKey(const Key('rw-toggle-folder:lib')));
    await t.pump();
    expect(find.byKey(const Key('rw-group-folder:n3')), findsNothing);
    // 展开 / 收起不切分组。
    expect(log.where((e) => e.startsWith('group:')), isEmpty);
    // 子级比父级缩进更深。
    await t.tap(find.byKey(const Key('rw-toggle-folder:lib')));
    await t.pump();
    final parent = t.getTopLeft(
      find.descendant(
        of: find.byKey(const Key('rw-group-folder:lib')),
        matching: find.text('01_图库'),
      ),
    );
    final child = t.getTopLeft(
      find.descendant(
        of: find.byKey(const Key('rw-group-folder:n3')),
        matching: find.text('NAI 3'),
      ),
    );
    expect(child.dx, greaterThan(parent.dx + 10));
    // 资料库没有“今天”。
    expect(find.text('今天'), findsOne); // 只剩卡片墙的日期段头
    expect(find.byKey(const Key('rw-group-today')), findsNothing);
  });

  testWidgets('sort menu lists fields only; arrow toggles direction', (
    t,
  ) async {
    final data = _view(FloatingResourceKind.gallery);
    final log = await _pump(t, data);
    await t.tap(find.byKey(const Key('rw-sort-field')));
    await t.pump();
    for (final s in data.sorts) {
      expect(find.byKey(Key('rw-sort-${s.id}')), findsOne);
    }
    expect(find.textContaining('升序'), findsNothing);
    await t.tap(find.byKey(const Key('rw-sort-fileName')));
    await t.pump();
    await t.tap(find.byKey(const Key('rw-sort-direction')));
    expect(log.where((e) => e != 'more'), ['sort:fileName', 'desc:false']);
    // 块库“自定义顺序”没有方向箭头。
    await _pump(
      t,
      ResourceWindowViewData(
        kind: FloatingResourceKind.blocks,
        sorts: const [
          ResourceOption(id: 'custom', label: 'C', directional: false),
        ],
        sortId: 'custom',
        items: _view(FloatingResourceKind.blocks).items,
      ),
    );
    expect(find.byKey(const Key('rw-sort-direction')), findsNothing);
  });

  testWidgets('tab counts stay and badges never overflow the card', (t) async {
    await _pump(t, _view(FloatingResourceKind.gallery, ResourceLayout.grid));
    for (final k in FloatingResourceKind.values) {
      expect(find.byKey(Key('rw-tab-count-${k.name}')), findsOne);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('single tap selects at once; second tap opens', (t) async {
    final data = _view(FloatingResourceKind.blocks);
    final log = await _pump(t, data);
    final id = data.items[3].id;
    await t.tap(find.byKey(Key('rw-item-$id')));
    expect(log.where((e) => e != 'more'), ['select:$id']);
    await t.pump(const Duration(milliseconds: 80));
    await t.tap(find.byKey(Key('rw-item-$id')));
    expect(log.where((e) => e != 'more'), [
      'select:$id',
      'select:$id',
      'open:$id',
    ]);
  });

  testWidgets('action failure shows a notice that goes away', (t) async {
    final base = _view(FloatingResourceKind.gallery);
    await _pump(t, base);
    expect(find.byKey(const Key('rw-notice')), findsNothing);
    await _pump(
      t,
      ResourceWindowViewData(
        kind: base.kind,
        sections: base.sections,
        items: base.items,
        notice: const ResourceNotice(id: 1, code: 'not_found'),
      ),
    );
    await t.pump();
    expect(find.byKey(const Key('rw-notice')), findsOne);
    expect(find.text('这一项已经不存在，列表已刷新'), findsOne);
    await t.pump(const Duration(seconds: 6));
    expect(find.byKey(const Key('rw-notice')), findsNothing);
  });

  testWidgets('narrow top bar keeps close/pin visible and tabs icon-only', (
    t,
  ) async {
    await _pump(t, _view(FloatingResourceKind.blocks), width: 560);
    expect(t.takeException(), isNull);
    for (final k in ['rw-pin', 'rw-new', 'rw-close']) {
      final r = t.getRect(find.byKey(Key(k)));
      expect(r.right, lessThanOrEqualTo(560));
    }
    expect(find.text('Vibe 库'), findsNothing);
  });
}
