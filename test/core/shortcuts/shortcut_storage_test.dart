import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_storage.dart';

void main() {
  const customized = ShortcutBinding(
    id: ShortcutIds.generateImage,
    actionKey: 'shortcut_action_generate_image',
    defaultShortcut: 'ctrl+enter',
    customShortcut: 'alt+g',
    context: ShortcutContext.generation,
    enabled: false,
  );

  ShortcutConfig legacyConfig() => const ShortcutConfig(
    bindings: {ShortcutIds.generateImage: customized},
    enableShortcuts: false,
  );

  test(
    'navigation migration updates defaults but preserves custom bindings',
    () async {
      const legacy = ShortcutConfig(
        bindings: {
          ShortcutIds.navigateToLocalGallery: ShortcutBinding(
            id: ShortcutIds.navigateToLocalGallery,
            actionKey: 'shortcut_action_navigate_to_local_gallery',
            defaultShortcut: 'ctrl+2',
          ),
          ShortcutIds.navigateToStatistics: ShortcutBinding(
            id: ShortcutIds.navigateToStatistics,
            actionKey: 'shortcut_action_navigate_to_statistics',
            defaultShortcut: 'ctrl+6',
            customShortcut: 'alt+s',
            enabled: false,
          ),
        },
      );
      String? persisted;
      final storage = ShortcutStorage.forTesting(
        readConfig: () async => persisted ?? jsonEncode(legacy.toJson()),
        writeConfig: (value) async => persisted = value,
      );
      final loaded = await storage.loadConfig();
      expect(
        loaded.getEffectiveShortcut(ShortcutIds.navigateToLocalGallery),
        'ctrl+3',
      );
      final statistics = loaded.getBinding(ShortcutIds.navigateToStatistics)!;
      expect(statistics.customShortcut, 'alt+s');
      expect(statistics.enabled, isFalse);
      expect(statistics.defaultShortcut, 'ctrl+9');
      expect(await storage.loadConfig(), loaded);
      expect(
        loaded
            .resetToDefault(ShortcutIds.navigateToStatistics)
            .setEnabled(ShortcutIds.navigateToStatistics, true)
            .getEffectiveShortcut(ShortcutIds.navigateToStatistics),
        'ctrl+9',
      );
    },
  );

  test('new navigation defaults do not claim a customized binding', () async {
    const legacy = ShortcutConfig(
      bindings: {
        ShortcutIds.navigateToLocalGallery: ShortcutBinding(
          id: ShortcutIds.navigateToLocalGallery,
          actionKey: 'shortcut_action_navigate_to_local_gallery',
          defaultShortcut: 'ctrl+2',
          customShortcut: 'control + 2',
        ),
        ShortcutIds.generateImage: ShortcutBinding(
          id: ShortcutIds.generateImage,
          actionKey: 'shortcut_action_generate_image',
          defaultShortcut: 'ctrl+enter',
          customShortcut: 'ctrl+7',
          context: ShortcutContext.generation,
        ),
      },
    );
    String? persisted;
    final storage = ShortcutStorage.forTesting(
      readConfig: () async => persisted ?? jsonEncode(legacy.toJson()),
      writeConfig: (value) async => persisted = value,
    );
    final loaded = await storage.loadConfig();
    expect(
      loaded.getEffectiveShortcut(ShortcutIds.navigateToLocalGallery),
      'control + 2',
    );
    expect(
      loaded.getEffectiveShortcut('navigate_to_style_explore'),
      anyOf(isNull, isEmpty),
    );
    expect(
      loaded.getEffectiveShortcut('navigate_to_precise_ref_library'),
      anyOf(isNull, isEmpty),
    );
    expect(await storage.loadConfig(), loaded);
    expect(
      loaded
          .resetToDefault('navigate_to_style_explore')
          .getEffectiveShortcut('navigate_to_style_explore'),
      'ctrl+2',
    );
  });

  test(
    'load merges missing defaults and persists without replacing custom data',
    () async {
      String? persisted;
      final storage = ShortcutStorage.forTesting(
        readConfig: () async => jsonEncode(legacyConfig().toJson()),
        writeConfig: (value) async => persisted = value,
      );

      final loaded = await storage.loadConfig();

      expect(loaded.bindings[ShortcutIds.generateImage], customized);
      expect(loaded.enableShortcuts, isFalse);
      expect(loaded.bindings, contains(ShortcutIds.generationPrevImage));
      expect(persisted, isNotNull);
      expect(
        ShortcutConfig.fromJson(jsonDecode(persisted!) as Map<String, dynamic>),
        loaded,
      );
    },
  );

  test('load returns merged config when persisting the merge fails', () async {
    final storage = ShortcutStorage.forTesting(
      readConfig: () async => jsonEncode(legacyConfig().toJson()),
      writeConfig: (_) async => throw const FileSystemException('read only'),
    );

    final loaded = await storage.loadConfig();

    expect(loaded.bindings[ShortcutIds.generateImage], customized);
    expect(loaded.bindings, contains(ShortcutIds.generationNextImage));
    expect(loaded.enableShortcuts, isFalse);
  });

  test(
    'import merges defaults before persisting and returning config',
    () async {
      String? persisted;
      final storage = ShortcutStorage.forTesting(
        readConfig: () async => null,
        writeConfig: (value) async => persisted = value,
      );

      final imported = await storage.importConfig(
        jsonEncode(legacyConfig().toJson()),
      );

      expect(imported.bindings[ShortcutIds.generateImage], customized);
      expect(imported.bindings, contains(ShortcutIds.generationPrevImage));
      expect(
        ShortcutConfig.fromJson(jsonDecode(persisted!) as Map<String, dynamic>),
        imported,
      );
    },
  );
}
