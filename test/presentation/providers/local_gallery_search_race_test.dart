import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/exceptions/gallery_exceptions.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';

import '../../helpers/fake_local_gallery_service.dart';

class _Delayed extends FakeLocalGalleryService {
  _Delayed()
    : super([
        LocalImageRecord(
          path: '/gallery/new.png',
          size: 1,
          modifiedAt: DateTime(2026),
        ),
      ]);
  final pending = <String, Completer<void>>{};
  @override
  Future<void> applyFilter(FilterCriteria criteria) async {
    if (criteria.searchQuery.isNotEmpty) {
      final gate = Completer<void>();
      pending[criteria.searchQuery] = gate;
      await gate.future;
    }
    await super.applyFilter(criteria);
  }
}

class _NoRag extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(enabled: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'browse/cache/sort do not publish content changes; refresh and tags do',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeLocalGalleryService([
        LocalImageRecord(
          path: '/gallery/a.png',
          size: 1,
          modifiedAt: DateTime(2026),
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(service),
          ),
          ragSettingsProvider.overrideWith(_NoRag.new),
        ],
      );
      addTearDown(container.dispose);
      final gallery = container.read(localGalleryNotifierProvider.notifier);
      await gallery.initialize();
      final initial = container
          .read(localGalleryNotifierProvider)
          .contentRevision;
      await gallery.loadRecords(['/gallery/a.png']);
      expect(
        container.read(localGalleryNotifierProvider).recordsRevision,
        greaterThan(0),
      );
      expect(
        container.read(localGalleryNotifierProvider).contentRevision,
        initial,
      );
      await gallery.setSearchQuery('a');
      await gallery.setSort(
        GallerySortField.fileName,
        GallerySortDirection.ascending,
      );
      expect(
        container.read(localGalleryNotifierProvider).contentRevision,
        initial,
      );
      await gallery.refresh(scan: false);
      expect(
        container.read(localGalleryNotifierProvider).contentRevision,
        greaterThan(initial),
      );
      final refreshed = container
          .read(localGalleryNotifierProvider)
          .contentRevision;
      await gallery.setTags('/gallery/a.png', ['test']);
      expect(
        container.read(localGalleryNotifierProvider).contentRevision,
        refreshed + 1,
      );
    },
  );
  for (final failOld in [false, true]) {
    test(
      'late old ${failOld ? 'failure' : 'success'} cannot stop loading or set error for new query',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = _Delayed();
        final container = ProviderContainer(
          overrides: [
            galleryServiceProvider.overrideWith(
              () => FakeGalleryServiceNotifier(service),
            ),
            ragSettingsProvider.overrideWith(_NoRag.new),
          ],
        );
        addTearDown(container.dispose);
        final gallery = container.read(localGalleryNotifierProvider.notifier);
        await gallery.initialize();
        final old = gallery.setSearchQuery('old');
        await Future<void>.delayed(Duration.zero);
        final current = gallery.setSearchQuery('new');
        await Future<void>.delayed(Duration.zero);
        if (failOld) {
          service.pending['old']!.completeError(
            const GalleryFilterException(message: 'old failure'),
          );
        } else {
          service.pending['old']!.complete();
        }
        await old;
        expect(container.read(localGalleryNotifierProvider).isLoading, isTrue);
        expect(container.read(localGalleryNotifierProvider).error, isNull);
        service.pending['new']!.complete();
        await current;
        expect(container.read(localGalleryNotifierProvider).isLoading, isFalse);
        expect(
          container
              .read(localGalleryNotifierProvider)
              .filterCriteria
              .searchQuery,
          'new',
        );
        final failed = gallery.setSearchQuery('fail');
        await Future<void>.delayed(Duration.zero);
        service.pending['fail']!.completeError(
          const GalleryFilterException(message: 'current failure'),
        );
        await failed;
        expect(
          container.read(localGalleryNotifierProvider).error!.code,
          LocalGalleryErrorCode.filterFailed,
        );
      },
    );
  }
}
