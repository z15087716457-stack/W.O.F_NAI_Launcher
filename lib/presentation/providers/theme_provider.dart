import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';
import '../themes/app_theme.dart';
import 'font_provider.dart';

part 'theme_provider.g.dart';

final studioSystemBrightnessProvider =
    NotifierProvider<StudioSystemBrightness, Brightness>(
      StudioSystemBrightness.new,
    );

class StudioSystemBrightness extends Notifier<Brightness>
    with WidgetsBindingObserver {
  @override
  Brightness build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    state = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}

/// One persisted appearance for bootstrap, login and every workspace route.
/// Keep it alive while the bootstrap MaterialApp is replaced by the router.
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Brightness build() {
    final storage = ref.read(localStorageServiceProvider);
    final mode = storage.getStudioThemeMode();
    if (mode == 'system') return ref.watch(studioSystemBrightnessProvider);
    return mode == 'light' ? Brightness.light : Brightness.dark;
  }

  /// 设置主题
  Future<void> setTheme(Brightness brightness) async {
    state = brightness;

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setStudioThemeMode(brightness.name);
  }

  Future<void> setMode(String mode) async {
    if (!const ['light', 'dark', 'system'].contains(mode)) {
      throw ArgumentError.value(mode, 'mode');
    }
    await ref.read(localStorageServiceProvider).setStudioThemeMode(mode);
    ref.invalidateSelf();
  }

  /// 深浅切换；旧风格索引保留在存储中，不再用于主界面。
  Future<void> nextTheme() async {
    await setTheme(
      state == Brightness.dark ? Brightness.light : Brightness.dark,
    );
  }
}

final studioLightThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.getTheme(
    AppStyle.geist,
    Brightness.light,
    fontConfig: ref.watch(fontNotifierProvider),
  ),
);
final studioDarkThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.getTheme(
    AppStyle.geist,
    Brightness.dark,
    fontConfig: ref.watch(fontNotifierProvider),
  ),
);
