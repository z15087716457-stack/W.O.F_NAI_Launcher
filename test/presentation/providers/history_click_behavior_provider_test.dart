import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';

void main() {
  group('HistoryClickBehaviorNotifier', () {
    test('missing storage value defaults to linked preview', () {
      final storage = LocalStorageService();
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      expect(storage.getHistoryClickBehavior(), 'select_preview');
      expect(
        container.read(historyClickBehaviorNotifierProvider),
        HistoryClickBehavior.selectPreview,
      );
    });

    test('unknown storage value falls back to linked preview', () {
      final storage = _FakeStorage()..behavior = 'unknown';
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(historyClickBehaviorNotifierProvider),
        HistoryClickBehavior.selectPreview,
      );
    });

    test(
      'an explicit open-detail preference remains after reloading',
      () async {
        final storage = _FakeStorage();
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWith((ref) => storage),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(historyClickBehaviorNotifierProvider.notifier)
            .setBehavior(HistoryClickBehavior.openDetail);

        expect(storage.behavior, 'open_detail');
        container.invalidate(historyClickBehaviorNotifierProvider);
        expect(
          container.read(historyClickBehaviorNotifierProvider),
          HistoryClickBehavior.openDetail,
        );
      },
    );
  });
}

class _FakeStorage extends LocalStorageService {
  String behavior = 'select_preview';

  @override
  String getHistoryClickBehavior() => behavior;

  @override
  Future<void> setHistoryClickBehavior(String value) async {
    behavior = value;
  }
}
