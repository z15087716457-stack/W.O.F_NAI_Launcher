import 'dart:io';

import 'package:dio/dio.dart';

/// 解析 HTTP `Retry-After`：秒数（`120`）或 HTTP 日期
/// （`Wed, 21 Oct 2026 07:28:00 GMT`）。
///
/// 解析不了或是负数返回 null；日期已经过去按 0 处理。
Duration? parseRetryAfter(String? value, {DateTime? now}) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  final seconds = int.tryParse(text);
  if (seconds != null) {
    return seconds < 0 ? null : Duration(seconds: seconds);
  }
  final DateTime date;
  try {
    date = HttpDate.parse(text);
  } on HttpException {
    return null;
  } on FormatException {
    return null;
  }
  final wait = date.difference((now ?? DateTime.now()).toUtc());
  return wait.isNegative ? Duration.zero : wait;
}

/// 失败响应里服务器给的 `Retry-After`；没有或解析不了返回 null。
Duration? retryAfterOf(DioException error, {DateTime? now}) {
  final values = error.response?.headers['retry-after'];
  return parseRetryAfter(
    values == null || values.isEmpty ? null : values.first,
    now: now,
  );
}
