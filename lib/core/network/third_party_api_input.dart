import 'dart:convert';

import '../utils/localization_extension.dart';
import 'nai_api_endpoint.dart';

/// Accept a raw token or the connection export copied from a New API console.
({String token, NaiApiEndpointConfig? endpoint}) parseThirdPartyApiInput(
  String input,
) {
  final text = input.trim();
  if (!text.startsWith('{')) return (token: text, endpoint: null);

  final Object? value;
  try {
    value = jsonDecode(text);
  } on FormatException {
    throw ArgumentError(currentL10n.auth_connectionImportInvalid);
  }
  if (value is! Map<String, dynamic> ||
      value['_type'] != 'newapi_channel_conn' ||
      value['key'] is! String ||
      value['url'] is! String) {
    throw ArgumentError(currentL10n.auth_connectionImportInvalid);
  }
  final token = (value['key'] as String).trim();
  if (token.isEmpty) {
    throw ArgumentError(currentL10n.auth_tokenRequired);
  }
  return (
    token: token,
    endpoint: NaiApiEndpointConfig.fromInput(
      mainBaseUrl: value['url'] as String,
    ),
  );
}
