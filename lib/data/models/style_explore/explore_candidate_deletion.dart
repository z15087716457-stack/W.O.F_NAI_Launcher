import 'explore_run.dart';

class ExploreCandidateDeletion {
  ExploreCandidateDeletion({
    required this.id,
    required this.before,
    required Iterable<String> candidateIds,
    required Map<String, String> images,
    DateTime? createdAt,
  }) : candidateIds = Set.unmodifiable(candidateIds),
       images = Map.unmodifiable(images),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final ExploreRun before;
  final Set<String> candidateIds;
  final Map<String, String> images;
  final DateTime createdAt;

  List<ExploreCandidate> get candidates => before.candidates
      .where((candidate) => candidateIds.contains(candidate.id))
      .toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'before': before.toJson(),
    'candidateIds': candidateIds.toList(),
    'images': images,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExploreCandidateDeletion.fromJson(Map<String, dynamic> json) =>
      ExploreCandidateDeletion(
        id: json['id'] as String,
        before: ExploreRun.fromJson(
          Map<String, dynamic>.from(json['before'] as Map),
        ),
        candidateIds: List<String>.from(json['candidateIds'] as List),
        images: Map<String, String>.from(json['images'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  ExploreRun restoreInto(ExploreRun current) {
    if (current.id != before.id) {
      throw StateError('Explore undo belongs to another run');
    }
    final restored = candidates
        .where((candidate) => current.candidateById(candidate.id) == null)
        .toList();
    for (final candidate in restored) {
      if (current.roundById(candidate.roundId) == null) {
        throw StateError('Explore undo round no longer exists');
      }
    }
    final ids = restored.map((candidate) => candidate.id).toSet();
    final byId = {
      for (final candidate in current.candidates) candidate.id: candidate,
    };
    for (final candidate in restored) {
      byId[candidate.id] = candidate.copyWith(
        folderId: current.folderById(candidate.folderId ?? '') == null
            ? null
            : candidate.folderId,
      );
    }
    for (final candidate in current.candidates) {
      final old = before.candidateById(candidate.id);
      if (old == null) continue;
      final remaining = old.lineage.parentCandidateIds
          .where((id) => !candidateIds.contains(id))
          .toList();
      if (_equal(remaining, candidate.lineage.parentCandidateIds)) {
        byId[candidate.id] = candidate.copyWith(
          lineage: candidate.lineage.copyWith(
            parentCandidateIds: _insert(
              candidate.lineage.parentCandidateIds,
              old.lineage.parentCandidateIds,
              ids,
            ),
          ),
        );
      }
    }
    return current.copyWith(
      candidates: [
        for (final id in _insert(
          current.candidates.map((candidate) => candidate.id).toList(),
          before.candidates.map((candidate) => candidate.id).toList(),
          ids,
        ))
          byId[id]!,
      ],
      rounds: [
        for (final round in current.rounds)
          round.copyWith(
            candidateIds: _insert(
              round.candidateIds,
              before.roundById(round.id)?.candidateIds ?? [],
              ids,
            ),
          ),
      ],
    );
  }

  static bool _equal(List<String> a, List<String> b) =>
      a.length == b.length &&
      List.generate(
        a.length,
        (index) => index,
      ).every((index) => a[index] == b[index]);

  static List<String> _insert(
    List<String> current,
    List<String> original,
    Set<String> ids,
  ) {
    final result = [...current];
    for (var index = 0; index < original.length; index++) {
      final id = original[index];
      if (!ids.contains(id) || result.contains(id)) continue;
      final next = original.skip(index + 1).where(result.contains).firstOrNull;
      result.insert(next == null ? result.length : result.indexOf(next), id);
    }
    return result;
  }
}
