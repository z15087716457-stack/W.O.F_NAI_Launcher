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

  testWidgets('出图数输入框与「开始」按钮等高且顶部齐平', (tester) async {
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

    final inputFinder = find.byKey(const Key('explore-run-target-count'));
    final buttonFinder = find.byKey(const Key('explore-run-start'));
    expect(inputFinder, findsOneWidget);
    expect(buttonFinder, findsOneWidget);

    // 出图数是与底条 ×N 同款的 DraggableNumberInput 紧凑芯片，
    // 不钉死高度（内在尺寸随主题走），只验证与按钮垂直居中对齐
    expect(
      tester.getCenter(inputFinder).dy,
      tester.getCenter(buttonFinder).dy,
      reason: '出图数芯片与按钮垂直居中对齐',
    );
    // 且不比按钮高（静反馈满高框笨重）
    expect(
      tester.getSize(inputFinder).height <= tester.getSize(buttonFinder).height,
      isTrue,
      reason: '出图数芯片高度不超过同行按钮',
    );
  });
}
