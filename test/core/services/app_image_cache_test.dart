import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_image_cache.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';

/// The app's binding installs the cache the same way.
class _Binding extends AutomatedTestWidgetsFlutterBinding
    with AppImageCacheBinding {}

/// An image ready in a microtask (like a decode, without decoding anything),
/// to fill the cache quickly. Only [id] makes the key.
class _Picture extends ImageProvider<_Picture> {
  const _Picture(this.id, [this.image]);
  final int id;
  final ui.Image? image;

  @override
  Future<_Picture> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Picture key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future.value(ImageInfo(image: image!.clone())),
      );

  @override
  bool operator ==(Object other) => other is _Picture && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

void main() {
  _Binding();
  final visibility = AppVisibility.instance;
  late ui.Image pixels;
  late AppImageCache cache;

  setUpAll(() async {
    cache = PaintingBinding.instance.imageCache as AppImageCache;
    pixels = await createTestImage(width: 4, height: 4);
  });
  tearDown(() {
    visibility.debugSet(true);
    cache
      ..clear()
      ..clearLiveImages()
      ..maximumSize = 1000;
  });

  /// Shows [id] the way an Image widget does (resolve, listen) once it is
  /// ready; call the result to take it off screen.
  Future<VoidCallback> show(int id) async {
    final stream = _Picture(id, pixels).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) => info.dispose());
    stream.addListener(listener);
    await Future<void>.delayed(Duration.zero);
    return () => stream.removeListener(listener);
  }

  test('the app binding installs it', () {
    expect(PaintingBinding.instance.imageCache, isA<AppImageCache>());
  });

  test('visible, it is Flutter\'s cache: in use means listened to', () async {
    final hide = await show(1);
    (await show(2))();
    expect(cache.isInUse(const _Picture(1)), isTrue);
    expect(cache.isInUse(const _Picture(2)), isFalse);
    cache.clear();
    expect(cache.statusForKey(const _Picture(2)).untracked, isTrue);
    expect(cache.statusForKey(const _Picture(1)).live, isTrue);
    hide();
  });

  test('the record of keys stays about as large as the cache', () async {
    cache.maximumSize = 20;
    for (var i = 0; i < 500; i++) {
      (await show(i))();
    }
    expect(cache.currentSize, 20);
    expect(cache.debugKeyCount, lessThanOrEqualTo(20 + 64));
    cache.evict(const _Picture(499));
    cache.clear();
    expect(cache.debugKeyCount, 0);
  });

  test('hidden, it keeps no key the cache let go of', () async {
    cache.maximumSize = 20;
    visibility.debugSet(false);
    // Shown while hidden (in use), then pushed out of the cache.
    for (var i = 0; i < 500; i++) {
      (await show(i))();
    }
    expect(cache.debugKeyCount, lessThanOrEqualTo(20 + 64));
    // The 20 still cached were shown in this hidden period: they stay.
    cache.clear();
    expect(cache.currentSize, 20);
    expect(cache.inUseCount, 20);
    expect(cache.debugKeyCount, 20);
  });
}
