import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48。
const refsRail = 48.0;

/// 按“窗口宽”装一个参考库页（扣掉主导航），关掉动画，带窗口按钮避让，图片先解码好。
/// 基准图要画真投影：测试体里先 `debugDisableShadows = false`，结束前改回 true。
Future<void> pumpRefs(
  WidgetTester tester, {
  required RefsViewData data,
  RefsActions? actions,
  double window = 1600,
  double height = 1000,
  String locale = 'zh',
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - refsRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    refsApp(
      RefsLibraryPage(data: data, actions: actions ?? RefsActions.none),
      locale: locale,
      dark: dark,
    ),
  );
  await precacheRefs(tester, [
    for (final e in data.entries) ?e.thumb,
    ?data.detail?.image,
    for (final b in data.detail?.bundle ?? const <RefsBundleChild>[]) ?b.thumb,
    for (final t in data.tray.items) ?t.thumb,
    for (final r in data.importDraft?.rows ?? const <RefsImportRow>[]) ...[
      ?r.thumb,
      for (final b in r.bundle) ?b.thumb,
    ],
  ]);
}

Widget refsApp(Widget child, {String locale = 'zh', bool dark = false}) =>
    RepaintBoundary(
      key: const Key('refs-capture'),
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

Future<void> precacheRefs(
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
class RecordingRefsActions {
  final calls = <String>[];
  final filters = <RefsFilter>[];
  final adds = <(List<String>, bool, Map<String, RefsSendOverride>)>[];
  final bundles = <(String, List<int>?, Map<int, RefsSendOverride>)>[];
  final favorites = <(List<String>, bool)>[];
  final patches = <(String, RefsParamsPatch)>[];
  final imports = <RefsImportPlan>[];
  final exports = <RefsExportPlan>[];
  final deletes = <List<String>>[];
  final moves = <(List<String>, String?)>[];

  void _c(String s) => calls.add(s);

  RefsActions get actions => RefsActions(
    onFilterChanged: filters.add,
    onCardSizeChanged: (s) => _c('size:${s.name}'),
    onSidebarChanged: (v) => _c('sidebar:$v'),
    onInspectorChanged: (v) => _c('inspector:$v'),
    onSelect: (k) => _c('select:$k'),
    onAddToGeneration: (keys, {replace = false, overrides = const {}}) =>
        adds.add((keys, replace, overrides)),
    onAddBundle: (key, {indexes, overrides = const {}, replace = false}) =>
        bundles.add((key, indexes, overrides)),
    onSendImg2Img: (k) => _c('img2img:$k'),
    onSaveAsVibe: (k) => _c('saveAsVibe:$k'),
    onSetFavorite: (keys, v) => favorites.add((keys, v)),
    onRename: (k, n) => _c('rename:$k:$n'),
    onUpdateParams: (k, p) => patches.add((k, p)),
    onSetStrengthMany: (keys, v) => _c('strengthMany:${keys.length}:$v'),
    onSetTypeMany: (keys, t) => _c('typeMany:${keys.length}:${t.name}'),
    onSaveBundle: (k, v) => _c('saveBundle:$k:${v.keys.toList()}'),
    onSplitBundle: (k) => _c('split:$k'),
    onSetBundleCover: (k, i) => _c('cover:$k:$i'),
    onPackBundle: (keys) => _c('pack:${keys.length}'),
    onEncodeNow: (k) => _c('encode:$k'),
    onMoveToCategory: (keys, id) => moves.add((keys, id)),
    onAddTags: (keys, tags) => _c('tags:${keys.length}:${tags.join(',')}'),
    onRemoveTag: (k, t) => _c('removeTag:$k:$t'),
    onCreateCategory: (name, {parentId}) async {
      _c('createCategory:$name:$parentId');
      return 'new';
    },
    onRenameCategory: (id, n) => _c('renameCategory:$id:$n'),
    onDeleteCategory: (id) => _c('deleteCategory:$id'),
    onMoveCategory: (id, p) => _c('moveCategory:$id:$p'),
    onImport: (s) => _c('import:${s.name}'),
    onImportConfirm: imports.add,
    onImportCancel: () => _c('importCancel'),
    onExport: exports.add,
    onPickExportFolder: () async => r'D:\out',
    onExportAll: () => _c('exportAll'),
    onRescan: () => _c('rescan'),
    onOpenFolder: (k) => _c('openFolder:$k'),
    onReplacePreview: (k) => _c('replacePreview:$k'),
    onCopyImage: (k) => _c('copy:$k'),
    onDelete: deletes.add,
    onTrayRemove: (id) => _c('trayRemove:$id'),
    onTrayClear: () => _c('trayClear'),
    onPauseVibes: (v) => _c('pause:$v'),
    onGoGeneration: () => _c('goGeneration'),
    onSwitchModel: () => _c('switchModel'),
  );
}
