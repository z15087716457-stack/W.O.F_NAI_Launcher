import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/img2img_panel.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

import '../../../../helpers/studio_capture_fonts.dart';

class _Storage extends LocalStorageService {
  @override
  String getDefaultModel() => 'nai-diffusion-4-5-full';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = img.Image(width: 96, height: 128);
  img.fill(source, color: img.ColorRgb8(111, 137, 130));
  img.fillRect(
    source,
    x1: 8,
    y1: 16,
    x2: 87,
    y2: 111,
    color: img.ColorRgb8(204, 195, 172),
  );
  final bytes = Uint8List.fromList(img.encodePng(source));

  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 400.0]) {
        testWidgets(
          'source canvas action fits ${locale.toLanguageTag()} ${brightness.name} $width',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 700));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final container = ProviderContainer(
              overrides: [
                localStorageServiceProvider.overrideWith((ref) => _Storage()),
              ],
            );
            addTearDown(container.dispose);
            final workflow = container.read(
              imageWorkflowControllerProvider.notifier,
            );
            workflow.replaceSourceImage(bytes);
            await tester.runAsync(() async {
              await loadStudioCaptureFonts();
              await (FontLoader('MaterialIcons')..addFont(
                    rootBundle.load('fonts/MaterialIcons-Regular.otf'),
                  ))
                  .load();
            });
            final boundaryKey = GlobalKey();
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: AppTheme.getTheme(AppStyle.geist, brightness),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: const Img2ImgPanel(),
                      ),
                    ),
                  ),
                ),
              ),
            );
            for (final expanded in [false, true]) {
              workflow.setPanelExpanded(expanded);
              await tester.pumpAndSettle();
              final action = find.byKey(
                const Key('img2img-action-place-on-canvas'),
              );
              expect(action, findsOneWidget);
              expect(tester.getRect(action).right, lessThanOrEqualTo(width));
              expect(
                find.byKey(const Key('img2img-overflow-menu')),
                findsNothing,
              );
              expect(tester.takeException(), isNull);
              if (Platform.environment['IMG2IMG_CAPTURE'] == '1') {
                await tester.runAsync(() async {
                  final boundary =
                      boundaryKey.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary;
                  final rendered = await boundary.toImage(pixelRatio: 2);
                  final data = await rendered.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final folder = Directory(
                    '.dart_tool/img2img-canvas-20261005/captures',
                  )..createSync(recursive: true);
                  File(
                    '${folder.path}/${locale.toLanguageTag()}-${brightness.name}-${width.toInt()}-${expanded ? 'expanded' : 'collapsed'}.png',
                  ).writeAsBytesSync(data!.buffer.asUint8List());
                  rendered.dispose();
                });
              }
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 1));
          },
        );
      }
    }
  }
}
