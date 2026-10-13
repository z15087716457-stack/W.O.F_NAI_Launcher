import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_generation_card.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final source = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 256, height: 384)..clear(img.ColorRgb8(70, 148, 196)),
    ),
  );
  late ProviderContainer container;
  late NaiAgentGenerationApprovals broker;
  setUp(() {
    container = ProviderContainer();
    broker = container.read(naiAgentGenerationApprovalsProvider);
  });
  tearDown(() => container.dispose());
  Future<bool> request(String operation) => broker.request(
    const NaiAgentConversationOwner('workspace', 'chat'),
    NaiAgentGenerationQuote(
      id: 'synthetic-source-quote',
      input: NaiAgentGenerationInput(
        raw: ImageParams(
          model: 'nai-diffusion-5-full',
          prompt: '1girl, solo, scenery, detailed background, blue sky',
          action: ImageGenerationAction.img2img,
          sourceImage: source,
          width: 256,
          height: 384,
          strength: operation == 'variations' ? .8 : .5,
          noise: operation == 'variations' ? .1 : 0,
          upscaledEnhance: operation == 'enhance',
        ),
        effective: ImageParams(
          model: 'nai-diffusion-5-full',
          prompt: '1girl, solo, scenery, detailed background, blue sky',
          width: 256,
          height: 384,
          upscaledEnhance: operation == 'enhance',
        ),
        draftVersion: 'frozen-source',
        batchSize: operation == 'variations' ? 3 : 1,
        billing: {
          'estimated_anlas': 27,
          'per_request_anlas': 27,
          'encoding_anlas': 0,
          'balance_anlas': 2218,
        },
        accountId: 'test-account',
        accountName: 'Local test account',
        endpoint: 'synthetic',
        sourceOperation: operation,
        sourceImageId: 'original-test-image',
      ),
      params: const {},
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ),
    NaiAgentCancellation(),
    () {},
  );

  for (final operation in ['variations', 'enhance']) {
    for (final locale in ['zh', 'en', 'ja']) {
      for (final width in [320.0, 440.0]) {
        testWidgets(
          '$operation confirmation at $width px in $locale keeps source, native details and decision buttons visible',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final response = request(operation);
            final card = broker.forChat('chat').single;
            final key = GlobalKey();
            final brightness = width == 320
                ? Brightness.dark
                : Brightness.light;
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: AppTheme.getTheme(AppStyle.geist, brightness),
                  home: Scaffold(
                    body: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: RepaintBoundary(
                          key: key,
                          child: NaiAgentGenerationCard(request: card),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.runAsync(() async {
              for (final element in find.byType(Image).evaluate()) {
                await precacheImage((element.widget as Image).image, element);
              }
            });
            await tester.pumpAndSettle();
            expect(find.byType(Image), findsOneWidget);
            final image = tester.widget<Image>(find.byType(Image));
            expect((image.image as MemoryImage).bytes, source);
            expect(find.textContaining('27 Anlas'), findsWidgets);
            expect(
              find.textContaining(
                operation == 'variations' ? '256 × 384' : '512 × 768',
              ),
              findsOneWidget,
            );
            expect(find.textContaining('detailed background'), findsOneWidget);
            expect(tester.takeException(), isNull);
            if (locale == 'zh') {
              await tester.runAsync(() async {
                final boundary =
                    key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final rendered = await boundary.toImage();
                final png = await rendered.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final dir = Directory('.dart_tool/nai-agent-stage-e5c-ui');
                await dir.create(recursive: true);
                await File(
                  '${dir.path}/source-$operation-${width.toInt()}-${brightness.name}.png',
                ).writeAsBytes(png!.buffer.asUint8List());
                rendered.dispose();
              });
            }
            await tester.tap(find.byKey(const Key('agent-generation-confirm')));
            await tester.pump();
            expect(await response, true);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
