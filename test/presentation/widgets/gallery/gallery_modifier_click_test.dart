import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart'
    show FilterCriteria;
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_content_view.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card_3d.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  group('GenericGalleryContentView modifier tap routing', () {
    late List<LocalImageRecord> records;

    setUp(() {
      records = [
        LocalImageRecord(
          path: r'C:\gallery\img_0.png',
          size: 100,
          modifiedAt: DateTime(2026, 1, 1),
        ),
        LocalImageRecord(
          path: r'C:\gallery\img_1.png',
          size: 100,
          modifiedAt: DateTime(2026, 1, 2),
        ),
        LocalImageRecord(
          path: r'C:\gallery\img_2.png',
          size: 100,
          modifiedAt: DateTime(2026, 1, 3),
        ),
      ];
    });

    for (final (label, masonry) in <(String, bool)>[
      ('masonry', true),
      ('fixed grid', false),
    ]) {
      testWidgets('$label: normal tap opens viewer outside selection mode', (
        tester,
      ) async {
        LocalImageRecord? tappedItem;
        LocalImageRecord? enteredItem;

        await tester.pumpWidget(
          _buildApp(
            records: records,
            masonry: masonry,
            isActive: false,
            onTap: (item, index) => tappedItem = item,
            onEnterSelection: (item) => enteredItem = item,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        await tester.tap(find.byType(LocalImageCard3D).first);
        await tester.pump(const Duration(milliseconds: 400));

        expect(tappedItem?.path, records[0].path);
        expect(enteredItem, isNull);
      });

      testWidgets(
        '$label: Ctrl+tap enters selection and selects item outside selection mode',
        (tester) async {
          LocalImageRecord? tappedItem;
          LocalImageRecord? enteredItem;

          await tester.pumpWidget(
            _buildApp(
              records: records,
              masonry: masonry,
              isActive: false,
              onTap: (item, index) => tappedItem = item,
              onEnterSelection: (item) => enteredItem = item,
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));

          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.tap(find.byType(LocalImageCard3D).first);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();

          expect(tappedItem, isNull);
          expect(enteredItem?.path, records[0].path);
        },
      );

      testWidgets(
        '$label: Shift+tap without anchor enters selection outside selection mode',
        (tester) async {
          LocalImageRecord? tappedItem;
          LocalImageRecord? enteredItem;
          LocalImageRecord? rangeItem;

          await tester.pumpWidget(
            _buildApp(
              records: records,
              masonry: masonry,
              isActive: false,
              lastSelectedId: null,
              onTap: (item, index) => tappedItem = item,
              onEnterSelection: (item) => enteredItem = item,
              onSelectRange: (item) => rangeItem = item,
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));

          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.tap(find.byType(LocalImageCard3D).first);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pump();

          expect(tappedItem, isNull);
          expect(enteredItem?.path, records[0].path);
          expect(rangeItem, isNull);
        },
      );

      testWidgets(
        '$label: Shift+tap with anchor triggers selectRange outside selection mode',
        (tester) async {
          LocalImageRecord? tappedItem;
          LocalImageRecord? rangeItem;

          await tester.pumpWidget(
            _buildApp(
              records: records,
              masonry: masonry,
              isActive: false,
              lastSelectedId: records[0].path,
              onTap: (item, index) => tappedItem = item,
              onSelectRange: (item) => rangeItem = item,
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));

          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.tap(find.byType(LocalImageCard3D).at(2));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.pump();

          expect(tappedItem, isNull);
          expect(rangeItem?.path, records[2].path);
        },
      );

      testWidgets('$label: Ctrl+tap toggles selection in selection mode', (
        tester,
      ) async {
        LocalImageRecord? toggledItem;

        await tester.pumpWidget(
          _buildApp(
            records: records,
            masonry: masonry,
            isActive: true,
            selectedIds: {records[0].path},
            onSelectionToggle: (item) => toggledItem = item,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(find.byType(LocalImageCard3D).at(1));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();

        expect(toggledItem?.path, records[1].path);
      });

      testWidgets('$label: Shift+tap triggers selectRange in selection mode', (
        tester,
      ) async {
        LocalImageRecord? rangeItem;

        await tester.pumpWidget(
          _buildApp(
            records: records,
            masonry: masonry,
            isActive: true,
            selectedIds: {records[0].path},
            lastSelectedId: records[0].path,
            onSelectRange: (item) => rangeItem = item,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.tap(find.byType(LocalImageCard3D).at(2));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();

        expect(rangeItem?.path, records[2].path);
      });
    }
  });

  group('Selection provider modifier integration', () {
    test(
      'enterAndSelect and selectRange integration with ProviderContainer',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          localGallerySelectionNotifierProvider.notifier,
        );

        // 1. Ctrl+点击逻辑验证：enterAndSelect
        notifier.enterAndSelect('p1');
        var state = container.read(localGallerySelectionNotifierProvider);
        expect(state.isActive, isTrue);
        expect(state.selectedIds, {'p1'});
        expect(state.lastSelectedId, 'p1');

        // 2. toggleSelection
        notifier.toggle('p2');
        state = container.read(localGallerySelectionNotifierProvider);
        expect(state.selectedIds, {'p1', 'p2'});
        expect(state.lastSelectedId, 'p2');

        // 3. Shift+点击逻辑验证：selectRange
        final all = ['p0', 'p1', 'p2', 'p3', 'p4'];
        notifier.selectRange('p4', all);
        state = container.read(localGallerySelectionNotifierProvider);
        expect(state.selectedIds, {'p1', 'p2', 'p3', 'p4'});
        expect(state.lastSelectedId, 'p4');
      },
    );
  });
}

Widget _buildApp({
  required List<LocalImageRecord> records,
  required bool masonry,
  required bool isActive,
  Set<String> selectedIds = const {},
  String? lastSelectedId,
  void Function(LocalImageRecord item, int index)? onTap,
  void Function(LocalImageRecord item)? onEnterSelection,
  void Function(LocalImageRecord item)? onSelectionToggle,
  void Function(LocalImageRecord item)? onSelectRange,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GenericGalleryContentView<LocalImageRecord>(
          useMasonryView: masonry,
          columns: 3,
          itemWidth: 160,
          state: _SimpleGalleryState(records),
          selectionState: _SimpleSelectionState(
            isActive: isActive,
            selectedIds: selectedIds,
            lastSelectedId: lastSelectedId,
          ),
          itemBuilder: (_, __, ___, ____) => const SizedBox.shrink(),
          idExtractor: (item) => item.path,
          onTap: onTap,
          onEnterSelection: onEnterSelection,
          onSelectionToggle: onSelectionToggle,
          onSelectRange: onSelectRange,
        ),
      ),
    ),
  );
}

class _SimpleGalleryState implements GalleryState<LocalImageRecord> {
  const _SimpleGalleryState(this.records);
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

class _SimpleSelectionState implements SelectionState {
  const _SimpleSelectionState({
    required this.isActive,
    this.selectedIds = const {},
    this.lastSelectedId,
  });

  @override
  final bool isActive;

  @override
  final Set<String> selectedIds;

  @override
  final String? lastSelectedId;
}
