import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/image_share_sanitizer.dart';
import '../providers/share_image_settings_provider.dart';
import '../utils/clipboard_image.dart';

/// Copies original image bytes, applying the shared privacy policy before the
/// PNG clipboard writer. Neither thumbnails nor file-path clipboard formats.
class ImageClipboardService {
  ImageClipboardService({
    required this.stripMetadata,
    Future<void> Function(Uint8List)? write,
  }) : _write = write ?? writeImageBytesToClipboardAsPng;
  final bool Function() stripMetadata;
  final Future<void> Function(Uint8List) _write;

  Future<void> copyFile(String path) =>
      copyBytes(() => File(path).readAsBytes(), fileName: p.basename(path));

  Future<void> copyBytes(
    Future<Uint8List> Function() read, {
    required String fileName,
  }) async {
    final strip = stripMetadata();
    final image = await ImageShareSanitizer.prepareForCopyOrDrag(
      await read(),
      fileName: fileName,
      stripMetadata: strip,
    );
    await _write(image.bytes);
  }
}

final imageClipboardServiceProvider = Provider(
  (ref) => ImageClipboardService(
    stripMetadata: () => ref
        .read(shareImageSettingsProvider)
        .effectiveStripMetadataForCopyAndDrag,
  ),
);
