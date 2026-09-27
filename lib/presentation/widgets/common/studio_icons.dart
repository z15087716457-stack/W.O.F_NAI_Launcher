import 'package:flutter/material.dart';

/// Semantic feature icons shared by navigation, menus, titles and inline blocks.
/// SVG masters and font builder: tool/branding/studio_icons/.
abstract final class StudioIcons {
  static const _family = 'StudioIcons';

  static const styleExplore = IconData(0xe900, fontFamily: _family);
  static const inherit = IconData(0xe901, fontFamily: _family);
  static const onlineGallery = IconData(0xe902, fontFamily: _family);
  static const promptBlocks = IconData(0xe903, fontFamily: _family);
  static const preciseReference = IconData(0xe904, fontFamily: _family);
  static const vibeLibrary = IconData(0xe905, fontFamily: _family);

  // The former online-gallery symbol now identifies the local image library.
  static const localGallery = Icons.photo_library;
}
