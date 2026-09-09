import 'package:flutter/foundation.dart';
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

    testWidgets(
      '$label gallery enables drag in selection mode for selected cards with paths',
      (tester) async {
        final record = await _pumpGallery(
          tester,
          grouped: grouped,
          masonry: masonry,
          selectionMode: true,
          selectedPaths: {r'G:\gallery\drag-test.png'},
        );

        expect(find.byType(DragItemWidget), findsOneWidget);

        final dragWidget = tester.widget<DragItemWidget>(
          find.byType(DragItemWidget),
        );
        final session = _FakeDragSession();
        addTearDown(session.dispose);

        final dragItem = await dragWidget.dragItemProvider(
          DragItemRequest(location: Offset.zero, session: session),
        );
        final localData = dragItem?.localData as Map?;
        expect(localData?['source'], 'gallery_internal');
        expect(localData?['path'], record.path);
        expect(localData?['paths'], [record.path]);
      },
    );

    testWidgets(
      '$label gallery retains single drag in selection mode for unselected cards',
      (tester) async {
        final record = await _pumpGallery(
          tester,
          grouped: grouped,
          masonry: masonry,
          selectionMode: true,
          selectedPaths: {},
        );

        expect(find.byType(DragItemWidget), findsOneWidget);

        final dragWidget = tester.widget<DragItemWidget>(
          find.byType(DragItemWidget),
        );
        final session = _FakeDragSession();
        addTearDown(session.dispose);

        final dragItem = await dragWidget.dragItemProvider(
          DragItemRequest(location: Offset.zero, session: session),
        );
        final localData = dragItem?.localData as Map?;
        expect(localData?['source'], 'gallery_internal');
        expect(localData?['path'], record.path);
        expect(localData?['paths'], isNull);
      },
    );
  }
}

Future<LocalImageRecord> _pumpGallery(
  WidgetTester tester, {
  required bool grouped,
  required bool masonry,
  required bool selectionMode,
  Set<String> selectedPaths = const {},
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
            selectionState: _TestSelectionState(
              selectionMode,
              selectedIds: selectedPaths,
            ),
            itemBuilder: (_, __, ___, ____) => const SizedBox.shrink(),
            idExtractor: (item) => item.path,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return record;
}

final class _FakeDragSession extends DragSession {
  final _dragging = ValueNotifier(false);
  final _completed = ValueNotifier<DropOperation?>(null);
  final _location = ValueNotifier<Offset?>(null);

  @override
  ValueListenable<bool> get dragging => _dragging;

  @override
  ValueListenable<DropOperation?> get dragCompleted => _completed;

  @override
  ValueListenable<Offset?> get lastScreenLocation => _location;

  @override
  Future<List<Object?>?> getLocalData() async => null;

  void dispose() {
    _dragging.dispose();
    _completed.dispose();
    _location.dispose();
  }
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
  const _TestSelectionState(this.isActive, {this.selectedIds = const {}});

  @override
  final bool isActive;

  @override
  final Set<String> selectedIds;

  @override
  String? get lastSelectedId => null;
}
