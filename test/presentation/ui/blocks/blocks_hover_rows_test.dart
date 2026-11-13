import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_parts.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

BlockData _block(
  List<String> atoms, {
  bool negative = false,
  BlockThumb? thumb,
}) => BlockData(
  id: 'hover-rows',
  title: '显像管故障',
  color: const Color(0xFF8BAEB5),
  atoms: negative ? const [] : atoms,
  negativeAtoms: negative ? atoms : const [],
  thumb: thumb,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'hover shows all twelve sample items instead of the first seven',
    (t) async {
      const atoms = [
        'glowing lines',
        'luminous lines',
        'white lines',
        'neon effect',
        'lineart',
        'monochrome',
        'bloom',
        'chromatic aberration',
        'scanlines',
        'CRT screen',
        'retro',
        'cyberpunk',
      ];
      final imagePath = Platform.environment['BLOCK_HOVER_IMAGE'];
      final thumb = imagePath == null
          ? null
          : BlockThumb(MemoryImage(File(imagePath).readAsBytesSync()));
      await pumpBlocks(
        t,
        Center(child: BlockHoverCard(_block(atoms, thumb: thumb))),
        dark: true,
        window: 700,
        height: 650,
        rail: false,
      );
      if (thumb != null) {
        await t.runAsync(
          () => precacheImage(thumb.image, t.element(find.byType(Scaffold))),
        );
        await t.pumpAndSettle();
      }
      for (final atom in atoms) {
        expect(find.text(atom), findsOneWidget);
      }
      expect(find.text('+5'), findsNothing);
      expect(t.takeException(), isNull);

      final output = Platform.environment['BLOCK_HOVER_CAPTURE'];
      if (output != null) {
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('blocks-capture')),
        );
        await t.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(output).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );

  for (final width in [300.0, 260.0]) {
    for (final scale in [1.0, 1.3]) {
      for (final negative in [false, true]) {
        testWidgets('five rows fit at $width / x$scale / negative=$negative', (
          t,
        ) async {
          final atoms = List.generate(
            40,
            (i) => '${i.isEven ? 'glowing lines' : 'chromatic aberration'} $i',
          );
          await pumpBlocks(
            t,
            Center(
              child: SizedBox(
                width: width,
                child: MediaQuery.withClampedTextScaling(
                  minScaleFactor: scale,
                  maxScaleFactor: scale,
                  child: BlockHoverCard(_block(atoms, negative: negative)),
                ),
              ),
            ),
            dark: negative,
          );
          final chips = find.byType(BlockAtom);
          final rows = <double>{};
          final content = t.getRect(find.byType(BlockAtoms));
          var visible = 0;
          var remaining = 0;
          for (final e in chips.evaluate()) {
            final chip = e.widget as BlockAtom;
            final rect = t.getRect(find.byWidget(chip));
            rows.add(rect.top);
            expect(rect.left, greaterThanOrEqualTo(content.left));
            expect(rect.right, lessThanOrEqualTo(content.right + .01));
            if (chip.muted) {
              remaining = int.parse(chip.text.substring(1));
            } else {
              expect(chip.text, atoms[visible++]);
            }
          }
          expect(rows, hasLength(5));
          expect(remaining, greaterThan(0));
          expect(visible + remaining, atoms.length);
          expect(t.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('short previews keep their natural height', (t) async {
    await pumpBlocks(
      t,
      Center(child: BlockHoverCard(_block(['bloom', 'retro']))),
    );
    final first = t.getRect(find.text('bloom'));
    final second = t.getRect(find.text('retro'));
    expect(first.top, second.top);
    expect(t.getSize(find.byType(BlockAtoms)).height, 20);
    expect(t.takeException(), isNull);
  });
}
