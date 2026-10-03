import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/common/studio_icons.dart';
import '../widgets/data_source_cache_settings.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_columns.dart';
import 'generation_settings_section.dart';
import 'privacy_settings_section.dart';

class GenerationPreferencesSection extends StatelessWidget {
  const GenerationPreferencesSection({super.key, required this.onManageModels});

  final VoidCallback onManageModels;

  @override
  Widget build(BuildContext context) => SettingsColumns(
    leftFraction: .44,
    left: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          title: context.l10n.settings_promptInput,
          child: const Column(
            children: [
              GenerationSettingsSection(showHeading: false),
              DataSourceCacheSettings(controlsOnly: true, showHeading: false),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('settings-manage-translation-models'),
            onPressed: onManageModels,
            icon: const Icon(StudioIcons.settingsModels, size: 17),
            label: Text(context.l10n.settings_manageTranslationModelsRules),
          ),
        ),
      ],
    ),
    right: const PrivacySettingsSection(generationOnly: true),
  );
}
