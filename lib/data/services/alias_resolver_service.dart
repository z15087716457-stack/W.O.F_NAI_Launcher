import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/alias_parser.dart';
import '../../core/utils/app_logger.dart';
import '../../presentation/providers/prompt_block_library_provider.dart';
import '../models/prompt_block/prompt_block.dart';

part 'alias_resolver_service.g.dart';

/// 别名解析服务
///
/// 负责将别名引用（`<块标题>` 及随机/权重语法）解析为实际的提示词内容。
/// 数据源自全局 Prompt 块库；旧本地词库条目带原 ID 迁入后按标题命中。
///
/// 块库状态是异步加载的：启动侧由 `AppBootstrapEffects` 预热点 provider，
/// 这里按已加载快照同步读取；快照未就绪时按空库处理（别名原样保留）。
@Riverpod(keepAlive: true)
class AliasResolverService extends _$AliasResolverService {
  @override
  void build() {
    // 初始化时不需要特殊操作
  }

  /// 已加载的块快照；块库加载中/失败时为空表。
  List<PromptBlock> get _blocks {
    return ref.read(promptBlockLibraryNotifierProvider).valueOrNull?.blocks ??
        const [];
  }

  /// 解析文本中的所有别名引用
  ///
  /// [text] 包含别名的原始文本
  /// 返回解析后的文本（别名被替换为实际内容）
  String resolveAliases(String text) {
    if (text.isEmpty) return text;

    final references = AliasParser.parse(text);
    if (references.isEmpty) return text;

    // 按位置倒序处理（从后往前替换，避免位置偏移）
    final sortedRefs = references.toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    String result = text;
    for (final ref in sortedRefs) {
      final resolvedContent = _resolveReference(ref);
      if (resolvedContent != null) {
        result = result.replaceRange(ref.start, ref.end, resolvedContent);
      } else {
        // 别名未找到，记录警告
        AppLogger.w('别名未找到: ${ref.rawText}，请检查块库中是否存在该块', 'AliasResolver');
      }
    }

    return result;
  }

  /// 获取别名的详细信息（用于悬停浮窗）
  ///
  /// 返回对应的块，若别名无效则返回 null
  PromptBlock? getAliasEntry(AliasReference reference) {
    if (reference.type != AliasReferenceType.simple) {
      return null;
    }

    return findEntryByName(reference.primaryName);
  }

  /// 根据标题查找块（不区分大小写）
  PromptBlock? findEntryByName(String name) {
    if (name.isEmpty) return null;

    final lowerName = name.toLowerCase();
    for (final block in _blocks) {
      if (block.title.toLowerCase() == lowerName) {
        return block;
      }
    }
    return null;
  }

  /// 检查别名是否有效（对应的块存在）
  bool isAliasValid(AliasReference reference) {
    return getAliasEntry(reference) != null;
  }

  /// 检查名称对应的块是否存在
  bool isEntryNameValid(String name) {
    return findEntryByName(name) != null;
  }

  /// 搜索块（用于智能补全）
  ///
  /// [query] 搜索关键词
  /// [limit] 最大返回数量
  List<PromptBlock> searchEntries(String query, {int limit = 15}) {
    final blocks = _blocks;

    if (query.isEmpty) {
      // 返回最近使用的块
      final sorted = blocks.toList()
        ..sort((a, b) {
          // 先按收藏排序
          if (a.isFavorite != b.isFavorite) {
            return a.isFavorite ? -1 : 1;
          }
          // 再按使用次数排序
          return b.useCount.compareTo(a.useCount);
        });
      return sorted.take(limit).toList();
    }

    final lowerQuery = query.toLowerCase();

    // 搜索标题匹配的块
    final matches = <(PromptBlock, int)>[];
    for (final block in blocks) {
      final lowerTitle = block.title.toLowerCase();

      // 计算匹配分数
      int score = 0;

      // 完全匹配
      if (lowerTitle == lowerQuery) {
        score = 100;
      }
      // 前缀匹配
      else if (lowerTitle.startsWith(lowerQuery)) {
        score = 80;
      }
      // 包含匹配
      else if (lowerTitle.contains(lowerQuery)) {
        score = 60;
      }
      // 内容匹配
      else if (block.content.toLowerCase().contains(lowerQuery)) {
        score = 40;
      }

      if (score > 0) {
        // 收藏块加分
        if (block.isFavorite) score += 10;
        matches.add((block, score));
      }
    }

    // 按分数排序
    matches.sort((a, b) => b.$2.compareTo(a.$2));

    return matches.take(limit).map((m) => m.$1).toList();
  }

  /// 记录块使用（当别名被解析时调用）
  Future<void> recordEntryUsage(String entryName) async {
    final block = findEntryByName(entryName);
    if (block != null) {
      final notifier = ref.read(promptBlockLibraryNotifierProvider.notifier);
      await notifier.incrementUseCount(block.id);
    }
  }

  /// 解析单个引用
  String? _resolveReference(AliasReference ref) {
    switch (ref.type) {
      case AliasReferenceType.simple:
        return _resolveSimpleReference(ref.primaryName);
      case AliasReferenceType.random:
        // 预留：随机选择一个块
        return _resolveRandomReference(ref.entryNames);
      case AliasReferenceType.weighted:
        // 预留：按权重随机选择
        return _resolveWeightedReference(ref.entryNames, ref.weights);
    }
  }

  /// 解析简单引用
  String? _resolveSimpleReference(String entryName) {
    final block = findEntryByName(entryName);
    return block?.content;
  }

  /// 解析随机引用（预留）
  String? _resolveRandomReference(List<String> entryNames) {
    // 随机选择一个有效的块
    final validBlocks = <PromptBlock>[];
    for (final name in entryNames) {
      final block = findEntryByName(name);
      if (block != null) {
        validBlocks.add(block);
      }
    }

    if (validBlocks.isEmpty) return null;

    // 随机选择
    final random = DateTime.now().microsecondsSinceEpoch % validBlocks.length;
    return validBlocks[random].content;
  }

  /// 解析带权重的随机引用（预留）
  String? _resolveWeightedReference(
    List<String> entryNames,
    Map<String, double>? weights,
  ) {
    if (weights == null || weights.isEmpty) {
      return _resolveRandomReference(entryNames);
    }

    // 收集有效块和权重
    final validBlocks = <(PromptBlock, double)>[];
    double totalWeight = 0;

    for (final name in entryNames) {
      final block = findEntryByName(name);
      if (block != null) {
        final weight = weights[name] ?? 1.0;
        validBlocks.add((block, weight));
        totalWeight += weight;
      }
    }

    if (validBlocks.isEmpty || totalWeight <= 0) return null;

    // 按权重随机选择
    final randomValue =
        (DateTime.now().microsecondsSinceEpoch % 10000) / 10000 * totalWeight;
    double cumulative = 0;

    for (final (block, weight) in validBlocks) {
      cumulative += weight;
      if (randomValue < cumulative) {
        return block.content;
      }
    }

    // 兜底返回最后一个
    return validBlocks.last.$1.content;
  }
}
