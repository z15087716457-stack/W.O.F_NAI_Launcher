import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_local_gallery_service.dart';

class _SourceService extends FakeLocalGalleryService {
  _SourceService() : super([]);

  bool? scanRequested;

  @override
  Future<void> refresh({
    bool scan = true,
    Future<void> Function()? onFilesRefreshed,
  }) {
    scanRequested = scan;
    return super.refresh(scan: scan, onFilesRefreshed: onFilesRefreshed);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final initialized in [false, true]) {
    test(
      'source removal reloads service once (initialized: $initialized)',
      () async {
        final service = _SourceService();
        final container = ProviderContainer(
          overrides: [
            galleryServiceProvider.overrideWith(
              () => FakeGalleryServiceNotifier(service),
            ),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(localGalleryNotifierProvider.notifier);
        if (initialized) await notifier.initialize();
        final before = container
            .read(localGalleryNotifierProvider)
            .timeline
            .datasetId;
        await notifier.refreshSources();
        final state = container.read(localGalleryNotifierProvider);
        expect(service.refreshCount, 1);
        expect(service.scanRequested, false);
        expect(state.isInitialized, true);
        expect(state.error, isNull);
        expect(state.timeline.length, 0);
        if (initialized) expect(state.timeline.datasetId, before);
      },
    );
  }
}
