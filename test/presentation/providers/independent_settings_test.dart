import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/font_scale_provider.dart';
import 'package:nai_launcher/presentation/providers/settings_font_scale_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';

class _Storage extends LocalStorageService {
  final values = <String, dynamic>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

void main() {
  test('Anlas warning is opt-in and preserves an explicitly saved choice', () {
    expect(const ShareImageSettings().warnHighAnlasCost, isFalse);
    final storage = _Storage();
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    expect(
      container.read(shareImageSettingsProvider).warnHighAnlasCost,
      isFalse,
    );
    storage.values[StorageKeys.protectionWarnHighAnlasCost] = true;
    container.invalidate(shareImageSettingsProvider);
    expect(
      container.read(shareImageSettingsProvider).warnHighAnlasCost,
      isTrue,
    );
  });
  test(
    'settings defaults to 100 percent while workspace preferences stay intact',
    () {
      final storage = _Storage();
      expect(storage.getFontScale(), 1);
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      expect(container.read(fontScaleNotifierProvider), 1);
      expect(
        SettingsFontScaleNotifier.effectiveScale(
          container.read(settingsFontScaleProvider),
        ),
        1.0,
      );
      storage.values[StorageKeys.fontScale] = 1.1;
      expect(storage.getFontScale(), 1.1);
      storage.values[StorageKeys.fontScale] = 1.3;
      expect(storage.getFontScale(), 1.3);
      expect(container.read(settingsFontScaleProvider), 1);
      expect(storage.values.keys, [StorageKeys.fontScale]);
    },
  );
  test(
    'settings percentage persists separately and reset never rewrites global scale',
    () async {
      final storage = _Storage()..values[StorageKeys.fontScale] = 1.1;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      expect(container.read(settingsFontScaleProvider), 1);
      await container
          .read(settingsFontScaleProvider.notifier)
          .setFontScale(1.3);
      expect(container.read(settingsFontScaleProvider), closeTo(1.3, .001));
      expect(storage.values[StorageKeys.fontScale], 1.1);
      expect(
        SettingsFontScaleNotifier.effectiveScale(
          container.read(settingsFontScaleProvider),
        ),
        closeTo(1.3, .001),
      );
      await container.read(settingsFontScaleProvider.notifier).reset();
      expect(container.read(settingsFontScaleProvider), 1);
      expect(storage.getFontScale(), 1.1);
    },
  );
  test('all protection children work when the retired master is off', () {
    const settings = ShareImageSettings(
      protectionMode: false,
      warnHighAnlasCost: true,
      stripMetadataForCopyAndDrag: true,
      limitGenerationInterval: true,
      generationIntervalSeconds: 15,
      generationIntervalJitterPercent: 25,
    );
    expect(settings.effectiveStripMetadataForCopyAndDrag, isTrue);
    expect(settings.effectiveConfirmDangerousActions, isTrue);
    expect(settings.effectiveWarnExternalImageSend, isTrue);
    expect(settings.effectivePreventOverwrite, isTrue);
    expect(settings.effectiveWarnHighAnlasCost, isTrue);
    expect(settings.effectiveGenerationIntervalSeconds, 15);
    expect(settings.effectiveGenerationIntervalJitterPercent, 25);
    expect(
      settings
          .copyWith(limitGenerationInterval: false)
          .effectiveGenerationIntervalSeconds,
      0,
    );
    expect(
      settings.copyWith(warnHighAnlasCost: false).effectiveWarnHighAnlasCost,
      isFalse,
    );
  });
}
