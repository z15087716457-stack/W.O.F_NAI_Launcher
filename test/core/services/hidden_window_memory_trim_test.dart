import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/core/services/hidden_window_memory_trim.dart';
import 'package:nai_launcher/presentation/widgets/common/app_visibility_scope.dart';

import '../../helpers/app_image_cache_test_binding.dart';
import '../../helpers/app_logger_test_isolation.dart';

Uint8List _png(int seed) => Uint8List.fromList(
  img.encodePng(
    img.Image(width: 32, height: 32)..clear(img.ColorRgb8(seed, 0, 0)),
  ),
);

// The window signal itself is platform code (menu bar on macOS, tray on
// Windows); the trim only follows it, the same way on both.
const _platforms = TargetPlatformVariant({
  TargetPlatform.macOS,
  TargetPlatform.windows,
});

void main() {
  AppImageCacheTestBinding();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final visibility = AppVisibility.instance;
  final cache = AppImageCacheTestBinding.cache;
  late HiddenWindowMemoryTrim trim;
  late AppVisibilitySources sources;
  late MemoryImage shown, cachedOnly;

  setUp(() {
    // Hidden / shown comes from AppVisibility.debugSet here; the platform
    // sources are tested in app_visibility_test.
    sources = AppVisibilitySources(platform: TargetPlatform.android);
    trim = HiddenWindowMemoryTrim(visibility: visibility)..start();
  });
  tearDown(() {
    trim.stop();
    sources.detach();
    visibility.debugSet(true);
    cache
      ..clear()
      ..clearLiveImages();
  });

  /// The app's root: while the window is hidden, [AppVisibilityScope] turns
  /// TickerMode off below it, and every [Image] stops listening.
  Widget app(Widget child) => AppVisibilityScope(
    sources: sources,
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );

  Future<void> decode(WidgetTester tester, List<ImageProvider> images) =>
      tester.runAsync(() async {
        final element = tester.element(find.byType(Directionality));
        for (final image in images) {
          await precacheImage(image, element);
        }
      });

  /// What the [Image] widgets paint now; null is a blank one.
  List<ui.Image?> painted(WidgetTester tester) => [
    for (final raw in tester.widgetList<RawImage>(find.byType(RawImage)))
      raw.image,
  ];

  Future<void> showOne(WidgetTester tester) async {
    shown = MemoryImage(_png(10));
    cachedOnly = MemoryImage(_png(200));
    // Without gaplessPlayback (the default), an image decoded again shows
    // blank until it is ready.
    await tester.pumpWidget(app(Image(image: shown)));
    // cachedOnly: decoded earlier, no longer on screen (a gallery page
    // scrolled away).
    await decode(tester, [shown, cachedOnly]);
    await tester.pump();
    expect(cache.statusForKey(shown).live, isTrue);
    expect(cache.statusForKey(cachedOnly).keepAlive, isTrue);
  }

  /// Hides the window, then draws the frame that pauses the images (in the
  /// app it follows within milliseconds).
  Future<void> hide(WidgetTester tester) async {
    visibility.debugSet(false);
    await tester.pump();
  }

  testWidgets('a minute hidden releases images nothing shows', (tester) async {
    await showOne(tester);
    await hide(tester);
    await tester.pump(const Duration(seconds: 59));
    expect(cache.statusForKey(cachedOnly).keepAlive, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(cache.statusForKey(cachedOnly).untracked, isTrue);
  }, variant: _platforms);

  testWidgets('what is on screen keeps its decode: no reload, no blank', (
    tester,
  ) async {
    await showOne(tester);
    final before = painted(tester).single!;
    final loads = cache.loads;
    await hide(tester);
    // Paused by TickerMode, the Image keeps its decode but stops listening:
    // to Flutter's cache it looks unused.
    expect(cache.statusForKey(shown).live, isFalse);
    await tester.pump(const Duration(minutes: 1));
    expect(cache.statusForKey(cachedOnly).untracked, isTrue);
    expect(cache.statusForKey(shown).keepAlive, isTrue);

    visibility.debugSet(true);
    await tester.pump();
    final after = painted(tester).single;
    expect(after, isNotNull, reason: 'blank until decoded again');
    expect(after!.isCloneOf(before), isTrue);
    expect(cache.loads, loads, reason: 'decoded again');
  }, variant: _platforms);

  testWidgets('a picture put on screen while hidden counts as in use too', (
    tester,
  ) async {
    // A background generation finishing while the window is hidden.
    shown = MemoryImage(_png(10));
    final later = MemoryImage(_png(90));
    final second = ValueNotifier(false);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      app(
        ValueListenableBuilder<bool>(
          valueListenable: second,
          builder: (context, on, _) => Column(
            children: [
              Image(image: shown),
              if (on) Image(image: later),
            ],
          ),
        ),
      ),
    );
    await decode(tester, [shown]);
    await tester.pump();
    await hide(tester);

    second.value = true;
    await tester.pump();
    await decode(tester, [later]);
    await tester.pump();
    expect(painted(tester), everyElement(isNotNull));
    expect(cache.statusForKey(later).live, isFalse, reason: 'paused');
    final loads = cache.loads;

    await tester.pump(const Duration(minutes: 1));
    expect(cache.statusForKey(later).keepAlive, isTrue);
    visibility.debugSet(true);
    await tester.pump();
    expect(painted(tester), everyElement(isNotNull));
    expect(cache.loads, loads, reason: 'decoded again');
  }, variant: _platforms);

  testWidgets(
    'what left the screen while hidden goes once the window is back',
    (tester) async {
      // A picture replaced while the window is hidden (a stream preview, a
      // tile switching decodes): the paused Image tells the cache nothing.
      final before = MemoryImage(_png(10));
      final after = MemoryImage(_png(90));
      final image = ValueNotifier<ImageProvider>(before);
      addTearDown(image.dispose);
      await tester.pumpWidget(
        app(
          ValueListenableBuilder<ImageProvider>(
            valueListenable: image,
            builder: (context, value, _) =>
                Image(image: value, gaplessPlayback: true),
          ),
        ),
      );
      await decode(tester, [before]);
      await tester.pump();
      await hide(tester);
      image.value = after;
      await tester.pump();
      await decode(tester, [after]);
      await tester.pump();

      // The release cannot tell which of the two is still on screen.
      await tester.pump(const Duration(minutes: 1));
      expect(cache.statusForKey(before).keepAlive, isTrue);
      final loads = cache.loads;

      visibility.debugSet(true);
      await tester.pump();
      expect(cache.statusForKey(before).untracked, isTrue);
      expect(cache.statusForKey(after).keepAlive, isTrue, reason: 'on screen');
      expect(painted(tester).single, isNotNull);
      expect(cache.loads, loads, reason: 'decoded again');
    },
    variant: _platforms,
  );

  testWidgets('the release draws one frame: the memory comes back hidden', (
    tester,
  ) async {
    await showOne(tester);
    // A handle of our own on the decode of cachedOnly: it is freed once ours
    // is the only one left.
    ui.Image? probe;
    final stream = cachedOnly.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) => probe = info.image);
    stream
      ..addListener(listener)
      ..removeListener(listener);
    addTearDown(() => probe!.dispose());
    int handles() => probe!.debugGetOpenHandleStackTraces()!.length;
    expect(handles(), 2, reason: 'the cache\'s and ours');

    // Hidden the way macOS and Windows report it: the app draws no frames.
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(visibility.isVisible, isFalse);
    await tester.pump();
    await tester.pump(const Duration(seconds: 59));
    expect(tester.binding.hasScheduledFrame, isFalse);

    // The release, without drawing a frame yet.
    await tester.binding.delayed(const Duration(seconds: 1));
    expect(cache.statusForKey(cachedOnly).untracked, isTrue);
    expect(handles(), 2, reason: 'the cache lets go after the next frame');
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'asks for one');
    await tester.pump();
    expect(handles(), 1, reason: 'freed, still hidden');
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'only one');
    expect(visibility.isVisible, isFalse);
  }, variant: _platforms);

  testWidgets('showing the window within the minute keeps everything', (
    tester,
  ) async {
    await showOne(tester);
    await hide(tester);
    await tester.pump(const Duration(seconds: 30));
    visibility.debugSet(true);
    await tester.pump(const Duration(minutes: 5));
    expect(cache.statusForKey(cachedOnly).keepAlive, isTrue);
  }, variant: _platforms);

  testWidgets('once the window is back, what left the screen goes next time', (
    tester,
  ) async {
    await showOne(tester);
    await hide(tester);
    await tester.pump(const Duration(minutes: 1));
    visibility.debugSet(true);
    await tester.pump();
    expect(cache.statusForKey(shown).keepAlive, isTrue);

    // The picture leaves the screen; the window hides again for a minute.
    await tester.pumpWidget(app(const SizedBox()));
    await hide(tester);
    await tester.pump(const Duration(minutes: 1));
    expect(cache.statusForKey(shown).untracked, isTrue);
  }, variant: _platforms);
}
