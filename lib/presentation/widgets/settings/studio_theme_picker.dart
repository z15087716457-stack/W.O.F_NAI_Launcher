import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/theme_provider.dart';
import '../../themes/presets/geist_theme.dart';

/// The same two appearances used by startup, sign-in and all workspace pages.
class StudioThemePicker extends ConsumerWidget {
  const StudioThemePicker({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeNotifierProvider);
    if (compact) {
      Widget option(Brightness brightness) => _CompactThemeOption(
        brightness: brightness,
        selected: current == brightness,
        label: brightness == Brightness.dark
            ? context.l10n.settings_geistDark
            : context.l10n.settings_geistLight,
        onTap: () =>
            ref.read(themeNotifierProvider.notifier).setTheme(brightness),
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final light = option(Brightness.light);
          final dark = option(Brightness.dark);
          if (constraints.maxWidth < 460 * scale) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [light, const SizedBox(height: 10), dark],
            );
          }
          return Row(
            children: [
              Expanded(child: light),
              const SizedBox(width: 12),
              Expanded(child: dark),
            ],
          );
        },
      );
    }
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

class _CompactThemeOption extends StatelessWidget {
  const _CompactThemeOption({
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = brightness == Brightness.dark
        ? GeistTheme.dark.colorScheme
        : GeistTheme.light.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('studio_theme_${brightness.name}'),
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 72 * scale,
                  height: 50 * scale,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: preview.surface,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: preview.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(width: 9, color: preview.surfaceContainerHigh),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 4,
                              color: preview.onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            Container(height: 3, color: preview.outline),
                            const SizedBox(height: 4),
                            FractionallySizedBox(
                              widthFactor: .65,
                              child: Container(
                                height: 3,
                                color: preview.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(label, style: theme.textTheme.bodyMedium),
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
