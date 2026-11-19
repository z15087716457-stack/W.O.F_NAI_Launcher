import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_rag_startup.dart';

void main() {
  test(
    'starts immediately and blocks additional requests until completion',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final startup = container.read(settingsRagStartupProvider.notifier);
      final pending = Completer<void>();
      var calls = 0;
      final first = startup.run(SettingsRagSourceKind.wiki, () {
        calls++;
        return pending.future;
      });
      expect(calls, 1);
      expect(
        container.read(settingsRagStartupProvider),
        SettingsRagSourceKind.wiki,
      );
      await startup.run(SettingsRagSourceKind.tags, () async => calls++);
      expect(calls, 1);

      pending.complete();
      await first;
      expect(container.read(settingsRagStartupProvider), isNull);
      await startup.run(SettingsRagSourceKind.tags, () async => calls++);
      expect(calls, 2);
    },
  );

  test('a failed request releases the source for retry', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final startup = container.read(settingsRagStartupProvider.notifier);
    await expectLater(
      startup.run(
        SettingsRagSourceKind.tags,
        () async => throw StateError('preview failed'),
      ),
      throwsStateError,
    );
    expect(container.read(settingsRagStartupProvider), isNull);
    var retried = false;
    await startup.run(SettingsRagSourceKind.tags, () async => retried = true);
    expect(retried, isTrue);
  });

  test('pending work may finish after the container is disposed', () async {
    final container = ProviderContainer();
    final pending = Completer<void>();
    final first = container
        .read(settingsRagStartupProvider.notifier)
        .run(SettingsRagSourceKind.wiki, () => pending.future);
    container.dispose();
    pending.complete();
    await first;
  });
}
