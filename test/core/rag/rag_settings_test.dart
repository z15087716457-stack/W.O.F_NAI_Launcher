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
  test('disabled by default with a 120-token recommendation budget', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(ragSettingsProvider).enabled, isFalse);
    expect(c.read(ragSettingsProvider).tokenBudget, 120);
    expect(
      RagSettings.fromJson({'version': 99, 'enabled': true}).enabled,
      isFalse,
    );
  });
  test('old context modes migrate without losing other preferences', () {
    for (final mode in ['before', 'around', 'all']) {
      final settings = RagSettings.fromJson({
        'version': 1,
        'enabled': true,
        'mode': mode,
        'embedding': 'saved-model',
        'wikiEnabled': true,
      });
      expect(settings.tokenBudget, 120);
      expect(settings.enabled, isTrue);
      expect(settings.wikiEnabled, isTrue);
      expect(settings.embedding, 'saved-model');
      expect(settings.toJson().containsKey('mode'), isFalse);
    }
  });
  test('persisted budget is bounded and changes do not reconnect models', () {
    for (final (value, expected) in [
      (null, 120),
      ('512', 120),
      (128.5, 120),
      (0, 32),
      (32, 32),
      (121, 121),
      (512, 512),
      (999, 512),
    ]) {
      expect(
        RagSettings.fromJson({'tokenBudget': value}).tokenBudget,
        expected,
      );
    }
    const settings = RagSettings(enabled: true, embedding: 'saved-model');
    final changed = settings.copyWith(tokenBudget: 512);
    expect(RagSettings.fromJson(changed.toJson()).tokenBudget, 512);
    expect(changed.connectionKey, settings.connectionKey);
  });
  test(
    'ordered preference writes retain the latest values on a fresh scope',
    () async {
      final c = ProviderContainer();
      final controller = c.read(ragSettingsProvider.notifier);
      final a = controller.update(
        const RagSettings(enabled: true, tokenBudget: 32, embedding: 'first'),
      );
      final b = controller.update(
        const RagSettings(
          enabled: false,
          tokenBudget: 512,
          embedding: 'latest',
        ),
      );
      await Future.wait([a, b]);
      c.dispose();
      final next = ProviderContainer();
      addTearDown(next.dispose);
      expect(next.read(ragSettingsProvider).embedding, 'latest');
      expect(next.read(ragSettingsProvider).enabled, isFalse);
      expect(next.read(ragSettingsProvider).tokenBudget, 512);
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
