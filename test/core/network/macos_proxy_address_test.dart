import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/macos_proxy_address.dart';

void main() {
  const secure =
      '  HTTPSEnable : 1\n  HTTPSProxy : localhost\n  HTTPSPort : 8090\n';
  test('HTTPS-only scutil configuration is usable', () {
    expect(macOSProxyAddress(secure), 'localhost:8090');
    expect(
      macOSProxyAddress('HTTPEnable : 1\nHTTPPort : 0\n$secure'),
      'localhost:8090',
    );
  });
  test('a usable HTTP entry takes precedence over HTTPS', () {
    expect(
      macOSProxyAddress(
        'HTTPEnable : 1\nHTTPProxy : 127.0.0.1\nHTTPPort : 8080\n$secure',
      ),
      '127.0.0.1:8080',
    );
    expect(macOSProxyAddress(secure.replaceFirst(': 1', ': 0')), isNull);
    expect(macOSProxyAddress(secure.replaceFirst('8090', '65536')), isNull);
  });
}
