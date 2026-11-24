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
            fixed: ChannelTheme.cumulus,
            pool: {ChannelTheme.cumulus, ChannelTheme.nimbus},
            level: ChannelLevel.standard,
            sideTransparency: 0.25,
            ruler: false,
            motion: false,
            seed: 999,
          );
      await first.read(canvasChannelNotifierProvider.notifier).set(value);
      expect(first.read(canvasChannelNotifierProvider), value);
      final saved =
          jsonDecode(box.get(StorageKeys.canvasChannelPreferences) as String)
              as Map;
      expect(saved['version'], 3);
      expect(saved['sideTransparency'], 0.25);
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
      'version': 3,
      'mode': 'future',
      'fixed': 9,
      'pool': ['pelagic', 'pelagic', 'removed'],
      'level': false,
      'sideTransparency': 'opaque',
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

  test('v1 and v2 vector settings migrate cleanly to v3 ASCII themes', () {
    final storage = MemoryDraftSettings();
    storage.values[StorageKeys.canvasChannelPreferences] = jsonEncode({
      'version': 1,
      'mode': 'fixed',
      'fixed': 'stars',
      'pool': ['stars', 'wave'],
      'level': 'standard',
      'ruler': false,
      'motion': false,
    });
    final v1 = _container(storage, 5);
    addTearDown(v1.dispose);
    expect(
      v1.read(canvasChannelNotifierProvider),
      const ChannelSettings(
        mode: ChannelMode.fixed,
        fixed: ChannelTheme.aurora,
        pool: ChannelSettings.allThemes,
        level: ChannelLevel.strong,
        ruler: false,
        motion: false,
        seed: 5,
      ),
    );

    storage.values[StorageKeys.canvasChannelPreferences] = jsonEncode({
      'version': 2,
      'mode': 'off',
      'fixed': 'circuit',
      'pool': ['stars', 'luna'],
      'level': 'soft',
    });
    final v2 = _container(storage, 8);
    addTearDown(v2.dispose);
    expect(
      v2.read(canvasChannelNotifierProvider),
      const ChannelSettings(
        mode: ChannelMode.off,
        fixed: ChannelTheme.cumulus,
        pool: ChannelSettings.allThemes,
        level: ChannelLevel.soft,
        seed: 8,
      ),
    );

    storage.values[StorageKeys.canvasChannelPreferences] = jsonEncode({
      'version': 3,
      'fixed': 'singularity',
      'pool': ['pelagic', 'singularity', 'strata'],
      'level': 'standard',
    });
    final v3 = _container(storage, 9);
    addTearDown(v3.dispose);
    expect(
      v3.read(canvasChannelNotifierProvider),
      const ChannelSettings(
        fixed: ChannelTheme.aurora,
        pool: {ChannelTheme.pelagic, ChannelTheme.aurora, ChannelTheme.strata},
        level: ChannelLevel.standard,
        seed: 9,
      ),
    );
  });

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
        const ChannelSettings(fixed: ChannelTheme.pelagic, seed: 77),
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
        const ChannelSettings(fixed: ChannelTheme.pelagic, seed: 2),
      );
    },
  );
}
