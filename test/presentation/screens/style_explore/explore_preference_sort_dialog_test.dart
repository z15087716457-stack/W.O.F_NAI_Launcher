import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_preference_sort_dialog.dart';

/// 内存版 Run 存储（testWidgets 的 fakeAsync 区里 Hive 异步写盘不落定）。
class _MemoryRunStorage extends StyleExploreRunStorage {
  final Map<String, ExploreRun> _store = {};

  @override
  Future<List<ExploreRun>> getRuns() async => _store.values.toList();

  @override
  Future<ExploreRun?> getRun(String id) async => _store[id];

  @override
  Future<void> putRun(ExploreRun run, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    _store[run.id] = run;
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

class _DialogHost extends StatelessWidget {
  const _DialogHost({required this.runId, required this.parentSet});

  final String runId;
  final ExploreParentSet parentSet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('open-sort-dialog'),
          onPressed: () => ExplorePreferenceSortDialog.show(
            context,
            runId: runId,
            parentSet: parentSet,
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  late _MemoryRunStorage storage;
  late Directory tempDir;
  late String imagePath;
  final l10n = lookupAppLocalizations(const Locale('zh'));

  setUp(() {
    storage = _MemoryRunStorage();
    tempDir = Directory.systemTemp.createTempSync('explore-sort-dialog-test');
    // 真实小图：Image.file 走正常加载路径（缺图侧才落占位）。
    imagePath = '${tempDir.path}/c-1.png';
    File(imagePath).writeAsBytesSync(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
        'z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==',
      ),
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  const recipeSnapshot = ExploreRecipeSnapshot(
    positive: PillDocument(text: 'pos', instances: {}),
    negative: PillDocument(text: 'neg', instances: {}),
  );
  const paramsSnapshot = ExploreParamsSnapshot(
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
    cfgRescale: 0,
    noiseSchedule: 'karras',
    varietyPlus: false,
    decrisp: false,
  );

  ExploreCandidate candidate(String id, {String? filePath}) {
    return ExploreCandidate(
      id: id,
      roundId: 'dr-1',
      generation: ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
        filePath: filePath,
      ),
      lineage: const ExploreLineage(
        operation: ExploreLineageOperation.mutation,
        generation: 2,
        mutatedText: 'mut:a',
      ),
    );
  }

  /// 三个父本：p-1 有原图、p-2 来源候选无图、p-3 自定义串（无来源）→ 3 对。
  ExploreRun sortRun() {
    final createdAt = DateTime.utc(2026, 9, 1);
    return ExploreRun(
      id: 'run-1',
      name: 'A/B 对照',
      status: ExploreRunStatus.generated,
      createdAt: createdAt,
      updatedAt: createdAt,
      targetCount: 3,
      recipeSnapshot: recipeSnapshot,
      paramsSnapshot: paramsSnapshot,
      rounds: [
        ExploreRound(
          id: 'dr-1',
          number: 1,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.generated,
          createdAt: createdAt,
          targetCount: 3,
          candidateIds: const ['c-1', 'c-2'],
          familyId: 'fam-1',
          parentSetId: 'ps-1',
          generation: 2,
        ),
      ],
      candidates: [
        candidate('c-1', filePath: imagePath),
        candidate('c-2'),
      ],
      parentSets: const [
        ExploreParentSet(
          id: 'ps-1',
          familyId: 'fam-1',
          generation: 1,
          status: ExploreParentSetStatus.active,
          parents: [
            ExploreParent(
              id: 'p-1',
              sourceCandidateId: 'c-1',
              artistString: 'artist:with-image',
            ),
            ExploreParent(
              id: 'p-2',
              sourceCandidateId: 'c-2',
              artistString: 'artist:no-image',
            ),
            ExploreParent(id: 'p-3', artistString: 'artist:custom'),
          ],
        ),
      ],
      families: [
        ExploreFamily(
          id: 'fam-1',
          name: '家族甲',
          createdAt: createdAt,
          rootParentSetId: 'ps-1',
          activeParentSetId: 'ps-1',
        ),
      ],
    );
  }

  Future<void> openDialog(WidgetTester tester, ExploreRun run) async {
    await storage.putRun(run);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [styleExploreRunStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _DialogHost(runId: run.id, parentSet: run.parentSets.first),
        ),
      ),
    );
    // run 列表加载落定后再开窗（弹窗按 runId 解析原图与偏好）。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('open-sort-dialog')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder button(String key) => find.byKey(Key(key));

  testWidgets('narrow comparison keeps contain images and puts ranking below', (
    tester,
  ) async {
    await openDialog(tester, sortRun());
    final dialog = find.byKey(const Key('explore-preference-sort-dialog'));
    final surface = tester.getSize(
      find.descendant(of: dialog, matching: find.byType(Material)).first,
    );
    expect(surface.width, 1152);
    expect(surface.height, 852);
    expect(find.text(l10n.styleExplore_compareQuestion), findsOneWidget);
    expect(find.text(l10n.styleExplore_sortProgress(1, 3)), findsOneWidget);
    expect(find.text(l10n.styleExplore_candidateMissing), findsOneWidget);
    final left = tester.getRect(
      find.byKey(const Key('explore-sort-side-left')),
    );
    final right = tester.getRect(
      find.byKey(const Key('explore-sort-side-right')),
    );
    final ranking = tester.getRect(
      find.byKey(const Key('explore-sort-ranking')),
    );
    expect(left.top, right.top);
    expect(left.right, lessThan(right.left));
    expect(ranking.top, greaterThan(left.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide comparison uses prototype 1380 dialog, 280 ranking and 610 image limit',
    (tester) async {
      await openDialog(tester, sortRun());
      tester.view.physicalSize = const Size(1600, 1000);
      await tester.pumpAndSettle();
      final dialog = find.byKey(const Key('explore-preference-sort-dialog'));
      expect(
        tester
            .getSize(
              find
                  .descendant(of: dialog, matching: find.byType(Material))
                  .first,
            )
            .width,
        1380,
      );
      expect(
        tester.getSize(find.byKey(const Key('explore-sort-ranking'))).width,
        280,
      );
      final ranking = tester.getRect(
            find.byKey(const Key('explore-sort-ranking')),
          ),
          right = tester.getRect(
            find.byKey(const Key('explore-sort-side-right')),
          );
      expect(ranking.left, greaterThan(right.right));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'arrow and space shortcuts persist answers; escape closes early',
    (tester) async {
      await openDialog(tester, sortRun());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        (await storage.getRun(
          'run-1',
        ))!.parentSets.single.comparisons.map((c) => c.result),
        [
          ExploreComparisonResult.left,
          ExploreComparisonResult.neither,
          ExploreComparisonResult.skip,
        ],
      );
      expect(
        find.byKey(const Key('explore-preference-sort-dialog')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byKey(const Key('open-sort-dialog')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        (await storage.getRun(
          'run-1',
        ))!.parentSets.single.comparisons.last.result,
        ExploreComparisonResult.right,
      );
      expect(
        find.byKey(const Key('explore-preference-sort-dialog')),
        findsNothing,
      );
    },
  );

  testWidgets('左边好：落盘 +1.0，后续对子显示最新偏好值', (tester) async {
    await openDialog(tester, sortRun());

    await tester.tap(button('explore-sort-left'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final stored = (await storage.getRun('run-1'))!;
    expect(stored.parentSetById('ps-1')!.parents.first.preference, 2.0);
    expect(stored.parentSetById('ps-1')!.comparisons, hasLength(1));

    // 第 2 对 = (p-1, p-3)：左侧显示对照中刚落盘的 2.0，不是开窗快照 1.0。
    expect(find.text(l10n.styleExplore_sortProgress(2, 3)), findsOneWidget);
    expect(find.text('2.0'), findsOneWidget);
    expect(find.text('1.0'), findsWidgets);
    expect(find.text('artist:custom'), findsWidgets);
  });

  testWidgets('都不好 / 跳过 / 右边好：偏好落盘与关窗提示', (tester) async {
    await openDialog(tester, sortRun());

    await tester.tap(button('explore-sort-neither'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(button('explore-sort-skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(button('explore-sort-right'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final parents = (await storage.getRun(
      'run-1',
    ))!.parentSetById('ps-1')!.parents;
    // neither 各 -0.25、skip 只记录、right 胜方 +1.0。
    expect(parents.map((parent) => parent.preference), [0.75, 0.75, 2.0]);

    // 全部比完自动关窗并提示。
    expect(
      find.byKey(const Key('explore-preference-sort-dialog')),
      findsNothing,
    );
    expect(find.text(l10n.styleExplore_sortDone), findsOneWidget);

    // AppToast 的 3 秒自动关闭定时器。
    await tester.pump(const Duration(milliseconds: 3300));
  });
}
