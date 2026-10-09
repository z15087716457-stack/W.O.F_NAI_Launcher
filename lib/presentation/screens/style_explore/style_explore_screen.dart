import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/character_position_canvas_provider.dart';
import '../../providers/layout_state_provider.dart';
import '../../providers/style_explore/explore_manual_capture.dart';
import '../../providers/style_explore/explore_run_provider.dart';
import '../../providers/style_explore/explore_run_runner.dart';
import '../../providers/tips_provider.dart';
import '../../widgets/character/character_position_canvas.dart';
import '../../widgets/character/inline_character_section.dart';
import '../../widgets/common/collapsible_image_panel.dart';
import '../generation/widgets/block_library_panel_slot.dart';
import '../generation/widgets/generation_controls/generation_controls.dart';
import '../generation/widgets/generation_module_card.dart';
import '../generation/widgets/generation_param_sections.dart';
import '../generation/widgets/generation_params_menu_host.dart';
import '../generation/widgets/generation_sidebar_style.dart';
import '../generation/widgets/header_capsules.dart';
import '../generation/widgets/img2img_panel.dart';
import '../generation/widgets/precise_reference_panel.dart';
import '../generation/widgets/prompt_input.dart';
import '../generation/widgets/unified_reference_panel.dart';
import 'widgets/explore_candidate_gallery.dart';
import '../../providers/pill_workspace_provider.dart';
import '../../providers/prompt_block_library_provider.dart';
import 'widgets/explore_auto_run_name.dart';
import 'widgets/explore_icon.dart';
import 'widgets/explore_random_variables_module.dart';
import 'widgets/explore_run_actions.dart';
import 'widgets/explore_stage_header.dart';
import 'widgets/explore_workbench.dart';

/// Exploration workbench; editor and generation data remain shared.
class StyleExploreScreen extends ConsumerStatefulWidget {
  const StyleExploreScreen({super.key});

  @override
  ConsumerState<StyleExploreScreen> createState() => _StyleExploreScreenState();
}

class _StyleExploreScreenState extends ConsumerState<StyleExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final run = ref.watch(exploreActiveRunProvider);
    final busy =
        ref.watch(exploreRunRunnerProvider).isRunning ||
        ref.watch(imageGenerationNotifierProvider).isGenerating;
    final retryCount =
        !busy &&
            run != null &&
            (run.status == ExploreRunStatus.generated ||
                run.status == ExploreRunStatus.reviewing)
        ? run.failedCount
        : 0;

    // 探索页没有画布宿主（主页画布占图像预览区）：✥ 入口改走轻量弹窗。
    // 弹窗打开后 provider 再关（画布自带关闭按钮/再次点 ✥）由弹窗内
    // 监听同步收窗，见 _showPositionCanvasDialog。
    ref.listen(characterPositionCanvasProvider, (previous, next) {
      if (next && !(previous ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showPositionCanvasDialog());
        });
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ref.watch(layoutStateNotifierProvider);
          final notifier = ref.read(layoutStateNotifierProvider.notifier);
          return ExploreWorkbench(
            editorWidth: layout.styleExploreEditorWidth,
            inspectorWidth: layout.styleExploreInspectorWidth,
            inspectorVisible: layout.styleExploreInspectorVisible,
            onEditorResize: (dx) => notifier.setStyleExploreEditorWidth(
              ref.read(layoutStateNotifierProvider).styleExploreEditorWidth +
                  dx,
            ),
            onInspectorResize: (dx) => notifier.setStyleExploreInspectorWidth(
              ref.read(layoutStateNotifierProvider).styleExploreInspectorWidth +
                  dx,
            ),
            onCloseInspector: () =>
                notifier.setStyleExploreInspectorVisible(false),
            editor: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: LayoutBuilder(
                  builder: (context, box) =>
                      _buildCenterPanel(theme, availableWidth: box.maxWidth),
                ),
              ),
            ),
            stageBuilder: (context, inspectorVisible) => Column(
              children: [
                WindowHeader(
                  enabled: !inspectorVisible,
                  minimumInlineWidth: 520,
                  inlineDragWidth: 0,
                  dragBackground: true,
                  child: ExploreStageHeader(inspectorVisible: inspectorVisible),
                ),
                if (retryCount case final int count when count > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                      child: TextButton.icon(
                        key: const Key('explore-run-retry'),
                        onPressed: () {
                          final current = ref.read(exploreActiveRunProvider);
                          if (current != null) {
                            ExploreRunActions.retryFailed(
                              context,
                              ref,
                              current,
                            );
                          }
                        },
                        icon: ExploreIcon(
                          'swap',
                          size: 13,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          context.l10n.styleExplore_retryFailed(count),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                const Expanded(child: ExploreCandidateGallery()),
              ],
            ),
            inspector: _buildInspectorPlaceholder(theme),
            blockLibrary: layout.blockLibraryPanelExpanded
                ? const BlockLibraryPanelSlot(overlay: true)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildInspectorPlaceholder(ThemeData theme) => DecoratedBox(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      border: Border(left: BorderSide(color: theme.colorScheme.outlineVariant)),
    ),
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: WindowPanelHeader(
            headerHeight: 52,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.styleExplore_inspectorTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                context.l10n.styleExplore_inspectorPlaceholder,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  /// 头部胶囊行（官网式）：Model/Mode 合一胶囊居左，Opus/Anlas 额度胶囊居右；
  /// 宽度不足时余额胶囊整块落第二行靠左（与主生成页头部同款 Wrap 语义）。
  /// 低于排版下限时按 [editorWidth] 排版、超出部分裁掉（同滚动列保底）。
  Widget _buildCapsuleBar(ThemeData theme, {required double editorWidth}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: UnconstrainedBox(
        constrainedAxis: Axis.vertical,
        alignment: Alignment.centerLeft,
        // 自带裁剪并抑制 debug 溢出警告：窄面板时胶囊按下限排版裁右缘
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          // 16 = 本行 Container 的横向 padding，先扣掉再当排版宽度
          width: editorWidth - 16,
          child: const Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 2,
            spacing: 6,
            children: [ModelModeCapsule(), QuotaChipsCapsule()],
          ),
        ),
      ),
    );
  }

  // ==================== 主编辑区：主生成页左栏整套官网式装配（数据同源） ====================

  /// 编辑区排版宽度下限：窄侧栏挤压到放不下时按下限排版、超出右缘裁掉，
  /// 而不是在卡内溢出（与原 ParameterPanel 的 320 下限一致）。
  static const double _minEditorWidth = 320.0;

  /// 提示词=main/negative lane、参数=generationParamsNotifierProvider，
  /// 与主生成页实时同一份；胶囊行嵌主编辑区顶部；生成按钮走
  /// 主链 generate()（探索页入口在真实批次 start 前布防手动候选登记）。
  Widget _buildCenterPanel(ThemeData theme, {required double availableWidth}) {
    final showCharacters = ImageModels.isV4Model(
      ref.watch(
        generationParamsNotifierProvider.select((params) => params.model),
      ),
    );
    final manualCaptureNotifier = ref.read(
      exploreManualCaptureProvider.notifier,
    );

    final editorWidth = availableWidth < _minEditorWidth
        ? _minEditorWidth
        : availableWidth;

    return Column(
      children: [
        _buildCapsuleBar(theme, editorWidth: editorWidth),
        Expanded(
          child: GenerationParamsMenuHost(
            // 摘要条与滚动列共用一个排版下限（原 ParameterPanel 的 320）
            summaryMinWidth: _minEditorWidth,
            // 一体式滚动列（与主生成页左栏同款；生成数量只留请求次数
            // 步进——探索模式强制逐张出图，1–4 每次张数分段无意义）
            child: SingleChildScrollView(
              child: UnconstrainedBox(
                constrainedAxis: Axis.vertical,
                alignment: Alignment.topLeft,
                // 自带裁剪并抑制 debug 溢出警告（滚动视口也会裁右缘）
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: editorWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 提示词：随内容自由增高（官网式，视觉锚点置顶）
                        const PromptInputWidget(
                          autoGrow: true,
                          showMaximizeButton: false,
                          allowEvolutionToggle: true,
                          tipSurface: TipSurface.explorePrompt,
                        ),
                        const SizedBox(height: GenSidebarStyle.sectionGap),

                        const ExploreRandomVariablesModule(),
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
                              showPerRequestSegments: false,
                              exploreLabel: true,
                              layout: ImageCountSectionLayout.moduleRow,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: SizedBox(
            width: availableWidth,
            child: GenerationControls(
              // 主编辑区宽度有限，用紧凑钉底条（与主生成页左面板同款 2×2
              // 点数块布局），正常布局在此宽度会把点数 chips 压到重叠
              compact: true,
              exploreMode: true,
              // Opus/Anlas 芯片与自动保存都已上移到页面顶部，底栏不再渲染
              showBalanceChips: false,
              showAutoSaveChip: false,
              onBatchEvent: (event) => manualCaptureNotifier.handleBatchEvent(
                event,
                autoRunName: exploreAutoRunName(
                  document: ref
                      .read(pillWorkspaceProvider(PillScopes.main))
                      .document,
                  library: ref
                      .read(promptBlockLibraryNotifierProvider)
                      .valueOrNull,
                  l10n: context.l10n,
                ),
                activeRunId: ref.read(exploreActiveRunIdProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 位置画布轻量弹窗（探索页无画布宿主的替代入口）。
  ///
  /// 画布自带关闭按钮写 `provider.close()`，弹窗内监听其关闭同步收窗；
  /// 点外部/返回键关窗时反向收 provider，避免状态悬空（主页 ✥ 图标会
  /// 残留选中态）。
  Future<void> _showPositionCanvasDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            ref.listen(characterPositionCanvasProvider, (previous, next) {
              if (!next) Navigator.of(dialogContext).pop();
            });
            final screen = MediaQuery.sizeOf(context);
            return Dialog(
              child: SizedBox(
                width: screen.width * 0.6,
                height: screen.height * 0.85,
                child: const CharacterPositionCanvasView(),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (ref.read(characterPositionCanvasProvider)) {
      ref.read(characterPositionCanvasProvider.notifier).close();
    }
  }
}
