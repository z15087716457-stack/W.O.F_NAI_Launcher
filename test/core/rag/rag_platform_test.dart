import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_platform.dart';
import 'package:nai_launcher/core/rag/rag_runtime.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:path/path.dart' as p;

void main() {
  test('the host is read from the machine running the tests', () {
    expect(RagPlatform.host == RagPlatform.windows, Platform.isWindows);
    expect(RagPlatform.host.isMacOS, Platform.isMacOS);
  });

  test('managed interpreters follow the uv venv layout of each system', () {
    final root = p.join('data', 'rag', 'v1');
    expect(
      RagPlatform.windows.managedPython(root),
      p.join(root, 'runtime', 'Scripts', 'python.exe'),
    );
    for (final mac in [RagPlatform.macOSArm64, RagPlatform.macOSX64]) {
      expect(mac.isMacOS, isTrue);
      expect(
        mac.managedPython(root),
        p.join(root, 'runtime', 'bin', 'python3'),
      );
    }
  });

  test('Windows sends the chosen device as it is, whatever the memory', () {
    expect(RagPlatform.windows.supportsCuda, isTrue);
    for (final device in RagDevice.values) {
      for (final memory in [null, 8 << 30, 96 << 30]) {
        expect(
          RagSettings(
            device: device,
          ).deviceOn(RagPlatform.windows, memoryBytes: memory),
          device,
        );
      }
    }
  });

  test('a Mac runs auto on the GPU only with 18 GB of memory or more', () {
    expect(RagPlatform.macOSArm64.supportsCuda, isFalse);
    expect(RagPlatform.macOSX64.supportsCuda, isFalse);
    RagDevice on(RagDevice device, int? memory) => RagSettings(
      device: device,
    ).deviceOn(RagPlatform.macOSArm64, memoryBytes: memory);
    for (final (memory, expected) in [
      (8 << 30, RagDevice.cpu),
      (16 << 30, RagDevice.cpu),
      (null, RagDevice.cpu),
      (18 << 30, RagDevice.auto),
      (24 << 30, RagDevice.auto),
      (96 << 30, RagDevice.auto),
    ]) {
      expect(on(RagDevice.auto, memory), expected, reason: '$memory');
      // No CUDA on a Mac: a saved cuda follows the same rule as auto.
      expect(on(RagDevice.cuda, memory), expected, reason: '$memory');
      // A device chosen by hand is never moved.
      expect(on(RagDevice.cpu, memory), RagDevice.cpu);
    }
  });

  test('reads the memory of this Mac and nothing elsewhere', () async {
    final memory = readMacPhysicalMemory();
    if (!Platform.isMacOS) {
      expect(memory, isNull);
      return;
    }
    final sysctl = await Process.run('/usr/sbin/sysctl', ['-n', 'hw.memsize']);
    expect(memory, int.parse('${sysctl.stdout}'.trim()));
  });

  test('uv is pinned per platform; Intel Macs have no runtime', () {
    final windows = RagRuntimeInstaller.uvFor(RagPlatform.windows)!;
    expect(
      windows.url,
      'https://github.com/astral-sh/uv/releases/download/0.13.1/uv-x86_64-pc-windows-msvc.zip',
    );
    expect(
      windows.sha256,
      '3b2661a463a5baea7f5076ea2b25ab71d77f36a6c0d809e5350651792f80a672',
    );
    expect((windows.entry, windows.file), ('uv.exe', 'uv-0.13.1.exe'));
    final mac = RagRuntimeInstaller.uvFor(RagPlatform.macOSArm64)!;
    expect(
      mac.url,
      'https://github.com/astral-sh/uv/releases/download/0.13.1/uv-aarch64-apple-darwin.tar.gz',
    );
    expect(
      mac.sha256,
      'cfe454573412ff7380d15fc7dae5997ab53ffce72fce0a78e91ddbc84001acd2',
    );
    expect((mac.entry, mac.file), ('uv', 'uv-0.13.1'));
    expect(RagRuntimeInstaller.uvFor(RagPlatform.macOSX64), isNull);
    expect(RagRuntimeInstaller.uvFor(RagPlatform.other), isNull);
  });
}
