import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/macos_app_integration.dart';

Future<void> _pumpIntegration(
  WidgetTester tester, {
  required VoidCallback onOpenSettings,
  required Future<void> Function() onExitRequested,
}) {
  return tester.pumpWidget(
    MacOSAppIntegration(
      onOpenSettings: onOpenSettings,
      onExitRequested: onExitRequested,
      child: const SizedBox(),
    ),
  );
}

/// 模拟原生菜单「设置…」发来的调用
Future<void> _menuOpenSettings(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    macOSAppMenuChannel.name,
    const StandardMethodCodec().encodeMethodCall(
      const MethodCall('openSettings'),
    ),
    (_) {},
  );
}

/// 模拟系统发来的退出请求（菜单「退出」、程序坞「退出」都走这里）
Future<String?> _requestAppExit(WidgetTester tester) async {
  String? response;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.platform.name,
    const JSONMethodCodec().encodeMethodCall(
      const MethodCall('System.requestAppExit', {'type': 'cancelable'}),
    ),
    (data) {
      final result = const JSONMethodCodec().decodeEnvelope(data!);
      response = (result as Map)['response'] as String?;
    },
  );
  return response;
}

void main() {
  testWidgets('macOS：菜单「设置…」打开设置页，系统退出请求走关闭流程', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      var settingsOpened = 0;
      var shutdowns = 0;
      await _pumpIntegration(
        tester,
        onOpenSettings: () => settingsOpened++,
        onExitRequested: () async => shutdowns++,
      );

      await _menuOpenSettings(tester);
      expect(settingsOpened, 1);

      expect(await _requestAppExit(tester), 'exit');
      expect(shutdowns, 1);

      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('AppKit receives its exit reply only after cleanup finishes', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final flush = Completer<void>();
      await _pumpIntegration(
        tester,
        onOpenSettings: () {},
        onExitRequested: () => flush.future,
      );
      final exit = _requestAppExit(tester);
      String? reply;
      unawaited(exit.then((value) => reply = value));
      await tester.pump();
      expect(reply, isNull);
      flush.complete();
      expect(await exit, 'exit');
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('macOS：换成新的一份（启动页 → 主界面）后菜单照样有效', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      var splash = 0;
      var main = 0;
      await tester.pumpWidget(
        MacOSAppIntegration(
          key: const ValueKey('splash'),
          onOpenSettings: () => splash++,
          onExitRequested: () async {},
          child: const SizedBox(),
        ),
      );
      // 换 key：新的一份先 initState，旧的一份在同一帧稍后才 dispose
      await tester.pumpWidget(
        MacOSAppIntegration(
          key: const ValueKey('main'),
          onOpenSettings: () => main++,
          onExitRequested: () async {},
          child: const SizedBox(),
        ),
      );

      await _menuOpenSettings(tester);
      expect(splash, 0);
      expect(main, 1);

      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('其他平台不接这两件事', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      var settingsOpened = 0;
      var shutdowns = 0;
      await _pumpIntegration(
        tester,
        onOpenSettings: () => settingsOpened++,
        onExitRequested: () async => shutdowns++,
      );

      await _menuOpenSettings(tester);
      await _requestAppExit(tester);
      expect(settingsOpened, 0);
      expect(shutdowns, 0);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
