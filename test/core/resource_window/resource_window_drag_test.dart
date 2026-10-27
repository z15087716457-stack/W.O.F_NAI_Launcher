import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:nai_launcher/core/utils/resource_window_drag.dart';

class _Provider implements PlatformDataProvider {
  _Provider(this.value);
  final Object? value;
  final requested = <String>[];
  @override
  Future<Object?> getData(String format) async {
    requested.add(format);
    return value;
  }

  @override
  List<String> getAllFormats() => requested;
}

class _MapProvider implements PlatformDataProvider {
  _MapProvider(this.values);
  final Map<String, dynamic> values;
  @override
  Future<Object?> getData(String format) async => values[format];
  @override
  List<String> getAllFormats() => values.keys.toList();
}

class _Item extends Mock implements DropItem {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => 'item';
}

class _Session extends Mock implements DropSession {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'session';
}

class _Reader extends Mock implements DataReader {}

void main() {
  test(
    'gallery exports an OS file URI, not rejected gallery_internal localData',
    () async {
      final uri = Uri.file('C:/synthetic/shared.png', windows: true);
      final item = ResourceWindowDrag.createGalleryItem(uri);
      expect(item.localData, isNull);
      final encoded = await item.data.single;
      final formats = Formats.fileUri.codec.encodingFormats;
      expect(encoded.representations.map((entry) => entry.format), formats);
      final values = {
        for (final entry in encoded.representations)
          entry.format: (entry as dynamic).data,
      };
      final provider = _MapProvider(values);
      expect(await Formats.fileUri.codec.decode(provider, formats.first), uri);
      expect(
        () => ResourceWindowDrag.createGalleryItem(
          Uri.parse('https://invalid.test/image.png'),
        ),
        throwsArgumentError,
      );
    },
  );

  for (final kind in ResourceDragKind.values) {
    test(
      '$kind native format encodes only id and decodes without Dart identity',
      () async {
        final reference = ResourceDragReference(kind, '中文-"id');
        final item = ResourceWindowDrag.createItem(reference);
        expect(item.localData, isNull);
        final encoded = await item.data.single;
        final representation = encoded.representations.single;
        final format = ResourceWindowDrag.formatFor(kind);
        expect(representation.format, format.codec.encodingFormats.single);
        final data = (representation as dynamic).data as Uint8List;
        expect(jsonDecode(utf8.decode(data)), {'id': reference.id});
        final provider = _Provider(Uint8List.fromList(data));
        final pending = format.codec.decode(provider, representation.format);
        expect(provider.requested, [representation.format]);
        final decoded = await pending;
        expect(decoded!.kind, kind);
        expect(decoded.id, reference.id);
      },
    );
  }

  test(
    'formats are distinct and a mismatched source kind cannot be encoded',
    () {
      expect(
        ResourceWindowDrag.formats
            .map((f) => f.codec.encodingFormats.single)
            .toSet(),
        {
          'application/x-nai-block+json',
          'application/x-nai-vibe+json',
          'application/x-nai-precise+json',
        },
      );
      expect(
        () => ResourceWindowDrag.block(
          ResourceDragReference(ResourceDragKind.vibe, 'id'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ResourceDragReference(ResourceDragKind.block, ' '),
        throwsArgumentError,
      );
    },
  );

  test('rejects malformed, empty, non-byte and content-bearing payloads', () {
    for (final source in [
      'bad',
      '[]',
      '{}',
      '{"id":0}',
      '{"id":" "}',
      '{"id":"id","content":"stale prompt"}',
    ]) {
      expect(
        ResourceDragReference.decode(
          ResourceDragKind.block,
          Uint8List.fromList(utf8.encode(source)),
        ),
        isNull,
      );
    }
    expect(
      ResourceDragReference.decode(
        ResourceDragKind.block,
        Uint8List.fromList([0xff]),
      ),
      isNull,
    );
    expect(
      ResourceDragReference.decode(ResourceDragKind.block, '{"id":"id"}'),
      isNull,
    );
  });

  test(
    'receiver requests native data synchronously and never reads localData',
    () {
      final session = _Session();
      final item = _Item();
      final reader = _Reader();
      final received = <ResourceDragReference>[];
      final errors = <Object>[];
      final format = ResourceWindowDrag.block;
      when(() => session.items).thenReturn([item]);
      when(() => session.allowedOperations).thenReturn({DropOperation.copy});
      when(() => item.canProvide(format)).thenReturn(true);
      when(() => item.canProvide(ResourceWindowDrag.vibe)).thenReturn(false);
      when(() => item.dataReader).thenReturn(reader);
      ResourceDragReference? payload;
      AsyncValueChanged<ResourceDragReference?>? callback;
      when(
        () => reader.getValue<ResourceDragReference>(
          format,
          any(),
          onError: any(named: 'onError'),
        ),
      ).thenAnswer((invocation) {
        callback =
            invocation.positionalArguments[1]
                as AsyncValueChanged<ResourceDragReference?>;
        return null;
      });
      expect(
        ResourceWindowDrag.operation(session, ResourceDragKind.block),
        DropOperation.copy,
      );
      expect(
        ResourceWindowDrag.operation(session, ResourceDragKind.vibe),
        DropOperation.none,
      );
      ResourceWindowDrag.receive(
        PerformDropEvent(
          session: session,
          position: DropPosition(local: Offset.zero, global: Offset.zero),
          acceptedOperation: DropOperation.copy,
        ),
        kind: ResourceDragKind.block,
        onReference: received.add,
        onError: errors.add,
      );
      expect(callback, isNotNull);
      expect(received, isEmpty);
      payload = ResourceDragReference(
        ResourceDragKind.block,
        'current-library-id',
      );
      callback!(payload);
      expect(received.single.id, 'current-library-id');
      callback!(null);
      expect(received, hasLength(1));
      expect(errors, isEmpty);
      verifyNever(() => item.localData);
      when(() => session.allowedOperations).thenReturn({DropOperation.move});
      expect(
        ResourceWindowDrag.operation(session, ResourceDragKind.block),
        DropOperation.none,
      );
    },
  );
}
