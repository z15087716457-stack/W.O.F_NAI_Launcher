import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_version.dart';
import '../../../core/services/titlebar_region_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/theme_provider.dart';
import '../../themes/studio_typography.dart';
import '../auth/entry_controls.dart';
import '../navigation/integrated_title_bar.dart';
import 'entry_field.dart';

/// The complete, original wordmark. The asset only removes empty source margins;
/// both the W.O.F block and the NAI STUDIO signature remain in their original ratio.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 360});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/wof_logo_full.png',
    width: width,
    height: width * 547 / 1111,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'W.O.F NAI Studio',
  );
}

/// 登录与载入共用的整页场景。
///
/// 背景是「去噪」字符场 [EntryField]；Logo 与标语固定在同一高度（只随
/// 窗口高度变化），下方挂载入进度或登录卡片，所以载入页换成登录页时
/// Logo 不动、背景接着走，只有下面的内容淡入替换。页脚左侧是客户端
/// 说明，右侧是种子 / 去噪步数与版本号。
class BrandEntryScene extends ConsumerStatefulWidget {
  const BrandEntryScene({
    super.key,
    required this.child,
    this.loading = false,
    this.progress = 0,
    this.busy = false,
  });

  final Widget child;

  /// 载入页：背景随 [progress] 去噪，不穿插解码事件。
  final bool loading;
  final double progress;

  /// 登录中：背景加速去噪。
  final bool busy;

  /// 卡片与进度区的最大宽度。
  static const double panelWidth = 380;

  @override
  ConsumerState<BrandEntryScene> createState() => _BrandEntrySceneState();
}

class _BrandEntrySceneState extends ConsumerState<BrandEntryScene> {
  final _heroKey = GlobalKey();
  final _pointer = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = EntryPalette.of(context);
    final chromeInBar = TitleBarRegionService.isSupported;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        onHover: (event) => _pointer.value = event.localPosition,
        onExit: (_) => _pointer.value = null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            // 以整窗高度排版，Logo 在载入页和登录页落在同一处
            final windowHeight =
                height + (chromeInBar ? IntegratedTitleBarShell.barHeight : 0);
            final logoWidth = math.max(
              180.0,
              math.min(300.0, math.min(width - 96, (windowHeight - 80) * 0.36)),
            );
            final top = math.max(20.0, (windowHeight - 36 - 44 - 640) * 0.42);
            return Stack(
              children: [
                Positioned.fill(
                  child: EntryField(
                    signal: widget.loading ? widget.progress : 0,
                    ambient: !widget.loading,
                    busy: widget.busy,
                    clearKey: _heroKey,
                    pointer: _pointer,
                  ),
                ),
                Positioned.fill(
                  bottom: 44,
                  child: SingleChildScrollView(
                    key: const Key('brand_entry_scroll'),
                    padding: EdgeInsets.fromLTRB(16, top, 16, 40),
                    child: Center(
                      child: Column(
                        key: _heroKey,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BrandLogo(width: logoWidth),
                          const SizedBox(height: 18),
                          Text(
                            context.l10n.brand_entryTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 2.6,
                              color: palette.muted,
                            ),
                          ),
                          const SizedBox(height: 36),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.min(
                                BrandEntryScene.panelWidth,
                                width - 32,
                              ),
                            ),
                            child: widget.child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 0,
                  height: 44,
                  child: IgnorePointer(
                    child: _Footer(
                      loading: widget.loading,
                      busy: widget.busy,
                      progress: widget.progress,
                    ),
                  ),
                ),
                // 非 Windows 没有自绘标题栏，明暗切换放回页面右上角
                if (!chromeInBar)
                  Positioned(
                    top: 8,
                    right: 12,
                    child: IconButton(
                      key: const Key('brand_appearance_toggle'),
                      tooltip: palette.dark
                          ? context.l10n.brand_switchToLight
                          : context.l10n.brand_switchToDark,
                      onPressed: () =>
                          ref.read(themeNotifierProvider.notifier).nextTheme(),
                      icon: Icon(
                        palette.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.busy,
    required this.progress,
  });

  final bool loading;
  final bool busy;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final hud = StudioTypography.data.copyWith(
      fontSize: 10.5,
      letterSpacing: 0.84,
      color: palette.faint,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.app_subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: palette.faint),
          ),
        ),
        const SizedBox(width: 12),
        ExcludeSemantics(
          child: ListenableBuilder(
            listenable: Listenable.merge([EntryField.seed, EntryField.level]),
            builder: (context, _) {
              final denoising = loading || busy;
              final level = loading ? progress : EntryField.level.value;
              final step = (level.clamp(0.0, 1.0) * 28).round();
              return Text.rich(
                TextSpan(
                  children: [
                    if (denoising) ...[
                      TextSpan(
                        text: 'DENOISE  ',
                        style: TextStyle(color: palette.muted),
                      ),
                      TextSpan(
                        text: 'STEP ${step.toString().padLeft(2, '0')}/28  ·  ',
                      ),
                    ],
                    TextSpan(text: 'SEED ${EntryField.seed.value}  ·  '),
                    TextSpan(text: 'v${AppVersion.versionName}'),
                  ],
                ),
                style: hud,
              );
            },
          ),
        ),
      ],
    );
  }
}
