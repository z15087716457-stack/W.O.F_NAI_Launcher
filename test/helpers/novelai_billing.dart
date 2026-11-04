import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/services/anlas_request_ledger.dart';
import 'package:nai_launcher/data/services/anlas_statistics_service.dart';

/// A ledger that records nothing, for tests that build the NovelAI API
/// services by hand and do not look at the Anlas statistics.
AnlasRequestLedger unrecordedLedger() =>
    AnlasRequestLedger(readAccount: () => null, record: (_, __) async {});

/// A plain PNG of [width] × [height] (no NovelAI metadata).
Uint8List syntheticPng(int width, int height) =>
    Uint8List.fromList(img.encodePng(img.Image(width: width, height: height)));

/// An inpaint mask of [width] × [height]: white (repaint) inside [area],
/// black elsewhere.
Uint8List syntheticMask(
  int width,
  int height,
  ({int x, int y, int width, int height}) area,
) {
  final mask = img.Image(width: width, height: height);
  img.fill(mask, color: img.ColorRgb8(0, 0, 0));
  img.fillRect(
    mask,
    x1: area.x,
    y1: area.y,
    x2: area.x + area.width - 1,
    y2: area.y + area.height - 1,
    color: img.ColorRgb8(255, 255, 255),
  );
  return Uint8List.fromList(img.encodePng(mask));
}

/// How the stream endpoint answers: NovelAI's event stream; a ZIP, the way
/// a non-streamed answer comes back on it; or one length-prefixed MessagePack
/// message carrying the image under `data` instead of an event.
enum StreamAnswer { events, zip, dataMessage }

/// NovelAI's image API, answered inside the test process: nothing reaches
/// the network. Every request is listed by endpoint path ([paths]); the
/// billed endpoints answer with synthetic images, tag suggestions with an
/// empty list. A request for anything else, or to a host that is not
/// NovelAI's image API, is listed in [unexpected] and refused.
class FakeNovelAi implements HttpClientAdapter {
  FakeNovelAi({this.imageWidth = 64, this.imageHeight = 96});

  final int imageWidth, imageHeight;

  /// Every request's path, in the order they were sent.
  final paths = <String>[];

  /// Requests no test expects (another host, another endpoint).
  final unexpected = <String>[];

  /// The HTTP status to refuse a request with, as NovelAI refuses one (402
  /// not enough Anlas, 500 …), given its index among all requests so far and
  /// its path; null answers it.
  int? Function(int index, String path)? refuse;

  /// A stream request answers with this server error event instead of its
  /// images (an error NovelAI reports after accepting the request).
  String? streamErrorEvent;

  /// A stream request ends after this many of its images.
  int? streamImagesBeforeEnd;

  /// What a stream request is answered with.
  StreamAnswer streamAnswer = StreamAnswer.events;

  /// While set, answers wait for it (a request still running at NovelAI).
  Completer<void>? hold;

  int count(String endpoint) => paths.where((path) => path == endpoint).length;

  late final Uint8List _png = syntheticPng(imageWidth, imageHeight);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.addAll(chunk);
      }
    }
    final uri = options.uri;
    final index = paths.length;
    paths.add(uri.path);
    if (uri.host != Uri.parse(ApiConstants.imageBaseUrl).host) {
      unexpected.add('$uri');
      return _refuse(599);
    }
    final pending = hold;
    if (pending != null) await pending.future;
    final refused = refuse?.call(index, uri.path);
    if (refused != null) return _refuse(refused);
    final request = latin1.decode(body, allowInvalid: true);
    int? field(String name) => int.tryParse(
      RegExp('"$name":(\\d+)').firstMatch(request)?.group(1) ?? '',
    );
    final samples = field('n_samples') ?? 1;
    // An inpaint answers at the size it was asked for, so the app can paste
    // the image back into the source.
    final image = request.contains('"action":"infill"')
        ? syntheticPng(field('width')!, field('height')!)
        : _png;
    switch (uri.path) {
      case ApiConstants.generateImageEndpoint:
        return _zip([for (var i = 0; i < samples; i++) image]);
      case ApiConstants.generateImageStreamEndpoint:
        return _stream(samples, image);
      case ApiConstants.upscaleEndpoint:
        // The official upscale is a fixed 2x of the image it was sent.
        final sent = img.decodeImage(
          base64Decode(jsonDecode(utf8.decode(body))['image'] as String),
        )!;
        return _zip([syntheticPng(sent.width * 2, sent.height * 2)]);
      case ApiConstants.augmentImageEndpoint:
        return _zip([_png]);
      case ApiConstants.encodeVibeEndpoint:
        return ResponseBody.fromBytes(
          const [7, 7, 7, 7],
          200,
          headers: {
            Headers.contentTypeHeader: ['application/octet-stream'],
          },
        );
      case ApiConstants.suggestTagsEndpoint:
        return ResponseBody.fromString(
          '{"tags":[]}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
    }
    unexpected.add('$uri');
    return _refuse(599);
  }

  ResponseBody _zip(List<Uint8List> images) {
    final archive = Archive();
    for (var i = 0; i < images.length; i++) {
      archive.addFile(ArchiveFile('image_$i.png', images[i].length, images[i]));
    }
    return ResponseBody.fromBytes(
      ZipEncoder().encode(archive) ?? const <int>[],
      200,
      headers: {
        Headers.contentTypeHeader: ['application/x-zip-compressed'],
      },
    );
  }

  /// NovelAI's stream framing: a 4-byte big-endian length, then MessagePack.
  ResponseBody _stream(int samples, Uint8List image) {
    if (streamAnswer == StreamAnswer.zip) {
      return _zip([for (var i = 0; i < samples; i++) image]);
    }
    final events = <Map<String, Object?>>[
      if (streamAnswer == StreamAnswer.dataMessage)
        {'data': image}
      else if (streamErrorEvent != null)
        {'event_type': 'error', 'message': streamErrorEvent}
      else
        for (var i = 0; i < (streamImagesBeforeEnd ?? samples); i++) ...[
          {'event_type': 'intermediate', 'samp_ix': i, 'step_ix': 0},
          {'event_type': 'final', 'samp_ix': i, 'image': image},
        ],
    ];
    final bytes = <int>[];
    for (final event in events) {
      final encoded = msgpack.serialize(event);
      bytes
        ..add((encoded.length >> 24) & 0xFF)
        ..add((encoded.length >> 16) & 0xFF)
        ..add((encoded.length >> 8) & 0xFF)
        ..add(encoded.length & 0xFF)
        ..addAll(encoded);
    }
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/x-msgpack'],
      },
    );
  }

  ResponseBody _refuse(int status) => ResponseBody.fromString(
    '{"statusCode":$status,"message":"synthetic refusal"}',
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// The daily Anlas statistics, keeping every amount the app records (an
/// Opus-free request records 0) instead of writing preferences.
class SpendRecords extends AnlasStatisticsService {
  final amounts = <int>[];

  @override
  Future<AnlasStatisticsService> build() async => this;

  @override
  Future<void> recordCost(int cost, {DateTime? date}) async {
    amounts.add(cost);
  }
}
