import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/viewer/viewer_contract.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import 'image_viewer_backend.dart';

final imageViewerSessionProvider = StateProvider<ImageViewerSession?>(
  (ref) => null,
);
final imageViewerWindowProvider =
    StateProvider<({bool fullscreen, bool captionOverStage})>(
      (ref) => (fullscreen: false, captionOverStage: false),
    );

class ImageViewerSession {
  ImageViewerSession({
    required this.backend,
    required this.mode,
    this.scope,
    this.save,
    this.dimensions = const {},
    this.dates = const {},
  });
  final ImageViewerBackend backend;
  final ViewerMode mode;
  final ViewerScope? scope;
  final Future<void> Function(ImageDetailData)? save;
  final Map<String, ({int width, int height})> dimensions;
  final Map<String, DateTime> dates;
  final done = Completer<void>();
}
