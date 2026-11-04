import '../../l10n/app_localizations.dart';

/// Bounded server detail for error cards; copying still uses the original text.
String? generationErrorDetails(String? message, {int maxLength = 240}) {
  if (message == null) return null;
  final separator = message.indexOf('|');
  if (separator < 0) return null;
  final summary = message
      .substring(separator + 1)
      .trim()
      .replaceAll(RegExp(r'"[A-Za-z0-9+/=]{256,}"'), '"…"');
  return summary.length > maxLength
      ? '${summary.substring(0, maxLength)}…'
      : summary;
}

/// 解析 API 错误代码，返回 (标题, 提示)
(String, String?) generationErrorPresentation(
  String? message,
  AppLocalizations l,
) {
  if (message == null || message.isEmpty) {
    return (l.generation_generationFailed, null);
  }

  // 取消操作
  if (message == 'Cancelled') {
    return (l.generation_cancelGeneration, null);
  }

  final separator = message.indexOf('|');
  final errorCode = separator < 0 ? message : message.substring(0, separator);
  final details = generationErrorDetails(message);

  // 固定文案后拼接服务端真实详情，避免所有错误只显示同一句兜底提示
  String withDetails(String localizedHint) {
    if (details == null || details.isEmpty) return localizedHint;
    return '$localizedHint\n$details';
  }

  switch (errorCode) {
    case 'API_ERROR_429':
      return (
        '${l.api_error_429} (HTTP 429)',
        withDetails(l.api_error_429_hint),
      );
    case 'API_ERROR_401':
      return (
        '${l.api_error_401} (HTTP 401)',
        withDetails(l.api_error_401_hint),
      );
    case 'API_ERROR_402':
      return (
        '${l.api_error_402} (HTTP 402)',
        withDetails(l.api_error_402_hint),
      );
    case 'API_ERROR_400':
      return ('${l.common_error} (HTTP 400)', details);
    case 'API_ERROR_500':
      return (
        '${l.api_error_500} (HTTP 500)',
        withDetails(l.api_error_500_hint),
      );
    case 'API_ERROR_503':
      return (
        '${l.api_error_503} (HTTP 503)',
        withDetails(l.api_error_503_hint),
      );
    case 'API_ERROR_TIMEOUT':
      return (l.api_error_timeout, withDetails(l.api_error_timeout_hint));
    case 'API_ERROR_NETWORK':
      return (l.api_error_network, withDetails(l.api_error_network_hint));
    default:
      // 未知错误或其他 HTTP 错误
      if (errorCode.startsWith('API_ERROR_HTTP_')) {
        final code = errorCode.replaceFirst('API_ERROR_HTTP_', '');
        return ('${l.common_error} (HTTP $code)', details);
      }
      if (errorCode.startsWith('API_ERROR_')) {
        // 已编码但无专属文案的错误：显示真实状态码+详情而非整段原始串
        final code = errorCode.replaceFirst('API_ERROR_', '');
        return ('${l.common_error} ($code)', details ?? message);
      }
      return (l.generation_generationFailed, message);
  }
}
