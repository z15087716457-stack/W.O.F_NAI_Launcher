import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/image_generation_provider.dart';
import '../providers/tips_provider.dart';
import '../screens/generation/widgets/generation_controls/generation_controls.dart';
import '../screens/generation/widgets/generation_module_card.dart';
import '../screens/generation/widgets/generation_params_menu_host.dart';
import '../screens/generation/widgets/header_capsules.dart';
import '../screens/generation/widgets/img2img_panel.dart';
import '../screens/generation/widgets/precise_reference_panel.dart';
import '../screens/generation/widgets/prompt_input.dart';
import '../screens/generation/widgets/size_selector.dart';
import '../screens/generation/widgets/unified_reference_panel.dart';
import '../ui/explore/explore_contract.dart';
import '../widgets/character/inline_character_section.dart';
import '../widgets/common/collapsible_image_panel.dart';

class StyleExploreEditorWiring extends ConsumerWidget {
  const StyleExploreEditorWiring({
    super.key,
    required this.parts,
    required this.controller,
    required this.onBatchEvent,
    required this.canGenerate,
  });
  final ExploreEditorParts parts;
  final GenerationControlsController controller;
  final GenerationBatchCallback onBatchEvent;
  final bool Function() canGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(generationParamsNotifierProvider);
    return Column(
      children: [
        const SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [ModelModeCapsule(), QuotaChipsCapsule()],
          ),
        ),
        Expanded(
          child: GenerationParamsMenuHost(
            summaryMinWidth: 352,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PromptInputWidget(
                    prototypeExplore: true,
                    autoGrow: true,
                    allowEvolutionToggle: true,
                    tipSurface: TipSurface.explorePrompt,
                  ),
                  const SizedBox(height: 12),
                  parts.randomVariables,
                  if (ImageModels.isV4Model(params.model)) ...[
                    const SizedBox(height: 12),
                    const InlineCharacterSection(),
                  ],
                  const SizedBox(height: 12),
                  GenerationModuleCard(
                    title: context.l10n.generation_sectionReferenceImages,
                    children: const [
                      ReferenceModuleScope(
                        prototypeExplore: true,
                        child: Column(
                          children: [
                            Img2ImgPanel(),
                            UnifiedReferencePanel(),
                            PreciseReferencePanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GenerationModuleCard(
                    title: context.l10n.generation_moduleImage,
                    children: [
                      SizeSelector(
                        width: params.width,
                        height: params.height,
                        layout: SizeSelectorLayout.explorePrototype,
                        onChanged: (width, height) => ref
                            .read(generationParamsNotifierProvider.notifier)
                            .updateSize(width, height),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        GenerationControls(
          controller: controller,
          compact: true,
          exploreMode: true,
          showBalanceChips: false,
          showAutoSaveChip: false,
          onBatchEvent: onBatchEvent,
          canGenerate: canGenerate,
          presentationBuilder: (context, state) => parts.generateBar,
        ),
      ],
    );
  }
}
