import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/widgets/common/decoded_memory_image.dart';

void main() {
  test('DecodedMemoryImage 根据逻辑尺寸计算解码缓存尺寸', () {
    expect(
      DecodedMemoryImage.resolveCacheDimension(
        logicalSize: null,
        constrainedSize: 100,
        pixelRatio: 2,
      ),
      200,
    );
    expect(
      DecodedMemoryImage.resolveCacheDimension(
        logicalSize: 50,
        constrainedSize: 100,
        pixelRatio: 2,
        decodeScale: 1.5,
      ),
      150,
    );
    expect(
      DecodedMemoryImage.resolveCacheDimension(
        logicalSize: null,
        constrainedSize: null,
        pixelRatio: 2,
      ),
      isNull,
    );
  });

  testWidgets('DecodedMemoryImage keeps the encoded aspect ratio', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 100,
            height: 200,
            child: DecodedMemoryImage(
              bytes: _testPngBytes(width: 200, height: 100),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());

    final provider = image.image as ResizeImage;
    expect(provider.width, 100);
    expect(provider.height, 200);
    expect(provider.policy, ResizeImagePolicy.fit);
  });

  for (final spec in [
    (source: const Size(600, 900), dpr: 1.0, expected: const Size(300, 450)),
    (source: const Size(900, 300), dpr: 1.0, expected: const Size(540, 180)),
    (source: const Size(90, 60), dpr: 1.0, expected: const Size(90, 60)),
    (source: const Size(600, 900), dpr: 2.0, expected: const Size(600, 900)),
  ]) {
    testWidgets('cover banner decodes ${spec.source} at DPR ${spec.dpr}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = spec.dpr;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 180,
              child: DecodedMemoryImage(
                bytes: _testPngBytes(
                  width: spec.source.width.toInt(),
                  height: spec.source.height.toInt(),
                ),
                decodeForCover: true,
              ),
            ),
          ),
        ),
      );
      final provider = tester.widget<Image>(find.byType(Image)).image;
      final decoded = await tester.runAsync(() async {
        final result = Completer<Size>();
        final stream = provider.resolve(ImageConfiguration.empty);
        final listener = ImageStreamListener((info, _) {
          if (!result.isCompleted) {
            result.complete(
              Size(info.image.width.toDouble(), info.image.height.toDouble()),
            );
          }
          info.dispose();
        }, onError: result.completeError);
        stream.addListener(listener);
        try {
          return await result.future;
        } finally {
          stream.removeListener(listener);
        }
      });
      expect(decoded, spec.expected);
    });
  }

  testWidgets('cover cache changes with banner dimensions', (tester) async {
    final bytes = _testPngBytes(width: 600, height: 900);
    Future<ImageProvider> providerAt(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              height: 180,
              child: DecodedMemoryImage(bytes: bytes, decodeForCover: true),
            ),
          ),
        ),
      );
      return tester.widget<Image>(find.byType(Image)).image;
    }

    final small = await providerAt(200);
    final wide = await providerAt(400);
    final same = await providerAt(400);
    expect(small, isNot(wide));
    expect(wide, same);
  });
}

Uint8List _testPngBytes({required int width, required int height}) {
  return Uint8List.fromList(
    img.encodePng(img.Image(width: width, height: height)),
  );
}
