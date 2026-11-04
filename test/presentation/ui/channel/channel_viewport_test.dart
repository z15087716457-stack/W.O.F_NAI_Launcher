import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_geometry.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_scene.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';

import '../../../helpers/studio_capture_fonts.dart';

Future<Uint8List> render(
  ChannelTheme theme, {
  bool dark = true,
  Size size = const Size(922, 1000),
  Offset offset = const Offset(461, 50),
  double scale = 880 / 1216,
  double level = 1,
  ChannelMode mode = ChannelMode.fixed,
  Rect? pinboard = const Rect.fromLTWH(30, 100, 120, 200),
}) async {
  final recorder = ui.PictureRecorder();
  paintChannelScene(
    Canvas(recorder),
    size,
    ChannelSceneSpec(
      env: ChannelEnv.of(ChannelSettings(mode: mode, fixed: theme)),
      camera: ChannelCamera(offset: offset, scale: scale),
      dark: dark,
      base: dark ? const Color(0xff101012) : const Color(0xfffafafa),
      level: level,
      seed: 7,
      names: const {},
      pinboard: pinboard,
    ),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  picture.dispose();
  final raw = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  image.dispose();
  return raw;
}

/// Compare at the paint entry point. The reference uses the Git composition's
/// own camera; the welcome path must also scale text and one-pixel details.
Future<Uint8List> welcomeFrame(
  ChannelTheme theme,
  bool dark,
  Size viewport, {
  required bool reference,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final settings = ChannelSettings(
    mode: ChannelMode.fixed,
    fixed: theme,
    seed: 7,
    ruler: false,
  );
  final colors = UiColors.fromTheme(
    dark ? ThemeData.dark() : ThemeData.light(),
  );
  if (reference) {
    final k = viewport.width / 922;
    canvas.scale(k);
    final height = viewport.height / k;
    paintChannelScene(
      canvas,
      Size(922, height),
      ChannelSceneSpec(
        env: ChannelEnv.of(settings),
        camera: ChannelCamera(
          offset: Offset(461, 50 + (height - 1000) / 2),
          scale: 880 / 1216,
        ),
        dark: dark,
        base: colors.bg,
        level: 1,
        seed: 7,
        names: const {},
      ),
    );
  } else {
    ChannelBackdropPainter(
      data: ChannelViewData(
        settings: settings,
        camera: ChannelCamera.welcome(viewport),
        now: DateTime(2026),
        welcome: true,
      ),
      colors: colors,
      names: const {},
    ).paint(canvas, viewport);
  }
  final pic = recorder.endRecording();
  final image = await pic.toImage(
    viewport.width.toInt(),
    viewport.height.toInt(),
  );
  pic.dispose();
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  image.dispose();
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);

  for (final theme in ChannelTheme.values) {
    test(
      'whole welcome composition for ${theme.name} matches the original in light and dark',
      () async {
        for (final (dark, viewport) in [
          (false, const Size(160, 460)),
          (true, const Size(691, 514)),
        ]) {
          final expected = await welcomeFrame(
            theme,
            dark,
            viewport,
            reference: true,
          );
          final painted = await welcomeFrame(
            theme,
            dark,
            viewport,
            reference: false,
          );
          expect(painted, orderedEquals(expected));
        }
      },
    );
  }

  test(
    'a horizontal pan moves the complete background with the image',
    () async {
      const size = Size(760, 360);
      const width = 760, height = 360, delta = 66;
      for (final theme in ChannelTheme.values) {
        final first = await render(
          theme,
          size: size,
          scale: .74,
          offset: const Offset(420, 10),
          pinboard: null,
        );
        final moved = await render(
          theme,
          size: size,
          scale: .74,
          offset: const Offset(486, 10),
          pinboard: null,
        );
        var total = 0, changed = 0;
        for (var y = 4; y < height - 4; y++) {
          for (var x = 4; x < width - delta - 4; x++) {
            final a = 4 * (y * width + x), b = 4 * (y * width + x + delta);
            for (var c = 0; c < 3; c++) {
              total++;
              if ((first[a + c] - moved[b + c]).abs() > 3) changed++;
            }
          }
        }
        expect(changed / total, lessThan(.0005), reason: theme.name);
      }
    },
  );
}
