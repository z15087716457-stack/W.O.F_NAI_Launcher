import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/network/proxy_service.dart';
import 'package:nai_launcher/core/network/system_proxy_reader.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/settings/proxy_settings.dart';
import 'package:nai_launcher/presentation/providers/proxy_settings_provider.dart';

import '../../helpers/system_proxy_stand_ins.dart';

class _Storage extends LocalStorageService {
  _Storage(this.values);
  final Map<String, Object?> values;

  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values.containsKey(key) ? values[key] as T? : defaultValue;

  @override
  Future<void> setSetting<T>(String key, T value) async => values[key] = value;

  @override
  Future<void> deleteSetting(String key) async => values.remove(key);
}

/// The settings page reads the detected system proxy for as long as it is
/// open (`settingsViewData` watches it on every page) and is rebuilt each
/// time it opens. These tests open and close it the same way.
void main() {
  test('what was read outlives the settings page', () async {
    // Nothing is read here: the real reader only asks the system on read().
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final page = container.listen(systemProxyCacheProvider, (_, __) {});
    final cache = page.read();
    page.close();
    await container.pump();
    expect(container.read(systemProxyCacheProvider), same(cache));
  });

  ProviderContainer settingsWith(List<Override> overrides) {
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(
          _Storage({
            StorageKeys.proxyEnabled: true,
            StorageKeys.proxyMode: 'auto',
          }),
        ),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'on this machine the settings page shows what the synchronous lookup '
    'finds, through the reader the app builds',
    () async {
      final container = settingsWith(const []);
      final reader = container.read(systemProxyReaderProvider);
      expect(
        reader.platform,
        Platform.isMacOS
            ? SystemProxyPlatform.macOS
            : SystemProxyPlatform.windows,
      );
      expect(
        await container.read(detectedSystemProxyProvider.future),
        ProxyService.getSystemProxyAddress(),
      );
    },
    skip: Platform.isMacOS || Platform.isWindows
        ? false
        : 'reads the real macOS or Windows setting',
  );

  for (final platform in [
    SystemProxyPlatform.macOS,
    SystemProxyPlatform.windows,
  ]) {
    test('${platform.name}: what the settings page shows comes from the '
        'reader', () async {
      final system = SystemProxyStandIn(platform)..address = '127.0.0.1:7891';
      final container = settingsWith([
        systemProxyReaderProvider.overrideWithValue(system.reader()),
      ]);
      expect(
        await container.read(detectedSystemProxyProvider.future),
        '127.0.0.1:7891',
      );
    });
  }

  for (final platform in [
    SystemProxyPlatform.macOS,
    SystemProxyPlatform.windows,
  ]) {
    group('${platform.name}:', () {
      late SystemProxyStandIn system;
      late DateTime now;
      late int reads;
      late ProviderContainer container;

      setUp(() {
        system = SystemProxyStandIn(platform);
        now = DateTime(2026, 10, 30, 12);
        reads = 0;
        final reader = system.reader();
        container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(
              _Storage({
                StorageKeys.proxyEnabled: true,
                StorageKeys.proxyMode: 'auto',
              }),
            ),
            systemProxyCacheProvider.overrideWithValue(
              SystemProxyCache(() {
                reads++;
                return reader.read();
              }, now: () => now),
            ),
          ],
        );
      });
      tearDown(() => container.dispose());

      ProviderSubscription<AsyncValue<String?>> open() =>
          container.listen(detectedSystemProxyProvider, (_, __) {});

      Future<void> close(ProviderSubscription<Object?> page) async {
        page.close();
        await container.pump();
      }

      Future<String?> shown() =>
          container.read(detectedSystemProxyProvider.future);

      test('opening settings does not wait for the read', () async {
        system.delay = const Duration(milliseconds: 400);
        final watch = Stopwatch()..start();
        final page = open();
        expect(watch.elapsedMilliseconds, lessThan(100));
        expect(page.read(), isA<AsyncLoading<String?>>());
        expect(page.read().valueOrNull, isNull);
        expect(await shown(), '127.0.0.1:7890');
        expect(page.read(), isA<AsyncData<String?>>());
        expect(page.read().value, '127.0.0.1:7890');
        expect(reads, 1);
      });

      test('reopening within 30 s shows the last result at once', () async {
        final first = open();
        await shown();
        await close(first);
        now = now.add(const Duration(seconds: 29));
        system.address = '127.0.0.1:7897';
        final again = open();
        expect(again.read(), isA<AsyncData<String?>>());
        expect(again.read().value, '127.0.0.1:7890');
        expect(reads, 1);
      });

      test('reopening after 30 s reads again and shows the change', () async {
        final first = open();
        await shown();
        await close(first);
        now = now.add(const Duration(seconds: 30));
        system.address = '127.0.0.1:7897';
        final again = open();
        expect(again.read().isLoading, isTrue);
        expect(await shown(), '127.0.0.1:7897');
        expect(again.read().value, '127.0.0.1:7897');
        expect(reads, 2);
      });

      test('no system proxy is remembered the same way', () async {
        system.address = null;
        final first = open();
        expect(await shown(), isNull);
        await close(first);
        now = now.add(const Duration(seconds: 10));
        final again = open();
        expect(again.read(), isA<AsyncData<String?>>());
        expect(again.read().value, isNull);
        expect(reads, 1);
      });

      test('changing the proxy settings reads again at once, the old result '
          'staying on screen meanwhile', () async {
        final page = open();
        await shown();
        system.address = '127.0.0.1:7897';
        system.delay = const Duration(milliseconds: 200);
        await container
            .read(proxySettingsNotifierProvider.notifier)
            .setMode(ProxyMode.manual);
        await container.pump();
        final during = page.read();
        expect(during.isLoading, isTrue);
        expect(during.valueOrNull, '127.0.0.1:7890');
        expect(await shown(), '127.0.0.1:7897');
        expect(page.read().value, '127.0.0.1:7897');
        expect(reads, 2);

        await container
            .read(proxySettingsNotifierProvider.notifier)
            .setEnabled(false);
        await container.pump();
        expect(await shown(), '127.0.0.1:7897');
        expect(reads, 3);
      });

      test('a failed read shows no proxy, read again after 30 s', () async {
        system.fails = true;
        final first = open();
        expect(await shown(), isNull);
        await close(first);
        system.fails = false;
        now = now.add(const Duration(seconds: 30));
        final again = open();
        expect(again.read().isLoading, isTrue);
        expect(await shown(), '127.0.0.1:7890');
        expect(reads, 2);
      });
    });
  }
}
