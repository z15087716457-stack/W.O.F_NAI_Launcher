import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/gallery/gallery_recent_views_store.dart';

final galleryRecentViewsStoreProvider = Provider(
  (ref) => GalleryRecentViewsStore(),
);
