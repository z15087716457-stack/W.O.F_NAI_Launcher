import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/director/director_tool_type.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/director_tools_notifier.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/director_tools/director_tools_screen.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Api extends Mock implements NAIImageEnhancementApiService {}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(prompt: 'draft must stay intact');
}

class _Subscription extends SubscriptionNotifier {
  @override
  void schedulePostBillingRefresh({Duration delay = Duration.zero}) {}

  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 1000),
    ),
  );
}

class _Director extends DirectorToolsNotifier {
  void running() => state = state.copyWith(isRunning: true);
  void failed() =>
      state = state.copyWith(isRunning: false, error: 'Test processing error');
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));
void _checkAlignment(WidgetTester tester, {bool result = true}) {
  final source = _rect(tester, 'director-source-frame');
  final output = _rect(tester, 'director-result-frame');
  expect(source.size, output.size);
  final sf = _rect(tester, 'director-source-footer');
  final rf = _rect(tester, 'director-result-footer');
  expect(sf.height, 50);
  expect(rf.height, sf.height);
  expect(
    _rect(tester, 'director-source-preview').size,
    _rect(tester, 'director-result-preview').size,
  );
  if (source.left != output.left) {
    expect(sf.top, rf.top);
    expect(source.top, output.top);
  }
  if (result) {
    final si = _rect(tester, 'director-source-image');
    final ri = _rect(tester, 'director-result-image');
    expect(si.width, closeTo(ri.width, .000001));
    expect(si.height, closeTo(ri.height, .000001));
    if (source.left != output.left) expect(si.center.dy, ri.center.dy);
  }
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
  await tester.runAsync(() async {
    for (final widget in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(widget.image, boundary.currentContext!);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '.dart_tool/director-official-20261005/captures/$name.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List source;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await loadStudioCaptureFonts();
    registerFallbackValue(Uint8List(0));
    final captureSource = Platform.environment['CAPTURE_DIRECTOR_IMAGE'];
    source = captureSource != null
        ? await File(captureSource).readAsBytes()
        : Uint8List.fromList(
            img.encodePng(
              img.Image(width: 832, height: 1216)
                ..clear(img.ColorRgb8(80, 145, 190)),
            ),
          );
  });
  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final size in [
        const Size(1672, 1340),
        const Size(1180, 760),
        const Size(640, 640),
        const Size(380, 820),
      ]) {
        testWidgets('director alignment $locale $brightness $size', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final api = _Api();
          when(
            () => api.augmentImages(
              any(),
              reqType: 'bg-removal',
              prompt: null,
              defry: 0,
            ),
          ).thenAnswer((_) async => [source, source, source]);
          final container = ProviderContainer(
            overrides: [
              naiImageEnhancementApiServiceProvider.overrideWithValue(api),
              directorToolsNotifierProvider.overrideWith(_Director.new),
              imageGenerationNotifierProvider.overrideWith(_Generation.new),
              generationParamsNotifierProvider.overrideWith(_Params.new),
              subscriptionNotifierProvider.overrideWith(_Subscription.new),
            ],
          );
          addTearDown(container.dispose);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: RepaintBoundary(
                  key: boundary,
                  child: DirectorToolsScreen(sourceImage: source),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final controller =
              container.read(directorToolsNotifierProvider.notifier)
                  as _Director;
          final l10n = AppLocalizations.of(boundary.currentContext!)!;
          _checkAlignment(tester, result: false);
          expect(
            find.byKey(const ValueKey('director-result-image')),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey('director-transform')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          _checkAlignment(tester);
          expect(
            container.read(directorToolsNotifierProvider).resultVariants.length,
            3,
          );
          final name =
              '${locale.toLanguageTag()}-${brightness.name}-${size.width.toInt()}';
          await _capture(tester, boundary, '$name-background');
          await tester.tap(find.text(l10n.img2img_generated));
          await tester.pumpAndSettle();
          expect(container.read(directorToolsNotifierProvider).variantIndex, 1);
          _checkAlignment(tester);
          for (final tool in DirectorToolType.values) {
            controller.selectTool(tool);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$tool');
            _checkAlignment(tester);
            if ([
              DirectorToolType.colorize,
              DirectorToolType.fixEmotion,
              DirectorToolType.pixelSnap,
            ].contains(tool)) {
              await _capture(tester, boundary, '$name-${tool.name}');
            }
          }
          controller.selectTool(DirectorToolType.fixEmotion);
          await tester.pumpAndSettle();
          if (size.width == 1672) {
            await tester.tap(find.byType(DropdownButtonFormField<String>));
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.text(l10n.img2img_emotionHurt).last,
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text(l10n.img2img_emotionHurt).last);
            await tester.pumpAndSettle();
            expect(
              container.read(directorToolsNotifierProvider).emotion,
              'hurt',
            );
          }
          if (size.width >= 1180) {
            await tester.tap(find.byTooltip(l10n.img2img_directorWeaken));
            await tester.pumpAndSettle();
            expect(container.read(directorToolsNotifierProvider).defry, 1);
            expect(
              find.text(l10n.img2img_emotionStrengthSlightlyWeak),
              findsOneWidget,
            );
          }
          controller.selectTool(DirectorToolType.pixelSnap);
          await tester.pumpAndSettle();
          if (size.width < 1180) {
            await tester.tap(find.byKey(const ValueKey('director-more-tools')));
            await tester.pumpAndSettle();
            await tester.tap(find.text(l10n.img2img_pixelSnap).last);
            await tester.pumpAndSettle();
          }
          controller.running();
          await tester.pump();
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('director-transform')),
                )
                .onPressed,
            isNull,
          );
          _checkAlignment(tester);
          controller.failed();
          await tester.pumpAndSettle();
          expect(find.text('Test processing error'), findsOneWidget);
          _checkAlignment(tester);
          expect(tester.takeException(), isNull);
          expect(
            container.read(generationParamsNotifierProvider).prompt,
            'draft must stay intact',
          );
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
