import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/widgets/common/text_editing_shortcuts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48。
const genRail = 48.0;

/// 把回调记成字符串，测试里断言调用了什么。
class GenRecorder {
  final calls = <String>[];
  late final actions = GenActions.logging(calls.add);
  bool called(String prefix) => calls.any((c) => c.startsWith(prefix));
  String? last(String prefix) =>
      calls.lastWhere((c) => c.startsWith(prefix), orElse: () => '');
}

/// 按“窗口宽”装一个生图页（扣掉主导航），关掉动画，带窗口按钮避让，图片先解码好。
Future<void> pumpGen(
  WidgetTester tester, {
  required GenViewData data,
  GenActions? actions,
  GenSlots? slots,
  double window = 1600,
  double height = 1120,
  String locale = 'zh',
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - genRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    genApp(
      GenerationPage(
        data: data,
        actions: actions ?? GenActions.logging((_) {}),
        slots: slots ?? const GenSlots(editor: GenFixtureEditor.builder),
      ),
      locale: locale,
      dark: dark,
    ),
  );
  await precacheGen(tester, _images(data));
}

Iterable<ImageProvider> _images(GenViewData d) => [
  for (final t in d.canvas.focus?.tiles ?? const <GenTile>[]) ...[
    ?t.image,
    ?t.preview,
  ],
  for (final b in d.history.batches) ...b.images.map((i) => i.thumb),
  ?d.refs.img2img.image,
  for (final v in d.refs.vibes?.list ?? const <GenVibe>[]) v.thumb,
  for (final v in d.refs.vibes?.recent ?? const <GenRecentVibe>[]) v.thumb,
  for (final p in d.refs.precise?.list ?? const <GenPrecise>[]) p.thumb,
];

Widget genApp(Widget child, {String locale = 'zh', bool dark = false}) =>
    RepaintBoundary(
      key: const Key('gen-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? GeistTheme.dark : GeistTheme.light,
        locale: locale.contains('_')
            ? Locale(locale.split('_')[0], locale.split('_')[1])
            : Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: TextEditingShortcuts(child: child!),
        ),
        home: Scaffold(body: WindowChromeScope(child: child)),
      ),
    );

Future<void> precacheGen(
  WidgetTester tester,
  Iterable<ImageProvider> images,
) async {
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Scaffold));
    for (final i in images.toSet()) {
      await precacheImage(i, ctx);
    }
  });
  await tester.pumpAndSettle();
  // Layout-sized previews use their own cache keys. Await the providers which
  // are actually mounted, including ones introduced by expanded reference rows.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<TestGesture> hoverOver(WidgetTester tester, Finder f) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  await g.moveTo(tester.getCenter(f));
  await tester.pumpAndSettle();
  return g;
}
