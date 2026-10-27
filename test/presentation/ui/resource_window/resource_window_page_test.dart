import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_contract.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_fixture.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_page.dart';

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
  return log;
}

ResourceWindowViewData _view(FloatingResourceKind k, [ResourceLayout? l]) =>
    ResourceWindowFixture.view(
      k,
      layout: l,
      image: (i) => UiFixtureImage.gradient('rw$i'),
    );

void main() {
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
        find.byKey(Key('rw-group-${data.sections.last.groups.last.id}')),
      );
      await t.tap(find.byKey(Key('rw-item-${data.items.first.id}')));
      await t.pump(const Duration(milliseconds: 400));
      final primary = data.detail!.actions.firstWhere((a) => a.primary);
      await t.tap(find.byKey(Key('rw-act-${primary.id}')));
      expect(log, [
        'kind:${other.name}',
        'group:${data.sections.last.groups.last.id}',
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
      expect(log, ['layout:grid']);
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
    expect(t.getSize(find.byKey(const Key('rw-side'))).width, 212);
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
    expect(log, ['top:true', 'new', 'favorite:${fav.id}']);
  });

  testWidgets('disconnected main window shows in the status row', (t) async {
    await _pump(
      t,
      ResourceWindowFixture.view(FloatingResourceKind.blocks, connected: false),
    );
    expect(find.text('主窗口未连接'), findsOne);
  });
}
