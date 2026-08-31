import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/storage/prompt_workspace_state_storage.dart';
import '../../core/utils/prompt_block_composer.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_document.dart';

part 'prompt_block_workspace_provider.freezed.dart';

/// Prompt 工作区的正向与负向 lane。
enum PromptBlockLane { positive, negative }

/// 两个完全隔离的 Prompt 块文档状态。
@freezed
class PromptBlockWorkspaceState with _$PromptBlockWorkspaceState {
  const PromptBlockWorkspaceState._();

  const factory PromptBlockWorkspaceState({
    required PromptBlockDocument positiveDocument,
    required PromptBlockDocument negativeDocument,
  }) = _PromptBlockWorkspaceState;

  PromptBlockDocument documentFor(PromptBlockLane lane) {
    return switch (lane) {
      PromptBlockLane.positive => positiveDocument,
      PromptBlockLane.negative => negativeDocument,
    };
  }
}

/// Prompt 文档编辑器；可在测试中替换 UUID 与时钟来源。
final promptBlockComposerProvider = Provider<PromptBlockComposer>(
  (ref) => PromptBlockComposer(),
);

/// 工作区持久化存储；Box 未打开时读写都安全跳过。
final promptWorkspaceStateStorageProvider =
    Provider<PromptWorkspaceStateStorage>(
      (ref) => PromptWorkspaceStateStorage(),
    );

/// 仅管理 Prompt 块工作区文档，不连接生成参数或请求链。
///
/// 工作区按实例隔离：生成页与画风探索页各自持有独立 provider，
/// 共用同一编辑器组件。每次文档变更都会把快照写入 Hive，
/// 重启后在 [build] 中同步恢复；Box 未打开时（测试环境）退回空文档。
abstract class PromptBlockWorkspaceNotifier
    extends Notifier<PromptBlockWorkspaceState> {
  /// 持久化 scope key；由具体工作区实例决定。
  String get persistenceScope;

  @override
  PromptBlockWorkspaceState build() {
    final storage = ref.read(promptWorkspaceStateStorageProvider);
    final restored = storage.tryLoadSync(persistenceScope);
    if (restored != null) {
      return PromptBlockWorkspaceState(
        positiveDocument: restored.positiveDocument,
        negativeDocument: restored.negativeDocument,
      );
    }

    final composer = ref.read(promptBlockComposerProvider);
    return PromptBlockWorkspaceState(
      positiveDocument: composer.createDocumentFromPlainText(''),
      negativeDocument: composer.createDocumentFromPlainText(''),
    );
  }

  /// 用旧式纯文本重建指定 lane 的单文本段文档。
  void replacePlainText(PromptBlockLane lane, String text) {
    _replaceDocument(
      lane,
      ref.read(promptBlockComposerProvider).createDocumentFromPlainText(text),
    );
  }

  /// 外部纯文本写入的统一协调入口。
  ///
  /// 当前投影与 [text] 不等价时，把文档无损重建为单文本段；
  /// 投影等价（含外部写入恰好等于当前投影）时保留现有文档结构。
  /// 返回是否发生了重建。
  bool syncFromPlainText(PromptBlockLane lane, String text) {
    if (plainTextFor(lane) == text) return false;
    replacePlainText(lane, text);
    return true;
  }

  /// 用不可变文档快照替换指定 lane。
  void replaceDocument(PromptBlockLane lane, PromptBlockDocument document) {
    _replaceDocument(lane, document);
  }

  void updateText(
    PromptBlockLane lane, {
    required String segmentId,
    required String text,
  }) {
    final composer = ref.read(promptBlockComposerProvider);
    _replaceDocument(
      lane,
      composer.updateText(
        state.documentFor(lane),
        segmentId: segmentId,
        text: text,
      ),
    );
  }

  void insertBlock(
    PromptBlockLane lane, {
    required int index,
    required PromptBlock block,
  }) {
    final composer = ref.read(promptBlockComposerProvider);
    _replaceDocument(
      lane,
      composer.insertBlock(state.documentFor(lane), index: index, block: block),
    );
  }

  void insertBlockAtTextOffset(
    PromptBlockLane lane, {
    required String textSegmentId,
    required int offset,
    required PromptBlock block,
  }) {
    final composer = ref.read(promptBlockComposerProvider);
    _replaceDocument(
      lane,
      composer.insertBlockAtTextOffset(
        state.documentFor(lane),
        textSegmentId: textSegmentId,
        offset: offset,
        block: block,
      ),
    );
  }

  void toggleBlockEnabled(PromptBlockLane lane, {required String segmentId}) {
    final composer = ref.read(promptBlockComposerProvider);
    _replaceDocument(
      lane,
      composer.toggleBlockEnabled(
        state.documentFor(lane),
        segmentId: segmentId,
      ),
    );
  }

  void removeSegment(PromptBlockLane lane, {required String segmentId}) {
    final composer = ref.read(promptBlockComposerProvider);
    _replaceDocument(
      lane,
      composer.removeSegment(state.documentFor(lane), segmentId: segmentId),
    );
  }

  void expandBlock(PromptBlockLane lane, {required String segmentId}) {
    final composer = ref.read(promptBlockComposerProvider);
    _replaceDocument(
      lane,
      composer.expandBlock(state.documentFor(lane), segmentId: segmentId),
    );
  }

  void reorderSegments(PromptBlockLane lane, List<String> orderedIds) {
    final composer = ref.read(promptBlockComposerProvider);
    _replaceDocument(
      lane,
      composer.reorderSegments(state.documentFor(lane), orderedIds),
    );
  }

  String plainTextFor(PromptBlockLane lane) {
    return ref
        .read(promptBlockComposerProvider)
        .composePlainText(state.documentFor(lane));
  }

  void _replaceDocument(PromptBlockLane lane, PromptBlockDocument document) {
    state = switch (lane) {
      PromptBlockLane.positive => state.copyWith(positiveDocument: document),
      PromptBlockLane.negative => state.copyWith(negativeDocument: document),
    };
    _persist();
  }

  void _persist() {
    final storage = ref.read(promptWorkspaceStateStorageProvider);
    // fire-and-forget：持久化失败不打断编辑，Box 未打开时内部直接跳过。
    storage.persist(
      persistenceScope,
      PromptWorkspaceSnapshot(
        positiveDocument: state.positiveDocument,
        negativeDocument: state.negativeDocument,
      ),
    );
  }
}

/// 生成页的全局 Prompt 工作区。
class MainPromptWorkspaceNotifier extends PromptBlockWorkspaceNotifier {
  @override
  String get persistenceScope => 'main';
}

/// 画风探索页的独立 Prompt 工作区。
class StyleExploreWorkspaceNotifier extends PromptBlockWorkspaceNotifier {
  @override
  String get persistenceScope => 'styleExplore';
}

/// 生成页工作区 provider；外部协调（set_params、元数据导入等）只作用于此实例。
final promptBlockWorkspaceNotifierProvider =
    NotifierProvider<PromptBlockWorkspaceNotifier, PromptBlockWorkspaceState>(
      MainPromptWorkspaceNotifier.new,
    );

/// 画风探索页工作区 provider；与生成页完全隔离。
final styleExploreWorkspaceNotifierProvider =
    NotifierProvider<PromptBlockWorkspaceNotifier, PromptBlockWorkspaceState>(
      StyleExploreWorkspaceNotifier.new,
    );
