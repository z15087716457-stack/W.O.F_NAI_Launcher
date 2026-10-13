import '../../core/storage/style_explore_run_storage.dart';
import '../models/style_explore/explore_run.dart';

/// 画风探索 Run Repository。
///
/// Run 持有创建时刻的提示词与参数快照；这里只做持久化编排，
/// 不触碰块库与生成链。候选图的物理副本由 ExploreRunImageStore 负责。
class StyleExploreRunRepository {
  StyleExploreRunRepository(this._storage);

  final StyleExploreRunStorage _storage;

  /// 读取全部 Run，按更新时间新→旧排列。
  Future<List<ExploreRun>> load() async => [
    for (final run in await _storage.getRuns()) await _normalize(run),
  ];

  Future<ExploreRun?> getRun(String id) async {
    final run = await _storage.getRun(id);
    return run == null ? null : _normalize(run);
  }

  Future<ExploreRun> _normalize(ExploreRun run) async {
    var next = run.nextCandidateNumber;
    for (final candidate in run.candidates) {
      if (candidate.number >= next) next = candidate.number + 1;
    }
    final candidates = [
      for (final candidate in run.candidates)
        candidate.copyWith(
          number: candidate.number > 0 ? candidate.number : next++,
          createdAt:
              candidate.createdAt ??
              run.roundById(candidate.roundId)?.createdAt ??
              run.createdAt,
        ),
    ];
    final normalized = run.copyWith(
      candidates: candidates,
      nextCandidateNumber: next,
    );
    return normalized;
  }

  ExploreRun? currentRun(String id) => _storage.currentRun(id);

  /// 创建草稿 Run（快照由调用方捕获）。
  Future<ExploreRun> create({
    required String name,
    required ExploreRecipeSnapshot recipeSnapshot,
    required ExploreParamsSnapshot paramsSnapshot,
    required int targetCount,
    void Function()? beforeWrite,
  }) async {
    final run = ExploreRun.create(
      name: name,
      recipeSnapshot: recipeSnapshot,
      paramsSnapshot: paramsSnapshot,
      targetCount: targetCount,
    );
    await _storage.putRun(run, beforeWrite: beforeWrite);
    return run;
  }

  /// 覆盖保存：刷新 updatedAt 后整体落盘。
  Future<ExploreRun> transform(
    String id,
    ExploreRun Function(ExploreRun) update,
  ) => _storage.transformRun(
    id,
    (current) => update(current).copyWith(updatedAt: DateTime.now()),
  );

  Future<ExploreRun> overwrite(ExploreRun run) async {
    final existing = await _storage.getRun(run.id);
    if (existing == null) {
      throw StateError('Style explore run does not exist: ${run.id}');
    }
    final updated = await _normalize(
      run.copyWith(
        updatedAt: DateTime.now(),
        nextCandidateNumber:
            run.nextCandidateNumber < existing.nextCandidateNumber
            ? existing.nextCandidateNumber
            : run.nextCandidateNumber,
      ),
    );
    await _storage.putRun(updated);
    return updated;
  }

  /// 重命名。
  Future<ExploreRun> rename(String id, String name) async {
    final run = await _storage.getRun(id);
    if (run == null) {
      throw StateError('Style explore run does not exist: $id');
    }
    final updated = run.copyWith(name: name.trim(), updatedAt: DateTime.now());
    await _storage.putRun(updated);
    return updated;
  }

  /// 删除 Run 记录；不存在时保持幂等。run 目录副本的删除由调用方连带。
  Future<void> delete(String id) => _storage.deleteRun(id);
}
