import 'dart:io';

import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';

void main() {
  group('HistoryClickBehaviorNotifier', () {
    test('missing storage value defaults to focusing the image', () {
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

    test('unknown storage value falls back to focusing the image', () {
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
      'an explicitly stored open-detail choice survives an upgrade',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'history-click-upgrade-',
        );
        Hive.init(directory.path);
        addTearDown(() async {
          await Hive.close();
          await directory.delete(recursive: true);
        });
        final oldSettings = await Hive.openBox(StorageKeys.settingsBox);
        await oldSettings.put('history_click_behavior', 'open_detail');
        await oldSettings.close();
        await Hive.openBox(StorageKeys.settingsBox);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        expect(
          container.read(historyClickBehaviorNotifierProvider),
          HistoryClickBehavior.openDetail,
        );
        expect(
          container.read(localStorageServiceProvider).getHistoryClickBehavior(),
          'open_detail',
        );
      },
    );

    test('setBehavior persists and updates state', () async {
      final storage = _FakeStorage();
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      await container
          .read(historyClickBehaviorNotifierProvider.notifier)
          .setBehavior(HistoryClickBehavior.selectPreview);

      expect(
        container.read(historyClickBehaviorNotifierProvider),
        HistoryClickBehavior.selectPreview,
      );
      expect(storage.behavior, 'select_preview');
    });
  });
}

class _FakeStorage extends LocalStorageService {
  String behavior = 'open_detail';

  @override
  String getHistoryClickBehavior() => behavior;

  @override
  Future<void> setHistoryClickBehavior(String value) async {
    behavior = value;
  }
}
