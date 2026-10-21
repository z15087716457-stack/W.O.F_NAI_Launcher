import 'package:flutter/widgets.dart';

import '../../core/utils/gallery_storage_layout.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/gallery/gallery_category.dart';

extension GalleryCategoryLabel on GalleryCategory {
  bool get isUncategorizedFolder =>
      isRoot && !isExternal && isGalleryUncategorizedFolder(folderPath);

  String galleryLabel(BuildContext context) => isUncategorizedFolder
      ? context.l10n.localGallery_uncategorizedFolder
      : displayName;
}
