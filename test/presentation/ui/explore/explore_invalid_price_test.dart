import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_editor.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'explore_test_harness.dart';

class _Controller extends Fake implements ExploreController {}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final compact in [false, true]) {
    Future<RecordingExploreActions> pump(
      WidgetTester t,
      ExploreGenerate generate,
    ) async {
      final rec = RecordingExploreActions();
      await t.pumpWidget(
        exploreApp(
          ExploreScope(
            data: ExploreViewData(now: ExploreFixture.now, generate: generate),
            actions: rec.actions,
            controller: _Controller(),
            child: Center(
              child: SizedBox(
                width: 300,
                child: ExploreGenerateButton(compact: compact),
              ),
            ),
          ),
          locale: 'en',
        ),
      );
      await t.pumpAndSettle();
      return rec;
    }

    final button = find.byKey(
      Key(compact ? 'explore-onboarding-draw' : 'explore-generate'),
    );
    testWidgets(
      'invalid exploration estimate explains recovery, compact=$compact',
      (t) async {
        final rec = await pump(t, const ExploreGenerate(cost: -3));
        await t.tap(button);
        await t.pump();
        expect(rec.calls, isNot(contains('generate')));
        await t.longPress(button);
        await t.pumpAndSettle();
        expect(
          find.text(
            'This size and step combination is not supported. Reduce the size or steps.',
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'invalid next estimate keeps exploration stop available, compact=$compact',
      (t) async {
        final rec = await pump(
          t,
          const ExploreGenerate(cost: -3, phase: ExploreGeneratePhase.running),
        );
        await t.tap(button);
        await t.pump();
        expect(rec.calls, ['stop']);
      },
    );
    testWidgets('high exploration price remains actionable, compact=$compact', (
      t,
    ) async {
      final rec = await pump(
        t,
        const ExploreGenerate(cost: 60, highCost: true),
      );
      await t.tap(button);
      await t.pump();
      expect(rec.calls, ['generate']);
    });
  }
}
