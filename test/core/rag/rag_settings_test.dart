import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';

void main() {
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
  });
  tearDown(Hive.close);
  test('disabled by default; only the two 120-token modes are accepted', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(ragSettingsProvider).enabled, isFalse);
    expect(RagSettings.tokenBudget, 120);
    expect(
      RagSettings.fromJson({'version': 1, 'mode': 'all'}).mode,
      RagContextMode.around,
    );
    expect(
      RagSettings.fromJson({'version': 99, 'enabled': true}).enabled,
      isFalse,
    );
  });
  test(
    'ordered preference writes retain the latest values on a fresh scope',
    () async {
      final c = ProviderContainer();
      final controller = c.read(ragSettingsProvider.notifier);
      final a = controller.update(
        const RagSettings(
          enabled: true,
          mode: RagContextMode.before,
          embedding: 'first',
        ),
      );
      final b = controller.update(
        const RagSettings(
          enabled: false,
          mode: RagContextMode.around,
          embedding: 'latest',
        ),
      );
      await Future.wait([a, b]);
      c.dispose();
      final next = ProviderContainer();
      addTearDown(next.dispose);
      expect(next.read(ragSettingsProvider).embedding, 'latest');
      expect(next.read(ragSettingsProvider).enabled, isFalse);
      expect(next.read(ragSettingsProvider).mode, RagContextMode.around);
    },
  );
  test('invalid persisted data cannot enable indexing', () async {
    await Hive.box(StorageKeys.settingsBox).put(
      RagSettingsController.storageKey,
      jsonEncode({'enabled': true, 'version': 0}),
    );
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(ragSettingsProvider).enabled, isFalse);
  });
  test('a failed save does not poison subsequent saves', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final controller = c.read(ragSettingsProvider.notifier);
    await Hive.close();
    await expectLater(
      controller.update(const RagSettings(embedding: 'failed')),
      throwsA(anything),
    );
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
    await controller.update(const RagSettings(embedding: 'recovered'));
    expect(
      jsonDecode(
        Hive.box(StorageKeys.settingsBox).get(RagSettingsController.storageKey)
            as String,
      )['embedding'],
      'recovered',
    );
  });
}
