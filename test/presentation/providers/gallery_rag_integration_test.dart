import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_gallery_search.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/gallery/gallery_group_mode.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/gallery_rag_query_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import '../../helpers/fake_local_gallery_service.dart';

class _Settings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(
    enabled: true,
    tagsEnabled: false,
    galleryEnabled: true,
  );
  @override
  Future<void> update(RagSettings value) async {
    state = value;
  }
}

class _Rag extends RagController {
  bool deferred = false;
  final requests =
      <
        ({
          String text,
          String image,
          List<String> allowed,
          RagCancellation token,
          Completer<List<RagGalleryHit>> result,
        })
      >[];
  @override
  RagStatus build() => const RagStatus(
    sources: {
      RagSource.gallery: RagStatus(
        phase: 'ready',
        indexed: 10,
        total: 10,
        complete: true,
      ),
    },
  );
  @override
  Future<List<RagGalleryHit>> searchGallery({
    required String query,
    required List<String> allowed,
    required RagCancellation cancellation,
    String image = '',
    RagGalleryMode mode = RagGalleryMode.mixed,
  }) {
    final result = Completer<List<RagGalleryHit>>();
    requests.add((
      text: query,
      image: image,
      allowed: allowed,
      token: cancellation,
      result: result,
    ));
    if (!deferred) {
      result.complete(const [
        RagGalleryHit(id: '2', path: '/gallery/forest.png', channel: 'visual'),
        RagGalleryHit(
          id: 'outside',
          path: '/other/private.png',
          channel: 'visual',
        ),
      ]);
    }
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late LocalGalleryNotifier gallery;
  late _Rag rag;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeLocalGalleryService([
      LocalImageRecord(
        path: '/gallery/rain.png',
        size: 1,
        modifiedAt: DateTime(2026, 10, 15),
        isFavorite: true,
      ),
      LocalImageRecord(
        path: '/gallery/forest.png',
        size: 1,
        modifiedAt: DateTime(2026, 10, 14),
      ),
    ]);
    container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
        ),
        ragSettingsProvider.overrideWith(_Settings.new),
        ragControllerProvider.overrideWith(_Rag.new),
      ],
    );
    gallery = container.read(localGalleryNotifierProvider.notifier);
    rag = container.read(ragControllerProvider.notifier) as _Rag;
    await gallery.initialize();
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
  });
  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 240));
  test(
    'native results appear first and semantic extras obey the current scope',
    () async {
      rag.deferred = true;
      await gallery.setSearchQuery('rain');
      await Future<void>.delayed(Duration.zero);
      expect(
        container
            .read(localGalleryNotifierProvider)
            .timeline
            .entries
            .map((e) => e.path),
        ['/gallery/rain.png'],
      );
      expect(
        rag.requests.single.allowed,
        containsAll(['/gallery/rain.png', '/gallery/forest.png']),
      );
      rag.requests.single.result.complete(const [
        RagGalleryHit(id: '2', path: '/gallery/forest.png', channel: 'visual'),
        RagGalleryHit(id: '0', path: '/other/private.png', channel: 'visual'),
      ]);
      await flush();
      final state = container.read(localGalleryNotifierProvider);
      expect(state.timeline.entries.map((e) => e.path), [
        '/gallery/rain.png',
        '/gallery/forest.png',
      ]);
      expect(state.resultCount, 2);
      expect(state.effectiveGroupMode, GalleryGroupMode.none);
    },
  );
  test('a changed query cancels old results', () async {
    rag.deferred = true;
    await gallery.setSearchQuery('rain');
    await Future<void>.delayed(Duration.zero);
    final old = rag.requests.single;
    await gallery.setSearchQuery('forest');
    await Future<void>.delayed(Duration.zero);
    expect(old.token.isCancelled, isTrue);
    old.result.complete(const [
      RagGalleryHit(id: '1', path: '/gallery/rain.png', channel: 'visual'),
    ]);
    rag.requests.last.result.complete([]);
    await flush();
    expect(
      container
          .read(localGalleryNotifierProvider)
          .timeline
          .entries
          .map((e) => e.path),
      ['/gallery/forest.png'],
    );
  });
  test(
    'image queries contain only ranked matches and clear-all removes the query image',
    () async {
      container
          .read(galleryRagQueryProvider.notifier)
          .setImage('/query/original.png');
      await flush();
      expect(rag.requests.single.image, '/query/original.png');
      expect(
        container
            .read(localGalleryNotifierProvider)
            .timeline
            .entries
            .map((e) => e.path),
        ['/gallery/forest.png'],
      );
      expect(container.read(localGalleryChromeStateProvider).resultCount, 1);
      await gallery.clearAllFilters();
      await flush();
      expect(container.read(galleryRagQueryProvider).image, isEmpty);
      expect(container.read(localGalleryNotifierProvider).timeline.length, 2);
    },
  );
  test(
    'empty input and a disabled gallery source never query the model',
    () async {
      expect(rag.requests, isEmpty);
      await container
          .read(ragSettingsProvider.notifier)
          .update(const RagSettings());
      await gallery.setSearchQuery('rain');
      await flush();
      expect(rag.requests, isEmpty);
      expect(container.read(localGalleryNotifierProvider).timeline.length, 1);
    },
  );
  test('deleted images cannot be revived by a late semantic result', () async {
    rag.deferred = true;
    await gallery.setSearchQuery('rain');
    await Future<void>.delayed(Duration.zero);
    await gallery.removeDeletedImagesFromMemory(['/gallery/forest.png']);
    rag.requests.single.result.complete(const [
      RagGalleryHit(id: '2', path: '/gallery/forest.png', channel: 'visual'),
    ]);
    await flush();
    expect(
      container
          .read(localGalleryNotifierProvider)
          .timeline
          .entries
          .map((e) => e.path),
      ['/gallery/rain.png'],
    );
  });
}
