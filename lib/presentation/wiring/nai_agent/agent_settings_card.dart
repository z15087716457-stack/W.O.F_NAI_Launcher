import '../../../core/settings/settings_preferences_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../ui/agent/agent_contract.dart';
import '../../ui/settings/settings_contract.dart';

/// Public preference storage keys, not the Settings UI's translated values.
/// The two null rows are intentionally not navigable.
const agentSettingRows = <String, (SettingKey?, String)>{
  'studio_theme_mode': (SettingKey.themeMode, 'appearance'),
  'font_family': (SettingKey.fontFamily, 'appearance'),
  'font_scale': (null, 'appearance'),
  'settings_font_scale': (SettingKey.settingsFontScale, 'appearance'),
  'workspace_font_scale': (SettingKey.workspaceFontScale, 'appearance'),
  'locale': (SettingKey.language, 'appearance'),
  'history_click_behavior': (SettingKey.historyClick, 'canvas'),
  'simple_output_viewer': (SettingKey.outputViewer, 'canvas'),
  'simple_viewer_group_batches': (
    SettingKey.simpleViewerGroupBatches,
    'canvas',
  ),
  'thumbnail_cache_limit_gb': (SettingKey.thumbnailCacheLimitGb, 'storage'),
  'canvas_lock_camera': (SettingKey.canvasLockCamera, 'canvas'),
  'canvas_reduced_motion': (SettingKey.reduceMotion, 'appearance'),
  'canvas_zoom_to_fill': (SettingKey.canvasZoomToFill, 'canvas'),
  'notification_sound_enabled': (SettingKey.completionSound, 'appearance'),
  'enable_prompt_weight_scroll': (SettingKey.wheelWeight, 'generation'),
  'prompt_weight_scroll_modifier': (SettingKey.wheelModifier, 'generation'),
  'tag_expansion_result_limit': (null, 'generation'),
  'enable_cooccurrence_recommendation': (SettingKey.relatedTags, 'generation'),
  'prompt_autocomplete_enabled': (SettingKey.promptAutocomplete, 'generation'),
  'share_strip_metadata': (SettingKey.stripMetadata, 'privacy'),
  'protection_confirm_dangerous_actions': (
    SettingKey.confirmDangerous,
    'privacy',
  ),
  'protection_warn_external_image_send': (
    SettingKey.confirmExternalSend,
    'privacy',
  ),
  'protection_prevent_overwrite': (SettingKey.noOverwrite, 'privacy'),
  'protection_warn_high_anlas_cost': (SettingKey.costWarning, 'generation'),
  'protection_high_anlas_cost_threshold': (
    SettingKey.costThreshold,
    'generation',
  ),
  'protection_limit_generation_interval': (
    SettingKey.intervalLimit,
    'generation',
  ),
  'protection_generation_interval_seconds': (
    SettingKey.intervalSeconds,
    'generation',
  ),
  'protection_generation_interval_jitter_percent': (
    SettingKey.intervalJitter,
    'generation',
  ),
};

String agentSettingLabel(String storageKey) {
  final l = currentL10n;
  return switch (agentSettingRows[storageKey]?.$1) {
    SettingKey.themeMode => l.set_apTheme,
    SettingKey.fontFamily => l.set_apFont,
    SettingKey.settingsFontScale => l.set_apScale,
    SettingKey.language => l.set_apLanguage,
    SettingKey.historyClick => l.set_cvHistoryClick,
    SettingKey.outputViewer => l.set_cvViewer,
    SettingKey.simpleViewerGroupBatches => l.set_cvGroupBatches,
    SettingKey.thumbnailCacheLimitGb => l.set_stThumbnailCacheLimit,
    SettingKey.canvasLockCamera => l.set_cvLock,
    SettingKey.reduceMotion => l.set_apReduceMotion,
    SettingKey.canvasZoomToFill => l.set_cvFill,
    SettingKey.completionSound => l.set_apSound,
    SettingKey.wheelWeight || SettingKey.wheelModifier => l.set_gnWheel,
    SettingKey.relatedTags => l.set_gnRelated,
    SettingKey.stripMetadata => l.set_pvStrip,
    SettingKey.confirmDangerous => l.set_pvDanger,
    SettingKey.confirmExternalSend => l.set_pvExternal,
    SettingKey.noOverwrite => l.set_pvOverwrite,
    SettingKey.costWarning => l.set_gnWarn,
    SettingKey.costThreshold => l.set_gnThreshold,
    SettingKey.intervalLimit => l.set_gnLimit,
    SettingKey.intervalSeconds => l.set_gnInterval,
    SettingKey.intervalJitter => l.set_gnJitter,
    _ => storageKey,
  };
}

String agentSettingValue(String key, Object? value) {
  final l = currentL10n;
  if (value == null) return l.set_defaultTag;
  if (value is bool) return value ? l.set_on : l.set_off;
  if (key == 'font_scale' ||
      key == 'settings_font_scale' ||
      key == 'workspace_font_scale') {
    return '$value×';
  }
  if (key == 'thumbnail_cache_limit_gb') return '$value GB';
  if (key == 'protection_generation_interval_seconds') return '$value s';
  if (key == 'protection_generation_interval_jitter_percent') return '$value%';
  return switch ((key, value)) {
    ('studio_theme_mode', 'light') => l.set_apLight,
    ('studio_theme_mode', 'dark') => l.set_apDark,
    ('studio_theme_mode', 'system') => l.set_apSystem,
    ('history_click_behavior', 'open_detail') => l.set_cvOpenDetail,
    ('history_click_behavior', 'select_preview') => l.set_cvLinked,
    ('prompt_weight_scroll_modifier', 'none') => l.set_gnNoKey,
    _ => '$value',
  };
}

class AgentSettingsRestore {
  const AgentSettingsRestore(
    this.id,
    this.version,
    this.before,
    this.values,
    this.fields,
  );
  final String id, version;
  final Map<String, Object?> before, values;
  final List<String> fields;

  bool matches(Map<String, Object?> current) =>
      version.isNotEmpty &&
      fields.isNotEmpty &&
      fields.every(
        (k) =>
            SettingsPreferencesService.keys.contains(k) &&
            before.containsKey(k) &&
            values.containsKey(k) &&
            current.containsKey(k) &&
            current[k] == values[k],
      );

  List<AgentSettingChange> get changes => [
    for (final key in fields)
      if (before.containsKey(key) &&
          values.containsKey(key) &&
          before[key] != values[key])
        AgentSettingChange(
          key: key,
          label: agentSettingLabel(key),
          before: agentSettingValue(key, before[key]),
          after: agentSettingValue(key, values[key]),
          anchor: agentSettingRows[key]?.$1 == null
              ? null
              : (
                  section: agentSettingRows[key]!.$2,
                  anchor: agentSettingRows[key]!.$1!.name,
                ),
        ),
  ];
}
