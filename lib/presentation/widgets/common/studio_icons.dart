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
  static const tagWiki = IconData(0xe918, fontFamily: _family);

  // Local gallery line icons: the prototype set, 1.7 stroke on a 24 grid.
  static const gallerySearch = IconData(0xe919, fontFamily: _family);
  static const galleryPlus = IconData(0xe91a, fontFamily: _family);
  static const galleryChevronRight = IconData(0xe91b, fontFamily: _family);
  static const galleryChevronDown = IconData(0xe91c, fontFamily: _family);
  static const galleryImage = IconData(0xe91d, fontFamily: _family);
  static const galleryHeart = IconData(0xe91e, fontFamily: _family);
  static const galleryHeartFilled = IconData(0xe91f, fontFamily: _family);
  static const galleryTrash = IconData(0xe920, fontFamily: _family);
  static const galleryCollection = IconData(0xe921, fontFamily: _family);
  static const galleryFolder = IconData(0xe922, fontFamily: _family);
  static const galleryCalendar = IconData(0xe923, fontFamily: _family);
  static const gallerySortDesc = IconData(0xe924, fontFamily: _family);
  static const gallerySortAsc = IconData(0xe925, fontFamily: _family);
  static const gallerySelect = IconData(0xe926, fontFamily: _family);
  static const galleryPanelRight = IconData(0xe927, fontFamily: _family);
  static const galleryPanelLeft = IconData(0xe928, fontFamily: _family);
  static const galleryMore = IconData(0xe929, fontFamily: _family);
  static const galleryCopy = IconData(0xe92a, fontFamily: _family);
  static const galleryClose = IconData(0xe92b, fontFamily: _family);
  static const galleryReveal = IconData(0xe92c, fontFamily: _family);
  static const galleryRefresh = IconData(0xe92d, fontFamily: _family);
  static const gallerySend = IconData(0xe92e, fontFamily: _family);
  static const galleryUpscale = IconData(0xe92f, fontFamily: _family);
  static const galleryBrush = IconData(0xe930, fontFamily: _family);
  static const galleryBookmarkAdd = IconData(0xe931, fontFamily: _family);
  static const galleryBookmarkRemove = IconData(0xe932, fontFamily: _family);
  static const gallerySpark = IconData(0xe933, fontFamily: _family);
  static const galleryCheck = IconData(0xe934, fontFamily: _family);
  static const galleryCheckBold = IconData(0xe935, fontFamily: _family);
  static const galleryMove = IconData(0xe936, fontFamily: _family);
  static const galleryArchive = IconData(0xe937, fontFamily: _family);
  static const galleryEdit = IconData(0xe938, fontFamily: _family);
  static const gallerySizeSmall = IconData(0xe939, fontFamily: _family);
  static const gallerySizeLarge = IconData(0xe93a, fontFamily: _family);
  static const galleryTag = IconData(0xe93b, fontFamily: _family);
  static const galleryUndo = IconData(0xe93c, fontFamily: _family);
  static const galleryRedo = IconData(0xe93d, fontFamily: _family);
  static const galleryImport = IconData(0xe93e, fontFamily: _family);
  static const galleryHash = IconData(0xe93f, fontFamily: _family);
  static const galleryFolderPlus = IconData(0xe940, fontFamily: _family);
  static const galleryFolderImport = IconData(0xe941, fontFamily: _family);
  static const galleryBox = IconData(0xe942, fontFamily: _family);
  static const galleryViewGrid = IconData(0xe943, fontFamily: _family);
  static const galleryViewMasonry = IconData(0xe944, fontFamily: _family);

  static bool supportsMotion(IconData icon) =>
      icon.fontFamily == _family &&
      icon.codePoint >= 0xe900 &&
      (icon.codePoint <= 0xe90d || icon == tagWiki);
}
