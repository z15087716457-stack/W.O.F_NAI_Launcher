import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../providers/generation/generation_models.dart';
import '../screens/generation/widgets/generation_controls/generation_controls.dart';
import '../ui/explore/explore_contract.dart';
import '../ui/gen/gen_canvas.dart';
import '../ui/gen/gen_page.dart';
import '../ui/kit/ui_dialog.dart';
import '../ui/kit/ui_popover.dart';
import 'generation_wiring.dart';

/// 画风探索编辑列：直接用生图页的编辑列（顶栏胶囊、提示词、角色、参考图、图像、参数条），
/// 中间插“随机变量”，底部换成探索自己的生成条；数据和回调走生图页同一套接线。
class StyleExploreEditorWiring extends StatelessWidget {
  const StyleExploreEditorWiring({
    super.key,
    required this.parts,
    required this.controller,
    required this.onBatchEvent,
    required this.canGenerate,
  });
  final ExploreEditorParts parts;
  final GenerationControlsController controller;
  final GenerationBatchCallback onBatchEvent;
  final bool Function() canGenerate;

  @override
  Widget build(BuildContext context) => GenerationWiring(
    explore: true,
    builder: ({required data, required actions, required slots}) => GenHost(
      data: data,
      actions: actions,
      slots: slots,
      child: _PositionBoardHost(
        child: GenEditorColumn(
          afterPrompt: parts.randomVariables,
          showCount: false,
          collapsible: false,
          bottom: GenerationControls(
            controller: controller,
            compact: true,
            exploreMode: true,
            showBalanceChips: false,
            showAutoSaveChip: false,
            onBatchEvent: onBatchEvent,
            canGenerate: canGenerate,
            presentationBuilder: (context, state) => parts.generateBar,
          ),
        ),
      ),
    ),
  );
}

/// 角色“位置板”：生图页画在画布上，探索页没有画布，就用同一块板子开成弹窗；
/// 点“完成”、Esc 或点遮罩都收起。
class _PositionBoardHost extends StatelessWidget {
  const _PositionBoardHost({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context);
    final open = scope.data.canvas.positioning && scope.data.characters != null;
    return UiModal(
      dialog: open
          ? (context) {
              final size = MediaQuery.sizeOf(context);
              return GenScope(
                data: scope.data,
                actions: scope.actions,
                slots: scope.slots,
                controller: scope.controller,
                child: UiPopoverSurface(
                  key: const Key('explore-position-board'),
                  width: math.min(960, size.width * .7),
                  child: SizedBox(
                    height: size.height * .82,
                    child: const GenPositionBoard(),
                  ),
                ),
              );
            }
          : null,
      onDismiss: () => scope.actions.onPositioningChanged(false),
      child: child,
    );
  }
}
