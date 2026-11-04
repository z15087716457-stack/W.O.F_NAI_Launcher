import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/system_proxy_http_overrides.dart';
import 'package:nai_launcher/core/network/proxy_bypass.dart';

/// 这台 Mac 上 `scutil --proxy` 的真实输出（节选），开着 Clash。
const _scutil = '''
<dictionary> {
  ExceptionsList : <array> {
    0 : 192.168.0.0/16
    1 : 10.0.0.0/8
    2 : 172.16.0.0/12
    3 : 127.0.0.1
    4 : localhost
    5 : *.local
    6 : timestamp.apple.com
  }
  ExcludeSimpleHostnames : 1
  HTTPEnable : 1
  HTTPPort : 7890
  HTTPProxy : 127.0.0.1
}
''';

void main() {
  test('本机地址一律直连', () {
    const bypass = ProxyBypassList.loopbackOnly;
    for (final host in [
      'localhost',
      'LOCALHOST',
      'lmstudio.localhost',
      '127.0.0.1',
      '127.8.9.10',
      '::1',
      '[::1]',
    ]) {
      expect(bypass.matches(host), isTrue, reason: host);
    }
    expect(bypass.matches('novelai.net'), isFalse);
    expect(bypass.matches('192.168.1.5'), isFalse);
  });

  test('照 macOS 系统代理的「不走代理」名单：网段、通配、精确域名、简单主机名', () {
    final bypass = ProxyBypassList.fromScutil(_scutil);
    for (final host in [
      '192.168.1.5',
      '10.2.3.4',
      '172.20.0.1',
      'printer.local',
      'timestamp.apple.com',
      'nas',
    ]) {
      expect(bypass.matches(host), isTrue, reason: host);
    }
    for (final host in ['172.32.0.1', 'novelai.net', 'api.deepseek.com']) {
      expect(bypass.matches(host), isFalse, reason: host);
    }
  });

  test('没有名单时只放本机', () {
    final bypass = ProxyBypassList.fromScutil('<dictionary> {\n}\n');
    expect(bypass.matches('localhost'), isTrue);
    expect(bypass.matches('nas'), isFalse);
  });

  test('代理覆盖：本机和名单里的直连，其余走代理', () {
    final overrides = SystemProxyHttpOverrides(
      'PROXY 127.0.0.1:7890',
      bypass: ProxyBypassList.fromScutil(_scutil),
    );
    expect(overrides.proxyFor(Uri.parse('http://localhost:1234/v1')), 'DIRECT');
    expect(overrides.proxyFor(Uri.parse('http://192.168.1.9:8188')), 'DIRECT');
    expect(
      overrides.proxyFor(Uri.parse('https://image.novelai.net/ai/generate')),
      'PROXY 127.0.0.1:7890',
    );
  });

  test('代理覆盖不给名单时也放本机', () {
    final overrides = SystemProxyHttpOverrides('PROXY 127.0.0.1:7890');
    expect(overrides.proxyFor(Uri.parse('http://127.0.0.1:11434')), 'DIRECT');
  });
}
