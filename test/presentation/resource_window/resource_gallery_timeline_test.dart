import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/resource_window/resource_gallery_timeline.dart';
import 'package:nai_launcher/presentation/resource_window/resource_window_controller.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_cards.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_contract.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_page.dart';
import 'package:nai_launcher/presentation/widgets/gallery/timeline/gallery_timeline_header.dart';
import 'package:nai_launcher/presentation/widgets/gallery/timeline/gallery_timeline_scrubber.dart';

import '../../helpers/studio_capture_fonts.dart';

class TimelineController extends ResourceWindowController {
  TimelineController(ResourceHostCall invoke)
    : super(
        windowId: 'timeline',
        kind: FloatingResourceKind.gallery,
        invoke: invoke,
      );
  @override
  Widget dragWrap(ResourceItem item, Widget child) => child;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  final image = Uint8List.fromList(
    img.encodePng(img.Image(width: 2, height: 2)),
  );
  late TimelineController controller;
  final calls = <Map<String, Object?>>[];
  var revision = 1;
  DateTime date(int i) =>
      DateTime(2026, 10, 27, 12).subtract(Duration(days: i ~/ 30));
  setUp(() async {
    calls.clear();
    revision = 1;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ResourceWindowController.native,
          (_) async => null,
        );
    controller = TimelineController((method, args) async {
      calls.add({'method': method, ...args});
      if (method == 'resources.query') {
        return {
          'requestId': args['requestId'],
          'revision': revision,
          'total': 12000,
          'hasMore': false,
          'timeline': [
            for (var i = 0; i < 12000; i++)
              [
                'C:/timeline/$i.png',
                date(i).millisecondsSinceEpoch,
                100,
                150,
                200,
              ],
          ],
          'items': [],
          'layout': 'justified',
          'cellSize': 132.0,
          'sortId': 'modifiedAt',
          'groupMode': 'day',
        };
      }
      if (method == 'resources.thumbnail') return image;
      if (method == 'gallery.records') {
        return [
          for (final path in args['ids'] as List)
            {
              'id': path,
              'title': 'Image',
              'positive': 'source',
              'date': date(
                int.parse((path as String).split('/').last.split('.').first),
              ).millisecondsSinceEpoch,
              'thumbVersion':
                  '200:${date(int.parse(path.split('/').last.split('.').first)).millisecondsSinceEpoch}',
            },
        ];
      }
      return null;
    });
    await controller.initialize();
  });
  tearDown(() {
    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ResourceWindowController.native, null);
  });
  Future<void> pump(WidgetTester t, {bool dark = false}) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1040, 680);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      MaterialApp(
        theme: dark ? GeistTheme.dark : GeistTheme.light,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListenableBuilder(
          listenable: controller,
          builder: (_, _) => ResourceWindowPage(
            data: controller.data,
            actions: controller.actions,
            galleryBuilder: (scroll, cell) => ResourceGalleryTimeline(
              controller: controller,
              scroll: scroll,
              cell: cell,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      '12000 images use shared timeline rail/headers and bounded visible records, dark=$dark',
      (t) async {
        await pump(t, dark: dark);
        expect(controller.galleryTimeline, hasLength(12000));
        expect(find.byType(GalleryTimelineScrubber), findsOneWidget);
        expect(find.byType(GalleryTimelineGroupHeader), findsWidgets);
        expect(
          find.byType(ResourceGalleryCard).evaluate().length,
          lessThan(200),
        );
        final initial = calls
            .where((c) => c['method'] == 'gallery.records')
            .length;
        expect(initial, inInclusiveRange(1, 3));
        final rail = find.byKey(const Key('gallery-timeline-scrubber'));
        final year = find.descendant(of: rail, matching: find.text('2025'));
        expect(year, findsOneWidget);
        await t.tap(year);
        await t.pumpAndSettle();
        final scroll = t
            .widget<SingleChildScrollView>(
              find.byKey(const Key('rw-gallery-timeline-scroll')),
            )
            .controller!;
        expect(scroll.offset, greaterThan(0));
        expect(
          find.byType(ResourceGalleryCard).evaluate().length,
          lessThan(200),
        );
        expect(
          calls.where((c) => c['method'] == 'resources.query'),
          hasLength(1),
        );
        expect(
          calls
              .where((c) => c['method'] == 'gallery.records')
              .every((c) => (c['ids'] as List).length <= 60),
          true,
        );
        final before = scroll.offset;
        revision++;
        controller.changed({'kind': 'gallery', 'revision': revision});
        await t.pumpAndSettle();
        expect(scroll.offset, closeTo(before, .1));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
