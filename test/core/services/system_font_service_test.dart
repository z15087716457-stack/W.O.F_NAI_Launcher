import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/system_font_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  void answer(Future<Object?> Function() reply) {
    messenger.setMockMethodCallHandler(SystemFontService.channel, (call) {
      calls.add(call.method);
      return reply();
    });
  }

  setUp(calls.clear);
  tearDown(
    () => messenger.setMockMethodCallHandler(SystemFontService.channel, null),
  );

  test('reads the family names the native runner returns', () async {
    // Windows 和 macOS 的 runner 都返回字族名列表（字符串）。
    answer(() async => ['PingFang SC', 'Helvetica Neue', 'Microsoft YaHei']);

    expect(await SystemFontService().getSystemFonts(), [
      'PingFang SC',
      'Helvetica Neue',
      'Microsoft YaHei',
    ]);
    expect(calls, ['getSystemFonts']);
  });

  test('a runner without the channel gives an empty list', () async {
    answer(() async => throw MissingPluginException());

    expect(await SystemFontService().getSystemFonts(), isEmpty);
  });

  test('a malformed reply gives an empty list', () async {
    answer(() async => null);
    expect(await SystemFontService().getSystemFonts(), isEmpty);

    answer(() async => [1, 2]);
    expect(await SystemFontService().getSystemFonts(), isEmpty);
  });

  test('the provider sorts families case-insensitively', () async {
    answer(() async => ['helvetica', 'Arial', 'PingFang SC']);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(systemFontsProvider.future), [
      'Arial',
      'helvetica',
      'PingFang SC',
    ]);
  });

  test('both desktop runners answer the same channel and method', () {
    for (final runner in [
      'windows/runner/flutter_window.cpp',
      'macos/Runner/MainFlutterWindow.swift',
    ]) {
      final source = File(runner).readAsStringSync();
      expect(source, contains('"${SystemFontService.channel.name}"'));
      expect(source, contains('"${SystemFontService.getSystemFontsMethod}"'));
    }
  });
}
