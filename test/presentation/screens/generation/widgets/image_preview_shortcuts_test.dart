import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/image_preview.dart';
import 'package:nai_launcher/presentation/widgets/common/numpad_editing_shortcuts.dart';

class _PreviewImageGenerationNotifier extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() =>
      ImageGenerationState(currentImages: [_image('a'), _image('b')]);
}

class _PreviewHistoryBehaviorNotifier extends HistoryClickBehaviorNotifier {
  @override
  HistoryClickBehavior build() => HistoryClickBehavior.selectPreview;

  @override
  Future<void> setBehavior(HistoryClickBehavior behavior) async {
    state = behavior;
  }
}

/// The legacy "previous/next preview" arrow shortcut was removed: on the canvas
/// page it stole Left/Right (and on Windows the NumLock-off numpad 4/6) from
/// focused text fields.
void main() {
  test('generation arrow shortcuts are no longer shipped', () {
    final config = ShortcutConfig.createDefault();
    for (final binding in config.bindings.values) {
      if (binding.context != ShortcutContext.generation) continue;
      expect(
        binding.effectiveShortcut,
        isNot(anyOf('arrowleft', 'arrowright')),
        reason: binding.id,
      );
    }
    expect(DefaultShortcuts.all.keys, isNot(contains('generation_prev_image')));
  });

  test('stored legacy arrow bindings are pruned on load', () {
    final json =
        jsonDecode(jsonEncode(ShortcutConfig.createDefault().toJson()))
            as Map<String, dynamic>;
    (json['bindings'] as Map<String, dynamic>)['generation_prev_image'] = {
      'id': 'generation_prev_image',
      'actionKey': 'shortcut_action_generation_prev_image',
      'defaultShortcut': 'arrowleft',
      'context': 'generation',
      'enabled': true,
    };
    final loaded = ShortcutConfig.fromJson(json);
    expect(loaded.bindings, isNot(contains('generation_prev_image')));
  });

  testWidgets('arrows on the focused preview do not switch images', (
    tester,
  ) async {
    var outerLeft = 0;
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _app(
        container,
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
              outerLeft++;
            },
          },
          child: const PreviewNavShortcuts(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container.read(generationPreviewFocusNodeProvider).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(container.read(generationPreviewSelectionProvider), isNull);
    expect(outerLeft, 1, reason: 'Left bubbles to the outer scope');
  });

  testWidgets('a text field beside the preview keeps arrow and numpad caret '
      'movement on Windows', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => NumpadEditingShortcuts(child: child!),
            home: Scaffold(
              body: Column(
                children: [
                  const Expanded(
                    child: PreviewNavShortcuts(child: SizedBox.expand()),
                  ),
                  TextField(controller: controller),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(controller.selection.baseOffset, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      expect(controller.selection.baseOffset, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad6);
      expect(controller.selection.baseOffset, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(controller.selection.baseOffset, 3);
      expect(container.read(generationPreviewSelectionProvider), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

ProviderContainer _container() => ProviderContainer(
  overrides: [
    imageGenerationNotifierProvider.overrideWith(
      _PreviewImageGenerationNotifier.new,
    ),
    historyClickBehaviorNotifierProvider.overrideWith(
      _PreviewHistoryBehaviorNotifier.new,
    ),
  ],
);

Widget _app(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

GeneratedImage _image(String id) {
  return GeneratedImage(
    id: id,
    bytes: Uint8List.fromList([1, 2, 3]),
    width: 1,
    height: 1,
  );
}
