import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';

/// 清除筛选相关测试：
/// 1. 清除按钮按「会话过滤条件」显隐（仅剩 naiOnly 时不显示）
/// 2. clearAllFilters 清会话过滤但不动侧栏选中范围
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('clear button visibility', () {
    // 清除按钮带 shortcutId → ShortcutTooltip 包装，find.byTooltip 不可用，
    // 用图标（Icons.filter_alt_off）定位
    final clearButton = find.byIcon(Icons.filter_alt_off);

    testWidgets('hidden when only naiOnly is active', (tester) async {
      await _pumpToolbar(
        tester,
        const FilterCriteria(naiOnly: true),
      );

      expect(clearButton, findsNothing);
    });

    testWidgets('hidden when browsing a folder without session filters',
        (tester) async {
      await _pumpToolbar(
        tester,
        const FilterCriteria(
          naiOnly: true,
          categoryId: 'cat-1',
          categoryFolderPath: r'aaa\bbb',
        ),
      );

      expect(clearButton, findsNothing);
    });

    testWidgets('hidden when browsing a collection without session filters',
        (tester) async {
      await _pumpToolbar(
        tester,
        const FilterCriteria(naiOnly: true, collectionId: 'col-1'),
      );

      expect(clearButton, findsNothing);
    });

    testWidgets('hidden when favorites scope without session filters',
        (tester) async {
      await _pumpToolbar(
        tester,
        const FilterCriteria(naiOnly: true, showFavoritesOnly: true),
      );

      expect(clearButton, findsNothing);
    });

    testWidgets('visible when any session filter is active', (tester) async {
      await _pumpToolbar(
        tester,
        const FilterCriteria(naiOnly: true, searchQuery: 'solo'),
      );

      expect(clearButton, findsOneWidget);
    });

    testWidgets('visible when collection scope plus a session filter',
        (tester) async {
      await _pumpToolbar(
        tester,
        const FilterCriteria(
          naiOnly: true,
          collectionId: 'col-1',
          selectedTags: ['solo'],
        ),
      );

      expect(clearButton, findsOneWidget);
    });
  });

  group('clearAllFilters', () {
    test(
        'clears session filters only: keeps scope (folder/collection/favorites) '
        'and naiOnly, leaves category selection', () async {
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(() => _FakeServiceNotifier()),
          localGalleryNotifierProvider.overrideWith(
            () => LocalGalleryNotifier(),
          ),
          galleryCategoryNotifierProvider.overrideWith(
            () => _RecordingCategoryNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(localGalleryNotifierProvider.notifier);
      final categoryNotifier = container
          .read(galleryCategoryNotifierProvider.notifier)
          as _RecordingCategoryNotifier;

      await notifier.initialize();
      await notifier.setNaiOnly(true);
      // 浏览范围：文件夹 + 收藏集 + 收藏（收藏集的语义是互斥选择，
      // 这里分别设置验证各自保留；组合态仅用于断言保留逻辑）
      await notifier.setSelectedCategory('cat-1', r'aaa\bbb');
      await notifier.setSelectedCollection('col-1');
      await notifier.setShowFavoritesOnly(true);
      // 会话条件
      await notifier.setSearchQuery('solo');
      await notifier.addSelectedTags(['solo', '1girl']);
      await notifier.setDateRange(
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 2),
      );
      await notifier.setFilterModels(['nai-diffusion-5']);
      await notifier.setFilterSteps(20, 30);
      await notifier.setFilterResolutions(['832x1216']);

      final before = container.read(localGalleryNotifierProvider);
      expect(before.filterCriteria.hasSessionFilters, isTrue);
      final service = container
          .read(galleryServiceProvider) as _FakeLocalGalleryService;
      service.lastAppliedCriteria = null;

      await notifier.clearAllFilters();

      final after = container.read(localGalleryNotifierProvider);
      // 会话条件清空
      expect(after.filterCriteria.searchQuery, isEmpty);
      expect(after.filterCriteria.selectedTags, isEmpty);
      expect(after.filterCriteria.dateStart, isNull);
      expect(after.filterCriteria.dateEnd, isNull);
      expect(after.filterCriteria.filterModels, isEmpty);
      expect(after.filterCriteria.filterMinSteps, isNull);
      expect(after.filterCriteria.filterMaxSteps, isNull);
      expect(after.filterCriteria.filterResolutions, isEmpty);
      expect(after.hasSessionFilters, isFalse);
      // 浏览范围保留
      expect(after.filterCriteria.categoryId, 'cat-1');
      expect(after.filterCriteria.categoryFolderPath, r'aaa\bbb');
      expect(after.filterCriteria.collectionId, 'col-1');
      expect(after.filterCriteria.showFavoritesOnly, isTrue);
      // naiOnly 常驻偏好保留
      expect(after.filterCriteria.naiOnly, isTrue);
      // 内容仍按保留后的范围过滤（applyFilter 收到的是含范围的 criteria）
      expect(service.lastAppliedCriteria?.categoryId, 'cat-1');
      expect(service.lastAppliedCriteria?.collectionId, 'col-1');
      expect(service.lastAppliedCriteria?.showFavoritesOnly, isTrue);
      expect(service.lastAppliedCriteria?.searchQuery, isEmpty);
      // 侧栏选中范围不动（selectCategory 未被调用）
      expect(categoryNotifier.selectCategoryCalls, 0);
    });
  });
}

Future<void> _pumpToolbar(
  WidgetTester tester,
  FilterCriteria criteria,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localGalleryNotifierProvider.overrideWith(
          () => _StaticGalleryNotifier(
            LocalGalleryState(
              currentImages: [_record(r'C:\gallery\page-1.png')],
              filterCriteria: criteria,
              filteredCount: 1,
              totalCount: 1,
              totalPages: 1,
              isInitialized: true,
            ),
          ),
        ),
        localGallerySelectionNotifierProvider.overrideWith(
          () => _InactiveSelectionNotifier(),
        ),
        shortcutConfigNotifierProvider.overrideWith(
          _FakeShortcutConfigNotifier.new,
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LocalGalleryToolbar(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LocalImageRecord _record(String path) {
  return LocalImageRecord(
    path: path,
    size: 1,
    modifiedAt: DateTime(2026),
  );
}

class _StaticGalleryNotifier extends LocalGalleryNotifier {
  _StaticGalleryNotifier(this._initialState);

  final LocalGalleryState _initialState;

  @override
  LocalGalleryState build() => _initialState;
}

class _InactiveSelectionNotifier extends LocalGallerySelectionNotifier {
  @override
  SelectionModeState build() => const SelectionModeState();
}

class _FakeShortcutConfigNotifier extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class _RecordingCategoryNotifier extends GalleryCategoryNotifier {
  int selectCategoryCalls = 0;

  @override
  GalleryCategoryState build() => const GalleryCategoryState();

  @override
  void selectCategory(String? categoryId) {
    selectCategoryCalls++;
  }
}

/// galleryServiceProvider 的假实现：isInitialized=true，所有操作无副作用。
class _FakeServiceNotifier extends GalleryService {
  @override
  LocalGalleryService build() => _FakeLocalGalleryService();
}

class _FakeLocalGalleryService implements LocalGalleryService {
  /// 最近一次 applyFilter 收到的条件（用于断言清除后仍按范围过滤）
  FilterCriteria? lastAppliedCriteria;

  @override
  bool get isInitialized => true;

  @override
  int get filteredCount => 0;

  @override
  int get totalCount => 0;

  @override
  FilterCriteria get currentFilter => const FilterCriteria();

  @override
  Future<List<File>> initialize() async => [];

  @override
  Future<List<LocalImageRecord>> getPage(int page, {int? pageSize}) async => [];

  @override
  Future<void> applyFilter(FilterCriteria criteria) async {
    lastAppliedCriteria = criteria;
  }

  @override
  Future<bool> toggleFavorite(String filePath) async => false;

  @override
  Future<bool> isFavorite(String filePath) async => false;

  @override
  Future<int> getFavoriteCount() async => 0;

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
  Future<void> setPageSize(int size) async {}

  @override
  Future<void> setSort(GallerySort sort) async {}

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
