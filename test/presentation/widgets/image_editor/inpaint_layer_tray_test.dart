import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/inpaint_controls.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/layer_thumbnail_tray.dart';

Widget app(EditorState state, {VoidCallback? on3d}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: EditorLayerTray(state: state, inpaint: true, onAdd3dLayer: on3d),
    ),
  ),
);
EditorState create() {
  final state = EditorState(inpaint: true)..setCanvasSize(const Size(256, 384));
  final source = state.layerManager.addLayer(name: 'source')..locked = true;
  state.inpaintSourceLayerId = source.id;
  state.layerManager.addLayer(name: 'mask').inpaintMask = true;
  return state;
}

void main() {
  testWidgets(
    'official tray uses proportional 80px thumbnails and small controls without eye/lock clutter',
    (tester) async {
      final state = create();
      var calls = 0;
      await tester.pumpWidget(app(state, on3d: () => calls++));
      await tester.tap(find.byKey(const Key('inpaint_layers')));
      await tester.pump();
      final mask = state.layerManager.layers.last,
          source = state.layerManager.layers.first;
      final frame = find.byKey(const Key('inpaint_layer_panel'));
      expect(tester.getSize(frame), const Size(94, 242));
      expect(
        tester
            .getSize(find.byKey(Key('inpaint_layer_thumb_${mask.id}')))
            .height,
        80,
      );
      expect(
        tester.getSize(find.byKey(Key('inpaint_layer_thumb_${mask.id}'))).width,
        closeTo(80 * 2 / 3, .001),
      );
      expect(
        tester.getSize(find.byKey(const Key('inpaint_add_layer'))),
        const Size(24, 24),
      );
      expect(
        tester.getSize(find.byKey(const Key('inpaint_add_3d'))),
        const Size(28, 28),
      );
      expect(
        tester.getSize(find.byKey(Key('inpaint_layer_up_${mask.id}'))),
        const Size(20, 20),
      );
      expect(
        tester.getRect(find.byKey(const Key('inpaint_layers'))).right,
        tester.getRect(frame).right,
      );
      expect(
        tester.getRect(find.byKey(Key('inpaint_layer_thumb_${mask.id}'))).top,
        lessThan(
          tester
              .getRect(find.byKey(Key('inpaint_layer_thumb_${source.id}')))
              .top,
        ),
      );
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byKey(Key('inpaint_layer_type_${mask.id}')), findsOneWidget);
      expect(find.byKey(Key('inpaint_layer_type_${source.id}')), findsNothing);
      await tester.tap(find.byKey(const Key('inpaint_add_3d')));
      expect(calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
  testWidgets(
    'mask bitmap delete, undo, add and reorder preserve identity and source protection',
    (tester) async {
      final state = create();
      final mask = state.layerManager.layers.last,
          source = state.layerManager.layers.first;
      final image = img.Image(width: 256, height: 384, numChannels: 4);
      img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
      final bytes = Uint8List.fromList(img.encodePng(image));
      await tester.runAsync(() => mask.setBaseImage(bytes));
      await tester.pumpWidget(app(state));
      await tester.tap(find.byKey(const Key('inpaint_layers')));
      await tester.pump();
      final sourceDelete = tester.widget<InpaintButton>(
        find.byKey(Key('inpaint_layer_delete_${source.id}')),
      );
      expect(sourceDelete.onPressed, isNull);
      await tester.tap(find.byKey(Key('inpaint_layer_delete_${mask.id}')));
      await tester.pump();
      expect(state.layerManager.layerCount, 1);
      expect(state.layerManager.getLayerById(source.id), isNotNull);
      state.undo();
      await tester.pump();
      final restored = state.layerManager.getLayerById(mask.id)!;
      expect(restored.inpaintMask, isTrue);
      expect(restored.hasBaseImage, isTrue);
      expect(restored.baseImageBytes, bytes);
      expect(state.layerManager.activeLayerId, mask.id);
      await tester.tap(find.byKey(Key('inpaint_layer_down_${mask.id}')));
      await tester.pump();
      expect(state.layerManager.layers.first.id, mask.id);
      state.undo();
      await tester.pump();
      expect(state.layerManager.layers.last.id, mask.id);
      await tester.tap(find.byKey(const Key('inpaint_add_layer')));
      await tester.pump();
      expect(state.layerManager.layerCount, 3);
      expect(state.layerManager.layers.last.inpaintMask, isTrue);
      state.undo();
      await tester.pump();
      expect(state.layerManager.layerCount, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );
  testWidgets('resizing refreshes thumbnail geometry and cached aspect', (
    tester,
  ) async {
    final state = create();
    final mask = state.layerManager.layers.last;
    await tester.pumpWidget(app(state));
    await tester.tap(find.byKey(const Key('inpaint_layers')));
    await tester.pump();
    for (var i = 0; i < 40 && mask.thumbnail == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect((mask.thumbnail!.width, mask.thumbnail!.height), (43, 64));
    state.setCanvasSize(const Size(384, 256));
    await tester.pump(const Duration(milliseconds: 600));
    for (var i = 0; i < 40 && mask.thumbnail!.width != 64; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect((mask.thumbnail!.width, mask.thumbnail!.height), (64, 43));
    expect(
      tester.getSize(find.byKey(Key('inpaint_layer_thumb_${mask.id}'))).width,
      80,
    );
    expect(
      tester.getSize(find.byKey(Key('inpaint_layer_thumb_${mask.id}'))).height,
      closeTo(80 * 2 / 3, .001),
    );
    for (final extreme in [const Size(64, 4096), const Size(4096, 64)]) {
      state.setCanvasSize(extreme);
      await tester.pump();
      final size = tester.getSize(
        find.byKey(Key('inpaint_layer_thumb_${mask.id}')),
      );
      expect(
        size.width / size.height,
        closeTo(extreme.width / extreme.height, .001),
      );
      expect(tester.takeException(), isNull);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
