import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/rag/rag_gallery_search.dart';

/// Session-only query image. Never changes a generation draft or saved settings.
final galleryRagQueryProvider =
    NotifierProvider<GalleryRagQueryController, RagGalleryQueryOptions>(
      GalleryRagQueryController.new,
    );

class GalleryRagQueryController extends Notifier<RagGalleryQueryOptions> {
  @override
  RagGalleryQueryOptions build() => const RagGalleryQueryOptions();
  void setMode(RagGalleryMode mode) => state = RagGalleryQueryOptions(
    mode: mode,
    image: mode == RagGalleryMode.parameters ? '' : state.image,
  );
  void setImage(String path) => state = RagGalleryQueryOptions(
    mode: state.mode == RagGalleryMode.parameters
        ? RagGalleryMode.visual
        : state.mode,
    image: path,
  );
  void clearImage() => state = RagGalleryQueryOptions(mode: state.mode);
}
