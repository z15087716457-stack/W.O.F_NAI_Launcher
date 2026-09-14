import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_hover_preview.dart';

/// 1×1 透明 PNG（注入 Image.memory 规避 fakeAsync 区真文件 I/O）。
final _transparentPngBytes = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0a,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0d,
  0x0a,
  0x2d,
  0xb4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
]);

void main() {
  final preview = find.byKey(const Key('explore-candidate-hover-preview'));
  Finder previewFor(String id) =>
      find.byKey(ValueKey('explore-candidate-hover-$id'));
  Finder thumb(String id) => find.byKey(ValueKey('thumb-$id'));

  /// 测试用缩略图：filePath null = 无图项；badgeText 直传（l10n 拼接在
  /// 谱系面板侧，组件不感知）。
  Widget buildThumb(
    ExploreCandidateHoverSession session,
    String id, {
    String? filePath,
    String? badgeText,
  }) {
    return ExploreCandidateHoverThumb(
      key: ValueKey('hover-$id'),
      session: session,
      candidateId: id,
      filePath: filePath,
      badgeText: badgeText ?? '#$id',
      imageBuilder: (context, path) => SizedBox(
        width: 240,
        height: 160,
        child: Image.memory(_transparentPngBytes, fit: BoxFit.contain),
      ),
      // SizedBox(RenderConstrainedBox) 不自命中，需不透明底色让包装件内
      // 的 Listener(deferToChild) 收到 pointerDown（生产里 Image/ColoredBox 兜底）。
      child: ColoredBox(
        color: const Color(0x33000000),
        child: SizedBox(key: ValueKey('thumb-$id'), width: 64, height: 64),
      ),
    );
  }

  Future<void> pumpThumbs(
    WidgetTester tester,
    List<Widget> thumbs, {
    Alignment alignment = Alignment.center,
  }) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: alignment,
            child: Row(mainAxisSize: MainAxisSize.min, children: thumbs),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<TestGesture> hover(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(10, 760));
    await tester.pump();
    return gesture;
  }

  Offset centerOf(WidgetTester tester, String id) =>
      tester.getCenter(thumb(id));

  testWidgets('悬停满 800ms 弹预览：浮层在缩略图上方、带角标、不吃鼠标', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'a', filePath: '/a.png', badgeText: '#1 · 第1轮'),
      buildThumb(session, 'b', filePath: '/b.png'),
    ]);
    final mouse = await hover(tester);

    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump();
    expect(preview, findsNothing);

    await tester.pump(const Duration(milliseconds: 800));
    expect(preview, findsOneWidget);
    expect(previewFor('a'), findsOneWidget);
    expect(find.text('#1 · 第1轮'), findsOneWidget);

    // 居中布局下浮层优先显示在缩略图行上方（含间隙，不遮挡本行）。
    expect(
      tester.getBottomLeft(preview).dy,
      lessThan(tester.getTopLeft(thumb('a')).dy),
    );

    // 整层 IgnorePointer：浮层绝不吃鼠标事件。
    final ignore = tester.widget<IgnorePointer>(
      find.ancestor(of: preview, matching: find.byType(IgnorePointer)).first,
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('未满 800ms 移开不弹；离区超时后再悬停重新计 800ms', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'a', filePath: '/a.png'),
      buildThumb(session, 'b', filePath: '/b.png'),
    ]);
    final mouse = await hover(tester);

    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump(const Duration(milliseconds: 400));
    await mouse.moveTo(const Offset(500, 700));
    await tester.pump(const Duration(milliseconds: 600));
    expect(preview, findsNothing);

    // 会话已结束：重新悬停需重新计满 800ms。
    await mouse.moveTo(centerOf(tester, 'b'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(preview, findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(previewFor('b'), findsOneWidget);
  });

  testWidgets('预览存续期滑到相邻缩略图：0 延迟切换内容与锚点', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'a', filePath: '/a.png'),
      buildThumb(session, 'b', filePath: '/b.png'),
    ]);
    final mouse = await hover(tester);

    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(previewFor('a'), findsOneWidget);

    await mouse.moveTo(centerOf(tester, 'b'));
    await tester.pump();
    expect(previewFor('b'), findsOneWidget);
    expect(previewFor('a'), findsNothing);
  });

  testWidgets('离区 200ms 宽限内回到缩略图免延迟直切，跨间隔不断链', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'a', filePath: '/a.png'),
      buildThumb(session, 'b', filePath: '/b.png'),
    ]);
    final mouse = await hover(tester);

    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(previewFor('a'), findsOneWidget);

    // 离开全部缩略图 100ms（<200ms 宽限）：浮层仍在（滑动不闪烁）。
    await mouse.moveTo(const Offset(500, 700));
    await tester.pump(const Duration(milliseconds: 100));
    expect(previewFor('a'), findsOneWidget);

    // 宽限期内进入另一缩略图：立即切换，无 800ms 重等。
    await mouse.moveTo(centerOf(tester, 'b'));
    await tester.pump();
    expect(previewFor('b'), findsOneWidget);
  });

  testWidgets('无图项不弹浮层且不打断会话；滑到有图项仍免延迟', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'p'),
      buildThumb(session, 'a', filePath: '/a.png'),
    ]);
    final mouse = await hover(tester);

    // 会话从占位项起步：800ms 到点无图不弹，但会话解锁。
    await mouse.moveTo(centerOf(tester, 'p'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(preview, findsNothing);

    // 滑到有图项：0 延迟直弹。
    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump();
    expect(previewFor('a'), findsOneWidget);

    // 预览存续期滑回占位项：浮层撤下，会话不断。
    await mouse.moveTo(centerOf(tester, 'p'));
    await tester.pump();
    expect(preview, findsNothing);
    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump();
    expect(previewFor('a'), findsOneWidget);
  });

  testWidgets('点按缩略图即时关闭预览，会话保持可继续滑动', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'a', filePath: '/a.png'),
      buildThumb(session, 'b', filePath: '/b.png'),
    ]);
    final mouse = await hover(tester);

    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(previewFor('a'), findsOneWidget);

    // 按下即撤浮层（开详情防残余）。
    await mouse.down(centerOf(tester, 'a'));
    await tester.pump();
    expect(preview, findsNothing);
    await mouse.up();
    await tester.pump();

    // 会话未断：滑到下一张仍 0 延迟。
    await mouse.moveTo(centerOf(tester, 'b'));
    await tester.pump();
    expect(previewFor('b'), findsOneWidget);
  });

  testWidgets('悬停/展示项从树上消失：浮层关闭', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'a', filePath: '/a.png'),
      buildThumb(session, 'b', filePath: '/b.png'),
    ]);
    final mouse = await hover(tester);

    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(previewFor('a'), findsOneWidget);

    // 宽限期内浮层仍在（滑动不断链），此时拆掉展示项 → 浮层即时关闭。
    await mouse.moveTo(const Offset(500, 700));
    await tester.pump();
    expect(previewFor('a'), findsOneWidget);
    await pumpThumbs(tester, [buildThumb(session, 'b', filePath: '/b.png')]);
    expect(preview, findsNothing);

    // 同位候选变无图（删图留记录）→ 同样关闭。
    await mouse.moveTo(centerOf(tester, 'b'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(previewFor('b'), findsOneWidget);
    await pumpThumbs(tester, [buildThumb(session, 'b')]);
    expect(preview, findsNothing);
  });

  testWidgets('缩略图行贴顶时浮层自动翻转到下方', (tester) async {
    final session = ExploreCandidateHoverSession();
    addTearDown(session.dispose);
    await pumpThumbs(tester, [
      buildThumb(session, 'a', filePath: '/a.png'),
    ], alignment: Alignment.topCenter);
    final mouse = await hover(tester);

    await mouse.moveTo(centerOf(tester, 'a'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(preview, findsOneWidget);
    expect(
      tester.getTopLeft(preview).dy,
      greaterThan(tester.getBottomLeft(thumb('a')).dy),
    );
  });
}
