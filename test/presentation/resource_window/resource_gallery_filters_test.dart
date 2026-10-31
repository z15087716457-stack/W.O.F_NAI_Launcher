import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/resource_window_protocol.dart';
import 'package:nai_launcher/presentation/resource_window/resource_window_controller.dart';
import 'package:nai_launcher/presentation/resource_window/resource_window_entry.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_nai_versions.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_filter_bar.dart';

import '../../helpers/studio_capture_fonts.dart';

void main() {
  testWidgets(
    'child uses the shared filter bar below the toolbar without a ProviderScope',
    (t) async {
      await t.runAsync(loadStudioCaptureFonts);
      final requests = <Map<String, Object?>>[];
      final controller = ResourceWindowController(
        windowId: 'filters',
        kind: FloatingResourceKind.gallery,
        invoke: (method, args) async {
          if (method != 'resources.query') return null;
          requests.add(args);
          return {
            'requestId': args['requestId'],
            'revision': 1,
            'items': [],
            'timeline': [],
            'total': 0,
            'hasMore': false,
            'layout': 'grid',
            'cellSize': 132.0,
            'groupMode': 'day',
            'sortId': 'modifiedAt',
            'chips': [
              {'id': 'nai', 'label': '仅 NAI 图片'},
              {'id': 'favorite', 'label': '收藏'},
            ],
            'sections': [
              {
                'title': '资料库',
                'groups': [
                  {'id': 'all', 'label': '全部图片'},
                ],
              },
            ],
          };
        },
      );
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        ResourceWindowController.native,
        (_) async => null,
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          ResourceWindowController.native,
          null,
        ),
      );
      await controller.initialize();
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1100, 760);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(
        ResourceWindowApp(
          controller: controller,
          locale: const Locale('zh'),
          arguments: const ResourceWindowArguments(
            kind: FloatingResourceKind.gallery,
          ),
        ),
      );
      await t.pump();
      final bar = find.byKey(const Key('rw-gallery-filters'));
      expect(find.byType(GalleryFilterBar), findsOneWidget);
      expect(find.byKey(const Key('rw-chip-nai')), findsNothing);
      expect(find.byKey(const Key('gallery-filter-nai')), findsOneWidget);
      expect(
        t.getRect(bar).top,
        greaterThan(t.getRect(find.byKey(const Key('rw-search'))).bottom),
      );
      expect(t.getRect(bar).height, localGalleryFilterBarHeight);
      await t.tap(find.byKey(const Key('gallery-version-4.5')));
      await t.pump();
      expect(requests.last['models'], GalleryNaiVersions.modelIds['4.5']);
      expect(requests.last['chips'], contains('nai'));
      final afterModel = requests.length;
      controller.galleryFilters(models: GalleryNaiVersions.modelIds['4.5']);
      await t.pump();
      expect(requests.length, afterModel);
      final start = DateTime(2026, 10, 1), end = DateTime(2026, 10, 30);
      controller.galleryFilters(start: start, end: end, dates: true);
      await t.pump();
      expect(requests.last['dateStart'], start.millisecondsSinceEpoch);
      expect(requests.last['dateEnd'], end.millisecondsSinceEpoch);
      controller.group('trash');
      await t.pump();
      expect(find.byKey(const Key('rw-gallery-filters')), findsNothing);
      controller.group('all');
      await t.pump();
      expect(requests.last['models'], GalleryNaiVersions.modelIds['4.5']);
      expect(requests.last['dateStart'], start.millisecondsSinceEpoch);
      await t.tap(find.byKey(const Key('gallery-filter-nai')));
      await t.pump();
      expect(requests.last['models'], isEmpty);
      expect(requests.last['chips'], isNot(contains('nai')));
      await t.tap(find.byKey(const Key('gallery-filter-clear')));
      await t.pump();
      expect(requests.last['dateStart'], isNull);
      expect(requests.last['dateEnd'], isNull);
      for (final width in [560.0, 780.0]) {
        t.view.physicalSize = Size(width, 760);
        await t.pump();
        expect(find.byKey(const Key('gallery-filter-date')), findsOneWidget);
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
    },
  );
}
