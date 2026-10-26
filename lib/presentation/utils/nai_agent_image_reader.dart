import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';

import '../../core/nai_agent/attachment_image.dart';
import '../../core/nai_agent/windows_clipboard_image.dart';
import 'dropped_file_reader.dart';

const agentImageReadTimeout = Duration(seconds: 10);
final agentImageReadFormats = [
  Formats.png,
  Formats.jpeg,
  Formats.webp,
  Formats.gif,
  Formats.bmp,
];

Future<Uint8List> readAgentImageStream(
  Stream<List<int>> stream, {
  int maxBytes = agentAttachmentMaxBytes,
}) async {
  final builder = BytesBuilder(copy: false);
  var length = 0;
  await for (final chunk in stream.timeout(agentImageReadTimeout)) {
    length += chunk.length;
    if (length > maxBytes) throw const AgentImageInputException('oversized');
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Future<DroppedFileData> readAgentImageFile(String path) async {
  final file = File(path);
  if (await file.length().timeout(agentImageReadTimeout) >
      agentAttachmentMaxBytes) {
    throw const AgentImageInputException('oversized');
  }
  return DroppedFileData(
    fileName: p.basename(path),
    bytes: await readAgentImageStream(file.openRead()),
    sourcePath: path,
    sourceUri: file.uri,
  );
}

bool isAgentImagePath(String path) => const {
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.gif',
  '.bmp',
}.contains(p.extension(path).toLowerCase());

Future<Uri> readAgentFileUri(DataReader reader) async {
  final complete = Completer<Uri?>();
  final progress = reader.getValue<Uri>(
    Formats.fileUri,
    (uri) {
      if (!complete.isCompleted) complete.complete(uri);
    },
    onError: (error) {
      if (!complete.isCompleted) complete.completeError(error);
    },
  );
  if (progress == null) throw const AgentImageInputException('unreadable');
  final uri = await complete.future.timeout(
    agentImageReadTimeout,
    onTimeout: () {
      progress.cancel();
      throw const AgentImageInputException('unreadable');
    },
  );
  if (uri == null || !uri.isScheme('file')) {
    throw const AgentImageInputException('unreadable');
  }
  return uri;
}

/// File URI takes priority over a synthesized bitmap, retaining PNG chunks,
/// EXIF and exact source bytes. URL/HTML-only sources never trigger a download.
Future<DroppedFileData?> readAgentImage(
  DataReader reader, {
  bool dropping = false,
  bool clipboard = false,
}) async {
  if (reader.canProvide(Formats.fileUri)) {
    return readAgentImageFile((await readAgentFileUri(reader)).toFilePath());
  }
  for (final format in agentImageReadFormats) {
    if (!reader.canProvide(format)) continue;
    final complete = Completer<DroppedFileData>();
    final progress = reader.getFile(
      format,
      (file) async {
        try {
          if ((file.fileSize ?? 0) > agentAttachmentMaxBytes) {
            throw const AgentImageInputException('oversized');
          }
          final bytes = await readAgentImageStream(file.getStream());
          if (!complete.isCompleted) {
            complete.complete(
              DroppedFileData(fileName: file.fileName ?? 'image', bytes: bytes),
            );
          }
        } catch (error, stack) {
          file.close();
          if (!complete.isCompleted) complete.completeError(error, stack);
        }
      },
      onError: (error) {
        if (!complete.isCompleted) complete.completeError(error);
      },
      synthesizeFilesFromURIs: false,
    );
    if (progress == null) throw const AgentImageInputException('unreadable');
    return complete.future.timeout(
      agentImageReadTimeout,
      onTimeout: () {
        progress.cancel();
        throw const AgentImageInputException('unreadable');
      },
    );
  }
  // Only OS-backed clipboard readers may access this fallback. Injected widget
  // readers never inspect the user's real clipboard; external OLE is separate.
  if (clipboard && reader.rawReader != null) {
    final bitmap = await readAgentWindowsClipboardBitmap().timeout(
      agentImageReadTimeout,
    );
    if (bitmap != null) {
      return DroppedFileData(fileName: 'clipboard.bmp', bytes: bitmap);
    }
  }
  if (dropping &&
      (reader.canProvide(Formats.uri) || reader.canProvide(Formats.htmlText))) {
    throw const AgentImageInputException('link_only');
  }
  return null;
}
