import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../core/utils/localization_extension.dart';

class AnlasCostDialog extends StatelessWidget {
  const AnlasCostDialog({
    super.key,
    required this.cost,
    required this.threshold,
  });
  final int cost;
  final int threshold;

  static Future<bool> show(
    BuildContext context, {
    required int cost,
    required int threshold,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AnlasCostDialog(cost: cost, threshold: threshold),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.toll_outlined, size: 22, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.settings_highAnlasCostTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settings_highAnlasCostEstimate,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$cost Anlas',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.settings_highAnlasCostThresholdLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '$threshold Anlas',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.settings_highAnlasCostQuestion,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.common_cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l.settings_continueGeneration),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
