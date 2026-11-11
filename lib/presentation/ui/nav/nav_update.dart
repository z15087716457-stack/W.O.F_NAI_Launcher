import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import 'nav_contract.dart';

extension NavUpdateLook on NavUpdateData {
  String title(BuildContext context) {
    final l = context.l10n;
    return switch (status) {
      NavUpdateStatus.available => l.updateAvailable,
      NavUpdateStatus.downloading => l.navShell_updateDownloading,
      NavUpdateStatus.downloaded =>
        manualReplace ? l.updateMacReveal : l.navShell_updateReady,
      NavUpdateStatus.installing => l.updateInstalling,
      NavUpdateStatus.downloadFailed => l.updateDownloadFailed,
      NavUpdateStatus.installFailed => l.updateInstallFailed,
    };
  }

  String subtitle(BuildContext context) {
    final l = context.l10n;
    if (failed) return l.navShell_updateRetryHint;
    if (status == NavUpdateStatus.downloading) {
      return l.navShell_updateDownloadProgress((progress * 100).round());
    }
    if (version == null) return l.updateViewDetails;
    return status == NavUpdateStatus.available
        ? l.navShell_updateAvailableVersion(version!)
        : l.navShell_updateReadyVersion(version!);
  }

  String tooltip(BuildContext context) {
    final label = status == NavUpdateStatus.downloading
        ? context.l10n.updateDownloadingProgress((progress * 100).round())
        : title(context);
    return version == null ? label : '$label · $version';
  }
}

/// 收起／展开共用一个 26px 图标；进度更新不改变按钮尺寸。
class NavUpdateGlyph extends StatelessWidget {
  const NavUpdateGlyph({
    super.key,
    required this.data,
    this.reducedMotion = false,
  });

  final NavUpdateData data;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final downloading = data.status == NavUpdateStatus.downloading;
    final installing = data.status == NavUpdateStatus.installing;
    final progress = downloading || installing;
    final reduce = reducedMotion || MediaQuery.disableAnimationsOf(context);
    final glyph = data.failed
        ? UiGlyphs.alert
        : data.status == NavUpdateStatus.available || downloading
        ? UiGlyphs.download
        : UiGlyphs.refresh;
    return Container(
      key: const Key('main-nav-update-glyph'),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: progress || data.failed ? null : c.brand,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (progress)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: downloading
                    ? data.progress
                    : reduce
                    ? .75
                    : null,
                strokeWidth: 2,
                color: c.accent,
                backgroundColor: c.accent.withValues(alpha: .2),
              ),
            ),
          UiGlyph(
            glyph,
            size: 16,
            color: data.failed
                ? c.error
                : progress
                ? c.accent
                : c.onBrand,
          ),
        ],
      ),
    );
  }
}
