import 'package:flutter/widgets.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import 'nav_contract.dart';

/// 页面的图标和名字。图标沿用 StudioIcons（本地 / 在线画廊、Vibe / 精准参考是故意成对设计的）。
extension NavPageLook on NavPage {
  IconData get icon => switch (this) {
    NavPage.generation => StudioIcons.generation,
    NavPage.styleExplore => StudioIcons.styleExplore,
    NavPage.localGallery => StudioIcons.localGallery,
    NavPage.onlineGallery => StudioIcons.onlineGallery,
    NavPage.promptBlocks => StudioIcons.promptBlocks,
    NavPage.vibeLibrary => StudioIcons.vibeLibrary,
    NavPage.preciseRef => StudioIcons.preciseReference,
    NavPage.tagWiki => StudioIcons.tagWiki,
    NavPage.statistics => StudioIcons.statistics,
    NavPage.settings => StudioIcons.settings,
  };

  String label(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      NavPage.generation => l.navShell_page_generation,
      NavPage.styleExplore => l.navShell_page_styleExplore,
      NavPage.localGallery => l.navShell_page_localGallery,
      NavPage.onlineGallery => l.navShell_page_onlineGallery,
      NavPage.promptBlocks => l.navShell_page_promptBlocks,
      NavPage.vibeLibrary => l.navShell_page_vibeLibrary,
      NavPage.preciseRef => l.navShell_page_preciseRef,
      NavPage.tagWiki => l.navShell_page_tagWiki,
      NavPage.statistics => l.navShell_page_statistics,
      NavPage.settings => l.navShell_page_settings,
    };
  }
}

String navGroupLabel(BuildContext context, int group) {
  final l = context.l10n;
  return switch (group) {
    0 => l.navShell_group_create,
    1 => l.navShell_group_gallery,
    2 => l.navShell_group_assets,
    _ => l.navShell_group_tools,
  };
}

extension NavTaskLook on NavTaskKind {
  IconData get icon => switch (this) {
    NavTaskKind.localUpscale ||
    NavTaskKind.cloudUpscale => StudioIcons.galleryUpscale,
    NavTaskKind.bulkDelete => StudioIcons.galleryTrash,
    NavTaskKind.bulkExport => StudioIcons.galleryImport,
    NavTaskKind.bulkMetadata => StudioIcons.galleryEdit,
    NavTaskKind.bulkAddToCollection ||
    NavTaskKind.bulkRemoveFromCollection => StudioIcons.galleryCollection,
    NavTaskKind.bulkFavorite => StudioIcons.galleryHeart,
  };

  String label(BuildContext context) {
    final l = context.l10n;
    return switch (this) {
      NavTaskKind.localUpscale => l.navShell_task_localUpscale,
      NavTaskKind.cloudUpscale => l.navShell_task_cloudUpscale,
      NavTaskKind.bulkDelete => l.navShell_task_bulkDelete,
      NavTaskKind.bulkExport => l.navShell_task_bulkExport,
      NavTaskKind.bulkMetadata => l.navShell_task_bulkMetadata,
      NavTaskKind.bulkAddToCollection => l.navShell_task_bulkAddToCollection,
      NavTaskKind.bulkRemoveFromCollection =>
        l.navShell_task_bulkRemoveFromCollection,
      NavTaskKind.bulkFavorite => l.navShell_task_bulkFavorite,
    };
  }
}

extension NavViewDataX on NavViewData {
  /// 导航栏上实际显示的分组：去掉隐藏页（当前页除外），空组整组去掉。
  List<List<NavPage>> get visibleGroups => [
    for (final g in navGroups)
      if (g.where(isVisible).toList() case final v when v.isNotEmpty) v,
  ];

  bool isVisible(NavPage p) =>
      navLockedPages.contains(p) || !hidden.contains(p) || p == current;

  /// 按住 Ctrl 时的编号：只有“Ctrl + 单个键”的绑定才有。
  String? ctrlNumber(NavPage p) {
    final keys = shortcuts[p];
    if (keys == null || keys.length != 2) return null;
    return keys.first.toLowerCase() == 'ctrl' ? keys.last : null;
  }

  /// 正在跑的任务数（含正在生成）。
  int get runningTasks =>
      tasks.where((t) => !t.finished).length +
      (generation.state == NavGenerationState.running ? 1 : 0);
}

extension NavGenerationX on NavGeneration {
  /// 进度圈：当前这一张的进度；没有就按张数估。
  double get ringFraction =>
      (progress ?? (total > 0 ? (current - 1).clamp(0, total) / total : 0))
          .clamp(0.0, 1.0)
          .toDouble();
}

extension NavTaskX on NavTask {
  double? get resolvedFraction =>
      fraction ??
      (done != null && total != null && total! > 0 ? done! / total! : null);
}
