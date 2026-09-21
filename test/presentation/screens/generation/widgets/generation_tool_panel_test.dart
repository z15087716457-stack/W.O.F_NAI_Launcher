import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_tool_panel.dart';
import '../../../../helpers/official_ui_capture_fonts.dart';

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();
}

class _Storage extends LocalStorageService {
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

void main() {
  setUpAll(loadOfficialUiCaptureFonts);
  for (final size in [const Size(920, 640), const Size(320, 480)]) {
    testWidgets(
      'enhance floating controls fit $size and close restores the draft',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(_Storage()),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            generationParamsNotifierProvider.overrideWith(_Params.new),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final boundary = GlobalKey();
        controller.openTemporaryTool(
          Uint8List.fromList(
            img.encodePng(img.Image(width: 832, height: 1216)),
          ),
          ImageWorkflowMode.enhance,
        );
        expect(
          container.read(generationParamsNotifierProvider).sourceImage,
          isNull,
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: officialUiCaptureTheme(),
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: RepaintBoundary(
                  key: boundary,
                  child: const GenerationToolPanel(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('1.5x'), findsOneWidget);
        if (Platform.environment['CAPTURE_OFFICIAL_UI'] == '1') {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              '.dart_tool/official-ui-captures/enhance-${size.width}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.text('显示高级设置'));
        await tester.pumpAndSettle();
        expect(find.byType(Slider), findsNWidgets(2));
        expect(
          container.read(generationParamsNotifierProvider).sourceImage,
          isNull,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('关闭'));
        await tester.pumpAndSettle();
        expect(
          container.read(generationParamsNotifierProvider).sourceImage,
          isNull,
        );
        expect(find.byType(Slider), findsNothing);
      },
    );
  }
}
