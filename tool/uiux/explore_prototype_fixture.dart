import 'dart:async';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_icon.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_text.dart';

import 'dart:io';
import 'dart:convert';
import 'package:nai_launcher/data/models/image/image_params.dart'
    hide CharacterPrompt;
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import 'package:flutter/material.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';

ExploreRun wallFixture({
  String id = 'wall',
  int count = 12,
  String scene = 'idle',
}) {
  final today = DateTime.now();
  final now = DateTime(today.year, today.month, today.day, 18, 54);
  final candidates = [
    for (var i = 1; i <= count; i++)
      ExploreCandidate(
        id: 'c$i',
        roundId: 'r${((i - 1) / 4).floor() + 1}',
        generation: ExploreCandidateGeneration(
          status: scene == 'failed' && i == count - 1
              ? ExploreCandidateGenerationStatus.failed
              : (scene == 'runner' || scene == 'manual') && i > count - 2
              ? ExploreCandidateGenerationStatus.pending
              : ExploreCandidateGenerationStatus.done,
          error: scene == 'failed' && i == count - 1 ? 'fixture failure' : null,
        ),
        rollSnapshot: const ExploreRollSnapshot(
          positive: 'scenery, artist:ciloranko',
          negative: 'lowres',
          instanceRolls: [
            ExploreInstanceRoll(
              lane: 'pos',
              marker: 'a',
              blockId: 'pool',
              blockTitle: '400精选画师池',
              rolledText: '0.8::artist:wanke::, artist:kantoku',
            ),
            ExploreInstanceRoll(
              lane: 'pos',
              marker: 'b',
              blockId: 'favorite',
              blockTitle: '收藏艺术家池',
              rolledText: '1.2::artist:quasarcake::',
            ),
          ],
        ),
        review: ExploreCandidateReview(heart: i == 1 || i == count),
        lineage: const ExploreLineage(
          operation: ExploreLineageOperation.manual,
        ),
      ),
  ];
  return ExploreRun(
    id: id,
    name: '柔光画风 · 400 池',
    status: ExploreRunStatus.generated,
    createdAt: now,
    updatedAt: now,
    targetCount: count,
    recipeSnapshot: ExploreRecipeSnapshot(
      positive: PillDocument.empty(),
      negative: PillDocument.empty(),
    ),
    paramsSnapshot: const ExploreParamsSnapshot(
      model: 'nai-diffusion-5',
      width: 832,
      height: 1216,
      steps: 28,
      scale: 5,
      sampler: 'k_euler_ancestral',
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
    rounds: [
      for (var i = 1; i <= (count / 4).ceil(); i++)
        ExploreRound(
          id: 'r$i',
          number: i,
          phase: ExploreRoundPhase.manual,
          status: scene == 'runner' && i == (count / 4).ceil()
              ? ExploreRoundStatus.generating
              : ExploreRoundStatus.generated,
          createdAt: now.subtract(Duration(minutes: (3 - i) * 20)),
          targetCount: 4,
          candidateIds: [
            for (final c in candidates)
              if (c.roundId == 'r$i') c.id,
          ],
        ),
    ],
    candidates: candidates,
  );
}

PromptBlockLibraryState variableFixtureLibrary({bool dark = false}) =>
    PromptBlockLibraryState(
      blocks: [
        PromptBlock(
          id: 'pool',
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
          title: '400精选画师池',
          content: 'artist:a',
          atoms: List.generate(400, (i) => 'artist:a$i'),
          color: dark ? '#FFF06595' : '#FFD6336C',
        ),
        PromptBlock(
          id: 'favorite',
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
          title: '收藏艺术家池',
          content: 'artist:b',
          atoms: List.generate(86, (i) => 'artist:b$i'),
          color: dark ? '#FF4DABF7' : '#FF1C7ED6',
        ),
        PromptBlock(
          id: 'negative',
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
          title: '负面随机池',
          content: 'lowres, blurry',
          color: '#FF0064E2',
        ),
      ],
      folders: [],
    );

PillDocument variableFixtureDocument(int count) => PillDocument(
  text: [
    for (var i = 0; i < count; i++) String.fromCharCode(0xe000 + i),
  ].join(' '),
  instances: {
    for (var i = 0; i < count; i++)
      String.fromCharCode(0xe000 + i): PillInstance(
        blockId: i == 0
            ? 'pool'
            : i == 1
            ? 'favorite'
            : 'negative',
        evolutionEnabled: i == 0,
        settings: const PillInstanceSettings(mode: PillRollMode.random),
      ),
  },
);

ExploreRun evolutionCaptureFixture({String scene = 'three'}) {
  final cards =
      jsonDecode(
            File('tool/uiux/explore_prototype_cards.json').readAsStringSync(),
          )
          as List;
  final base = wallFixture(count: 40), generations = scene == 'one' ? 1 : 3;
  final sets = [
    for (var g = 1; g <= generations; g++)
      ExploreParentSet(
        id: 'set$g',
        familyId: 'line',
        generation: g,
        status: g == generations
            ? ExploreParentSetStatus.active
            : ExploreParentSetStatus.used,
        parents: [
          for (var p = 0; p < (g == 1 ? 2 : 3); p++)
            ExploreParent(
              id: 'p$g-$p',
              sourceCandidateId:
                  'c${g == 1 ? p + 1 : 4 + (g - 2) * 12 + p + 1}',
              artistString: g == 1
                  ? '${p == 0 ? '0.8::artist:sincos::' : 'artist:ciloranko'}, artist:tiv'
                  : 'artist:child$p, artist:new',
              preference: [3.0, 2.0, 1.5, 1.0][p],
            ),
          if (g > 1)
            for (var p = 0; p < 2; p++)
              ExploreParent(
                id: 'back$g-$p',
                sourceCandidateId: 'c${p + 1}',
                artistString:
                    '${p == 0 ? '0.8::artist:sincos::' : 'artist:ciloranko'}, artist:tiv',
                preference: .75,
              ),
        ],
      ),
  ];
  final candidates = [
    for (var i = 0; i < 4 + generations * 12; i++)
      base.candidates[i].copyWith(
        roundId: i < 4 ? 'roots' : 'round${1 + (i - 4) ~/ 12}',
        generation: base.candidates[i].generation.copyWith(
          filePath:
              'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[i % cards.length]['image']}',
          status: scene == 'generating' && i >= 4 + generations * 12 - 3
              ? ExploreCandidateGenerationStatus.pending
              : ExploreCandidateGenerationStatus.done,
        ),
        lineage: ExploreLineage(
          operation: i < 4
              ? ExploreLineageOperation.basicRoll
              : [
                  ExploreLineageOperation.crossover,
                  ExploreLineageOperation.mutation,
                  ExploreLineageOperation.injection,
                ][i % 3],
          parentCandidateIds: i < 4 ? [] : ['c1', 'c2'],
          generation: i < 4 ? 1 : 1 + (i - 4) ~/ 12,
          mutatedText: 'artist:sincos, artist:tiv, artist:new',
        ),
      ),
  ];
  return base.copyWith(
    candidates: candidates,
    families: scene == 'empty'
        ? []
        : [
            ExploreFamily(
              id: 'line',
              name: '冷色·厚涂',
              createdAt: base.createdAt,
              rootParentSetId: 'set1',
              activeParentSetId: 'set$generations',
            ),
          ],
    parentSets: scene == 'empty' ? [] : sets,
    rounds: [
      ExploreRound(
        id: 'roots',
        number: 1,
        phase: ExploreRoundPhase.basic,
        status: ExploreRoundStatus.generated,
        createdAt: base.createdAt,
        targetCount: 4,
        candidateIds: [for (var i = 1; i <= 4; i++) 'c$i'],
      ),
      for (var g = 1; g <= generations; g++)
        ExploreRound(
          id: 'round$g',
          number: g + 1,
          phase: ExploreRoundPhase.deep,
          status: scene == 'generating' && g == generations
              ? ExploreRoundStatus.generating
              : ExploreRoundStatus.generated,
          createdAt: base.createdAt,
          targetCount: 12,
          parentSetId: 'set$g',
          familyId: 'line',
          generation: g,
          candidateIds: [
            for (var i = 0; i < 12; i++) 'c${5 + (g - 1) * 12 + i}',
          ],
        ),
    ],
  );
}

class ExploreCaptureRunStorage extends StyleExploreRunStorage {
  final Map<String, ExploreRun> _store = {};

  @override
  Future<List<ExploreRun>> getRuns() async {
    final runs = _store.values.toList()
      ..sort((a, b) {
        final comparison = b.updatedAt.compareTo(a.updatedAt);
        if (comparison != 0) return comparison;
        return a.id.compareTo(b.id);
      });
    return runs;
  }

  @override
  Future<ExploreRun?> getRun(String id) async => _store[id];

  @override
  Future<void> putRun(ExploreRun run, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    _store[run.id] = run;
  }

  @override
  ExploreRun? currentRun(String id) => _store[id];

  @override
  Future<ExploreRun> transformRun(
    String id,
    ExploreRun Function(ExploreRun) update,
  ) async {
    final next = update(_store[id]!);
    _store[id] = next;
    return next;
  }

  @override
  Future<void> deleteRun(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

class ExploreCaptureSettings extends LocalStorageService {
  ExploreCaptureSettings({Map<String, Object?>? initial}) {
    if (initial != null) settings.addAll(initial);
  }

  /// 已写入的设置值（含布局 provider 落盘的 toggle 状态）。
  final Map<String, Object?> settings = {};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = settings[key];
    if (value is T) return value;
    return defaultValue;
  }

  @override
  Future<void> setSetting<T>(String key, T value) async {
    settings[key] = value;
  }

  @override
  bool getEnablePromptWeightScroll() => false;

  @override
  bool getEnableAutocomplete() => false;

  @override
  bool getAutoFormatPrompt() => false;

  @override
  bool getHighlightEmphasis() => true;

  @override
  bool getSdSyntaxAutoConvert() => false;

  @override
  String getLastPrompt() => '';

  @override
  String getLastNegativePrompt() => '';

  @override
  String getDefaultModel() => 'nai-diffusion-4-5-full';

  @override
  String getDefaultSampler() => 'k_euler_ancestral';

  @override
  int getDefaultSteps() => 28;

  @override
  double getDefaultScale() => 5.0;

  @override
  int getDefaultWidth() => 832;

  @override
  int getDefaultHeight() => 1216;

  @override
  bool getLastSmea() => false;

  @override
  bool getLastSmeaDyn() => false;

  @override
  double getLastCfgRescale() => 0.0;

  @override
  String getLastNoiseSchedule() => 'native';

  @override
  bool getLastVarietyPlus() => false;
}

class ExploreCaptureVibes extends VibeLibraryNotifier {
  @override
  VibeLibraryState build() => const VibeLibraryState();
}

class ExploreCaptureVibeStorage extends VibeLibraryStorageService {
  @override
  Future<List<VibeLibraryEntry>> getRecentDisplayEntries({
    int limit = 20,
  }) async => const [];
}

class ExploreCaptureCooldown extends GenerationCooldownNotifier {
  @override
  GenerationCooldownState build() => const GenerationCooldownState();
}

class ExploreCaptureCharacters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig(
    characters: [
      CharacterPrompt(
        id: 'prototype-role',
        prompt:
            'girl, 1.5::loli, child::, 1.4::silver hair::, 1.3::long hair::, 0.3::fluffy hair, messy hair::, pale skin, hair between eyes, blue eyes, blush, black capelet, blue butterfly brooch, white blouse',
      ),
    ],
  );
}

class ExploreCaptureKrita extends KritaBridgeNotifier {
  @override
  Future<void> close() async {}
}

class ExploreCaptureSubscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 2218),
      usage: OpusUsage(percent: 147),
    ),
  );
}

class ExploreCaptureRunner extends ExploreRunRunner {
  int cancelCalls = 0, pauseCalls = 0;
  String? started;
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
  void set(ExploreRunRunnerState value) {
    state = value;
  }

  @override
  void pause() {
    pauseCalls++;
  }

  @override
  void cancel() {
    cancelCalls++;
  }

  @override
  Future<bool> start(
    String runId, {
    void Function(ImageParams)? beforeGenerate,
  }) async {
    started = runId;
    return true;
  }
}

class ExploreCaptureManual extends ExploreManualCaptureNotifier {
  @override
  ExploreManualCaptureState build() => const ExploreManualCaptureState();
  void set(ExploreManualCaptureState value) {
    state = value;
  }
}

class ExploreCaptureGeneration extends ImageGenerationNotifier {
  int cancelCalls = 0;
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void set(ImageGenerationState value) {
    state = value;
  }

  @override
  void cancel() {
    cancelCalls++;
  }
}

class ExploreCaptureLibrary extends PromptBlockLibraryNotifier {
  ExploreCaptureLibrary(this.dark);
  final bool dark;
  @override
  Future<PromptBlockLibraryState> build() async {
    final library = variableFixtureLibrary(dark: dark);
    return PromptBlockLibraryState(
      blocks: library.blocks,
      folders: [
        PromptBlockFolder(
          id: 'style',
          name: '画风',
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
        ),
      ],
    );
  }
}

class ExploreCaptureWorkspace extends PillWorkspaceNotifier {
  @override
  PillWorkspaceState build(String scope) {
    final doc = scope == PillScopes.main
        ? variableFixtureDocument(2).copyWith(
            text:
                'scenery, panorama, from behind, green theme, blue theme, plant, detailed background, (extremely vibrant colors), magical atmosphere, dynamic composition, sitting, wide shot, white dress, blue flower, frilled dress, giant, 0.8::artist:sincos:: ${variableFixtureDocument(2).text}\nartist:asteroid_ill, candid, year 2025, very aesthetic, masterpiece, sketch, lineart, solo, no text',
          )
        : PillDocument.empty();
    return PillWorkspaceState(document: doc, projection: doc.text);
  }
}

class ExploreCaptureParams extends GenerationParamsNotifier {
  ExploreCaptureParams(this.model);
  final String model;
  @override
  ImageParams build() => ImageParams(
    model: model,
    width: 832,
    height: 1216,
    steps: 28,
    scale: 5,
    nSamples: 10,
    sampler: 'k_dpmpp_2m_sde',
    prompt: 'scenery',
    seed: -1,
  );
  @override
  Future<void> restoreGenerationState() async {}
  @override
  Future<void> saveGenerationState() async {}
}

ExploreRun finalCaptureRun(String scene, String model) {
  final cards =
      jsonDecode(
            File(
              'tool/uiux/explore_prototype_all_cards.json',
            ).readAsStringSync(),
          )
          as List;
  final evolution = evolutionCaptureFixture();
  final base = wallFixture(count: scene == 'onboarding' ? 0 : 38);
  final candidates = [
    for (var i = 0; i < base.candidates.length; i++)
      base.candidates[i].copyWith(
        roundId: scene == 'evolution' || scene == 'compare'
            ? base.candidates[i].roundId
            : i < 16
            ? 'r1'
            : i < 26
            ? 'r2'
            : 'r3',
        generation: base.candidates[i].generation.copyWith(
          status: scene == 'running' && i >= 35
              ? ExploreCandidateGenerationStatus.pending
              : scene == 'failed' && i == 31
              ? ExploreCandidateGenerationStatus.failed
              : ExploreCandidateGenerationStatus.done,
          filePath:
              (scene == 'running' && i >= 35) || (scene == 'failed' && i == 31)
              ? null
              : 'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[i % cards.length]['image']}',
          seed: 3274348526 + (i >= 26 ? i - 26 : i),
          elapsedMs: 14800,
          error: scene == 'failed' && i == 31
              ? 'Synthetic failure, no API request'
              : null,
        ),
        rollSnapshot: ExploreRollSnapshot(
          positive:
              'scenery, panorama, from behind, green theme, blue theme, plant, detailed background, (extremely vibrant colors), magical atmosphere, dynamic composition, sitting, wide shot, white dress, blue flower, frilled dress, giant, 0.8::artist:sincos:: ${(cards[i % cards.length]['atoms'] as List).join(', ')}\nartist:asteroid_ill, candid, year 2025, very aesthetic, masterpiece, sketch, lineart, solo, no text',
          negative: 'lowres, bad anatomy',
          instanceRolls: [
            const ExploreInstanceRoll(
              lane: 'pos',
              marker: '\uE000',
              blockId: 'pool',
              blockTitle: '400精选画师池',
              rolledText: '',
            ),
            ExploreInstanceRoll(
              lane: 'pos',
              marker: '\uE001',
              blockId: 'favorite',
              blockTitle: '收藏艺术家池',
              rolledText: (cards[i % cards.length]['atoms'] as List).join(', '),
            ),
          ],
        ),
        review: ExploreCandidateReview(
          heart: [17, 22, 26, 28, 30, 33].contains(i),
        ),
        folderId: i == 26 || i == 30 || i == 37
            ? 'cold'
            : i == 33 || i == 22
            ? 'thick'
            : null,
      ),
  ];
  final configured = base.copyWith(
    paramsSnapshot: base.paramsSnapshot.copyWith(
      model: model,
      sampler: 'k_dpmpp_2m_sde',
    ),
    status: scene == 'running'
        ? ExploreRunStatus.generating
        : ExploreRunStatus.generated,
    candidates: candidates,
    families: [
      evolution.families.single.copyWith(name: '柔光主线'),
      evolution.families.single.copyWith(
        id: 'side',
        name: '冷色支线',
        activeParentSetId: 'side2',
      ),
    ],
    parentSets: [
      ...evolution.parentSets,
      evolution.parentSets[1].copyWith(id: 'side2', familyId: 'side'),
    ],
    folders: [
      ExploreCandidateFolder(
        id: 'cold',
        name: '冷色调',
        createdAt: base.createdAt,
      ),
      ExploreCandidateFolder(
        id: 'thick',
        name: '厚涂',
        createdAt: base.createdAt,
      ),
    ],
    rounds: scene == 'evolution' || scene == 'compare'
        ? base.rounds
        : [
            for (var i = 1; i <= 3; i++)
              ExploreRound(
                id: 'r$i',
                number: i,
                phase: ExploreRoundPhase.manual,
                status: scene == 'running' && i == 3
                    ? ExploreRoundStatus.generating
                    : ExploreRoundStatus.generated,
                createdAt: base.createdAt.subtract(
                  Duration(minutes: (3 - i) * 94),
                ),
                targetCount: i == 1
                    ? 16
                    : i == 2
                    ? 10
                    : 12,
                candidateIds: [
                  for (final c in candidates)
                    if (c.roundId == 'r$i') c.id,
                ],
              ),
          ],
  );
  return scene == 'evolution' || scene == 'compare'
      ? _prototypeEvolution(configured, cards)
      : configured;
}

/// Surrounding reference navigation for the isolated screenshot fixture.
/// Production routing continues to use the app's navigation shell.
class ExploreCaptureRail extends StatelessWidget {
  const ExploreCaptureRail({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget divider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Container(width: 20, height: 1, color: c.outlineVariant),
    );
    Widget item(IconData glyph, {bool selected = false}) => Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected ? c.primary.withValues(alpha: .1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        glyph,
        size: 20,
        color: selected ? c.primary : c.onSurface.withValues(alpha: .78),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          right: BorderSide(color: c.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xff005dff),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const ExploreText(
              '鹈',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          divider(),
          item(const IconData(0xe906, fontFamily: 'StudioIcons')),
          item(
            const IconData(0xe900, fontFamily: 'StudioIcons'),
            selected: true,
          ),
          divider(),
          for (final glyph in const [
            IconData(0xe907, fontFamily: 'StudioIcons'),
            IconData(0xe902, fontFamily: 'StudioIcons'),
            IconData(0xe903, fontFamily: 'StudioIcons'),
            IconData(0xe905, fontFamily: 'StudioIcons'),
            IconData(0xe904, fontFamily: 'StudioIcons'),
            IconData(0xe918, fontFamily: 'StudioIcons'),
          ])
            item(glyph),
          divider(),
          item(const IconData(0xe908, fontFamily: 'StudioIcons')),
          const Spacer(),
          SizedBox(
            width: 36,
            height: 44,
            child: Center(
              child: ExploreIcon('dbl', size: 18, color: c.onSurfaceVariant),
            ),
          ),
          item(const IconData(0xe909, fontFamily: 'StudioIcons')),
        ],
      ),
    );
  }
}

/// Raw prototype sample data in a consistent in-memory evolution model.
/// Pair totals and preference bars continue to use the production algorithms.
ExploreRun _prototypeEvolution(ExploreRun base, List cards) {
  final indexes = [for (var i = 0; i < 38; i++) i];
  for (var i = 0; i < 4; i++) {
    indexes[i] = [26, 28, 29, 32][i];
  }
  for (var i = 0; i < 10; i++) {
    indexes[4 + i] = 2 + i;
  }
  for (var i = 0; i < 12; i++) {
    indexes[22 + i] = i < 10 ? 16 + i : i - 10;
  }
  indexes[36] = 17;
  final ops = [
    ExploreLineageOperation.crossover,
    ExploreLineageOperation.mutation,
    ExploreLineageOperation.crossover,
    ExploreLineageOperation.injection,
    ExploreLineageOperation.mutation,
    ExploreLineageOperation.crossover,
    ExploreLineageOperation.crossover,
    ExploreLineageOperation.mutation,
    ExploreLineageOperation.injection,
    ExploreLineageOperation.crossover,
    ExploreLineageOperation.mutation,
    ExploreLineageOperation.crossover,
  ];
  final candidates = [
    for (var i = 0; i < 38; i++)
      base.candidates[i].copyWith(
        roundId: i >= 22 && i < 34
            ? 'round3'
            : i >= 4 && i < 14
            ? 'round2'
            : 'roots',
        generation: base.candidates[i].generation.copyWith(
          filePath:
              'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[indexes[i]]['image']}',
        ),
        rollSnapshot: ExploreRollSnapshot(
          positive:
              'scenery, ${(cards[indexes[i]]['atoms'] as List).join(', ')}, year 2025',
          negative: 'lowres, bad anatomy',
          instanceRolls: [
            ExploreInstanceRoll(
              lane: 'pos',
              marker: '',
              blockId: 'pool',
              blockTitle: '400精选画师池',
              rolledText: (cards[indexes[i]]['atoms'] as List).join(', '),
            ),
          ],
        ),
        review: ExploreCandidateReview(
          heart: cards[indexes[i]]['heart'] == true,
        ),
        folderId: null,
        lineage: ExploreLineage(
          operation: i >= 22 && i < 34
              ? ops[i - 22]
              : ExploreLineageOperation.basicRoll,
          generation: i >= 22 && i < 34 ? 3 : 1,
          parentCandidateIds: i >= 22 && i < 34 ? ['c1'] : [],
          mutatedText: i == 23
              ? '0.8::artist:sincos::, 0.7::artist:tiv::'
              : null,
        ),
      ),
  ];
  ExploreParent parent(int index, double weight) => ExploreParent(
    id: 'p$index',
    sourceCandidateId: 'c${index + 1}',
    preference: weight,
    artistString:
        candidates[index].rollSnapshot!.instanceRolls.single.rolledText,
  );
  final sets = [
    ExploreParentSet(
      id: 'set1',
      familyId: 'line',
      generation: 1,
      status: ExploreParentSetStatus.used,
      parents: [parent(0, 1), parent(36, 1), parent(35, 1), parent(36, 1)],
    ),
    ExploreParentSet(
      id: 'set2',
      familyId: 'line',
      generation: 2,
      status: ExploreParentSetStatus.used,
      parents: [for (var i = 0; i < 4; i++) parent(i, 1)],
    ),
    ExploreParentSet(
      id: 'set3',
      familyId: 'line',
      generation: 3,
      status: ExploreParentSetStatus.active,
      parents: [
        parent(0, 3),
        parent(1, 2),
        parent(2, 1.5),
        parent(3, 1),
        parent(36, .75),
      ],
    ),
    ExploreParentSet(
      id: 'side2',
      familyId: 'side',
      generation: 2,
      status: ExploreParentSetStatus.active,
      parents: [parent(34, 1), parent(35, 1)],
    ),
  ];
  return base.copyWith(
    candidates: candidates,
    parentSets: sets,
    rounds: [
      ExploreRound(
        id: 'roots',
        number: 1,
        phase: ExploreRoundPhase.basic,
        status: ExploreRoundStatus.generated,
        createdAt: base.createdAt,
        targetCount: 4,
        familyId: 'line',
        parentSetId: 'set1',
        generation: 1,
        candidateIds: const [],
      ),
      ExploreRound(
        id: 'round2',
        number: 2,
        phase: ExploreRoundPhase.deep,
        status: ExploreRoundStatus.generated,
        createdAt: base.createdAt,
        targetCount: 10,
        familyId: 'line',
        parentSetId: 'set2',
        generation: 2,
        candidateIds: [for (var i = 5; i <= 14; i++) 'c$i'],
      ),
      ExploreRound(
        id: 'round3',
        number: 3,
        phase: ExploreRoundPhase.deep,
        status: ExploreRoundStatus.generated,
        createdAt: base.createdAt,
        targetCount: 12,
        familyId: 'line',
        parentSetId: 'set3',
        generation: 3,
        candidateIds: [for (var i = 23; i <= 34; i++) 'c$i'],
      ),
    ],
  );
}
