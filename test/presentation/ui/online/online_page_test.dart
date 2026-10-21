import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';
import 'package:nai_launcher/presentation/ui/online/online_format.dart';
import 'package:nai_launcher/presentation/ui/online/online_wall.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'online_test_harness.dart';

Finder _k(String key) => find.byKey(Key(key));

void main() {
  setUpAll(loadStudioCaptureFonts);

  late RecordingOnlineActions rec;
  setUp(() => rec = RecordingOnlineActions());

  Future<void> tap(WidgetTester t, String key) async {
    await t.ensureVisible(_k(key));
    await t.pumpAndSettle();
    await t.tap(_k(key));
    await t.pumpAndSettle();
  }

  group('排版', () {
    test('列数按目标宽取整，和原型一致', () {
      expect(OnlineLayout.columns(936, OnlineCardSize.medium), 5);
      expect(OnlineLayout.columns(1278, OnlineCardSize.medium), 6);
      expect(OnlineLayout.columns(936, OnlineCardSize.small), 6);
      expect(OnlineLayout.columns(936, OnlineCardSize.large), 4);
      expect(OnlineLayout.columns(100, OnlineCardSize.large), 1);
    });

    test('瀑布流放进最矮的一列', () {
      expect(OnlineLayout.assign([100, 50, 10, 10], 2), [
        [0],
        [1, 2, 3],
      ]);
    });

    test('格式化', () {
      expect(OnlineFormat.count(12840), '12.8k');
      expect(OnlineFormat.count(1000), '1k');
      expect(OnlineFormat.count(980), '980');
      final seg = OnlineFormat.promptSegments('a, artist:x, 1.2::artist:y::');
      expect(seg.where((s) => s.$2).map((s) => s.$1), [
        'artist:x',
        '1.2::artist:y::',
      ]);
      expect(seg.map((s) => s.$1).join(), 'a, artist:x, 1.2::artist:y::');
    });

    for (final window in [1600.0, 1280.0, 1000.0, 800.0]) {
      testWidgets('窗口 $window 不溢出', (t) async {
        await pumpOnline(t, data: OnlineFixture.view(), window: window);
        expect(t.takeException(), isNull);
        final inspector = _k('online-inspector').evaluate().isNotEmpty;
        final sidebar = _k('online-sidebar').evaluate().isNotEmpty;
        expect(inspector, window >= 1188, reason: '墙宽不到 560 时先收检查器');
        expect(sidebar, window >= 848, reason: '再不够才收左栏');
      });
    }

    for (final (source, mode) in [
      (OnlineSource.aiTag, OnlineMode.ranking),
      (OnlineSource.aiTag, OnlineMode.favorites),
      (OnlineSource.danbooru, OnlineMode.search),
      (OnlineSource.danbooru, OnlineMode.ranking),
      (OnlineSource.danbooru, OnlineMode.favorites),
      (OnlineSource.safebooru, OnlineMode.ranking),
      (OnlineSource.gelbooru, OnlineMode.favorites),
    ]) {
      testWidgets('${source.name} · ${mode.name} 不报错', (t) async {
        await pumpOnline(
          t,
          data: OnlineFixture.view(source: source, mode: mode),
        );
        expect(t.takeException(), isNull);
      });
    }

    for (final size in OnlineCardSize.values) {
      testWidgets('卡片 ${size.name}', (t) async {
        await pumpOnline(t, data: OnlineFixture.view(cardSize: size));
        expect(t.takeException(), isNull);
        final w = t.getSize(_k('online-card-c03')).width;
        expect(w, lessThanOrEqualTo(OnlineLayout.targetWidth(size)));
      });
    }
  });

  group('卡片墙', () {
    testWidgets('不知道原图尺寸：缩略图加载后按真实比例排版，不裁成方块', (t) async {
      // 夹具缩略图是 24×32（竖图）；作品尺寸传 0 = 未知（AI TAG 列表）。
      final base = OnlineFixture.aiTagWorks().first;
      final work = OnlineWork(
        key: base.key,
        id: base.id,
        thumb: base.thumb,
        width: 0,
        height: 0,
        title: base.title,
        author: base.author,
      );
      await pumpOnline(
        t,
        data: OnlineFixture.view(
          list: OnlineList(key: 'unknown', items: [work]),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pumpAndSettle();
      final card = find.byKey(Key('online-card-${work.key}'));
      final image = t.widget<OnlineCard>(
        find.ancestor(of: card, matching: find.byType(OnlineCard)),
      );
      final width = t.getSize(card).width;
      expect(image.imageHeight / width, closeTo(32 / 24, .02));
    });

    testWidgets('单击选中、双击打开大图、Esc 关闭', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await t.tap(_k('online-card-c14'));
      await t.pump(const Duration(milliseconds: 50));
      expect(rec.selects, ['c14']);
      await t.tap(_k('online-card-c14'));
      await t.pumpAndSettle();
      expect(_k('online-viewer'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(_k('online-viewer'), findsNothing);
    });

    testWidgets('大图里切图、Shift+→ 换作品、F / Ctrl+C / Enter', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(selectedKey: 'c14'),
        actions: rec.actions,
      );
      await t.tap(_k('online-card-c14'));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(_k('online-card-c14'));
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pumpAndSettle();
      expect(find.text('图 2 / 12 · 作品 3 / 28'), findsOneWidget);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(rec.selects.last, 't12');
      await t.sendKeyEvent(LogicalKeyboardKey.keyF);
      expect(rec.favorites, ['c14']);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyC);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(rec.copies.single, ['c14']);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(rec.sends.single.$2, OnlineSendMode.replace);
      expect(_k('online-viewer'), findsNothing);
    });

    testWidgets('方向键在墙上移动选中；F 收藏；Ctrl+C 复制', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(rec.selects, hasLength(2));
      expect(rec.selects.first, isNot('c03'));
      await t.sendKeyEvent(LogicalKeyboardKey.keyF);
      expect(rec.favorites, ['c03']);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyC);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(rec.copies, [
        ['c03'],
      ]);
    });

    testWidgets('悬停操作条：收藏、复制、更多菜单', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(cardSize: OnlineCardSize.large),
        actions: rec.actions,
      );
      await hoverOver(t, _k('online-card-c14'));
      Future<void> press(String key) async {
        await t.tap(_k(key));
        await t.pumpAndSettle();
      }

      await press('online-card-fav');
      expect(rec.favorites, ['c14']);
      await press('online-card-copy');
      expect(rec.copies.single, ['c14']);
      await press('online-card-more');
      expect(_k('online-menu'), findsOneWidget);
      await t.tap(find.text('在网站打开'));
      await t.pumpAndSettle();
      expect(rec.calls, contains('open:c14'));
    });

    testWidgets('右键菜单：只看 TA', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await t.tap(_k('online-card-c14'), buttons: kSecondaryButton);
      await t.pumpAndSettle();
      await t.tap(find.text('只看 TA').last);
      await t.pumpAndSettle();
      expect(rec.calls, contains('onlyAuthor:c14'));
    });

    testWidgets('滚到底触发加载下一页', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await t.drag(_k('online-wall'), const Offset(0, -4000));
      await t.pumpAndSettle();
      expect(rec.calls, contains('loadMore'));
    });

    testWidgets('追加失败可重试；到底写清总数和黑名单', (t) async {
      final items = OnlineFixture.aiTagWorks().take(6).toList();
      await pumpOnline(
        t,
        data: OnlineFixture.view(
          list: OnlineList(
            key: 'x',
            items: items,
            pages: 3,
            hasMore: true,
            appendError: const OnlineAppendError(page: 4, reason: '超时'),
          ),
        ),
        actions: rec.actions,
      );
      expect(find.text('第 4 页没加载出来：超时'), findsOneWidget);
      await tap(t, 'online-retry-page');
      expect(rec.calls, contains('retryPage'));
      await pumpOnline(
        t,
        data: OnlineFixture.view(
          list: OnlineList(key: 'y', items: items, blocked: 6),
        ),
      );
      expect(find.text('已经到底了 · 共 6 张 · 黑名单挡掉 6 张'), findsOneWidget);
    });

    testWidgets('第一页加载中画骨架；出错可重试', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(list: const OnlineList(loading: true)),
        actions: rec.actions,
      );
      expect(t.takeException(), isNull);
      expect(_k('online-card-c03'), findsNothing);
      await pumpOnline(
        t,
        data: OnlineFixture.view(list: const OnlineList(error: '断网了')),
        actions: rec.actions,
      );
      expect(find.text('没加载出来：断网了'), findsOneWidget);
      await tap(t, 'online-retry');
      expect(rec.calls, contains('retry'));
    });

    testWidgets('没结果：按当前筛选给放宽建议', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(
          list: const OnlineList(key: 'e'),
          query: const OnlineQuery(work: 'ocean', prompt: 'x'),
          filters: const OnlineFilters(
            model: OnlineModel.v45,
            timeRange: 'y2025',
          ),
        ),
        actions: rec.actions,
      );
      expect(find.text('没有找到 “ocean, x” 的作品'), findsOneWidget);
      await t.tap(find.text('去掉“仅 NAI 图片”'));
      await t.tap(find.text('换成全部时间'));
      await t.tap(find.text('模型改成全部'));
      await t.tap(find.text('清空 Prompt 条件'));
      expect(
        rec.calls,
        containsAll(['naiOnly:false', 'time:all', 'model:null']),
      );
      expect(rec.searches.single.prompt, '');
    });
  });

  group('多选', () {
    testWidgets('勾选 → 收藏到子集 / 新建子集；下载按图数；退出', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await tap(t, 'online-multi');
      expect(_k('online-inspector'), findsNothing);
      await tap(t, 'online-card-c03');
      await tap(t, 'online-card-c14');
      expect(find.text('已选 2 张'), findsOneWidget);
      expect(find.text('下载 · 16 张图'), findsOneWidget);
      expect(rec.selects, isEmpty);
      await tap(t, 'online-sel-favorite');
      await tap(t, 'online-favto-style');
      expect(rec.favoriteMany.single.$1, ['c03', 'c14']);
      expect(rec.favoriteMany.single.$2, 'style');
      expect(_k('online-selection-bar'), findsNothing);

      await tap(t, 'online-multi');
      await tap(t, 'online-sel-all');
      expect(find.text('已选 28 张'), findsOneWidget);
      await tap(t, 'online-sel-invert');
      expect(find.text('已选 0 张'), findsOneWidget);
      await tap(t, 'online-card-c03');
      await tap(t, 'online-sel-favorite');
      await tap(t, 'online-favto-new');
      await t.enterText(find.byType(TextField).last, '海边');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.favoriteMany.last.$3, '海边');

      await tap(t, 'online-multi');
      await tap(t, 'online-card-c03');
      await tap(t, 'online-sel-copy');
      await tap(t, 'online-sel-download');
      expect(rec.copies.last, ['c03']);
      expect(rec.downloads.last.$2, isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(_k('online-selection-bar'), findsNothing);
    });

    testWidgets('Danbooru 多选直接收藏到网站', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(source: OnlineSource.danbooru),
        actions: rec.actions,
      );
      await tap(t, 'online-multi');
      await tap(t, 'online-card-db-c04');
      expect(find.text('收藏到网站'), findsOneWidget);
      await tap(t, 'online-sel-favorite');
      expect(rec.favoriteMany.single.$1, ['db-c04']);
    });
  });

  group('检查器与发送', () {
    testWidgets('三种发送方式；记住选择；没参数时第三种不可选', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await tap(t, 'online-insp-send');
      expect(_k('online-send-popover'), findsOneWidget);
      expect(find.text('生图页现在的正向有 386 字，会被替换'), findsOneWidget);
      await tap(t, 'online-send-withParams');
      await tap(t, 'online-send-go');
      expect(rec.sends.single, ('c03', OnlineSendMode.withParams, true));

      await pumpOnline(
        t,
        data: OnlineFixture.view(source: OnlineSource.danbooru),
        actions: rec.actions,
      );
      await tap(t, 'online-insp-send-modes');
      expect(find.text('这张图没有生成参数，只能发送提示词'), findsOneWidget);
      await tap(t, 'online-send-withParams');
      await tap(t, 'online-send-remember');
      await tap(t, 'online-send-go');
      expect(rec.sends.last, ('db-c04', OnlineSendMode.replace, false));
    });

    testWidgets('记住过方式：主按钮直接发，箭头仍可选', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(
          send: const OnlineSendContext(remembered: OnlineSendMode.promptOnly),
        ),
        actions: rec.actions,
      );
      await tap(t, 'online-insp-send');
      expect(_k('online-send-popover'), findsNothing);
      expect(rec.sends.single.$2, OnlineSendMode.promptOnly);
      await tap(t, 'online-insp-send-modes');
      expect(_k('online-send-popover'), findsOneWidget);
    });

    testWidgets('作者、标签、收藏、复制、多图下载菜单', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await tap(t, 'online-insp-only-author');
      await tap(t, 'online-insp-fav-author');
      await tap(t, 'online-site-tag-海');
      await tap(t, 'online-insp-fav');
      await tap(t, 'online-insp-copy');
      await tap(t, 'online-insp-open');
      expect(
        rec.calls,
        containsAll(['onlyAuthor:c03', 'favAuthor:c03', 'tag:海', 'open:c03']),
      );
      expect(rec.favorites, ['c03']);
      await tap(t, 'online-insp-download');
      await t.tap(find.text('只下载这一张'));
      await t.pumpAndSettle();
      final d = rec.downloads.single;
      expect((d.$1, d.$2, d.$3), (d.$1, false, 0));
      expect(d.$1, ['c03']);
    });

    testWidgets('详情加载中 / 失败', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(detailLoading: true),
        actions: rec.actions,
      );
      expect(t.takeException(), isNull);
      expect(_k('online-insp-prompt'), findsNothing);
      await pumpOnline(t, data: OnlineFixture.view(selectedKey: null));
      expect(find.text('单击一张卡片，在这里看 Prompt 和生成参数'), findsOneWidget);
    });

    testWidgets('Danbooru 分组标签点一下加入搜索', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(source: OnlineSource.danbooru),
        actions: rec.actions,
      );
      await tap(t, 'online-tag-row-scarf');
      expect(rec.calls, contains('tag:scarf'));
    });
  });

  group('工具栏与筛选', () {
    testWidgets('AI TAG 两段搜索：回车提交作品和 Prompt', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await t.enterText(_k('online-search-work'), 'sea');
      await t.enterText(_k('online-search-prompt'), 'artist:wlop');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.searches.single.work, 'sea');
      expect(rec.searches.single.prompt, 'artist:wlop');
    });

    testWidgets('标签补全：方向键 + 回车接受', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await t.enterText(_k('online-search-work'), 'oc');
      await t.pump(const Duration(milliseconds: 200));
      await t.pumpAndSettle();
      expect(_k('online-suggest'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(_k('online-search-work')).controller!.text,
        'ocean_view ',
      );
    });

    testWidgets('Danbooru 标签块：空格成块、× 删除并搜索、模糊匹配', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(source: OnlineSource.danbooru),
        actions: rec.actions,
      );
      await t.enterText(_k('online-search-tags'), 'scarf ');
      await t.pumpAndSettle();
      expect(find.text('scarf'), findsWidgets);
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.searches.last.tags, [
        'shiroko_(blue_archive)',
        '1girl',
        '-comic',
        'scarf',
      ]);
      await t.tap(
        find.descendant(
          of: _k('online-tag-1'),
          matching: find.byType(GestureDetector),
        ),
      );
      await t.pumpAndSettle();
      expect(rec.searches.last.tags, contains('-comic'));
      expect(rec.searches.last.tags, isNot(contains('1girl')));
      await tap(t, 'online-fuzzy');
      expect(rec.searches.last.fuzzy, isTrue);
    });

    testWidgets('卡片大小、多选、刷新、检查器、收起左栏', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await t.tap(find.byTooltip('大'));
      await tap(t, 'online-refresh');
      await tap(t, 'online-inspector-toggle');
      await t.tap(find.byTooltip('收起左栏'));
      await t.pumpAndSettle();
      expect(
        rec.calls,
        containsAll([
          'size:large',
          'refresh',
          'inspector:false',
          'sidebar:false',
        ]),
      );
      await pumpOnline(
        t,
        data: OnlineFixture.view(sidebarOpen: false),
        actions: rec.actions,
      );
      await t.tap(find.byTooltip('展开左栏'));
      expect(rec.calls, contains('sidebar:true'));
    });

    testWidgets('仅 NAI、模型、时间范围、跳到页', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await tap(t, 'online-nai-only');
      await t.tap(find.text('V4.5').first);
      await tap(t, 'online-time-range');
      await t.tap(find.text('2026 Q3'));
      await t.pumpAndSettle();
      await tap(t, 'online-jump');
      await t.enterText(_k('online-jump-input'), '7');
      await tap(t, 'online-jump-go');
      expect(
        rec.calls,
        containsAll(['naiOnly:false', 'model:v45', 'time:q2026Q3', 'jump:7']),
      );
    });

    testWidgets('月榜月份和更早归档；Danbooru 热门翻日期', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(mode: OnlineMode.ranking),
        actions: rec.actions,
      );
      await t.tap(find.text('2026-08'));
      await t.tap(find.text('更早归档'));
      await t.pumpAndSettle();
      await t.tap(find.text('2026-05'));
      await t.pumpAndSettle();
      expect(rec.calls, containsAll(['period:2026-08', 'period:2026-05']));
      expect(find.text('1'), findsWidgets, reason: '排行显示名次');

      await pumpOnline(
        t,
        data: OnlineFixture.view(
          source: OnlineSource.danbooru,
          mode: OnlineMode.ranking,
        ),
        actions: rec.actions,
      );
      await t.tap(find.text('周榜'));
      await t.tap(find.byTooltip('上一个'));
      await t.pumpAndSettle();
      expect(rec.calls, contains('scale:week'));
      expect(rec.calls.last, startsWith('rankDate:2026-10-04'));
    });

    testWidgets('评级至少留一个', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(source: OnlineSource.danbooru),
        actions: rec.actions,
      );
      await tap(t, 'online-rating-questionable');
      expect(rec.calls.last, 'ratings:general,sensitive,questionable');
      await pumpOnline(
        t,
        data: OnlineFixture.view(
          source: OnlineSource.danbooru,
          filters: const OnlineFilters(ratings: {OnlineRating.general}),
        ),
        actions: rec.actions,
      );
      final before = rec.calls.length;
      await tap(t, 'online-rating-general');
      expect(rec.calls.length, before);
    });
  });

  group('左栏', () {
    testWidgets('换来源浮层写清能力；选中换来源', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await tap(t, 'online-source-card');
      expect(_k('online-source-popover'), findsOneWidget);
      expect(find.text('收藏（只读）'), findsOneWidget);
      expect(find.text('只有全年龄'), findsOneWidget);
      await tap(t, 'online-source-gelbooru');
      expect(rec.calls, contains('source:gelbooru'));
    });

    testWidgets('不支持的浏览方式灰掉不回调', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(source: OnlineSource.gelbooru),
        actions: rec.actions,
      );
      expect(find.text('没有排行'), findsOneWidget);
      expect(find.text('只读'), findsOneWidget);
      await tap(t, 'online-mode-ranking');
      await tap(t, 'online-mode-favorites');
      expect(rec.calls, ['mode:favorites']);
    });

    testWidgets('最近搜索点回、清除', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      await tap(t, 'online-recent-1');
      await t.tap(find.text('清除'));
      expect(rec.calls, ['recent:artist:ciloranko', 'clearRecent']);
    });

    testWidgets('黑名单：加、删、同步开关', (t) async {
      await pumpOnline(t, data: OnlineFixture.view(), actions: rec.actions);
      expect(find.text('屏蔽 12 个标签'), findsOneWidget);
      await tap(t, 'online-blacklist');
      await t.enterText(_k('online-blacklist-input'), 'gore');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: _k('online-blacklist-tag-comic'),
          matching: find.byType(GestureDetector),
        ),
      );
      await tap(t, 'online-blacklist-sync');
      expect(rec.calls, ['blAdd:gore', 'blRemove:comic', 'sync:false']);
    });

    testWidgets('收藏：子集、作者、新建、重命名、拖到子集', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(mode: OnlineMode.favorites),
        actions: rec.actions,
      );
      expect(_k('online-drag-hint'), findsOneWidget);
      await tap(t, 'online-collection-style');
      await tap(t, 'online-collection-');
      await tap(t, 'online-author-100');
      await t.tap(find.byTooltip('新建子集'));
      await t.pumpAndSettle();
      await t.enterText(_k('online-collection-name'), '夜景');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await t.tap(_k('online-collection-comp'), buttons: kSecondaryButton);
      await t.pumpAndSettle();
      await t.tap(find.text('删除子集'));
      await t.pumpAndSettle();
      expect(
        rec.calls,
        containsAll([
          'collection:style',
          'collection:',
          'author:100',
          'create:夜景',
          'delete:comp',
        ]),
      );

      await t.ensureVisible(_k('online-card-c14'));
      await t.pumpAndSettle();
      final card = t.getCenter(_k('online-card-c14'));
      final target = t.getCenter(_k('online-collection-color'));
      final g = await t.startGesture(card);
      await g.moveBy(const Offset(30, 0));
      await t.pump();
      await g.moveTo(target);
      await t.pump();
      await g.up();
      await t.pumpAndSettle();
      expect(rec.moves.single.$1, ['c14']);
      expect(rec.moves.single.$2, 'color');
    });

    testWidgets('只看收藏作者：头部两个操作', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(mode: OnlineMode.favorites, authorId: 100),
        actions: rec.actions,
      );
      expect(find.text('收藏了 24 张 · 收藏作者于 2026-08-12'), findsOneWidget);
      await tap(t, 'online-author-works');
      await tap(t, 'online-author-unfav');
      expect(rec.calls, ['authorWorks:100', 'unfavAuthor:100']);
    });

    testWidgets('Danbooru 收藏未登录：登录和 API Key 说明', (t) async {
      await pumpOnline(
        t,
        data: OnlineFixture.view(
          source: OnlineSource.danbooru,
          mode: OnlineMode.favorites,
          statuses: [
            for (final s in OnlineFixture.sources)
              s.source == OnlineSource.danbooru
                  ? const OnlineSourceStatus(
                      source: OnlineSource.danbooru,
                      favorites: true,
                      favoritesWritable: true,
                      account: OnlineAccountState.signedOut,
                    )
                  : s,
          ],
        ),
        actions: rec.actions,
      );
      expect(_k('online-inspector'), findsNothing);
      expect(find.text('未登录'), findsWidgets);
      await tap(t, 'online-login-go');
      await tap(t, 'online-login-help');
      expect(rec.calls, ['login:danbooru', 'apiKeyHelp:danbooru']);
    });
  });
}
