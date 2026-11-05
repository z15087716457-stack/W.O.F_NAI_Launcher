import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Visibility of the main window, shared by drawing and view-owned polling.
class AppVisibility extends ValueNotifier<bool>
    with WindowListener, WidgetsBindingObserver {
  AppVisibility() : super(true);

  static final instance = AppVisibility();

  bool _hidden = false;
  bool _minimized = false;
  bool _lifecycleHidden = false;

  void attach() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    if (Platform.isWindows) windowManager.addListener(this);
    final lifecycle = binding.lifecycleState;
    if (lifecycle != null) didChangeAppLifecycleState(lifecycle);
  }

  @override
  void onWindowEvent(String eventName) {
    switch (eventName) {
      case 'hide':
        _hidden = true;
      case 'show':
        _hidden = false;
      case 'minimize':
        _minimized = true;
      // A maximized window can emit maximize instead of restore.
      case 'restore' || 'maximize':
        _minimized = false;
    }
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleHidden =
        state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    _update();
  }

  void _update() => value = !(_hidden || _minimized || _lifecycleHidden);
}
