import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_run_control_bar.dart';

void main() {
  late Directory hiveDirectory;
  late StyleExploreRunStorage runStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'explore_control_bar_test_',
    );
    Hive.init(hiveDirectory.path);
    runStorage = StyleExploreRunStorage();
    await runStorage.init();
  });

  setUp(() async {
    await runStorage.clear();
  });

  tearDownAll(() async {
    await runStorage.close();
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  ExploreRun draftRun() => ExploreRun.create(
    name: '探索1',
    recipeSnapshot: const ExploreRecipeSnapshot(
      positive: PillDocument(text: 'pos', instances: {}),
      negative: PillDocument(text: 'neg', instances: {}),
    ),
    paramsSnapshot: const ExploreParamsSnapshot(
      model: 'm',
      width: 832,
      height: 1216,
      steps: 28,
      scale: 5,
      sampler: 's',
      seed: -1,
      ucPreset: 0,
      qualityToggle: true,
      smea: false,
      smeaDyn: false,
      cfgRescale: 0,
      noiseSchedule: 'n',
      varietyPlus: false,
      decrisp: false,
    ),
    targetCount: 10,
  );

  testWidgets('基础轮入口不在 Run 控制条重复显示', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(body: ExploreRunControlBar(run: draftRun())),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('explore-run-target-count')), findsNothing);
    expect(find.byKey(const Key('explore-run-start')), findsNothing);
    expect(find.text('共 0 张'), findsOneWidget);
    expect(find.byKey(const Key('explore-run-actions')), findsOneWidget);
  });

  testWidgets('窄宽 Run 控制条会换行且不溢出', (tester) async {
    tester.view.physicalSize = const Size(300, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final run = draftRun().copyWith(
      status: ExploreRunStatus.generated,
      candidates: [
        ExploreCandidate.shell(roundId: 'r-1', id: 'failed').copyWith(
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: 'boom',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(body: ExploreRunControlBar(run: run)),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('explore-run-control-bar-content')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('explore-run-retry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
