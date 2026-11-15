import 'dart:io';

import 'package:path/path.dart' as p;
import '../../../core/utils/gallery_path_utils.dart';

enum GallerySourceValidationError { notFound, duplicate, covered }

Future<GallerySourceValidationError?> validateGallerySource({
  required String selectedPath,
  required List<String> existingRoots,
}) async {
  if (!await Directory(selectedPath).exists()) {
    return GallerySourceValidationError.notFound;
  }
  final selected = p.normalize(
    p.absolute(normalizeGalleryFilePath(selectedPath)),
  );
  for (final root in existingRoots) {
    final existing = p.normalize(p.absolute(normalizeGalleryFilePath(root)));
    if (galleryFilePathsEqual(existing, selected)) {
      return GallerySourceValidationError.duplicate;
    }
    if (galleryPathIsWithin(existing, selected)) {
      return GallerySourceValidationError.covered;
    }
  }
  return null;
}
