import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/models/director/director_tool_type.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/director_tools_notifier.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/director_tools/director_tools_screen.dart';
import '../../../helpers/official_ui_capture_fonts.dart';

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 1000),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOfficialUiCaptureFonts);
  for (final size in [
    const Size(1440, 900),
    const Size(900, 620),
    const Size(640, 640),
    const Size(380, 820),
  ]) {
    testWidgets(
      'director workspace fits $size with localized tools and options',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final container = ProviderContainer(
          overrides: [
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            generationParamsNotifierProvider.overrideWith(_Params.new),
            subscriptionNotifierProvider.overrideWith(_Subscription.new),
          ],
        );
        addTearDown(container.dispose);
        final input = img.Image(width: 192, height: 288);
        for (var y = 0; y < input.height; y++) {
          for (var x = 0; x < input.width; x++) {
            input.setPixelRgb(
              x,
              y,
              (x * 255 / input.width).round(),
              70,
              (y * 255 / input.height).round(),
            );
          }
        }
        final boundary = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: officialUiCaptureTheme(),
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RepaintBoundary(
                key: boundary,
                child: DirectorToolsScreen(
                  sourceImage: Uint8List.fromList(img.encodePng(input)),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final controller = container.read(
          directorToolsNotifierProvider.notifier,
        );
        for (final tool in [
          DirectorToolType.colorize,
          DirectorToolType.fixEmotion,
          DirectorToolType.pixelSnap,
        ]) {
          controller.selectTool(tool);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$tool at $size');
        }
        if (Platform.environment['CAPTURE_OFFICIAL_UI'] == '1' &&
            size.width == 1440) {
          await tester.runAsync(
            () => precacheImage(
              MemoryImage(Uint8List.fromList(img.encodePng(input))),
              boundary.currentContext!,
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('.dart_tool/official-ui-captures/director.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
