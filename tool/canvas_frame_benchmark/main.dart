// Native, isolated frame-time probe. No app bootstrap, account or model calls.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/wiring/generation_backdrop_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_canvas_wiring.dart';
import 'package:window_manager/window_manager.dart';

class MemorySettings extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async => values[key] = value;
}

class SyntheticGeneration extends ImageGenerationNotifier {
  static late ImageGenerationState initial;
  @override
  ImageGenerationState build() => initial;
}

class ProbeChannel extends CanvasChannelNotifier {
  static String variant = 'full';
  @override
  ChannelSettings build() => ChannelSettings(
    seed: 7,
    mode: variant == 'off' ? ChannelMode.off : ChannelMode.random,
    motion: true,
  );

  void freeze() => state = state.copyWith(motion: false);
}

Future<Uint8List> syntheticImage(int i) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(1664, 2432);
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        size.bottomRight(Offset.zero),
        [Color(0xff183c64 + i * 0x050100), const Color(0xffb7d6c4)],
      ),
  );
  final rng = math.Random(i);
  for (var n = 0; n < 1800; n++) {
    canvas.drawCircle(
      Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
      1 + rng.nextDouble() * 14,
      Paint()
        ..color = Color.fromARGB(
          180,
          rng.nextInt(256),
          rng.nextInt(256),
          rng.nextInt(256),
        ),
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(1664, 2432);
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  String arg(String key, String fallback) =>
      args
          .where((s) => s.startsWith('--$key='))
          .map((s) => s.substring(key.length + 3))
          .firstOrNull ??
      fallback;
  final output = arg('output', 'frames.json');
  final variant = ProbeChannel.variant = arg('variant', 'full');
  final root = arg('source', '');
  for (final (family, file) in [
    ('StudioIcons', 'StudioIcons.ttf'),
    ('Geist', 'Geist-Regular.ttf'),
    ('Geist Mono', 'GeistMono-Regular.ttf'),
    ('Geist Pixel Square', 'GeistPixel-Square.ttf'),
    ('HarmonyOS Sans SC', 'HarmonyOS_Sans_SC_Regular.ttf'),
  ]) {
    final loader = FontLoader(family)
      ..addFont(
        File(
          '$root/assets/fonts/$file',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await loader.load();
  }
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1600, 1000),
      title: 'Canvas frame probe (isolated)',
    ),
    () async {
      await windowManager.show();
    },
  );
  final images = [for (var i = 0; i < 8; i++) await syntheticImage(i)];
  final count = int.parse(arg('count', '200'));
  SyntheticGeneration.initial = ImageGenerationState(
    history: [
      for (var i = 0; i < count; i++)
        GeneratedImage(
          id: 'probe-$i',
          bytes: images[i % images.length],
          width: 1664,
          height: 2432,
          generationRunId: count - i,
          batchIndex: 0,
          createdAt: DateTime(
            2026,
            10,
            16,
            12,
          ).subtract(Duration(minutes: i * 50)),
        ),
    ],
  );
  final storage = MemorySettings();
  final container = ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(storage),
      imageGenerationNotifierProvider.overrideWith(SyntheticGeneration.new),
      canvasChannelNotifierProvider.overrideWith(ProbeChannel.new),
      canvasChannelSeedProvider.overrideWithValue(7),
    ],
  );
  final provider = MemoryImage(images.first);
  final base = GenFixture.view(images: (_) => provider);
  final data = base.copyWith(
    canvas: GenCanvasData(
      focus: GenGroup(
        id: 'run:$count',
        tiles: [
          GenTile(id: 'probe-0', width: 1664, height: 2432, image: provider),
        ],
      ),
      info: const GenFocusInfo(
        tileId: 'probe-0',
        width: 1664,
        height: 2432,
        seed: 123,
      ),
      upscale: base.canvas.upscale,
      channel: const ChannelSettings(seed: 7),
    ),
  );
  final canvasKey = GlobalKey();
  final snapshotKey = GlobalKey();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: GeistTheme.light,
        home: Scaffold(
          body: RepaintBoundary(
            key: snapshotKey,
            child: GenerationPage(
              data: data,
              actions: GenActions.logging((_) {}),
              slots: GenSlots(
                editor: (context, target) => const Text(
                  'scenery, panorama, detailed background, blue flowers',
                ),
                canvas: (context, tile) =>
                    GenerationCanvasWiring(key: canvasKey, tileBuilder: tile),
                panelBackdrop: (context, rect) => variant == 'no-sides'
                    ? const SizedBox.expand()
                    : GenerationPanelBackdropWiring(canvasViewport: rect),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 3));
  final context = canvasKey.currentContext!;
  for (final bytes in images) {
    if (!context.mounted) throw StateError('Probe canvas was unmounted');
    await precacheImage(MemoryImage(bytes), context);
  }
  if (!context.mounted) throw StateError('Probe canvas was unmounted');
  final box = context.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(box.size.center(Offset.zero));
  final camera = container.read(generationCanvasCameraProvider.notifier);
  final samples = <String, Object?>{};
  final rows = <ui.FrameTiming>[];
  void timings(List<ui.FrameTiming> batch) => rows.addAll(batch);
  SchedulerBinding.instance.addTimingsCallback(timings);
  Future<void> drive(
    String name,
    void Function(double t, int frame) action,
  ) async {
    camera.jump(
      CanvasCamera(
        offset: box.size.center(Offset.zero) - const Offset(0, 1216) * .32,
        scale: .32,
      ),
      notifyIdle: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
    rows.clear();
    final start = developer.Timeline.now;
    final done = Completer<void>();
    var frame = 0;
    late final Ticker ticker;
    ticker = Ticker((elapsed) {
      final t = elapsed.inMicroseconds / 1e6;
      if (t >= 6) {
        ticker.stop();
        done.complete();
        return;
      }
      action(t, frame++);
    })..start();
    await done.future;
    ticker.dispose();
    final end = developer.Timeline.now;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final frames = rows
        .where(
          (f) =>
              f.timestampInMicroseconds(ui.FramePhase.vsyncStart) >= start &&
              f.timestampInMicroseconds(ui.FramePhase.vsyncStart) <= end,
        )
        .toList();
    samples[name] = {
      'ticks': frame,
      'start': start,
      'end': end,
      'frames': [
        for (final f in frames)
          {
            'vsync': f.timestampInMicroseconds(ui.FramePhase.vsyncStart),
            'build_us': f.buildDuration.inMicroseconds,
            'raster_us': f.rasterDuration.inMicroseconds,
            'total_us': f.totalSpan.inMicroseconds,
          },
      ],
    };
  }

  var previousDrag = Offset.zero;
  await drive('drag', (t, i) {
    if (i == 0) {
      GestureBinding.instance.handlePointerEvent(
        PointerDownEvent(
          pointer: 1,
          position: anchor,
          buttons: kMiddleMouseButton,
        ),
      );
    }
    final position = Offset(40 * math.sin(t), -180 * t);
    final delta = position - previousDrag;
    previousDrag = position;
    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        pointer: 1,
        position: anchor + position,
        delta: delta,
        buttons: kMiddleMouseButton,
      ),
    );
  });
  GestureBinding.instance.handlePointerEvent(
    PointerCancelEvent(pointer: 1, position: anchor),
  );
  var previousWheel = 0;
  await drive('wheel', (t, i) {
    final step = (t * 24).floor();
    if (step > previousWheel) {
      GestureBinding.instance.handlePointerEvent(
        PointerScrollEvent(
          position: anchor,
          scrollDelta: Offset(0, (step - previousWheel) * 24),
        ),
      );
    }
    previousWheel = step;
  });
  await drive('zoom', (t, i) {
    // Same production camera operation used by smooth Ctrl-wheel.
    final s = .32 + .18 * math.sin(t * 1.6);
    final current = container.read(generationCanvasCameraProvider);
    camera.zoomBy(
      s / current.scale,
      anchor: box.size.center(Offset.zero),
      smooth: true,
    );
  });
  SchedulerBinding.instance.removeTimingsCallback(timings);
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  (container.read(canvasChannelNotifierProvider.notifier) as ProbeChannel)
      .freeze();
  camera.jump(
    CanvasCamera(
      offset: box.size.center(Offset.zero) - const Offset(0, 1216) * .32,
      scale: .32,
    ),
    notifyIdle: false,
  );
  await Future<void>.delayed(const Duration(milliseconds: 600));
  final capture =
      await (snapshotKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary)
          .toImage(pixelRatio: view.devicePixelRatio);
  await File('$output.png').writeAsBytes(
    (await capture.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
  );
  capture.dispose();
  await File(output).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'variant': variant,
      'count': count,
      'physical': [view.physicalSize.width, view.physicalSize.height],
      'dpr': view.devicePixelRatio,
      'refresh_hz': view.display.refreshRate,
      'samples': samples,
    }),
  );
  // The external driver stops this isolated process only after a complete
  // result has been flushed. No Studio plugin/session shutdown is exercised.
  await Completer<void>().future;
}
