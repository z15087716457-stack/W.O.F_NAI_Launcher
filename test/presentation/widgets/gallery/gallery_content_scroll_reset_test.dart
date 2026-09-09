import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart'
    show FilterCriteria;
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_content_view.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// galleryShouldResetScroll 纯函数 + 翻页滚动复位 widget 回归测试。
///
/// 回归背景：瀑布流/固定网格共用持久 ScrollController 且翻页不重挂，
/// 旧页的滚动偏移会原样带进新页——滚到中途点「下一页」，新页不从顶部
/// 开始，需要手动上滑。
void main() {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  group('galleryShouldResetScroll', () {
    test('翻页（页码变化）→ 复位到顶部', () {
      expect(
        galleryShouldResetScroll(
          samePage: false,
          sameFilters: true,
          sameSort: true,
        ),
        isTrue,
      );
    });

    test('切换过滤条件 → 复位到顶部', () {
      expect(
        galleryShouldResetScroll(
          samePage: true,
          sameFilters: false,
          sameSort: true,
        ),
        isTrue,
      );
    });

    test('切换排序 → 复位到顶部', () {
      expect(
        galleryShouldResetScroll(
          samePage: true,
          sameFilters: true,
          sameSort: false,
        ),
        isTrue,
      );
    });

    test('同页同过滤同排序（元数据原地刷新）→ 不复位', () {
      expect(
        galleryShouldResetScroll(
          samePage: true,
          sameFilters: true,
          sameSort: true,
        ),
        isFalse,
      );
    });
  });

  group('masonry gallery scroll reset', () {
    // 注：不走拖动手势、不用 pumpAndSettle——视口边缘卡片的可见性
    // 回调会持续调度帧，永远等不到静止；用 jumpTo 制造确定的中途偏移。
    testWidgets('滚到中途翻页 → 新页从顶部开始', (tester) async {
      final harness = _ScrollHarness(page: 0);

      await tester.pumpWidget(harness._build());
      await tester.pump(const Duration(milliseconds: 300));

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));

      // 复现：翻页时不在顶部（停在页面中途）
      scrollable.position.jumpTo(400);
      await tester.pump();
      expect(scrollable.position.pixels, greaterThan(0));

      // 点「下一页」：页码 + 内容全部替换
      harness.page = 1;
      harness.records = _records('page2', 16);
      await tester.pumpWidget(harness._build());
      // didUpdateWidget 在 build 期注册的 post-frame 复位，本帧末已生效；
      // 再补一帧消化复位后的可见性回调
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(scrollable.position.pixels, 0, reason: '翻页是新数据集，滚动位置应弹回顶部，不带旧页偏移');
    });

    testWidgets('同页原地刷新（页码/过滤/排序不变）→ 保持滚动位置', (tester) async {
      final harness = _ScrollHarness(page: 0);

      await tester.pumpWidget(harness._build());
      await tester.pump(const Duration(milliseconds: 300));

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );

      scrollable.position.jumpTo(400);
      await tester.pump();
      final offsetBefore = scrollable.position.pixels;
      expect(offsetBefore, greaterThan(0));

      // 同页同长度原地刷新（元数据更新场景）：数据集身份未变
      harness.records = _records('page1', 16);
      await tester.pumpWidget(harness._build());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        scrollable.position.pixels,
        offsetBefore,
        reason: '同一数据集原地刷新不应弹动滚动位置',
      );
    });
  });
}

List<LocalImageRecord> _records(String prefix, int count) => List.generate(
  count,
  (i) => LocalImageRecord(
    path: 'G:/gallery/$prefix-${i.toString().padLeft(2, '0')}.png',
    size: 42,
    modifiedAt: DateTime(2026, 7, 11),
  ),
);

/// 可变数据源外壳：模拟 loadPage 改写 provider 状态后视图重建
class _ScrollHarness {
  _ScrollHarness({required this.page}) : records = _records('page1', 16);

  int page;
  List<LocalImageRecord> records;

  Widget _build() {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: GenericGalleryContentView<LocalImageRecord>(
              useMasonryView: true,
              columns: 2,
              itemWidth: 372,
              columnWidth: 260,
              state: _ScrollGalleryState(page: page, records: records),
              selectionState: const _InactiveSelectionState(),
              itemBuilder: (_, __, ___, ____) => const SizedBox.shrink(),
              idExtractor: (item) => item.path,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollGalleryState implements GalleryState<LocalImageRecord> {
  const _ScrollGalleryState({required this.page, required this.records});

  final int page;
  final List<LocalImageRecord> records;

  @override
  List<LocalImageRecord> get currentImages => records;

  @override
  List<LocalImageRecord> get groupedImages => const [];

  @override
  bool get isGroupedView => false;

  @override
  bool get isPageLoading => false;

  @override
  bool get isGroupedLoading => false;

  @override
  int get currentPage => page;

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

class _InactiveSelectionState implements SelectionState {
  const _InactiveSelectionState();

  @override
  bool get isActive => false;

  @override
  Set<String> get selectedIds => const {};

  @override
  String? get lastSelectedId => null;
}
