import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart'
    show FilterCriteria;
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_content_view.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  for (final (label, grouped, masonry) in <(String, bool, bool)>[
    ('grouped', true, false),
    ('masonry', false, true),
    ('fixed grid', false, false),
  ]) {
    testWidgets('$label gallery enables external drag outside selection mode', (
      tester,
    ) async {
      await _pumpGallery(
        tester,
        grouped: grouped,
        masonry: masonry,
        selectionMode: false,
      );

      expect(find.byType(DragItemWidget), findsOneWidget);
    });

    testWidgets('$label gallery disables external drag in selection mode', (
      tester,
    ) async {
      await _pumpGallery(
        tester,
        grouped: grouped,
        masonry: masonry,
        selectionMode: true,
      );

      expect(find.byType(DragItemWidget), findsNothing);
    });
  }
}

Future<void> _pumpGallery(
  WidgetTester tester, {
  required bool grouped,
  required bool masonry,
  required bool selectionMode,
}) async {
  final record = LocalImageRecord(
    path: r'G:\gallery\drag-test.png',
    size: 42,
    modifiedAt: DateTime(2026, 7, 11),
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GenericGalleryContentView<LocalImageRecord>(
            useMasonryView: masonry,
            columns: 1,
            itemWidth: 160,
            state: _TestGalleryState(record, grouped: grouped),
            selectionState: _TestSelectionState(selectionMode),
            itemBuilder: (_, __, ___, ____) => const SizedBox.shrink(),
            idExtractor: (item) => item.path,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _TestGalleryState implements GalleryState<LocalImageRecord> {
  const _TestGalleryState(this.record, {required this.grouped});

  final LocalImageRecord record;
  final bool grouped;

  @override
  List<LocalImageRecord> get currentImages => [record];

  @override
  List<LocalImageRecord> get groupedImages => [record];

  @override
  bool get isGroupedView => grouped;

  @override
  bool get isPageLoading => false;

  @override
  bool get isGroupedLoading => false;

  @override
  int get currentPage => 0;

  @override
  bool get hasFilters => false;

  @override
  List<LocalImageRecord> get filteredFiles => [record];

  @override
  FilterCriteria get filterCriteria => const FilterCriteria();

  @override
  GallerySortField get sortField => GallerySortField.modifiedAt;

  @override
  GallerySortDirection get sortDirection => GallerySortDirection.descending;
}

class _TestSelectionState implements SelectionState {
  const _TestSelectionState(this.isActive);

  @override
  final bool isActive;

  @override
  Set<String> get selectedIds => const {};
}
