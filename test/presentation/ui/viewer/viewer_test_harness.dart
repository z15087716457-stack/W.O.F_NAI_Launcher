import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48（全屏时主导航藏起来，传 rail: 0）。
const viewerRail = 48.0;

/// 按“窗口宽”装一个大图查看器（扣掉主导航），关掉动画，带窗口按钮避让，图片先解码好。
Future<void> pumpViewer(
  WidgetTester tester, {
  required ViewerViewData data,
  ViewerActions? actions,
  double window = 1600,
  double height = 1000,
  double rail = viewerRail,
  String locale = 'zh',
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - rail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    viewerApp(
      ImageViewerPage(data: data, actions: actions ?? ViewerActions.none),
      locale: locale,
      dark: dark,
    ),
  );
  await precacheViewer(tester, [
    for (final i in data.items) ...[?i.thumb, ?i.image],
  ]);
}

Widget viewerApp(Widget child, {String locale = 'zh', bool dark = false}) =>
    RepaintBoundary(
      key: const Key('viewer-capture'),
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
          child: child!,
        ),
        home: Scaffold(body: WindowChromeScope(child: child)),
      ),
    );

Future<void> precacheViewer(
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
}

Future<TestGesture> hoverOver(WidgetTester tester, Finder f) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  await g.moveTo(tester.getCenter(f));
  await tester.pumpAndSettle();
  return g;
}

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)));
  await t.pumpAndSettle();
}

/// 记录所有回调，断言用。
class RecordingViewerActions {
  final calls = <String>[];
  void _c(String s) => calls.add(s);

  ViewerActions get actions => ViewerActions(
    onClose: ({required keyboard}) => _c('close:$keyboard'),
    onSelect: (k) => _c('select:$k'),
    onStep: (d) => _c('step:$d'),
    onJump: ({required last}) => _c('jump:$last'),
    onLoadMore: ({required forward}) => _c('more:$forward'),
    onInfoChanged: (v) => _c('info:$v'),
    onFullscreenChanged: (v) => _c('fullscreen:$v'),
    onSetFavorite: (k, v) => _c('favorite:$k:$v'),
    onToggleCollection: (k, id, v) => _c('collection:$k:$id:$v'),
    onCreateCollection: (k) => _c('newCollection:$k'),
    onDelete: (k) => _c('delete:$k'),
    onUndoDelete: () => _c('undo'),
    onDismissUndo: () => _c('dismissUndo'),
    onAction: (k, a) => _c('action:$k:${a.name}'),
    onCopy: (k, p) => _c('copy:$k:$p'),
    onToggleTranslation: (k, p) => _c('translate:$k:$p'),
    onSaveVibe: (k, i) => _c('saveVibe:$k:$i'),
    onZoomHintSeen: () => _c('zoomHintSeen'),
    onCaptionOverStage: (v) => _c('caption:$v'),
  );
}
