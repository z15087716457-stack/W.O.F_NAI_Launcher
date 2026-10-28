import 'dart:io';
import '../../helpers/grouped_canvas_batches.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_history.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/wiring/generation_data_wiring.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../ui/gen/gen_test_harness.dart';

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();

  void publish(ImageGenerationState value) => state = value;
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final (width, height) in [(1216, 832), (832, 1216), (1024, 1024)]) {
    for (final dark in [false, true]) {
      testWidgets('history placeholder follows batch $width x $height dark=$dark', (
        tester,
      ) async {
        final container = ProviderContainer(
          overrides: [
            groupedCanvasBatchesOverride,
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            generationFavoriteImagesProvider.overrideWith((_) async => {}),
            generationClockProvider.overrideWithValue(
              () => DateTime(2026, 10, 21, 13, 42),
            ),
          ],
        );
        addTearDown(container.dispose);
        final generation =
            container.read(imageGenerationNotifierProvider.notifier)
                as _Generation;
        final pending = ImageGenerationState(
          status: GenerationStatus.generating,
          generationRunId: 7,
          totalImages: 1,
          batchWidth: width,
          batchHeight: height,
          // A previous preview must not dictate the active request's shape.
          displayWidth: height,
          displayHeight: width,
        );
        generation.publish(pending);
        final capture = GlobalKey();
        await tester.pumpWidget(
          genApp(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 260,
                child: RepaintBoundary(
                  key: capture,
                  child: UncontrolledProviderScope(
                    container: container,
                    child: Consumer(
                      builder: (context, ref, _) => GenHost(
                        data: GenFixture.empty().copyWith(
                          history: GenHistoryData(
                            batches: ref.watch(
                              generationHistoryBatchesProvider,
                            ),
                            selected: 'run:7',
                          ),
                        ),
                        actions: GenActions.logging((_) {}),
                        slots: GenSlots(
                          editor: (_, _) => const SizedBox.shrink(),
                        ),
                        child: const GenHistoryPanel(width: 260),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        final cover = find.byKey(const Key('gen-batch-focused'));
        final placeholder = tester.getSize(cover);
        final batch = container.read(generationHistoryBatchesProvider).single;
        expect((batch.pendingWidth, batch.pendingHeight), (width, height));
        // The pane's 1px divider slightly constrains full-width landscape covers.
        expect(
          (placeholder.width - placeholder.height * width / height).abs(),
          lessThanOrEqualTo(1.01),
        );
        final batches = container.read(generationHistoryBatchesProvider);
        generation.publish(
          pending.copyWith(
            progress: .6,
            currentImage: 1,
            displayWidth: 512,
            displayHeight: 1024,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          identical(container.read(generationHistoryBatchesProvider), batches),
          isTrue,
          reason: 'Progress and old display size do not rebuild batch history.',
        );
        expect(tester.getSize(cover), placeholder);

        final output = Platform.environment['HISTORY_PENDING_CAPTURES'];
        if (output != null) {
          await tester.runAsync(() async {
            final image =
                await (capture.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            try {
              final png = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              final file = File('$output/$width-$height-$dark.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(png.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        // A size-only state update for the same run must reach the history UI.
        generation.publish(
          pending.copyWith(batchWidth: height, batchHeight: width),
        );
        await tester.pumpAndSettle();
        final changed = tester.getSize(cover);
        expect(
          (changed.width - changed.height * height / width).abs(),
          lessThanOrEqualTo(1.01),
        );
        generation.publish(pending);
        await tester.pumpAndSettle();

        final image =
            UiFixtureImage.gradient('history-pending-result') as MemoryImage;
        await tester.runAsync(() async {
          await precacheImage(image, tester.element(cover));
        });
        generation.publish(
          pending.copyWith(
            status: GenerationStatus.idle,
            currentImages: [
              GeneratedImage(
                id: 'finished',
                bytes: image.bytes,
                width: width,
                height: height,
                generationRunId: 7,
                batchIndex: 0,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(cover),
          placeholder,
          reason:
              'The finished cover must replace the placeholder at the same size.',
        );
        expect(find.text('生成中'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
