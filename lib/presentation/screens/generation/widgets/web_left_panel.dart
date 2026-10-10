import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nai_launcher/core/utils/localization_extension.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../widgets/character/inline_character_section.dart';
import '../../../widgets/common/collapsible_image_panel.dart';
import 'collapsed_panel.dart';
import 'generation_controls/generation_controls.dart';
import 'generation_module_card.dart';
import 'generation_param_sections.dart';
import 'generation_params_menu_host.dart';
import 'generation_sidebar_style.dart';
import 'header_capsules.dart';
import 'img2img_panel.dart';
import 'precise_reference_panel.dart';
import 'prompt_input.dart';
import 'unified_reference_panel.dart';

/// 官网式布局左栏
///
/// 一体式滚动列，自上而下：提示词（随内容自由增高）→ 角色 →
/// 反推/图生图/风格迁移/精准参考 → 尺寸。
/// 模型选择常驻头部条（官网式）；AI 参数（种子/采样器/噪声调度/步数/CFG/
/// CFG Rescale）走 [GenerationParamsMenuHost] 的二级菜单抽屉。
class WebLeftPanel extends ConsumerWidget {
  final ValueNotifier<bool> negativeModeNotifier;
  final bool isResizing;

  const WebLeftPanel({
    super.key,
    required this.negativeModeNotifier,
    this.isResizing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ? _buildExpanded(context, theme, ref)
        : CollapsedPanel(
            icon: Icons.edit_note,
            label: context.l10n.generation_params,
            onTap: () => ref
                .read(layoutStateNotifierProvider.notifier)
                .setWebLeftPanelExpanded(true),
          );

    // 拖拽时不使用动画，避免粘滞感
    if (isResizing) {
      return Container(width: width, decoration: decoration, child: child);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: decoration,
      child: child,
    );
  }

  Widget _buildExpanded(BuildContext context, ThemeData theme, WidgetRef ref) {
    final showCharacters = ImageModels.isV4Model(
      ref.watch(
        generationParamsNotifierProvider.select((params) => params.model),
      ),
    );

    return Column(
      children: [
        // 头部条：折叠按钮钉右上角不移动；chips 宽时贴折叠按钮左侧，
        // 拖侧边收窄随折叠栏实时左移，放不下整条换到第二行靠左，
        // 底部分隔线始终横向贯通
        Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          // Stack 两行语义合一：
          //  - Wrap(spaceBetween) 两块原子换行：放得下时胶囊组钉最左、
          //    chips 推最右贴折叠按钮左缘，收窄随动；放不下 chips 整块
          //    落第二行靠左（无中间态）
          //  - 折叠按钮作为覆盖层永远钉右上角，不占任何一行
          child: Stack(
            children: [
              // SizedBox 撑满 Stack 宽 → Wrap 吃满面板宽，底部分隔线横向贯通
              const SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 2,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [ModelModeCapsule()],
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 36),
                      child: QuotaChipsCapsule(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CollapseButton(
                  icon: Icons.chevron_left,
                  onTap: () => ref
                      .read(layoutStateNotifierProvider.notifier)
                      .setWebLeftPanelExpanded(false),
                ),
              ),
            ],
          ),
        ),

        // 内容区 + 参数二级菜单浮层（抽屉自底部滑出，悬浮于滚动内容之上）
        Expanded(
          child: GenerationParamsMenuHost(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 提示词：随内容自由增高（官网式，视觉锚点置顶）
                  PromptInputWidget(
                    autoGrow: true,
                    showMaximizeButton: false,
                    negativeModeNotifier: negativeModeNotifier,
                  ),
                  const SizedBox(height: GenSidebarStyle.sectionGap),

                  // 角色区：内联在主提示词正下方（官网式，内容常显）
                  if (showCharacters) ...[
                    const InlineCharacterSection(),
                    const SizedBox(height: GenSidebarStyle.sectionGap),
                  ],
                  GenerationModuleCard(
                    title: context.l10n.generation_sectionReferenceImages,
                    children: const [
                      ReferenceModuleScope(
                        child: Column(
                          children: [
                            Img2ImgPanel(),
                            UnifiedReferencePanel(),
                            PreciseReferencePanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GenSidebarStyle.sectionGap),

                  GenerationModuleCard(
                    title: context.l10n.generation_moduleImage,
                    children: const [
                      SizeSection(layout: SizeSectionLayout.moduleRow),
                      ImageCountSection(
                        layout: ImageCountSectionLayout.moduleRow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
