import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_fixture.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../../helpers/studio_capture_fonts.dart';

Widget _page(String name, {ValueChanged<String>? onAction}) => switch (name) {
  'gen-positioning' => GenerationPage(
    data: GenFixture.characters().copyWith(
      canvas: const GenCanvasData(positioning: true),
    ),
    actions: GenActions.logging(onAction ?? (_) {}),
    slots: const GenSlots(editor: GenFixtureEditor.builder),
  ),
  'gen-empty' || 'gen-images' || 'gen-collapsed' => GenerationPage(
    data: name == 'gen-empty'
        ? GenFixture.empty()
        : GenFixture.view(
            layout: GenLayout(historyOpen: name != 'gen-collapsed'),
          ),
    actions: GenActions.logging(onAction ?? (_) {}),
    slots: const GenSlots(editor: GenFixtureEditor.builder),
  ),
  'explore' || 'explore-empty' => StyleExplorePage(
    data: name == 'explore' ? ExploreFixture.view() : ExploreFixture.empty(),
    actions: ExploreActions.none,
    // The production editor is covered by generation tests; the static preview
    // editor has its own minimum width and is not the installed editor.
    editor: (_, _) => const SizedBox.shrink(),
  ),
  'viewer-panel' || 'viewer-stage' => ImageViewerPage(
    data: ViewerFixture.gallery(infoOpen: name == 'viewer-panel'),
    actions: ViewerActions.none,
  ),
  'editor' => ToolsEditorPage(
    data: ToolsFixture.editor(),
    actions: ToolsEditorActions.logging((_) {}),
  ),
  'director' => ToolsDirectorPage(
    data: ToolsFixture.director(),
    actions: ToolsDirectorActions.logging((_) {}),
  ),
  _ => StatisticsPage(data: StatsFixture.view(), actions: StatsActions.none),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  var maximized = false;
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    calls.clear();
    maximized = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.nailauncher/titlebar'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'isMaximized') return maximized;
      if (call.method == 'isFullScreen') return false;
      if (call.method == 'maximize') maximized = true;
      if (call.method == 'unmaximize') maximized = false;
      return null;
    });
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.nailauncher/titlebar'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      null,
    );
  });

  Future<void> drag(WidgetTester tester, Offset point) async {
    calls.clear();
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.down(point);
    await mouse.moveBy(const Offset(40, 0));
    await mouse.up();
    await tester.pump();
    expect(
      calls.where((c) => c == 'startDragging'),
      hasLength(1),
      reason: '$point',
    );
  }

  for (final name in [
    'gen-empty',
    'gen-images',
    'gen-collapsed',
    'gen-positioning',
    'explore',
    'explore-empty',
    'viewer-panel',
    'viewer-stage',
    'editor',
    'director',
    'statistics',
  ]) {
    for (final width in [name == 'explore' ? 1000.0 : 800.0, 1600.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          '$name top moves the window and captions blend $width $dark',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 1000);
            addTearDown(tester.view.reset);
            final boundary = GlobalKey();
            final actions = <String>[];
            final gen = name.startsWith('gen-');
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: dark ? GeistTheme.dark : GeistTheme.light,
                locale: const Locale('zh'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: RepaintBoundary(
                  key: boundary,
                  child: IntegratedTitleBarShell(
                    deferToRoute: true,
                    captionHeight: gen
                        ? 36
                        : name == 'statistics'
                        ? 36
                        : 61,
                    child: WindowChromePage(
                      captionTheme: name == 'viewer-stage'
                          ? GeistTheme.dark
                          : null,
                      child: Scaffold(body: _page(name, onAction: actions.add)),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.runAsync(() async {
              final context = tester.element(find.byType(Scaffold));
              final providers = tester
                  .widgetList<Image>(find.byType(Image))
                  .map((image) => image.image)
                  .toSet();
              for (final provider in providers) {
                await precacheImage(provider, context);
              }
            });
            await tester.pumpAndSettle();

            if (gen) {
              final canvas = tester.getRect(
                find.byKey(const Key('gen-canvas')),
              );
              if (name == 'gen-positioning') {
                await drag(tester, canvas.topLeft + const Offset(6, 6));
                calls.clear();
                await tester.tap(find.byKey(const Key('gen-position-done')));
                await tester.pump();
                expect(calls, isNot(contains('startDragging')));
              } else {
                await drag(tester, canvas.topLeft + const Offset(12, 6));
                // The strip remains callable above the floating canvas toolbar.
                await drag(tester, Offset(canvas.center.dx, canvas.top + 4));
                final topBar = find.byKey(const Key('gen-bar-top'));
                if (topBar.evaluate().isEmpty ||
                    tester.getSize(topBar).width < canvas.width - 40) {
                  // Blank space beside the toolbar belongs to the window,
                  // through the lower edge of the enlarged drag strip.
                  for (final x in [canvas.left + 12, canvas.right - 12]) {
                    for (final y in [32.0, 42.0]) {
                      final point = Offset(x, canvas.top + y);
                      final captions = tester.getRect(
                        find.byKey(const Key('window-caption-controls')),
                      );
                      if (!captions.contains(point)) {
                        await drag(tester, point);
                      }
                    }
                  }
                }
                calls.clear();
                await tester.dragFrom(
                  canvas.topLeft + const Offset(12, 52),
                  const Offset(40, 0),
                  kind: ui.PointerDeviceKind.mouse,
                );
                await tester.pumpAndSettle();
                expect(calls, isNot(contains('startDragging')));
                if (topBar.evaluate().isNotEmpty) {
                  calls.clear();
                  await tester.tap(find.byKey(const Key('gen-enhance')));
                  await tester.pumpAndSettle();
                  expect(actions.any((a) => a.startsWith('onEnhance')), isTrue);
                  expect(calls, isNot(contains('startDragging')));
                  if (tester.getSize(topBar).width > canvas.width) {
                    final scrollable = Scrollable.of(tester.element(topBar));
                    final before = scrollable.position.pixels;
                    calls.clear();
                    await tester.dragFrom(
                      Offset(canvas.center.dx, canvas.top + 28),
                      const Offset(-60, 0),
                      kind: ui.PointerDeviceKind.mouse,
                    );
                    await tester.pumpAndSettle();
                    expect(scrollable.position.pixels, greaterThan(before));
                    expect(calls, isNot(contains('startDragging')));
                  }
                }
              }
              final header = tester.getRect(
                find.byKey(const Key('gen-header')),
              );
              await drag(tester, header.topLeft + const Offset(3, 3));
              final history = find.byKey(const Key('gen-history-window-inset'));
              if (history.evaluate().isNotEmpty) {
                await drag(
                  tester,
                  tester.getTopLeft(history) + const Offset(12, 6),
                );
              }
              calls.clear();
              await tester.tap(find.byKey(const Key('gen-model')));
              await tester.pumpAndSettle();
              expect(calls, isNot(contains('startDragging')));
              // Close the model popup without changing a setting.
              await tester.tapAt(Offset(canvas.center.dx, 200));
              await tester.pumpAndSettle();
            } else {
              final header = find.byType(WindowHeader).first;
              await drag(
                tester,
                tester.getTopLeft(header) + const Offset(10, 5),
              );
            }

            final captions = tester.getRect(
              find.byKey(const Key('window-caption-controls')),
            );
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final data = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              int pixel(int x, int y) =>
                  data.getUint32((y * image.width + x) * 4);
              expect(
                pixel(captions.left.floor() + 6, 6),
                pixel(captions.left.floor() - 2, 6),
                reason:
                    'window buttons inherit the actual adjoining panel surface',
              );
              if (Platform.environment['CAPTURE_WINDOW_HEADERS'] == '1') {
                final png = (await image.toByteData(
                  format: ui.ImageByteFormat.png,
                ))!;
                final file = File(
                  '.dart_tool/window-headers-20261014/captures/$name-${width.toInt()}-${dark ? 'dark' : 'light'}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(png.buffer.asUint8List());
              }
              image.dispose();
            });
            calls.clear();
            await tester.tap(find.byIcon(Icons.remove));
            await tester.pump();
            expect(calls, contains('minimize'));
            expect(calls, isNot(contains('startDragging')));
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
          variant: TargetPlatformVariant.only(TargetPlatform.windows),
        );
      }
    }
  }

  testWidgets('captions follow a split header surface', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 500);
    addTearDown(tester.view.reset);
    for (final dark in [false, true]) {
      final theme = dark ? GeistTheme.dark : GeistTheme.light;
      final panel = theme.colorScheme.surfaceContainerLow;
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: RepaintBoundary(
            key: boundary,
            child: IntegratedTitleBarShell(
              child: ColoredBox(color: panel, child: const SizedBox.expand()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        int pixel(int x, int y) => data.getUint32((y * image.width + x) * 4);
        expect(pixel(770, 2), pixel(880, 2));
        expect(pixel(855, 2), pixel(880, 2));
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
