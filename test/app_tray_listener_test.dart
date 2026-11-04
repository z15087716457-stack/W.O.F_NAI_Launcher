// 退出期间不响应托盘或菜单栏图标，避免窗口被重新打开。
// 最小化的窗口两个平台都由 windowManager.show() 先恢复（它自己先问 isMinimized）。
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/main.dart' show AppTrayListener;
import 'package:tray_manager/tray_manager.dart';

import 'helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  final calls = <String>[];
  var minimized = false;
  const channels = [
    'window_manager',
    'tray_manager',
    'com.nailauncher/window_control',
  ];

  setUp(() {
    calls.clear();
    minimized = false;
    for (final channel in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (call) async {
            if (channel == 'com.nailauncher/window_control') return null;
            calls.add(call.method);
            return call.method == 'isMinimized' ? minimized : null;
          });
    }
  });

  tearDown(() {
    for (final channel in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  Future<void> clickAll(AppTrayListener listener) async {
    await listener.onTrayIconMouseDown();
    listener.onTrayIconRightMouseDown();
    await listener.onTrayMenuItemClick(MenuItem(key: 'show', label: 'Show'));
  }

  test('tray actions are ignored while the desktop app is quitting', () async {
    await clickAll(AppTrayListener(shuttingDown: () => true));
    expect(calls, isEmpty);
  });

  test('show restores a minimized window first', () async {
    minimized = true;
    await AppTrayListener(shuttingDown: () => false).onTrayIconMouseDown();
    expect(calls, ['isMinimized', 'restore', 'show', 'focus']);
  });
}
