import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/theme_provider.dart';
import '../../themes/presets/geist_theme.dart';

/// The same two appearances used by startup, sign-in and all workspace pages.
class StudioThemePicker extends ConsumerWidget {
  const StudioThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeNotifierProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.settings_geistDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final brightness in [Brightness.dark, Brightness.light]) ...[
              if (brightness == Brightness.light) const SizedBox(width: 14),
              Expanded(
                child: _ThemeOption(
                  brightness: brightness,
                  selected: current == brightness,
                  label: brightness == Brightness.dark
                      ? context.l10n.settings_geistDark
                      : context.l10n.settings_geistLight,
                  onTap: () => ref
                      .read(themeNotifierProvider.notifier)
                      .setTheme(brightness),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.brightness,
    required this.selected,
    required this.label,
    required this.onTap,
  });
  final Brightness brightness;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme =
        (brightness == Brightness.dark ? GeistTheme.dark : GeistTheme.light)
            .colorScheme;
    final outer = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        key: ValueKey('studio_theme_${brightness.name}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 112,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? outer.primary : outer.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 15,
                            height: 6,
                            color: GeistTheme.blue,
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 24,
                            height: 3,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            color: scheme.surfaceContainerLow,
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.only(top: 10),
                            child: Icon(
                              Icons.grid_view_rounded,
                              color: scheme.primary,
                              size: 12,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 5,
                                    width: 48,
                                    color: scheme.onSurface,
                                  ),
                                  const SizedBox(height: 7),
                                  Container(
                                    height: 3,
                                    width: 64,
                                    color: scheme.outline,
                                  ),
                                  const Spacer(),
                                  Container(
                                    height: 16,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: GeistTheme.blue,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 16,
                    color: selected ? outer.primary : outer.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
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
