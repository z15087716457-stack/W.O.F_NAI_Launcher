import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_rail.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'nav_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final pinned in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
        'larger account anchor fits rail and account panel pinned=$pinned dark=$dark',
        (t) async {
          await pumpNav(
            t,
            data: NavFixture.view(pinned: pinned),
            dark: dark,
            size: const Size(640, 760),
          );
          final anchor = find.byKey(
            Key(pinned ? 'main-nav-panel-account' : 'main-nav-avatar'),
          );
          final face = find.descendant(
            of: anchor,
            matching: find.byType(NavAvatar),
          );
          final hit = t.getRect(anchor), visible = t.getRect(face);
          expect(visible.size, const Size(40, 40));
          expect(hit.contains(visible.topLeft), isTrue);
          expect(
            hit.contains(visible.bottomRight - const Offset(.01, .01)),
            isTrue,
          );
          expect(t.takeException(), isNull);
          if (Platform.environment['FEEDBACK_CAPTURES'] == '1') {
            await t.runAsync(() async {
              final boundary = t.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('nav-capture')),
              );
              final bitmap = await boundary.toImage();
              final bytes = await bitmap.toByteData(
                format: ui.ImageByteFormat.png,
              );
              bitmap.dispose();
              final file = File(
                '.dart_tool/feedback-restoration-20261014/captures/avatar-${pinned ? 'expanded' : 'rail'}-${dark ? 'dark' : 'light'}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }
        },
      );
    }
  }
}
