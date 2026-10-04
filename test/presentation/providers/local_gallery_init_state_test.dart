import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_state_views.dart';
import 'package:nai_launcher/presentation/widgets/gallery/timeline/gallery_timeline_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_local_gallery_service.dart';

class _StateNotifier extends LocalGalleryNotifier {
  _StateNotifier(this.initial);

  final LocalGalleryState initial;

  @override
  LocalGalleryState build() => initial;
}

FakeLocalGalleryService _service() => FakeLocalGalleryService([
  for (var i = 0; i < 10; i++)
    LocalImageRecord(
      path: 'C:/gallery/$i.png',
      size: 1,
      modifiedAt: DateTime(2026, 9, 1).subtract(Duration(hours: i)),
    ),
]);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalGalleryNotifier preference restoration sequence (A-2)', () {
    test('初始化前设置排序和NAI-only只暂存状态，不触发服务层查询与加载', () async {
      final fakeService = _service();
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(fakeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(localGalleryNotifierProvider.notifier);
      final initialState = container.read(localGalleryNotifierProvider);
      expect(initialState.isInitialized, isFalse);

      // 模拟首屏 _restoreGalleryPreferences 在 initialize 前调用
      await notifier.setSort(
        GallerySortField.createdAt,
        GallerySortDirection.ascending,
      );
      await notifier.setNaiOnly(true);

      // 断言：未初始化状态下，底层服务查询与时间线读取完全未被触发
      expect(fakeService.setSortCount, equals(0));
      expect(fakeService.applyFilterCount, equals(0));
      expect(fakeService.timelineRequests, equals(0));

      // 断言：偏好值已正确暂存至 notifier state
      final stagedState = container.read(localGalleryNotifierProvider);
      expect(stagedState.sortField, equals(GallerySortField.createdAt));
      expect(stagedState.sortDirection, equals(GallerySortDirection.ascending));
      expect(stagedState.filterCriteria.naiOnly, isTrue);

      // 现在执行 initialize()（模拟 _checkPermissionsAndScan）
      await notifier.initialize();

      // 断言：initialize 内一次性应用了暂存的排序与过滤，且首屏只读一次时间线
      expect(fakeService.setSortCount, equals(1));
      expect(fakeService.applyFilterCount, equals(1));
      expect(fakeService.timelineRequests, equals(1));
      expect(container.read(localGalleryNotifierProvider).timeline.length, 10);
      expect(
        container.read(localGalleryNotifierProvider).isInitialized,
        isTrue,
      );

      // 验证后续正常操作（已初始化态）会正常触发底层更新
      await notifier.setSort(
        GallerySortField.fileSize,
        GallerySortDirection.descending,
      );
      expect(fakeService.setSortCount, equals(2));
      expect(fakeService.timelineRequests, equals(2));
    });

    test('导入后切换目录只保留 NAI-only 偏好并清除旧筛选', () async {
      final fakeService = _service();
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(fakeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setNaiOnly(true);
      await notifier.setSearchQuery('old search');
      await notifier.setShowFavoritesOnly(true);
      await notifier.setSelectedCollection('old-collection');

      final before = fakeService.applyFilterCount;
      await notifier.showImportedCategory('new-root', '/gallery/new-root');

      final criteria = container
          .read(localGalleryNotifierProvider)
          .filterCriteria;
      expect(criteria.categoryId, 'new-root');
      expect(criteria.categoryFolderPath, '/gallery/new-root');
      expect(criteria.searchQuery, isEmpty);
      expect(criteria.showFavoritesOnly, isFalse);
      expect(criteria.collectionId, isNull);
      expect(criteria.naiOnly, isTrue);
      expect(fakeService.currentFilter.categoryId, 'new-root');
      expect(fakeService.applyFilterCount, before + 1);
    });
  });

  group('GalleryTimelineView empty & loading state guards (A-1)', () {
    Future<void> pumpView(WidgetTester tester, LocalGalleryState state) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localGalleryNotifierProvider.overrideWith(
              () => _StateNotifier(state),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GalleryTimelineView(
                onOpenViewer: (_) {},
                onContextMenu: (_, __) {},
                onUseImage: (_) async {},
                onFavoriteMenu: (_, __) {},
                onClearFilters: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('未初始化时显示 Loading，不显示 EmptyView', (tester) async {
      await pumpView(tester, const LocalGalleryState());

      expect(find.byType(GalleryLoadingView), findsOneWidget);
      expect(find.byType(GalleryEmptyView), findsNothing);
    });

    testWidgets('初始化完成且确实无图时显示 EmptyView', (tester) async {
      await pumpView(tester, const LocalGalleryState(isInitialized: true));

      expect(find.byType(GalleryEmptyView), findsOneWidget);
      expect(find.byType(GalleryLoadingView), findsNothing);
    });

    testWidgets('有筛选且无结果时显示 NoResults 而非 EmptyView', (tester) async {
      await pumpView(
        tester,
        const LocalGalleryState(
          isInitialized: true,
          filterCriteria: FilterCriteria(searchQuery: 'none'),
        ),
      );

      expect(find.byType(GalleryNoResultsView), findsOneWidget);
      expect(find.byType(GalleryEmptyView), findsNothing);
    });
  });
}
