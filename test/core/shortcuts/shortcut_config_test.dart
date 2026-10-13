import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';

void main() {
  test('navigation defaults follow the new rail order', () {
    final config = ShortcutConfig.createDefault();
    const expected = {
      'navigate_to_generation': 'ctrl+1',
      'navigate_to_style_explore': 'ctrl+2',
      'navigate_to_local_gallery': 'ctrl+3',
      'navigate_to_online_gallery': 'ctrl+4',
      'navigate_to_tag_library': 'ctrl+5',
      'navigate_to_vibe_library': 'ctrl+6',
      'navigate_to_precise_ref_library': 'ctrl+7',
      'navigate_to_tag_wiki': 'ctrl+8',
      'navigate_to_statistics': 'ctrl+9',
      'navigate_to_settings': 'ctrl+comma',
    };
    for (final entry in expected.entries) {
      expect(config.getEffectiveShortcut(entry.key), entry.value);
      expect(config.getBinding(entry.key)?.context, ShortcutContext.global);
    }
  });

  test(
    'new generation navigation defaults use arrows in generation context',
    () {
      final config = ShortcutConfig.createDefault();

      expect(
        config.getEffectiveShortcut(ShortcutIds.generationPrevImage),
        'arrowleft',
      );
      expect(
        config.getEffectiveShortcut(ShortcutIds.generationNextImage),
        'arrowright',
      );
      expect(
        config.getBinding(ShortcutIds.generationPrevImage)?.context,
        ShortcutContext.generation,
      );
    },
  );

  test('mergedWithDefaults only adds missing ids', () {
    const customized = ShortcutBinding(
      id: ShortcutIds.generateImage,
      actionKey: 'shortcut_action_generate_image',
      defaultShortcut: 'ctrl+enter',
      customShortcut: 'alt+g',
      context: ShortcutContext.generation,
      enabled: false,
    );
    final stored = ShortcutConfig(
      bindings: {customized.id: customized},
      enableShortcuts: false,
    );

    final merged = stored.mergedWithDefaults();

    expect(merged.bindings[customized.id], customized);
    expect(merged.bindings, contains(ShortcutIds.generationPrevImage));
    expect(merged.enableShortcuts, isFalse);
  });

  test('conflicts are isolated by context except for global bindings', () {
    const config = ShortcutConfig(
      bindings: {
        'viewer-left': ShortcutBinding(
          id: 'viewer-left',
          actionKey: 'viewer-left',
          defaultShortcut: 'arrowleft',
          context: ShortcutContext.viewer,
        ),
        'generation-left': ShortcutBinding(
          id: 'generation-left',
          actionKey: 'generation-left',
          defaultShortcut: 'arrowleft',
          context: ShortcutContext.generation,
        ),
        'global-left': ShortcutBinding(
          id: 'global-left',
          actionKey: 'global-left',
          defaultShortcut: 'arrowleft',
          context: ShortcutContext.global,
        ),
      },
    );

    expect(
      config.findConflicts(
        'arrowleft',
        context: ShortcutContext.generation,
        excludeId: 'generation-left',
      ),
      ['global-left'],
    );
    expect(
      config.findConflicts(
        'arrowleft',
        context: ShortcutContext.global,
        excludeId: 'global-left',
      ),
      unorderedEquals(['viewer-left', 'generation-left']),
    );
  });
}
