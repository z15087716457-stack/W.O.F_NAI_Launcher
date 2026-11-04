import 'dart:io';

import 'package:nai_launcher/core/network/system_proxy_reader.dart';
import 'package:nai_launcher/core/network/windows_proxy_helper.dart';

/// What `scutil --proxy` prints on a Mac whose HTTP proxy is [address]
/// (`host:port`), or with the proxy off when it is null. Shaped like the
/// output on a Mac running Clash.
String scutilProxyOutput(String? address) {
  if (address == null) {
    return '<dictionary> {\n'
        '  HTTPEnable : 0\n'
        '  HTTPSEnable : 0\n'
        '  ProxyAutoConfigEnable : 0\n'
        '  SOCKSEnable : 0\n'
        '}\n';
  }
  final colon = address.lastIndexOf(':');
  final host = address.substring(0, colon);
  final port = address.substring(colon + 1);
  return '<dictionary> {\n'
      '  ExceptionsList : <array> {\n'
      '    0 : 192.168.0.0/16\n'
      '    1 : 127.0.0.1\n'
      '    2 : localhost\n'
      '    3 : *.local\n'
      '  }\n'
      '  ExcludeSimpleHostnames : 1\n'
      '  HTTPEnable : 1\n'
      '  HTTPPort : $port\n'
      '  HTTPProxy : $host\n'
      '  HTTPSEnable : 1\n'
      '  HTTPSPort : $port\n'
      '  HTTPSProxy : $host\n'
      '}\n';
}

/// One system's proxy setting as [SystemProxyReader] sees it, so the macOS
/// and the Windows path both run on any machine.
///
/// The reader asks the system on a background isolate, so each stand-in hands
/// it a function that carries only plain values, copied as they are when a
/// read starts, and that blocks the isolate running it for as long as the
/// system takes. A reader that asked on the caller's isolate would hold the
/// caller up for that long.
abstract class SystemProxyStandIn {
  factory SystemProxyStandIn(SystemProxyPlatform platform) =>
      platform == SystemProxyPlatform.windows
      ? WindowsRegistryStandIn()
      : ScutilStandIn();

  /// The system proxy, `host:port`, or null when it is off.
  set address(String? value);

  /// How long the system takes to answer.
  set delay(Duration value);

  /// Reads fail: scutil exits with an error, the registry cannot be opened.
  set fails(bool value);

  /// A reader for this system, built like the app builds it apart from what
  /// it asks.
  SystemProxyReader reader();
}

/// macOS: answers in place of the `scutil --proxy` child process.
class ScutilStandIn implements SystemProxyStandIn {
  final _state = _ScutilState();

  @override
  set address(String? value) => _state.output = scutilProxyOutput(value);
  @override
  set delay(Duration value) => _state.delay = value;
  @override
  set fails(bool value) => _state.fails = value;

  @override
  SystemProxyReader reader() => SystemProxyReader(
    platform: SystemProxyPlatform.macOS,
    scutil: _scutilRun(_state),
  );
}

class _ScutilState {
  String output = scutilProxyOutput('127.0.0.1:7890');
  Duration delay = Duration.zero;
  bool fails = false;
}

ScutilProxyCommand _scutilRun(_ScutilState state) => () async {
  // Starting scutil, reading the setting and waiting for it to exit.
  sleep(state.delay);
  return state.fails
      ? ProcessResult(4242, 1, '', 'scutil: configd not responding')
      : ProcessResult(4242, 0, state.output, '');
};

/// Windows: the values under Internet Settings in HKEY_CURRENT_USER.
class WindowsRegistryStandIn implements SystemProxyStandIn {
  final _values = _RegistryValues();

  @override
  set address(String? value) {
    _values.enable = value == null ? 0 : 1;
    if (value != null) _values.server = value;
  }

  /// Sets the raw values, for example `http=…;https=…` in ProxyServer.
  void set({int? enable, String? server}) {
    _values.enable = enable;
    _values.server = server;
  }

  @override
  set delay(Duration value) => _values.delay = value;
  @override
  set fails(bool value) => _values.fails = value;

  @override
  SystemProxyReader reader() => SystemProxyReader(
    platform: SystemProxyPlatform.windows,
    registry: _registryRead(_values),
  );
}

class _RegistryValues {
  int? enable = 1;
  String? server = '127.0.0.1:7890';
  Duration delay = Duration.zero;
  bool fails = false;
}

WindowsProxyRegistryRead _registryRead(_RegistryValues values) => () {
  // A slow registry call.
  sleep(values.delay);
  if (values.fails) throw const OSError('Access is denied.', 5);
  // Like the real read, ProxyServer is only looked at when the proxy is on.
  return (
    enable: values.enable,
    server: values.enable == 1 ? values.server : null,
  );
};
