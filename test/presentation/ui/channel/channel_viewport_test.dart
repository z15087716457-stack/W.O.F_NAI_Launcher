import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_geometry.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_scene.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';

import '../../../helpers/studio_capture_fonts.dart';

Future<Uint8List> _welcomeFrame(
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
  final camera = ChannelCamera.welcome(viewport);
  if (reference) {
    paintChannelScene(
      canvas,
      viewport,
      ChannelSceneSpec(
        env: ChannelEnv.of(settings),
        camera: camera,
        dark: dark,
        base: colors.bg,
        level: settings.level.factor,
        seed: 7,
        names: const {},
        welcome: true,
      ),
    );
  } else {
    final time = ValueNotifier(0.0);
    ChannelBackdropPainter(
      data: ChannelViewData(
        settings: settings,
        camera: camera,
        now: DateTime(2026),
        welcome: true,
      ),
      colors: colors,
      names: const {},
      time: time,
      pass: ChannelPaintPass.scene,
    ).paint(canvas, viewport);
    time.dispose();
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    viewport.width.toInt(),
    viewport.height.toInt(),
  );
  picture.dispose();
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
    test('welcome renders at 1:1 native glyph pitch across narrow and wide viewports for ${theme.name}', () async {
      for (final (dark, viewport) in [
        (false, const Size(380, 880)),
        (true, const Size(691, 514)),
        (true, const Size(1920, 1080)),
      ]) {
        final reference = await _welcomeFrame(
          theme,
          dark,
          viewport,
          reference: true,
        );
        final painted = await _welcomeFrame(
          theme,
          dark,
          viewport,
          reference: false,
        );
        expect(painted, orderedEquals(reference));
      }
    });
  }
}
