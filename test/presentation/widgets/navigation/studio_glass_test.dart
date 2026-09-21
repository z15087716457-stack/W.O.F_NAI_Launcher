import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/window_material_service.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/collapsible_image_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_glass_surface.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
