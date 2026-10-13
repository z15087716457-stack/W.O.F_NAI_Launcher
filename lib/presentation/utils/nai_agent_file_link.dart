import 'dart:io';
import 'package:path/path.dart' as p;

/// Model-written file links resolve only to existing files in this workspace.
Future<Uri?> resolveAgentFileLink(Directory workspace, Uri link) async {
  if (link.scheme.isNotEmpty && link.scheme != 'file') return null;
  if (link.path.isEmpty) return null;
  try {
    final root = await workspace.resolveSymbolicLinks();
    final path = link.scheme == 'file'
        ? p.fromUri(link)
        : p.join(root, Uri.decodeComponent(link.path));
    final absolute = p.normalize(p.absolute(path));
    if (!p.isWithin(root, absolute)) return null;
    final file = File(absolute);
    if (!await file.exists()) return null;
    final canonical = await file.resolveSymbolicLinks();
    return p.isWithin(root, canonical) ? Uri.file(canonical) : null;
  } on FileSystemException {
    return null;
  }
}
