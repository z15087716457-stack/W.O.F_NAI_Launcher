import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/pill_workspace_storage.dart';
import '../../core/utils/pill_document_editor.dart';
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

  @override
  PillWorkspaceState build(String scope) {
    final storage = ref.read(pillWorkspaceStorageProvider);
    final restored = storage.tryLoadSync(scope);
    final document = restored ?? PillDocument.empty();
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

  /// 块库内容变化后由编辑器调用：投影可能已变，需要重新发出。
  void refreshProjection() {
    final projection = _project(state.document);
    if (projection != state.projection) {
      state = state.copyWith(projection: projection);
    }
  }

  String _project(PillDocument document) {
    return PillDocumentEditor.project(document, _resolveContent);
  }

  String? _resolveContent(String blockId) {
    return ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(blockId)
        ?.content;
  }

  void _apply(PillDocument document) {
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
    NotifierProvider.family<
      PillWorkspaceNotifier,
      PillWorkspaceState,
      String
    >(PillWorkspaceNotifier.new);

/// 主提示词（正向）lane 的便捷别名，等价 `pillWorkspaceProvider('main')`。
final pillWorkspaceNotifierProvider = pillWorkspaceProvider(PillScopes.main);
