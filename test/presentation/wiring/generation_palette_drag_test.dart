import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_palette_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_palette.dart';
import 'package:nai_launcher/presentation/wiring/generation_blocks_dock.dart';

import '../../helpers/studio_capture_fonts.dart';

final _block = PromptBlock.create(
  id: 'drag-block',
  title: 'Drag into palette',
  content: 'synthetic tag',
  color: '#FF248C65',
);

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [_block], folders: const []);
}

class _Palette extends PromptBlockPaletteNotifier {
  @override
  Future<PromptBlockPaletteState> build() async =>
      PromptBlockPaletteState(blocks: const []);

  @override
  Future<void> addBlock(String blockId) async {
    if (blockId == _block.id) {
      state = AsyncData(PromptBlockPaletteState(blocks: [_block]));
    }
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final nestedNavigator in [false, true]) {
    testWidgets(
      'dock drag remains visible above floating palette and is accepted '
      '(nested navigator: $nestedNavigator)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1100, 760);
        addTearDown(tester.view.reset);
        final container = ProviderContainer(
          overrides: [
            promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
            promptBlockPaletteNotifierProvider.overrideWith(_Palette.new),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(PromptBlockPaletteButton.closeFloating);
        await container.read(promptBlockLibraryNotifierProvider.future);
        await container.read(promptBlockPaletteNotifierProvider.future);
        final boundary = GlobalKey();
        const dock = Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 300, child: BlocksDockWiring()),
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: GeistTheme.light,
                home: Scaffold(
                  body: nestedNavigator
                      ? Navigator(
                          onGenerateRoute: (_) =>
                              MaterialPageRoute<void>(builder: (_) => dock),
                        )
                      : dock,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await PromptBlockPaletteButton.showAt(
          tester.element(find.byType(BlocksDockWiring)),
          const Rect.fromLTWH(480, 90, 30, 20),
        );
        await tester.pumpAndSettle();
        final card = find.byKey(const Key('prompt-block-palette-card'));
        final target = tester.getRect(card).topLeft + const Offset(70, 100);
        final capture =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        Future<List<int>> pixels(String name) async =>
            (await tester.runAsync(() async {
              final image = await capture.toImage();
              try {
                final output = Platform.environment['PALETTE_DRAG_CAPTURES'];
                if (output != null) {
                  final png = (await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  ))!;
                  final file = File('$output/$name-$nestedNavigator.png');
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(png.buffer.asUint8List());
                }
                final data = (await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                ))!;
                return [
                  for (
                    var y = target.dy.toInt() + 2;
                    y < target.dy.toInt() + 16;
                    y++
                  )
                    for (
                      var x = target.dx.toInt() + 4;
                      x < target.dx.toInt() + 90;
                      x++
                    )
                      data.getUint32((y * image.width + x) * 4),
                ];
              } finally {
                image.dispose();
              }
            }))!;

        final before = await pixels('empty');
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('dock-pill-drag-block'))),
        );
        await gesture.moveBy(const Offset(30, 0));
        await tester.pump();
        await gesture.moveTo(target);
        await tester.pumpAndSettle();
        final feedback = find.byWidgetPredicate(
          (widget) => widget is UiBlockPill && widget.dragging,
        );
        expect(
          tester.getRect(card).contains(tester.getCenter(feedback)),
          isTrue,
        );
        final during = await pixels('dragging');
        final changedPixels = [
          for (var i = 0; i < before.length; i++)
            if (before[i] != during[i]) i,
        ].length;
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          container
              .read(promptBlockPaletteNotifierProvider)
              .requireValue
              .blocks
              .map((block) => block.id),
          [_block.id],
        );
        expect(PromptBlockPaletteButton.floatingOpen, isTrue);
        expect(
          changedPixels,
          greaterThan(100),
          reason: 'The dragged pill must paint above the palette surface.',
        );
        expect(tester.takeException(), isNull);
        PromptBlockPaletteButton.closeFloating();
        await tester.pumpAndSettle();
      },
    );
  }
}
