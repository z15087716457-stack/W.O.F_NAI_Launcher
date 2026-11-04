import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/anlas_calculator.dart';
import '../../core/utils/app_logger.dart';
// 价按屏幕上那份缓存的账号算：读已经在的订阅与登录状态，不新建、不查余额。
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/subscription_provider.dart';
import '../models/image/image_params.dart';
import '../models/user/user_subscription.dart';
import 'anlas_statistics_service.dart';

/// 每次计费的 NovelAI 请求按应用给它算的价记一笔（用户 2026-10-31 定：
/// 「按每次请求的价格记」）。
///
/// 记账放在 NovelAI 图像接口服务里（`NAIImageGenerationApiService`、
/// `NAIImageEnhancementApiService`）：生图（流式和非流式）、云端放大、Vibe
/// 编码、导演工具都只经过这两个服务，生图页、重试、变体、画风探索、Agent、
/// 提示词组卡、Krita／外部桥接因此一个也漏不掉。请求发出前按请求本身和缓存的
/// 账号算价，与界面价签、Agent／桥接报价同一套算法；NovelAI 把结果交回来后
/// 记一次。失败、被拒、NovelAI 交回结果前取消的请求不记；ComfyUI、本地放大、
/// 标签联想等不经过这里。
///
/// 不发任何请求、不读余额，所以之后点余额不会把同一笔再记一遍。记账出错只写
/// 日志，不影响请求本身。
class AnlasRequestLedger {
  AnlasRequestLedger({
    required UserSubscription? Function() readAccount,
    required Future<void> Function(int anlas, DateTime at) record,
  }) : _readAccount = readAccount,
       _record = record;

  /// 缓存的账号；拿不到为 null，按非 Opus 算（与界面相同）。
  final UserSubscription? Function() _readAccount;

  /// 把一笔记进每日统计和当天明细（[AnlasStatisticsService.recordCost]）。
  final Future<void> Function(int anlas, DateTime at) _record;

  /// 一次生图请求（流式或非流式）；[request] 的 `nSamples` 是这次请求的张数。
  /// Opus 免费的那张按缓存的额度算，免费就记 0，和价签一致。Vibe 编码费不在
  /// 这里：每次编码请求自己记一笔（[vibeEncoding]）。
  AnlasCharge generation(ImageParams request) => _charge('generation', () {
    final account = _readAccount();
    return AnlasCalculator.requestCostForParams(
      request,
      batchSize: math.max(1, request.nSamples),
      isOpus: account?.isOpus == true,
      opusUsageExhausted: account?.isOpusUsageExhausted ?? false,
    );
  });

  /// 一次云端放大，按源图尺寸（固定 2x，Opus 不免）。
  AnlasCharge upscale({required int width, required int height}) => _charge(
    'upscale',
    () => AnlasCalculator.calculateNovelAiUpscaleCost(
      inputWidth: width,
      inputHeight: height,
    ),
  );

  /// 一次 Vibe 编码（生成前编码、编码按钮、请求组装时补编码都算）。
  AnlasCharge vibeEncoding() =>
      _charge('vibe encoding', () => AnlasCalculator.vibeEncodingCost);

  /// 一次导演工具（augment-image），按源图尺寸；去背景另有定价。
  AnlasCharge directorTool({
    required int width,
    required int height,
    required bool backgroundRemoval,
  }) => _charge(
    'director tool',
    () => AnlasCalculator.calculateAugmentCost(
      width: width,
      height: height,
      isBgRemoval: backgroundRemoval,
      isOpus: _readAccount()?.isOpus == true,
    ),
  );

  AnlasCharge _charge(String kind, int Function() price) {
    var anlas = AnlasCalculator.invalidCost;
    try {
      anlas = price();
    } catch (error) {
      AppLogger.w('No Anlas price for a $kind request: $error', 'AnlasLedger');
    }
    return AnlasCharge._(this, kind, anlas);
  }
}

/// 一个请求的价：发出前算好，NovelAI 交回结果后 [delivered] 记一笔。
class AnlasCharge {
  AnlasCharge._(this._ledger, this._kind, this.anlas);

  final AnlasRequestLedger _ledger;
  final String _kind;

  /// 这次请求的价；小于 0 是算不出来（如尺寸超出计价范围），不记。
  final int anlas;

  bool _delivered = false;

  /// NovelAI 交回了这次请求的结果：记一笔，只记一次。不等记完，也不抛错。
  void delivered() {
    if (_delivered) return;
    _delivered = true;
    if (anlas < 0) {
      AppLogger.w(
        'A delivered $_kind request has no price; not recorded',
        'AnlasLedger',
      );
      return;
    }
    void failed(Object error) =>
        AppLogger.w('Could not record a $_kind request: $error', 'AnlasLedger');
    try {
      unawaited(_ledger._record(anlas, DateTime.now()).catchError(failed));
    } catch (error) {
      failed(error);
    }
  }
}

/// 缓存的账号：已载入的订阅（屏幕上显示的那份），没有就用登录验证带回的那份；
/// 与 Agent／桥接报价读的是同一份。两个 provider 不在时不新建它们，也就不会
/// 因为记账去查余额。
UserSubscription? cachedAnlasAccount(Ref ref) {
  if (ref.exists(subscriptionNotifierProvider)) {
    final loaded = ref.read(subscriptionNotifierProvider).subscription;
    if (loaded != null) return loaded;
  }
  if (!ref.exists(authNotifierProvider)) return null;
  final raw = ref.read(authNotifierProvider).subscriptionInfo;
  return raw == null ? null : UserSubscription.fromJson(raw);
}

final anlasRequestLedgerProvider = Provider<AnlasRequestLedger>(
  (ref) => AnlasRequestLedger(
    readAccount: () => cachedAnlasAccount(ref),
    record: (anlas, at) async {
      final statistics = await ref.read(anlasStatisticsServiceProvider.future);
      await statistics.recordCost(anlas, date: at);
    },
  ),
);
