import 'package:uuid/uuid.dart';
import '../../data/models/image/image_params.dart';
import '../utils/max_enhance_utils.dart';
import '../services/opus_price_check.dart';
import 'agent_tool.dart';

class NaiAgentConversationOwner {
  const NaiAgentConversationOwner(this.workspaceId, this.chatId);
  final String workspaceId, chatId;
}

class NaiAgentGenerationInput {
  NaiAgentGenerationInput({
    required this.raw,
    required this.effective,
    required this.draftVersion,
    required this.batchSize,
    required this.billing,
    required this.accountId,
    required this.accountName,
    required this.endpoint,
    this.promptContextVersion = '',
    this.workflowGuard,
    this.localEnhance,
    this.blockedReason,
    this.sourceOperation,
    this.sourceImageId,
    bool freeOnLowOpusQuota = false,
    OpusPriceCheck? opusPriceCheck,
  }) : opusPriceCheck =
           opusPriceCheck ??
           (freeOnLowOpusQuota ? OpusPriceCheck.low : OpusPriceCheck.none);
  final ImageParams raw, effective;
  final String draftVersion, accountName, endpoint, promptContextVersion;
  final String? accountId, blockedReason;
  final String? sourceOperation, sourceImageId;
  final int batchSize;
  final Map<String, dynamic> billing;
  final Object? workflowGuard;
  final Map<String, dynamic>? localEnhance;

  final OpusPriceCheck opusPriceCheck;
  bool get freeOnLowOpusQuota => opusPriceCheck == OpusPriceCheck.low;
  int get estimate => billing['estimated_anlas'] as int;
  int? get balance => billing['balance_anlas'] as int?;
  ({int width, int height}) get outputSize =>
      effective.upscaledEnhance &&
          MaxEnhanceMath.isEligible(
            effective.model,
            effective.width,
            effective.height,
          )
      ? MaxEnhanceMath.targetSize(effective.width, effective.height)
      : (width: effective.width, height: effective.height);
  bool sameRequest(NaiAgentGenerationInput other) =>
      draftVersion == other.draftVersion &&
      accountId == other.accountId &&
      endpoint == other.endpoint &&
      batchSize == other.batchSize &&
      sourceOperation == other.sourceOperation &&
      sourceImageId == other.sourceImageId &&
      raw.copyWith(advancedOptionsExpanded: false) ==
          other.raw.copyWith(advancedOptionsExpanded: false) &&
      // Native random aliases may resolve differently at every read. Guard
      // their definitions, not a transient random projection of those aliases.
      promptContextVersion == other.promptContextVersion &&
      workflowGuard == other.workflowGuard &&
      estimate == other.estimate &&
      balance == other.balance &&
      billing['per_request_anlas'] == other.billing['per_request_anlas'] &&
      billing['encoding_anlas'] == other.billing['encoding_anlas'];
}

class NaiAgentGenerationQuote {
  NaiAgentGenerationQuote({
    required this.id,
    required this.input,
    required this.params,
    required this.expiresAt,
  });
  final String id;
  final NaiAgentGenerationInput input;
  final Map<String, dynamic> params;
  final DateTime expiresAt;
  bool approved = false, reserved = false;
  Map<String, dynamic> toJson() => {
    'quote_id': id,
    'expires_at': expiresAt.toIso8601String(),
    'action': input.raw.action.name,
    'account_name': input.accountName,
    'draft_version': input.draftVersion,
    'model': input.effective.model,
    'model_constraints': input.effective.modelSpec.requestConstraints,
    'width': input.outputSize.width,
    'height': input.outputSize.height,
    if (input.sourceOperation != null) ...{
      'source_operation': input.sourceOperation,
      'source_image_id': input.sourceImageId,
      'request_width': input.effective.width,
      'request_height': input.effective.height,
      'strength': input.effective.strength,
      'noise': input.effective.noise,
      'max_enhance': input.effective.upscaledEnhance,
      'prompt': input.effective.prompt,
      'negative_prompt': input.effective.negativePrompt,
    },
    'steps': input.effective.steps,
    'sampler': input.effective.sampler,
    'requests': input.raw.nSamples,
    'images_per_request': input.batchSize,
    'samples': input.raw.nSamples * input.batchSize,
    ...input.billing,
    'local_enhance': input.localEnhance,
    'can_generate': input.blockedReason == null,
    'blocked_reason': input.blockedReason,
    'authorization': 'explicit_user_button_required',
  };
}

class NaiAgentGenerationRun {
  NaiAgentGenerationRun({
    required this.id,
    required this.completion,
    required this.cancel,
  });
  final String id;
  final Future<Map<String, dynamic>> completion;

  /// Returns false if a newer/manual run has taken over.
  final bool Function() cancel;
}

/// Quotes and button authorization are owned by one official Pi conversation.
/// No model-supplied authorization flag is consulted, and nothing auto-resumes.
class NaiAgentGenerationTools {
  NaiAgentGenerationTools({
    required this.readInput,
    required this.approve,
    required this.backup,
    required this.start,
    required this.isAlive,
    this.recheckBalance,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final NaiAgentGenerationInput Function(Map<String, dynamic>) readInput;
  final Future<bool> Function(
    NaiAgentGenerationQuote,
    NaiAgentCancellation,
    void Function(),
  )
  approve;
  final Future<String> Function(NaiAgentGenerationInput) backup;
  final NaiAgentGenerationRun? Function(NaiAgentGenerationInput) start;
  final bool Function() isAlive;

  /// A price check and a balance check use the same subscription request.
  /// Fresh depleted quotes reuse the last check; an expired existing quote
  /// must still match the price returned before the user approves it.
  final Future<void> Function()? recheckBalance;
  final DateTime Function() clock;
  final _quotes = <String, NaiAgentGenerationQuote>{};
  NaiAgentGenerationRun? _active;
  String? _lastRunId;
  String? get activeId => _active?.id;

  /// Reasons that come from the cached balance, not from the request.
  static const balanceBlocks = {'insufficient_balance', 'balance_unavailable'};

  NaiAgentGenerationQuote _prepareQuote(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio owner closed');
    }
    final requests = params['requests'], size = params['images_per_request'];
    if ((requests != null &&
            (requests is! int || requests < 1 || requests > 999)) ||
        (size != null && (size is! int || size < 1 || size > 4))) {
      throw const NaiAgentToolError(
        'invalid_batch',
        'Use 1 to 999 requests and 1 to 4 images per request',
      );
    }
    return NaiAgentGenerationQuote(
      id: const Uuid().v4(),
      input: readInput(params),
      params: Map.unmodifiable(params),
      expiresAt: clock().add(const Duration(minutes: 5)),
    );
  }

  /// Read the request again after a necessary balance or quota check.
  Future<NaiAgentGenerationQuote> _quoteOnFreshBalance(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    final quote = _prepareQuote(params, token);
    final recheck = recheckBalance;
    if (recheck == null ||
        !quote.input.opusPriceCheck.needsRefresh(
          balanceWouldBlock: balanceBlocks.contains(quote.input.blockedReason),
        )) {
      return quote;
    }
    await recheck();
    return _prepareQuote(params, token);
  }

  Future<Map<String, dynamic>> prepare(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    final quote = await _quoteOnFreshBalance(params, token);
    _quotes.removeWhere(
      (_, quote) => !quote.expiresAt.isAfter(clock()) && !quote.reserved,
    );
    if (_quotes.length >= 20) {
      final disposable = _quotes.values.where((q) => !q.reserved).firstOrNull;
      if (disposable == null) {
        throw const NaiAgentToolError(
          'quote_busy',
          'Generation requests are already pending',
        );
      }
      _quotes.remove(disposable.id);
    }
    _quotes[quote.id] = quote;
    return naiAgentTextResult({'quote': quote.toJson()});
  }

  Future<Map<String, dynamic>> run(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    token.check();
    final recheck = recheckBalance;
    final waiting = _quotes[params['quote_id']];
    if (recheck != null &&
        waiting != null &&
        !waiting.reserved &&
        _needsPreSubmitCheck(waiting.params)) {
      await recheck();
      token.check();
    }
    // Looked up after any wait: a quote another run took meanwhile is gone.
    final quote = _quotes[params['quote_id']];
    if (quote == null) {
      throw const NaiAgentToolError(
        'quote_missing',
        'Prepare a new generation quote in this chat',
      );
    }
    return _run(quote, token);
  }

  /// An existing quote may need a fresh balance or depleted-quota check.
  /// A read that fails is left to the run's own validation.
  bool _needsPreSubmitCheck(Map<String, dynamic> params) {
    try {
      final current = readInput(params);
      return current.opusPriceCheck.needsRefresh(
        balanceWouldBlock: balanceBlocks.contains(current.blockedReason),
        checkLow: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _run(
    NaiAgentGenerationQuote quote,
    NaiAgentCancellation token, {
    bool userButton = false,
  }) async {
    if (quote.reserved) {
      throw const NaiAgentToolError(
        'quote_in_use',
        'This quote is already waiting or running',
      );
    }
    NaiAgentGenerationInput check() {
      token.check();
      if (!isAlive()) {
        throw const NaiAgentToolError('closed', 'Studio owner closed');
      }
      if (!quote.expiresAt.isAfter(clock())) {
        throw const NaiAgentToolError('quote_expired', 'Prepare a fresh quote');
      }
      final current = readInput(quote.params);
      if (!quote.input.sameRequest(current)) {
        throw const NaiAgentToolError(
          'quote_changed',
          'Draft, account, references or price changed; prepare again',
        );
      }
      if (current.blockedReason != null) {
        throw NaiAgentToolError(
          current.blockedReason!,
          'Generation is not ready: ${current.blockedReason}',
        );
      }
      return current;
    }

    quote.reserved = true;
    try {
      check();
      if (!userButton && !quote.approved) {
        final accepted = await approve(quote, token, check);
        if (!accepted) {
          _quotes.remove(quote.id);
          return naiAgentTextResult({
            'status': 'cancelled',
            'quote_id': quote.id,
          });
        }
        check();
        quote.approved = true;
      }
      final path = await backup(quote.input);
      final atSubmission = check();
      final refresh = recheckBalance;
      if (refresh != null &&
          atSubmission.opusPriceCheck == OpusPriceCheck.exhausted) {
        await refresh();
        check();
      }
      final job = start(quote.input);
      if (job == null) {
        throw const NaiAgentToolError(
          'not_started',
          'Studio rejected this start; no generation was admitted',
        );
      }
      _quotes.remove(quote.id); // Once admitted, never replay, even on failure.
      _active = job;
      _lastRunId = job.id;
      token.whenCancelled.then((_) {
        if (identical(_active, job)) job.cancel();
      });
      try {
        final result = await job.completion;
        return naiAgentTextResult({
          ...result,
          'run_id': job.id,
          'quote_id': quote.id,
          'backup_path': path,
          'estimated_anlas': quote.input.estimate,
          'balance_before_anlas': quote.input.balance,
          'actual_anlas': null,
          'authorization': {'source': 'user_button', 'quote_id': quote.id},
        });
      } finally {
        if (identical(_active, job)) _active = null;
      }
    } catch (_) {
      if (token.isCancelled) _quotes.remove(quote.id);
      rethrow;
    } finally {
      quote.reserved = false;
    }
  }

  /// Only the human prompt-set card action calls this Dart entry point. That
  /// click authorizes one image, not a reusable approval for a model tool.
  /// Keep its fresh quote out of _quotes, including on backup/admission failure.
  /// All readiness, backup, rechecks, native ownership and collection stay in
  /// the shared pipeline. No model parameter can select this authorization.
  Future<Map<String, dynamic>> requestUserGeneration(
    NaiAgentCancellation token,
  ) async => _run(
    await _quoteOnFreshBalance({'requests': 1, 'images_per_request': 1}, token),
    token,
    userButton: true,
  );

  Future<Map<String, dynamic>> cancel(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    token.check();
    final id = params['run_id'];
    if (id != null && id != _active?.id && id != _lastRunId) {
      throw const NaiAgentToolError(
        'run_not_owned',
        'This chat does not own the requested generation',
      );
    }
    final active = _active;
    return naiAgentTextResult({
      'run_id': active?.id ?? _lastRunId,
      'status': active == null
          ? 'already_finished'
          : active.cancel()
          ? 'cancelling'
          : 'already_finished',
    });
  }
}
