import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  group('NAIImageEnhancementApiService', () {
    test(
      'director tools preserve all three background removal variants',
      () async {
        final dio = _MockDio();
        final images = [
          for (final width in [12, 24, 36]) _buildPng(width: width, height: 8),
        ];
        final archive = Archive();
        for (final entry in images.indexed) {
          archive.addFile(
            ArchiveFile('${entry.$1}.png', entry.$2.length, entry.$2),
          );
        }
        when(
          () => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            data: Uint8List.fromList(ZipEncoder().encode(archive)!),
            requestOptions: RequestOptions(path: '/augment-image'),
          ),
        );
        final result = await NAIImageEnhancementApiService(
          dio,
        ).augmentImages(images.first, reqType: 'bg-removal');
        expect(result, hasLength(3));
        for (var i = 0; i < images.length; i++) {
          expect(result[i], images[i]);
        }
      },
    );

    test(
      'upscale uses the current image host and V5 request instead of the retired main host',
      () async {
        final dio = _MockDio();
        final sourceImage = _buildPng(width: 48, height: 32);
        final zipBytes = _buildZipWithSingleImage(sourceImage);
        Map<String, dynamic>? capturedData;

        when(
          () => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ),
        ).thenAnswer((invocation) async {
          capturedData = Map<String, dynamic>.from(
            invocation.namedArguments[#data] as Map,
          );
          return Response<dynamic>(
            data: zipBytes,
            requestOptions: RequestOptions(path: '/ai/upscale'),
          );
        });

        final service = NAIImageEnhancementApiService(dio);
        final result = await service.upscaleImage(sourceImage);

        expect(result, isNotEmpty);
        expect(
          capturedData,
          equals({
            'image': base64Encode(sourceImage),
            'model': 'nai-diffusion-5-curated',
            'declared_blur_sigma': 0,
          }),
        );
        verify(
          () => dio.post<dynamic>(
            'https://image.novelai.net/ai/upscale',
            data: any(named: 'data'),
            options: any(named: 'options'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ),
        ).called(1);
      },
    );

    for (final rawPng in [true, false]) {
      test(
        'upscale honors a custom image endpoint and rejects non-image HTTP 200 ($rawPng)',
        () async {
          final dio = _MockDio();
          final source = _buildPng(width: 48, height: 32);
          final endpoint = NaiApiEndpointService()
            ..setCurrent(
              const NaiApiEndpointConfig(
                mainBaseUrl: 'https://main.example',
                imageBaseUrl: 'https://images.example',
              ),
            );
          when(
            () => dio.post<dynamic>(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
              onReceiveProgress: any(named: 'onReceiveProgress'),
            ),
          ).thenAnswer(
            (_) async => Response(
              data: rawPng
                  ? source
                  : Uint8List.fromList(utf8.encode('{"error":"not an image"}')),
              requestOptions: RequestOptions(path: '/ai/upscale'),
            ),
          );
          final result = NAIImageEnhancementApiService(
            dio,
            endpoint,
          ).upscaleImage(source);
          if (rawPng) {
            expect(await result, source);
          } else {
            await expectLater(result, throwsFormatException);
          }
          verify(
            () => dio.post<dynamic>(
              'https://images.example/ai/upscale',
              data: any(named: 'data'),
              options: any(named: 'options'),
              onReceiveProgress: any(named: 'onReceiveProgress'),
            ),
          ).called(1);
        },
      );
    }

    test('unsupported upscale inputs fail before a billable request', () async {
      final dio = _MockDio();
      await expectLater(
        NAIImageEnhancementApiService(
          dio,
        ).upscaleImage(_buildPng(width: 2048, height: 2048)),
        throwsArgumentError,
      );
      verifyNever(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      );
    });

    test(
      'should send source image width and height for director tools',
      () async {
        final dio = _MockDio();
        final sourceImage = _buildPng(width: 48, height: 32);
        final zipBytes = _buildZipWithSingleImage(sourceImage);
        Map<String, dynamic>? capturedData;

        when(
          () => dio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          capturedData = Map<String, dynamic>.from(
            invocation.namedArguments[#data] as Map,
          );
          return Response<dynamic>(
            data: zipBytes,
            requestOptions: RequestOptions(path: '/augment-image'),
          );
        });

        final service = NAIImageEnhancementApiService(dio);
        final result = await service.removeBackground(sourceImage);

        expect(result, isNotEmpty);
        expect(capturedData?['req_type'], equals('bg-removal'));
        expect(capturedData?['width'], equals(48));
        expect(capturedData?['height'], equals(32));
      },
    );

    test('encodeVibe should send information_extracted to API', () async {
      final dio = _MockDio();
      final sourceImage = _buildPng(width: 32, height: 32);
      Map<String, dynamic>? capturedData;

      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        capturedData = Map<String, dynamic>.from(
          invocation.namedArguments[#data] as Map,
        );
        return Response<dynamic>(
          data: Uint8List.fromList(const [1, 2, 3]),
          requestOptions: RequestOptions(path: '/encode-vibe'),
        );
      });

      final service = NAIImageEnhancementApiService(dio);
      final result = await service.encodeVibe(
        sourceImage,
        model: 'nai-diffusion-4-5-full',
        informationExtracted: 0.35,
      );

      expect(result, isNotEmpty);
      expect(capturedData?['model'], equals('nai-diffusion-4-5-full'));
      expect(capturedData?['information_extracted'], equals(0.35));
      expect(capturedData?.containsKey('informationExtracted'), isFalse);
    });
  });
}

Uint8List _buildPng({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _buildZipWithSingleImage(Uint8List imageBytes) {
  final archive = Archive()
    ..addFile(ArchiveFile('result.png', imageBytes.length, imageBytes));
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded!);
}
