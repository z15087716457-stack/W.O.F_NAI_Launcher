import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/services/notification_service.dart';
import '../../core/storage/local_storage_service.dart';
import 'image_generation_provider.dart';

part 'notification_settings_provider.g.dart';

/// 音效设置状态
class NotificationSettings {
  final bool soundEnabled;
  final String? customSoundPath;

  const NotificationSettings({this.soundEnabled = true, this.customSoundPath});

  NotificationSettings copyWith({
    bool? soundEnabled,
    String? customSoundPath,
    bool clearCustomSound = false,
  }) {
    return NotificationSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      customSoundPath: clearCustomSound
          ? null
          : (customSoundPath ?? this.customSoundPath),
    );
  }
}

/// 音效设置 Provider
@Riverpod(keepAlive: true)
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  @override
  NotificationSettings build() {
    final storage = ref.read(localStorageServiceProvider);
    return NotificationSettings(
      soundEnabled:
          storage.getSetting<bool>(
            StorageKeys.notificationSoundEnabled,
            defaultValue: true,
          ) ??
          true,
      customSoundPath: storage.getSetting<String>(
        StorageKeys.notificationCustomSoundPath,
      ),
    );
  }

  /// 设置音效开关
  Future<void> setSoundEnabled(bool value) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setSetting(StorageKeys.notificationSoundEnabled, value);
    state = state.copyWith(soundEnabled: value);
  }

  /// 设置自定义音效路径
  Future<void> setCustomSoundPath(String? path) async {
    final storage = ref.read(localStorageServiceProvider);
    if (path != null) {
      await storage.setSetting(StorageKeys.notificationCustomSoundPath, path);
      state = state.copyWith(customSoundPath: path);
    } else {
      await storage.deleteSetting(StorageKeys.notificationCustomSoundPath);
      state = state.copyWith(clearCustomSound: true);
    }
  }
}

/// 生成完成音效监听器
///
/// 监听生成状态从 generating 变为 completed 时播放完成音效
/// （原由 QueueExecutionNotifier 托管，队列功能移除后独立常驻）
@Riverpod(keepAlive: true)
class GenerationCompletionWatcher extends _$GenerationCompletionWatcher {
  @override
  void build() {
    ref.listen<ImageGenerationState>(imageGenerationNotifierProvider, (
      previous,
      next,
    ) {
      if (previous?.status == GenerationStatus.generating &&
          next.status == GenerationStatus.completed) {
        _notifyGenerationComplete();
      }
    });
  }

  void _notifyGenerationComplete() {
    final settings = ref.read(notificationSettingsNotifierProvider);
    if (!settings.soundEnabled) return;

    Future.microtask(() async {
      await NotificationService.instance.notifyGenerationComplete(
        playSound: settings.soundEnabled,
        customSoundPath: settings.customSoundPath,
      );
    });
  }
}
