import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48。
const blocksRail = 48.0;

/// 测试用图：一律生成的渐变（不读原型图，结果稳定）。
ImageProvider blocksTestImage(String key) => UiFixtureImage.gradient(key);

/// 按“窗口宽”装一个块系统界面（扣掉主导航），关掉动画，带窗口按钮避让，图片先解码好。
/// 基准图要画真投影：测试体里先 `debugDisableShadows = false`，结束前改回 true。
Future<void> pumpBlocks(
  WidgetTester tester,
  Widget child, {
  double window = 1600,
  double height = 1000,
  String locale = 'zh',
  bool dark = false,
  bool rail = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - (rail ? blocksRail : 0), height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(blocksApp(child, locale: locale, dark: dark));
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Scaffold));
    for (final b in BlocksFixture.blocks(blocksTestImage)) {
      if (b.thumb != null) await precacheImage(b.thumb!.image, ctx);
    }
    await precacheImage(blocksTestImage('c12'), ctx);
  });
  await tester.pumpAndSettle();
}

Widget blocksApp(Widget child, {String locale = 'zh', bool dark = false}) =>
    RepaintBoundary(
      key: const Key('blocks-capture'),
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

/// 记录所有回调，断言用。每条记成 `名字:参数` 一行。
class RecordingBlocks {
  final calls = <String>[];
  final drafts = <BlockDraft>[];
  final patches = <(String, BlockPatch)>[];
  final settings = <BlockRollSettings>[];
  final quicks = <BlockQuickDraft>[];

  void _c(String s) => calls.add(s);

  BlocksLibraryActions get library => BlocksLibraryActions(
    onScopeChanged: (s) => _c('scope:${s.kind.name}:${s.id}'),
    onQueryChanged: (q) => _c('query:$q'),
    onSortChanged: (s, {required descending}) =>
        _c('sort:${s.name}:$descending'),
    onViewChanged: (v) => _c('view:${v.name}'),
    onQuickChanged: (q) =>
        _c('quick:${(q.map((e) => e.name).toList()..sort()).join(',')}'),
    onCardSizeChanged: (v) => _c('size:${v.toStringAsFixed(2)}'),
    onSidebarChanged: (v) => _c('sidebar:$v'),
    onInspectorChanged: (v) => _c('inspector:$v'),
    onSelect: (id) => _c('select:$id'),
    onInsert: (ids) => _c('insert:${ids.join(',')}'),
    onSetFavorite: (ids, v) => _c('favorite:${ids.join(',')}:$v'),
    onDuplicate: (id) => _c('duplicate:$id'),
    onCopyText: (id) => _c('copyText:$id'),
    onCreate: (d) async => drafts.add(d),
    onSave: (id, d) async {
      _c('save:$id');
      drafts.add(d);
    },
    onUpdate: (id, p) => patches.add((id, p)),
    onBatchStyle: (ids, {color, look}) =>
        _c('batchStyle:${ids.length}:${look?.name}:${color != null}'),
    onDelete: (ids) => _c('delete:${ids.join(',')}'),
    onDropToFolder: (ids, f, m) =>
        _c('dropFolder:${ids.join(',')}:$f:${m.name}'),
    onDropToCollection: (ids, k, m) =>
        _c('dropCollection:${ids.join(',')}:$k:${m.name}'),
    onRemoveFromCollection: (ids, k) =>
        _c('removeFromCollection:${ids.join(',')}:$k'),
    onReorder: (id, before) => _c('reorder:$id:$before'),
    onAddTag: (ids, t) => _c('addTag:${ids.join(',')}:${t.name}'),
    onRemoveTag: (ids, t) => _c('removeTag:${ids.join(',')}:$t'),
    onAddToPalette: (ids) => _c('palette:${ids.join(',')}'),
    onExport: (ids) => _c('export:${ids.join(',')}'),
    onApplyParams: (id) => _c('applyParams:$id'),
    onPickThumbnail: () async {
      _c('pickThumb');
      return BlockThumbPick(blocksTestImage('c12'), 'c12');
    },
    onCaptureParams: () async {
      _c('captureParams');
      return BlocksFixture.y99Params;
    },
    onCreateFolder: (name, {parentId}) async {
      _c('createFolder:$name:$parentId');
      return 'new';
    },
    onRenameFolder: (id, n) => _c('renameFolder:$id:$n'),
    onDeleteFolder: (id) => _c('deleteFolder:$id'),
    onToggleFolder: (id, v) => _c('toggleFolder:$id:$v'),
    onMoveFolder: (id, p) => _c('moveFolder:$id:$p'),
    onReorderFolder: (id, d) => _c('reorderFolder:$id:$d'),
    onCreateCollection: (name, {parentId, isFolder = false}) async {
      _c('createCollection:$name');
      return 'new';
    },
    onRenameCollection: (id, n) => _c('renameCollection:$id:$n'),
    onDeleteCollection: (id) => _c('deleteCollection:$id'),
    onRenameTag: (n, m) => _c('renameTag:$n:$m'),
    onSetTagColor: (n, c) => _c('tagColor:$n'),
    onDeleteTag: (n) => _c('deleteTag:$n'),
    onImportTxt: () => _c('importTxt'),
    onImportFolder: () => _c('importFolder'),
    onImportCuration: () => _c('importCuration'),
    onExportBackup: () => _c('exportBackup'),
    onImportBackup: () => _c('importBackup'),
  );

  BlocksDockActions get dock => BlocksDockActions(
    onQueryChanged: (q) => _c('dock.query:$q'),
    onFilterChanged: (f) => _c('dock.filter:${f.favorites}:${f.folderId}'),
    onInsert: (id) => _c('dock.insert:$id'),
    dragDataOf: (id) => id,
    onCreate: () => _c('dock.create'),
    onOpenLibrary: () => _c('dock.openLibrary'),
    onClose: () => _c('dock.close'),
    onToggleGroup: (g, v) => _c('dock.toggle:$g:$v'),
    onEdit: (id) => _c('dock.edit:$id'),
    onSetFavorite: (id, v) => _c('dock.favorite:$id:$v'),
    onAddToPalette: (id) => _c('dock.palette:$id'),
    onShowInLibrary: (id) => _c('dock.show:$id'),
  );

  BlockInstanceActions instance(BlockInstanceViewData d) =>
      BlockInstanceActions(
        onReroll: () => _c('reroll'),
        onLockChanged: (v) => _c('lock:$v'),
        onModeChanged: (m) => _c('mode:${m.name}'),
        onStep: (n) => _c('step:$n'),
        onSideChanged: (s) => _c('side:${s.name}'),
        onEnabledChanged: (v) => _c('enabled:$v'),
        onEditBlock: () => _c('editBlock'),
        onRemove: () => _c('remove'),
        onApplyParams: () => _c('applyParams'),
        onSaveSettings: settings.add,
        sample: (s, n) => BlocksFixture.sample(d.block, s, n, seed: 7),
        onShowInLibrary: () => _c('showInLibrary'),
        onCopySend: () => _c('copySend'),
      );

  BlockEditActions get edit => BlockEditActions(
    onSave: drafts.add,
    onCancel: () => _c('edit.cancel'),
    onPickThumbnail: () async {
      _c('edit.pick');
      return BlockThumbPick(blocksTestImage('c12'), 'c12');
    },
    onCaptureParams: () async {
      _c('edit.capture');
      return BlocksFixture.y99Params;
    },
    onDelete: () => _c('edit.delete'),
  );

  BlockQuickSaveActions get quick => BlockQuickSaveActions(
    onSave: quicks.add,
    onCancel: () => _c('quick.cancel'),
  );
}
