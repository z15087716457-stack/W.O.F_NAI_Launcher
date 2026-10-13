import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_artifact.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory workspace;
  setUpAll(loadStudioCaptureFonts);
  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('nai-agent-artifact-ui-');
    final image = img.Image(width: 240, height: 160);
    for (final pixel in image) {
      pixel.setRgb(25 + pixel.x ~/ 2, 90 + pixel.y ~/ 2, 190);
    }
    await File(
      '${workspace.path}/image.png',
    ).writeAsBytes(img.encodePng(image));
  });
  tearDown(() async => workspace.delete(recursive: true));
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('zh'),
    Brightness brightness = Brightness.light,
    double width = 440,
  }) async {
    tester.view.physicalSize = Size(width, 380);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.getTheme(AppStyle.geist, brightness),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage(
          (element.widget as Image).image,
          element,
          onError: (error, stack) {},
        );
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'local image opens detail viewer and closes without model vision',
    (tester) async {
      await pump(
        tester,
        NaiAgentImageArtifact(workspace: workspace, path: 'image.png'),
      );
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'missing or invalid artifact shows a bounded broken-image placeholder',
    (tester) async {
      File('${workspace.path}/invalid.png').writeAsStringSync('invalid image');
      await pump(
        tester,
        Wrap(
          children: [
            NaiAgentImageArtifact(workspace: workspace, path: 'missing.png'),
            NaiAgentImageArtifact(workspace: workspace, path: 'invalid.png'),
          ],
        ),
      );
      expect(find.byIcon(Icons.broken_image_outlined), findsNWidgets(2));
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('decoder-corrupt image is handled in thumbnail and viewer', (
    tester,
  ) async {
    final png = File('${workspace.path}/image.png').readAsBytesSync();
    File('${workspace.path}/corrupt.png').writeAsBytesSync(png.sublist(0, 33));
    await pump(
      tester,
      NaiAgentImageArtifact(workspace: workspace, path: 'corrupt.png'),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('actual workspace link escape refuses rendering external image', (
    tester,
  ) async {
    final outside = Directory.systemTemp.createTempSync(
      'nai-agent-artifact-outside-',
    );
    final link = Directory(p.join(workspace.path, 'linked'));
    try {
      File(
        '${outside.path}/image.png',
      ).writeAsBytesSync(File('${workspace.path}/image.png').readAsBytesSync());
      if (Platform.isWindows) {
        final result = await tester.runAsync(
          () => Process.run('cmd.exe', [
            '/c',
            'mklink',
            '/J',
            link.path,
            outside.path,
          ]),
        );
        expect(result!.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      } else {
        Link(link.path).createSync(outside.path);
      }
      await pump(
        tester,
        NaiAgentImageArtifact(workspace: workspace, path: 'linked/image.png'),
      );
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(File('${outside.path}/image.png').existsSync(), true);
      await tester.pumpWidget(const SizedBox());
    } finally {
      outside.deleteSync(recursive: true);
    }
  });
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'real-font $locale ${brightness.name} local artifacts fit narrow chat',
        (tester) async {
          final key = GlobalKey();
          const longName = 'seedvr2-7b-sharp-int8-original-image-upscaled.png';
          File('${workspace.path}/$longName').writeAsBytesSync(
            File('${workspace.path}/image.png').readAsBytesSync(),
          );
          for (final width in [320.0, 440.0]) {
            await pump(
              tester,
              RepaintBoundary(
                key: key,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      NaiAgentImageArtifact(
                        workspace: workspace,
                        path: 'image.png',
                      ),
                      NaiAgentImageArtifact(
                        workspace: workspace,
                        path: longName,
                      ),
                    ],
                  ),
                ),
              ),
              locale: Locale(locale),
              brightness: brightness,
              width: width,
            );
            expect(find.byType(Image), findsNWidgets(2));
            expect(tester.takeException(), isNull);
            if (Platform.environment['CAPTURE_NAI_AGENT'] == '1' &&
                locale == 'zh') {
              await tester.runAsync(() async {
                final image =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final captures = Directory(
                  '.dart_tool/nai-agent-stage-e5a/native-captures',
                )..createSync(recursive: true);
                File(
                  '${captures.path}/artifacts-${brightness.name}-${width.toInt()}.png',
                ).writeAsBytesSync(data!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
