import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/dio_client.dart';
import 'package:nai_launcher/core/network/error_mappers/api_error_mapper.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
import 'package:nai_launcher/presentation/providers/locale_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_error_view.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Locale extends LocaleNotifier {
  _Locale(this.locale);
  final Locale locale;
  @override
  Locale build() => locale;
}

class _Passed extends ErrorInterceptorHandler {
  DioException? error;
  @override
  void next(DioException err) => error = err;
}

final _request = RequestOptions(path: '/ai/generate-image');

DioException _rejected(int status) => DioException.badResponse(
  statusCode: status,
  requestOptions: _request,
  // A non-stream request asks for bytes, so the body is never a map.
  response: Response<Uint8List>(
    requestOptions: _request,
    statusCode: status,
    data: Uint8List(0),
  ),
);

/// What a failed non-stream request leaves in `errorMessage`: dio's error as
/// the app's error interceptor hands it on, worded in the app's language.
String _nonStream(DioException error, Locale locale) {
  final container = ProviderContainer(
    overrides: [localeNotifierProvider.overrideWith(() => _Locale(locale))],
  );
  addTearDown(container.dispose);
  final handler = _Passed();
  container
      .read(Provider((ref) => ErrorInterceptor(ref)))
      .onError(error, handler);
  return handler.error!.toString();
}

/// What a failed stream request leaves: the service's text, wrapped in
/// `Exception: ` by the batch loop.
List<String> _stream(DioException error) {
  final text = ApiErrorMapper.formatDioError(error);
  return [text, 'Exception: $text'];
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  for (final locale in AppLocalizations.supportedLocales) {
    final tag = locale.toLanguageTag();
    final l = lookupAppLocalizations(locale);

    test(
      'each status gets its reason and what to do, in both shapes ($tag)',
      () {
        final byStatus = <int, (String, String)>{
          400: (l.api_error_400, l.api_error_400_hint),
          401: (l.api_error_401, l.api_error_401_hint),
          402: (l.api_error_402, l.api_error_402_hint),
          403: (l.api_error_403, l.api_error_403_hint),
          404: (l.api_error_404, l.api_error_404_hint),
          429: (l.api_error_429, l.api_error_429_hint),
          500: (l.api_error_500, l.api_error_500_hint),
          502: (l.api_error_500, l.api_error_500_hint),
          503: (l.api_error_503, l.api_error_503_hint),
          504: (l.api_error_500, l.api_error_500_hint),
        };
        for (final MapEntry(key: status, value: (title, hint))
            in byStatus.entries) {
          expect(title, isNotEmpty, reason: 'HTTP $status title');
          expect(hint, isNotEmpty, reason: 'HTTP $status hint');
          for (final message in [
            ..._stream(_rejected(status)),
            _nonStream(_rejected(status), locale),
          ]) {
            final error = generationErrorView(l, message);
            expect(error.title, title, reason: message);
            expect(error.hint, hint, reason: message);
            expect(error.detail, message);
            // An error that did not stop the run is copied as it is.
            expect(error.copy, message);
            expect(generationErrorTitle(l, message), title, reason: message);
          }
        }
      },
    );

    test('network errors and timeouts, in both shapes ($tag)', () {
      final network = [
        ..._stream(
          DioException.connectionError(
            requestOptions: _request,
            reason: 'Connection refused',
          ),
        ),
        // A body cut off mid-stream, as the stream service passes it on.
        const SocketException(
          'Connection reset by peer',
          osError: OSError('Connection reset by peer', 54),
        ).toString(),
        'Exception: ${const SocketException('An existing connection was forcibly closed by the remote host.', osError: OSError('An existing connection was forcibly closed by the remote host.', 10054))}',
        HttpException(
          'Connection closed while receiving data',
          uri: Uri.parse('https://image.novelai.net/ai/generate-image-stream'),
        ).toString(),
        _nonStream(
          DioException.connectionError(
            requestOptions: _request,
            reason: 'Connection refused',
          ),
          locale,
        ),
        _nonStream(
          DioException(
            requestOptions: _request,
            error: const SocketException('Connection reset by peer'),
          ),
          locale,
        ),
      ];
      for (final message in network) {
        final error = generationErrorView(l, message);
        expect(error.title, l.api_error_network, reason: message);
        expect(error.hint, l.api_error_network_hint, reason: message);
        expect(error.detail, message);
        expect(error.copy, message);
      }
      final timeouts = [
        for (final error in [
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: _request,
          ),
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: _request,
          ),
          DioException.sendTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: _request,
          ),
        ]) ...[..._stream(error), _nonStream(error, locale)],
        'Exception: ${TimeoutException('No stream event', const Duration(seconds: 30))}',
      ];
      for (final message in timeouts) {
        final error = generationErrorView(l, message);
        expect(error.title, l.api_error_timeout, reason: message);
        expect(error.hint, l.api_error_timeout_hint, reason: message);
        expect(error.detail, message);
      }
    });

    test('a run that stopped says why ($tag)', () {
      final concurrency = generationConcurrencyStoppedError(
        'API_ERROR_429|Concurrent generation is locked',
      );
      final card = generationErrorView(l, concurrency);
      expect(card.title, l.api_error_429);
      expect(card.hint, l.gen_concurrencyStopped);
      expect(card.detail, concurrency);
      // Copy details leaves out the stop marker and keeps the rest.
      expect(card.copy, 'API_ERROR_429|Concurrent generation is locked');
      for (final (status, title, hint) in [
        (400, l.api_error_400, l.api_error_400_hint),
        (401, l.api_error_401, l.api_error_401_hint),
        (402, l.api_error_402, l.api_error_402_hint),
        (403, l.api_error_403, l.api_error_403_hint),
        (404, l.api_error_404, l.api_error_404_hint),
      ]) {
        for (final failure in <Object>[
          _rejected(status),
          GenerationStreamError(
            ApiErrorMapper.formatDioError(_rejected(status)),
          ),
        ]) {
          final stopped = generationStatusStoppedError(failure);
          final error = generationErrorView(l, stopped);
          expect(error.title, title, reason: stopped);
          expect(error.hint, hint, reason: stopped);
          expect(error.detail, stopped);
          expect(
            error.copy,
            stopped.substring('GENERATION_STATUS_STOPPED|'.length),
          );
          expect(error.copy, isNot(contains('STOPPED')));
        }
      }
    });

    test('anything else keeps the plain card ($tag)', () {
      for (final message in [
        null,
        '',
        'API_ERROR_UNKNOWN|Unknown error',
        'API_ERROR_HTTP_409|Conflict',
        'Exception: API_ERROR_HTTP_413|Payload too large',
        'Exception: No final image received from stream',
        'Failed to parse response',
        'No images returned from generation',
        l.localUpscale_notInstalled,
        _nonStream(_rejected(409), locale),
        _nonStream(
          DioException.badCertificate(requestOptions: _request),
          locale,
        ),
      ]) {
        final error = generationErrorView(l, message);
        expect(error.title, l.common_error, reason: message);
        expect(error.hint, isNull, reason: message);
        expect(error.detail, message);
        expect(error.copy, message);
        expect(generationErrorTitle(l, message), isNull, reason: message);
      }
    });
  }

  test('as one text: the reason and what to do, else the error without the '
      'stop marker, else nothing', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      final tag = locale.toLanguageTag();
      for (final (message, place, text) in [
        (
          ApiErrorMapper.formatDioError(_rejected(402)),
          GenerationErrorPlace.generationPage,
          '${l.api_error_402}\n${l.api_error_402_hint}',
        ),
        (
          _nonStream(_rejected(400), locale),
          GenerationErrorPlace.generationPage,
          '${l.api_error_400}\n${l.api_error_400_hint}',
        ),
        (
          generationStatusStoppedError(_rejected(403)),
          GenerationErrorPlace.styleExplore,
          '${l.api_error_403}\n${l.explore_error403Hint}',
        ),
        (
          generationConcurrencyStoppedError(
            'API_ERROR_429|Concurrent generation is locked',
          ),
          GenerationErrorPlace.generationPage,
          '${l.api_error_429}\n${l.gen_concurrencyStopped}',
        ),
        (
          generationConcurrencyStoppedError(
            'API_ERROR_429|Concurrent generation is locked',
          ),
          GenerationErrorPlace.styleExplore,
          '${l.api_error_429}\n${l.explore_concurrencyStoppedHint}',
        ),
        (
          'API_ERROR_HTTP_409|Conflict',
          GenerationErrorPlace.generationPage,
          'API_ERROR_HTTP_409|Conflict',
        ),
        (
          generationStatusStoppedError('API_ERROR_UNKNOWN|odd'),
          GenerationErrorPlace.styleExplore,
          'API_ERROR_UNKNOWN|odd',
        ),
      ]) {
        expect(
          generationErrorText(l, message, place: place),
          text,
          reason: '$tag $message',
        );
      }
      for (final message in [null, '', ' ', generationStatusStoppedError('')]) {
        expect(generationErrorText(l, message), isNull, reason: '$message');
      }
    }
  });

  test('Copy details leaves out the stop marker of a card it cannot name', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final message = generationStatusStoppedError('API_ERROR_UNKNOWN|odd');
    final error = generationErrorView(l, message);
    expect(error.title, l.common_error);
    expect(error.detail, message);
    expect(error.copy, 'API_ERROR_UNKNOWN|odd');
    expect(generationErrorView(l, null).copy, isNull);
  });

  test('a non-stream error is read whatever language it was worded in', () {
    for (final worded in AppLocalizations.supportedLocales) {
      final message = _nonStream(_rejected(402), worded);
      for (final shown in AppLocalizations.supportedLocales) {
        final l = lookupAppLocalizations(shown);
        expect(
          generationErrorView(l, message).title,
          l.api_error_402,
          reason: '$worded → $shown: $message',
        );
      }
    }
  });

  test('dio\'s own wording of a rejected request is read too', () {
    final l = lookupAppLocalizations(const Locale('en'));
    for (final status in [400, 401, 402, 403, 404, 502]) {
      // Without the app's interceptor the message still names the status.
      final message = _rejected(status).toString();
      expect(message, contains('status code of $status'));
      expect(generationErrorView(l, message).title, isNot(l.common_error));
    }
    expect(
      generationErrorView(l, _rejected(402).toString()).title,
      l.api_error_402,
    );
  });

  test('the card reads like this in Chinese and English', () {
    final zh = lookupAppLocalizations(const Locale('zh'));
    final en = lookupAppLocalizations(const Locale('en'));
    String card(AppLocalizations l, int status) {
      final error = generationErrorView(
        l,
        ApiErrorMapper.formatDioError(_rejected(status)),
      );
      return '${error.title} / ${error.hint}';
    }

    expect(card(zh, 402), '余额不足 / Anlas 余额不足，请充值后重试');
    expect(card(zh, 401), '认证失败 / Token 无效或已过期，请重新登录');
    expect(card(zh, 400), '请求无效 / 无法生成：NovelAI 不接受这组设置。请检查提示词和参数，改好后再点“生成”');
    expect(card(zh, 403), '没有权限 / 无法生成：这个账号没有这项功能的权限。请检查订阅，或换个账号后再点“生成”');
    expect(card(zh, 404), '未找到 / 无法生成：服务器上没有这个接口或模型。请检查 API 地址和模型，改好后再点“生成”');
    expect(
      card(en, 402),
      'Insufficient balance / Insufficient Anlas. Please top up and try again',
    );
    expect(
      card(en, 401),
      'Authentication failed / Token invalid or expired. Please login again',
    );
    expect(
      card(en, 400),
      "Invalid request / Can't generate: NovelAI rejected these settings. "
      'Check the prompt and parameters, then click Generate',
    );
    expect(
      card(en, 403),
      "Access denied / Can't generate: this account doesn't have permission "
      'for this. Check your subscription or switch accounts, then click '
      'Generate',
    );
    expect(
      card(en, 404),
      "Not found / Can't generate: the server doesn't have this endpoint or "
      'model. Check the API address and the model, then click Generate',
    );
  });

  test('a run that skipped the requests NovelAI turned down says how many, '
      'points to Generate and has no Retry', () {
    // With a sequential or random block every request draws its own words,
    // so a 400 skips only that request and the run finishes with the
    // others. Retry would send a turned-down request as it was; the words
    // are fixed in the blocks and go out through Generate.
    const retryWording = {
      'en': ['try again', 'retry', 'Retry'],
      'ja': ['もう一度お試し', '再試行'],
      'ko': ['다시 시도'],
      'zh': ['重试'],
      'zh-TW': ['重試'],
    };
    const generate = {
      'en': 'then click Generate',
      'ja': '「生成」を押してください',
      'ko': '“생성”을 누르세요',
      'zh': '再点“生成”',
      'zh-TW': '再點“生成”',
    };
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      final l = lookupAppLocalizations(locale);
      for (final lastError in [
        ..._stream(_rejected(400)),
        _nonStream(_rejected(400), locale),
      ]) {
        for (final count in [1, 2, 5]) {
          final card = generationRejectedBatchesView(
            l,
            GenerationRejectedBatches(count: count, lastError: lastError),
          );
          final hint = card.hint!;
          // Titled as the page's 400 card; the hint says how many.
          expect(card.title, l.api_error_400, reason: tag);
          expect(hint, l.gen_rejectedRequestsHint(count), reason: tag);
          expect(hint, contains('$count'), reason: '$tag $hint');
          expect(hint, isNot(l.api_error_400_hint), reason: tag);
          expect(hint, endsWith(generate[tag]!), reason: '$tag $hint');
          for (final word in retryWording[tag]!) {
            expect(hint, isNot(contains(word)), reason: '$tag $hint');
          }
          expect(card.retry, isFalse, reason: tag);
          // Copy details: the last turned-down request's error, as it was.
          expect(card.detail, lastError);
          expect(card.copy, lastError);
        }
      }
      // Every other card keeps its Retry.
      for (final message in [
        null,
        ..._stream(_rejected(400)),
        generationStatusStoppedError(_rejected(400)),
        generationConcurrencyStoppedError('API_ERROR_429|locked'),
        'API_ERROR_HTTP_409|Conflict',
      ]) {
        expect(
          generationErrorView(l, message).retry,
          isTrue,
          reason: '$tag $message',
        );
      }
    }
  });

  test('the skipped requests read like this in Chinese and English', () {
    String card(AppLocalizations l, int count) {
      final error = generationRejectedBatchesView(
        l,
        GenerationRejectedBatches(
          count: count,
          lastError: 'Exception: API_ERROR_400|Bad request',
        ),
      );
      return '${error.title} / ${error.hint}';
    }

    final zh = lookupAppLocalizations(const Locale('zh'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      card(zh, 2),
      '请求无效 / 有 2 次请求抽到的词 NovelAI 不接受，已跳过，其余请求照常发送。'
      '请检查顺序或随机块里的词，改好后再点“生成”',
    );
    expect(
      card(en, 1),
      'Invalid request / NovelAI rejected the words drawn for 1 request, so it '
      'was skipped and the other requests were sent. Check the words in the '
      'sequential or random blocks, then click Generate',
    );
    expect(
      card(en, 3),
      'Invalid request / NovelAI rejected the words drawn for 3 requests, so '
      'they were skipped and the other requests were sent. Check the words in '
      'the sequential or random blocks, then click Generate',
    );
  });

  test('400, 403 and 404 send the user to Generate, not Retry', () {
    // Retry on the card sends the failed request again as it was, and only
    // for the account that sent it: a changed prompt, parameter or model, or
    // another account, goes out only through Generate.
    const retryWording = {
      'en': ['try again', 'retry', 'Retry'],
      'ja': ['もう一度お試し', '再試行'],
      'ko': ['다시 시도'],
      'zh': ['重试'],
      'zh-TW': ['重試'],
    };
    const generate = {
      'en': 'then click Generate',
      'ja': '「生成」を押してください',
      'ko': '“생성”을 누르세요',
      'zh': '再点“生成”',
      'zh-TW': '再點“生成”',
    };
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      final l = lookupAppLocalizations(locale);
      for (final hint in [
        l.api_error_400_hint,
        l.api_error_403_hint,
        l.api_error_404_hint,
      ]) {
        expect(hint, endsWith(generate[tag]!), reason: '$tag: $hint');
        expect(hint, isNot(contains(l.gen_retry)), reason: '$tag: $hint');
        for (final word in retryWording[tag]!) {
          expect(hint, isNot(contains(word)), reason: '$tag: $hint');
        }
      }
    }
  });

  test('in a style explore 400, 403, 404 and a waited-out 429 point to Retry '
      'failed candidates; everything else reads as on the page', () {
    // How each language's hint ends: Generate on the page, the explore's
    // Retry failed candidates button there.
    const onPage = {
      'en': 'then click Generate',
      'ja': '「生成」を押してください',
      'ko': '“생성”을 누르세요',
      'zh': '再点“生成”',
      'zh-TW': '再點“生成”',
    };
    String inExplore(String tag, String button) => switch (tag) {
      'en' => 'then click "$button"',
      'ja' => '「$button」を押してください',
      'ko' => '“$button”를 누르세요',
      'zh' => '再点“$button”',
      _ => '再點“$button”',
    };
    // How the page's 429 stop names its card's Retry (one word in English,
    // so no quotes).
    String onPageRetry(String tag, String button) => switch (tag) {
      'en' => 'then click $button',
      'ja' => '「$button」を押してください',
      'ko' => '“$button”를 누르세요',
      'zh' => '再点“$button”',
      _ => '再點“$button”',
    };
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      final l = lookupAppLocalizations(locale);
      final generate = onPage[tag]!;
      final retryFailed = inExplore(tag, l.explore_retryFailed);
      GenError explore(String message) => generationErrorView(
        l,
        message,
        place: GenerationErrorPlace.styleExplore,
      );
      for (final (status, hint) in [
        (400, l.explore_error400Hint),
        (403, l.explore_error403Hint),
        (404, l.explore_error404Hint),
      ]) {
        for (final message in [
          ..._stream(_rejected(status)),
          _nonStream(_rejected(status), locale),
          generationStatusStoppedError(_rejected(status)),
        ]) {
          final page = generationErrorView(l, message);
          final error = explore(message);
          expect(error.title, page.title, reason: '$tag $message');
          expect(error.hint, hint, reason: '$tag $message');
          expect(error.detail, page.detail);
          expect(error.copy, page.copy);
          // The same reason and steps as on the page; only the button the
          // hint ends with differs.
          expect(page.hint, endsWith(generate), reason: '$tag ${page.hint}');
          expect(hint, endsWith(retryFailed), reason: '$tag $hint');
          expect(
            hint.substring(0, hint.length - retryFailed.length),
            page.hint!.substring(0, page.hint!.length - generate.length),
            reason: tag,
          );
        }
      }
      // A 429 that waited out its time stops the explore. The page's hint
      // ends with the card's Retry; the explore has no such button, only
      // Retry failed candidates, which goes on with the candidates the stop
      // left. Around the button it is word for word the page's hint.
      final stopped = generationConcurrencyStoppedError(
        'API_ERROR_429|Concurrent generation is locked',
      );
      final onPageStop = generationErrorView(l, stopped);
      final inExploreStop = explore(stopped);
      final retry = onPageRetry(tag, l.gen_retry);
      final stopHint = inExploreStop.hint!;
      // Retry-After can exceed the remaining time even before all 90 seconds
      // have actually elapsed. Both pages explain the limit for the whole run.
      expect(onPageStop.hint, contains('90'), reason: tag);
      expect(stopHint, contains('90'), reason: tag);
      expect(inExploreStop.title, onPageStop.title, reason: tag);
      expect(stopHint, l.explore_concurrencyStoppedHint, reason: tag);
      expect(inExploreStop.detail, onPageStop.detail);
      expect(inExploreStop.copy, onPageStop.copy);
      expect(
        onPageStop.hint,
        contains(retry),
        reason: '$tag ${onPageStop.hint}',
      );
      expect(stopHint, contains(retryFailed), reason: '$tag $stopHint');
      expect(stopHint, isNot(contains(retry)), reason: '$tag $stopHint');
      expect(
        stopHint.replaceFirst(retryFailed, retry),
        onPageStop.hint,
        reason: tag,
      );
      for (final message in [
        for (final status in [401, 402, 429, 500, 502, 503])
          ..._stream(_rejected(status)),
        generationStatusStoppedError(_rejected(401)),
        generationStatusStoppedError(_rejected(402)),
        ..._stream(
          DioException.connectionError(
            requestOptions: _request,
            reason: 'Connection refused',
          ),
        ),
        ..._stream(
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: _request,
          ),
        ),
        'API_ERROR_HTTP_409|Conflict',
      ]) {
        expect(
          explore(message),
          generationErrorView(l, message),
          reason: '$tag $message',
        );
      }
    }
  });

  test('every reason an explore shows names only the button it has', () {
    // Where an explore shows why a candidate failed (hovering the failed
    // card, Reason in the inspector) the button to press is Retry failed
    // candidates. The generation page's Generate and its error card's Retry
    // are not there.
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      final l = lookupAppLocalizations(locale);
      // A button a text names: in quotes, “…” in Chinese and Korean and 「…」
      // in Japanese; English writes click "…", or click and one word.
      final named = switch (tag) {
        'en' => RegExp(r'click (?:"([^"]+)"|(\w+))'),
        'ja' => RegExp('「([^」]+)」'),
        _ => RegExp('“([^”]+)”'),
      };
      List<String?> buttons(String text) => [
        for (final match in named.allMatches(text))
          match.group(1) ?? match.group(2),
      ];
      final concurrency = generationConcurrencyStoppedError(
        'API_ERROR_429|Concurrent generation is locked',
      );
      // What the page names, so the pattern is known to find them.
      expect(buttons(generationErrorText(l, concurrency)!), [
        l.gen_retry,
      ], reason: tag);
      expect(
        buttons(generationErrorText(l, _stream(_rejected(400)).first)!),
        hasLength(1),
        reason: tag,
      );
      var count = 0;
      for (final message in [
        for (final status in [400, 401, 402, 403, 404, 429, 500, 502, 503])
          ..._stream(_rejected(status)),
        for (final status in [400, 401, 402, 403, 404, 429, 500, 503])
          _nonStream(_rejected(status), locale),
        for (final status in [400, 401, 402, 403, 404])
          generationStatusStoppedError(_rejected(status)),
        concurrency,
        ..._stream(
          DioException.connectionError(
            requestOptions: _request,
            reason: 'Connection refused',
          ),
        ),
        ..._stream(
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: _request,
          ),
        ),
      ]) {
        final text = generationErrorText(
          l,
          message,
          place: GenerationErrorPlace.styleExplore,
        )!;
        for (final button in buttons(text)) {
          expect(button, l.explore_retryFailed, reason: '$tag $message: $text');
          count++;
        }
      }
      // 400, 403 and 404 in every shape, and the 429 stop.
      expect(count, 3 * 4 + 1, reason: tag);
    }
  });

  test('on a prompt-set card a 400 points to the parameters or to Agent for '
      "the item's prompt; everything else reads as on the page", () {
    // The card's Generate writes the item's prompt into the draft again
    // before it sends, so a prompt fixed on the canvas does not go out. It
    // leaves the parameters, model and account as they are, so the page's
    // other hints work on the card. (A 429 that waited out its time reaches
    // the card without the stop marker: recordAgentPromptSetImages drops it.)
    const reasonFirst = {
      'en': "Can't generate: NovelAI rejected these settings. ",
      'ja': '生成できません：NovelAI がこの設定を受け付けませんでした。',
      'ko': '생성할 수 없습니다. NovelAI가 이 설정을 받아들이지 않았습니다. ',
      'zh': '无法生成：NovelAI 不接受这组设置。',
      'zh-TW': '無法生成：NovelAI 不接受這組設定。',
    };
    const onCard = {
      'en': 'then click Generate',
      'ja': '「生成」を押してください',
      'ko': '“생성”을 누르세요',
      'zh': '再点“生成”',
      'zh-TW': '再點“生成”',
    };
    const retryWording = {
      'en': ['try again', 'retry', 'Retry'],
      'ja': ['もう一度お試し', '再試行'],
      'ko': ['다시 시도'],
      'zh': ['重试'],
      'zh-TW': ['重試'],
    };
    for (final locale in AppLocalizations.supportedLocales) {
      final tag = locale.toLanguageTag();
      final l = lookupAppLocalizations(locale);
      GenError card(String message) => generationErrorView(
        l,
        message,
        place: GenerationErrorPlace.promptSet,
      );
      final hint = l.ag_psError400Hint;
      for (final message in [
        ..._stream(_rejected(400)),
        _nonStream(_rejected(400), locale),
        generationStatusStoppedError(_rejected(400)),
      ]) {
        final page = generationErrorView(l, message);
        final error = card(message);
        expect(error.title, page.title, reason: '$tag $message');
        expect(error.hint, hint, reason: '$tag $message');
        expect(error.detail, page.detail);
        expect(error.copy, page.copy);
      }
      // The page's reason first and the card's own Generate last; in between
      // it names Agent, which edits the card's item, for the prompt.
      expect(l.api_error_400_hint, startsWith(reasonFirst[tag]!), reason: tag);
      expect(hint, startsWith(reasonFirst[tag]!), reason: tag);
      expect(hint, endsWith(onCard[tag]!), reason: tag);
      expect(hint, contains('Agent'), reason: tag);
      expect(hint, isNot(l.api_error_400_hint), reason: tag);
      expect(hint, isNot(contains(l.gen_retry)), reason: tag);
      for (final word in retryWording[tag]!) {
        expect(hint, isNot(contains(word)), reason: '$tag: $hint');
      }
      for (final message in [
        for (final status in [401, 402, 403, 404, 429, 500, 502, 503])
          ..._stream(_rejected(status)),
        _nonStream(_rejected(403), locale),
        _nonStream(_rejected(404), locale),
        for (final status in [401, 402, 403, 404])
          generationStatusStoppedError(_rejected(status)),
        ..._stream(
          DioException.connectionError(
            requestOptions: _request,
            reason: 'Connection refused',
          ),
        ),
        ..._stream(
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: _request,
          ),
        ),
        'API_ERROR_HTTP_409|Conflict',
      ]) {
        expect(
          card(message),
          generationErrorView(l, message),
          reason: '$tag $message',
        );
      }
    }
  });

  test("a prompt-set card's 400 reads like this in Chinese and English", () {
    String card(AppLocalizations l) => generationErrorText(
      l,
      ApiErrorMapper.formatDioError(_rejected(400)),
      place: GenerationErrorPlace.promptSet,
    )!;
    expect(
      card(lookupAppLocalizations(const Locale('zh'))),
      '请求无效\n无法生成：NovelAI 不接受这组设置。请检查参数，或让 Agent 修改这一项的提示词，改好后再点“生成”',
    );
    expect(
      card(lookupAppLocalizations(const Locale('en'))),
      "Invalid request\nCan't generate: NovelAI rejected these settings. "
      "Check the parameters, or ask Agent to edit this item's prompt, then "
      'click Generate',
    );
  });
}
