import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nai_launcher/core/utils/localization_extension.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../widgets/character/inline_character_section.dart';
import 'collapsed_panel.dart';
import 'generation_controls/generation_controls.dart';
import 'generation_param_sections.dart';
import 'img2img_panel.dart';
import 'precise_reference_panel.dart';
import 'prompt_input.dart';
import 'reverse_prompt_panel.dart';
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
              const SizedBox(width: 12),
              Icon(
                Icons.edit_note,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              // 模型选择常驻面板头部（官网式）：点击弹菜单切换
              const Expanded(child: _ModelMenuButton()),
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
                        const ReversePromptPanel(),
                        const SizedBox(height: 8),
                        const Img2ImgPanel(),
                        const SizedBox(height: 8),
                        const UnifiedReferencePanel(),
                        const SizedBox(height: 8),
                        const PreciseReferencePanel(),
                        const SizedBox(height: 10),

                        // 尺寸设置：低频控件下沉至滚动列末尾（官网 Layout A）
                        const SizeSection(),
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

        // 参数摘要条（官网式）：Steps/Guidance/Seed/Sampler 四列常驻，
        // 点列可交互，右端箭头随抽屉开合旋转
        GenerationParamsSummaryBar(
          onToggleDrawer: _toggleParamsMenu,
          arrow: RotationTransition(
            turns: Tween<double>(begin: 0, end: 0.5).animate(_menuAnimation),
            child: const Icon(Icons.keyboard_arrow_up, size: 20),
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
          child: const GenerationControls(compact: true),
        ),
      ],
    );
  }
}

/// 头部条模型选择器：紧凑胶囊，点击弹菜单切换模型
class _ModelMenuButton extends ConsumerWidget {
  const _ModelMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final model = ref.watch(
      generationParamsNotifierProvider.select((params) => params.model),
    );
    final modelName = ImageModels.modelDisplayNames[model] ?? model;

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        tooltip: modelName,
        offset: const Offset(0, 32),
        position: PopupMenuPosition.under,
        itemBuilder: (context) => [
          for (final m in ImageModels.allModels)
            PopupMenuItem<String>(
              value: m,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: m == model
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ImageModels.modelDisplayNames[m] ?? m,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
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
              Flexible(
                child: Text(
                  modelName,
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
}

/// 参数摘要条（官网式）：Steps / Guidance / Seed / Sampler 四列等宽常驻，
/// 上小标签下参数值；Seed 列点击固定↔随机切换，Sampler 列点击弹采样器菜单，
/// 其余区域点击展开/收起参数抽屉。
class GenerationParamsSummaryBar extends ConsumerWidget {
  final VoidCallback onToggleDrawer;
  final Widget arrow;

  const GenerationParamsSummaryBar({
    super.key,
    required this.onToggleDrawer,
    required this.arrow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // 锁标志在 storage 不在 state，select 元组在「锁定同值种子」时不重建会滞后；
    // 改 watch 整个 params——toggleSeedLock 每条路径都写新 state 实例，必重建。
    final params = ref.watch(generationParamsNotifierProvider);
    final isSeedLocked = ref
        .read(generationParamsNotifierProvider.notifier)
        .isSeedLocked;

    Widget buildColumn({
      required String label,
      required Widget value,
      VoidCallback? onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
            ),
          ),
        ),
      );
    }

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
            Expanded(
              child: buildColumn(
                label: l10n.generation_stepsLabel,
                value: Text(params.steps.toString()),
                onTap: onToggleDrawer,
              ),
            ),
            Expanded(
              child: buildColumn(
                label: l10n.generation_guidance,
                value: Text(params.scale.toStringAsFixed(1)),
                onTap: onToggleDrawer,
              ),
            ),
            Expanded(
              child: buildColumn(
                label: l10n.generation_seed,
                value: isSeedLocked && params.seed != -1
                    ? Text(params.seed.toString())
                    : Icon(
                        Icons.autorenew,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                onTap: () {
                  ref
                      .read(generationParamsNotifierProvider.notifier)
                      .toggleSeedLock();
                },
              ),
            ),
            Expanded(
              child: PopupMenuButton<String>(
                tooltip: Samplers.samplerDisplayNames[params.sampler] ??
                    params.sampler,
                offset: const Offset(0, -8),
                itemBuilder: (context) => [
                  for (final s in Samplers.allSamplers)
                    PopupMenuItem<String>(
                      value: s,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: s == params.sampler
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              Samplers.samplerDisplayNames[s] ?? s,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  ref
                      .read(generationParamsNotifierProvider.notifier)
                      .updateSampler(value);
                },
                child: _buildPopupColumn(
                  context,
                  theme,
                  label: l10n.generation_sampler,
                  value: Samplers.samplerDisplayNames[params.sampler] ??
                      params.sampler,
                ),
              ),
            ),
            arrow,
          ],
        ),
      ),
    );
  }

  /// PopupMenuButton 的 child 不吃 InkWell，单独用同版式渲染
  Widget _buildPopupColumn(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            value,
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
