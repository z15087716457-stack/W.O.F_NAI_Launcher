import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_group_mode.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_nai_versions.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_filter_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_local_gallery_service.dart';

/// 记录筛选调用的轻量 Notifier：只改 state，不访问服务。
class _RecordingNotifier extends LocalGalleryNotifier {
  _RecordingNotifier(this.initial);

  final LocalGalleryState initial;
  final List<List<String>> modelCalls = [];
  final List<bool> naiOnlyCalls = [];
  int clearCalls = 0;

  LocalGalleryState get current => state;

  @override
  LocalGalleryState build() => initial;

  @override
  Future<void> setFilterModels(List<String> models) async {
    modelCalls.add(models);
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(filterModels: models),
    );
  }

  @override
  Future<void> setNaiOnly(bool value) async {
    naiOnlyCalls.add(value);
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(naiOnly: value),
    );
  }

  @override
  Future<void> clearAllFilters() async {
    clearCalls++;
  }
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<_RecordingNotifier> pumpBar(
    WidgetTester tester, {
    FilterCriteria criteria = const FilterCriteria(),
    GallerySortField sortField = GallerySortField.modifiedAt,
  }) async {
    // 换掉旧 ProviderScope：同位置复用的 scope 不会应用新的 overrides
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = const Size(1200, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final notifier = _RecordingNotifier(
      LocalGalleryState(
        isInitialized: true,
        filterCriteria: criteria,
        sortField: sortField,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localGalleryNotifierProvider.overrideWith(() => notifier)],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: LocalGalleryFilterBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return notifier;
  }

  group('clear filters button', () {
    Finder clear() => find.byKey(const Key('gallery-filter-clear'));

    testWidgets('hidden when only naiOnly or browsing scope is active', (
      tester,
    ) async {
      await pumpBar(tester, criteria: const FilterCriteria(naiOnly: true));
      expect(clear(), findsNothing);

      await pumpBar(
        tester,
        criteria: const FilterCriteria(
          naiOnly: true,
          categoryId: 'cat-1',
          collectionId: 'col-1',
          showFavoritesOnly: true,
        ),
      );
      expect(clear(), findsNothing);
    });

    testWidgets('visible with a session filter and clears on tap', (
      tester,
    ) async {
      final notifier = await pumpBar(
        tester,
        criteria: const FilterCriteria(
          collectionId: 'col-1',
          selectedTags: ['solo'],
        ),
      );
      expect(clear(), findsOneWidget);
      expect(find.text('solo'), findsOneWidget);

      await tester.tap(clear());
      expect(notifier.clearCalls, 1);
    });
  });

  group('model version segment', () {
    testWidgets('tapping a version selects all its variants and enables NAI', (
      tester,
    ) async {
      final notifier = await pumpBar(tester);

      await tester.tap(find.byKey(const ValueKey('gallery-version-4.5')));
      await tester.pumpAndSettle();

      expect(notifier.modelCalls.single, GalleryNaiVersions.modelIds['4.5']);
      expect(notifier.naiOnlyCalls, [true]);
      expect(notifier.current.filterCriteria.naiOnly, isTrue);
    });

    testWidgets('variant menu writes Full or Curated subsets', (tester) async {
      final notifier = await pumpBar(
        tester,
        criteria: FilterCriteria(
          naiOnly: true,
          filterModels: GalleryNaiVersions.modelIds['4.5']!,
        ),
      );
      expect(find.text('V4.5'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('gallery-version-variant-4.5')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full').last);
      await tester.pumpAndSettle();
      expect(notifier.modelCalls.last, GalleryNaiVersions.fullIds['4.5']);
      expect(find.text('V4.5 F'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('gallery-version-variant-4.5')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Curated').last);
      await tester.pumpAndSettle();
      expect(notifier.modelCalls.last, GalleryNaiVersions.curatedIds['4.5']);
      expect(find.text('V4.5 C'), findsOneWidget);
    });

    testWidgets('tapping the active version again clears the model filter', (
      tester,
    ) async {
      final notifier = await pumpBar(
        tester,
        criteria: FilterCriteria(
          naiOnly: true,
          filterModels: GalleryNaiVersions.modelIds['5']!,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('gallery-version-5')));
      await tester.pumpAndSettle();
      expect(notifier.modelCalls.single, isEmpty);
    });

    testWidgets('V3 has no Full/Curated submenu', (tester) async {
      await pumpBar(
        tester,
        criteria: FilterCriteria(
          naiOnly: true,
          filterModels: GalleryNaiVersions.modelIds['3']!,
        ),
      );
      expect(
        find.byKey(const ValueKey('gallery-version-variant-3')),
        findsNothing,
      );
    });
  });

  testWidgets('turning NAI-only off also drops the model filter', (
    tester,
  ) async {
    final notifier = await pumpBar(
      tester,
      criteria: FilterCriteria(
        naiOnly: true,
        filterModels: GalleryNaiVersions.modelIds['4']!,
      ),
    );
    await tester.tap(find.byKey(const Key('gallery-filter-nai')));
    await tester.pumpAndSettle();
    expect(notifier.naiOnlyCalls, [false]);
    expect(notifier.modelCalls.single, isEmpty);
  });

  testWidgets('group mode menu only appears for time sorting', (tester) async {
    await pumpBar(tester);
    expect(find.byKey(const Key('gallery-filter-group-mode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('gallery-filter-group-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按月分组').last);
    await tester.pumpAndSettle();
    expect(await const GalleryGroupModeStore().load(), GalleryGroupMode.month);

    await pumpBar(tester, sortField: GallerySortField.fileName);
    expect(find.byKey(const Key('gallery-filter-group-mode')), findsNothing);
  });

  test(
    'clearAllFilters keeps scope and naiOnly, clears session filters',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeLocalGalleryService([
        LocalImageRecord(path: 'a.png', size: 1, modifiedAt: DateTime(2026)),
      ]);
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(service),
          ),
          galleryCategoryNotifierProvider.overrideWith(
            _RecordingCategoryNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      final categoryNotifier =
          container.read(galleryCategoryNotifierProvider.notifier)
              as _RecordingCategoryNotifier;

      await notifier.initialize();
      await notifier.setNaiOnly(true);
      await notifier.setSelectedCategory('cat-1', r'aaa\bbb');
      await notifier.setSelectedCollection('col-1');
      await notifier.setShowFavoritesOnly(true);
      await notifier.setSearchQuery('solo');
      await notifier.addSelectedTags(['solo', '1girl']);
      await notifier.setDateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 2));
      await notifier.setFilterModels(['nai-diffusion-5']);
      expect(
        container.read(localGalleryNotifierProvider).hasSessionFilters,
        isTrue,
      );

      await notifier.clearAllFilters();

      final after = container.read(localGalleryNotifierProvider).filterCriteria;
      expect(after.searchQuery, isEmpty);
      expect(after.selectedTags, isEmpty);
      expect(after.dateStart, isNull);
      expect(after.dateEnd, isNull);
      expect(after.filterModels, isEmpty);
      expect(after.categoryId, 'cat-1');
      expect(after.categoryFolderPath, r'aaa\bbb');
      expect(after.collectionId, 'col-1');
      expect(after.showFavoritesOnly, isTrue);
      expect(after.naiOnly, isTrue);
      expect(service.currentFilter.categoryId, 'cat-1');
      expect(service.currentFilter.searchQuery, isEmpty);
      expect(categoryNotifier.selectCategoryCalls, 0);
    },
  );
}
