import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/pill_workspace_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../providers/krita/bridge_draft_snapshot.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../providers/style_explore/explore_run_provider.dart';

class NaiAgentGenerationCard extends ConsumerWidget {
  const NaiAgentGenerationCard({super.key, required this.request});
  final AgentGenerationApproval request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Production quote reads already initialize these dependencies. Standalone
    // cards/tests do not start account, storage or generation services.
    if (ref.exists(authNotifierProvider)) ref.watch(authNotifierProvider);
    if (ref.exists(generationParamsNotifierProvider)) {
      ref.watch(generationParamsNotifierProvider);
      ref.watch(bridgeDraftVersionProvider);
    }
    if (ref.exists(imageGenerationNotifierProvider)) {
      ref.watch(imageGenerationNotifierProvider);
    }
    if (ref.exists(pillWorkspaceRevisionProvider)) {
      ref.watch(pillWorkspaceRevisionProvider);
    }
    if (ref.exists(subscriptionNotifierProvider)) {
      ref.watch(subscriptionNotifierProvider);
    }
    if (ref.exists(imageWorkflowControllerProvider)) {
      ref.watch(imageWorkflowControllerProvider);
    }
    if (ref.exists(promptBlockLibraryNotifierProvider)) {
      ref.watch(promptBlockLibraryNotifierProvider);
    }
    if (request.quote.input.sourceOperation == 'explore' &&
        ref.exists(exploreRunListNotifierProvider)) {
      ref.watch(exploreRunListNotifierProvider);
    }
    var valid = true;
    try {
      request.check();
    } catch (_) {
      valid = false;
    }
    final q = request.quote, input = q.input;
    final l = context.l10n, scheme = Theme.of(context).colorScheme;
    final action = switch (input.sourceOperation ?? input.raw.action.name) {
      'variations' => l.img2img_generateVariations,
      'enhance' => l.img2img_enhance,
      'explore' => l.nav_styleExplore,
      'img2img' => l.naiAgent_generationImage,
      'infill' => l.naiAgent_generationInpaint,
      _ => l.naiAgent_generationText,
    };
    return Container(
      key: ValueKey('agent-generation-approval-${request.id}'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.naiAgent_generationTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  action,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (input.sourceOperation != null &&
              input.raw.sourceImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 112,
                child: Image.memory(
                  input.raw.sourceImage!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l.img2img_strength} ${input.raw.strength.toStringAsFixed(2)} · ${l.img2img_noise} ${input.raw.noise.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
          ],
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      '${input.outputSize.width} × ${input.outputSize.height} · ${input.effective.model}',
                ),
                if (input.raw.upscaledEnhance) ...[
                  TextSpan(
                    text:
                        ' · ${l.img2img_enhanceMax.replaceAll('✨', '').trim()}',
                  ),
                  WidgetSpan(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          if (input.sourceOperation != null &&
              input.effective.prompt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              input.effective.prompt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l.naiAgent_generationBatch(
              input.raw.nSamples,
              input.batchSize,
              input.raw.nSamples * input.batchSize,
            ),
            style: const TextStyle(fontSize: 12),
          ),
          if (input.accountName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l.naiAgent_generationAccount(input.accountName),
              style: const TextStyle(fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l.naiAgent_generationTotal(input.estimate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l.naiAgent_generationUnit(
              input.billing['per_request_anlas'] as int,
            ),
            style: const TextStyle(fontSize: 11),
          ),
          if (input.billing['encoding_anlas'] != 0)
            Text(
              l.naiAgent_generationEncoding(
                input.billing['encoding_anlas'] as int,
              ),
              style: const TextStyle(fontSize: 11),
            ),
          const SizedBox(height: 4),
          Text(
            l.naiAgent_generationBalance(input.balance?.toString() ?? '—'),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          if (input.localEnhance case final enhancement?) ...[
            const SizedBox(height: 8),
            Text(
              l.naiAgent_generationLocalEnhance(
                enhancement['model'].toString(),
                enhancement['scale'].toString(),
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            valid
                ? l.naiAgent_generationEstimateNote
                : l.naiAgent_generationChanged,
            style: TextStyle(
              fontSize: 10,
              color: valid ? scheme.onSurfaceVariant : scheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton.icon(
                key: const Key('agent-generation-confirm'),
                onPressed: valid
                    ? () => ref
                          .read(naiAgentGenerationApprovalsProvider)
                          .decide(request.id, generate: true)
                    : null,
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: Text(l.generation_generate),
              ),
              TextButton(
                key: const Key('agent-generation-decline'),
                onPressed: () => ref
                    .read(naiAgentGenerationApprovalsProvider)
                    .decide(request.id, generate: false),
                child: Text(l.common_cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
