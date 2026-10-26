import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nai_agent/settings_tools.dart';
import '../../../core/settings/settings_preferences_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../data/services/nai_agent/agent_snapshot_files.dart';
import '../../../core/autocomplete/autocomplete_settings.dart' as autocomplete;
import '../theme_provider.dart';
import '../font_provider.dart';
import '../font_scale_provider.dart';
import '../settings_font_scale_provider.dart';
import '../locale_provider.dart';
import '../history_click_behavior_provider.dart';
import '../simple_output_viewer_provider.dart';
import '../simple_viewer_group_batches_provider.dart';
import '../canvas_settings_provider.dart';
import '../notification_settings_provider.dart';
import '../share_image_settings_provider.dart';
import '../generation/generation_settings_notifiers.dart' as generation;

class _WorkspacePreferences extends SettingsPreferencesService {
  _WorkspacePreferences(super.storage, this.workspace);
  final Directory workspace;

  @override
  Future<File> backup(Map<String, Object?> values) async {
    final saved = await AgentSnapshotFiles(workspace).save(
      'Before settings update',
      {'kind': 'public_preferences', 'preferences': values},
      backup: true,
    );
    return File(saved['path'] as String);
  }
}

NaiAgentSettingsTools bindNaiAgentSettings(
  Ref ref,
  Directory workspace,
  bool Function() alive,
) => NaiAgentSettingsTools(
  _WorkspacePreferences(ref.read(localStorageServiceProvider), workspace),
  isAlive: alive,
  refresh: () {
    ref.invalidate(themeNotifierProvider);
    ref.invalidate(fontNotifierProvider);
    ref.invalidate(fontScaleNotifierProvider);
    ref.invalidate(settingsFontScaleProvider);
    ref.invalidate(localeNotifierProvider);
    ref.invalidate(historyClickBehaviorNotifierProvider);
    ref.invalidate(simpleOutputViewerNotifierProvider);
    ref.invalidate(simpleViewerGroupBatchesProvider);
    ref.invalidate(canvasLockCameraNotifierProvider);
    ref.invalidate(canvasReducedMotionNotifierProvider);
    ref.invalidate(canvasZoomToFillNotifierProvider);
    ref.invalidate(notificationSettingsNotifierProvider);
    ref.invalidate(shareImageSettingsProvider);
    ref.invalidate(autocomplete.autocompleteSettingsProvider);
    ref.invalidate(generation.autocompleteSettingsProvider);
    ref.invalidate(generation.promptWeightScrollSettingsProvider);
    ref.invalidate(generation.promptWeightScrollModifierSettingsProvider);
  },
);
