import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/services.dart';

import '../../data/models/character/character_prompt.dart';
import '../constants/model_spec.dart';
import '../utils/nai_prompt_parser.dart';

class PromptTokenUsage {
  const PromptTokenUsage({
    required this.usedTokens,
    required this.limit,
    this.breakdown = const [],
  });

  final int usedTokens;
  final int limit;
  final List<PromptTokenBreakdownEntry> breakdown;

  bool get isOverLimit => usedTokens > limit;
}

class PromptTokenBreakdownEntry {
  const PromptTokenBreakdownEntry({
    required this.label,
    required this.tokens,
  });

  final String label;
  final int tokens;
}

abstract class PromptTokenEncoder {
  Future<int> countTokens(String text);
}

class PromptTokenCounterService {
  const PromptTokenCounterService({
    required PromptTokenEncoder encoder,
  }) : _encoder = encoder;

  static const int v4PromptTokenLimit = 512;

  /// V5 提示词上限（静 2026-08-21 确认：正向合计 1471，负向合计同为 1471）。
  static const int v5PromptTokenLimit = 1471;
  static const String _t5TokenizerAssetPath =
      'assets/data/tokenizers/t5_spiece.model';

  final PromptTokenEncoder _encoder;

  static bool supportsPromptTokenCount(String model) {
    return ModelSpecs.of(model).v4Prompts;
  }

  static int? tokenLimitForModel(String model) {
    final spec = ModelSpecs.of(model);
    if (!spec.v4Prompts) {
      return null;
    }
    return spec.isV5 ? v5PromptTokenLimit : v4PromptTokenLimit;
  }

  static Future<PromptTokenCounterService> createDefault() async {
    final encoder = await T5PromptTokenEncoder.load(
      assetPath: _t5TokenizerAssetPath,
    );
    return PromptTokenCounterService(encoder: encoder);
  }

  Future<PromptTokenUsage?> countUsageFromTexts({
    required String model,
    required String mainText,
    Iterable<String> extraTexts = const [],
    bool applyWebAdjustment = true,
    List<PromptTokenBreakdownEntry> breakdown = const [],
  }) async {
    final limit = tokenLimitForModel(model);
    if (limit == null) {
      return null;
    }

    final usedTokens = await countTokensForTexts(
      _collectCountedTexts(
        mainText: mainText,
        extraTexts: extraTexts,
      ),
      applyWebAdjustment: applyWebAdjustment,
    );

    return PromptTokenUsage(
      usedTokens: usedTokens,
      limit: limit,
      breakdown: breakdown,
    );
  }

  Future<PromptTokenUsage?> countUsage({
    required String model,
    required String basePrompt,
    required List<CharacterPrompt> characters,
    bool applyWebAdjustment = true,
  }) async {
    return countUsageFromTexts(
      model: model,
      mainText: basePrompt,
      extraTexts: characters
          .where((character) => character.enabled)
          .map((character) => character.prompt),
      applyWebAdjustment: applyWebAdjustment,
    );
  }

  Future<int> countTokensForTexts(
    Iterable<String> texts, {
    bool applyWebAdjustment = false,
  }) async {
    var usedTokens = 0;
    for (final text in texts) {
      final normalizedText = _normalizePromptForCounting(text);
      if (normalizedText.isEmpty) {
        continue;
      }
      usedTokens += await _encoder.countTokens(normalizedText);
    }

    if (applyWebAdjustment && usedTokens > 0) {
      usedTokens += 1;
    }

    return usedTokens;
  }

  Iterable<String> _collectCountedTexts({
    required String mainText,
    required Iterable<String> extraTexts,
  }) sync* {
    final trimmedMainText = mainText.trim();
    if (trimmedMainText.isNotEmpty) {
      yield trimmedMainText;
    }

    for (final text in extraTexts) {
      final trimmedText = text.trim();
      if (trimmedText.isEmpty) {
        continue;
      }
      yield trimmedText;
    }
  }

  static String _normalizePromptForCounting(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final normalizedBuffer = StringBuffer();
    final segmentBuffer = StringBuffer();
    var braceDepth = 0;
    var bracketDepth = 0;
    var parenDepth = 0;
    var inPipe = false;

    void flushSegment() {
      if (segmentBuffer.length == 0) {
        return;
      }
      normalizedBuffer.write(
        _stripSegmentWeightSyntaxPreservingWhitespace(segmentBuffer.toString()),
      );
      segmentBuffer.clear();
    }

    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];

      if (char == '{') {
        braceDepth++;
      } else if (char == '}') {
        braceDepth--;
      } else if (char == '[') {
        bracketDepth++;
      } else if (char == ']') {
        bracketDepth--;
      } else if (char == '(') {
        parenDepth++;
      } else if (char == ')') {
        parenDepth--;
      }

      if (char == '|' &&
          i + 1 < trimmed.length &&
          trimmed[i + 1] == '|') {
        inPipe = !inPipe;
        segmentBuffer.write('||');
        i++;
        continue;
      }

      if (char == ',' &&
          braceDepth == 0 &&
          bracketDepth == 0 &&
          parenDepth == 0 &&
          !inPipe) {
        flushSegment();
        normalizedBuffer.write(',');
        continue;
      }

      segmentBuffer.write(char);
    }

    flushSegment();

    final normalized = normalizedBuffer.toString().trim();
    return normalized.isEmpty ? trimmed : normalized;
  }

  static String _stripSegmentWeightSyntaxPreservingWhitespace(String segment) {
    final leadingWhitespaceLength = segment.length - segment.trimLeft().length;
    final trailingWhitespaceLength = segment.length - segment.trimRight().length;
    final leadingWhitespace =
        segment.substring(0, leadingWhitespaceLength);
    final trailingWhitespace = segment.substring(
      segment.length - trailingWhitespaceLength,
    );
    final core = segment.trim();
    if (core.isEmpty) {
      return segment;
    }

    final strippedCore = NaiPromptParser.stripWeightSyntax(core);
    return '$leadingWhitespace$strippedCore$trailingWhitespace';
  }
}

class T5PromptTokenEncoder implements PromptTokenEncoder {
  T5PromptTokenEncoder._(this._tokenizer);

  static Future<T5PromptTokenEncoder>? _instanceFuture;

  final SentencePieceTokenizer _tokenizer;

  static Future<T5PromptTokenEncoder> load({
    required String assetPath,
  }) {
    return _instanceFuture ??= _loadFromAsset(assetPath);
  }

  static Future<T5PromptTokenEncoder> _loadFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final tokenizer = SentencePieceTokenizer.fromBytes(
      data.buffer.asUint8List(),
      config: const SentencePieceConfig(),
    );
    return T5PromptTokenEncoder._(tokenizer);
  }

  @override
  Future<int> countTokens(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final encoding = _tokenizer.encode(
      normalized,
      addSpecialTokens: false,
    );
    return encoding.ids.length;
  }
}
