import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/localization_extension.dart';
import 'explore_controls.dart';
import 'explore_icon.dart';
import 'explore_style.dart';

class ExploreDialogFrame extends StatelessWidget {
  const ExploreDialogFrame({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.footer,
    this.subtitle,
    this.width = 660,
    this.top,
    this.titleIcon,
  });
  final String title, icon;
  final String? subtitle;
  final Widget child, footer;
  final double width;
  final double? top;
  final Widget? titleIcon;
  static ButtonStyle buttonStyle(BuildContext context, {bool primary = false}) {
    final c = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      foregroundColor: c.onSurface,
      backgroundColor: c.surface,
      side: BorderSide(color: c.outlineVariant),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static InputDecoration inputDecoration(BuildContext context, {String? hint}) {
    final c = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      visualDensity: VisualDensity.standard,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: border(c.outlineVariant),
      enabledBorder: border(c.outlineVariant),
      focusedBorder: border(c.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme;
    return Dialog(
      alignment: top == null ? Alignment.center : Alignment.topCenter,
      insetPadding: EdgeInsets.fromLTRB(24, top ?? 24, 24, 24),
      backgroundColor: ExploreStyle.raised(t),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: (MediaQuery.sizeOf(context).height - (top ?? 24) - 24)
              .clamp(0, double.infinity),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 18, 6),
                  child: Row(
                    children: [
                      titleIcon ??
                          ExploreIcon(
                            icon,
                            size: 20,
                            color: icon == 'evo'
                                ? ExploreStyle.evolution(t)
                                : c.onSurface,
                          ),
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
                      ExploreIconButton(
                        'x',
                        size: 18,
                        tooltip: context.l10n.common_close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                if (subtitle case final label?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                    child: child,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: ExploreStyle.panel(t),
                    border: Border(top: BorderSide(color: c.outlineVariant)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: footer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExploreDialogFocusRing extends StatefulWidget {
  const ExploreDialogFocusRing({super.key, required this.child});
  final Widget child;
  @override
  State<ExploreDialogFocusRing> createState() => _ExploreDialogFocusRingState();
}

class _ExploreDialogFocusRingState extends State<ExploreDialogFocusRing> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (value) => setState(() => _focused = value),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .15),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: widget.child,
    ),
  );
}
