import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/model_display.dart';
import '../../../../core/constants/model_spec.dart';
import '../../../../data/models/image/image_params.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../widgets/anlas/anlas_balance_chip.dart';
import '../../../widgets/anlas/opus_usage_chip.dart';
import '../../../widgets/character/inline_character_section.dart';
import 'collapsed_panel.dart';
import 'generation_controls/generation_controls.dart';
import 'generation_param_sections.dart';
import 'img2img_panel.dart';
import 'precise_reference_panel.dart';
import 'prompt_input.dart';
import 'reverse_prompt_panel.dart';
import 'section_header.dart';
import 'unified_reference_panel.dart';

/// 官网式布局左栏
///
/// 一体式滚动列，自上而下：提示词（随内容自由增高）→ 角色 →
/// 反推/图生图/风格迁移/精准参考 → 尺寸。
/// 模型选择常驻头部条（官网式）；AI 参数（种子/采样器/噪声调度/步数/CFG/
/// CFG Rescale）是独立的二级菜单：触发条固定在钉底生成控制条上方，
/// 点击后面板向上弹出、悬浮于滚动内容之上（官网式，不与提示词等模块同层）。
class WebLeftPanel extends ConsumerStatefulWidget {
  final ValueNotifier<bool> negativeModeNotifier;
  final bool isResizing;

  const WebLeftPanel({
    super.key,
    required this.negativeModeNotifier,
    this.isResizing = false,
  });

  @override
  ConsumerState<WebLeftPanel> createState() => _WebLeftPanelState();
}

class _WebLeftPanelState extends ConsumerState<WebLeftPanel>
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
    final layoutState = ref.watch(layoutStateNotifierProvider);

    final width = layoutState.webLeftPanelExpanded
        ? layoutState.webLeftPanelWidth
        : 40.0;
    final decoration = BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
    );

    final child = layoutState.webLeftPanelExpanded
        ? _buildExpanded(context, theme)
        : CollapsedPanel(
            icon: Icons.edit_note,
            label: context.l10n.generation_params,
            onTap: () => ref
                .read(layoutStateNotifierProvider.notifier)
                .setWebLeftPanelExpanded(true),
          );

    // 拖拽时不使用动画，避免粘滞感
    if (widget.isResizing) {
      return Container(width: width, decoration: decoration, child: child);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: decoration,
      child: child,
    );
  }

  Widget _buildExpanded(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // 头部条：折叠按钮不悬浮，避免遮挡提示词工具栏
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              // 模型选择 + 模式胶囊常驻面板头部（官网式）：模型与模式一组，
              // Opus 额度与 Anlas 余额一组，组间拉开间隙（静定排版）
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ModelMenuButton(),
                        SizedBox(width: 6),
                        _ModeCapsule(),
                        SizedBox(width: 16),
                        OpusUsageChip(compact: true),
                        SizedBox(width: 6),
                        AnlasBalanceChip(compact: true),
                      ],
                    ),
                  ),
                ),
              ),
              CollapseButton(
                icon: Icons.chevron_left,
                onTap: () => ref
                    .read(layoutStateNotifierProvider.notifier)
                    .setWebLeftPanelExpanded(false),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // 内容区 + 参数二级菜单浮层
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // 一体式滚动列
                  // 用 SingleChildScrollView 而非 ListView：列内容有限，且需要
                  // 保持子项 State（撤销历史、面板展开态）不随滚动销毁
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 提示词：随内容自由增高（官网式，视觉锚点置顶）
                        PromptInputWidget(
                          autoGrow: true,
                          showMaximizeButton: false,
                          negativeModeNotifier: widget.negativeModeNotifier,
                        ),
                        const SizedBox(height: 10),

                        // 角色区：内联在主提示词正下方（官网式，内容常显）
                        const InlineCharacterSection(),
                        const SizedBox(height: 10),

                        // 功能面板：反推 / 图生图 / 风格迁移 / 精准参考
                        // （官网 Reference Images 小节）
                        SectionHeader(
                          title: context
                              .l10n.generation_sectionReferenceImages,
                        ),
                        const SizedBox(height: 6),
                        const ReversePromptPanel(),
                        const SizedBox(height: 8),
                        const Img2ImgPanel(),
                        const SizedBox(height: 8),
                        const UnifiedReferencePanel(),
                        const SizedBox(height: 8),
                        const PreciseReferencePanel(),
                        const SizedBox(height: 10),

                        // 尺寸/数量：低频控件下沉至滚动列末尾
                        // （官网 Image Settings 小节）
                        SectionHeader(
                          title: context.l10n.generation_sectionImageSettings,
                        ),
                        const SizedBox(height: 6),
                        const SizeSection(),
                        const SizedBox(height: 12),

                        // 生成数量：请求次数步进 + 每次张数分段（官网 Image
                        // Settings 式），与钉底生成按钮文案实时联动
                        const ImageCountSection(),
                      ],
                    ),
                  ),

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
        GenerationParamsSummaryBar(
          onToggleDrawer: _toggleParamsMenu,
          arrow: RotationTransition(
            turns: Tween<double>(begin: 0, end: -0.25)
                .animate(_menuAnimation),
            child: const Icon(Icons.play_arrow, size: 20),
          ),
        ),

        // 钉底生成控制条（压扁）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: const GenerationControls(
            compact: true,
            // Opus/Anlas 芯片已上移到头部条，底栏不再渲染
            showBalanceChips: false,
            // 自动保存开关挪到了历史面板标题栏
            showAutoSaveChip: false,
          ),
        ),
      ],
    );
  }
}

/// 头部条模型选择器：紧凑胶囊，点击弹分组卡式菜单切换模型（官网式：
/// NEW / LEGACY 两段，每项展示全名 + 简介行）
class _ModelMenuButton extends ConsumerWidget {
  const _ModelMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final model = ref.watch(
      generationParamsNotifierProvider.select((params) => params.model),
    );
    final shortName = ModelDisplay.shortNameOf(model);
    final fullName = ImageModels.modelDisplayNames[model] ?? model;

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        tooltip: fullName,
        offset: const Offset(0, 32),
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
        itemBuilder: (context) => [
          _modelGroupHeader(theme, l10n.generation_modelGroupNew),
          for (final m in ImageModels.allModels.where(
            (m) => ModelDisplay.groupOf(m) == ModelListGroup.newer,
          ))
            _modelMenuItem(context, l10n, theme, m, model),
          _modelGroupHeader(theme, l10n.generation_modelGroupLegacy),
          for (final m in ImageModels.allModels.where(
            (m) => ModelDisplay.groupOf(m) == ModelListGroup.legacy,
          ))
            _modelMenuItem(context, l10n, theme, m, model),
        ],
        onSelected: (value) {
          ref.read(generationParamsNotifierProvider.notifier).updateModel(value);
        },
        child: Container(
          height: 28,
          constraints: const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/novelai-icon.png',
                width: 15,
                height: 15,
                // 素材是纯黑剪影，srcIn 着色后深浅主题自适应
                color: theme.colorScheme.onSurface,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  shortName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuEntry<String> _modelGroupHeader(ThemeData theme, String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 26,
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

  PopupMenuEntry<String> _modelMenuItem(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String m,
    String current,
  ) {
    final fullName = ImageModels.modelDisplayNames[m] ?? m;
    final description = ModelDisplay.descriptionOf(l10n, m);
    return PopupMenuItem<String>(
      value: m,
      height: description != null ? 48 : 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: m == current
                ? theme.colorScheme.primary
                : Colors.transparent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ModelDisplay.isNewModel(m)) ...[
                      const SizedBox(width: 6),
                      Text(
                        l10n.generation_modelBadgeNew,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 头部条模式胶囊（官网 modelMode）：仅 V4+ 模型显示，
/// 点击在 Anime / Furry 间切换，furry 时向 v4_prompt.base_caption
/// 注入 `fur dataset, ` 前缀（与官网机制一致）。
class _ModeCapsule extends ConsumerWidget {
  const _ModeCapsule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final model = ref.watch(
      generationParamsNotifierProvider.select((params) => params.model),
    );
    // 模式切换只对 v4_prompt 结构有意义（V3 及以下无 base_caption）
    if (!ModelSpecs.of(model).v4Prompts) return const SizedBox.shrink();

    final furryMode = ref.watch(
      generationParamsNotifierProvider.select((params) => params.furryMode),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref
            .read(generationParamsNotifierProvider.notifier)
            .updateModelMode(!furryMode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.generation_modelMode,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 6),
              // 官网同款图标：anime=sakura 樱花 / furry=爪印
              SvgPicture.asset(
                furryMode
                    ? 'assets/icons/nai-icon-furry.svg'
                    : 'assets/icons/nai-icon-sakura.svg',
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                furryMode
                    ? l10n.generation_modeFurry
                    : l10n.generation_modeAnime,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
    Widget tappableColumn(
      String label,
      Widget value,
      VoidCallback? onTap,
    ) =>
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
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            column(
              l10n.generation_stepsLabel,
              Text(params.steps.toString()),
            ),
            column(
              l10n.generation_guidance,
              Text(params.scale.toStringAsFixed(1)),
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
                final notifier =
                    ref.read(generationParamsNotifierProvider.notifier);
                if (params.seed != -1) {
                  notifier.randomizeSeed();
                } else {
                  notifier.pinRandomSeed();
                }
              },
            ),
            Builder(
              builder: (buttonContext) => tappableColumn(
                l10n.generation_sampler,
                Text(
                  Samplers.samplerDisplayNames[params.sampler] ??
                      params.sampler,
                ),
                () => _showSamplerMenu(
                  buttonContext,
                  ref,
                  theme,
                  l10n,
                  params,
                ),
              ),
            ),
            const Spacer(),
            // 右端箭头同样开合抽屉（与官网一致）；GestureDetector 无 hover/涟漪装饰
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleDrawer,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: arrow,
                ),
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

    final menuHeight = _menuVerticalPadding * 2 +
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
