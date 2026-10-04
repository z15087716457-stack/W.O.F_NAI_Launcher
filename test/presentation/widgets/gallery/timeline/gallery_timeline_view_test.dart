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
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/data/services/thumbnail_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_focus_provider.dart';
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

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    records = _records();
    service = FakeLocalGalleryService(records);
    opened.clear();
    contextMenus.clear();
    container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
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
              onOpenViewer: opened.add,
              onContextMenu: (record, _) => contextMenus.add(record.path),
              onSendAction: (_, __) async {},
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

  testWidgets('Ctrl+tap starts multi-select with the focused image', (
    tester,
  ) async {
    await pumpView(tester);

    await tester.tap(card(0));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(card(3));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(selection().isActive, isTrue);
    expect(selection().selectedIds, {records[0].path, records[3].path});

    // 多选中普通单击切换选择
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(card(0));
    await tester.pump();
    expect(selection().selectedIds, {records[3].path});

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(selection().isActive, isFalse);
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
