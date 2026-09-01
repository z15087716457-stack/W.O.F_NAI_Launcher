import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/pill_workspace_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pill_document_editor.dart';
import '../../core/utils/pill_roll_engine.dart';
import '../../data/models/prompt_block/pill_document.dart';
import 'prompt_block_library_provider.dart';

/// 药丸工作区状态：文档 + 最近一次投影结果。
///
/// 投影缓存在状态里，使 [PillWorkspaceNotifier.syncFromPlainText]
/// 无需接触块库即可做等价判断；文档每次变更时重算投影。
class PillWorkspaceState {
  const PillWorkspaceState({required this.document, required this.projection});

  final PillDocument document;

  /// 按当前块库内容展开后的完整提示词。
  final String projection;

  PillWorkspaceState copyWith({PillDocument? document, String? projection}) {
    return PillWorkspaceState(
      document: document ?? this.document,
      projection: projection ?? this.projection,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PillWorkspaceState &&
      other.document == document &&
      other.projection == projection;

  @override
  int get hashCode => Object.hash(document, projection);
}

final pillWorkspaceStorageProvider = Provider<PillWorkspaceStorage>(
  (ref) => PillWorkspaceStorage(),
);

/// 药丸工作区 scope 集中定义（P3 多 lane）。
abstract final class PillScopes {
  /// 生成页正向主提示词。
  static const String main = 'main';

  /// 生成页负向（UC）框。
  static const String negative = 'negative';

  /// 角色框正向：char:<characterId>:pos
  static String charPos(String characterId) => 'char:$characterId:pos';

  /// 角色框负向：char:<characterId>:neg
  static String charNeg(String characterId) => 'char:$characterId:neg';
}

/// 药丸编辑器「活动插入目标」：最近一次 caret/焦点变化所在的
/// (scope, caret)。块库面板点击插入按此路由；null = 尚未聚焦过任何
/// 药丸框，插入到主提示词文本末尾。
final pillActiveEditorTargetProvider =
    StateProvider<({String scope, int caret})?>((ref) => null);

/// 药丸工作区（P3 起按 scope 分 lane：正向/负向/角色框各自独立文档）。
///
/// keep-alive（非 autoDispose）：切换 正面/UC tab 会卸载编辑器，
/// 墓碑缓存与文档实例必须活过 tab 切换，否则剪切→切 tab→粘贴 变失效块。
/// 块内容从块库 provider 实时解析，库编辑即时反映到投影。
class PillWorkspaceNotifier extends FamilyNotifier<PillWorkspaceState, String> {
  /// 最近被移除实例的墓碑缓存（marker → 实例快照）。
  ///
  /// 剪切/删除会让标记字符从文本消失、实例被对账移除；此后若同一字符
  /// 又被粘贴回来（剪贴板带着它），在 [setText] 里复活实例，
  /// 避免显示为「失效块」。仅内存、重启不保留，FIFO 上限 64。
  final Map<String, PillInstance> _tombstones = {};
  static const int _tombstoneCapacity = 64;

  /// 全局随机数源（roll 不可复现是特性：复现链 = currentRoll 快照 +
  /// 生成图元数据 + nai_fill.py 回填，不做种子系统）。
  /// 测试可替换为 seeded Random 锁定确定性。
  @visibleForTesting
  static Random rng = Random();

  /// 活跃 lane 注册表（P2.5）：roll 协调器据此枚举各工作区。
  /// keep-alive 家族实例一旦建立即常驻；角色删除走 [forgetScope] 摘除。
  static final Set<String> activeScopes = <String>{};

  /// 从注册表摘除 lane（角色删除/清空时随 `deleteScope` 一并调用）。
  static void forgetScope(String scope) => activeScopes.remove(scope);

  @override
  PillWorkspaceState build(String scope) {
    activeScopes.add(scope);
    final storage = ref.read(pillWorkspaceStorageProvider);
    final restored = storage.tryLoadSync(scope);
    // 挂载即兜底物化：存档里的随机实例若缺 currentRoll 先 roll 再投影
    final document = _materializeRolls(restored ?? PillDocument.empty());
    return PillWorkspaceState(
      document: document,
      projection: _project(document),
    );
  }

  /// 用户直接编辑文本后的入口：复活无主标记、对账实例并重算投影。
  void setText(String text) {
    var document = state.document;
    if (text == document.text) return;
    document = _resurrectMarkers(document, text);
    _apply(PillDocumentEditor.reconcile(document, text));
  }

  /// 文本里无实例但墓碑缓存有快照的标记字符 → 恢复其实例。
  PillDocument _resurrectMarkers(PillDocument document, String text) {
    if (_tombstones.isEmpty) return document;
    final resurrected = <String, PillInstance>{};
    for (var i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (!isPillMarkerCodeUnit(codeUnit)) continue;
      final marker = String.fromCharCode(codeUnit);
      if (document.instances.containsKey(marker) ||
          resurrected.containsKey(marker)) {
        continue;
      }
      final tomb = _tombstones.remove(marker);
      if (tomb != null) resurrected[marker] = tomb;
    }
    if (resurrected.isEmpty) return document;
    final instances = Map<String, PillInstance>.of(document.instances)
      ..addAll(resurrected);
    return document.copyWith(instances: instances);
  }

  /// 在 [offset] 处插入库块新实例。
  void insertBlockAt({required int offset, required String blockId}) {
    _apply(
      PillDocumentEditor.insertBlock(
        state.document,
        offset: offset,
        blockId: blockId,
      ),
    );
  }

  /// 文内拖动药丸：把 [marker] 的第 [occurrence] 次出现移到 [newOffset]。
  void moveMarker({
    required String marker,
    required int occurrence,
    required int newOffset,
  }) {
    _apply(
      PillDocumentEditor.moveMarker(
        state.document,
        marker: marker,
        occurrence: occurrence,
        newOffset: newOffset,
      ),
    );
  }

  /// 切换实例启用态。
  void toggleEnabled(String marker) {
    final instance = state.document.instances[marker];
    if (instance == null) return;
    _apply(
      PillDocumentEditor.setEnabled(
        state.document,
        marker,
        enabled: !instance.enabled,
      ),
    );
  }

  /// 更新实例随机参数（L2 弹窗确定，roll 时机 2）：
  /// 写设置；切到/更新随机模式时立即重 roll 一次。
  void updateInstanceSettings(String marker, PillInstanceSettings settings) {
    final instance = state.document.instances[marker];
    if (instance == null) {
      AppLogger.w(
        'updateInstanceSettings: marker not found in lane "$arg", ignored',
        'PillWorkspace',
      );
      return;
    }
    var updated = instance.copyWith(settings: settings);
    if (settings.isRandom) {
      updated = updated.copyWith(currentRoll: _rollFor(updated));
    }
    final instances = Map<String, PillInstance>.of(state.document.instances)
      ..[marker] = updated;
    _apply(state.document.copyWith(instances: instances));
  }

  /// 手动重 roll（L1 骰子，roll 时机 3）；固定模式无操作。
  void rollMarker(String marker) {
    final instance = state.document.instances[marker];
    if (instance == null || !instance.settings.isRandom) return;
    final instances = Map<String, PillInstance>.of(state.document.instances)
      ..[marker] = instance.copyWith(currentRoll: _rollFor(instance));
    _apply(state.document.copyWith(instances: instances));
  }

  /// 本 lane 全部随机实例重 roll（roll 时机 4：每次生成入队后）。
  /// 返回是否有实例的 currentRoll 发生了变化（协调器据此推送投影）。
  bool rollAllRandom() {
    var changed = false;
    final instances = Map<String, PillInstance>.of(state.document.instances);
    for (final entry in instances.entries) {
      final instance = entry.value;
      if (!instance.settings.isRandom) continue;
      final rolled = _rollFor(instance);
      if (rolled != instance.currentRoll) {
        instances[entry.key] = instance.copyWith(currentRoll: rolled);
        changed = true;
      }
    }
    if (!changed) return false;
    _apply(state.document.copyWith(instances: instances));
    return true;
  }

  /// 删除标记（含未知/失效标记），文本中的出现一并清除。
  void removeMarker(String marker) {
    _apply(PillDocumentEditor.removeMarker(state.document, marker));
  }

  /// 用外部纯文本整体重建（剥离任何私有区字符，实例清空）。
  void replaceWithPlainText(String text) {
    _apply(
      PillDocument(
        text: PillDocumentEditor.stripMarkers(text),
        instances: const {},
      ),
    );
  }

  /// 外部纯文本写入的统一协调入口（与旧工作区语义一致）：
  /// 与当前投影等价时保留文档结构，否则重建。返回是否发生了重建。
  bool syncFromPlainText(String text) {
    if (state.projection == text) return false;
    replaceWithPlainText(text);
    return true;
  }

  /// 用完整文档快照整体恢复（Recipe 载入等外部场景）。
  ///
  /// 与 [build] 恢复同一路径：`_apply` 内部兜底物化缺失的 currentRoll
  /// （不新增 roll 时机）、记录墓碑并重算投影、分键持久化。
  void restoreDocument(PillDocument document) {
    _apply(document);
  }

  /// 块库内容变化后由编辑器调用：投影可能已变，需要重新发出。
  void refreshProjection() {
    final projection = _project(state.document);
    if (projection != state.projection) {
      state = state.copyWith(projection: projection);
    }
  }

  String _project(PillDocument document) {
    return PillDocumentEditor.project(document, _resolveInstance);
  }

  /// 实例内容解析（P2.5）：固定模式 = 块库实时内容；随机模式 =
  /// 物化的 `currentRoll`（投影永不 roll，物化只在文档变更点发生）。
  String? _resolveInstance(PillInstance instance) {
    if (instance.settings.isRandom) return instance.currentRoll;
    return _resolveBlockContent(instance.blockId);
  }

  String? _resolveBlockContent(String blockId) {
    return ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(blockId)
        ?.content;
  }

  /// 随机实例的兜底物化：`currentRoll == null` 时立即 roll 一次。
  /// 保证「L1 显示 = 生成发送 = token 计数」三者永远同一份。
  PillDocument _materializeRolls(PillDocument document) {
    var changed = false;
    final instances = Map<String, PillInstance>.of(document.instances);
    for (final entry in instances.entries) {
      final instance = entry.value;
      if (instance.settings.isRandom && instance.currentRoll == null) {
        instances[entry.key] = instance.copyWith(
          currentRoll: _rollFor(instance),
        );
        changed = true;
      }
    }
    return changed ? document.copyWith(instances: instances) : document;
  }

  /// 对单个实例执行 roll：块内容切原子 → 随机引擎。
  String _rollFor(PillInstance instance) {
    final content = _resolveBlockContent(instance.blockId) ?? '';
    return PillRollEngine.rollInstance(
      settings: instance.settings,
      atoms: PillRollEngine.splitTopLevelAtoms(content),
      rng: rng,
    );
  }

  void _apply(PillDocument document) {
    document = _materializeRolls(document);
    _recordTombstones(state.document, document);
    state = PillWorkspaceState(
      document: document,
      projection: _project(document),
    );
    _persist(document);
  }

  /// 新旧文档间消失的实例进墓碑缓存（供剪切-粘贴复活）。
  void _recordTombstones(PillDocument before, PillDocument after) {
    if (before.instances.isEmpty) return;
    for (final entry in before.instances.entries) {
      if (!after.instances.containsKey(entry.key)) {
        _tombstones[entry.key] = entry.value;
      }
    }
    while (_tombstones.length > _tombstoneCapacity) {
      _tombstones.remove(_tombstones.keys.first);
    }
  }

  void _persist(PillDocument document) {
    // fire-and-forget：持久化失败不打断编辑，Box 未打开时内部直接跳过。
    ref.read(pillWorkspaceStorageProvider).persist(arg, document);
  }
}

/// 按 scope 取药丸工作区（同参返回同一 provider 实例，家族内隔离）。
final pillWorkspaceProvider =
    NotifierProvider.family<PillWorkspaceNotifier, PillWorkspaceState, String>(
      PillWorkspaceNotifier.new,
    );

/// 主提示词（正向）lane 的便捷别名，等价 `pillWorkspaceProvider('main')`。
final pillWorkspaceNotifierProvider = pillWorkspaceProvider(PillScopes.main);
