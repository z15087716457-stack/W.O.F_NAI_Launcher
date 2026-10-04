import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_thumbnail_quality_store.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_local_gallery_service.dart';

void main() {
  test('quality change updates state first and persists the choice', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final service = FakeLocalGalleryService([
      for (var i = 0; i < 5; i++)
        LocalImageRecord(
          path: 'image_$i.png',
          size: 1,
          modifiedAt: DateTime(2026, 1, 1),
        ),
    ]);
    final container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(localGalleryNotifierProvider.notifier);
    notifier.setThumbnailQualityStoreForTesting(
      const GalleryThumbnailQualityStore(),
    );
    await notifier.initialize();
    final timeline = container.read(localGalleryNotifierProvider).timeline;

    await notifier.setThumbnailQuality(GalleryThumbnailQuality.sd);

    final state = container.read(localGalleryNotifierProvider);
    expect(state.thumbnailQuality, GalleryThumbnailQuality.sd);
    expect(state.timeline, same(timeline), reason: '换档不重读数据集');
    expect(
      await const GalleryThumbnailQualityStore().load(),
      GalleryThumbnailQuality.sd,
    );
  });
}
