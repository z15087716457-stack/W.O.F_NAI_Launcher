import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';

void main() {
  test('Japanese locale is generated and available', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('ja')));

    final l10n = lookupAppLocalizations(const Locale('ja'));
    expect(l10n.settings_language, '言語');
    expect(l10n.common_cancel, isNot('Cancel'));
  });

  test('Traditional Chinese (Taiwan) is generated separately from zh', () {
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('zh', 'TW')),
    );

    final traditional = lookupAppLocalizations(const Locale('zh', 'TW'));
    final simplified = lookupAppLocalizations(const Locale('zh'));
    expect(traditional.localeName, 'zh_TW');
    expect(traditional.settings_language, '語言');
    expect(simplified.settings_language, '语言');
  });

  test('selected visible surfaces do not hardcode Chinese strings', () {
    final files = [
      'lib/presentation/widgets/image_editor/widgets/panels/layer_thumbnail_tray.dart',
      'lib/presentation/widgets/image_editor/widgets/panels/editor_quick_settings.dart',
      'lib/presentation/widgets/image_editor/image_editor_session_models.dart',
      'lib/presentation/widgets/image_editor/widgets/toolbar/editor_overlay_toolbar.dart',
      'lib/presentation/wiring/tools_director_wiring.dart',
      'lib/presentation/wiring/tools_editor_wiring.dart',
      'lib/presentation/wiring/tools_generation_wiring.dart',
      'lib/presentation/screens/generation/widgets/image_operation_badge.dart',
      'lib/presentation/screens/generation/widgets/generation_tool_panel.dart',
      'lib/presentation/screens/generation/widgets/generation_sidebar_style.dart',
      'lib/presentation/widgets/common/themed_confirm_dialog.dart',
      'lib/presentation/widgets/common/themed_input.dart',
      'lib/core/services/warmup_task_scheduler.dart',
      'lib/core/enums/warmup_phase.dart',
      'lib/core/network/dio_client.dart',
      'lib/presentation/providers/warmup_provider.dart',
      'lib/presentation/screens/splash/splash_screen.dart',
      'lib/core/shortcuts/default_shortcuts.dart',
      'lib/presentation/widgets/shortcuts/shortcut_help_dialog.dart',
      'lib/presentation/widgets/shortcuts/shortcut_binding_editor.dart',
      'lib/presentation/providers/gallery_category_provider.dart',
      'lib/presentation/providers/vibe_library_category_provider.dart',
      'lib/presentation/providers/local_gallery_provider.dart',
      'lib/presentation/providers/comfyui/comfyui_provider.dart',
      'lib/presentation/providers/bulk_operation_provider.dart',
      'lib/data/models/vibe/vibe_empty_state_info.dart',
      'lib/presentation/wiring/refs_library_wiring.dart',
      'lib/presentation/wiring/refs_generation_target.dart',
      'lib/presentation/wiring/refs_import_session.dart',
      'lib/presentation/wiring/refs_exporter.dart',
      'lib/presentation/wiring/refs_platform.dart',
      'lib/presentation/wiring/refs_drop_reader.dart',
      'lib/presentation/wiring/refs_picker_wiring.dart',
      'lib/presentation/widgets/common/save_vibe_dialog.dart',
      'lib/presentation/widgets/common/save_as_block_dialog.dart',
      'lib/presentation/widgets/common/add_to_library_dialog.dart',
      'lib/presentation/widgets/common/image_detail/components/detail_prompt_section.dart',
      'lib/presentation/wiring/image_viewer_wiring.dart',
      'lib/presentation/wiring/image_viewer_actions.dart',
      'lib/presentation/widgets/gallery/local_gallery_toolbar.dart',
      'lib/presentation/widgets/gallery/local_gallery_filter_bar.dart',
      'lib/presentation/widgets/gallery/gallery_inspector_panel.dart',
      'lib/presentation/widgets/gallery/gallery_floating_bulk_bar.dart',
      'lib/presentation/widgets/gallery/local_image_card.dart',
      'lib/presentation/widgets/gallery/timeline/gallery_timeline_view.dart',
      'lib/presentation/widgets/gallery/timeline/gallery_timeline_scrubber.dart',
      'lib/presentation/widgets/bulk_action_bar.dart',
      'lib/presentation/widgets/generation/auto_save_toggle_chip.dart',
      'lib/presentation/widgets/prompt/comfyui_import_dialog.dart',
      'lib/presentation/wiring/nav_wiring.dart',
      'lib/presentation/widgets/drop/global_drop_handler.dart',
      'lib/presentation/widgets/drop/image_destination_dialog.dart',
      'lib/presentation/wiring/generation_wiring.dart',
      'lib/presentation/wiring/generation_operations.dart',
      'lib/presentation/screens/generation/widgets/history_batch.dart',
      'lib/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart',
      'lib/presentation/screens/generation/widgets/canvas/canvas_display_settings.dart',
      'lib/presentation/screens/generation/widgets/canvas/canvas_image_background.dart',
      'lib/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart',
      'lib/presentation/screens/generation/widgets/canvas/canvas_world_viewport.dart',
      'lib/presentation/screens/generation/widgets/canvas/generated_image_actions.dart',
      'lib/presentation/screens/generation/widgets/canvas/generated_image_card.dart',
      'lib/presentation/screens/generation/handlers/vibe_import_handler.dart',
      'lib/presentation/widgets/gallery/gallery_scan_progress_panel.dart',
      'lib/presentation/widgets/common/animated_favorite_button.dart',
      'lib/presentation/widgets/anlas/anlas_balance_chip.dart',
      'lib/presentation/widgets/character/add_to_library_dialog.dart',
      'lib/presentation/widgets/drop/prompt_block_drop_menu.dart',
      'lib/presentation/screens/generation/widgets/generation_param_sections.dart',
      'lib/presentation/widgets/online_gallery/video_player_widget.dart',
      'lib/presentation/screens/generation/widgets/vibe_transfer_content.dart',
      'lib/presentation/widgets/common/image_picker_card/_internal/loading_overlay.dart',
      'lib/presentation/widgets/common/image_picker_card/_internal/picker_handler.dart',
      'lib/presentation/widgets/common/image_picker_card/image_picker_card.dart',
      'lib/presentation/utils/metadata_import_coordinator.dart',
    ];

    final violations = <String>[];
    final chinese = RegExp(r'[\u4e00-\u9fff]');
    final stringLiteral = RegExp(
      r'''(["'])(?:(?!\1).)*[\u4e00-\u9fff](?:(?!\1).)*\1''',
    );

    for (final path in files) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path should exist');

      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') ||
            trimmed.startsWith('*') ||
            trimmed.startsWith('/*')) {
          continue;
        }
        if (_isLoggingLine(lines, index)) {
          continue;
        }

        if (!chinese.hasMatch(line) || !stringLiteral.hasMatch(line)) {
          continue;
        }

        if (_isAllowedCompatibilityLine(path, line)) {
          continue;
        }

        violations.add('${file.path}:${index + 1}: ${line.trim()}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Move visible Chinese text into ARB/l10n keys or explicit legacy compatibility maps.',
    );
  });
}

bool _isLoggingLine(List<String> lines, int index) {
  final line = lines[index];
  if (line.contains('AppLogger.') || line.contains('debugPrint(')) {
    return true;
  }

  final lookbehindStart = index - 4 < 0 ? 0 : index - 4;
  for (var i = index - 1; i >= lookbehindStart; i -= 1) {
    final previous = lines[i];
    if (previous.contains('AppLogger.') || previous.contains('debugPrint(')) {
      return true;
    }
    if (previous.trimRight().endsWith(';')) {
      break;
    }
  }

  return false;
}

bool _isAllowedCompatibilityLine(String path, String line) {
  if (path.endsWith('splash_screen.dart')) {
    return line.contains('contains(') || line.contains('RegExp(');
  }

  return false;
}
