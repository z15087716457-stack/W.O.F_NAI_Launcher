import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:nai_launcher/l10n/app_localizations.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/image/image_params.dart';
import '../../../providers/image_generation_provider.dart';
import 'generation_param_sections.dart';

/// AI 参数二级菜单宿主（官网式）
///
/// 主生成页左栏与画风探索页主编辑区共用。[child] 是正常滚动的编辑内容；
/// AI 参数（种子/采样器/噪声调度/步数/CFG/CFG Rescale）作为抽屉悬浮其上：
/// 触发条钉在宿主底部常驻，点击后遮罩淡入、抽屉自底部滑出，
/// 点遮罩或再次点击箭头收起。
class GenerationParamsMenuHost extends ConsumerStatefulWidget {
  /// 抽屉下方的常驻内容（滚动编辑列），随宿主高度拉伸。
  final Widget child;

  /// 摘要条排版宽度下限：面板被挤窄时摘要条按此宽度排版并裁剪超出
  /// 部分，避免内部四列直接溢出报错；null = 不设下限。
  final double? summaryMinWidth;

  const GenerationParamsMenuHost({
    super.key,
    required this.child,
    this.summaryMinWidth,
  });

  @override
  ConsumerState<GenerationParamsMenuHost> createState() =>
      _GenerationParamsMenuHostState();
}

class _GenerationParamsMenuHostState
    extends ConsumerState<GenerationParamsMenuHost>
    with SingleTickerProviderStateMixin {
  /// 参数二级菜单是否挂载（动画收起完毕后卸载，瞬态不持久化）
  bool _paramsMenuMounted = false;

  late final AnimationController _menuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _menuAnimation = CurvedAnimation(
    parent: _menuController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<Offset> _menuSlide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(_menuAnimation);

  @override
  void initState() {
    super.initState();
    // 收起动画播完再卸载浮层
    _menuController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() => _paramsMenuMounted = false);
      }
    });
  }

  @override
  void dispose() {
    _menuAnimation.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _toggleParamsMenu() {
    final opening =
        _menuController.status == AnimationStatus.dismissed ||
        _menuController.status == AnimationStatus.reverse;
    if (opening) {
      setState(() => _paramsMenuMounted = true);
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _closeParamsMenu() {
    _menuController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // 编辑内容 + 参数抽屉浮层
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  widget.child,

                  // 参数二级菜单：遮罩淡入淡出 + 抽屉从触发条上方拉出
                  if (_paramsMenuMounted) ...[
                    Positioned.fill(
                      child: FadeTransition(
                        opacity: _menuAnimation,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _closeParamsMenu,
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRect(
                        child: SlideTransition(
                          position: _menuSlide,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight - 12,
                            ),
                            child: Material(
                              elevation: 8,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              color: theme.colorScheme.surface,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10),
                                  ),
                                  border: Border(
                                    top: BorderSide(color: theme.dividerColor),
                                    left: BorderSide(color: theme.dividerColor),
                                    right: BorderSide(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                ),
                                child: const SingleChildScrollView(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // 种子与采样器同行（官网 AI Settings 式）
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: SeedSection()),
                                          SizedBox(width: 10),
                                          Expanded(child: SamplerSection()),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      NoiseScheduleSection(),
                                      SizedBox(height: 10),
                                      StepsSection(),
                                      CfgScaleSection(),
                                      AdvancedSamplingOptions(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // 参数摘要条（官网式）：Steps/Guidance/Seed/Sampler 四列靠左常驻，
        // 右端右指箭头随抽屉开合旋转（收起朝右，展开朝上）
        LayoutBuilder(
          builder: (context, constraints) {
            final minWidth = widget.summaryMinWidth;
            final summaryBar = GenerationParamsSummaryBar(
              onToggleDrawer: _toggleParamsMenu,
              arrow: RotationTransition(
                turns: Tween<double>(
                  begin: 0,
                  end: -0.25,
                ).animate(_menuAnimation),
                child: const Icon(Icons.play_arrow, size: 20),
              ),
            );
            if (minWidth == null || constraints.maxWidth >= minWidth) {
              return summaryBar;
            }
            // 窄面板：摘要条按下限排版，超出右缘由 UnconstrainedBox 自带裁剪
            // （clipBehavior != none 时不弹 debug 溢出警告）
            return UnconstrainedBox(
              constrainedAxis: Axis.vertical,
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: minWidth, child: summaryBar),
            );
          },
        ),
      ],
    );
  }
}

/// 参数摘要条（官网式）：Steps / Guidance / Seed / Sampler 四列靠左常驻，
/// 上小标签下参数值；Steps/Guidance 纯展示，Seed 列点击 pin/unpin 随机种子，
/// Sampler 列点击从列上方弹出分组菜单，右端箭头点击展开/收起参数抽屉。
class GenerationParamsSummaryBar extends ConsumerWidget {
  final VoidCallback onToggleDrawer;
  final Widget arrow;

  const GenerationParamsSummaryBar({
    super.key,
    required this.onToggleDrawer,
    required this.arrow,
  });

  // 菜单项高度固定，锚定计算才有确定性
  static const double _menuItemHeight = 40;
  static const double _menuHeaderHeight = 26;
  static const double _menuVerticalPadding = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final params = ref.watch(generationParamsNotifierProvider);

    // 纯展示列（不可点）
    Widget column(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: _columnContent(theme, label, value),
    );

    // 可点列
    Widget tappableColumn(String label, Widget value, VoidCallback? onTap) =>
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              child: _columnContent(theme, label, value),
            ),
          ),
        );

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            column(l10n.generation_stepsLabel, Text(params.steps.toString())),
            Flexible(
              child: column(
                l10n.generation_guidance,
                Text(params.scale.toStringAsFixed(1)),
              ),
            ),
            tappableColumn(
              l10n.generation_seed,
              params.seed != -1
                  ? Text(params.seed.toString())
                  : SvgPicture.asset(
                      'assets/icons/nai-icon-seed.svg',
                      height: 14,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        BlendMode.srcIn,
                      ),
                    ),
              () {
                final notifier = ref.read(
                  generationParamsNotifierProvider.notifier,
                );
                if (params.seed != -1) {
                  notifier.randomizeSeed();
                } else {
                  notifier.pinRandomSeed();
                }
              },
            ),
            Expanded(
              child: Builder(
                builder: (buttonContext) => tappableColumn(
                  l10n.generation_sampler,
                  Text(
                    Samplers.samplerDisplayNames[params.sampler] ??
                        params.sampler,
                  ),
                  () =>
                      _showSamplerMenu(buttonContext, ref, theme, l10n, params),
                ),
              ),
            ),
            // 右端箭头同样开合抽屉（与官网一致）；GestureDetector 无 hover/涟漪装饰
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleDrawer,
                child: Padding(padding: const EdgeInsets.all(6), child: arrow),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _columnContent(ThemeData theme, String label, Widget value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        DefaultTextStyle(
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: value,
        ),
      ],
    );
  }

  /// 从采样器列上方弹出分组菜单（官网式：RECOMMENDED / OTHER）
  ///
  /// Flutter 的 showMenu 把菜单顶边对齐 position.top；把锚点顶边算成
  /// 「触发器顶 − 菜单高」，菜单即整体向上展开。
  void _showSamplerMenu(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    ImageParams params,
  ) {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final box = context.findRenderObject() as RenderBox;
    final triggerRect = box.localToGlobal(Offset.zero) & box.size;

    final samplers = Samplers.samplersForModel(params.model);
    final recommended = samplers
        .where((s) => Samplers.recommendedSamplers.contains(s))
        .toList();
    final others = samplers
        .where((s) => !Samplers.recommendedSamplers.contains(s))
        .toList();

    final menuHeight =
        _menuVerticalPadding * 2 +
        (recommended.isNotEmpty ? _menuHeaderHeight : 0) +
        (others.isNotEmpty ? _menuHeaderHeight : 0) +
        samplers.length * _menuItemHeight;
    // 菜单底边贴触发器顶边，向上展开；顶到屏幕边缘时由 _fitInsideScreen 兜底
    final menuTop = triggerRect.top - menuHeight - 2;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        triggerRect.left,
        menuTop,
        overlayBox.size.width - triggerRect.right,
        0,
      ),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      items: [
        if (recommended.isNotEmpty) ...[
          _menuHeader(theme, l10n.generation_samplerRecommended),
          for (final s in recommended) _menuItem(theme, s, params.sampler),
        ],
        if (others.isNotEmpty) ...[
          _menuHeader(theme, l10n.generation_samplerOther),
          for (final s in others) _menuItem(theme, s, params.sampler),
        ],
      ],
    ).then((value) {
      if (value != null) {
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updateSampler(value);
      }
    });
  }

  PopupMenuEntry<String> _menuHeader(ThemeData theme, String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: _menuHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  PopupMenuEntry<String> _menuItem(
    ThemeData theme,
    String sampler,
    String current,
  ) {
    return PopupMenuItem<String>(
      value: sampler,
      height: _menuItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: sampler == current
                ? theme.colorScheme.primary
                : Colors.transparent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              Samplers.samplerDisplayNames[sampler] ?? sampler,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
