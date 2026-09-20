import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';

GeneratedImage _img({
  required String id,
  int width = 832,
  int height = 1216,
}) {
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
      images: [img],
      requestedCount: 1,
    );

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWith(
        (ref) => _FakeCanvasStorage(),
      ),
      estimatedCostProvider.overrideWithValue(7),
    ],
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
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
      expect(find.text('7'), findsNWidgets(2)); // variations+upscale 价签
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

    testWidgets('bottomEnd renders pin|copy|download|info|upload',
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
      expect(find.byType(SvgPicture), findsNWidgets(5));
    });
  });

  group('CanvasMiniToolbar', () {
    testWidgets('renders pin|copy|download + seed pill', (tester) async {
      final img = _img(id: 'a');
      await tester.pumpWidget(
        _wrap(
          CanvasMiniToolbar(
            image: img,
            group: _group(img),
          ),
        ),
      );
      expect(find.byType(SvgPicture), findsNWidgets(4)); // pin|copy|download|seed
    });
  });
}

class _FakeCanvasStorage extends LocalStorageService {
  @override
  bool getCanvasLockCamera() => false;

  @override
  bool getCanvasReducedMotion() => false;
}
