import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';

void main() {
  late Directory hiveDirectory;
  late StyleExploreRunStorage storage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'style_explore_run_storage_test_',
    );
    Hive.init(hiveDirectory.path);
    storage = StyleExploreRunStorage();
    await storage.init();
  });

  setUp(() async {
    await storage.clear();
  });

  tearDownAll(() async {
    await storage.close();
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  ExploreRun run(String id, String name, {DateTime? updatedAt}) {
    return ExploreRun(
      id: id,
      name: name,
      status: ExploreRunStatus.draft,
      createdAt: DateTime.utc(2026, 8, 30),
      updatedAt: updatedAt ?? DateTime.utc(2026, 8, 31),
      targetCount: 10,
      recipeSnapshot: ExploreRecipeSnapshot(
        positive: PillDocument(
          text: 'soft lighting, $name',
          instances: const {},
        ),
        negative: const PillDocument(text: 'lowres', instances: {}),
      ),
      paramsSnapshot: const ExploreParamsSnapshot(
        model: 'nai-diffusion-4-5-full',
        width: 832,
        height: 1216,
        steps: 28,
        scale: 5.0,
        sampler: 'k_euler_ancestral',
        seed: -1,
        ucPreset: 0,
        qualityToggle: true,
        smea: false,
        smeaDyn: false,
        cfgRescale: 0.0,
        noiseSchedule: 'karras',
        varietyPlus: false,
        decrisp: false,
      ),
    );
  }

  test('JSON round-trip preserves nested documents and candidates', () async {
    const marker = '';
    final complex = run('complex', '复杂').copyWith(
      recipeSnapshot: ExploreRecipeSnapshot(
        positive: const PillDocument(
          text: '1girl,  tail',
          instances: {marker: PillInstance(blockId: 'b-1')},
        ),
        negative: PillDocument.empty(),
      ),
      candidates: [
        const ExploreCandidate(
          id: 'c-1',
          roundId: 'r-1',
          rollSnapshot: ExploreRollSnapshot(
            positive: '1girl, watercolor',
            negative: 'lowres',
            instanceRolls: [
              ExploreInstanceRoll(
                lane: 'pos',
                marker: marker,
                blockId: 'b-1',
                blockTitle: '画风',
                rolledText: 'watercolor',
              ),
            ],
          ),
          generation: ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.done,
            filePath: '/x/c-1.png',
            seed: 42,
            elapsedMs: 100,
          ),
          review: ExploreCandidateReview(heart: true),
          lineage: ExploreLineage(
            operation: ExploreLineageOperation.basicRoll,
          ),
        ),
      ],
    );

    await storage.putRun(complex);
    final restored = await storage.getRun('complex');

    expect(restored, complex);
    expect(
      restored!.candidates.single.rollSnapshot!.instanceRolls.single.marker,
      marker,
    );
  });

  test('getRuns sorts by updatedAt newest first', () async {
    await storage.putRun(run('old', '旧', updatedAt: DateTime.utc(2026, 1, 1)));
    await storage.putRun(run('new', '新', updatedAt: DateTime.utc(2026, 8, 31)));
    await storage.putRun(run('mid', '中', updatedAt: DateTime.utc(2026, 5, 1)));

    final runs = await storage.getRuns();
    expect(runs.map((item) => item.id), ['new', 'mid', 'old']);
  });

  test('corrupt records are skipped without affecting others', () async {
    await storage.putRun(run('good', '好'));
    final box = Hive.box<String>(StyleExploreRunStorage.boxName);
    await box.put(StyleExploreRunStorage.runKey('corrupt'), 'not a json {{{');

    final runs = await storage.getRuns();
    expect(runs.map((item) => item.id), ['good']);
    expect(await storage.getRun('corrupt'), isNull);
    expect(await storage.getRun('good'), isNotNull);
  });

  test('delete is idempotent and schema version stays readable', () async {
    expect(await storage.getSchemaVersion(), 1);

    await storage.putRun(run('doomed', '删我'));
    await storage.deleteRun('doomed');
    await storage.deleteRun('doomed');

    expect(await storage.getRun('doomed'), isNull);
    expect(await storage.getRuns(), isEmpty);
    expect(await storage.getSchemaVersion(), 1);

    final box = Hive.box<String>(StyleExploreRunStorage.boxName);
    final schema =
        jsonDecode(box.get(StyleExploreRunStorage.schemaKey)!)
            as Map<String, dynamic>;
    expect(schema['schemaVersion'], 1);
  });
}
