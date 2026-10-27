import 'dart:convert';
import 'dart:typed_data';

import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

/// Resource kinds are separated by OS format, not by trusted Dart localData.
enum ResourceDragKind { block, vibe, precise }

class ResourceDragReference {
  ResourceDragReference(this.kind, this.id) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id');
  }

  final ResourceDragKind kind;
  final String id;

  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode({'id': id})));

  static ResourceDragReference? decode(ResourceDragKind kind, Object? bytes) {
    if (bytes is! Uint8List) return null;
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic> ||
          json.length != 1 ||
          json['id'] is! String ||
          (json['id'] as String).trim().isEmpty) {
        return null;
      }
      return ResourceDragReference(kind, json['id'] as String);
    } on FormatException {
      return null;
    }
  }
}

ValueFormat<ResourceDragReference> _format(
  ResourceDragKind kind,
  String identifier,
) => SimpleValueFormat<ResourceDragReference>(
  fallback: SimplePlatformCodec<ResourceDragReference>(
    formats: [identifier],
    onEncode: (value, _) {
      if (value.kind != kind) throw ArgumentError('Resource kind mismatch');
      return value.encode();
    },
    onDecode: (provider, format) async =>
        ResourceDragReference.decode(kind, await provider.getData(format)),
  ),
);

abstract final class ResourceWindowDrag {
  static final block = _format(
    ResourceDragKind.block,
    'application/x-nai-block+json',
  );
  static final vibe = _format(
    ResourceDragKind.vibe,
    'application/x-nai-vibe+json',
  );
  static final precise = _format(
    ResourceDragKind.precise,
    'application/x-nai-precise+json',
  );
  static final formats = [block, vibe, precise];

  static ValueFormat<ResourceDragReference> formatFor(ResourceDragKind kind) =>
      switch (kind) {
        ResourceDragKind.block => block,
        ResourceDragKind.vibe => vibe,
        ResourceDragKind.precise => precise,
      };

  /// Main engine supplies the export URI after applying its existing sharing
  /// policy (original or ImageShareSanitizer temporary file). Never tag a child
  /// file as gallery_internal: GlobalDropHandler intentionally rejects that tag.
  static DragItem createGalleryItem(Uri exportUri) {
    if (exportUri.scheme != 'file') {
      throw ArgumentError.value(exportUri, 'exportUri', 'Expected a file URI');
    }
    return DragItem()..add(Formats.fileUri(exportUri));
  }

  /// For DragItemWidget.dragItemProvider in the resource engine. No body,
  /// encodings, image bytes, prompt parameters or snapshot crosses the drag.
  static DragItem createItem(ResourceDragReference reference) {
    final format = formatFor(reference.kind);
    return DragItem()..add(format(reference));
  }

  static DropOperation operation(DropSession session, ResourceDragKind kind) {
    final format = formatFor(kind);
    return session.allowedOperations.contains(DropOperation.copy) &&
            session.items.any((item) => item.canProvide(format))
        ? DropOperation.copy
        : DropOperation.none;
  }

  /// Call synchronously from DropRegion.onPerformDrop and immediately return
  /// from that callback. Request the OS data before async work; never await
  /// the main library lookup while Windows is completing its OLE drop.
  /// [onReference] must resolve the id against the current main-engine library.
  static void receive(
    PerformDropEvent event, {
    required ResourceDragKind kind,
    required void Function(ResourceDragReference) onReference,
    required void Function(Object) onError,
  }) {
    if (event.acceptedOperation != DropOperation.copy) return;
    final format = formatFor(kind);
    for (final item in event.session.items) {
      final reader = item.dataReader;
      if (!item.canProvide(format) || reader == null) continue;
      reader.getValue<ResourceDragReference>(format, (reference) {
        if (reference != null) onReference(reference);
      }, onError: onError);
    }
  }
}
