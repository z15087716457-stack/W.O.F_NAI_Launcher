import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/online_gallery/gallery_item.dart';
import '../../data/services/gallery/online_gallery_download_service.dart';

final onlineGalleryDownloadServiceProvider =
    Provider<OnlineGalleryDownloadService>(
      (ref) => const OnlineGalleryDownloadService(),
    );

/// The inspector and viewer share one selection. Agent tools read its last
/// displayed work/page even when the user switches to the chat tab.
class OnlineGallerySelection {
  GalleryItem? item;
  int page = 1;

  void select(GalleryItem? work) {
    if (item?.stableKey != work?.stableKey) page = 1;
    item = work;
  }

  int indexFor(String key) => item?.stableKey == key ? page - 1 : 0;

  void setMedia(String key, int index) {
    if (item?.stableKey == key) page = index + 1;
  }
}

final onlineGallerySelectionProvider = Provider(
  (ref) => OnlineGallerySelection(),
);
