import 'package:flutter/material.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import '../../../navigation/window_chrome_layout.dart';
import 'viewer_icon.dart';
import 'viewer_stage.dart';

class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.position,
    this.leading,
    this.trailing,
    this.onZoomOut,
    this.onZoomIn,
    this.onOriginalSize,
    this.onFullscreen,
    this.onTogglePanel,
    this.panelVisible = true,
    this.showZoom = true,
    this.showOriginalSize = true,
    this.showFullscreen = true,
    this.showPanelToggle = true,
    this.reserveWindowButtons = true,
    this.zoomLabel,
  });
  final String backLabel;
  final VoidCallback onBack;
  final Widget? position, leading, trailing;
  final VoidCallback? onZoomOut,
      onZoomIn,
      onOriginalSize,
      onFullscreen,
      onTogglePanel;
  final bool panelVisible,
      showZoom,
      showOriginalSize,
      showFullscreen,
      showPanelToggle,
      reserveWindowButtons;
  final String? zoomLabel;
  static final ink = Colors.white.withValues(alpha: .92);
  static final mono = TextStyle(
    fontFamily: 'Geist Mono',
    fontFamilyFallback: const ['HarmonyOS Sans SC', 'Pretendard'],
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.72),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    height: ViewerStage.topBarHeight,
    child: WindowPaneInset(
      enabled: reserveWindowButtons,
      horizontal: true,
      child: SizedBox(
        height: ViewerStage.topBarHeight,
        child: LayoutBuilder(
          builder: (context, box) => Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: InkWell(
                    key: const Key('viewer-back'),
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      height: 30,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ViewerIcon('arrL', size: 15, color: ink),
                            const SizedBox(width: 6),
                            Text(
                              backLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Esc',
                                  style: TextStyle(
                                    fontFamily: 'Geist Mono',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _divider(14),
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Expanded(
                  child: box.maxWidth > 600 && position != null
                      ? DefaultTextStyle(
                          style: mono,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: position!,
                        )
                      : const SizedBox.shrink(),
                ),
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                if (showZoom && box.maxWidth > 450) ...[
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _button(
                          context.l10n.shortcut_action_zoom_out,
                          'min',
                          onZoomOut,
                          size: 14,
                          key: const Key('viewer-zoom-out'),
                        ),
                        Container(
                          height: 28,
                          constraints: const BoxConstraints(minWidth: 74),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                zoomLabel ?? context.l10n.viewer_fit,
                                style: mono.copyWith(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const ViewerIcon('chevD', size: 12),
                            ],
                          ),
                        ),
                        _button(
                          context.l10n.shortcut_action_zoom_in,
                          'plus',
                          onZoomIn,
                          size: 14,
                          key: const Key('viewer-zoom-in'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (showOriginalSize && box.maxWidth > 450) ...[
                  Tooltip(
                    message: context.l10n.viewer_originalSize,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('viewer-original-size'),
                        onTap: onOriginalSize,
                        borderRadius: BorderRadius.circular(7),
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: Center(
                            child: Text(
                              '1:1',
                              style: mono.copyWith(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _divider(10),
                ],
                if (showFullscreen) ...[
                  _button(
                    context.l10n.viewer_fullscreen,
                    'full',
                    onFullscreen,
                    key: const Key('viewer-fullscreen'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (showPanelToggle)
                  _button(
                    panelVisible
                        ? context.l10n.viewer_hideInfo
                        : context.l10n.viewer_showInfo,
                    'panel',
                    onTogglePanel,
                    selected: panelVisible,
                    key: const Key('viewer-toggle-panel'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  static Widget _divider(double gap) => Padding(
    padding: EdgeInsets.symmetric(horizontal: gap / 2),
    child: SizedBox(
      width: 1,
      height: 18,
      child: ColoredBox(color: Colors.white.withValues(alpha: 0.1)),
    ),
  );
  static Widget _button(
    String label,
    String icon,
    VoidCallback? action, {
    Key? key,
    bool selected = false,
    double size = 16,
  }) => Tooltip(
    message: label,
    child: Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        key: key,
        onTap: action,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: ViewerIcon(
              icon,
              size: size,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    ),
  );
}
