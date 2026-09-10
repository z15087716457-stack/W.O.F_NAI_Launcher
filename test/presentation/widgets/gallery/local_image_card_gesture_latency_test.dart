import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart'
    show FilterCriteria;
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/floating_action_buttons.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_content_view.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card_3d.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 卡片手势响应回归：双击识别器不得再拖慢卡片内按钮与卡片本体的点击。
///
/// 背景（修复前实测）：卡片手势层带 onDoubleTap 时，双击识别器会在首次
/// 抬手后 hold 手势竞技场到双击窗口（约 300ms）结束——卡片内按钮点击要等
/// 约 300ms 才响应，窗口内连点还会被判成双击、按钮回调整轮丢失。修复分两步：
/// ① 三个悬浮按钮移出双击手势子树（成为兄弟节点）；② 非多选态不挂卡片双击。
void main() {
  // VisibilityDetector 默认 500ms 周期会在测试结束时留下挂起 Timer
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  LocalImageRecord record(String path) =>
      LocalImageRecord(path: path, size: 100, modifiedAt: DateTime(2026, 1, 1));

  /// 卡片直接嵌在普通手势区里的最小场景：拖拽等画廊装饰层不参与。
  Widget cardApp({
    required LocalImageRecord record,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    void Function(Offset anchor)? onFavoriteToggle,
  }) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: LocalImageCard3D(
              record: record,
              width: 180,
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onFavoriteToggle: onFavoriteToggle,
            ),
          ),
        ),
      ),
    );
  }

  Finder favoriteButton() => find.descendant(
    of: find.byType(FloatingActionButtons),
    matching: find.byIcon(Icons.favorite_border),
  );

  testWidgets('悬浮按钮点击在双击窗口内即时响应（不被双击识别器 hold）', (tester) async {
    var favoriteTaps = 0;
    await tester.pumpWidget(
      cardApp(
        record: record(r'C:\gallery\a.png'),
        onTap: () {},
        // 故意挂上双击：修复前正是它把按钮点击 hold 到 300ms 后
        onDoubleTap: () {},
        onFavoriteToggle: (_) => favoriteTaps++,
      ),
    );
    // 悬停让按钮组显形（按钮本体始终在树上，AnimatedOpacity 只改透明度）
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(LocalImageCard3D)));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(favoriteButton());
    await tester.pump(const Duration(milliseconds: 16));

    expect(favoriteTaps, 1, reason: '按钮点击应在同一帧内响应，不等双击窗口结束');
  });

  testWidgets('双击窗口内连点按钮：两次回调都不丢', (tester) async {
    var favoriteTaps = 0;
    await tester.pumpWidget(
      cardApp(
        record: record(r'C:\gallery\b.png'),
        onTap: () {},
        onDoubleTap: () {},
        onFavoriteToggle: (_) => favoriteTaps++,
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(LocalImageCard3D)));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(favoriteButton());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(favoriteButton());
    await tester.pump(const Duration(milliseconds: 100));

    expect(favoriteTaps, 2, reason: '窗口内第二次点击不得被判成双击吞掉');
  });

  testWidgets('按钮点击不冒泡到卡片（不触发卡片单击/双击）', (tester) async {
    var cardTaps = 0;
    var cardDoubles = 0;
    await tester.pumpWidget(
      cardApp(
        record: record(r'C:\gallery\c.png'),
        onTap: () => cardTaps++,
        onDoubleTap: () => cardDoubles++,
        onFavoriteToggle: (_) {},
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(LocalImageCard3D)));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(favoriteButton());
    await tester.pump(const Duration(milliseconds: 500));

    expect(cardTaps, 0);
    expect(cardDoubles, 0);
  });

  for (final (label, masonry) in <(String, bool)>[
    ('瀑布流', true),
    ('固定网格', false),
  ]) {
    testWidgets('$label 非多选态：画廊不把双击传给卡片（卡片点击即时）', (tester) async {
      final records = [
        record(r'C:\gallery\d0.png'),
        record(r'C:\gallery\d1.png'),
      ];
      LocalImageRecord? tapped;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GenericGalleryContentView<LocalImageRecord>(
                useMasonryView: masonry,
                columns: 2,
                itemWidth: 160,
                columnWidth: 160,
                state: _FakeGalleryState(records),
                selectionState: const _FakeSelectionState(isActive: false),
                itemBuilder: (_, __, ___, ____) => const SizedBox.shrink(),
                idExtractor: (item) => item.path,
                onTap: (item, _) => tapped = item,
                view3DConfig: Gallery3DViewConfig<LocalImageRecord>(
                  images: records,
                  showDetailViewer: (_, __) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final card = tester.widget<LocalImageCard3D>(
        find.byType(LocalImageCard3D).first,
      );
      expect(card.onDoubleTap, isNull, reason: '非多选态下双击与单击同义，不应挂双击识别器');

      await tester.tap(find.byType(LocalImageCard3D).first);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tapped?.path, records.first.path, reason: '卡片点击应即时响应');

      // 放掉画廊可见性回调节流定时器（120ms），避免测试结束时有挂起 Timer
      await tester.pump(const Duration(milliseconds: 300));
    });
  }

  testWidgets('多选态：双击仍开大图（行为不回退）', (tester) async {
    final records = [
      record(r'C:\gallery\e0.png'),
      record(r'C:\gallery\e1.png'),
    ];
    var viewerOpened = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GenericGalleryContentView<LocalImageRecord>(
              useMasonryView: true,
              columns: 2,
              itemWidth: 160,
              columnWidth: 160,
              state: _FakeGalleryState(records),
              selectionState: const _FakeSelectionState(isActive: true),
              itemBuilder: (_, __, ___, ____) => const SizedBox.shrink(),
              idExtractor: (item) => item.path,
              view3DConfig: Gallery3DViewConfig<LocalImageRecord>(
                images: records,
                showDetailViewer: (_, __) => viewerOpened++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final card = tester.widget<LocalImageCard3D>(
      find.byType(LocalImageCard3D).first,
    );
    expect(card.onDoubleTap, isNotNull, reason: '多选态保留双击开大图');

    await tester.tap(find.byType(LocalImageCard3D).first);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byType(LocalImageCard3D).first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(viewerOpened, 1);
  });
}

class _FakeGalleryState implements GalleryState<LocalImageRecord> {
  const _FakeGalleryState(this.records);
  final List<LocalImageRecord> records;

  @override
  List<LocalImageRecord> get currentImages => records;

  @override
  List<LocalImageRecord> get groupedImages => records;

  @override
  bool get isGroupedView => false;

  @override
  bool get isPageLoading => false;

  @override
  bool get isGroupedLoading => false;

  @override
  int get currentPage => 0;

  @override
  bool get hasFilters => false;

  @override
  List<LocalImageRecord> get filteredFiles => records;

  @override
  FilterCriteria get filterCriteria => const FilterCriteria();

  @override
  GallerySortField get sortField => GallerySortField.modifiedAt;

  @override
  GallerySortDirection get sortDirection => GallerySortDirection.descending;
}

class _FakeSelectionState implements SelectionState {
  const _FakeSelectionState({required this.isActive});

  @override
  final bool isActive;

  @override
  Set<String> get selectedIds => const {};

  @override
  String? get lastSelectedId => null;
}
