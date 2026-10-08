import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/model_display.dart';
import '../../../core/constants/model_spec.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/image_generation_provider.dart';
import '../../screens/generation/widgets/header_capsules.dart';
import 'library_icon.dart';
import 'library_status_colors.dart';

class LibraryStatusBadge extends StatelessWidget {
  const LibraryStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.typeStyle = false,
  });
  final String label;
  final Color color;
  final String? icon;
  final bool typeStyle;
  @override
  Widget build(BuildContext context) => Container(
    height: 18,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          LibraryIcon(icon!, size: 11, color: color, strokeWidth: 2),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: typeStyle
                  ? Color.lerp(
                      Theme.of(context).colorScheme.onSurface,
                      color,
                      .8,
                    )
                  : color,
            ),
          ),
        ),
      ],
    ),
  );
}

class LibraryModelCapsule extends ConsumerWidget {
  const LibraryModelCapsule({
    super.key,
    this.preciseReference = false,
    this.compact = false,
  });
  final bool preciseReference, compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context),
        params = ref.watch(generationParamsNotifierProvider);
    final available = preciseReference
        ? ModelSpecs.of(params.model).characterReferences
        : ModelSpecs.of(params.model).vibetransfer;
    final status = LibraryStatusColors(theme);
    return GenerationModelMenuButton(
      theme: theme,
      model: params.model,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Text(
                context.l10n.library_currentModel,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              ModelDisplay.shortNameOf(params.model),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            if (compact)
              LibraryIcon(
                available ? 'check' : 'warn',
                size: 11,
                color: available ? status.ok : status.warn,
              )
            else
              LibraryStatusBadge(
                label: available
                    ? context.l10n.library_available
                    : context.l10n.library_unavailable,
                color: available ? status.ok : status.warn,
                icon: available ? 'check' : 'warn',
              ),
          ],
        ),
      ),
    );
  }
}
