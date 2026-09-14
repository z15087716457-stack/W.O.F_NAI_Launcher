import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';

void main() {
  group('ExploreRun model', () {
    test('JSON roundtrip with nested PillDocument and all enums', () {
      const marker = '';
      final run = ExploreRun(
        id: 'run-1',
        name: '柔光试验',
        status: ExploreRunStatus.reviewing,
        archivedAt: DateTime.utc(2026, 8, 31, 10),
        createdAt: DateTime.utc(2026, 8, 30),
        updatedAt: DateTime.utc(2026, 8, 31),
        targetCount: 30,
        recipeSnapshot: ExploreRecipeSnapshot(
          positive: const PillDocument(
            text: 'soft light $marker',
            instances: {
              marker: PillInstance(
                blockId: 'block-1',
                enabled: true,
                settings: PillInstanceSettings(
                  mode: PillRollMode.random,
                  countMin: 1,
                  countMax: 3,
                  triggerProbability: 0.5,
                ),
                currentRoll: 'watercolor',
              ),
            },
          ),
          negative: PillDocument.empty(),
        ),
        paramsSnapshot: const ExploreParamsSnapshot(
          model: 'nai-diffusion-4-5-full',
          width: 832,
          height: 1216,
          steps: 28,
          scale: 5.0,
          sampler: 'k_euler_ancestral',
          seed: -1,
          ucPreset: 1,
          qualityToggle: true,
          smea: false,
          smeaDyn: true,
          cfgRescale: 0.4,
          noiseSchedule: 'karras',
          varietyPlus: true,
          decrisp: false,
        ),
        rounds: [
          ExploreRound(
            id: 'round-1',
            number: 1,
            phase: ExploreRoundPhase.basic,
            status: ExploreRoundStatus.generated,
            createdAt: DateTime.utc(2026, 8, 30, 12),
            targetCount: 30,
            candidateIds: const ['cand-1'],
          ),
          ExploreRound(
            id: 'round-2',
            number: 2,
            phase: ExploreRoundPhase.deep,
            status: ExploreRoundStatus.generating,
            createdAt: DateTime.utc(2026, 8, 31, 9),
            targetCount: 8,
            candidateIds: const [],
            familyId: 'family-1',
            parentSetId: 'pset-2',
            generation: 2,
          ),
        ],
        candidates: [
          const ExploreCandidate(
            id: 'cand-1',
            roundId: 'round-1',
            rollSnapshot: ExploreRollSnapshot(
              positive: 'soft light, watercolor',
              negative: 'lowres',
              instanceRolls: [
                ExploreInstanceRoll(
                  lane: 'pos',
                  marker: marker,
                  blockId: 'block-1',
                  blockTitle: '画风池',
                  rolledText: 'watercolor',
                ),
              ],
            ),
            generation: ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.done,
              filePath: '/tmp/run-1/cand-1.png',
              seed: 424242,
              anlas: 5,
              elapsedMs: 12345,
            ),
            review: ExploreCandidateReview(heart: true),
            folderId: 'folder-1',
            lineage: ExploreLineage(
              parentCandidateIds: ['cand-0'],
              operation: ExploreLineageOperation.basicRoll,
              generation: 1,
              mutatedText: '0.9::watercolor::',
              targetBlockId: 'block-1',
            ),
          ),
          ExploreCandidate.shell(roundId: 'round-2', id: 'cand-2'),
        ],
        folders: [
          ExploreCandidateFolder(
            id: 'folder-1',
            name: '暖光',
            createdAt: DateTime.utc(2026, 8, 31, 13),
          ),
        ],
        parentSets: [
          ExploreParentSet(
            id: 'pset-2',
            familyId: 'family-1',
            generation: 2,
            status: ExploreParentSetStatus.used,
            branchName: '回交分支',
            parents: const [
              ExploreParent(
                id: 'parent-1',
                sourceCandidateId: 'cand-1',
                artistString: 'soft light, watercolor',
                preference: 1.5,
              ),
              ExploreParent(id: 'parent-2', artistString: 'custom string'),
            ],
            comparisons: [
              ExplorePairwiseComparison(
                leftParentId: 'parent-1',
                rightParentId: 'parent-2',
                result: ExploreComparisonResult.left,
                comparedAt: DateTime.utc(2026, 8, 31, 11),
              ),
              ExplorePairwiseComparison(
                leftParentId: 'parent-1',
                rightParentId: 'parent-2',
                result: ExploreComparisonResult.skip,
                comparedAt: DateTime.utc(2026, 8, 31, 12),
              ),
            ],
          ),
        ],
        families: [
          ExploreFamily(
            id: 'family-1',
            name: '柔光家族',
            createdAt: DateTime.utc(2026, 8, 31),
            rootParentSetId: 'pset-1',
            activeParentSetId: 'pset-2',
          ),
        ],
      );

      // 与生产一致走 jsonEncode 往返（嵌套 toJson 由 jsonEncode 递归展开）。
      final decoded = ExploreRun.fromJson(
        jsonDecode(jsonEncode(run)) as Map<String, dynamic>,
      );

      expect(decoded, run);
      expect(
        decoded.recipeSnapshot.positive.instances[marker]?.currentRoll,
        'watercolor',
      );
      expect(decoded.rounds[1].phase, ExploreRoundPhase.deep);
      expect(decoded.candidates[0].review.heart, isTrue);
      expect(decoded.candidates[0].folderId, 'folder-1');
      expect(decoded.folders.single.name, '暖光');
      expect(
        decoded.candidates[0].lineage.operation,
        ExploreLineageOperation.basicRoll,
      );
      expect(
        decoded.candidates[1].generation.status,
        ExploreCandidateGenerationStatus.pending,
      );
      expect(decoded.parentSets.single.status, ExploreParentSetStatus.used);
      expect(decoded.candidates[0].lineage.mutatedText, '0.9::watercolor::');
      expect(decoded.candidates[0].lineage.targetBlockId, 'block-1');
      expect(decoded.parentSets.single.comparisons, hasLength(2));
      expect(
        decoded.parentSets.single.comparisons[1].result,
        ExploreComparisonResult.skip,
      );
      // 旧数据无新键：缺省 null/空表，零迁移兼容。
      final legacy = ExploreLineage.fromJson(const {
        'operation': 'mutation',
        'generation': 3,
      });
      expect(legacy.mutatedText, isNull);
      expect(legacy.targetBlockId, isNull);
      final legacySet = ExploreParentSet.fromJson(const {
        'id': 'p',
        'familyId': 'f',
        'generation': 1,
        'status': 'active',
      });
      expect(legacySet.comparisons, isEmpty);
    });

    test('lineage operation serializes to snake_case wire values', () {
      const candidate = ExploreLineage(
        operation: ExploreLineageOperation.basicRoll,
      );
      expect(candidate.toJson()['operation'], 'basic_roll');
      expect(
        ExploreLineage.fromJson(candidate.toJson()).operation,
        ExploreLineageOperation.basicRoll,
      );
    });

    test('create trims name and defaults to draft with empty collections', () {
      final run = ExploreRun.create(
        name: '  边缘空白  ',
        recipeSnapshot: ExploreRecipeSnapshot(
          positive: PillDocument.empty(),
          negative: PillDocument.empty(),
        ),
        paramsSnapshot: const ExploreParamsSnapshot(
          model: 'm',
          width: 1,
          height: 1,
          steps: 1,
          scale: 1,
          sampler: 's',
          seed: -1,
          ucPreset: 0,
          qualityToggle: true,
          smea: false,
          smeaDyn: false,
          cfgRescale: 0,
          noiseSchedule: 'karras',
          varietyPlus: false,
          decrisp: false,
        ),
        targetCount: 12,
        id: 'fixed-id',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(run.name, '边缘空白');
      expect(run.status, ExploreRunStatus.draft);
      expect(run.rounds, isEmpty);
      expect(run.candidates, isEmpty);
      expect(run.families, isEmpty);
      expect(run.parentSets, isEmpty);
      expect(run.displayName, '边缘空白');
      expect(
        ExploreRun.create(
          name: ' ',
          recipeSnapshot: run.recipeSnapshot,
          paramsSnapshot: run.paramsSnapshot,
          targetCount: 1,
        ).displayName,
        '未命名任务',
      );
    });

    test('candidate counters and pending query', () {
      final run = ExploreRun.create(
        name: 'x',
        recipeSnapshot: ExploreRecipeSnapshot(
          positive: PillDocument.empty(),
          negative: PillDocument.empty(),
        ),
        paramsSnapshot: const ExploreParamsSnapshot(
          model: 'm',
          width: 1,
          height: 1,
          steps: 1,
          scale: 1,
          sampler: 's',
          seed: -1,
          ucPreset: 0,
          qualityToggle: true,
          smea: false,
          smeaDyn: false,
          cfgRescale: 0,
          noiseSchedule: 'karras',
          varietyPlus: false,
          decrisp: false,
        ),
        targetCount: 3,
      );
      final filled = run.copyWith(
        candidates: [
          ExploreCandidate.shell(roundId: 'r', id: 'a').copyWith(
            generation: const ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.done,
            ),
          ),
          ExploreCandidate.shell(roundId: 'r', id: 'b').copyWith(
            generation: const ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.failed,
              error: 'boom',
            ),
          ),
          ExploreCandidate.shell(roundId: 'r', id: 'c'),
        ],
      );

      expect(filled.generatedCount, 1);
      expect(filled.failedCount, 1);
      expect(filled.pendingCandidates.map((c) => c.id), ['c']);
      expect(filled.candidateById('b')?.generation.error, 'boom');
      expect(filled.candidateById('nope'), isNull);
    });

    test('params snapshot captures archive fields from image params', () {
      const base = ImageParams(
        prompt: 'keep me',
        nSamples: 4,
        steps: 23,
        decrisp: true,
      );

      final captured = ExploreParamsSnapshot.fromImageParams(base);
      expect(captured.model, base.model);
      expect(captured.seed, -1);
      expect(captured.steps, 23);
      expect(captured.decrisp, isTrue);
    });

    test('review legacy keys are dropped on decode; heart survives', () {
      const review = ExploreCandidateReview(heart: true);
      final decoded = ExploreCandidateReview.fromJson(
        jsonDecode(jsonEncode(review)) as Map<String, dynamic>,
      );
      expect(decoded, review);
      expect(decoded.heart, isTrue);

      // 存量数据（评审体系拆除前写入）的旧键静默丢弃，不抛错、不迁移。
      final legacy = ExploreCandidateReview.fromJson(const {
        'heart': false,
        'preliminaryLabel': 'treasure',
        'label': 'special',
        'formalReviewedAt': '2026-09-01T08:30:00.000Z',
      });
      expect(legacy.heart, isFalse);
      expect(ExploreCandidateReview.fromJson(const {'heart': true}).toJson(), {
        'heart': true,
      });
    });

    test(
      'legacy run without folders decodes to empty list; folderById works',
      () {
        final run = ExploreRun.create(
          name: 'x',
          recipeSnapshot: ExploreRecipeSnapshot(
            positive: PillDocument.empty(),
            negative: PillDocument.empty(),
          ),
          paramsSnapshot: const ExploreParamsSnapshot(
            model: 'm',
            width: 1,
            height: 1,
            steps: 1,
            scale: 1,
            sampler: 's',
            seed: -1,
            ucPreset: 0,
            qualityToggle: true,
            smea: false,
            smeaDyn: false,
            cfgRescale: 0,
            noiseSchedule: 'karras',
            varietyPlus: false,
            decrisp: false,
          ),
          targetCount: 3,
        );

        // 旧数据无 folders 键：缺省空表，零迁移兼容。
        final legacyJson = jsonDecode(jsonEncode(run)) as Map<String, dynamic>;
        legacyJson.remove('folders');
        final legacy = ExploreRun.fromJson(legacyJson);
        expect(legacy.folders, isEmpty);
        expect(legacy.folderById('nope'), isNull);

        final folder = ExploreCandidateFolder(
          id: 'f-1',
          name: '暖光',
          createdAt: DateTime.utc(2026, 9, 14),
        );
        final filled = run.copyWith(
          folders: [folder],
          candidates: [
            ExploreCandidate.shell(
              roundId: 'r',
              id: 'a',
            ).copyWith(folderId: folder.id),
            ExploreCandidate.shell(roundId: 'r', id: 'b'),
          ],
        );
        expect(filled.folderById('f-1'), folder);
        expect(filled.candidateById('a')!.folderId, 'f-1');
        expect(filled.candidateById('b')!.folderId, isNull);
      },
    );
  });
}
