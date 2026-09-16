import 'dart:convert';
import 'dart:math';

import '../../core/storage/local_storage_service.dart';
import '../../core/storage/prompt_block_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/prompt_block/prompt_block.dart';
import '../repositories/prompt_block_repository.dart';

/// 旧「固定词」系统 → 块库 + 颜料版的一次性迁移（FEAT-5 / EVAL-1）。
///
/// 语义：每条固定词迁为一个普通块（正文 = 加权后内容，保留用户看到的
/// 实际生效文本）；启用的条目按 sortOrder 额外挂上颜料版（只存块 id
/// 引用，不拷贝内容）。迁移完成后旧设置键清除；重复执行由 meta 旗标短路。
class FixedTagMigrationService {
  FixedTagMigrationService({
    required PromptBlockStorage blockStorage,
    required LocalStorageService localStorage,
  }) : _blockStorage = blockStorage,
       _localStorage = localStorage;

  final PromptBlockStorage _blockStorage;
  final LocalStorageService _localStorage;

  static const String _doneFlag = 'fixedTagMigrationDone';

  /// 旧设置键（StorageKeys 常量已随固定词系统删除，这里保留字面量）。
  static const List<String> _legacySettingKeys = [
    'fixed_tags_data',
    'fixed_tag_links_data',
    'fixed_tag_categories_data',
    'fixed_tags_negative_panel_expanded',
    'fixed_tags_sidebar_expanded',
    'fixed_tags_sidebar_width',
    'fixed_tags_sidebar_view_mode',
    'fixed_tags_negative_height',
  ];

  /// 执行迁移（幂等）：迁移完成或失败后都落旗标，避免每启动重试。
  Future<void> run() async {
    if (await _blockStorage.getMeta(_doneFlag) == '1') return;
    try {
      await _migrate();
      AppLogger.i('Fixed-tag migration finished', 'FixedTagMigrationService');
    } catch (error, stackTrace) {
      AppLogger.e(
        'Fixed-tag migration failed',
        error,
        stackTrace,
        'FixedTagMigrationService',
      );
    }
    await _blockStorage.putMeta(_doneFlag, '1');
  }

  Future<void> _migrate() async {
    final raw = _localStorage.getSetting<String>('fixed_tags_data');
    final decoded = raw == null || raw.isEmpty ? null : jsonDecode(raw);
    if (decoded is! List) {
      await _cleanLegacyKeys();
      return;
    }

    final repository = PromptBlockRepository(_blockStorage);
    final existing = await repository.load();
    final byContent = {
      for (final block in existing.blocks) block.content.trim(): block,
    };

    final migrated = <({String blockId, int sortOrder, bool enabled})>[];
    final toCreate = <PromptBlock>[];
    for (final item in decoded.whereType<Map>()) {
      final json = Map<String, dynamic>.from(item);
      final content = _applyWeight(
        (json['content'] as String? ?? '').trim(),
        (json['weight'] as num?)?.toDouble() ?? 1.0,
      );
      if (content.isEmpty) continue;

      final reusable = byContent[content];
      final enabled = json['enabled'] as bool? ?? true;
      if (reusable != null) {
        migrated.add((
          blockId: reusable.id,
          sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
          enabled: enabled,
        ));
        continue;
      }

      final name = (json['name'] as String? ?? '').trim();
      final block = PromptBlock.create(
        title: name.isNotEmpty ? name : _titleFromContent(content),
        content: content,
        iconName: 'palette',
      );
      byContent[content] = block;
      toCreate.add(block);
      migrated.add((
        blockId: block.id,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        enabled: enabled,
      ));
    }

    if (toCreate.isNotEmpty) {
      await repository.importBlocks(toCreate);
    }

    final enabledIds = migrated.where((entry) => entry.enabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (enabledIds.isNotEmpty) {
      final palette = await _blockStorage.getPaletteBlockIds();
      final merged = <String>[
        ...palette,
        for (final entry in enabledIds)
          if (!palette.contains(entry.blockId)) entry.blockId,
      ];
      await _blockStorage.putPaletteBlockIds(merged);
    }

    await _cleanLegacyKeys();
  }

  Future<void> _cleanLegacyKeys() async {
    for (final key in _legacySettingKeys) {
      try {
        await _localStorage.deleteSetting(key);
      } catch (_) {
        // 单键删除失败不阻断迁移
      }
    }
  }

  static String _titleFromContent(String content) {
    if (content.length > 20) return '${content.substring(0, 20)}...';
    return content.isEmpty ? '固定词' : content;
  }

  /// 与旧 `FixedTagEntry.applyWeight` 同款的权重嵌套（{} / [] 每层 ±1.05x）。
  static String _applyWeight(String content, double weight) {
    if (content.isEmpty || weight == 1.0) return content;
    final layers = (log(weight.clamp(0.5, 2.0)) / log(1.05)).round();
    if (layers == 0) return content;
    if (layers > 0) {
      return '${'{' * layers}$content${'}' * layers}';
    }
    return '${'[' * (-layers)}$content${']' * (-layers)}';
  }
}
