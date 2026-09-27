import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/utils/gallery_path_utils.dart';

enum GalleryExtraRootValidationError { notFound, sameAsMain, duplicate, nested }

/// Check a new gallery source before saving it. The main root and existing
/// extra roots must not overlap, otherwise the scanner would visit images twice.
Future<GalleryExtraRootValidationError?> validateGalleryExtraRoot({
  required String selectedPath,
  required String? mainRoot,
  required List<String> existingRoots,
}) async {
  if (!await Directory(selectedPath).exists()) {
    return GalleryExtraRootValidationError.notFound;
  }

  final selected = _comparisonPath(selectedPath);
  if (mainRoot != null && mainRoot.isNotEmpty) {
    final main = _comparisonPath(mainRoot);
    if (galleryFilePathsEqual(main, selected)) {
      return GalleryExtraRootValidationError.sameAsMain;
    }
    if (_pathsOverlap(main, selected)) {
      return GalleryExtraRootValidationError.nested;
    }
  }

  for (final root in existingRoots) {
    final existing = _comparisonPath(root);
    if (galleryFilePathsEqual(existing, selected)) {
      return GalleryExtraRootValidationError.duplicate;
    }
    if (_pathsOverlap(existing, selected)) {
      return GalleryExtraRootValidationError.nested;
    }
  }

  return null;
}

String _comparisonPath(String value) =>
    p.normalize(p.absolute(normalizeGalleryFilePath(value)));

bool _pathsOverlap(String left, String right) =>
    galleryPathIsWithin(left, right) || galleryPathIsWithin(right, left);
