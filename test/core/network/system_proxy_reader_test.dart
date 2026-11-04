import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/proxy_service.dart';
import 'package:nai_launcher/core/network/system_proxy_reader.dart';
import 'package:nai_launcher/core/network/windows_proxy_helper.dart';

import '../../helpers/system_proxy_stand_ins.dart';

/// Starts [read] next to a 50 ms timer on this isolate and records which
/// finishes first. A read that runs on this isolate holds the timer back.
Future<({String? value, List<String> order, int handBackMs})> _race(
  Future<String?> Function() read,
) async {
  final order = <String>[];
  final frame = Timer(
    const Duration(milliseconds: 50),
    () => order.add('frame'),
  );
  final watch = Stopwatch()..start();
  final pending = read().then((value) {
    order.add('read');
    return value;
  });
  final handBackMs = watch.elapsedMilliseconds;
  final value = await pending;
  frame.cancel();
  return (value: value, order: order, handBackMs: handBackMs);
}

const _platforms = [SystemProxyPlatform.macOS, SystemProxyPlatform.windows];

void main() {
  for (final platform in _platforms) {
    group('${platform.name}:', () {
      late SystemProxyStandIn system;
      setUp(() => system = SystemProxyStandIn(platform));

      test('a slow system answer leaves this isolate free', () async {
        system.delay = const Duration(milliseconds: 400);
        final race = await _race(system.reader().read);
        expect(race.value, '127.0.0.1:7890');
        expect(race.handBackMs, lessThan(100));
        expect(race.order, ['frame', 'read']);
      });

      test('the proxy off reads as none', () async {
        system.address = null;
        expect(await system.reader().read(), isNull);
      });

      test('a failed read shows no proxy instead of an error', () async {
        system.fails = true;
        expect(await system.reader().read(), isNull);
      });
    });
  }

  group('macOS:', () {
    test('only an enabled HTTP proxy with host and port counts', () {
      for (final entry in {
        scutilProxyOutput('127.0.0.1:7890'): '127.0.0.1:7890',
        scutilProxyOutput('proxy.lan:3128'): 'proxy.lan:3128',
        scutilProxyOutput(null): null,
        '<dictionary> {\n  HTTPEnable : 1\n  HTTPProxy : 127.0.0.1\n}\n': null,
        '<dictionary> {\n  HTTPEnable : 1\n  HTTPPort : 7890\n}\n': null,
        '<dictionary> {\n}\n': null,
      }.entries) {
        expect(
          ProxyService.macOSProxyFrom(ProcessResult(1, 0, entry.key, '')),
          entry.value,
          reason: entry.key,
        );
      }
      expect(
        ProxyService.macOSProxyFrom(
          ProcessResult(1, 1, scutilProxyOutput('127.0.0.1:7890'), 'error'),
        ),
        isNull,
      );
    });

    test('scutil that cannot be started shows no proxy', () async {
      final reader = SystemProxyReader(
        platform: SystemProxyPlatform.macOS,
        scutil: () => SystemProxyReader.runCommand(
          '/nonexistent/scutil-${DateTime.now().microsecondsSinceEpoch}',
          const ['--proxy'],
        ),
      );
      expect(await reader.read(), isNull);
    });

    group('a real child process standing in for scutil', () {
      late Directory dir;
      setUp(() => dir = Directory.systemTemp.createTempSync('system-proxy-'));
      tearDown(() => dir.deleteSync(recursive: true));

      test('runs without holding up this isolate', () async {
        final output = File('${dir.path}/scutil.txt')
          ..writeAsStringSync(scutilProxyOutput('127.0.0.1:7897'));
        final reader = SystemProxyReader(
          platform: SystemProxyPlatform.macOS,
          scutil: () => SystemProxyReader.runCommand('/bin/sh', [
            '-c',
            'sleep 0.4; cat "\$0"',
            output.path,
          ]),
        );
        final race = await _race(reader.read);
        expect(race.value, '127.0.0.1:7897');
        expect(race.handBackMs, lessThan(100));
        expect(race.order, ['frame', 'read']);
      });

      test('one that hangs is stopped after the timeout', () async {
        final stopped = File('${dir.path}/stopped');
        final watch = Stopwatch()..start();
        await expectLater(
          SystemProxyReader.runCommand('/bin/sh', [
            '-c',
            'trap \'echo stopped > "\$0"; kill \$! 2>/dev/null; exit 143\' '
                'TERM; sleep 30 & wait',
            stopped.path,
          ], timeout: const Duration(milliseconds: 300)),
          throwsA(isA<TimeoutException>()),
        );
        expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
        for (var i = 0; i < 50 && !stopped.existsSync(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(stopped.readAsStringSync().trim(), 'stopped');
      });

      test('the reader gives up on a hanging scutil and shows none', () async {
        final reader = SystemProxyReader(
          platform: SystemProxyPlatform.macOS,
          scutil: () => SystemProxyReader.runCommand('/bin/sh', const [
            '-c',
            'exec sleep 30',
          ], timeout: const Duration(milliseconds: 300)),
        );
        final watch = Stopwatch()..start();
        expect(await reader.read(), isNull);
        expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
      });
    }, skip: Platform.isWindows ? 'needs a POSIX shell' : false);

    test(
      'on this Mac the reader the app builds reads the macOS setting and finds '
      'what the synchronous lookup finds',
      () async {
        // Built as the app builds it: platform from the host, real scutil.
        final reader = SystemProxyReader();
        expect(reader.platform, SystemProxyPlatform.macOS);
        expect(await reader.read(), ProxyService.getSystemProxyAddress());
      },
      skip: Platform.isMacOS ? false : 'reads the real macOS setting',
    );
  });

  group('Windows:', () {
    test('ProxyServer is read the way the registry helper reads it', () async {
      final registry = WindowsRegistryStandIn();
      final reader = registry.reader();
      for (final entry in <(int?, String?), String?>{
        (1, '127.0.0.1:7890'): '127.0.0.1:7890',
        (1, ' 127.0.0.1:7890 '): '127.0.0.1:7890',
        (1, 'http=127.0.0.1:7890;https=127.0.0.1:7891'): '127.0.0.1:7890',
        (1, 'https=127.0.0.1:7891;socks=127.0.0.1:1080'): '127.0.0.1:7891',
        (1, 'socks=127.0.0.1:1080'): '127.0.0.1:1080',
        (1, 'ftp=127.0.0.1:21'): null,
        (1, ''): null,
        (1, null): null,
        (0, '127.0.0.1:7890'): null,
        (null, '127.0.0.1:7890'): null,
      }.entries) {
        registry.set(enable: entry.key.$1, server: entry.key.$2);
        final expected = ProxyService.addressFromWindowsProxy(
          WindowsProxyHelper.proxyFromRegistryValues((
            enable: entry.key.$1,
            server: entry.key.$1 == 1 ? entry.key.$2 : null,
          )),
        );
        expect(expected, entry.value, reason: '${entry.key}');
        expect(await reader.read(), entry.value, reason: '${entry.key}');
      }
    });

    test(
      'on this PC the reader the app builds reads the registry and finds what '
      'the synchronous lookup finds',
      () async {
        // Built as the app builds it: platform from the host, real registry.
        final reader = SystemProxyReader();
        expect(reader.platform, SystemProxyPlatform.windows);
        expect(await reader.read(), ProxyService.getSystemProxyAddress());
      },
      skip: Platform.isWindows ? false : 'reads the real Windows registry',
    );
  });

  test(
    'elsewhere the reader the app builds reads nothing',
    () => expect(SystemProxyReader().platform, SystemProxyPlatform.other),
    skip: Platform.isMacOS || Platform.isWindows
        ? 'only on systems without a proxy reader'
        : false,
  );

  test('other systems have no proxy to read', () async {
    final reader = SystemProxyReader(
      platform: SystemProxyPlatform.other,
      scutil: () async =>
          ProcessResult(1, 0, scutilProxyOutput('127.0.0.1:7890'), ''),
      registry: () => (enable: 1, server: '127.0.0.1:7890'),
    );
    expect(await reader.read(), isNull);
  });

  group('SystemProxyCache', () {
    late DateTime now;
    late List<Completer<String?>> reads;
    late SystemProxyCache cache;
    setUp(() {
      now = DateTime(2026, 10, 30, 12);
      reads = [];
      cache = SystemProxyCache(() {
        final read = Completer<String?>();
        reads.add(read);
        return read.future;
      }, now: () => now);
    });

    test('a value read in the last 30 s comes back at once', () async {
      final first = cache.read();
      expect(first, isA<Future<String?>>());
      reads.single.complete('127.0.0.1:7890');
      expect(await first, '127.0.0.1:7890');
      now = now.add(const Duration(seconds: 29, milliseconds: 999));
      expect(cache.read(), '127.0.0.1:7890');
      expect(reads, hasLength(1));
    });

    test('once 30 s have passed it reads again', () async {
      final first = cache.read();
      reads.single.complete('127.0.0.1:7890');
      await first;
      now = now.add(const Duration(seconds: 30));
      final second = cache.read();
      expect(second, isA<Future<String?>>());
      expect(reads, hasLength(2));
      reads.last.complete('127.0.0.1:7897');
      expect(await second, '127.0.0.1:7897');
      expect(cache.read(), '127.0.0.1:7897');
      expect(reads, hasLength(2));
    });

    test('a clock set back reads again instead of keeping the value', () async {
      final first = cache.read();
      reads.single.complete('127.0.0.1:7890');
      await first;
      // Set back by hand, an NTP step or a restored VM snapshot: the age of
      // the result comes out negative, which is not "less than 30 s old".
      now = now.subtract(const Duration(hours: 1));
      final second = cache.read();
      expect(second, isA<Future<String?>>());
      expect(reads, hasLength(2));
      reads.last.complete(null);
      expect(await second, isNull);
    });

    test('no proxy is remembered like an address', () async {
      final first = cache.read();
      reads.single.complete(null);
      expect(await first, isNull);
      expect(cache.read(), isNull);
      expect(reads, hasLength(1));
    });

    test('asking again during a read shares that read', () async {
      final first = cache.read();
      final second = cache.read();
      expect(identical(first, second), isTrue);
      expect(reads, hasLength(1));
      reads.single.complete('127.0.0.1:7890');
      expect(await second, '127.0.0.1:7890');
    });

    test('a different scope reads again at once', () async {
      const before = 'proxy auto';
      const after = 'proxy manual';
      final first = cache.read(scope: before);
      reads.single.complete('127.0.0.1:7890');
      await first;
      final second = cache.read(scope: after);
      expect(second, isA<Future<String?>>());
      expect(reads, hasLength(2));
      reads.last.complete('127.0.0.1:7897');
      expect(await second, '127.0.0.1:7897');
      expect(cache.read(scope: after), '127.0.0.1:7897');
      expect(reads, hasLength(2));
    });

    test('a read for an old scope does not replace the newer one', () async {
      final old = cache.read(scope: 'before');
      final current = cache.read(scope: 'after');
      expect(reads, hasLength(2));
      reads.last.complete('127.0.0.1:7897');
      await current;
      reads.first.complete('127.0.0.1:7890');
      await old;
      expect(cache.read(scope: 'after'), '127.0.0.1:7897');
      expect(reads, hasLength(2));
    });

    test('a failed read is not kept: the next one tries again', () async {
      final first = cache.read();
      reads.single.completeError(StateError('scutil vanished'));
      await expectLater(first, throwsStateError);
      final second = cache.read();
      expect(second, isA<Future<String?>>());
      expect(reads, hasLength(2));
      reads.last.complete('127.0.0.1:7890');
      expect(await second, '127.0.0.1:7890');
    });
  });
}
