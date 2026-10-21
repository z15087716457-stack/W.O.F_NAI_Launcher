import 'package:path/path.dart' as p;

import 'gallery_path_utils.dart';

/// Stable on-disk name; the sidebar label is localized independently.
const galleryUncategorizedFolderName = 'Uncategorized';

String galleryUncategorizedPath(String rootPath) =>
    p.join(rootPath, galleryUncategorizedFolderName);

bool isGalleryUncategorizedFolder(String relativePath) =>
    galleryFilePathsEqual(relativePath, galleryUncategorizedFolderName);
