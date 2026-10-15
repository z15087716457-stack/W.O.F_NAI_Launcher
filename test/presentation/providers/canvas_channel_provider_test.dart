import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_provider.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';

import '../../helpers/app_logger_test_isolation.dart';
import 'krita/agent_bridge_draft_test.dart' show MemoryDraftSettings;

class _SlowStorage extends MemoryDraftSettings {
  final gate = Completer<void>();
  var calls = 0;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    calls++;
    if (calls == 1) await gate.future;
    if (calls == 2) throw StateError('synthetic write failure');
    await super.setSetting(key, value);
  }
}

ProviderContainer _container(LocalStorageService storage, int seed) =>
    ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        canvasChannelSeedProvider.overrideWithValue(seed),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  test(
    'real isolated storage survives restart; only the seed changes',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'canvas-channel-settings-',
      );
      Hive.init(dir.path);
      var box = await Hive.openBox(StorageKeys.settingsBox);
      await box.put('unrelated', 'preserved');
      final first = _container(LocalStorageService(), 17);
      expect(
        first.read(canvasChannelNotifierProvider),
        const ChannelSettings(seed: 17),
      );
      final value = first
          .read(canvasChannelNotifierProvider)
          .copyWith(
            mode: ChannelMode.fixed,
            fixed: ChannelTheme.wave,
            pool: {ChannelTheme.wave, ChannelTheme.herb},
            level: ChannelLevel.strong,
            ruler: false,
            motion: false,
            seed: 999,
          );
      await first.read(canvasChannelNotifierProvider.notifier).set(value);
      expect(first.read(canvasChannelNotifierProvider), value);
      final saved =
          jsonDecode(box.get(StorageKeys.canvasChannelPreferences) as String)
              as Map;
      expect(saved.containsKey('seed'), isFalse);
      expect(box.get('unrelated'), 'preserved');
      first.dispose();
      await box.close();
      box = await Hive.openBox(StorageKeys.settingsBox);
      final second = _container(LocalStorageService(), 23);
      expect(
        second.read(canvasChannelNotifierProvider),
        value.copyWith(seed: 23),
      );
      final sub = second.listen(canvasChannelNotifierProvider, (_, _) {});
      sub.close();
      await second.pump();
      expect(second.read(canvasChannelNotifierProvider).seed, 23);
      second.dispose();
      await Hive.close();
      await dir.delete(recursive: true);
    },
  );

  for (final raw in <Object?>[
    null,
    'broken-json',
    '[]',
    jsonEncode({
      'mode': 'future',
      'fixed': 9,
      'pool': ['stars', 'stars', 'removed'],
      'level': false,
      'ruler': 3,
      'motion': 'false',
      'seed': 99,
    }),
  ]) {
    test('invalid preference fields recover defaults: $raw', () {
      final storage = MemoryDraftSettings();
      storage.values[StorageKeys.canvasChannelPreferences] = raw;
      final container = _container(storage, 31);
      addTearDown(container.dispose);
      expect(
        container.read(canvasChannelNotifierProvider),
        const ChannelSettings(seed: 31),
      );
    });
  }

  test(
    'rapid changes write in order; a failed write does not break later saves',
    () async {
      final storage = _SlowStorage();
      final container = _container(storage, 1);
      addTearDown(container.dispose);
      final notifier = container.read(canvasChannelNotifierProvider.notifier);
      final a = notifier.set(const ChannelSettings(mode: ChannelMode.off));
      final b = notifier.set(const ChannelSettings(level: ChannelLevel.soft));
      final c = notifier.set(
        const ChannelSettings(fixed: ChannelTheme.abyss, seed: 77),
      );
      await Future<void>.delayed(Duration.zero);
      expect(storage.calls, 1);
      expect(container.read(canvasChannelNotifierProvider).seed, 77);
      storage.gate.complete();
      await Future.wait([a, b, c]);
      expect(storage.calls, 3);
      final restored = _container(storage, 2);
      addTearDown(restored.dispose);
      expect(
        restored.read(canvasChannelNotifierProvider),
        const ChannelSettings(fixed: ChannelTheme.abyss, seed: 2),
      );
    },
  );
}
