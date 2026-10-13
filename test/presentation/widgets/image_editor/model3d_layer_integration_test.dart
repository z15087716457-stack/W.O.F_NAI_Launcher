import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/layer_thumbnail_tray.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_bridge.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_library_service.dart';

Uint8List pixels({bool model = false}) {
  final image = img.Image(width: 64, height: 96, numChannels: 4);
  if (!model) img.fill(image, color: img.ColorRgba8(225, 214, 186, 255));
  if (model) {
    img.fillRect(
      image,
      x1: 24,
      y1: 32,
      x2: 40,
      y2: 64,
      color: img.ColorRgba8(40, 100, 180, 255),
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

class Observer extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
}

class FakeScene {
  late final Model3dBridge bridge;
  final commands = <Map<String, dynamic>>[];
  int revision = 0;
  bool failRender = false;
  FakeScene() {
    bridge = Model3dBridge(
      evalJs: (source) async {
        final encoded = RegExp(
          r'dispatch\((.+)\)$',
        ).firstMatch(source)!.group(1)!;
        final command = Map<String, dynamic>.from(
          jsonDecode(jsonDecode(encoded) as String),
        );
        commands.add(command);
        if (command['type'] == 'restoreScene') {
          revision = (command['sceneState'] as Map)['revision'] as int? ?? 0;
        }
        final response = switch (command['type']) {
          'serialize' => {
            'sceneState': {'version': 1, 'revision': revision},
          },
          'render' => {'png': base64Encode(pixels(model: true))},
          _ => <String, dynamic>{},
        };
        bridge.handleJsMessage([
          {
            'type': 'response',
            'requestId': command['requestId'],
            'ok': !(command['type'] == 'render' && failRender),
            'data': command['type'] == 'render' && failRender
                ? {'error': 'synthetic_render_failure'}
                : response,
          },
        ]);
      },
    );
  }
  void change() {
    revision++;
    bridge.handleJsMessage([
      {'type': 'onDirty'},
    ]);
  }
}

Future<void> drain(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 70));
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<(EditorState, Observer, List<FakeScene>, Future<ImageEditorResult?>)>
  open(
    WidgetTester tester, {
    ImageEditorMode mode = ImageEditorMode.edit,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final observer = Observer();
    final scenes = <FakeScene>[];
    late Future<ImageEditorResult?> result;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorObservers: [observer],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                result = Navigator.push<ImageEditorResult>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageEditorScreen(
                      key: key,
                      initialImage: pixels(),
                      mode: mode,
                      debugDisableDropRegion: true,
                      debugModel3dBridgeFactory: () {
                        final scene = FakeScene();
                        scenes.add(scene);
                        return scene.bridge;
                      },
                      debugModel3dViewport: (_) => const SizedBox.expand(
                        key: ValueKey('integrated-viewport'),
                      ),
                      debugModel3dLibrary: Model3dLibraryService(
                        libraryDir: Directory.systemTemp,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await drain(tester);
    final dynamic state = key.currentState;
    return (state.debugEditorState as EditorState, observer, scenes, result);
  }

  testWidgets(
    '3D stays in the image editor, keeps tray and fills both empty sidebars',
    (tester) async {
      final (state, observer, scenes, _) = await open(tester);
      final count = state.layerManager.layerCount;
      final routeCount = observer.pushes;
      await tester.tap(
        find.byKey(
          find.byKey(const Key('tools-layer-add3d')).evaluate().isNotEmpty
              ? const Key('tools-layer-add3d')
              : const Key('inpaint_add_3d'),
        ),
      );
      await drain(tester);
      expect(observer.pushes, routeCount);
      expect(find.byType(ImageEditorScreen), findsOneWidget);
      expect(find.byType(Model3dEditorScreen), findsOneWidget);
      expect(find.byType(EditorLayerTray), findsOneWidget);
      expect(state.layerManager.layerCount, count + 1);
      expect(state.layerManager.activeLayer!.hasModel3d, true);
      await tester.tap(find.byTooltip('Bone List'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Morph Targets'));
      await tester.pumpAndSettle();
      for (final title in ['Bone List', 'Morph Targets']) {
        final rect = tester.getRect(
          find.byKey(ValueKey('model3d-panel-$title')),
        );
        expect(rect.left, 10);
        expect(rect.width, 200);
      }
      final context = scenes.single.commands.lastWhere(
        (m) => m['type'] == 'setContextLayers',
      );
      final below = img.decodePng(base64Decode(context['below'] as String))!;
      final above = img.decodePng(base64Decode(context['above'] as String))!;
      expect(below.getPixel(0, 0).r, 225);
      expect(above.getPixel(0, 0).a, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'single-clicking layers commits current scene and reopens it without pushing a route',
    (tester) async {
      final (state, observer, scenes, _) = await open(tester);
      final base = state.layerManager.activeLayer!;
      await tester.tap(
        find.byKey(
          find.byKey(const Key('tools-layer-add3d')).evaluate().isNotEmpty
              ? const Key('tools-layer-add3d')
              : const Key('inpaint_add_3d'),
        ),
      );
      await drain(tester);
      final model = state.layerManager.activeLayer!;
      scenes.single.change();
      await tester.pump();
      await tester.tap(
        find.byKey(
          Key(
            find.byKey(Key('tools-layer-${base.id}')).evaluate().isNotEmpty
                ? 'tools-layer-${base.id}'
                : 'inpaint_layer_thumb_${base.id}',
          ),
        ),
      );
      await drain(tester);
      expect(state.layerManager.activeLayerId, base.id);
      expect(find.byType(Model3dEditorScreen), findsNothing);
      expect(model.model3d!.sceneState['revision'], 1);
      expect(model.hasBaseImage, true);
      expect(observer.pushes, 2);
      await tester.tap(
        find.byKey(
          Key(
            find.byKey(Key('tools-layer-${model.id}')).evaluate().isNotEmpty
                ? 'tools-layer-${model.id}'
                : 'inpaint_layer_thumb_${model.id}',
          ),
        ),
      );
      await drain(tester);
      expect(find.byType(Model3dEditorScreen), findsOneWidget);
      final restore = scenes.last.commands.singleWhere(
        (m) => m['type'] == 'restoreScene',
      );
      expect((restore['sceneState'] as Map)['revision'], 1);
      scenes.last.change();
      await tester.pump();
      await tester.tap(
        find.byKey(
          Key(
            find.byKey(Key('tools-layer-${base.id}')).evaluate().isNotEmpty
                ? 'tools-layer-${base.id}'
                : 'inpaint_layer_thumb_${base.id}',
          ),
        ),
      );
      await drain(tester);
      expect(model.model3d!.sceneState['revision'], 2);
      expect(observer.pushes, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'save closes the whole image editor and exports the base plus model pixels',
    (tester) async {
      final (_, observer, scenes, result) = await open(tester);
      await tester.tap(
        find.byKey(
          find.byKey(const Key('tools-layer-add3d')).evaluate().isNotEmpty
              ? const Key('tools-layer-add3d')
              : const Key('inpaint_add_3d'),
        ),
      );
      await drain(tester);
      scenes.single.change();
      await tester.pump();
      await tester.tap(find.text('Save and Exit'));
      await drain(tester);
      final saved = await result;
      expect(saved!.hasImageChanges, true);
      final output = img.decodePng(saved.modifiedImage!)!;
      expect(output.width, 64);
      expect(output.height, 96);
      expect(output.getPixel(0, 0).r, 225);
      expect(output.getPixel(32, 48).b, 180);
      expect(find.byType(ImageEditorScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(
        observer.pushes,
        3,
      ); // image editor plus its existing export progress dialog
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('3D reorder and delete preserve scene, pixels and canvas undo', (
    tester,
  ) async {
    final (state, observer, scenes, _) = await open(tester);
    final base = state.layerManager.activeLayer!;
    await tester.tap(
      find.byKey(
        find.byKey(const Key('tools-layer-add3d')).evaluate().isNotEmpty
            ? const Key('tools-layer-add3d')
            : const Key('inpaint_add_3d'),
      ),
    );
    await drain(tester);
    final first = state.layerManager.activeLayer!;
    scenes.last.change();
    await tester.pump();
    await tester.tap(
      find.byKey(
        find.byKey(const Key('tools-layer-add3d')).evaluate().isNotEmpty
            ? const Key('tools-layer-add3d')
            : const Key('inpaint_add_3d'),
      ),
    );
    await drain(tester);
    final second = state.layerManager.activeLayer!;
    expect(first.model3d!.sceneState['revision'], 1);
    scenes.last.change();
    scenes.last.change();
    await tester.pump();
    await tester.tap(find.byKey(Key('inpaint_layer_down_${second.id}')));
    await drain(tester);
    expect(state.layerManager.layers.map((l) => l.id), [
      base.id,
      second.id,
      first.id,
    ]);
    final context = scenes.last.commands.lastWhere(
      (m) => m['type'] == 'setContextLayers',
    );
    final below = img.decodePng(base64Decode(context['below'] as String))!;
    final above = img.decodePng(base64Decode(context['above'] as String))!;
    expect(below.getPixel(0, 0).r, 225);
    expect(above.getPixel(32, 48).b, 180);
    expect(above.getPixel(0, 0).a, 0);
    await tester.tap(find.byTooltip('Undo'));
    await drain(tester);
    expect(state.layerManager.layers.map((l) => l.id), [
      base.id,
      first.id,
      second.id,
    ]);
    expect(scenes.last.revision, 2);
    await tester.tap(find.byKey(Key('inpaint_layer_delete_${second.id}')));
    await drain(tester);
    expect(state.layerManager.getLayerById(second.id), isNull);
    expect(state.layerManager.activeLayerId, first.id);
    await tester.tap(find.byTooltip('Undo'));
    await drain(tester);
    final restored = state.layerManager.getLayerById(second.id)!;
    expect(state.layerManager.activeLayerId, restored.id);
    expect(restored.model3d!.sceneState['revision'], 2);
    expect(img.decodePng(restored.baseImageBytes!)!.getPixel(32, 48).b, 180);
    expect(scenes.last.revision, 2);
    await tester.tap(find.byTooltip('Redo'));
    await drain(tester);
    expect(state.layerManager.getLayerById(second.id), isNull);
    expect(observer.pushes, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'a failed 3D render keeps the active layer and uncommitted scene',
    (tester) async {
      final (state, observer, scenes, _) = await open(tester);
      final base = state.layerManager.activeLayer!;
      await tester.tap(
        find.byKey(
          find.byKey(const Key('tools-layer-add3d')).evaluate().isNotEmpty
              ? const Key('tools-layer-add3d')
              : const Key('inpaint_add_3d'),
        ),
      );
      await drain(tester);
      final model = state.layerManager.activeLayer!;
      scenes.last.change();
      scenes.last.failRender = true;
      await tester.pump();
      await tester.tap(
        find.byKey(
          Key(
            find.byKey(Key('tools-layer-${base.id}')).evaluate().isNotEmpty
                ? 'tools-layer-${base.id}'
                : 'inpaint_layer_thumb_${base.id}',
          ),
        ),
      );
      await drain(tester);
      expect(state.layerManager.activeLayerId, model.id);
      expect(model.hasBaseImage, false);
      expect(model.model3d!.sceneState, isEmpty);
      expect(find.byType(Model3dEditorScreen), findsOneWidget);
      expect(observer.pushes, 2);
      scenes.last.failRender = false;
      await tester.tap(
        find.byKey(
          Key(
            find.byKey(Key('tools-layer-${base.id}')).evaluate().isNotEmpty
                ? 'tools-layer-${base.id}'
                : 'inpaint_layer_thumb_${base.id}',
          ),
        ),
      );
      await drain(tester);
      expect(state.layerManager.activeLayerId, base.id);
      expect(model.model3d!.sceneState['revision'], 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('inpaint 3D and mask layers switch in the same tray', (
    tester,
  ) async {
    final (state, observer, scenes, _) = await open(
      tester,
      mode: ImageEditorMode.inpaint,
    );
    final mask = state.layerManager.activeLayer!;
    expect(mask.inpaintMask, true);
    await tester.tap(
      find.byKey(
        find.byKey(const Key('tools-layer-add3d')).evaluate().isNotEmpty
            ? const Key('tools-layer-add3d')
            : const Key('inpaint_add_3d'),
      ),
    );
    await drain(tester);
    final model = state.layerManager.activeLayer!;
    expect(model.hasModel3d, true);
    expect(observer.pushes, 2);
    expect(find.byType(EditorLayerTray), findsOneWidget);
    await tester.tap(
      find.byKey(
        Key(
          find.byKey(Key('tools-layer-${mask.id}')).evaluate().isNotEmpty
              ? 'tools-layer-${mask.id}'
              : 'inpaint_layer_thumb_${mask.id}',
        ),
      ),
    );
    await drain(tester);
    expect(state.layerManager.activeLayerId, mask.id);
    if (find
        .byKey(
          Key(
            find.byKey(Key('tools-layer-${model.id}')).evaluate().isNotEmpty
                ? 'tools-layer-${model.id}'
                : 'inpaint_layer_thumb_${model.id}',
          ),
        )
        .evaluate()
        .isEmpty) {
      await tester.tap(find.byKey(const Key('inpaint_layers')));
      await drain(tester);
    }
    await tester.tap(
      find.byKey(
        Key(
          find.byKey(Key('tools-layer-${model.id}')).evaluate().isNotEmpty
              ? 'tools-layer-${model.id}'
              : 'inpaint_layer_thumb_${model.id}',
        ),
      ),
    );
    await drain(tester);
    expect(state.layerManager.activeLayerId, model.id);
    expect(scenes.length, 2);
    expect(observer.pushes, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
