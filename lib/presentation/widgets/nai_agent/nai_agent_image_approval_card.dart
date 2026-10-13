import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/director/director_tool_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/director_tools_notifier.dart';
import '../../providers/generation/cloud_upscale_provider.dart';
import '../../providers/generation/local_upscale_provider.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';

class NaiAgentImageApprovalCard extends ConsumerWidget {
  const NaiAgentImageApprovalCard({super.key, required this.request});
  final AgentImageApproval request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.exists(authNotifierProvider)) ref.watch(authNotifierProvider);
    if (ref.exists(subscriptionNotifierProvider)) {
      ref.watch(subscriptionNotifierProvider);
    }
    if (ref.exists(imageGenerationNotifierProvider)) {
      ref.watch(imageGenerationNotifierProvider);
    }
    if (ref.exists(directorToolsNotifierProvider)) {
      ref.watch(directorToolsNotifierProvider);
    }
    if (ref.exists(cloudUpscaleTaskProvider)) {
      ref.watch(cloudUpscaleTaskProvider);
    }
    if (ref.exists(localUpscaleTaskProvider)) {
      ref.watch(localUpscaleTaskProvider);
    }
    if (ref.exists(imageWorkflowControllerProvider)) {
      ref.watch(imageWorkflowControllerProvider);
    }
    var valid = true;
    try {
      request.check();
    } catch (_) {
      valid = false;
    }
    final l = context.l10n,
        scheme = Theme.of(context).colorScheme,
        q = request.quote;
    final tool = DirectorToolType.values
        .where((t) => t.name == q['tool'])
        .firstOrNull;
    final title = tool?.labelKey(l) ?? l.img2img_novelAiCloudUpscale;
    return Container(
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
                Icons.auto_fix_high_outlined,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (request.sourceBytes case final bytes?) ...[
            SizedBox(
              height: 80,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                cacheWidth: 256,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.broken_image_outlined),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '${q['width']} × ${q['height']}',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            l.naiAgent_generationAccount(q['account_name'].toString()),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            l.naiAgent_generationTotal(q['estimated_anlas'] as int),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l.naiAgent_generationBalance(q['balance_anlas']?.toString() ?? '—'),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          if (q['prompt'] case final String prompt when prompt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              prompt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
          if (q['emotion'] case final String emotion) ...[
            const SizedBox(height: 4),
            Text(emotion, style: const TextStyle(fontSize: 11)),
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
            children: [
              FilledButton.icon(
                key: const Key('agent-image-confirm'),
                onPressed: valid
                    ? () => ref
                          .read(naiAgentImageApprovalsProvider)
                          .decide(request.id, run: true)
                    : null,
                icon: const Icon(Icons.auto_fix_high, size: 14),
                label: Text(l.common_confirm),
              ),
              TextButton(
                key: const Key('agent-image-decline'),
                onPressed: () => ref
                    .read(naiAgentImageApprovalsProvider)
                    .decide(request.id, run: false),
                child: Text(l.common_cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
