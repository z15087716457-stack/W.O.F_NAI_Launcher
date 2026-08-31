import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/focused_selection_state.dart';

void main() {
  group('FocusedSelectionState', () {
    test('captureSelection should store a bounded focused rect', () {
      final state = FocusedSelectionState(canvasSize: const Size(512, 512));

      final consumed = state.captureSelection(
        Path()..addRect(const Rect.fromLTWH(32, 40, 120, 96)),
      );

      expect(consumed, isTrue);
      expect(state.committedRect, const Rect.fromLTWH(32, 40, 120, 96));
    });

    test(
      'resolveActiveRect should prefer preview path over committed rect',
      () {
        final state = FocusedSelectionState(
          canvasSize: const Size(512, 512),
          initialRect: const Rect.fromLTWH(32, 40, 120, 96),
        );

        final activeRect = state.resolveActiveRect(
          previewPath: Path()..addRect(const Rect.fromLTWH(180, 200, 64, 72)),
        );

        expect(activeRect, const Rect.fromLTWH(180, 200, 64, 72));
      },
    );

    test('clear should remove previously committed focused rect', () {
      final state = FocusedSelectionState(
        canvasSize: const Size(512, 512),
        initialRect: const Rect.fromLTWH(32, 40, 120, 96),
      );

      state.clear();

      expect(state.committedRect, isNull);
      expect(state.resolveActiveRect(), isNull);
    });

    test(
      'should suppress generic selection overlay while focused rect selection is active',
      () {
        final state = FocusedSelectionState(canvasSize: const Size(512, 512));

        final suppress = state.shouldSuppressSelectionOverlay(
          focusedEnabled: true,
          currentToolId: 'rect_selection',
          previewPath: Path()..addRect(const Rect.fromLTWH(20, 24, 80, 64)),
        );

        expect(suppress, isTrue);
      },
    );
  });
}
