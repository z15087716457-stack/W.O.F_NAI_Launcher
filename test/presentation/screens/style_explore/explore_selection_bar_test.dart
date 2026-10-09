import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_wall.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_selection_bar.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_filter_widgets.dart';
import 'explore_candidate_wall_test.dart';
import 'explore_inspector_test.dart' show InspectorBlocks;
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';

void main() {
  testWidgets('pending candidate is preserved when Delete is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      wallFixtureApp(wallFixture(count: 4, scene: 'manual'), scene: 'manual'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-candidate-c4')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ExploreCandidateWall)),
    );
    expect(
      container
          .read(exploreActiveRunProvider)!
          .candidateById('c4')!
          .generation
          .status,
      ExploreCandidateGenerationStatus.pending,
    );
  });
  testWidgets(
    'narrow stage exposes remaining actions in the shared overflow menu',
    (tester) async {
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        wallFixtureApp(wallFixture(count: 4), width: 480),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExploreCandidateWall)),
      );
      container.read(exploreSelectionModeProvider.notifier).state = true;
      container.read(exploreSelectionProvider.notifier).selectAll(['c1', 'c2']);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('library-selection-overflow')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PopupMenuItem<int>, '开始进化'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    ExploreRun? run,
    Widget? child,
  }) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wallFixtureApp(
        run ?? wallFixture(count: 4),
        width: 1100,
        child: child,
        extraOverrides: [
          promptBlockLibraryNotifierProvider.overrideWith(InspectorBlocks.new),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(ExploreCandidateWall)),
    );
  }

  Future<void> click(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('explore-candidate-$id')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  test('vertical movement preserves columns across uneven rounds', () {
    final run = wallFixture();
    final visible = exploreWallCandidates(run, const ExploreGalleryFilterAll());
    expect(exploreMovedFocus(visible, 'c12', 0, 1, 3), 'c5');
    expect(exploreMovedFocus(visible, 'c5', 0, -1, 3), 'c12');
    expect(exploreMovedFocus(visible, 'c10', 0, 1, 3), 'c12');
    expect(exploreMovedFocus(visible, 'c9', -1, 0, 3), 'c9');
  });
  testWidgets('shared chips include counts and full selection follows filter', (
    tester,
  ) async {
    final container = await pump(tester);
    final favorite = tester.widget<GalleryFilterChip>(
      find.byWidgetPredicate((w) => w is GalleryFilterChip && w.label == '收藏'),
    );
    expect(favorite.count, 2);
    await tester.tap(find.byKey(const Key('explore-filter-hearted')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-gallery-select-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-gallery-select-toggle')));
    await tester.pumpAndSettle();
    expect(container.read(exploreSelectionProvider), {'c1', 'c4'});
    expect(find.byType(ExploreSelectionBar), findsOneWidget);
  });
  testWidgets(
    'Ctrl toggles, Shift selects a range; tab switch clears both states',
    (tester) async {
      final container = await pump(tester);
      await click(tester, 'c1');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await click(tester, 'c3');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(container.read(exploreSelectionProvider), {'c3'});
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await click(tester, 'c1');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(container.read(exploreSelectionProvider), {'c1', 'c2', 'c3'});
      await tester.tap(find.byKey(const Key('explore-tab-evolution')));
      await tester.pumpAndSettle();
      expect(container.read(exploreSelectionProvider), isEmpty);
      expect(container.read(exploreSelectionModeProvider), isFalse);
    },
  );
  testWidgets(
    'hover checkbox enters selection; double click still opens viewer',
    (tester) async {
      final container = await pump(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(
        tester.getCenter(find.byKey(const Key('explore-candidate-c2'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-candidate-select-c2')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(container.read(exploreSelectionModeProvider), isTrue);
      expect(container.read(exploreSelectionProvider), {'c2'});
      final card = find.byKey(const Key('explore-candidate-c2'));
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-candidate-detail')), findsOneWidget);
      await mouse.removePointer();
    },
  );
  testWidgets(
    'F and grouping shortcuts preserve focus; Delete confirms before removal',
    (tester) async {
      final run = wallFixture(count: 4);
      final container = await pump(
        tester,
        run: run.copyWith(
          folders: [
            ExploreCandidateFolder(
              id: 'cool',
              name: '冷光',
              createdAt: run.createdAt,
            ),
          ],
        ),
      );
      await click(tester, 'c2');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      expect(
        container
            .read(exploreActiveRunProvider)!
            .candidateById('c2')!
            .review
            .heart,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c2')!.folderId,
        'cool',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c2')!.folderId,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c2'),
        isNotNull,
      );
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pumpAndSettle();
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c2'),
        isNull,
      );
      expect(container.read(exploreFocusedCandidateIdProvider), 'c3');
    },
  );
  testWidgets('navigation and Escape clear selection then focus', (
    tester,
  ) async {
    final container = await pump(tester);
    await click(tester, 'c2');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(container.read(exploreFocusedCandidateIdProvider), 'c3');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(container.read(exploreSelectionProvider).length, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(container.read(exploreSelectionProvider), isEmpty);
    expect(container.read(exploreFocusedCandidateIdProvider), 'c3');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(container.read(exploreFocusedCandidateIdProvider), isNull);
  });
  testWidgets(
    'text input outside stage receives keys without candidate actions',
    (tester) async {
      final container = await pump(
        tester,
        child: const Column(
          children: [
            TextField(key: Key('outside-editor')),
            Expanded(child: ExploreCandidateWall()),
          ],
        ),
      );
      await click(tester, 'c2');
      await tester.enterText(find.byKey(const Key('outside-editor')), 'draft');
      for (final key in [
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.delete,
        LogicalKeyboardKey.space,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(exploreSelectionProvider), isEmpty);
      expect(
        container
            .read(exploreActiveRunProvider)!
            .candidateById('c2')!
            .review
            .heart,
        isFalse,
      );
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  testWidgets('selection bar toggles all hearts and assigns chosen group', (
    tester,
  ) async {
    final run = wallFixture(count: 4);
    final container = await pump(
      tester,
      run: run.copyWith(
        folders: [
          ExploreCandidateFolder(
            id: 'cool',
            name: '冷光',
            createdAt: run.createdAt,
          ),
        ],
      ),
    );
    container.read(exploreSelectionModeProvider.notifier).state = true;
    container.read(exploreSelectionProvider.notifier).selectAll(['c1', 'c2']);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-selection-heart')));
    await tester.pumpAndSettle();
    expect(
      container
          .read(exploreActiveRunProvider)!
          .candidates
          .take(2)
          .every((c) => c.review.heart),
      isTrue,
    );
    await tester.tap(find.widgetWithText(TextButton, '分组'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, '冷光'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(exploreActiveRunProvider)!
          .candidates
          .take(2)
          .every((c) => c.folderId == 'cool'),
      isTrue,
    );
  });
}
