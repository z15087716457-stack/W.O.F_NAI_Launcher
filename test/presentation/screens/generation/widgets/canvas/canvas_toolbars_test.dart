import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';

GeneratedImage _img({required String id, int width = 832, int height = 1216}) {
  return GeneratedImage(
    id: id,
    bytes: Uint8List(0),
    width: width,
    height: height,
    createdAt: DateTime(2025, 1, 1),
    kind: GeneratedImageKind.completed,
    generationRunId: 1,
  );
}

CanvasFeedGroup _group(GeneratedImage img) => CanvasFeedGroup(
  key: 'run:1',
  runId: 1,
  tiles: [CanvasTileSpec.image(img)],
  requestedCount: 1,
);

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWith((ref) => _FakeCanvasStorage()),
      estimatedCostProvider.overrideWithValue(7),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CanvasEdgeToolbar', () {
    testWidgets('top zone renders 7 icons + divider', (tester) async {
      final img = _img(id: 'a');
      await tester.pumpWidget(
        _wrap(
          CanvasEdgeToolbar(
            zone: CanvasToolbarZone.top,
            image: img,
            group: _group(img),
            focus: null,
          ),
        ),
      );
      expect(find.byType(SvgPicture), findsNWidgets(7));
      // No metadata quote yet; opening upscale settings is not a cloud request.
      expect(find.text('7'), findsNothing);
    });

    testWidgets('bottomStart renders WxH + settings + seed', (tester) async {
      final img = _img(id: 'a', width: 832, height: 1216);
      await tester.pumpWidget(
        _wrap(
          CanvasEdgeToolbar(
            zone: CanvasToolbarZone.bottomStart,
            image: img,
            group: _group(img),
            focus: null,
          ),
        ),
      );
      expect(find.text('832 × 1216'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNWidgets(2));
    });

    testWidgets(
      'bottomEnd renders pin|copy|download|info without fake upload',
      (tester) async {
        final img = _img(id: 'a');
        await tester.pumpWidget(
          _wrap(
            CanvasEdgeToolbar(
              zone: CanvasToolbarZone.bottomEnd,
              image: img,
              group: _group(img),
              focus: null,
            ),
          ),
        );
        expect(find.byType(SvgPicture), findsNWidgets(4));
        expect(find.byTooltip('Upload to explore'), findsNothing);
      },
    );
  });

  testWidgets(
    'main toolbars stay on viewport edges through pan, zoom and resize',
    (tester) async {
      final image = GeneratedImage(
        id: 'viewport-toolbar-image',
        bytes: Uint8List.fromList(
          img.encodePng(img.Image(width: 1, height: 1)),
        ),
        width: 832,
        height: 1216,
        createdAt: DateTime(2025, 1, 1),
        kind: GeneratedImageKind.completed,
        generationRunId: 1,
      );
      final group = _group(image);
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _FakeCanvasStorage(),
          ),
          estimatedCostProvider.overrideWithValue(7),
          canvasFeedLayoutProvider.overrideWith(
            () => _FixedCanvasLayout(group),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.fromLTRB(200, 40, 150, 30),
                child: GenerationCanvasView(
                  generationState: ImageGenerationState(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Rect barRect(CanvasToolbarZone zone) => tester.getRect(
        find.byWidgetPredicate((w) => w is CanvasEdgeToolbar && w.zone == zone),
      );
      void expectViewportAnchors() {
        final viewport = tester.getRect(find.byType(GenerationCanvasView));
        final top = barRect(CanvasToolbarZone.top);
        final left = barRect(CanvasToolbarZone.bottomStart);
        final right = barRect(CanvasToolbarZone.bottomEnd);
        expect(top.top, closeTo(viewport.top + 12, 0.01));
        expect(top.center.dx, closeTo(viewport.center.dx, 0.01));
        expect(left.left, closeTo(viewport.left + 12, 0.01));
        expect(left.bottom, closeTo(viewport.bottom - 12, 0.01));
        expect(right.right, closeTo(viewport.right - 12, 0.01));
        expect(right.bottom, closeTo(viewport.bottom - 12, 0.01));
        expect(left.right, lessThan(right.left));
        expect(tester.takeException(), isNull);
      }

      expectViewportAnchors();
      final initial = {
        for (final zone in CanvasToolbarZone.values) zone: barRect(zone),
      };
      final camera = container.read(generationCanvasCameraProvider.notifier);
      // Change real camera state far enough to move the selected tile off screen.
      camera.panBy(const Offset(600, -500));
      await tester.pump();
      for (final scale in [0.1, 0.5, 2.0, 8.0]) {
        camera.flyTo(CanvasCamera(offset: const Offset(180, 90), scale: scale));
        await tester.pump();
        expect(container.read(generationCanvasCameraProvider).scale, scale);
        for (final zone in CanvasToolbarZone.values) {
          expect(barRect(zone), initial[zone]);
        }
      }
      // The overlay must leave blank space available for canvas panning.
      final before = container.read(generationCanvasCameraProvider).offset;
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(GenerationCanvasView)),
          scrollDelta: const Offset(0, 70),
        ),
      );
      await tester.pump();
      expect(
        container.read(generationCanvasCameraProvider).offset,
        before - const Offset(0, 70),
      );
      expectViewportAnchors();

      await tester.binding.setSurfaceSize(const Size(900, 650));
      await tester.pump();
      expectViewportAnchors();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  group('CanvasMiniToolbar', () {
    testWidgets('renders pin|copy|download + seed pill', (tester) async {
      final img = _img(id: 'a');
      await tester.pumpWidget(
        _wrap(CanvasMiniToolbar(image: img, group: _group(img))),
      );
      expect(
        find.byType(SvgPicture),
        findsNWidgets(4),
      ); // pin|copy|download|seed
    });
  });
}

class _FakeCanvasStorage extends LocalStorageService {
  @override
  bool getCanvasLockCamera() => false;

  @override
  bool getCanvasReducedMotion() => true;

  @override
  Set<String> getCanvasPinnedImages() => {};
}

class _FixedCanvasLayout extends CanvasFeedLayoutNotifier {
  _FixedCanvasLayout(this.group);
  final CanvasFeedGroup group;

  @override
  CanvasFeedLayoutResult build() {
    final layout = layoutCanvasFeed([group]);
    return CanvasFeedLayoutResult(
      items: layout.items,
      groups: [group],
      bounds: layout.bounds,
    );
  }
}
