import 'package:flutter/material.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/prompt/pills/dna_icon.dart';
import 'explore_icon.dart';

/// The prototype's modal shell, shared by evolution and block-save dialogs.
class ExploreDialogFrame extends StatelessWidget {
  const ExploreDialogFrame({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.footer,
    this.subtitle,
    this.width = 660,
  });
  final String title, icon;
  final String? subtitle;
  final Widget child, footer;
  final double width;

  static ButtonStyle buttonStyle(BuildContext context, {bool primary = false}) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: colors.onSurface,
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.outlineVariant),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    );
  }

  static InputDecoration inputDecoration(BuildContext context, {String? hint}) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 12, 6),
                child: Row(
                  children: [
                    if (icon == 'evo')
                      DnaIcon(
                        size: 20,
                        color: DnaIcon.prototypeColor(
                          Theme.of(context).brightness,
                        ),
                      )
                    else
                      ExploreIcon(icon, size: 20, color: colors.onSurface),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.common_close,
                      iconSize: 18,
                      onPressed: () => Navigator.pop(context),
                      icon: ExploreIcon(
                        'x',
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                    child: child,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                padding: const EdgeInsets.all(14),
                child: footer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
