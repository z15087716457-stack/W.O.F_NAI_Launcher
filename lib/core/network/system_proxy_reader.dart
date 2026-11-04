import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';
import 'proxy_service.dart';
import 'windows_proxy_helper.dart';

/// 读哪个系统的代理设置。正式运行用 [host]；测试传另一个，Mac 和 Windows 两条路在哪台机器上都能跑。
enum SystemProxyPlatform {
  macOS,
  windows,
  other;

  static final SystemProxyPlatform host = Platform.isMacOS
      ? macOS
      : Platform.isWindows
      ? windows
      : other;
}

/// 跑一次 `scutil --proxy`，给出它的退出码和输出。在后台 isolate 里调用。
typedef ScutilProxyCommand = Future<ProcessResult> Function();

/// 读系统代理（"host:port"，没有就是 null），不占调用它的线程。
///
/// [ProxyService.getSystemProxyAddress] 是同步的：macOS 上用 `Process.runSync` 等 `scutil --proxy`
/// 跑完，Windows 上当场查注册表，界面线程这期间停着。这里两边都把找系统要设置的那一步放进后台
/// isolate（macOS 起 scutil 子进程并等它结束，Windows 查注册表），解析和日志回到调用方这边，
/// 和同步版共用，读到的结果一样、日志照样进日志文件。
class SystemProxyReader {
  SystemProxyReader({
    SystemProxyPlatform? platform,
    ScutilProxyCommand? scutil,
    WindowsProxyRegistryRead? registry,
  }) : platform = platform ?? SystemProxyPlatform.host,
       _scutil = scutil ?? _runScutil,
       _registry = registry ?? WindowsProxyHelper.readRegistryValues;

  final SystemProxyPlatform platform;
  final ScutilProxyCommand _scutil;
  final WindowsProxyRegistryRead _registry;

  /// `scutil` 卡住时最多等这么久，到时结束它，当作没读到代理。
  static const commandTimeout = Duration(seconds: 5);

  /// 读不到（命令失败、注册表打不开）时和同步版一样记日志，给 null。
  Future<String?> read() => switch (platform) {
    SystemProxyPlatform.macOS => _readMacOS(),
    SystemProxyPlatform.windows => _readWindows(),
    SystemProxyPlatform.other => Future.value(),
  };

  Future<String?> _readMacOS() async {
    // 起子进程时 fork 是同步的，也放进后台 isolate：界面线程既不等 scutil 跑完，也不等 fork。
    final scutil = _scutil;
    try {
      final result = await Isolate.run(scutil, debugName: 'system-proxy');
      return ProxyService.macOSProxyFrom(result);
    } catch (e) {
      AppLogger.w('Failed to read macOS proxy: $e', 'PROXY');
      return null;
    }
  }

  Future<String?> _readWindows() async {
    final registry = _registry;
    try {
      final values = await Isolate.run(registry, debugName: 'system-proxy');
      return ProxyService.addressFromWindowsProxy(
        WindowsProxyHelper.proxyFromRegistryValues(values),
      );
    } catch (e, stackTrace) {
      WindowsProxyHelper.logReadFailure(e, stackTrace);
      return null;
    }
  }

  static Future<ProcessResult> _runScutil() =>
      runCommand('scutil', const ['--proxy']);

  /// 起一个子进程，异步等它结束并收下输出（按系统编码解码，和 `Process.runSync` 默认一样）。
  /// 超过 [timeout] 还没结束就结束它，抛 [TimeoutException]。
  @visibleForTesting
  static Future<ProcessResult> runCommand(
    String executable,
    List<String> arguments, {
    Duration timeout = commandTimeout,
  }) async {
    final process = await Process.start(executable, arguments);
    // 和 Process.run 一样不给输入。
    process.stdin.close().ignore();
    final stdout = process.stdout.transform(systemEncoding.decoder).join();
    final stderr = process.stderr.transform(systemEncoding.decoder).join();
    final int exitCode;
    try {
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      process.kill();
      stdout.ignore();
      stderr.ignore();
      rethrow;
    }
    return ProcessResult(process.pid, exitCode, await stdout, await stderr);
  }
}

/// 设置页显示的系统代理：读一次要起子进程（macOS）或查注册表（Windows），设置页每次打开都要显示它。
///
/// [maxAge] 内读过就直接给上次的结果；正在读就共用那一次；[read] 的 `scope`
/// 变了（比如代理设置改了）就不用旧结果、马上重读。
///
/// [SystemProxyReader] 读不到时给 null，和「没有系统代理」一样记下；只有读取本身报错才不留，下次再读。
class SystemProxyCache {
  SystemProxyCache(
    this._read, {
    DateTime Function()? now,
    this.maxAge = const Duration(seconds: 30),
  }) : _now = now ?? DateTime.now;

  final Future<String?> Function() _read;
  final DateTime Function() _now;

  /// 结果用多久。系统代理变了，最晚这么久以后再打开设置页就能看到。
  final Duration maxAge;

  _SystemProxyResult? _last;
  _SystemProxyRead? _pending;

  /// 有能用的结果时直接返回值（不是 Future），否则返回这次（或正在进行的那次）读取。
  FutureOr<String?> read({Object? scope}) {
    final last = _last;
    if (last != null && last.scope == scope) {
      // 系统时间往回调过（手动改、NTP 校时、虚拟机快照恢复）时差值是负的，也算过期。
      final age = _now().difference(last.at);
      if (!age.isNegative && age < maxAge) return last.value;
    }
    final pending = _pending;
    if (pending != null && pending.scope == scope) return pending.future;

    final at = _now();
    final read = _SystemProxyRead(Future.sync(_read), scope);
    _pending = read;
    read.future.then(
      (value) {
        if (!identical(_pending, read)) return;
        _pending = null;
        _last = _SystemProxyResult(value, at, scope);
      },
      onError: (Object _) {
        if (identical(_pending, read)) _pending = null;
      },
    );
    return read.future;
  }
}

class _SystemProxyResult {
  const _SystemProxyResult(this.value, this.at, this.scope);
  final String? value;

  /// 开始读的时间：结果不会比它更新。
  final DateTime at;
  final Object? scope;
}

class _SystemProxyRead {
  _SystemProxyRead(this.future, this.scope);
  final Future<String?> future;
  final Object? scope;
}
