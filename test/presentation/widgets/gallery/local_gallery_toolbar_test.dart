import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 顶栏：范围面包屑与数量、搜索标签、排序菜单、视图切换、多选与详情开关。
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('breadcrumb shows the folder path and the result count', (
    tester,
  ) async {
    await _pumpToolbar(
      tester,
      state: const LocalGalleryState(
        isInitialized: true,
        totalCount: 48809,
        filteredCount: 19832,
        filterCriteria: FilterCriteria(categoryId: 'normal'),
      ),
    );

    expect(find.text('01_图库'), findsOneWidget);
    expect(find.text('NAI 4.5'), findsOneWidget);
    expect(find.text('正常向'), findsOneWidget);
    expect(find.text('19,832 张'), findsOneWidget);
    expect(find.text('搜索：正常向'), findsOneWidget);
  });

  testWidgets('sort menu switches field and direction and persists it', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester);

    await tester.tap(find.byKey(const Key('gallery-toolbar-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('文件名').last);
    await tester.pumpAndSettle();
    expect(notifier.sortCalls.last, (
      GallerySortField.fileName,
      GallerySort.defaultDirectionFor(GallerySortField.fileName),
    ));

    await tester.tap(find.byKey(const Key('gallery-toolbar-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('降序').last);
    await tester.pumpAndSettle();
    expect(notifier.sortCalls.last, (
      GallerySortField.fileName,
      GallerySortDirection.descending,
    ));
    expect(
      (await const GallerySortStore().load())?.direction,
      GallerySortDirection.descending,
    );
  });

  testWidgets('view segment switches the layout mode', (tester) async {
    final notifier = await _pumpToolbar(tester);
    await tester.tap(find.byKey(const ValueKey('gallery-view-masonry')));
    await tester.pump();
    expect(notifier.current.viewMode, GalleryViewMode.masonry);
  });

  testWidgets('multi-select toggles selection mode; inspector toggle obeys '
      'availability', (tester) async {
    var inspectorToggles = 0;
    await _pumpToolbar(
      tester,
      inspectorAvailable: false,
      onToggleInspector: () => inspectorToggles++,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LocalGalleryToolbar)),
    );

    await tester.tap(find.byKey(const Key('gallery-toolbar-multiselect')));
    await tester.pump();
    expect(
      container.read(localGallerySelectionNotifierProvider).isActive,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('gallery-toolbar-multiselect')));
    await tester.pump();
    expect(
      container.read(localGallerySelectionNotifierProvider).isActive,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('gallery-toolbar-inspector')));
    await tester.pump();
    expect(inspectorToggles, 0, reason: '窗口过窄时详情面板不可展开');
  });

  for (final width in [1500.0, 860.0]) {
    testWidgets('fits in one row without overflow at width $width', (
      tester,
    ) async {
      await _pumpToolbar(tester, width: width);
      expect(tester.takeException(), isNull);
      final toolbar = tester.getRect(find.byType(LocalGalleryToolbar));
      final more = tester.getRect(
        find.byKey(const Key('gallery-toolbar-more')),
      );
      expect(more.right, lessThanOrEqualTo(toolbar.right));
      expect(tester.getSize(find.byType(TextField)).width, greaterThan(140));
    });
  }

  testWidgets('Ctrl+click selects a local tag as a gallery filter chip', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester, autocomplete: true);
    final field = find.byType(TextField).first;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(field);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'blue',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(notifier.current.filterCriteria.selectedTags, ['blue_hair']);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
  });
}

Future<_FakeGalleryNotifier> _pumpToolbar(
  WidgetTester tester, {
  LocalGalleryState state = const LocalGalleryState(
    isInitialized: true,
    totalCount: 3,
  ),
  double width = 1400,
  bool inspectorAvailable = true,
  VoidCallback? onToggleInspector,
  bool autocomplete = false,
}) async {
  tester.view.physicalSize = Size(width, 400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);

  final notifier = _FakeGalleryNotifier(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localGalleryNotifierProvider.overrideWith(() => notifier),
        galleryCategoryNotifierProvider.overrideWith(_FakeCategoryNotifier.new),
        shortcutConfigNotifierProvider.overrideWith(
          _FakeShortcutConfigNotifier.new,
        ),
        localTagExpansionServiceProvider.overrideWithValue(
          LocalTagExpansionService(
            catalog: const _BlueHairSource(),
            relatedTags: const _EmptySource(),
            substringSearch: (input, {limit = 20}) async => const [],
            popularSearch: ({limit = 12}) async => const [],
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: LocalGalleryToolbar(
              searchFocusNode: focusNode,
              inspectorVisible: true,
              inspectorAvailable: inspectorAvailable,
              onToggleInspector: onToggleInspector ?? () {},
              onOpenFolder: () {},
              onRefresh: () {},
              showCategoryPanel: true,
              onToggleCategoryPanel: () {},
              enableSearchAutocomplete: autocomplete,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

class _FakeGalleryNotifier extends LocalGalleryNotifier {
  _FakeGalleryNotifier(this._initialState);

  final LocalGalleryState _initialState;
  final List<(GallerySortField, GallerySortDirection)> sortCalls = [];

  LocalGalleryState get current => state;

  @override
  LocalGalleryState build() => _initialState;

  @override
  Future<void> setSort(
    GallerySortField field,
    GallerySortDirection direction,
  ) async {
    sortCalls.add((field, direction));
    state = state.copyWith(sortField: field, sortDirection: direction);
  }

  @override
  Future<void> addSelectedTags(
    List<String> tags, {
    bool clearSearchQuery = false,
  }) async {
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(
        selectedTags: [...state.filterCriteria.selectedTags, ...tags],
        searchQuery: clearSearchQuery ? '' : state.filterCriteria.searchQuery,
      ),
    );
  }
}

class _FakeCategoryNotifier extends GalleryCategoryNotifier {
  @override
  GalleryCategoryState build() {
    final now = DateTime(2026);
    GalleryCategory category(String id, String name, String? parent) =>
        GalleryCategory(
          id: id,
          name: name,
          folderPath: name,
          parentId: parent,
          createdAt: now,
          updatedAt: now,
        );
    return GalleryCategoryState(
      categories: [
        category('root', '01_图库', null),
        category('v45', 'NAI 4.5', 'root'),
        category('normal', '正常向', 'v45'),
      ],
    );
  }
}

class _BlueHairSource implements CompletionSource {
  const _BlueHairSource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => [
    const CompletionCandidate(
      canonicalTag: 'blue_hair',
      category: TagCategory.general,
      postCount: 100,
      matchKind: CompletionMatchKind.englishPrefix,
      sources: {CompletionSourceKind.base},
    ),
  ];
}

class _EmptySource implements CompletionSource {
  const _EmptySource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      const [];
}

class _FakeShortcutConfigNotifier extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}
