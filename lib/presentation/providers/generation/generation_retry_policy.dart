import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_mappers/api_error_mapper.dart';
import '../../../core/network/retry_after.dart';
import '../../../data/models/image/image_stream_chunk.dart';
import '../../../l10n/app_localizations.dart';

/// 生图请求失败后怎么处理。
enum GenerationFailureKind {
  /// 网络错误、超时、5xx，以及流里说不清原因的失败（服务器发来的 error 事件、
  /// 没有最终图）：隔 1、2、4 秒重试，最多 3 次。
  transient,

  /// 429 并发限制：按 [GenerationConcurrencyBackoff] 等，等满就整次停下。
  concurrencyLimited,

  /// 其余错误（400、401、402、403、404 等客户端错误，响应解析失败……）：
  /// 重试也没用，直接报错。其中 400、401、402、403、404 还让批量生成整次停下
  /// （[stopsGenerationRun]）。
  permanent,
}

/// 把一次生图请求的失败归类。认得三种形状：
/// - 非流式请求抛出的 [DioException]；
/// - 流式请求的错误块文字（`API_ERROR_<码>|详情`，批次里包成 `Exception: …`）；
/// - 流读到一半断开时原样带出的 Socket / Http / 握手 / 超时异常（对象或文字）。
///
/// HTTP 200 的流里服务器发来的 error 事件、流结束了却没有最终图，这两种说不清
/// 原因，多半是服务器或网络的临时状况，跟网络错误一样重试；error 事件里带了
/// 能认出的状态码就照码处理。
GenerationFailureKind classifyGenerationFailure(Object error) {
  if (error is DioException) return _classifyDio(error);
  if (_isNetworkException(error)) return GenerationFailureKind.transient;
  if (error case GenerationStreamError(
    source: ImageStreamErrorSource.serverEvent ||
        ImageStreamErrorSource.noFinalImage,
    :final message,
  )) {
    final status = _statusOfText(message);
    return status == null
        ? GenerationFailureKind.transient
        : _classifyStatus(status);
  }
  return _classifyText(error.toString());
}

GenerationFailureKind _classifyDio(DioException error) {
  final status = error.response?.statusCode;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return GenerationFailureKind.transient;
    case DioExceptionType.badResponse:
      return _classifyStatus(status);
    case DioExceptionType.unknown:
      if (status != null) return _classifyStatus(status);
      final cause = error.error;
      return cause != null && _isNetworkException(cause)
          ? GenerationFailureKind.transient
          : GenerationFailureKind.permanent;
    default:
      // 证书不对、已取消，以及 dio 以后新加的类型：不重试。
      return GenerationFailureKind.permanent;
  }
}

GenerationFailureKind _classifyStatus(int? status) {
  if (status == 429) return GenerationFailureKind.concurrencyLimited;
  if (status != null && status >= 500 && status < 600) {
    return GenerationFailureKind.transient;
  }
  return GenerationFailureKind.permanent;
}

/// 和 `ApiErrorMapper` 一样，握手失败算网络错误。
bool _isNetworkException(Object error) =>
    error is SocketException ||
    error is HttpException ||
    error is HandshakeException ||
    error is TimeoutException;

const _networkExceptionNames = [
  'SocketException',
  'HttpException',
  'HandshakeException',
  'TimeoutException',
];

/// 去掉批次包在外面的 `Exception: `（可能不止一层）。
String _unwrapped(String text) {
  var message = text.trim();
  const wrapper = 'Exception: ';
  while (message.startsWith(wrapper)) {
    message = message.substring(wrapper.length);
  }
  return message;
}

/// `API_ERROR_<码>|详情` 里 `|` 前面的错误码。
String _codeOf(String message) {
  final bar = message.indexOf('|');
  return bar < 0 ? message : message.substring(0, bar);
}

GenerationFailureKind _classifyText(String text) {
  final message = _unwrapped(text);
  final code = _codeOf(message);
  switch (code) {
    case 'API_ERROR_429':
      return GenerationFailureKind.concurrencyLimited;
    case 'API_ERROR_TIMEOUT':
    case 'API_ERROR_NETWORK':
    case 'API_ERROR_500':
    case 'API_ERROR_503':
      return GenerationFailureKind.transient;
  }
  const httpPrefix = 'API_ERROR_HTTP_';
  if (code.startsWith(httpPrefix)) {
    return _classifyStatus(int.tryParse(code.substring(httpPrefix.length)));
  }
  // 400 / 401 / 402 / UNKNOWN 等其余错误码。
  if (code.startsWith('API_ERROR_')) return GenerationFailureKind.permanent;
  for (final name in _networkExceptionNames) {
    if (message.startsWith(name)) return GenerationFailureKind.transient;
  }
  return GenerationFailureKind.permanent;
}

/// 失败带的 HTTP 状态码：非流式的从响应读，流式的从错误块文字
/// （`API_ERROR_<码>|…`、`API_ERROR_HTTP_<码>|…`）读。存下来的报错（文字）
/// 两种都认，另加非流式请求留下的 dio 文字；前面的 `Exception: ` 和整次停下
/// 的标记都跳过。网络错误、超时等没有状态码，返回 null。
int? generationFailureStatus(Object error) => switch (error) {
  DioException(:final response) => response?.statusCode,
  GenerationStreamError(:final message) => _statusOfText(message),
  _ => _statusOfStored(error.toString()),
};

final _statusCodePattern = RegExp(r'^API_ERROR_(?:HTTP_)?(\d{3})$');

int? _statusOfText(String text) {
  final match = _statusCodePattern.firstMatch(
    _codeOf(generationFailureDetail(text)),
  );
  return match == null ? null : int.parse(match.group(1)!);
}

int? _statusOfStored(String text) =>
    _statusOfText(text) ?? _dioStatus(generationFailureDetail(text));

final _dioText = RegExp(r'^DioException \[([^\]]+)\]: ');

/// 非流式请求被拒时的状态码。dio 自己的说明里写着状态码；经过应用的错误
/// 拦截器（`ErrorInterceptor`）后说明换成了界面语言的「Anlas 不足」之类，
/// 就按每种界面语言的这几句反查。
int? _dioStatus(String detail) {
  final match = _dioText.firstMatch(detail);
  if (match == null || match.group(1) != 'bad response') return null;
  final said = detail.substring(match.end).split('\n').first.trim();
  final code = RegExp(r'status code of (\d{3})').firstMatch(said);
  if (code != null) return int.parse(code.group(1)!);
  if (_interceptorStatuses[said] case final status?) return status;
  for (final pattern in _requestFailedPatterns) {
    if (pattern.firstMatch(said) case final found?) {
      return int.parse(found.group(1)!);
    }
  }
  return null;
}

/// 每种界面语言里错误拦截器换上的说明 → 状态码。
final _interceptorStatuses = <String, int>{
  for (final locale in AppLocalizations.supportedLocales)
    ..._interceptorStatusesIn(lookupAppLocalizations(locale)),
};

/// 跟 `ErrorInterceptor._parseResponseError` 一一对应。
Map<String, int> _interceptorStatusesIn(AppLocalizations l) => {
  l.networkError_badRequest: 400,
  l.networkError_authFailed: 401,
  l.networkError_insufficientAnlas: 402,
  l.networkError_forbidden: 403,
  l.networkError_notFound: 404,
  l.networkError_conflict: 409,
  l.networkError_rateLimited: 429,
  l.networkError_serverInternal: 500,
  l.networkError_badGateway: 502,
  l.networkError_unavailable: 503,
};

/// 其余状态码的说明（「请求失败（504）」），每种界面语言一份。
final _requestFailedPatterns = [
  for (final locale in AppLocalizations.supportedLocales)
    _requestFailedPattern(lookupAppLocalizations(locale)),
];

RegExp _requestFailedPattern(AppLocalizations l) {
  const marker = 987654321;
  final parts = l.networkError_requestFailed(marker).split('$marker');
  return RegExp(
    '^${RegExp.escape(parts.first)}(\\d{3})${RegExp.escape(parts.last)}\$',
  );
}

/// 存下来的报错（`errorMessage`）里那次失败的原文：去掉批次包的
/// `Exception: ` 和整次停下的标记。
String generationFailureDetail(String message) =>
    _unwrapped(generationErrorWithoutStopMarker(_unwrapped(message)));

/// 去掉开头整次停下的标记，后面那次失败的原文原样返回；没停下的报错原样
/// 返回。失败卡「复制详情」复制的就是它。
String generationErrorWithoutStopMarker(String message) {
  for (final stop in const [
    generationConcurrencyStoppedCode,
    generationStatusStoppedCode,
  ]) {
    if (message.startsWith('$stop|')) return message.substring(stop.length + 1);
  }
  return message;
}

/// 400、401、402、403、404：请求无效、登录失效、余额不足、没有权限、找不到。
/// 这类错误不会自己好，批量生成碰到就整次停下，剩下的批次发了也是白发。
/// 409 等其余客户端错误只算这一批失败。
///
/// [badRequestStopsRun] 为 false 时 400 也只算这一批失败：画风探索每张候选
/// 抽到的画风串不同，生图页批量生成时提示词里的随机块每批重新抽，一批请求
/// 无效不代表都无效。
bool stopsGenerationRun(Object error, {bool badRequestStopsRun = true}) =>
    switch (generationFailureStatus(error)) {
      400 => badRequestStopsRun,
      401 || 402 || 403 || 404 => true,
      _ => false,
    };

/// 流式请求的错误块。比原来的 `Exception(…)` 多带服务器给的 Retry-After；
/// 文字和原来一样，界面上的报错不变。
class GenerationStreamError implements Exception {
  const GenerationStreamError(
    this.message, {
    this.retryAfter,
    this.source = ImageStreamErrorSource.other,
  });

  final String message;
  final Duration? retryAfter;

  /// 错误块是怎么来的（[ImageStreamChunk.errorSource]）。
  final ImageStreamErrorSource source;

  @override
  String toString() => 'Exception: $message';
}

/// 失败里带的 Retry-After：流式错误块随块带出，非流式从响应头读。
Duration? generationRetryAfterOf(Object error) => switch (error) {
  GenerationStreamError(:final retryAfter) => retryAfter,
  final DioException dio => retryAfterOf(dio),
  _ => null,
};

/// 429 并发限制的等待：服务器给了 Retry-After 就照它等，没给就
/// 3 → 6 → 12 → 24 → 30 秒（单次最多 30 秒）。一次运行总共最多等 90 秒，
/// 最后一次截到刚好用完；等满（或服务器要求等的比剩下的还久）就该整次停下。
class GenerationConcurrencyBackoff {
  static const Duration firstDelay = Duration(seconds: 3);
  static const Duration maxDelay = Duration(seconds: 30);
  static const Duration budget = Duration(seconds: 90);

  /// Retry-After 给 0 或已经过去的时间时，至少也等这么久，免得连着发。
  static const Duration minRetryAfter = Duration(seconds: 1);

  int _attempt = 0;
  Duration _waited = Duration.zero;

  /// 这次运行已经因为 429 等了多久。
  Duration get waited => _waited;

  /// 下次重试前要等多久；null 表示不再重试，整次运行停下。
  Duration? nextDelay({Duration? retryAfter}) {
    final remaining = budget - _waited;
    if (remaining <= Duration.zero) return null;
    final Duration delay;
    if (retryAfter != null) {
      final asked = retryAfter < minRetryAfter ? minRetryAfter : retryAfter;
      if (asked > remaining) return null;
      delay = asked;
    } else {
      final grown = firstDelay * (1 << math.min(_attempt, 4));
      final capped = grown > maxDelay ? maxDelay : grown;
      delay = capped > remaining ? remaining : capped;
    }
    _attempt++;
    _waited += delay;
    return delay;
  }

  /// 请求成功了一次：下次 429 重新从 3 秒开始退避，已经等掉的总时长不退回。
  void reset() => _attempt = 0;
}

/// 429 等满、整次运行停下时 `errorMessage` 的开头；生图页据此说明停下的原因。
const generationConcurrencyStoppedCode = 'GENERATION_CONCURRENCY_STOPPED';

/// 停下时的 `errorMessage`：开头是停下的标记，后面是最后一次 429 的原文。
String generationConcurrencyStoppedError(Object lastError) =>
    '$generationConcurrencyStoppedCode|${_stopDetail(lastError)}';

bool isGenerationConcurrencyStopped(String? message) =>
    message?.startsWith('$generationConcurrencyStoppedCode|') ?? false;

/// 按状态码（400、401、402、403、404，[stopsGenerationRun]）整次运行停下时
/// `errorMessage` 的开头。
const generationStatusStoppedCode = 'GENERATION_STATUS_STOPPED';

/// 按状态码停下时的 `errorMessage`：开头是停下的标记，后面是那次失败的
/// 原文（`API_ERROR_<码>|…`），失败卡和导航栏据此认出是哪种错误。
String generationStatusStoppedError(Object lastError) =>
    '$generationStatusStoppedCode|${_stopDetail(lastError)}';

bool isGenerationStatusStopped(String? message) =>
    message?.startsWith('$generationStatusStoppedCode|') ?? false;

/// 整次运行停下了（429 等满，或者碰到 400、401、402、403、404）：剩下的批次
/// 没发，停下前出的图照常保留。
bool isGenerationRunStopped(String? message) =>
    isGenerationConcurrencyStopped(message) ||
    isGenerationStatusStopped(message);

/// 停下那次失败的原文；非流式的按流式的写法记，状态码就在开头。
String _stopDetail(Object lastError) => switch (lastError) {
  GenerationStreamError(:final message) => message,
  final DioException dio => ApiErrorMapper.formatDioError(dio),
  _ => lastError.toString(),
};

/// 重试前的等待：等满 [delay]；[cancelled] 先完成（用户点了取消）就马上结束。
/// 测试换掉它，记下每次等多久而不真的等。
typedef GenerationRetryDelay =
    Future<void> Function(Duration delay, Future<void> cancelled);

final generationRetryDelayProvider = Provider<GenerationRetryDelay>(
  (ref) => waitBeforeGenerationRetry,
);

/// [GenerationRetryDelay] 的正式实现：被取消时连计时器一起放掉，不留到点。
Future<void> waitBeforeGenerationRetry(Duration delay, Future<void> cancelled) {
  final done = Completer<void>();
  final timer = Timer(delay, done.complete);
  cancelled.whenComplete(() {
    timer.cancel();
    if (!done.isCompleted) done.complete();
  }).ignore();
  return done.future;
}
