import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart'
    show FilterCriteria;
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_content_view.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_grid.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card_3d.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 可见性 setState 合并（120ms flush）回归：
/// 1) 集合立即更新、卡片重建推迟到 flush 窗口末尾（窗口内仍是挂载时的旧 props）；
/// 2) 滚动后新挂载批次同样推迟，flush 到点后一次重建传播 isVisible/priority。
///
/// 注：widget 测试环境里 cacheExtent 不会额外挂载屏外卡片（默认视口只挂
/// 可见行），所以预载档 priority 3/10 无法从 widget props 观察，不在用例内断言。
void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  // 带 width/height 元数据：跳过宽高比异步探测，避免额外的父级 setState 干扰断言
  LocalImageRecord record(int i) => LocalImageRecord(
    path: 'G:/gallery/visibility-$i.png',
    size: 42,
    modifiedAt: DateTime(2026, 9, 10),
    metadata: const NaiImageMetadata(width: 1000, height: 1000),
  );

  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  group('GalleryGrid 可见性 flush', () {
    testWidgets('可见性变化在窗口内不重建，窗口末尾合并为一次重建', (tester) async {
      final images = List.generate(40, record);
      await tester.pumpWidget(wrap(GalleryGrid(images: images, columns: 4)));
      await tester.pump();

      final firstCard = find.byType(LocalImageCard3D).first;
      // flush 未到：卡片还持挂载时构建的旧 props
      expect(tester.widget<LocalImageCard3D>(firstCard).isVisible, isFalse);

      await tester.pump(galleryVisibilityFlushInterval);

      expect(tester.widget<LocalImageCard3D>(firstCard).isVisible, isTrue);
      expect(tester.widget<LocalImageCard3D>(firstCard).priority, 1);
    });

    testWidgets('滚动后新挂载卡片同样推迟到 flush 才拿到可见态', (tester) async {
      final images = List.generate(40, record);
      await tester.pumpWidget(
        wrap(SizedBox(
          height: 600,
          child: GalleryGrid(images: images, columns: 4),
        )),
      );
      await tester.pump();
      await tester.pump(galleryVisibilityFlushInterval);
      final initialPath =
          tester
              .widget<LocalImageCard3D>(find.byType(LocalImageCard3D).first)
              .record
              .path;

      // 拖 ScrollView 本体：从卡片起拖会被拖拽包装器抢走手势。
      // -800 让拖动前挂载的整批卡片（~3 行）全部滚出视口
      await tester.drag(
        find.descendant(
          of: find.byType(GalleryGrid),
          matching: find.byType(Scrollable),
        ),
        const Offset(0, -800),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // 窗口未到：新挂载卡片以 isVisible=false 构建，可见集合的更新
      // 还没通过重建传播（旧实现此时已在下一帧重建传播）
      final afterDrag = find.byType(LocalImageCard3D).first;
      final afterDragPath =
          tester.widget<LocalImageCard3D>(afterDrag).record.path;
      expect(afterDragPath, isNot(initialPath));
      expect(tester.widget<LocalImageCard3D>(afterDrag).isVisible, isFalse);

      await tester.pump(galleryVisibilityFlushInterval);

      expect(tester.widget<LocalImageCard3D>(afterDrag).isVisible, isTrue);
      expect(tester.widget<LocalImageCard3D>(afterDrag).priority, 1);
    });
  });

  group('瀑布流可见性 flush', () {
    testWidgets('滚动突发在窗口末尾合并重建，新可见卡片最终拿到正确状态', (tester) async {
      final records = List.generate(40, record);
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 800,
            height: 600,
            child: GenericGalleryContentView<LocalImageRecord>(
              useMasonryView: true,
              columnWidth: 180,
              columns: 4,
              itemWidth: 180,
              state: _MasonryGalleryState(records),
              selectionState: const _InactiveSelectionState(),
              itemBuilder: (_, __, ___, ____) => const SizedBox.shrink(),
              idExtractor: (item) => item.path,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(galleryVisibilityFlushInterval);

      final firstCard = find.byType(LocalImageCard3D).first;
      expect(tester.widget<LocalImageCard3D>(firstCard).isVisible, isTrue);
      final initialPath = tester.widget<LocalImageCard3D>(firstCard).record.path;

      // 大幅滚动：可视区整批换卡（新挂载批次以 isVisible=false 构建）
      await tester.drag(find.byType(MasonryGridView), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 16));

      final afterDrag = find.byType(LocalImageCard3D).first;
      final afterDragPath =
          tester.widget<LocalImageCard3D>(afterDrag).record.path;
      // 确认拖动确实换了可视批次，且新卡在窗口内还没拿到可见态
      expect(afterDragPath, isNot(initialPath));
      expect(tester.widget<LocalImageCard3D>(afterDrag).isVisible, isFalse);

      await tester.pump(galleryVisibilityFlushInterval);

      expect(tester.widget<LocalImageCard3D>(afterDrag).isVisible, isTrue);
      expect(tester.widget<LocalImageCard3D>(afterDrag).priority, 1);
    });
  });
}

class _MasonryGalleryState implements GalleryState<LocalImageRecord> {
  const _MasonryGalleryState(this.records);

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

class _InactiveSelectionState implements SelectionState {
  const _InactiveSelectionState();

  @override
  bool get isActive => false;

  @override
  Set<String> get selectedIds => const {};

  @override
  String? get lastSelectedId => null;
}
