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
  if (reference) {
    final factor = viewport.width / 922;
    final height = viewport.height / factor;
    canvas.scale(factor);
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
    final time = ValueNotifier(0.0);
    ChannelBackdropPainter(
      data: ChannelViewData(
        settings: settings,
        camera: ChannelCamera.welcome(viewport),
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
    test('welcome composition scales as a whole for ${theme.name}', () async {
      for (final (dark, viewport) in [
        (false, const Size(160, 460)),
        (true, const Size(691, 514)),
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
