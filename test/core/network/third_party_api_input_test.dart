import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/third_party_api_input.dart';

void main() {
  test('plain token does not change the configured service addresses', () {
    final input = parseThirdPartyApiInput('  sk-offline-fixture  ');
    expect(input.token, 'sk-offline-fixture');
    expect(input.endpoint, isNull);
  });

  test('New API connection JSON separates token from the service address', () {
    final input = parseThirdPartyApiInput(
      r'{"_type":"newapi_channel_conn","key":"sk-offline-fixture","url":"https:\/\/gateway.invalid\/v1\/novelai\/"}',
    );
    expect(input.token, 'sk-offline-fixture');
    expect(input.endpoint?.mainBaseUrl, 'https://gateway.invalid/v1/novelai');
    expect(input.endpoint?.imageBaseUrl, input.endpoint?.mainBaseUrl);
  });

  for (final input in [
    '{',
    '{"_type":"other","key":"fixture-secret","url":"https://gateway.invalid"}',
    '{"_type":"newapi_channel_conn","key":123,"url":"https://gateway.invalid"}',
    '{"_type":"newapi_channel_conn","key":"","url":"https://gateway.invalid"}',
    '{"_type":"newapi_channel_conn","key":"fixture-secret","url":"https://user:password@gateway.invalid"}',
  ]) {
    test(
      'invalid connection reports a field error without echoing the key: ${input.length}',
      () {
        expect(
          () => parseThirdPartyApiInput(input),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('fixture-secret')),
            ),
          ),
        );
      },
    );
  }
}
