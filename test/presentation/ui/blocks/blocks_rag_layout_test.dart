import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final actions = RecordingBlocks();
  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final dock in [false, true]) {
        testWidgets('RAG badge ${locale.toLanguageTag()} dark=$dark dock=$dock', (
          tester,
        ) async {
          Widget scene({bool searching = false}) {
            final status = BlocksRagStatus(
              enabled: true,
              available: true,
              searching: searching,
              tooltip: 'Local semantic search',
            );
            return dock
                ? BlocksDock(
                    data: BlocksDockViewData(
                      total: 1,
                      query: 'rain',
                      results: [BlocksFixture.blocks(blocksTestImage).first],
                      rag: status,
                    ),
                    actions: actions.dock,
                  )
                : BlocksLibraryPage(
                    data: BlocksLibraryViewData(
                      now: BlocksFixture.now,
                      blocks: [BlocksFixture.blocks(blocksTestImage).first],
                      counts: const BlocksCounts(all: 1),
                      sidebarOpen: false,
                      rag: status,
                      query: 'rain',
                    ),
                    actions: actions.library,
                  );
          }

          await pumpBlocks(
            tester,
            scene(),
            window: dock ? 320 : 760,
            height: 800,
            rail: false,
            locale: locale.toString(),
            dark: dark,
          );
          expect(find.byKey(const Key('blocks-rag-badge')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            blocksApp(
              scene(searching: true),
              locale: locale.toString(),
              dark: dark,
            ),
          );
          await tester.pump(const Duration(milliseconds: 80));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('blocks-capture')),
            );
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            final dir = Directory('.dart_tool/rag-text-20261015/captures');
            await dir.create(recursive: true);
            await File(
              '${dir.path}/blocks-${dock ? 'dock' : 'library'}-${locale.toLanguageTag()}-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
          });
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
