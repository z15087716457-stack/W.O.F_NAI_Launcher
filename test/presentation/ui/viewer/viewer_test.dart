// 大图查看器交互：每个回调、快捷键和界面自己的状态（缩放、抽屉、快捷键表、确认框、计时器）。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'viewer_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  late RecordingViewerActions rec;
  setUp(() => rec = RecordingViewerActions());

  Future<void> key(
    WidgetTester t,
    LogicalKeyboardKey k, {
    bool ctrl = false,
    bool shift = false,
  }) async {
    if (ctrl) await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(k);
    if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (ctrl) await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester t,
    ViewerViewData data, {
    double window = 1600,
    double height = 1000,
    double rail = viewerRail,
  }) => pumpViewer(
    t,
    data: data,
    actions: rec.actions,
    window: window,
    height: height,
    rail: rail,
  );

  /// 卸掉页面，取消撤销 / 提示计时器。
  Future<void> done(WidgetTester t) => t.pumpWidget(const SizedBox());

  String zoomLabel(WidgetTester t) {
    final texts = t.widgetList<Text>(
      find.descendant(
        of: find.byKey(const Key('viewer-zoom-menu')),
        matching: find.byType(Text),
      ),
    );
    return texts.first.data!;
  }

  testWidgets('返回：按钮和 Esc 区分键盘', (t) async {
    await pump(t, ViewerFixture.gallery());
    await tapKey(t, 'viewer-back');
    await key(t, LogicalKeyboardKey.escape);
    expect(rec.calls, containsAllInOrder(['close:false', 'close:true']));
    await done(t);
  });

  testWidgets('左右键 / Home End / 箭头 / 胶片条', (t) async {
    await pump(t, ViewerFixture.gallery());
    await key(t, LogicalKeyboardKey.arrowLeft);
    await key(t, LogicalKeyboardKey.arrowRight);
    await key(t, LogicalKeyboardKey.home);
    await key(t, LogicalKeyboardKey.end);
    await tapKey(t, 'viewer-prev');
    await tapKey(t, 'viewer-next');
    await tapKey(t, 'viewer-film-16');
    expect(rec.calls.where((c) => !c.startsWith('caption')), [
      'step:-1',
      'step:1',
      'jump:false',
      'jump:true',
      'step:-1',
      'step:1',
      'select:16',
    ]);
    await done(t);
  });

  testWidgets('范围头上没有上一张箭头', (t) async {
    await pump(t, ViewerFixture.gallery(position: 0));
    expect(find.byKey(const Key('viewer-prev')), findsNothing);
    expect(find.byKey(const Key('viewer-next')), findsOneWidget);
    await done(t);
  });

  testWidgets('顶栏位置和范围', (t) async {
    await pump(t, ViewerFixture.nometa());
    expect(find.textContaining('38,016'), findsOneWidget);
    expect(find.text('氛围图 · 按修改时间'), findsOneWidget);
    await done(t);
  });

  testWidgets('宽窗口 I 回调信息栏开关，窗口按钮位置随之报告', (t) async {
    await pump(t, ViewerFixture.gallery());
    expect(rec.calls, contains('caption:false'));
    await key(t, LogicalKeyboardKey.keyI);
    await tapKey(t, 'viewer-info-toggle');
    expect(rec.calls.where((c) => c.startsWith('info')), [
      'info:false',
      'info:false',
    ]);
    await pump(t, ViewerFixture.gallery(infoOpen: false));
    expect(find.byKey(const Key('viewer-info')), findsNothing);
    expect(rec.calls.last, 'caption:true');
    await done(t);
  });

  testWidgets('窄窗口信息栏是抽屉：I 开关、Esc 先关抽屉', (t) async {
    await pump(t, ViewerFixture.gallery(), window: 1100, height: 760);
    expect(find.byKey(const Key('viewer-drawer')), findsNothing);
    expect(rec.calls, contains('caption:true'));
    await key(t, LogicalKeyboardKey.keyI);
    expect(find.byKey(const Key('viewer-drawer')), findsOneWidget);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byKey(const Key('viewer-drawer')), findsNothing);
    expect(rec.calls, isNot(contains('close:true')));
    await tapKey(t, 'viewer-info-toggle');
    await tapKey(t, 'viewer-drawer-close');
    expect(find.byKey(const Key('viewer-drawer')), findsNothing);
    expect(rec.calls.where((c) => c.startsWith('info')), isEmpty);
    await done(t);
  });

  testWidgets('收藏：F 直接切换，心形打开收藏集', (t) async {
    await pump(t, ViewerFixture.gallery());
    await key(t, LogicalKeyboardKey.keyF);
    expect(rec.calls.last, 'favorite:08:false');
    await tapKey(t, 'viewer-info-favorite');
    expect(find.byKey(const Key('viewer-collections')), findsOneWidget);
    await tapKey(t, 'viewer-col-artists');
    await tapKey(t, 'viewer-col-wof');
    await tapKey(t, 'viewer-col-favorite');
    expect(find.byKey(const Key('viewer-collections')), findsOneWidget);
    await tapKey(t, 'viewer-col-new');
    expect(find.byKey(const Key('viewer-collections')), findsNothing);
    expect(rec.calls.sublist(rec.calls.length - 4), [
      'collection:08:artists:true',
      'collection:08:wof:false',
      'favorite:08:false',
      'newCollection:08',
    ]);
    await done(t);
  });

  testWidgets('删除：普通图直接删，受保护的先确认', (t) async {
    await pump(t, ViewerFixture.gallery());
    await key(t, LogicalKeyboardKey.delete);
    await tapKey(t, 'viewer-info-delete');
    expect(rec.calls.where((c) => c.startsWith('delete')), [
      'delete:08',
      'delete:08',
    ]);

    rec.calls.clear();
    final d = ViewerFixture.gallery();
    final protected = ViewerViewData(
      mode: d.mode,
      items: [
        for (final i in d.items)
          ViewerItem(
            key: i.key,
            width: i.width,
            height: i.height,
            thumb: i.thumb,
            image: i.image,
            protected: true,
          ),
      ],
      currentKey: d.currentKey,
      now: d.now,
      position: d.position,
      total: d.total,
      detail: d.detail,
      actions: d.actions,
    );
    await pump(t, protected);
    await key(t, LogicalKeyboardKey.delete);
    expect(find.byKey(const Key('viewer-delete')), findsOneWidget);
    expect(rec.calls.where((c) => c.startsWith('delete')), isEmpty);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byKey(const Key('viewer-delete')), findsNothing);
    expect(rec.calls, isNot(contains('close:true')));
    await key(t, LogicalKeyboardKey.delete);
    await tapKey(t, 'viewer-delete-confirm');
    expect(rec.calls.where((c) => c.startsWith('delete')), ['delete:08']);
    await done(t);
  });

  testWidgets('撤销：Ctrl Z / 按钮；6 秒后自动收起', (t) async {
    await pump(t, ViewerFixture.deleted());
    expect(find.byKey(const Key('viewer-undo')), findsOneWidget);
    await key(t, LogicalKeyboardKey.keyZ, ctrl: true);
    await tapKey(t, 'viewer-undo-button');
    expect(rec.calls.where((c) => c == 'undo'), hasLength(2));
    await t.pump(const Duration(seconds: 6));
    expect(rec.calls.last, 'dismissUndo');
    await done(t);
  });

  testWidgets('缩放：+ / 0 / 1 / 菜单 / 双击；放大后有小地图和一次性提示', (t) async {
    await pump(t, ViewerFixture.gallery());
    expect(zoomLabel(t), startsWith('适应 · '));
    expect(find.byKey(const Key('viewer-minimap')), findsNothing);
    await key(t, LogicalKeyboardKey.digit1);
    expect(zoomLabel(t), '100%');
    expect(find.byKey(const Key('viewer-zoom-hint')), findsOneWidget);
    await key(t, LogicalKeyboardKey.equal);
    expect(zoomLabel(t), '125%');
    expect(find.byKey(const Key('viewer-minimap')), findsOneWidget);
    // 能拖动时收起左右箭头，回到适应再出来。
    expect(find.byKey(const Key('viewer-next')), findsNothing);
    await key(t, LogicalKeyboardKey.digit0);
    expect(zoomLabel(t), startsWith('适应'));
    expect(find.byKey(const Key('viewer-next')), findsOneWidget);
    await tapKey(t, 'viewer-zoom-menu');
    await tapKey(t, 'viewer-zoom-400');
    expect(zoomLabel(t), '400%');
    await tapKey(t, 'viewer-zoom-out');
    expect(zoomLabel(t), '320%');
    await tapKey(t, 'viewer-actual');
    expect(zoomLabel(t), '100%');
    final view = find.byKey(const Key('viewer-view'));
    await t.tap(view);
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(view);
    await t.pumpAndSettle();
    expect(zoomLabel(t), startsWith('适应'));
    await t.pump(const Duration(seconds: 4));
    expect(rec.calls, contains('zoomHintSeen'));
    expect(find.byKey(const Key('viewer-zoom-hint')), findsNothing);
    await done(t);
  });

  testWidgets('看过提示就不再出；滚轮以鼠标处缩放', (t) async {
    await pump(t, ViewerFixture.gallery(zoomHintSeen: true));
    final center = t.getCenter(find.byKey(const Key('viewer-view')));
    final g = TestPointer(1, PointerDeviceKind.mouse);
    await t.sendEventToBinding(g.hover(center));
    await t.sendEventToBinding(g.scroll(const Offset(0, -100)));
    await t.pumpAndSettle();
    expect(zoomLabel(t), isNot(startsWith('适应')));
    expect(find.byKey(const Key('viewer-zoom-hint')), findsNothing);
    await done(t);
  });

  testWidgets('复用参数：Ctrl R / 主按钮；没有元数据时灰掉', (t) async {
    await pump(t, ViewerFixture.gallery());
    await key(t, LogicalKeyboardKey.keyR, ctrl: true);
    await tapKey(t, 'viewer-primary');
    expect(rec.calls.where((c) => c.startsWith('action')), [
      'action:08:reuse',
      'action:08:reuse',
    ]);

    rec.calls.clear();
    await pump(t, ViewerFixture.nometa());
    expect(find.byKey(const Key('viewer-info-nometa')), findsOneWidget);
    await key(t, LogicalKeyboardKey.keyR, ctrl: true);
    await tapKey(t, 'viewer-primary');
    await key(t, LogicalKeyboardKey.keyC, ctrl: true);
    expect(
      rec.calls.where((c) => c.startsWith('action') || c.startsWith('copy')),
      isEmpty,
    );
    await tapKey(t, 'viewer-tile-img2img');
    expect(rec.calls.last, 'action:04:img2img');
    await done(t);
  });

  testWidgets('复制和翻译按段走；Ctrl C 复制主提示词', (t) async {
    await pump(t, ViewerFixture.gallery(current: '29', favorite: false));
    await key(t, LogicalKeyboardKey.keyC, ctrl: true);
    await tapKey(t, 'viewer-copy-seed');
    await tapKey(t, 'viewer-copy-prompt0');
    await tapKey(t, 'viewer-translate-prompt0');
    await t.ensureVisible(find.byKey(const Key('viewer-copy-character2')));
    await t.pumpAndSettle();
    await tapKey(t, 'viewer-copy-character2');
    await tapKey(t, 'viewer-translate-character1');
    await t.ensureVisible(find.byKey(const Key('viewer-copy-negative0')));
    await t.pumpAndSettle();
    await tapKey(t, 'viewer-copy-negative0');
    expect(
      rec.calls.where((c) => c.startsWith('copy') || c.startsWith('translate')),
      [
        'copy:29:prompt',
        'copy:29:seed',
        'copy:29:prompt',
        'translate:29:prompt',
        'copy:29:character(2)',
        'translate:29:character(1)',
        'copy:29:negative',
      ],
    );
    expect(find.text('位置 C3'), findsNothing);
    expect(find.text('C3'), findsWidgets);
    await done(t);
  });

  testWidgets('译文替换原文显示；失败显示原因', (t) async {
    await pump(
      t,
      ViewerFixture.gallery(
        current: '29',
        translations: {
          ViewerPart.prompt: const ViewerTranslation(text: '官方插画，视觉小说 CG'),
          const ViewerPart.character(0): const ViewerTranslation(error: '额度用完'),
        },
      ),
    );
    expect(
      find.textContaining('官方插画，视觉小说 CG', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('翻译失败：额度用完'), findsOneWidget);
    await done(t);
  });

  testWidgets('提示词折叠：展开全部 / 收起', (t) async {
    await pump(t, ViewerFixture.gallery());
    Future<void> toggle() async {
      await t.ensureVisible(find.byKey(const Key('viewer-prompt-more')));
      await t.pumpAndSettle();
      await tapKey(t, 'viewer-prompt-more');
    }

    expect(find.text('展开全部'), findsOneWidget);
    await toggle();
    expect(find.text('展开全部'), findsNothing);
    expect(find.text('收起'), findsOneWidget);
    await toggle();
    expect(find.text('展开全部'), findsOneWidget);
    await done(t);
  });

  testWidgets('操作格：Krita 没连接时灰掉', (t) async {
    await pump(t, ViewerFixture.gallery());
    for (final a in [
      'img2img',
      'styleTransfer',
      'preciseRef',
      'saveToRefLibrary',
      'upscale',
      'krita',
    ]) {
      await tapKey(t, 'viewer-tile-$a');
    }
    expect(rec.calls.where((c) => c.startsWith('action')), [
      'action:08:img2img',
      'action:08:styleTransfer',
      'action:08:preciseRef',
      'action:08:saveToRefLibrary',
      'action:08:upscale',
    ]);
    await done(t);
  });

  testWidgets('更多菜单：每一项都回调，收藏集子菜单在旁边展开', (t) async {
    await pump(t, ViewerFixture.gallery());
    for (final a in [
      'copyImage',
      'copyPath',
      'copyAllPrompts',
      'saveAsBlock',
      'moveTo',
      'copyTo',
    ]) {
      await tapKey(t, 'viewer-info-more');
      await tapKey(t, 'viewer-more-$a');
      expect(find.byKey(const Key('viewer-more')), findsNothing);
      expect(rec.calls.last, 'action:08:$a');
    }
    await tapKey(t, 'viewer-info-more');
    await tapKey(t, 'viewer-more-collections');
    expect(find.byKey(const Key('viewer-collections')), findsOneWidget);
    await tapKey(t, 'viewer-col-travel');
    expect(rec.calls.last, 'collection:08:travel:true');
    await tapKey(t, 'viewer-more-delete');
    expect(rec.calls.last, 'delete:08');
    await tapKey(t, 'viewer-info-folder');
    expect(rec.calls.last, 'action:08:showInFolder');
    await done(t);
  });

  testWidgets('快捷键表：? 开关，Esc 只关表', (t) async {
    await pump(t, ViewerFixture.gallery());
    await key(t, LogicalKeyboardKey.slash, shift: true);
    expect(find.byKey(const Key('viewer-help')), findsOneWidget);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byKey(const Key('viewer-help')), findsNothing);
    expect(rec.calls, isNot(contains('close:true')));
    await key(t, LogicalKeyboardKey.slash, shift: true);
    await key(t, LogicalKeyboardKey.slash, shift: true);
    expect(find.byKey(const Key('viewer-help')), findsNothing);
    await done(t);
  });

  testWidgets('快捷键按设置显示和生效', (t) async {
    final d = ViewerFixture.gallery();
    await pump(
      t,
      ViewerViewData(
        mode: d.mode,
        items: d.items,
        currentKey: d.currentKey,
        now: d.now,
        position: d.position,
        total: d.total,
        detail: d.detail,
        actions: d.actions,
        keys: const {
          ViewerCommand.reuse: [
            SingleActivator(LogicalKeyboardKey.keyU, control: true),
          ],
        },
      ),
    );
    expect(find.text('Ctrl U'), findsOneWidget);
    await key(t, LogicalKeyboardKey.keyR, ctrl: true);
    expect(rec.calls.where((c) => c.startsWith('action')), isEmpty);
    await key(t, LogicalKeyboardKey.keyU, ctrl: true);
    expect(rec.calls.last, 'action:08:reuse');
    await done(t);
  });

  testWidgets('全屏：F11 进出；全屏里 Esc 先退出全屏，I 开抽屉', (t) async {
    await pump(t, ViewerFixture.gallery());
    await key(t, LogicalKeyboardKey.f11);
    await tapKey(t, 'viewer-fullscreen');
    expect(rec.calls.where((c) => c.startsWith('fullscreen')), [
      'fullscreen:true',
      'fullscreen:true',
    ]);

    rec.calls.clear();
    await pump(t, ViewerFixture.gallery(fullscreen: true), rail: 0);
    expect(find.byKey(const Key('viewer-topbar')), findsNothing);
    expect(find.byKey(const Key('viewer-info')), findsNothing);
    expect(find.byKey(const Key('viewer-fullscreen-badge')), findsOneWidget);
    await key(t, LogicalKeyboardKey.keyI);
    expect(find.byKey(const Key('viewer-drawer')), findsOneWidget);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byKey(const Key('viewer-drawer')), findsNothing);
    await key(t, LogicalKeyboardKey.escape);
    await tapKey(t, 'viewer-fullscreen-exit');
    expect(
      rec.calls.where(
        (c) => c.startsWith('fullscreen') || c.startsWith('close'),
      ),
      ['fullscreen:false', 'fullscreen:false'],
    );
    await done(t);
  });

  testWidgets('全屏：鼠标静止 2 秒藏起控件，移到底部浮出胶片条', (t) async {
    await pump(t, ViewerFixture.gallery(fullscreen: true), rail: 0);
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: const Offset(800, 400));
    addTearDown(g.removePointer);
    await g.moveTo(const Offset(810, 400));
    await t.pump();
    expect(find.byKey(const Key('viewer-fullscreen-badge')), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('viewer-fullscreen-badge')), findsNothing);
    expect(find.byKey(const Key('viewer-filmstrip')), findsNothing);
    await g.moveTo(const Offset(800, 960));
    await t.pump();
    expect(find.byKey(const Key('viewer-filmstrip')), findsOneWidget);
    await done(t);
  });

  testWidgets('生成结果：保存 / Ctrl S；没有收藏和删除', (t) async {
    await pump(t, ViewerFixture.generation());
    expect(find.text('未保存'), findsOneWidget);
    expect(find.byKey(const Key('viewer-info-favorite')), findsNothing);
    expect(find.byKey(const Key('viewer-info-delete')), findsNothing);
    await key(t, LogicalKeyboardKey.keyS, ctrl: true);
    await tapKey(t, 'viewer-primary');
    await key(t, LogicalKeyboardKey.keyF);
    await key(t, LogicalKeyboardKey.delete);
    for (final a in ['copyImage', 'saveAsBlock', 'reuse']) {
      await tapKey(t, 'viewer-tile-$a');
    }
    expect(
      rec.calls.where(
        (c) =>
            c.startsWith('action') ||
            c.startsWith('favorite') ||
            c.startsWith('delete'),
      ),
      [
        'action:16:save',
        'action:16:save',
        'action:16:copyImage',
        'action:16:saveAsBlock',
        'action:16:reuse',
      ],
    );

    rec.calls.clear();
    await pump(t, ViewerFixture.generation(saved: {'16'}));
    expect(find.text('已保存'), findsWidgets);
    await key(t, LogicalKeyboardKey.keyS, ctrl: true);
    await tapKey(t, 'viewer-primary');
    expect(rec.calls.where((c) => c.startsWith('action')), isEmpty);
    await done(t);
  });

  testWidgets('读原图：模糊缩略图 + 读取条；元数据骨架', (t) async {
    await pump(
      t,
      ViewerFixture.gallery(
        current: '16',
        loading: true,
        status: ViewerMetaStatus.loading,
      ),
    );
    expect(find.byKey(const Key('viewer-loading')), findsOneWidget);
    expect(find.textContaining('读取原图 · 1.95 MB'), findsOneWidget);
    expect(find.byKey(const Key('viewer-info-loading')), findsOneWidget);
    expect(zoomLabel(t), '适应 · —');
    await done(t);
  });

  testWidgets('找不到文件：打开文件夹 / 下一张', (t) async {
    await pump(t, ViewerFixture.gallery(current: '16', missing: true));
    expect(find.byKey(const Key('viewer-missing')), findsOneWidget);
    await tapKey(t, 'viewer-missing-folder');
    await tapKey(t, 'viewer-missing-next');
    expect(rec.calls.where((c) => !c.startsWith('caption')), [
      'action:16:showInFolder',
      'step:1',
    ]);
    await done(t);
  });

  testWidgets('Vibe：存入 Vibe 库', (t) async {
    await pump(t, ViewerFixture.generation(current: '41'));
    await t.ensureVisible(find.byKey(const Key('viewer-info-vibes')));
    await t.pumpAndSettle();
    await t.tap(find.text('存入 Vibe 库'));
    await t.pumpAndSettle();
    expect(rec.calls.last, 'saveVibe:41:0');
    await done(t);
  });

  testWidgets('胶片条滚到边缘续读', (t) async {
    await pump(t, ViewerFixture.gallery());
    final strip = find.byKey(const Key('viewer-filmstrip'));
    final g = TestPointer(2, PointerDeviceKind.mouse);
    await t.sendEventToBinding(g.hover(t.getCenter(strip)));
    await t.sendEventToBinding(g.scroll(const Offset(0, 4000)));
    await t.pumpAndSettle();
    expect(rec.calls, contains('more:true'));
    await done(t);
  });
}
