import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/pill_roll_engine.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/style_explore/explore_run.dart' as domain;
import '../providers/generation/generation_models.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/style_explore/explore_manual_capture.dart';
import '../providers/style_explore/explore_roll_capture.dart';
import '../providers/style_explore/explore_run_runner.dart';
import '../providers/style_explore/explore_run_provider.dart';
import '../utils/explore_display_data.dart';
import '../ui/explore/explore_contract.dart' as ui;
import '../widgets/prompt/blocks/prompt_block_colors.dart';

ImageProvider? styleExploreImage(String? path, {bool thumbnail = false}) {
  if (path == null || path.isEmpty) return null;
  final image = FileImage(File(path));
  return thumbnail
      ? ResizeImage(
          image,
          width: 400,
          height: 400,
          policy: ResizeImagePolicy.fit,
          allowUpscaling: false,
        )
      : image;
}

List<MapEntry<String, PillInstance>> styleExploreVariableInstances(
  PillDocument document,
) =>
    document.instances.entries
        .where(
          (entry) =>
              entry.value.enabled &&
              !entry.value.temporary &&
              entry.value.settings.hasRoll &&
              document.text.contains(entry.key),
        )
        .toList()
      ..sort(
        (a, b) => document.text
            .indexOf(a.key)
            .compareTo(document.text.indexOf(b.key)),
      );

List<ui.ExploreVariable> styleExploreVariables(
  PillDocument document,
  PromptBlockLibraryState? library, {
  required String missingLabel,
}) {
  return [
    for (final entry in styleExploreVariableInstances(document))
      ui.ExploreVariable(
        title:
            library?.blockById(entry.value.blockId)?.displayTitle ??
            missingLabel,
        color: promptBlockColorFromString(
          library?.blockById(entry.value.blockId)?.color ?? '#FF607D8B',
        ),
        icon: library?.blockById(entry.value.blockId)?.iconName,
        poolSize: library?.blockById(entry.value.blockId)?.atomsOrSplit.length,
        evolution: entry.value.evolutionEnabled,
        missing: library?.blockById(entry.value.blockId) == null,
      ),
  ];
}

ui.ExploreCandidate styleExploreCandidate(
  domain.ExploreRun run,
  domain.ExploreCandidate candidate, {
  PromptBlockLibraryState? library,
  String? runningId,
}) {
  final snapshot = candidate.rollSnapshot;
  final params = candidate.paramsSnapshot ?? run.paramsSnapshot;
  final round = run.roundById(candidate.roundId);
  final set = run.parentSetById(round?.parentSetId ?? '');
  final family = run.familyById(set?.familyId ?? round?.familyId ?? '');
  final target =
      candidate.lineage.targetBlockId ??
      (set == null ? null : exploreTargetBlockIdForParentSet(run, set));
  Color color(String id) =>
      promptBlockColorFromString(library?.blockById(id)?.color ?? '#FF607D8B');
  return ui.ExploreCandidate(
    key: candidate.id,
    roundId: candidate.roundId,
    number: candidate.number > 0
        ? candidate.number
        : run.candidates.indexOf(candidate) + 1,
    state:
        candidate.id == runningId &&
            candidate.generation.status ==
                domain.ExploreCandidateGenerationStatus.pending
        ? ui.ExploreCandidateState.running
        : switch (candidate.generation.status) {
            domain.ExploreCandidateGenerationStatus.pending =>
              ui.ExploreCandidateState.pending,
            domain.ExploreCandidateGenerationStatus.done =>
              ui.ExploreCandidateState.done,
            domain.ExploreCandidateGenerationStatus.failed =>
              ui.ExploreCandidateState.failed,
          },
    image: styleExploreImage(candidate.generation.filePath),
    thumb: styleExploreImage(candidate.generation.filePath, thumbnail: true),
    width: params.width,
    height: params.height,
    favorite: candidate.review.heart,
    groupId: candidate.folderId,
    draws: [
      if (snapshot != null)
        for (final roll in snapshot.instanceRolls)
          ui.ExploreDraw(
            title: roll.blockTitle,
            color: color(roll.blockId),
            icon: library?.blockById(roll.blockId)?.iconName,
            evolution:
                roll.lane == 'pos' &&
                (target == null
                    ? identical(roll, snapshot.instanceRolls.firstOrNull)
                    : roll.blockId == target),
            atoms: [
              for (final atom in PillRollEngine.splitTopLevelAtoms(
                roll.rolledText,
              ))
                ui.ExploreAtom.parse(atom),
            ],
          ),
    ],
    prompt: snapshot?.positive ?? '',
    negative: snapshot?.negative ?? '',
    hits: [
      if (snapshot != null)
        for (final hit in explorePromptMatches(snapshot))
          ui.ExploreHit(
            start: hit.start,
            end: hit.end,
            color: color(hit.blockId),
          ),
    ],
    seed: candidate.generation.seed,
    elapsed: candidate.generation.elapsedMs == null
        ? null
        : Duration(milliseconds: candidate.generation.elapsedMs!),
    model: ImageModels.modelDisplayNames[params.model] ?? params.model,
    steps: params.steps,
    scale: params.scale,
    sampler: Samplers.samplerDisplayNames[params.sampler] ?? params.sampler,
    createdAt: candidate.createdAt ?? round?.createdAt ?? run.createdAt,
    error: candidate.generation.error,
    op: switch (candidate.lineage.operation) {
      domain.ExploreLineageOperation.mutation => ui.ExploreOp.mutation,
      domain.ExploreLineageOperation.crossover => ui.ExploreOp.crossover,
      domain.ExploreLineageOperation.injection => ui.ExploreOp.injection,
      _ => null,
    },
    lineId: family?.id,
    generation: set?.generation,
    parentKeys: candidate.lineage.parentCandidateIds,
    changedAtoms: exploreHasLineage(candidate)
        ? [
            for (final atom in exploreNewLineageAtoms(run, candidate))
              ui.ExploreAtom.parse(atom),
          ]
        : [],
    inEvolution: run.parentSets.any(
      (set) =>
          set.parents.any((parent) => parent.sourceCandidateId == candidate.id),
    ),
  );
}

String? styleExploreRunningCandidate(
  domain.ExploreRun run,
  ExploreRunRunnerState runner,
  ExploreManualCaptureState capture,
) {
  if (runner.isRunning && runner.runId == run.id) {
    return run.rounds
        .where((round) => round.status == domain.ExploreRoundStatus.generating)
        .expand((round) => round.candidateIds)
        .where(
          (id) =>
              run.candidateById(id)?.generation.status ==
              domain.ExploreCandidateGenerationStatus.pending,
        )
        .firstOrNull;
  }
  if (capture.armed && capture.runId == run.id) {
    return capture.candidateIds
        .where(
          (id) =>
              run.candidateById(id)?.generation.status ==
              domain.ExploreCandidateGenerationStatus.pending,
        )
        .firstOrNull;
  }
  return null;
}

ui.ExploreProgress? styleExploreProgress(
  domain.ExploreRun run,
  ExploreRunRunnerState runner,
  ExploreManualCaptureState capture,
) {
  final manual = capture.armed && capture.runId == run.id;
  final running = runner.isRunning && runner.runId == run.id;
  if (!manual && !running && run.status != domain.ExploreRunStatus.paused) {
    return null;
  }
  final currentId = styleExploreRunningCandidate(run, runner, capture);
  final round =
      run.roundById(run.candidateById(currentId ?? '')?.roundId ?? '') ??
      run.rounds
          .where(
            (round) =>
                round.status == domain.ExploreRoundStatus.pending ||
                round.status == domain.ExploreRoundStatus.generating,
          )
          .firstOrNull ??
      (manual
          ? run.roundById(
              run
                      .candidateById(capture.candidateIds.firstOrNull ?? '')
                      ?.roundId ??
                  '',
            )
          : null);
  if (round == null) return null;
  final set = run.parentSetById(round.parentSetId ?? '');
  final family = run.familyById(set?.familyId ?? round.familyId ?? '');
  final ids = manual ? capture.candidateIds : round.candidateIds;
  final done = ids
      .where(
        (id) =>
            run.candidateById(id)?.generation.status !=
            domain.ExploreCandidateGenerationStatus.pending,
      )
      .length;
  final basics = run.rounds
      .where((entry) => entry.phase != domain.ExploreRoundPhase.deep)
      .toList();
  return ui.ExploreProgress(
    done: running ? runner.processedCount : done,
    total: running ? runner.totalCount : ids.length,
    round: round.phase == domain.ExploreRoundPhase.deep
        ? null
        : basics.indexWhere((entry) => entry.id == round.id) + 1,
    lineName: family?.name,
    generation: set?.generation,
    paused: !running && !manual && run.status == domain.ExploreRunStatus.paused,
  );
}

ui.ExploreRunView styleExploreRunView(
  domain.ExploreRun run, {
  PromptBlockLibraryState? library,
  ExploreRunRunnerState runner = const ExploreRunRunnerState(),
  ExploreManualCaptureState capture = const ExploreManualCaptureState(),
}) {
  final runningId = styleExploreRunningCandidate(run, runner, capture);
  var basicNumber = 0;
  final rounds = [...run.rounds]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return ui.ExploreRunView(
    id: run.id,
    name: run.displayName,
    createdAt: run.createdAt,
    candidates: [
      for (final candidate in run.candidates)
        styleExploreCandidate(
          run,
          candidate,
          library: library,
          runningId: runningId,
        ),
    ],
    rounds: [
      for (final round in rounds)
        ui.ExploreRound(
          id: round.id,
          number: round.phase == domain.ExploreRoundPhase.deep
              ? round.number
              : ++basicNumber,
          createdAt: round.createdAt,
          keys: round.candidateIds,
          kind: round.phase == domain.ExploreRoundPhase.deep
              ? ui.ExploreRoundKind.deep
              : ui.ExploreRoundKind.basic,
          lineName: run
              .familyById(
                run.parentSetById(round.parentSetId ?? '')?.familyId ??
                    round.familyId ??
                    '',
              )
              ?.name,
          generation: run.parentSetById(round.parentSetId ?? '')?.generation,
        ),
    ],
    groups: [
      for (final folder in run.folders)
        ui.ExploreGroup(id: folder.id, name: folder.name),
    ],
    lines: [
      for (final family in run.families)
        if (run.parentSets.any((set) => set.familyId == family.id))
          ui.ExploreLine(
            id: family.id,
            name: family.name,
            generations: [
              for (final generation in exploreFamilyGenerations(run, family))
                ui.ExploreGeneration(
                  number: generation.parentSet.generation,
                  parents: [
                    for (final parent in generation.parentSet.parents)
                      ui.ExploreParent(
                        id: parent.id,
                        candidateKey: parent.sourceCandidateId,
                        atoms: [
                          for (final atom in PillRollEngine.splitTopLevelAtoms(
                            parent.artistString,
                          ))
                            ui.ExploreAtom.parse(atom),
                        ],
                        image: styleExploreImage(
                          run
                              .candidateById(parent.sourceCandidateId ?? '')
                              ?.generation
                              .filePath,
                          thumbnail: true,
                        ),
                        preference: parent.preference,
                      ),
                  ],
                  childKeys: generation.pile
                      .map((candidate) => candidate.id)
                      .toList(),
                  fromGeneration: generation.parentSet.generation == 1
                      ? null
                      : generation.parentSet.generation - 1,
                  picked: generation.parentSet.parents
                      .where(
                        (parent) =>
                            parent.sourceCandidateId != null &&
                            (generation.parentSet.generation == 1 ||
                                run
                                            .candidateById(
                                              parent.sourceCandidateId!,
                                            )
                                            ?.lineage
                                            .operation !=
                                        domain
                                            .ExploreLineageOperation
                                            .basicRoll &&
                                    run
                                            .candidateById(
                                              parent.sourceCandidateId!,
                                            )
                                            ?.lineage
                                            .operation !=
                                        domain.ExploreLineageOperation.manual),
                      )
                      .length,
                  backcross:
                      generation.parentSet.generation > 1 &&
                      generation.parentSet.parents.any(
                        (parent) =>
                            run
                                .parentSetById(family.rootParentSetId)
                                ?.parents
                                .any(
                                  (root) =>
                                      root.artistString == parent.artistString,
                                ) ==
                            true,
                      ),
                ),
            ],
          ),
    ],
    progress: styleExploreProgress(run, runner, capture),
  );
}

ui.ExploreRunSummary styleExploreRunSummary(
  domain.ExploreRun run, {
  ExploreRunRunnerState runner = const ExploreRunRunnerState(),
  ExploreManualCaptureState capture = const ExploreManualCaptureState(),
}) {
  final basic = run.candidates
      .where(
        (candidate) =>
            run.roundById(candidate.roundId)?.phase !=
            domain.ExploreRoundPhase.deep,
      )
      .toList();
  final latest = [...run.candidates]
    ..sort((a, b) => b.number.compareTo(a.number));
  final thumbs = <ImageProvider?>[];
  final seen = <String>{};
  for (final candidate in [
    ...latest.where((candidate) => candidate.review.heart),
    ...latest,
  ]) {
    if (!seen.add(candidate.id)) continue;
    final image = styleExploreImage(
      candidate.generation.filePath,
      thumbnail: true,
    );
    if (image != null) thumbs.add(image);
    if (thumbs.length == 3) break;
  }
  final progress = styleExploreProgress(run, runner, capture);
  return ui.ExploreRunSummary(
    id: run.id,
    name: run.displayName,
    updatedAt: run.updatedAt,
    total: basic.length,
    favorites: run.candidates
        .where((candidate) => candidate.review.heart)
        .length,
    lines: run.families.length,
    thumbs: thumbs,
    state:
        runner.isRunning && runner.runId == run.id ||
            capture.armed && capture.runId == run.id
        ? ui.ExploreRunState.running
        : run.status == domain.ExploreRunStatus.paused
        ? ui.ExploreRunState.paused
        : run.failedCount > 0
        ? ui.ExploreRunState.failed
        : ui.ExploreRunState.idle,
    done: progress?.done ?? 0,
    target: progress?.total ?? 0,
    failed: run.failedCount,
  );
}

List<ui.ExploreBlockFolder> styleExploreBlockFolders(
  PromptBlockLibraryState? library,
  String rootName,
) {
  final result = <ui.ExploreBlockFolder>[
    ui.ExploreBlockFolder(id: null, name: rootName),
  ];
  final visited = <String>{};
  void visit(String? parentId, int depth) {
    for (final folder in library?.foldersIn(parentId) ?? []) {
      if (!visited.add(folder.id)) continue;
      result.add(
        ui.ExploreBlockFolder(id: folder.id, name: folder.name, depth: depth),
      );
      visit(folder.id, depth + 1);
    }
  }

  visit(null, 0);
  return result;
}

ui.ExploreGenerate styleExploreGenerate({
  required int count,
  required int cost,
  required int? balance,
  required ImageGenerationState generation,
  required ExploreRunRunnerState runner,
  required ExploreManualCaptureState capture,
  required String? activeRunId,
  required int cooldown,
  bool otherBusy = false,
}) => ui.ExploreGenerate(
  count: count,
  maxCount: 100,
  cost: cost,
  insufficient: balance != null && balance < cost,
  phase: capture.armed && capture.runId == activeRunId
      ? ui.ExploreGeneratePhase.running
      : generation.isGenerating || runner.isRunning || otherBusy
      ? ui.ExploreGeneratePhase.busy
      : cooldown > 0
      ? ui.ExploreGeneratePhase.cooldown
      : ui.ExploreGeneratePhase.ready,
  done: generation.currentImage,
  total: generation.totalImages,
  cooldown: cooldown,
);
