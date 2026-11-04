import '../../l10n/app_localizations.dart';
import '../providers/generation/generation_models.dart';
import '../providers/generation/generation_retry_policy.dart';
import '../ui/gen/gen_contract.dart';
import '../utils/generation_error_presentation.dart';

/// 失败原因显示在哪里。400、403、404 的说明最后让用户点的按钮不一样：生图页
/// 改好的提示词、参数、账号只有点“生成”才发得出去；画风探索里点“重试失败的
/// 候选”，那些候选就按现在的提示词、参数和账号重新抽、重新发。429 等满停下
/// 的说明在生图页指向失败卡上的“重试”，探索里也指向“重试失败的候选”。提示
/// 词集卡片上的“生成”先把这一项的提示词重新写进草稿再发，在画布上改好的提示
/// 词会被盖掉，所以 400 让用户检查参数，或让 Agent 修改这一项的提示词；参数、
/// 模型和账号导入时不动，403、404 照生图页的说明做就有效。
enum GenerationErrorPlace { generationPage, styleExplore, promptSet }

/// 生成失败卡：按错误类型给标题和一句说明（为什么、接下来怎么办），原始错误
/// 照旧可以复制（整次停下的内部标记不复制，悬停也不显示）。认得 400、401、
/// 402、403、404、429（含等满停下）、5xx、网络错误和超时，流式和非流式两种
/// 报错都认；认不出的只给通用标题。
GenError generationErrorView(
  AppLocalizations l,
  String? message, {
  GenerationErrorPlace place = GenerationErrorPlace.generationPage,
}) {
  final reason = _reasonOf(message);
  final copy = message == null
      ? null
      : generationErrorWithoutStopMarker(message);
  if (reason == null) {
    return GenError(title: l.common_error, detail: message, copy: copy);
  }
  final (title, hint) = _text(l, reason);
  return GenError(
    title: title,
    hint: switch (place) {
      GenerationErrorPlace.generationPage => hint,
      GenerationErrorPlace.styleExplore => _exploreHint(l, reason) ?? hint,
      GenerationErrorPlace.promptSet => _promptSetHint(l, reason) ?? hint,
    },
    detail: message,
    copy: copy,
  );
}

/// 画风探索里 400、403、404 和 429 等满停下的说明，末尾指向“重试失败的候选”：
/// 生图页的说明让人点“生成”或失败卡上的“重试”，探索里没有这两个按钮。其余的
/// 说明是“……后重试”之类，不点名按钮，在探索里点重试本来就对，跟生图页一样。
String? _exploreHint(AppLocalizations l, _Reason reason) => switch (reason) {
  _Reason.badRequest => l.explore_error400Hint,
  _Reason.forbidden => l.explore_error403Hint,
  _Reason.notFound => l.explore_error404Hint,
  _Reason.concurrencyStopped => l.explore_concurrencyStoppedHint,
  _ => null,
};

/// 提示词集卡片上 400 的说明：参数照常检查，提示词让 Agent 修改这一项，末尾
/// 还是卡片上的“生成”。其余的说明照做在卡片上都有效，跟生图页一样。
String? _promptSetHint(AppLocalizations l, _Reason reason) => switch (reason) {
  _Reason.badRequest => l.ag_psError400Hint,
  _ => null,
};

/// 批量生成出完了，但有几次请求被 NovelAI 拒绝（400）、跳过了：提示词里有顺序
/// 或随机块、每次请求重新抽词时，400 只算那一次失败，其余照发。画布用同一张
/// 失败卡说明：标题跟 400 一样，说明写跳过了几次、改好后点“生成”。卡上不出
/// “重试”：重试照原样补发，被拒的词再发一遍还是 400；“复制详情”给最后被拒
/// 那一次的原文。
GenError generationRejectedBatchesView(
  AppLocalizations l,
  GenerationRejectedBatches rejected,
) => GenError(
  title: l.api_error_400,
  hint: l.gen_rejectedRequestsHint(rejected.count),
  detail: rejected.lastError,
  copy: generationErrorWithoutStopMarker(rejected.lastError),
  retry: false,
);

/// 画布下方的失败卡：失败了（包括整次停下）写原因；批量出完了、只是有几次请
/// 求被 NovelAI 拒绝跳过，同一张卡写跳过了几次；别的时候没有卡。
GenError? generationCanvasError(
  AppLocalizations l,
  ImageGenerationState generation,
) => switch (generation) {
  ImageGenerationState(isExploreRun: true) => null,
  ImageGenerationState(status: GenerationStatus.error) => _canvasFailure(
    l,
    generation.errorMessage,
    generation.partialBatch,
  ),
  ImageGenerationState(
    status: GenerationStatus.completed,
    rejectedBatches: final rejected?,
  ) =>
    generationRejectedBatchesView(l, rejected),
  _ => null,
};

/// Preserve upstream's visible HTTP status/server reason and bounded image
/// echoes, followed by the action hint for this page. Other places retain
/// their own retry instructions; skipped-batch notices remain non-retryable.
GenError _canvasFailure(
  AppLocalizations l,
  String? message,
  GenerationPartialBatch? partial,
) {
  final card = generationErrorView(l, message);
  final detail = generationFailureDetail(message ?? '');
  final status = generationFailureStatus(detail);
  final hint = partial == null
      ? card.hint
      : l.gen_partialBatchHint(partial.received, partial.expected);
  final summary = generationErrorDetails(
    detail,
    maxLength: (240 - (hint?.length ?? 0)).clamp(1, 240),
  );
  return GenError(
    title: status == null ? card.title : '${card.title} (HTTP $status)',
    hint: summary == null || summary.isEmpty
        ? hint
        : [summary, if (hint != null && hint.isNotEmpty) hint].join('\n'),
    detail: card.detail,
    copy: card.copy,
    retry: partial == null ? card.retry : partial.unsentRequests > 0,
  );
}

/// 失败卡上的原因标题，导航栏的失败提示也用它；认不出返回 null。
String? generationErrorTitle(AppLocalizations l, String? message) {
  final reason = _reasonOf(message);
  return reason == null ? null : _text(l, reason).$1;
}

/// 失败原因写成一段字，给没有失败卡的地方用（提示、画风探索候选的失败原因）：
/// 认得的跟失败卡一样，「原因标题\n接下来怎么办」；认不出的给原文，整次停下
/// 的标记去掉；没有报错（连原文都没有）返回 null，调用方换成自己的通用说明。
String? generationErrorText(
  AppLocalizations l,
  String? message, {
  GenerationErrorPlace place = GenerationErrorPlace.generationPage,
}) {
  if (message == null) return null;
  final card = generationErrorView(l, message, place: place);
  if (card.hint case final hint?) return '${card.title}\n$hint';
  final copy = card.copy;
  return copy == null || copy.trim().isEmpty ? null : copy;
}

enum _Reason {
  badRequest,
  unauthorized,
  paymentRequired,
  forbidden,
  notFound,
  concurrencyLimited,

  /// 429 等满，整次运行停下。
  concurrencyStopped,

  /// 503 以外的 5xx。
  serverError,
  unavailable,
  network,
  timeout,
}

(String, String) _text(AppLocalizations l, _Reason reason) => switch (reason) {
  _Reason.badRequest => (l.api_error_400, l.api_error_400_hint),
  _Reason.unauthorized => (l.api_error_401, l.api_error_401_hint),
  _Reason.paymentRequired => (l.api_error_402, l.api_error_402_hint),
  _Reason.forbidden => (l.api_error_403, l.api_error_403_hint),
  _Reason.notFound => (l.api_error_404, l.api_error_404_hint),
  _Reason.concurrencyLimited => (l.api_error_429, l.api_error_429_hint),
  _Reason.concurrencyStopped => (l.api_error_429, l.gen_concurrencyStopped),
  _Reason.serverError => (l.api_error_500, l.api_error_500_hint),
  _Reason.unavailable => (l.api_error_503, l.api_error_503_hint),
  _Reason.network => (l.api_error_network, l.api_error_network_hint),
  _Reason.timeout => (l.api_error_timeout, l.api_error_timeout_hint),
};

/// 认得的报错：
/// - 流式：`API_ERROR_<码>|原文`（批次包的 `Exception: `、整次停下的标记都跳过），
///   以及流读到一半断开时带出的 Socket / Http / 握手 / 超时异常文字；
/// - 非流式：DioException 原文，`DioException [<类型>]: <说明>`。
_Reason? _reasonOf(String? message) {
  if (message == null || message.trim().isEmpty) return null;
  if (isGenerationConcurrencyStopped(message)) {
    return _Reason.concurrencyStopped;
  }
  final detail = generationFailureDetail(message);
  final status = generationFailureStatus(detail);
  if (status != null) return _byStatus(status);
  return _connectionReason(detail);
}

_Reason? _byStatus(int status) => switch (status) {
  400 => _Reason.badRequest,
  401 => _Reason.unauthorized,
  402 => _Reason.paymentRequired,
  403 => _Reason.forbidden,
  404 => _Reason.notFound,
  429 => _Reason.concurrencyLimited,
  503 => _Reason.unavailable,
  >= 500 && < 600 => _Reason.serverError,
  _ => null,
};

/// 非流式请求失败留下的 dio 文字（`DioException [<类型>]: <说明>`）；被拒时的
/// 状态码由 [generationFailureStatus] 读，这里只看超时和连不上。
final _dioText = RegExp(r'^DioException \[([^\]]+)\]: ');

_Reason? _connectionReason(String detail) {
  if (detail.startsWith('API_ERROR_TIMEOUT|')) return _Reason.timeout;
  if (detail.startsWith('API_ERROR_NETWORK|')) return _Reason.network;
  final dio = _dioText.firstMatch(detail);
  if (dio == null) return _exceptionReason(detail);
  switch (dio.group(1)) {
    case 'connection timeout' ||
        'send timeout' ||
        'receive timeout' ||
        'transform timeout':
      return _Reason.timeout;
    case 'connection error':
      return _Reason.network;
  }
  // 其余类型看底层异常，在另起一行的 `Error: ` 后面。
  const cause = '\nError: ';
  final at = detail.indexOf(cause);
  return at < 0 ? null : _exceptionReason(detail.substring(at + cause.length));
}

/// 流读到一半断开时原样带出的异常文字。
_Reason? _exceptionReason(String text) {
  if (text.startsWith('TimeoutException')) return _Reason.timeout;
  for (final name in const [
    'SocketException',
    'HttpException',
    'HandshakeException',
  ]) {
    if (text.startsWith(name)) return _Reason.network;
  }
  return null;
}
