import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/settings/studio_settings_backups.dart';
import 'settings_backups.dart';
import 'settings_dialogs.dart';
import 'settings_edits.dart';

import '../../../core/shortcuts/default_shortcuts.dart';
import '../../../core/shortcuts/shortcut_config.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/shortcuts_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../utils/shortcut_labels.dart';

final settingsShortcutOrderProvider = StateProvider<Map<String, int>>(
  (ref) => {},
);

List<String> settingsShortcutKeys(String? shortcut) =>
    shortcut == null || shortcut.isEmpty
    ? []
    : shortcut
          .split('+')
          .map((key) => key.trim())
          .where((key) => key.isNotEmpty)
          .toList();

SettingsShortcutsData settingsShortcutsData(
  BuildContext context,
  WidgetRef ref,
) {
  final config =
      ref.watch(shortcutConfigNotifierProvider).valueOrNull ??
      ShortcutConfig.createDefault();
  final defaults = ShortcutConfig.createDefault();
  final order = ref.watch(settingsShortcutOrderProvider);
  final bindings = config.bindings.values.toList()
    ..sort((a, b) => (order[b.id] ?? 0).compareTo(order[a.id] ?? 0));
  return SettingsShortcutsData(
    contexts: [
      for (final scope in ShortcutContext.values)
        SettingsShortcutContext(
          id: scope.name,
          label: settingsShortcutContextLabel(context.l10n, scope),
        ),
    ],
    shortcuts: [
      for (final binding in bindings)
        SettingsShortcut(
          id: binding.id,
          context: binding.context.name,
          label: settingsShortcutLabel(context.l10n, binding.actionKey),
          keys: settingsShortcutKeys(binding.effectiveShortcut),
          defaultKeys: settingsShortcutKeys(
            defaults.bindings[binding.id]?.effectiveShortcut,
          ),
          conflictWith:
              binding.effectiveShortcut == null ||
                  binding.effectiveShortcut!.isEmpty
              ? null
              : config
                    .findConflicts(
                      binding.effectiveShortcut!,
                      context: binding.context,
                      excludeId: binding.id,
                    )
                    .firstOrNull,
        ),
    ],
  );
}

class SettingsShortcutActions {
  SettingsShortcutActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;
  Future<void> record(String id, List<String> keys) async {
    final config = await ref.read(shortcutConfigNotifierProvider.future);
    if (!context.mounted) return;
    final binding = config.bindings[id];
    if (binding == null) throw ArgumentError.value(id, 'id');
    final normalized = keys.map((key) => key.trim()).toList();
    if (normalized.any((key) => key.isEmpty || key.length > 40) ||
        keys.length > 5) {
      throw const FormatException('Invalid shortcut');
    }
    await ref
        .read(shortcutConfigNotifierProvider.notifier)
        .updateBinding(
          binding.copyWith(customShortcut: normalized.join('+'), enabled: true),
        );
    if (context.mounted) {
      ref.read(settingsShortcutOrderProvider.notifier).state = {
        ...ref.read(settingsShortcutOrderProvider),
        id: DateTime.now().microsecondsSinceEpoch,
      };
    }
  }

  Future<void> clear(String id) => record(id, []);
  Future<void> reset(String id) async {
    await ref.read(shortcutConfigNotifierProvider.future);
    if (!context.mounted) return;
    final binding = ShortcutConfig.createDefault().bindings[id];
    if (binding == null) throw ArgumentError.value(id, 'id');
    await ref
        .read(shortcutConfigNotifierProvider.notifier)
        .updateBinding(binding);
  }

  Future<void> resetAll() =>
      SettingsBackupActions(context, ref).reset({SettingsResetScope.shortcuts});

  Future<void> exportConfig() async {
    await ref.read(shortcutConfigNotifierProvider.future);
    if (!context.mounted) return;
    final raw = await ref
        .read(shortcutConfigNotifierProvider.notifier)
        .exportConfig();
    if (!context.mounted) return;
    final file = await FilePicker.platform.saveFile(
      fileName: 'studio-shortcuts.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file != null) await File(file).writeAsString(raw, flush: true);
  }

  Future<void> importConfig() async {
    final backups = SettingsBackupActions(context, ref);
    final service = await backups.ready();
    final before = service.capture();
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;
    final file = File(path);
    if (await file.length() > 1024 * 1024) {
      throw const FormatException('Shortcut file is too large');
    }
    final raw = await file.readAsString();
    if (!context.mounted) return;
    final parsed = ShortcutConfig.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    ).withCurrentNavigationDefaults().mergedWithDefaults();
    if (!context.mounted ||
        !await settingsConfirm(
          context,
          context.l10n.settings_importPreferences,
          context.l10n.settings_applyPreferencesConfirm(parsed.bindings.length),
        ) ||
        !context.mounted) {
      return;
    }
    await ref.read(settingsEditsProvider.notifier).transaction(() async {
      await service.apply(
        StudioSettingsSnapshot(const {}, parsed),
        expected: before,
      );
      backups.refresh();
    });
  }

  void help() => ref.read(shortcutHelpDialogNotifierProvider.notifier).show();
}
