import 'dart:io';
import 'dart:async';

// Same native mocks as the existing local-gallery layout regression.
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/screens/local_gallery/local_gallery_screen.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card.dart';

import '../../test/helpers/fake_local_gallery_service.dart';
import '../../test/helpers/light_theme_contrast.dart'
    show InMemoryLocalStorageService;
import 'readme_data.dart';

void setUpGalleryFakes() {
  // ignore: invalid_use_of_visible_for_testing_member
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
}

class GalleryShortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class GalleryBridge extends KritaBridgeNotifier {
  @override
  Future<void> close() async {}
}

class GalleryCollections extends CollectionNotifier {
  GalleryCollections(this.d);
  final ReadmeData d;
  @override
  CollectionState build() => CollectionState(
    collections: [
      ImageCollection(
        id: 'sample',
        name: d.tr('光影练习', 'Light studies'),
        createdAt: ReadmeData.now,
        imageCount: 8,
      ),
    ],
  );
  @override
  Future<void> initialize() async {}
  @override
  Future<void> refresh() async {}
}

class GalleryCategories extends GalleryCategoryNotifier {
  GalleryCategories(this.d);
  final ReadmeData d;
  @override
  GalleryCategoryState build() => GalleryCategoryState(
    categories: [
      for (var i = 0; i < 5; i++)
        GalleryCategory(
          id: 'f$i',
          name: d.folders[i],
          folderPath: d.folders[i],
          imageCount: 5,
          createdAt: ReadmeData.now,
          updatedAt: ReadmeData.now,
        ),
    ],
  );
  @override
  Future<void> refresh() async {}
  @override
  Future<void> syncWithFileSystem() async {}
}

final galleryFiles = <String, File>{};

Future<void> withGalleryFiles(Future<void> Function() action) {
  final parent = Zone.current;
  return IOOverrides.runZoned(
    action,
    createFile: (path) => galleryFiles[path] ?? parent.run(() => File(path)),
  );
}

Widget galleryScene(ReadmeData d) {
  final dir = Directory('.dart_tool/readme-shots/gallery-cache/${d.locale}')
    ..createSync(recursive: true);
  final thumbs = Directory('${dir.path}/.thumbs')..createSync(recursive: true);
  final records = <LocalImageRecord>[];
  final dimensions = <String, (int, int)>{};
  for (final (i, e) in d.images.entries.indexed) {
    final path =
        '${dir.absolute.path}${Platform.pathSeparator}sample-${i + 1}.jpg';
    final bytes = File(
      '.dart_tool/readme-shots/images/${e['file']}',
    ).readAsBytesSync();
    File(path).writeAsBytesSync(bytes);
    for (final size in ThumbnailSize.values) {
      File(
        // ignore: invalid_use_of_visible_for_testing_member
        '${thumbs.path}/${ThumbnailCacheService.buildThumbnailFileNameForTest(path, size: size)}',
      ).writeAsBytesSync(bytes);
    }
    final w = e['w'] as int, h = e['h'] as int;
    final neutral = 'D:\\NAI Studio\\outputs\\sample-${i + 1}.jpg';
    galleryFiles[neutral] = File(path);
    dimensions[neutral] = (w, h);
    records.add(
      LocalImageRecord(
        path: neutral,
        size: bytes.length,
        modifiedAt: ReadmeData.now.subtract(
          Duration(days: i ~/ 8, minutes: i * 5),
        ),
        isFavorite: i % 4 == 0,
        metadata: NaiImageMetadata(
          prompt: prompt,
          negativePrompt: negative,
          width: w,
          height: h,
          model: 'nai-diffusion-5-full',
          seed: 194200000 + i,
          steps: 28,
          scale: 5,
          sampler: 'k_euler_ancestral',
        ),
      ),
    );
  }
  return ProviderScope(
    overrides: [
      galleryFileMonitorProvider.overrideWith(
        (ref) => fakeGalleryFileMonitor(),
      ),
      galleryServiceProvider.overrideWith(
        () => FakeGalleryServiceNotifier(
          FakeLocalGalleryService(records, dimensions: dimensions),
        ),
      ),
      galleryCategoryNotifierProvider.overrideWith(() => GalleryCategories(d)),
      collectionNotifierProvider.overrideWith(() => GalleryCollections(d)),
      shortcutConfigNotifierProvider.overrideWith(GalleryShortcuts.new),
      kritaBridgeNotifierProvider.overrideWith((ref) => GalleryBridge()),
      localStorageServiceProvider.overrideWith(
        (ref) => InMemoryLocalStorageService(),
      ),
    ],
    child: const LocalGalleryScreen(),
  );
}

Future<void> prepareGallery(WidgetTester t, ReadmeData d) async {
  for (var i = 0; i < 35; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 80));
  }
  expect(find.byType(LocalImageCard), findsWidgets);
  await t.tap(find.byType(LocalImageCard).first);
  for (var i = 0; i < 10; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 80));
  }
}
