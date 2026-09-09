import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_state_views.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGalleryServiceNotifier extends GalleryService {
  _FakeGalleryServiceNotifier(this.service);

  final LocalGalleryService service;

  @override
  LocalGalleryService build() => service;
}

class _TrackingLocalGalleryService implements LocalGalleryService {
  _TrackingLocalGalleryService();

  final int initialTotal = 10;
  FilterCriteria filter = const FilterCriteria();
  GallerySort currentSort = const GallerySort.modifiedAtDesc();
  int pageSize = 50;

  int applyFilterCount = 0;
  int setSortCount = 0;
  int getPageCount = 0;

  @override
  bool get isInitialized => true;

  @override
  int get filteredCount => filter.hasFilters ? 2 : initialTotal;

  @override
  int get totalCount => initialTotal;

  @override
  FilterCriteria get currentFilter => filter;

  @override
  Future<List<File>> initialize() async => [];

  @override
  Future<List<LocalImageRecord>> getPage(int page, {int? pageSize}) async {
    getPageCount++;
    return [];
  }

  @override
  Future<void> applyFilter(FilterCriteria criteria) async {
    applyFilterCount++;
    filter = criteria;
  }

  @override
  Future<void> setSort(GallerySort sort) async {
    setSortCount++;
    currentSort = sort;
  }

  @override
  Future<bool> toggleFavorite(String filePath) async => false;

  @override
  Future<bool> isFavorite(String filePath) async => false;

  @override
  Future<int> getFavoriteCount() async => 0;

  @override
  Future<int> unfavoriteImages(List<String> filePaths) async => 0;

  @override
  Future<NaiImageMetadata?> getMetadata(String filePath) async => null;

  @override
  Future<void> refresh({bool scan = true}) async {}

  @override
  Future<bool> addNewImageImmediately(
    String filePath, {
    NaiImageMetadata? metadata,
  }) async => false;

  @override
  Future<void> setSearchQuery(String query) async {}

  @override
  Future<void> setDateRange(DateTime? start, DateTime? end) async {}

  @override
  Future<void> setShowFavoritesOnly(bool value) async {}

  @override
  Future<void> setPageSize(int size) async {
    pageSize = size;
  }

  @override
  Future<void> clearFilters() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<LocalImageRecord>> getRecordsByPaths(List<String> paths) async =>
      [];

  @override
  void removeImagesFromMemory(List<String> paths) {}

  @override
  Future<List<String>> getFilteredImagePaths() async => [];
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalGalleryNotifier preference restoration sequence (A-2)', () {
    test('初始化前设置排序和NAI-only只暂存状态，不触发服务层查询与加载', () async {
      final fakeService = _TrackingLocalGalleryService();
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => _FakeGalleryServiceNotifier(fakeService),
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

      // 断言：未初始化状态下，底层服务查询与 getPage 完全未被触发
      expect(fakeService.setSortCount, equals(0));
      expect(fakeService.applyFilterCount, equals(0));
      expect(fakeService.getPageCount, equals(0));

      // 断言：偏好值已正确暂存至 notifier state
      final stagedState = container.read(localGalleryNotifierProvider);
      expect(stagedState.sortField, equals(GallerySortField.createdAt));
      expect(stagedState.sortDirection, equals(GallerySortDirection.ascending));
      expect(stagedState.filterCriteria.naiOnly, isTrue);

      // 现在执行 initialize()（模拟 _checkPermissionsAndScan）
      await notifier.initialize();

      // 断言：initialize 内一次性应用了暂存的排序与过滤，且首屏只跑了一次 getPage(0)
      expect(fakeService.setSortCount, equals(1));
      expect(fakeService.applyFilterCount, equals(1));
      expect(fakeService.getPageCount, equals(1));
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
      expect(fakeService.getPageCount, equals(2));
    });
  });

  group('LocalGalleryScreen empty & loading state guards (A-1)', () {
    Widget buildTestBody(LocalGalleryState state) {
      // 提取自 local_gallery_screen.dart:755-770 的 _buildBody 逻辑进行严格测试
      if (state.error != null) {
        return Builder(
          builder: (context) => GalleryErrorView(
            error: state.error!.localized(AppLocalizations.of(context)!),
            onRetry: () {},
          ),
        );
      }

      if ((!state.isInitialized || state.isLoading) && state.allFiles.isEmpty) {
        return const GalleryLoadingView();
      }

      if (state.allFiles.isEmpty) {
        return const GalleryEmptyView();
      }

      return const Text('Content');
    }

    testWidgets('未初始化且无图片时显示 Loading，不显示 EmptyView', (tester) async {
      const state = LocalGalleryState(
        isInitialized: false,
        isLoading: false,
        currentImages: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: buildTestBody(state)),
        ),
      );

      expect(find.byType(GalleryLoadingView), findsOneWidget);
      expect(find.byType(GalleryEmptyView), findsNothing);
    });

    testWidgets('初始化完成且确实无图时显示 EmptyView', (tester) async {
      const state = LocalGalleryState(
        isInitialized: true,
        isLoading: false,
        currentImages: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: buildTestBody(state)),
        ),
      );

      expect(find.byType(GalleryEmptyView), findsOneWidget);
      expect(find.byType(GalleryLoadingView), findsNothing);
    });

    testWidgets('出现错误时无论是否初始化均显示 ErrorView，不被 Loading 遮盖', (tester) async {
      const state = LocalGalleryState(
        isInitialized: false,
        isLoading: false,
        error: LocalGalleryError(LocalGalleryErrorCode.permissionDenied),
        currentImages: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: buildTestBody(state)),
        ),
      );

      expect(find.byType(GalleryErrorView), findsOneWidget);
      expect(find.byType(GalleryLoadingView), findsNothing);
      expect(find.byType(GalleryEmptyView), findsNothing);
    });
  });
}
