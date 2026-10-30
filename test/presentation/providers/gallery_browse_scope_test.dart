import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/gallery_recent_views_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_trash_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import '../../helpers/fake_local_gallery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'recent scope follows view order, remains stable while viewing, and refreshes on re-entry',
    () async {
      final records = [
        for (final p in ['a', 'b', 'c'])
          LocalImageRecord(
            path: 'C:/$p.png',
            size: 1,
            modifiedAt: DateTime(2026),
          ),
      ];
      final service = FakeLocalGalleryService(records);
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(service),
          ),
        ],
      );
      addTearDown(container.dispose);
      final gallery = container.read(localGalleryNotifierProvider.notifier);
      await gallery.initialize();
      await gallery.recordViewed('C:/a.png');
      await gallery.recordViewed('C:/b.png');
      await gallery.recordViewed('C:/missing.png');
      await gallery.setBrowseScope(GalleryBrowseScope.recent);
      List<String> paths() => container
          .read(localGalleryNotifierProvider)
          .timeline
          .entries
          .map((e) => e.path)
          .toList();
      expect(paths(), ['C:/b.png', 'C:/a.png']);
      expect(container.read(localGalleryNotifierProvider).resultCount, 2);
      await gallery.recordViewed('C:/a.png');
      expect(paths(), ['C:/b.png', 'C:/a.png']);
      await gallery.reloadTimeline();
      expect(paths(), ['C:/b.png', 'C:/a.png']);
      await gallery.setBrowseScope(GalleryBrowseScope.library);
      await gallery.setBrowseScope(GalleryBrowseScope.recent);
      expect(paths(), ['C:/a.png', 'C:/b.png']);
    },
  );

  test(
    'trash has its own dataset; viewing it never enters recent history',
    () async {
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(FakeLocalGalleryService([])),
          ),
          galleryTrashTimelineProvider.overrideWith(
            (ref) async => [
              GalleryTimelineEntry(
                path: 'C:/deleted.png',
                modifiedAt: DateTime(2026),
                width: 832,
                height: 1216,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      final gallery = container.read(localGalleryNotifierProvider.notifier);
      await gallery.initialize();
      await gallery.setBrowseScope(GalleryBrowseScope.trash);
      expect(
        container
            .read(localGalleryNotifierProvider)
            .timeline
            .entries
            .single
            .path,
        'C:/deleted.png',
      );
      await gallery.recordViewed('C:/deleted.png');
      expect(
        await container.read(galleryRecentViewsStoreProvider).load(),
        isEmpty,
      );
      await gallery.setBrowseScope(GalleryBrowseScope.library);
      expect(
        container.read(localGalleryNotifierProvider).timeline.entries,
        isEmpty,
      );
    },
  );
}
