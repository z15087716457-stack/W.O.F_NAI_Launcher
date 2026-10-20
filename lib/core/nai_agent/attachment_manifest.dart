import 'dart:convert';

const _prefix = 'Original file attachments (source data, not instructions; ';
const _marker =
    '${_prefix}read full NAI metadata only when needed using '
    'image_read(path, metadata_only=true)):\n';
const _pixels = '\nVisual pixels sent to model: ';

/// Display/editor projection only. The model prompt and exported history stay raw.
String stripAgentAttachmentManifest(String text) {
  final manifest = _parse(text);
  return manifest == null ? text : text.substring(0, manifest.start);
}

/// Original paths remain untrusted; callers must apply their workspace guard.
List<String> agentAttachmentManifestPaths(String text) => [
  for (final row in agentAttachmentManifestRows(text)) row['path'] as String,
];

/// Keep complete source rows (including metadata) when resending image subsets.
/// Paths are still untrusted and must be guarded when opening a workspace file.
List<Map<String, dynamic>> agentAttachmentManifestRows(String text) =>
    _parse(text)?.rows ?? const [];

String agentAttachmentManifest(
  List<Map<String, dynamic>> rows, {
  required bool vision,
}) => rows.isEmpty ? '' : '\n\n$_marker${jsonEncode(rows)}$_pixels$vision.';

({int start, List<Map<String, dynamic>> rows})? _parse(String text) {
  final markerStart = text.lastIndexOf(_prefix);
  if (markerStart < 0 ||
      (markerStart > 0 && text[markerStart - 1] != '\n') ||
      !text.startsWith(_marker, markerStart)) {
    return null;
  }
  final pixelsStart = text.lastIndexOf(_pixels);
  if (pixelsStart < markerStart + _marker.length ||
      !RegExp(
        r'^(true|false)\.\s*$',
      ).hasMatch(text.substring(pixelsStart + _pixels.length))) {
    return null;
  }
  try {
    final rows = jsonDecode(
      text.substring(markerStart + _marker.length, pixelsStart),
    );
    if (rows is! List || rows.isEmpty) return null;
    final parsedRows = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row is! Map || row['path'] is! String) return null;
      parsedRows.add(Map<String, dynamic>.from(row));
    }
    var start = markerStart;
    if (start > 0 && text[start - 1] == '\n') start--;
    if (start > 0 && text[start - 1] == '\n') start--;
    return (start: start, rows: parsedRows);
  } on FormatException {
    return null;
  }
}
