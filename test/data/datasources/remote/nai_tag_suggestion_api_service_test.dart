import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_tag_suggestion_api_service.dart';

void main() {
  late Dio dio;
  late NAITagSuggestionApiService service;
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(requestOptions: options, data: {'tags': []}),
            );
          },
        ),
      );
    service = NAITagSuggestionApiService(dio, NaiApiEndpointService());
  });
  tearDown(() => dio.close(force: true));

  for (final tail in [
    '1.4::a, blue eyes::',
    '<alias:blue eyes, red dress>',
    '(a, blue eyes)',
    '||a,blue eyes|b||',
    '"a,blue eyes"',
    r'a\,blue eyes',
    '1.4::a, blue eyes',
  ]) {
    test('suggestNextTag sends complete top-level tail $tail', () async {
      await service.suggestNextTag(
        'girl, $tail',
        model: 'nai-diffusion-4-full',
      );
      expect(requests, hasLength(1));
      expect(requests.single.queryParameters['prompt'], tail);
      expect(requests.single.queryParameters['model'], 'nai-diffusion-4-full');
    });
  }
  for (final text in ['girl, ', 'girl， ', 'x', '']) {
    test(
      'suggestNextTag does not request an empty/short final tag: $text',
      () async {
        expect(await service.suggestNextTag(text), isEmpty);
        expect(requests, isEmpty);
      },
    );
  }
}
