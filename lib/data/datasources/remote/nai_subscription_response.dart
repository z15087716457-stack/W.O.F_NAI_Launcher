import 'package:dio/dio.dart';

/// The HTTP 200 response of a web console is not an API connection.
class NaiApiCompatibilityException implements Exception {
  const NaiApiCompatibilityException();
}

Map<String, dynamic> readNaiSubscriptionResponse(Response<dynamic> response) {
  final data = response.data;
  if (data is! Map<String, dynamic> ||
      data['tier'] is! int ||
      (data['active'] != null && data['active'] is! bool)) {
    throw const NaiApiCompatibilityException();
  }
  return data;
}
