import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import '../../core/storage/prompt_block_storage.dart';
import 'prompt_block_library_provider.dart';

part 'prompt_block_palette_provider.g.dart';

/// 颜料版状态：按用户排序解析后的块列表 + 库文件夹快照
/// （供悬停预览显示块所在路径，复用现有 library 依赖边）。
///
/// 板上只存块 ID 引用（不拷贝内容），解析时对库做一次 join——库里
/// 改块内容后板上自动跟随；指向已删块的 ID 在解析时被修剪并回写。
class PromptBlockPaletteState {
  PromptBlockPaletteState({
    required List<PromptBlock> blocks,
    List<PromptBlockFolder> folders = const [],
  }) : blocks = List.unmodifiable(blocks),
       folders = List.unmodifiable(folders);

  final List<PromptBlock> blocks;

  /// 库文件夹快照（随库 provider 重建同步刷新）。
  final List<PromptBlockFolder> folders;

  bool get isEmpty => blocks.isEmpty;

  bool contains(String blockId) => blocks.any((block) => block.id == blockId);
}

/// 颜料版：固定词的手动替代——用户把常用块「收纳」到悬浮窗里，
/// 用时点击插到光标处或拖进提示词框。不做任何自动拼装。
@Riverpod(keepAlive: true)
class PromptBlockPaletteNotifier extends _$PromptBlockPaletteNotifier {
  late PromptBlockStorage _storage;

  @override
  Future<PromptBlockPaletteState> build() async {
    final library = await ref.watch(promptBlockLibraryNotifierProvider.future);
    _storage = ref.watch(promptBlockStorageProvider);
    final ids = await _storage.getPaletteBlockIds();

    final resolved = <PromptBlock>[];
    final liveIds = <String>[];
    for (final id in ids) {
      final block = library.blockById(id);
      if (block != null) {
        resolved.add(block);
        liveIds.add(id);
      }
    }
    // 库删块 → 板上引用同步消失，回写清理后的 id 表。
    if (liveIds.length != ids.length) {
      unawaited(_storage.putPaletteBlockIds(liveIds));
    }
    return PromptBlockPaletteState(blocks: resolved, folders: library.folders);
  }

  /// 收纳一个块（幂等：同块只收一次）。
  Future<void> addBlock(String blockId) =>
      _update((ids) => ids.contains(blockId) ? null : [...ids, blockId]);

  /// 收纳到指定下标；已在板上的块视为移动到该下标。
  Future<void> insertBlock(String blockId, int index) => _update((ids) {
    final next = ids.where((id) => id != blockId).toList();
    next.insert(index.clamp(0, next.length), blockId);
    return next;
  });

  /// 从板上移除一个块（不动库）。
  Future<void> removeBlock(String blockId) => _update(
    (ids) => ids.contains(blockId)
        ? ids.where((id) => id != blockId).toList()
        : null,
  );

  /// 板内移动。索引语义与 ReorderableListView.onReorder 一致：
  /// [newIndex] 已是「移除旧项之后」的坐标系，直接使用。
  Future<void> move(int oldIndex, int newIndex) => _update((ids) {
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex >= ids.length) {
      return null;
    }
    final next = [...ids];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    return next;
  });

  /// 变换并持久化 id 表；[transform] 返回 null 表示无变更。
  Future<void> _update(
    List<String>? Function(List<String> ids) transform,
  ) async {
    // 按钮在 provider 尚未完成初始 build 时也可能收拖放——先等 build
    // 落定再写，否则完成后返回的 build 结果会盖掉本次变更。await 之后
    // 不能再碰 ref（依赖可能恰在期间变更而触发 outdated 断言），所以
    // storage 走 build 期缓存的字段，写完统一 invalidateSelf 让重建
    // 按库最新状态重新解析。
    await future;
    final next = transform(await _storage.getPaletteBlockIds());
    if (next == null) return;
    await _storage.putPaletteBlockIds(next);
    ref.invalidateSelf();
  }
}
