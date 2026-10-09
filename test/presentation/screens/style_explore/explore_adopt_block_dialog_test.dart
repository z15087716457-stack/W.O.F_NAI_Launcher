import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_adopt_block_dialog.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'explore_candidate_wall_test.dart';

class SaveDialogLibrary extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [],
    folders: [
      PromptBlockFolder.create(id: 'style', name: '画风'),
      PromptBlockFolder.create(id: 'soft', name: '柔光', parentId: 'style'),
    ],
  );
}

Widget saveDialogApp(
  List<ExploreCandidate> candidates, {
  String locale = 'zh',
  bool dark = false,
  ValueChanged<ExploreAdoptBlockResult?>? onResult,
}) => ProviderScope(
  overrides: [
    promptBlockLibraryNotifierProvider.overrideWith(SaveDialogLibrary.new),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: (dark ? GeistTheme.dark : GeistTheme.light).copyWith(
      platform: TargetPlatform.windows,
    ),
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('open-save'),
            onPressed: () async {
              final result = await ExploreAdoptBlockDialog.show(
                context,
                initialTitle: candidates.length == 1
                    ? '柔光画风 #27'
                    : '柔光画风 ×${candidates.length}',
                candidates: candidates,
                sequenceNumber: 27,
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

List<ExploreCandidate> saveDialogFixture() {
  final base = wallFixture(count: 3);
  return [
    for (var i = 0; i < 3; i++)
      base.candidates[i].copyWith(
        rollSnapshot: ExploreRollSnapshot(
          positive: 'scenery, 0.8::artist:a, artist:b::, artist:c, year 2025',
          negative: 'lowres',
          instanceRolls: [
            ExploreInstanceRoll(
              lane: 'pos',
              marker: 'p',
              blockId: 'pool',
              blockTitle: 'Artists',
              rolledText: i == 2
                  ? 'artist:d, artist:c'
                  : '0.8::artist:a, artist:b::, artist:c',
            ),
            const ExploreInstanceRoll(
              lane: 'neg',
              marker: 'n',
              blockId: 'negative',
              blockTitle: 'Negative',
              rolledText: 'bad anatomy',
            ),
          ],
        ),
      ),
  ];
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('zh'));
  Future<void> open(
    WidgetTester tester,
    List<ExploreCandidate> candidates, {
    ValueChanged<ExploreAdoptBlockResult?>? onResult,
  }) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(saveDialogApp(candidates, onResult: onResult));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-save')));
    await tester.pumpAndSettle();
  }

  test(
    'only positive draw records are deduplicated, and internal commas stay one atom',
    () {
      expect(exploreAdoptArtists(saveDialogFixture()), [
        '0.8::artist:a, artist:b::',
        'artist:c',
        'artist:d',
      ]);
      expect(exploreAdoptPositive(saveDialogFixture()), [
        'scenery',
        '0.8::artist:a, artist:b::',
        'artist:c',
        'year 2025',
      ]);
    },
  );
  testWidgets('artist/full modes remove and restore independently', (
    tester,
  ) async {
    await open(tester, saveDialogFixture());
    expect(
      find.byKey(const ValueKey('explore-adopt-remove-scenery')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('explore-adopt-remove-artist:c')),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.styleExplore_saveRemoved(1)), findsOneWidget);
    await tester.tap(find.byKey(const Key('explore-adopt-full')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('explore-adopt-remove-scenery')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('explore-adopt-remove-artist:c')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('explore-adopt-artists')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('explore-adopt-remove-artist:c')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('explore-adopt-restore')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('explore-adopt-remove-artist:c')),
      findsOneWidget,
    );
  });
  testWidgets('all atoms removed or empty title disables save', (tester) async {
    await open(tester, saveDialogFixture());
    for (final raw in exploreAdoptArtists(saveDialogFixture())) {
      await tester.tap(find.byKey(ValueKey('explore-adopt-remove-$raw')));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('explore-adopt-block-confirm')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('explore-adopt-restore')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('explore-adopt-block-name')),
      ' ',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('explore-adopt-block-confirm')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'legacy candidates default to full prompt with artist mode disabled',
    (tester) async {
      await open(tester, [
        saveDialogFixture().first.copyWith(
          rollSnapshot: const ExploreRollSnapshot(
            positive: 'artist:legacy, scenery',
            negative: '',
          ),
        ),
      ]);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('explore-adopt-artists')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const ValueKey('explore-adopt-remove-scenery')),
        findsOneWidget,
      );
      expect(find.text(l10n.styleExplore_saveNoDraws), findsOneWidget);
    },
  );
  testWidgets(
    'save returns exact atoms/content and nested folder, selected color and icon',
    (tester) async {
      ExploreAdoptBlockResult? result;
      await open(tester, saveDialogFixture(), onResult: (r) => result = r);
      await tester.tap(
        find.byKey(const ValueKey('prompt-block-color-option-#FF0064E2')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-adopt-folder')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('画风 / 柔光').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prompt-block-icon-trigger')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('prompt-block-icon-option-palette')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-adopt-block-confirm')));
      await tester.pumpAndSettle();
      expect(result!.atoms, [
        '0.8::artist:a, artist:b::',
        'artist:c',
        'artist:d',
      ]);
      expect(result!.content, result!.atoms.join(', '));
      expect(result!.folderId, 'soft');
      expect(result!.color, '#FF0064E2');
      expect(result!.iconName, 'palette');
    },
  );
}
