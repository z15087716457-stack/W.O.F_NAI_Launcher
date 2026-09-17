import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/storage/local_storage_service.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import 'prompt_block_library_provider.dart';

part 'uc_preset_provider.g.dart';

/// 负面词预设状态
class UcPresetState {
  /// 当前选择的 NAI 预设类型
  final UcPresetType presetType;

  /// 当前选中的自定义条目 ID（如果有值，则使用自定义内容替换 NAI 预设）
  final String? customEntryId;

  /// 所有已添加的自定义条目 ID 列表（持久化保存）
  final List<String> customEntryIds;

  const UcPresetState({
    this.presetType = UcPresetType.heavy,
    this.customEntryId,
    this.customEntryIds = const [],
  });

  UcPresetState copyWith({
    UcPresetType? presetType,
    String? customEntryId,
    bool clearCustomEntryId = false,
    List<String>? customEntryIds,
  }) {
    return UcPresetState(
      presetType: presetType ?? this.presetType,
      customEntryId: clearCustomEntryId
          ? null
          : (customEntryId ?? this.customEntryId),
      customEntryIds: customEntryIds ?? this.customEntryIds,
    );
  }

  /// 是否使用自定义条目
  bool get isCustom => customEntryId != null;

  /// 是否启用预设（非 none 且非自定义）
  bool get isPresetEnabled => !isCustom && presetType != UcPresetType.none;

  /// 是否完全禁用（none 且非自定义）
  bool get isDisabled => !isCustom && presetType == UcPresetType.none;

  /// 是否有已添加的自定义条目
  bool get hasCustomEntries => customEntryIds.isNotEmpty;
}

/// 负面词预设 Provider（支持自定义条目）
@Riverpod(keepAlive: true)
class UcPresetNotifier extends _$UcPresetNotifier {
  LocalStorageService get _storage => ref.read(localStorageServiceProvider);

  @override
  UcPresetState build() {
    // 读取自定义条目列表
    final customIds = _storage.getUcPresetCustomIds();

    // 读取当前选中的自定义条目 ID
    final customId = _storage.getUcPresetCustomId();

    // 读取 NAI 预设类型
    final storedType = _storage.getUcPresetType();
    final presetType = UcPresets.getPresetTypeFromStorage(storedType);

    return UcPresetState(
      presetType: presetType,
      customEntryId: customId,
      customEntryIds: customIds,
    );
  }

  /// 设置 NAI 预设类型（清除当前选中的自定义，但保留列表）
  void setPresetType(UcPresetType type) {
    state = state.copyWith(presetType: type, clearCustomEntryId: true);
    _save();
  }

  /// 设置为自定义条目
  void setCustomEntry(String entryId) {
    // 添加到列表（如果不存在）
    final newIds = List<String>.from(state.customEntryIds);
    if (!newIds.contains(entryId)) {
      newIds.add(entryId);
    }

    state = state.copyWith(customEntryId: entryId, customEntryIds: newIds);
    _save();

    // 记录使用次数
    ref
        .read(promptBlockLibraryNotifierProvider.notifier)
        .incrementUseCount(entryId);
  }

  /// 切换到已添加的自定义条目
  void selectCustomEntry(String entryId) {
    if (!state.customEntryIds.contains(entryId)) return;
    state = state.copyWith(customEntryId: entryId);
    _save();
  }

  /// 从列表中删除自定义条目
  void removeCustomEntry(String entryId) {
    final newIds = List<String>.from(state.customEntryIds)..remove(entryId);

    // 如果删除的是当前选中的条目，清除当前选中
    if (state.customEntryId == entryId) {
      state = state.copyWith(clearCustomEntryId: true, customEntryIds: newIds);
    } else {
      state = state.copyWith(customEntryIds: newIds);
    }
    _save();
  }

  /// 保存到本地存储
  void _save() {
    _storage.setUcPresetType(UcPresets.toApiValue(state.presetType));
    _storage.setUcPresetCustomId(state.customEntryId);
    _storage.setUcPresetCustomIds(state.customEntryIds);
  }

  /// 获取实际应用的负面词内容
  ///
  /// [model] 当前选择的模型
  /// 返回 null 表示不添加预设内容
  String? getEffectiveContent(String model) {
    // 如果有自定义条目，使用自定义内容
    if (state.isCustom) {
      return ref
          .read(promptBlockLibraryNotifierProvider)
          .valueOrNull
          ?.blockById(state.customEntryId!)
          ?.content;
    }

    // 使用 NAI 预设
    if (state.presetType == UcPresetType.none) {
      return null;
    }
    return UcPresets.getPresetContent(model, state.presetType);
  }
}

/// 当前选择的 UC 自定义条目（块库中的对应块；旧词库条目带原 ID 迁入）
@riverpod
PromptBlock? currentUcEntry(Ref ref) {
  final config = ref.watch(ucPresetNotifierProvider);
  if (!config.isCustom) return null;

  return ref
      .watch(promptBlockLibraryNotifierProvider)
      .valueOrNull
      ?.blockById(config.customEntryId!);
}

/// 所有已添加的 UC 自定义条目列表
@riverpod
List<PromptBlock> ucCustomEntries(Ref ref) {
  final config = ref.watch(ucPresetNotifierProvider);
  final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
  if (library == null) return const [];

  return config.customEntryIds
      .map(library.blockById)
      .whereType<PromptBlock>()
      .toList();
}
