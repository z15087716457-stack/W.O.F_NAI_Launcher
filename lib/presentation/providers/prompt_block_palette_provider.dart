import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/localization_extension.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import '../../data/models/prompt_block/prompt_block_palette_entry.dart';
import '../../core/storage/prompt_block_storage.dart';
import '../utils/prompt_block_instance_display.dart';
import 'prompt_block_library_provider.dart';

part 'prompt_block_palette_provider.g.dart';

/// 颜料版状态：按用户排序解析后的块列表 + 库文件夹快照
/// （供悬停预览显示块所在路径，复用现有 library 依赖边）。
///
/// Library entries follow their source. Temporary entries own their content.
class PromptBlockPaletteState {
  PromptBlockPaletteState({
    required List<PromptBlock> blocks,
    List<PromptBlockFolder> folders = const [],
    Map<String, PillTempContent> temporary = const {},
  }) : blocks = List.unmodifiable(blocks),
       folders = List.unmodifiable(folders),
       temporary = Map.unmodifiable(temporary);

  final List<PromptBlock> blocks;
  final Map<String, PillTempContent> temporary;

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
    final entries = await _storage.getPaletteEntries();

    final resolved = <PromptBlock>[];
    final temporary = <String, PillTempContent>{};
    final missingIds = <String>{};
    for (final entry in entries) {
      if (entry.temp case final temp?) {
        temporary[entry.id] = temp;
        resolved.add(
          temporaryBlockDisplay(
            temp,
            currentL10n.blocks_tempLabel,
            id: entry.id,
          ),
        );
        continue;
      }
      final block = library.blockById(entry.id);
      if (block != null) {
        resolved.add(block);
      } else {
        missingIds.add(entry.id);
      }
    }
    // 库删块 → 板上引用同步消失，回写清理后的 id 表。
    if (missingIds.isNotEmpty) {
      await _storage.updatePaletteEntries(
        (current) => current.any((entry) => missingIds.contains(entry.id))
            ? current.where((entry) => !missingIds.contains(entry.id)).toList()
            : null,
      );
    }
    return PromptBlockPaletteState(
      blocks: resolved,
      folders: library.folders,
      temporary: temporary,
    );
  }

  /// 收纳一个块（幂等：同块只收一次）。
  Future<void> addBlock(String blockId) => _update(
    (entries) => entries.any((entry) => entry.id == blockId)
        ? null
        : [...entries, PromptBlockPaletteEntry.library(blockId)],
  );

  Future<void> addTemporary(PillTempContent temp, {int? index}) =>
      _update((entries) {
        final next = [...entries];
        next.insert(
          (index ?? next.length).clamp(0, next.length),
          PromptBlockPaletteEntry.temporary(
            id: 'temp:${const Uuid().v4()}',
            temp: temp,
          ),
        );
        return next;
      });

  /// 收纳到指定下标；已在板上的块视为移动到该下标。
  Future<void> insertBlock(String blockId, int index) => _update((entries) {
    final next = entries.where((entry) => entry.id != blockId).toList();
    next.insert(
      index.clamp(0, next.length),
      PromptBlockPaletteEntry.library(blockId),
    );
    return next;
  });

  /// 从板上移除一个块（不动库）。
  Future<void> removeBlock(String blockId) => _update(
    (entries) => entries.any((entry) => entry.id == blockId)
        ? entries.where((entry) => entry.id != blockId).toList()
        : null,
  );

  /// 批量移除一组块（不动库）。
  Future<void> removeBlocks(Set<String> blockIds) => _update(
    (entries) => entries.any((entry) => blockIds.contains(entry.id))
        ? entries.where((entry) => !blockIds.contains(entry.id)).toList()
        : null,
  );

  /// 清空板上全部块（不动库）。
  Future<void> clear() =>
      _update((entries) => entries.isEmpty ? null : const []);

  /// 板内移动。索引语义与 ReorderableListView.onReorder 一致：
  /// [newIndex] 已是「移除旧项之后」的坐标系，直接使用。
  Future<void> move(int oldIndex, int newIndex) => _update((entries) {
    if (oldIndex < 0 ||
        oldIndex >= entries.length ||
        newIndex < 0 ||
        newIndex >= entries.length) {
      return null;
    }
    final next = [...entries];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    return next;
  });

  /// 变换并持久化 id 表；[transform] 返回 null 表示无变更。
  Future<void> _update(
    List<PromptBlockPaletteEntry>? Function(
      List<PromptBlockPaletteEntry> entries,
    )
    transform,
  ) async {
    // 按钮在 provider 尚未完成初始 build 时也可能收拖放——先等 build
    // 落定再写，否则完成后返回的 build 结果会盖掉本次变更。await 之后
    // 不能再碰 ref（依赖可能恰在期间变更而触发 outdated 断言），所以
    // storage 走 build 期缓存的字段，写完统一 invalidateSelf 让重建
    // 按库最新状态重新解析。
    await future;
    if (await _storage.updatePaletteEntries(transform)) {
      ref.invalidateSelf();
    }
  }
}
