import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/services/window_material_service.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/collapsible_image_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/decoded_memory_image.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_glass_surface.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import '../../../helpers/official_ui_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOfficialUiCaptureFonts);
  const channel = MethodChannel('com.nailauncher/window_material');
  final requests = <Map<dynamic, dynamic>>[];
  setUp(() {
    WindowMaterialService.available.value = false;
    requests.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = call.arguments as Map;
          requests.add(args);
          return args['enabled'];
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    WindowMaterialService.available.value = false;
  });

  Widget shell(Brightness brightness, {bool highContrast = false}) =>
      MaterialApp(
        theme: brightness == Brightness.dark
            ? GeistTheme.dark
            : GeistTheme.light,
        themeAnimationDuration: Duration.zero,
        home: MediaQuery(
          data: MediaQueryData(highContrast: highContrast),
          child: const IntegratedTitleBarShell(child: Scaffold()),
        ),
      );

  testWidgets(
    'title glass follows app appearance and high contrast; body stays opaque',
    (tester) async {
      await tester.pumpWidget(shell(Brightness.dark));
      await tester.pumpAndSettle();
      expect(requests.last, {'dark': true, 'enabled': true});
      expect(
        tester
            .widget<StudioGlassSurface>(find.byType(StudioGlassSurface))
            .nativeBackdrop,
        isTrue,
      );
      expect(
        Theme.of(
          tester.element(find.byType(Scaffold)),
        ).scaffoldBackgroundColor.a,
        1,
      );
      await tester.pumpWidget(shell(Brightness.light));
      await tester.pumpAndSettle();
      expect(requests.last, {'dark': false, 'enabled': true});
      await tester.pumpWidget(shell(Brightness.light, highContrast: true));
      await tester.pumpAndSettle();
      expect(requests.last, {'dark': false, 'enabled': false});
      expect(
        tester
            .widget<StudioGlassSurface>(find.byType(StudioGlassSurface))
            .nativeBackdrop,
        isFalse,
      );
      expect(find.text('NAI Studio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('native title glass is a flat page tint flush with content in '
        '${brightness.name}', (tester) async {
      await tester.pumpWidget(shell(brightness));
      await tester.pumpAndSettle();
      final glass = find.byType(StudioGlassSurface);
      final tint = tester.widget<ColoredBox>(
        find.descendant(of: glass, matching: find.byType(ColoredBox)).first,
      );
      final theme = brightness == Brightness.dark
          ? GeistTheme.dark
          : GeistTheme.light;
      expect(
        tint.color,
        theme.colorScheme.surface.withValues(
          alpha: brightness == Brightness.dark ? .80 : .78,
        ),
      );
      expect(
        tester.getTopLeft(find.byType(Scaffold)).dy,
        IntegratedTitleBarShell.barHeight,
      );
    });
  }

  testWidgets('unsupported native material keeps an opaque title surface', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'unsupported'),
        );
    await tester.pumpWidget(shell(Brightness.dark));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StudioGlassSurface>(find.byType(StudioGlassSurface))
          .nativeBackdrop,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'image glass keeps foreground clear and expands in ${brightness.name}',
      (tester) async {
        final source = img.Image(width: 600, height: 900);
        for (var y = 0; y < 900; y += 30) {
          for (var x = 0; x < 600; x += 30) {
            img.fillRect(
              source,
              x1: x,
              y1: y,
              x2: x + 29,
              y2: y + 29,
              color: img.ColorRgb8(50 + x ~/ 4, 70 + y ~/ 6, 150),
            );
          }
        }
        final bytes = Uint8List.fromList(img.encodePng(source));
        final boundary = GlobalKey();
        var expanded = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.dark
                ? GeistTheme.dark
                : GeistTheme.light,
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: boundary,
                  child: SizedBox(
                    width: 400,
                    child: StatefulBuilder(
                      builder: (context, setState) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CollapsibleImagePanel(
                            frosted: true,
                            title: '精准参考',
                            subtitle: '将生成绑定到角色或风格参考',
                            icon: Icons.person_pin,
                            hasData: true,
                            backgroundImage: DecodedMemoryImage(
                              bytes: bytes,
                              decodeForCover: true,
                            ),
                            isExpanded: expanded,
                            onToggle: () =>
                                setState(() => expanded = !expanded),
                            child: const SizedBox(
                              height: 100,
                              child: Text('参考参数'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CollapsibleImagePanel(
                            frosted: true,
                            title: '图生图',
                            subtitle: '基于底图生成变体',
                            icon: Icons.image,
                            isExpanded: false,
                            onToggle: () {},
                            child: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ImageFiltered), findsOneWidget);
        final imageFinder = find.byType(Image);
        await tester.runAsync(
          () => precacheImage(
            tester.widget<Image>(imageFinder).image,
            tester.element(imageFinder),
          ),
        );
        await tester.pump();
        expect(
          find.ancestor(
            of: find.text('精准参考'),
            matching: find.byType(ImageFiltered),
          ),
          findsNothing,
        );
        if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              '.dart_tool/glass-rollout-captures/cards-${brightness.name}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.text('精准参考'));
        await tester.pumpAndSettle();
        expect(expanded, isTrue);
        expect(find.byType(ImageFiltered), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'glass card preserves import and expand actions in ${brightness.name}',
      (tester) async {
        var expanded = false;
        var imported = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.dark
                ? GeistTheme.dark
                : GeistTheme.light,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 360,
                    child: CollapsibleImagePanel(
                      frosted: true,
                      title: '图生图',
                      subtitle: '基于底图生成变体',
                      icon: Icons.image,
                      isExpanded: expanded,
                      onToggle: () => setState(() => expanded = !expanded),
                      headerActions: [
                        TextButton(
                          onPressed: () => imported++,
                          child: const Text('上传图片'),
                        ),
                      ],
                      child: const SizedBox(height: 100, child: Text('参数')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('上传图片'));
        await tester.pumpAndSettle();
        expect(imported, 1);
        expect(expanded, isFalse);
        await tester.tap(find.text('图生图'));
        await tester.pumpAndSettle();
        expect(expanded, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
