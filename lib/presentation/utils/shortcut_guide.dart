import '../../core/shortcuts/default_shortcuts.dart';
import '../../core/shortcuts/shortcut_config.dart';
import '../../core/utils/desktop_platform.dart';
import '../../l10n/app_localizations.dart';
import '../ui/settings/settings_contract.dart';
import 'shortcut_labels.dart';

/// 设置与 F1 共用的展示清单。固定键由各页面处理，不进入用户的绑定配置。
SettingsShortcutsData shortcutGuide(
  AppLocalizations l,
  ShortcutConfig config, {
  Map<String, int> order = const {},
}) {
  final defaults = ShortcutConfig.createDefault();
  final bindings = config.bindings.values.toList()
    ..sort((a, b) => (order[b.id] ?? 0).compareTo(order[a.id] ?? 0));
  final fixed = _fixedShortcuts(l);

  bool overlaps(ShortcutBinding binding, _FixedShortcut row) =>
      (binding.context.name == row.context ||
          binding.context == ShortcutContext.global &&
              row.context != ShortcutContext.input.name) &&
      _sameShortcut(binding.effectiveShortcut, row.keys);

  return SettingsShortcutsData(
    contexts: [
      for (final scope in ShortcutContext.values)
        SettingsShortcutContext(
          id: scope.name,
          label: settingsShortcutContextLabel(l, scope),
        ),
      SettingsShortcutContext(id: 'inpaint', label: l.tools_inpaint),
    ],
    shortcuts: [
      for (final binding in bindings)
        SettingsShortcut(
          id: binding.id,
          context: binding.context.name,
          label: settingsShortcutLabel(l, binding.actionKey),
          keys: _keys(binding.effectiveShortcut),
          defaultKeys: _keys(defaults.bindings[binding.id]?.effectiveShortcut),
          conflictWith:
              fixed.where((row) => overlaps(binding, row)).firstOrNull?.id ??
              (switch (binding.effectiveShortcut) {
                final keys? when keys.isNotEmpty =>
                  config
                      .findConflicts(
                        keys,
                        context: binding.context,
                        excludeId: binding.id,
                      )
                      .firstOrNull,
                _ => null,
              }),
        ),
      for (final row in fixed)
        SettingsShortcut(
          id: row.id,
          context: row.context,
          label: row.label,
          keys: _keys(row.keys),
          defaultKeys: const [],
          fixed: true,
          conflictWith: bindings.where((b) => overlaps(b, row)).firstOrNull?.id,
        ),
    ],
  );
}

List<String> _keys(String? shortcut) => shortcut == null || shortcut.isEmpty
    ? []
    : shortcut
          .split('+')
          .map((key) => key.trim())
          .where((key) => key.isNotEmpty)
          .toList();

bool _sameShortcut(String? a, String b) {
  if (a == null || a.isEmpty) return false;
  final parsed = ShortcutParser.parse(a);
  return parsed != null &&
      parsed.toActivatorString() ==
          ShortcutParser.parse(b)?.toActivatorString();
}

typedef _FixedShortcut = ({
  String id,
  String context,
  String label,
  String keys,
});

List<_FixedShortcut> _fixedShortcuts(AppLocalizations l) {
  final primary = usesMacOSConventions ? 'Meta' : 'Ctrl';
  final generation = ShortcutContext.generation.name;
  final gallery = ShortcutContext.gallery.name;
  final viewer = ShortcutContext.viewer.name;
  final settings = ShortcutContext.settings.name;
  final input = ShortcutContext.input.name;
  const inpaint = 'inpaint';

  _FixedShortcut row(String id, String scope, String label, String keys) =>
      (id: 'fixed-$id', context: scope, label: label, keys: keys);

  return [
    for (final (scope, undo, redo) in [
      (generation, l.shortcut_fixedUndoPrompt, l.shortcut_fixedRedoPrompt),
      (gallery, l.shortcut_fixedUndoGallery, l.shortcut_fixedRedoGallery),
      (input, l.shortcut_fixedUndoText, l.shortcut_fixedRedoText),
      (inpaint, l.shortcut_fixedUndoMask, l.shortcut_fixedRedoMask),
    ]) ...[
      row('$scope-undo', scope, undo, '$primary+Z'),
      row('$scope-redo', scope, redo, '$primary+Y'),
      row('$scope-redo-shift', scope, redo, '$primary+Shift+Z'),
    ],
    for (final key in ['W', 'A', 'S', 'D'])
      row('canvas-pan-$key', generation, l.shortcut_fixedPanCanvas, key),
    row('canvas-next', generation, l.shortcut_fixedNextBatch, 'Q'),
    row(
      'canvas-previous',
      generation,
      l.shortcut_fixedPreviousBatch,
      'Shift+Q',
    ),
    row('canvas-focus', generation, l.shortcut_fixedFocusCanvas, 'F'),
    row('canvas-first', generation, l.shortcut_fixedFirstBatch, 'Home'),
    row('canvas-last', generation, l.shortcut_fixedLastBatch, 'End'),
    row('canvas-reset', generation, l.shortcut_fixedResetCanvas, '$primary+0'),
    row('canvas-zoom-in', generation, l.shortcut_action_zoom_in, '='),
    row('canvas-zoom-out', generation, l.shortcut_action_zoom_out, '-'),
    row('canvas-actual', generation, l.imageViewer_helpActual, '1'),
    row('gallery-delete', gallery, l.localGallery_moveToDeletePool, 'Delete'),
    row('viewer-undo', viewer, l.imageViewer_helpUndo, '$primary+Z'),
    row('viewer-first', viewer, l.shortcut_fixedFirstImage, 'Home'),
    row('viewer-last', viewer, l.shortcut_fixedLastImage, 'End'),
    row('viewer-actual', viewer, l.imageViewer_helpActual, '1'),
    row('viewer-save', viewer, l.shortcut_action_save_image, '$primary+S'),
    row('viewer-help', viewer, l.imageViewer_helpTitle, 'Shift+slash'),
    row('settings-undo', settings, l.shortcut_fixedUndoSetting, '$primary+Z'),
    row('settings-search', settings, l.set_search, '$primary+F'),
    row('inpaint-apply', inpaint, l.tools_applyMask, '$primary+Enter'),
  ];
}
