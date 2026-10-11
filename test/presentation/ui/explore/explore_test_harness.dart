import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48。
const exploreRail = 48.0;

/// 按“窗口宽”装一个画风探索页（扣掉主导航），关掉动画，带窗口按钮避让，图片先解码好。
Future<void> pumpExplore(
  WidgetTester tester, {
  required ExploreViewData data,
  ExploreActions? actions,
  double window = 1600,
  double height = 1000,
  String locale = 'zh',
  bool dark = false,
  bool v45 = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - exploreRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    exploreApp(
      StyleExplorePage(
        data: data,
        actions: actions ?? ExploreActions.none,
        editor: (context, parts) =>
            exploreFixtureEditor(context, parts, v45: v45),
      ),
      locale: locale,
      dark: dark,
    ),
  );
  await precacheExplore(tester, [
    for (final c in data.run?.candidates ?? const <ExploreCandidate>[]) ...[
      ?c.thumb,
      ?c.image,
    ],
    for (final r in data.runs) ...[for (final t in r.thumbs) ?t],
  ]);
}

Widget exploreApp(Widget child, {String locale = 'zh', bool dark = false}) =>
    RepaintBoundary(
      key: const Key('explore-capture'),
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

Future<void> precacheExplore(
  WidgetTester tester,
  Iterable<ImageProvider> images,
) async {
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Scaffold));
    for (final i in images.toSet()) {
      await precacheImage(i, ctx);
    }
    for (final a in [
      'assets/images/explore-example-c01.jpg',
      'assets/images/explore-example-c04.jpg',
      'assets/images/explore-example-c12.jpg',
      'assets/icons/novelai-icon.png',
    ]) {
      await precacheImage(AssetImage(a), ctx);
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
class RecordingExploreActions {
  final calls = <String>[];
  void _c(String s) => calls.add(s);

  ExploreActions get actions => ExploreActions(
    onOpenRun: (id) => _c('openRun:$id'),
    onNewRun: () => _c('newRun'),
    onRenameRun: (id, n) => _c('renameRun:$id:$n'),
    onDeleteRun: (id) => _c('deleteRun:$id'),
    onGenerate: () => _c('generate'),
    onStop: () => _c('stop'),
    onPause: () => _c('pause'),
    onResume: () => _c('resume'),
    onCountChanged: (v) => _c('count:$v'),
    onRetryFailed: () => _c('retry'),
    onSetFavorite: (k, v) => _c('favorite:${k.join(',')}:$v'),
    onAssignGroup: (k, g) => _c('group:${k.join(',')}:$g'),
    onCreateGroup: (n, k) => _c('newGroup:$n:${k.join(',')}'),
    onRenameGroup: (id, n) => _c('renameGroup:$id:$n'),
    onDeleteGroup: (id) => _c('deleteGroup:$id'),
    onDeleteCandidates: (k) => _c('delete:${k.join(',')}'),
    onUndoDelete: () => _c('undo'),
    onDismissUndo: () => _c('dismissUndo'),
    onCopyArtists: (k) => _c('copy:${k.join(',')}'),
    onApplyToEditor: (k) => _c('apply:$k'),
    onSaveBlock: (d) => _c(
      'block:${d.title}:${d.atoms.join('|')}:${d.fullText != null}:${d.folderId}',
    ),
    onStartEvolution: (p) => _c(
      'evolution:${p.candidateKeys.join(',')}:${p.customParents.join('|')}:'
      '${p.newLineName}:${p.joinLineId}:${p.generate}',
    ),
    onCompare: (line, a, b, r) => _c('compare:$line:$a:$b:${r.name}'),
    onBreed: (line, k) => _c('breed:$line:${k.join(',')}'),
    onGenerateChildren: (line, n) => _c('children:$line:$n'),
    onRenameLine: (id, n) => _c('renameLine:$id:$n'),
    onDeleteLine: (id) => _c('deleteLine:$id'),
    onOpenVariable: (i) => _c('variable:$i'),
    onOpenBlockLibrary: () => _c('library'),
    onCardSizeChanged: (s) => _c('size:${s.name}'),
    onInspectorChanged: (v) => _c('inspector:$v'),
    onEditorWidthChanged: (w) => _c('editorWidth:${w.round()}'),
    onFullscreenChanged: (v) => _c('fullscreen:$v'),
    onCaptionOverStage: (v) => _c('caption:$v'),
  );
}
