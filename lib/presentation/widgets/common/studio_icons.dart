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

  static const generation = IconData(0xe906, fontFamily: _family);
  static const localGallery = IconData(0xe907, fontFamily: _family);
  static const statistics = IconData(0xe908, fontFamily: _family);
  static const settings = IconData(0xe909, fontFamily: _family);
  static const promptBlockPalette = IconData(0xe90a, fontFamily: _family);

  // Reference-card feature marks have their own weight and silhouettes.
  static const imageToImage = IconData(0xe90b, fontFamily: _family);
  static const styleTransfer = IconData(0xe90c, fontFamily: _family);
  static const referenceFocus = IconData(0xe90d, fontFamily: _family);

  static const settingsAppearance = IconData(0xe90e, fontFamily: _family);
  static const settingsControls = IconData(0xe90f, fontFamily: _family);
  static const settingsGeneration = IconData(0xe910, fontFamily: _family);
  static const settingsStorage = IconData(0xe911, fontFamily: _family);
  static const settingsAccount = IconData(0xe912, fontFamily: _family);
  static const settingsModels = IconData(0xe913, fontFamily: _family);
  static const settingsIntegrations = IconData(0xe914, fontFamily: _family);
  static const settingsPrivacy = IconData(0xe915, fontFamily: _family);
  static const settingsAbout = IconData(0xe916, fontFamily: _family);
  static const settingsData = IconData(0xe917, fontFamily: _family);

  static bool supportsMotion(IconData icon) =>
      icon.fontFamily == _family &&
      icon.codePoint >= 0xe900 &&
      icon.codePoint <= 0xe90d;
}
