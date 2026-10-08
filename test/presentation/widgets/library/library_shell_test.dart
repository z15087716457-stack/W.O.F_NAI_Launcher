import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/library/library_widgets.dart';
import 'library_test_helpers.dart';

void main() {
  for (final width in [1280.0, 1600.0, 1920.0, 1000.0, 700.0]) {
    testWidgets('pane priority at $width', (tester) async {
      await pumpLibrary(
        tester,
        const LibraryShell(
          nav: Text('nav'),
          main: SizedBox(key: Key('main')),
          inspector: Text('inspector'),
        ),
        size: Size(width, 900),
      );
      expect(find.text('nav'), width >= 800 ? findsOneWidget : findsNothing);
      expect(
        find.text('inspector'),
        width >= 1140 ? findsOneWidget : findsNothing,
      );
      if (width >= 1140)
        expect(
          tester.getSize(find.byKey(const Key('main'))).width,
          width - 580,
        );
    });
  }
  testWidgets(
    'manual collapse and selected floating inspector; tray belongs to main',
    (tester) async {
      await pumpLibrary(
        tester,
        const LibraryShell(
          nav: Text('nav'),
          main: SizedBox(),
          navVisible: false,
          inspectorVisible: false,
          hasSelection: true,
          inspector: SizedBox(key: Key('inspector')),
          tray: SizedBox(key: Key('tray'), height: 76),
        ),
      );
      expect(find.text('nav'), findsNothing);
      expect(tester.getSize(find.byKey(const Key('inspector'))).width, 340);
      expect(tester.getSize(find.byKey(const Key('tray'))).width, 1600);
    },
  );
}
