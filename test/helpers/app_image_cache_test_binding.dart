import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_image_cache.dart';

/// A test binding with the app's image cache, as AppWidgetsBinding installs
/// it ([AppImageCacheBinding]), that also counts the decodes it starts.
/// Create it first thing in `main`.
class AppImageCacheTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ImageCache createImageCache() => CountingImageCache();

  static CountingImageCache get cache =>
      PaintingBinding.instance.imageCache as CountingImageCache;
}

class CountingImageCache extends AppImageCache {
  /// Decodes started: [putIfAbsent] had nothing to reuse for the key.
  int loads = 0;

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) => super.putIfAbsent(key, () {
    loads++;
    return loader();
  }, onError: onError);
}
