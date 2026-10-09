import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_onboarding.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';
import 'explore_candidate_wall_test.dart';
import 'explore_start_evolution_dialog_test.dart';

class OnboardingParams extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(nSamples: 10, prompt: 'scenery');
}

class OnboardingGeneration extends ImageGenerationNotifier {
  OnboardingGeneration([this.generating = false]);
  final bool generating;
  @override
  ImageGenerationState build() => ImageGenerationState(
    status: generating ? GenerationStatus.generating : GenerationStatus.idle,
  );
}

class OnboardingWorkspace extends EvolutionDialogWorkspace {
  OnboardingWorkspace(super.target);
  void setDocument(PillDocument doc) =>
      state = PillWorkspaceState(document: doc, projection: '');
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('zh'));
  testWidgets(
    'empty stage shows live variable pills, generate callback and previous run action',
    (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var generated = 0, opened = 0;
      await tester.pumpWidget(
        wallFixtureApp(
          wallFixture(count: 0),
          child: ExploreOnboarding(
            onGenerate: () async {
              generated++;
            },
            onOpenPrevious: () {
              opened++;
            },
          ),
          extraOverrides: [
            generationParamsNotifierProvider.overrideWith(OnboardingParams.new),
            imageGenerationNotifierProvider.overrideWith(
              OnboardingGeneration.new,
            ),
            promptBlockLibraryNotifierProvider.overrideWith(
              EvolutionDialogBlocks.new,
            ),
            pillWorkspaceProvider.overrideWith(() => OnboardingWorkspace(true)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PromptPill), findsOneWidget);
      expect(find.text(l10n.styleExplore_onboardingDraw(10)), findsOneWidget);
      await tester.tap(find.byKey(const Key('explore-onboarding-generate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-onboarding-previous')));
      await tester.pumpAndSettle();
      expect(generated, 1);
      expect(opened, 1);
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      (scope.read(pillWorkspaceProvider(PillScopes.main).notifier)
              as OnboardingWorkspace)
          .setDocument(PillDocument.empty());
      await tester.pumpAndSettle();
      expect(find.byType(PromptPill), findsNothing);
      expect(
        find.byKey(const Key('explore-onboarding-library')),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'missing blocks can open library; generation disables while busy',
    (tester) async {
      var library = 0, gen = 0;
      await tester.pumpWidget(
        wallFixtureApp(
          wallFixture(count: 0),
          child: ExploreOnboardingView(
            blocks: const [],
            count: 7,
            generating: true,
            hasPrevious: false,
            onOpenLibrary: () {
              library++;
            },
            onGenerate: () async {
              gen++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('explore-onboarding-library')));
      await tester.pumpAndSettle();
      expect(library, 1);
      expect(gen, 0);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('explore-onboarding-generate')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const Key('explore-onboarding-previous')),
        findsNothing,
      );
    },
  );
}
