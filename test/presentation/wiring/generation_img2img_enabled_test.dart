import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';

class EnabledStorage extends LocalStorageService {
  bool stored = true;
  final calls = <bool>[];
  Completer<void>? pending;
  bool failNext = false;
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      key == StorageKeys.generationImg2ImgEnabled ? stored as T : defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    calls.add(value as bool);
    await pending?.future;
    if (failNext) {
      failNext = false;
      throw StateError('test persistence failure');
    }
    stored = value;
  }
}

void main() {
  test('开关先即刻更新请求状态，持久化严格按操作顺序写入', () async {
    final storage = EnabledStorage()..pending = Completer<void>();
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final flag = container.read(generationImg2ImgEnabledProvider.notifier);
    flag.set(false);
    flag.set(true);
    expect(container.read(generationImg2ImgEnabledProvider), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(storage.calls, [false]);
    storage.pending!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(storage.calls, [false, true]);
    expect(storage.stored, isTrue);
  });
  test('一次保存失败不污染后续操作，停用偏好可重新读取', () async {
    final storage = EnabledStorage()..failNext = true;
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    final flag = container.read(generationImg2ImgEnabledProvider.notifier);
    flag.set(false);
    flag.set(true);
    flag.set(false);
    await Future<void>.delayed(Duration.zero);
    expect(storage.calls, [false, true, false]);
    expect(storage.stored, isFalse);
    container.dispose();
    final restored = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(restored.dispose);
    expect(restored.read(generationImg2ImgEnabledProvider), isFalse);
  });
}
