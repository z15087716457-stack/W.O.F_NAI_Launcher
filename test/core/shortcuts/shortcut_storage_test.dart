import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_storage.dart';

void main() {
  ShortcutConfig legacyDefaults() {
    final defaults = ShortcutConfig.createDefault();
    return defaults
        .updateBinding(
          defaults.bindings[ShortcutIds.minimizeToTray]!.copyWith(
            defaultShortcut: 'ctrl+m',
          ),
        )
        .updateBinding(
          defaults.bindings[ShortcutIds.vibeExport]!.copyWith(
            defaultShortcut: 'ctrl+e',
          ),
        );
  }

  test(
    'load upgrades both duplicate defaults once and preserves customization',
    () async {
      final legacy = legacyDefaults()
          .setCustomShortcut(ShortcutIds.generateImage, 'alt+g')
          .setEnabled(ShortcutIds.generateImage, false)
          .setCustomShortcut(ShortcutIds.saveImage, '')
          .copyWith(showInMenus: true);
      String? persisted;
      var writes = 0;
      final storage = ShortcutStorage.forTesting(
        readConfig: () async => persisted ?? jsonEncode(legacy.toJson()),
        writeConfig: (raw) async {
          persisted = raw;
          writes++;
        },
      );
      final loaded = await storage.loadConfig();
      expect(
        loaded.getEffectiveShortcut(ShortcutIds.minimizeToTray),
        'ctrl+shift+m',
      );
      expect(
        loaded.getEffectiveShortcut(ShortcutIds.vibeExport),
        'ctrl+shift+e',
      );
      expect(
        loaded.bindings[ShortcutIds.generateImage],
        legacy.bindings[ShortcutIds.generateImage],
      );
      expect(loaded.getEffectiveShortcut(ShortcutIds.saveImage), '');
      expect(loaded.showInMenus, isTrue);
      for (final binding in loaded.bindings.values.where(
        (b) => b.enabled && b.effectiveShortcut?.isNotEmpty == true,
      )) {
        expect(
          loaded.findConflicts(
            binding.effectiveShortcut!,
            context: binding.context,
            excludeId: binding.id,
          ),
          isEmpty,
          reason: binding.id,
        );
      }
      expect(await storage.loadConfig(), loaded);
      expect(writes, 1);
    },
  );

  test(
    'import also replaces obsolete defaults before returning or persisting',
    () async {
      String? persisted;
      final storage = ShortcutStorage.forTesting(
        readConfig: () async => persisted,
        writeConfig: (raw) async => persisted = raw,
      );
      final imported = await storage.importConfig(
        jsonEncode(legacyDefaults().toJson()),
      );
      expect(imported.bindings, ShortcutConfig.createDefault().bindings);
      expect(await storage.loadConfig(), imported);
      expect(await storage.resetToDefault(), ShortcutConfig.createDefault());
    },
  );

  test('new default keys yield to existing user customizations', () async {
    final legacy = legacyDefaults()
        .setCustomShortcut(ShortcutIds.togglePromptMode, 'ctrl+shift+m')
        .setCustomShortcut(ShortcutIds.vibeDetailExport, 'ctrl+shift+e');
    String? persisted;
    final storage = ShortcutStorage.forTesting(
      readConfig: () async => persisted ?? jsonEncode(legacy.toJson()),
      writeConfig: (raw) async => persisted = raw,
    );
    final loaded = await storage.loadConfig();
    expect(
      loaded.getEffectiveShortcut(ShortcutIds.togglePromptMode),
      'ctrl+shift+m',
    );
    expect(
      loaded.getEffectiveShortcut(ShortcutIds.vibeDetailExport),
      'ctrl+shift+e',
    );
    expect(loaded.getEffectiveShortcut(ShortcutIds.minimizeToTray), isEmpty);
    expect(loaded.getEffectiveShortcut(ShortcutIds.vibeExport), isEmpty);
    expect(await storage.loadConfig(), loaded);
  });

  test(
    'an explicit custom old key remains custom even when equal to the old default',
    () async {
      final legacy = legacyDefaults()
          .setCustomShortcut(ShortcutIds.minimizeToTray, 'ctrl+m')
          .setEnabled(ShortcutIds.minimizeToTray, false)
          .setCustomShortcut(ShortcutIds.vibeExport, '');
      final storage = ShortcutStorage.forTesting(
        readConfig: () async => jsonEncode(legacy.toJson()),
        writeConfig: (_) async {},
      );
      final loaded = await storage.loadConfig();
      expect(
        loaded.bindings[ShortcutIds.minimizeToTray]!.customShortcut,
        'ctrl+m',
      );
      expect(loaded.bindings[ShortcutIds.minimizeToTray]!.enabled, isFalse);
      expect(
        loaded.bindings[ShortcutIds.minimizeToTray]!.defaultShortcut,
        'ctrl+shift+m',
      );
      expect(loaded.getEffectiveShortcut(ShortcutIds.vibeExport), '');
    },
  );

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
      expect(loaded.bindings, contains(ShortcutIds.reuseParams));
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
    expect(loaded.bindings, contains(ShortcutIds.openHistoryPanel));
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
      expect(imported.bindings, contains(ShortcutIds.reuseParams));
      expect(
        ShortcutConfig.fromJson(jsonDecode(persisted!) as Map<String, dynamic>),
        imported,
      );
    },
  );
}
