import 'package:flutter/material.dart';

/// Compact, contained switch. Hover and focus stay inside the track.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      toggled: value,
      enabled: enabled,
      onTap: enabled ? () => onChanged!(!value) : null,
      child: Opacity(
        opacity: enabled ? 1 : .4,
        child: Material(
          color: value
              ? colors.primary
              : colors.onSurface.withValues(alpha: .20),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: enabled ? () => onChanged!(!value) : null,
            borderRadius: BorderRadius.circular(20),
            splashFactory: NoSplash.splashFactory,
            hoverColor: colors.onSurface.withValues(alpha: .055),
            focusColor: colors.onSurface.withValues(alpha: .10),
            child: SizedBox(
              width: 42,
              height: 24,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AnimatedAlign(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
