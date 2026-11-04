#!/bin/bash
# Tests that need a real macOS host, plus desktop paths changed since the upstream release.
# Uses fixtures only; does not start the application or call a live NAI API.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter test --no-pub --concurrency=3 \
  test/presentation/ui/viewer/viewer_key_labels_test.dart \
  test/presentation/widgets/shortcuts/page_focus_test.dart \
  test/presentation/ui/settings/settings_escape_test.dart \
  test/presentation/ui/tools/tools_director_test.dart \
  test/presentation/ui/explore/explore_page_test.dart \
  test/presentation/screens/brand_entry_test.dart \
  test/presentation/screens/local_gallery/local_gallery_screen_layout_test.dart \
  test/core/utils/hive_startup_box_opener_test.dart \
  test/core/utils/hive_storage_migration_test.dart \
  test/core/services/update_installer_service_test.dart \
  test/presentation/providers/auth_switch_transaction_test.dart \
  test/presentation/providers/update_provider_test.dart \
  test/presentation/widgets/common/macos_app_integration_test.dart \
  test/core/network/macos_proxy_address_test.dart \
  test/core/constants/app_version_test.dart \
  test/core/storage/mac_local_credential_routing_test.dart \
  test/presentation/providers/macos_local_credentials_login_test.dart \
  test/presentation/widgets/navigation/macos_native_titlebar_test.dart \
  test/presentation/router/workspace_keyboard_navigation_test.dart \
  test/presentation/ui/gen/gen_header_responsive_test.dart \
  test/presentation/widgets/common/studio_scroll_behavior_test.dart \
  test/presentation/wiring/resource_window_opener_test.dart \
  test/presentation/ui/gen/gen_bulk_selection_test.dart \
  test/presentation/providers/warmup_startup_test.dart \
  test/app_tray_listener_test.dart \
  test/core/services/desktop_app_shutdown_service_test.dart \
  test/presentation/providers/nai_agent/workspace_controller_test.dart \
  test/presentation/providers/nai_agent/app_shutdown_test.dart \
  test/presentation/ui/channel/channel_viewport_test.dart \
  test/app_exit_shortcuts_test.dart \
  test/core/services/mac_legacy_data_import_test.dart \
  test/core/services/mac_legacy_data_sync_test.dart \
  test/core/rag/rag_platform_test.dart \
  test/core/utils/file_sha256_test.dart \
  test/core/utils/studio_sandbox_test.dart \
  test/core/nai_agent/node_runtime_environment_test.dart \
  test/presentation/providers/nai_agent/agent_management_test.dart \
  test/app_test.dart \
  test/presentation/wiring/settings_storage_inventory_test.dart \
  test/presentation/providers/nai_agent/nai_agent_builtin_skills_path_test.dart \
  test/presentation/wiring/generation_data_wiring_test.dart \
  test/presentation/wiring/generation_canvas_wiring_test.dart
