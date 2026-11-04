// macOS 上资源小窗开在主窗口里的浮动面板：不走 Windows 的原生子窗口（desktop_multi_window）。
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/wiring/resource_window_wiring.dart';

import '../providers/floating_resource_windows_test.dart'
    show MemoryWindowSettings;

void main() {
  test(
    'macOS opens every resource kind as a floating panel, never a native window',
    () async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(MemoryWindowSettings()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nativeResourceWindowsProvider), isFalse);
      final opener = container.read(resourceWindowOpenerProvider);
      for (final kind in FloatingResourceKind.values) {
        await opener.open(kind);
      }
      // 「新开一个窗口」在浮动面板里也是再开一个
      await opener.open(FloatingResourceKind.gallery, newWindow: true);

      expect(
        container.read(floatingResourceWindowsProvider).map((w) => w.kind),
        [...FloatingResourceKind.values, FloatingResourceKind.gallery],
      );
      // 原生资源窗口的服务没被接上
      final service = container.read(resourceWindowServiceProvider);
      expect(service.argumentsFor, isNull);
      expect(service.windows, isEmpty);
    },
    skip: !Platform.isMacOS,
  );
}
