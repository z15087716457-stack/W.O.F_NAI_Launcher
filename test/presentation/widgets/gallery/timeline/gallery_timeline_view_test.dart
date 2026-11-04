// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/data/services/thumbnail_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_focus_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_recent_views_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_trash_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card.dart';
import 'package:nai_launcher/presentation/widgets/gallery/timeline/gallery_timeline_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fake_local_gallery_service.dart';

class _TestKritaBridgeNotifier extends KritaBridgeNotifier {
  @override
  Future<void> close() async {}
}

/// 每天 8 张，共 5 天；竖横交替。
List<LocalImageRecord> _records() {
  final start = DateTime(2026, 9, 20, 20);
  return [
    for (var i = 0; i < 40; i++)
      LocalImageRecord(
        path: 'C:/gallery/missing/img_$i.png',
        size: 1000 + i,
        modifiedAt: start.subtract(Duration(days: i ~/ 8, minutes: i)),
        metadata: NaiImageMetadata(
          prompt: 'prompt $i',
          width: i.isEven ? 832 : 1216,
          height: i.isEven ? 1216 : 832,
        ),
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(ThumbnailService.instance.cancelAll);

  late List<LocalImageRecord> records;
  late FakeLocalGalleryService service;
  late ProviderContainer container;
  final opened = <int>[];
  final contextMenus = <String>[];
  final deleteRequests = <List<String>>[];

  Future<void> pumpView(
    WidgetTester tester, {
    List<LocalImageRecord>? images,
  }) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    records = images ?? _records();
    service = FakeLocalGalleryService(records);
    opened.clear();
    contextMenus.clear();
    deleteRequests.clear();
    container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
        ),
        galleryTrashTimelineProvider.overrideWith(
          (ref) async => [
            for (final r in records)
              GalleryTimelineEntry(
                path: r.path,
                modifiedAt: r.modifiedAt,
                width: r.metadata?.width,
                height: r.metadata?.height,
              ),
          ],
        ),
        kritaBridgeNotifierProvider.overrideWith(
          (ref) => _TestKritaBridgeNotifier(),
        ),
      ],
    );
    await container.read(localGalleryNotifierProvider.notifier).initialize();
    container.read(localGalleryNotifierProvider.notifier).setColumnWidth(160);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GalleryTimelineView(
              onDeleteRequested: () => deleteRequests.add(
                container
                    .read(localGallerySelectionNotifierProvider)
                    .selectedIds
                    .toList(),
              ),
              onOpenViewer: opened.add,
              onContextMenu: (record, _) => contextMenus.add(record.path),
              onUseImage: (_) async {},
              onFavoriteMenu: (_, __) {},
              onClearFilters: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  }

  Finder card(int index) => find.byWidgetPredicate(
    (widget) =>
        widget is LocalImageCard && widget.record.path == records[index].path,
  );

  String? focused() => container.read(localGalleryFocusNotifierProvider);
  SelectionModeState selection() =>
      container.read(localGallerySelectionNotifierProvider);

  Future<void> ctrlTap(WidgetTester tester, int index) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(card(index));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('builds only cards near the viewport with day headers', (
    tester,
  ) async {
    await pumpView(tester);

    final built = tester.widgetList(find.byType(LocalImageCard)).length;
    expect(built, greaterThan(4));
    expect(built, lessThan(records.length));
    expect(find.text('9月20日'), findsOneWidget);
    expect(find.text('周日 · 8 张'), findsOneWidget);

    // 可见区域的完整记录按需加载，远处条目不读
    final requested = service.recordRequests.expand((paths) => paths).toSet();
    expect(requested, contains(records.first.path));
    expect(requested, isNot(contains(records.last.path)));
    await dispose(tester);
  });

  testWidgets('tap focuses, double tap and Space open the viewer', (
    tester,
  ) async {
    await pumpView(tester);

    await tester.tap(card(1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(focused(), records[1].path);
    expect(selection().isActive, isFalse);
    expect(opened, isEmpty);

    await tester.tap(card(1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(opened, [1]);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focused(), records[2].path);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(opened, [1, 2]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(focused(), isNull);
    await dispose(tester);
  });

  for (final mode in GalleryViewMode.values) {
    testWidgets(
      'Ctrl+tap starts multi-select with only the clicked image (${mode.name})',
      (tester) async {
        await pumpView(tester);
        container.read(localGalleryNotifierProvider.notifier).setViewMode(mode);
        await tester.pump();

        await tester.tap(card(0));
        await tester.pump();
        expect(focused(), records[0].path);
        expect(selection().isActive, isFalse);
        expect(selection().selectedIds, isEmpty);

        await ctrlTap(tester, 3);
        expect(selection().isActive, isTrue);
        expect(selection().selectedIds, {records[3].path});
        expect(focused(), records[3].path);
        final recentlyViewed = await container
            .read(galleryRecentViewsStoreProvider)
            .load();
        expect(recentlyViewed.map((e) => e.path), [records[0].path]);
        expect(tester.widget<LocalImageCard>(card(0)).isSelected, isFalse);
        expect(tester.widget<LocalImageCard>(card(0)).isFocused, isFalse);
        expect(tester.widget<LocalImageCard>(card(3)).isSelected, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.delete);
        expect(deleteRequests.single, [records[3].path]);
        final candidates = await service.getRecordsByPaths(
          deleteRequests.single,
        );
        expect(candidates.map((record) => record.path), [records[3].path]);

        // 已有多选中的 Ctrl 和普通点击继续累加／取消。
        await ctrlTap(tester, 0);
        expect(selection().selectedIds, {records[0].path, records[3].path});
        await ctrlTap(tester, 0);
        expect(selection().selectedIds, {records[3].path});
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(card(0));
        await tester.pump();
        expect(selection().selectedIds, {records[0].path, records[3].path});
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(card(0));
        await tester.pump();
        expect(selection().selectedIds, {records[3].path});

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(selection().isActive, isFalse);
        expect(selection().selectedIds, isEmpty);
        expect(focused(), records[0].path);
        await ctrlTap(tester, 2);
        expect(selection().selectedIds, {records[2].path});
        await dispose(tester);
      },
    );
  }

  testWidgets('Ctrl+tap without a preview selects only the clicked image', (
    tester,
  ) async {
    await pumpView(tester);
    await ctrlTap(tester, 3);
    expect(selection().selectedIds, {records[3].path});
    await dispose(tester);
  });

  testWidgets('Ctrl+tap on the preview selects that image once', (
    tester,
  ) async {
    await pumpView(tester);
    await tester.tap(card(0));
    await ctrlTap(tester, 0);
    expect(selection().selectedIds, {records[0].path});
    await dispose(tester);
  });

  testWidgets('selection circle does not import the preview into selection', (
    tester,
  ) async {
    await pumpView(tester);
    await tester.tap(card(0));
    await tester.pump();
    tester.widget<LocalImageCard>(card(3)).onSelectionToggle!();
    await tester.pump();
    expect(selection().selectedIds, {records[3].path});
    await dispose(tester);
  });

  testWidgets('Shift range after Ctrl starts from the clicked image', (
    tester,
  ) async {
    await pumpView(tester);
    await tester.tap(card(0));
    await ctrlTap(tester, 2);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(card(4));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(selection().selectedIds, {
      for (var i = 2; i <= 4; i++) records[i].path,
    });
    await dispose(tester);
  });

  testWidgets('Shift+tap selects the range from the focused image', (
    tester,
  ) async {
    await pumpView(tester);

    await tester.tap(card(1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(card(4));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(selection().selectedIds, {
      for (var i = 1; i <= 4; i++) records[i].path,
    });
    await dispose(tester);
  });

  testWidgets('section circle selects a whole day; right click forwards', (
    tester,
  ) async {
    await pumpView(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('9月20日')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('gallery-group-select')).first);
    await tester.pump();
    expect(selection().selectedIds, {
      for (var i = 0; i < 8; i++) records[i].path,
    });

    await tester.tap(card(2), buttons: kSecondaryButton);
    await tester.pump();
    expect(contextMenus, [records[2].path]);
    await dispose(tester);
  });

  for (final category in ['favorites', 'folder', 'collection']) {
    testWidgets('$category and all images remember separate scroll positions', (
      tester,
    ) async {
      await pumpView(
        tester,
        images: _records().map((r) => r.copyWith(isFavorite: true)).toList(),
      );
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      final controller = tester
          .widget<SingleChildScrollView>(
            find.byKey(const Key('gallery-timeline-scroll')),
          )
          .controller!;
      Future<void> select(bool selected) async {
        await notifier.setBrowseScope(
          GalleryBrowseScope.library,
          filterCriteria: FilterCriteria(
            showFavoritesOnly: category == 'favorites' && selected,
            categoryId: category == 'folder' && selected ? 'folder' : null,
            categoryFolderPath: category == 'folder' && selected
                ? 'C:/gallery'
                : null,
            collectionId: category == 'collection' && selected
                ? 'collection'
                : null,
          ),
        );
        await tester.pump();
        await tester.pump();
      }

      controller.jumpTo(600);
      await tester.pump();
      final requests = service.timelineRequests;
      await select(true);
      expect(service.timelineRequests, requests + 1);
      expect(controller.offset, 0, reason: '首次进入分类从顶部开始');
      controller.jumpTo(900);
      await tester.pump();
      await select(false);
      expect(controller.offset, closeTo(600, .01));
      await select(true);
      expect(controller.offset, closeTo(900, .01));
      await dispose(tester);
    });
  }

  for (final scope in [GalleryBrowseScope.recent, GalleryBrowseScope.trash]) {
    testWidgets('$scope and all images retain independent browse positions', (
      tester,
    ) async {
      await pumpView(tester);
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      if (scope == GalleryBrowseScope.recent) {
        for (final record in records.reversed) {
          await notifier.recordViewed(record.path);
        }
      }
      final controller = tester
          .widget<SingleChildScrollView>(
            find.byKey(const Key('gallery-timeline-scroll')),
          )
          .controller!;
      controller.jumpTo(600);
      await tester.pump();
      await notifier.setBrowseScope(scope);
      await tester.pump();
      await tester.pump();
      expect(controller.offset, 0);
      final scoped = tester
          .widget<SingleChildScrollView>(
            find.byKey(const Key('gallery-timeline-scroll')),
          )
          .controller!;
      scoped.jumpTo(300);
      await tester.pump();
      await notifier.setBrowseScope(GalleryBrowseScope.library);
      await tester.pump();
      await tester.pump();
      expect(controller.offset, closeTo(600, .01));
      await notifier.setBrowseScope(scope);
      await tester.pump();
      await tester.pump();
      expect(scoped.offset, closeTo(300, .01));
      await dispose(tester);
    });
  }

  testWidgets(
    'returning restores the same image after earlier images are removed',
    (tester) async {
      await pumpView(
        tester,
        images: _records().map((r) => r.copyWith(isFavorite: true)).toList(),
      );
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      final controller = tester
          .widget<SingleChildScrollView>(
            find.byKey(const Key('gallery-timeline-scroll')),
          )
          .controller!;
      controller.jumpTo(600);
      await tester.pump();
      final visible = find
          .byType(LocalImageCard)
          .evaluate()
          .firstWhere(
            (e) => tester
                .getRect(find.byWidget(e.widget))
                .overlaps(const Rect.fromLTWH(0, 44, 1000, 656)),
          );
      final path = (visible.widget as LocalImageCard).record.path;
      Finder anchor() => find.byWidgetPredicate(
        (w) => w is LocalImageCard && w.record.path == path,
      );
      final top = tester.getTopLeft(anchor()).dy;
      await notifier.setShowFavoritesOnly(true);
      await tester.pump();
      await tester.pump();
      await notifier.removeDeletedImagesFromMemory(
        records.take(8).map((r) => r.path).toList(),
      );
      await tester.pump();
      await notifier.setShowFavoritesOnly(false);
      await tester.pump();
      await tester.pump();
      expect(controller.offset, lessThan(600));
      expect(tester.getTopLeft(anchor()).dy, closeTo(top, .01));
      await dispose(tester);
    },
  );

  for (final change in ['search', 'sort']) {
    testWidgets(
      '$change changes invalidate positions saved in other categories',
      (tester) async {
        await pumpView(
          tester,
          images: _records().map((r) => r.copyWith(isFavorite: true)).toList(),
        );
        final notifier = container.read(localGalleryNotifierProvider.notifier);
        final controller = tester
            .widget<SingleChildScrollView>(
              find.byKey(const Key('gallery-timeline-scroll')),
            )
            .controller!;
        controller.jumpTo(600);
        await tester.pump();
        await notifier.setShowFavoritesOnly(true);
        await tester.pump();
        await tester.pump();
        controller.jumpTo(300);
        await tester.pump();
        if (change == 'search') {
          await notifier.setSearchQuery('img_');
        } else {
          await notifier.setSort(
            GallerySortField.fileName,
            GallerySortDirection.ascending,
          );
        }
        await tester.pump();
        await tester.pump();
        expect(controller.offset, 0);
        await notifier.setShowFavoritesOnly(false);
        await tester.pump();
        await tester.pump();
        expect(controller.offset, 0, reason: '查询已变化时不恢复旧结果的位置');
        await dispose(tester);
      },
    );
  }

  testWidgets('filter change scrolls back to top; deletion keeps position', (
    tester,
  ) async {
    await pumpView(tester);
    final scrollable = find.byKey(const Key('gallery-timeline-scroll'));
    final controller = tester
        .widget<SingleChildScrollView>(scrollable)
        .controller!;

    controller.jumpTo(600);
    await tester.pump();
    await container
        .read(localGalleryNotifierProvider.notifier)
        .removeDeletedImagesFromMemory([records[0].path]);
    await tester.pump();
    await tester.pump();
    expect(controller.offset, 600);

    await container
        .read(localGalleryNotifierProvider.notifier)
        .setSearchQuery('img_1');
    await tester.pump();
    await tester.pump();
    expect(controller.offset, 0);
    expect(
      container.read(localGalleryNotifierProvider).filterCriteria,
      const FilterCriteria(searchQuery: 'img_1'),
    );
    await dispose(tester);
  });
}
