import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/font_provider.dart';
import '../../../themes/studio_typography.dart';
import 'settings_dialog.dart';

class SettingsFontDialog extends ConsumerStatefulWidget {
  const SettingsFontDialog({super.key, required this.current});
  final FontConfig current;
  @override
  ConsumerState<SettingsFontDialog> createState() => _SettingsFontDialogState();
}

class _SettingsFontDialogState extends ConsumerState<SettingsFontDialog> {
  late FontConfig selected = widget.current;
  String query = '';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return SettingsDialogFrame(
      title: context.l10n.settings_selectFont,
      width: 540,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.common_cancel),
        ),
        FilledButton(
          key: const Key('settings-font-apply'),
          onPressed: () => Navigator.pop(context, selected),
          child: Text(context.l10n.common_confirm),
        ),
      ],
      child: SizedBox(
        height: math.min(560, MediaQuery.sizeOf(context).height * .66),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('settings-font-search'),
              onChanged: (value) =>
                  setState(() => query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: context.l10n.settings_searchFonts,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ref
                  .watch(allFontsProvider)
                  .when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => Center(
                      child: Text(context.l10n.settings_couldNotLoadFonts),
                    ),
                    data: (groups) => ListView(
                      children: [
                        for (final group in groups.entries)
                          if (group.value.any(
                            (font) => '${font.displayName} ${font.fontFamily}'
                                .toLowerCase()
                                .contains(query),
                          )) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                              child: Text(
                                switch (group.key) {
                                  '应用默认' => context.l10n.settings_recommended,
                                  '内置字体' => context.l10n.settings_included,
                                  '系统字体' => context.l10n.settings_systemFonts,
                                  _ => group.key,
                                },
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            for (final font in group.value.where(
                              (font) => '${font.displayName} ${font.fontFamily}'
                                  .toLowerCase()
                                  .contains(query),
                            ))
                              SettingsChoiceRow(
                                label: font.displayName,
                                selected: selected == font,
                                onTap: () => setState(() => selected = font),
                              ),
                          ],
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              key: const Key('settings-font-preview'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: .035),
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settings_fontPreview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '让创作更从容。\nA little room for imagination. 0123456789',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: selected.source == FontSource.google
                          ? null
                          : selected.fontFamily,
                      fontFamilyFallback: StudioTypography.fallback,
                      height: 1.65,
                    ),
                  ),
                  if (selected.source == FontSource.google) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.settings_onlineFontsLoadAfterApplying,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
