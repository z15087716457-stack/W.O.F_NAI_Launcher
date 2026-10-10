import 'dart:async';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/character_position_canvas_provider.dart';
import '../../providers/layout_state_provider.dart';
import '../../providers/pill_workspace_provider.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../providers/style_explore/explore_manual_capture.dart';
import '../../providers/style_explore/explore_run_provider.dart';
import '../../widgets/character/character_position_canvas.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../generation/widgets/block_library_panel_slot.dart';
import '../generation/widgets/generation_controls/generation_controls.dart';
import 'actions/explore_auto_run_name.dart';
import 'ui/explore_candidate_wall.dart';
import 'ui/explore_editor.dart';
import 'ui/explore_inspector.dart';
import 'ui/explore_stage_header.dart';
import 'ui/explore_workbench.dart';

class StyleExploreScreen extends ConsumerStatefulWidget {
  const StyleExploreScreen({super.key});
  @override
  ConsumerState<StyleExploreScreen> createState() => _StyleExploreScreenState();
}

class _StyleExploreScreenState extends ConsumerState<StyleExploreScreen> {
  final _generationControls = GenerationControlsController();
  final _runMenu = MenuController();
  @override
  void dispose() {
    _generationControls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(characterPositionCanvasProvider, (previous, next) {
      if (next && !(previous ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showPositionCanvasDialog());
        });
      }
    });
    final layout = ref.watch(layoutStateNotifierProvider);
    final notifier = ref.read(layoutStateNotifierProvider.notifier);
    final run = ref.watch(exploreActiveRunProvider);
    return Scaffold(
      body: ExploreWorkbench(
        editorWidth: layout.styleExploreEditorWidth,
        inspectorWidth: layout.styleExploreInspectorWidth,
        inspectorVisible:
            layout.styleExploreInspectorVisible ??
            (run == null ||
                    run.candidates.isEmpty ||
                    MediaQuery.sizeOf(context).width <= 1280
                ? false
                : null),
        onEditorResize: (dx) => notifier.setStyleExploreEditorWidth(
          ref.read(layoutStateNotifierProvider).styleExploreEditorWidth + dx,
        ),
        onInspectorResize: (dx) => notifier.setStyleExploreInspectorWidth(
          ref.read(layoutStateNotifierProvider).styleExploreInspectorWidth + dx,
        ),
        onCloseInspector: () => notifier.setStyleExploreInspectorVisible(false),
        editor: ExploreEditor(
          controller: _generationControls,
          onBatchEvent: (event) => ref
              .read(exploreManualCaptureProvider.notifier)
              .handleBatchEvent(
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
        stageBuilder: (context, visible) {
          final empty = run == null && !visible;
          final stageHeader = ExploreStageHeader(
            inspectorVisible: visible,
            runMenuController: _runMenu,
          );
          final header = WindowHeader(
            enabled: !visible,
            minimumInlineWidth: 520,
            inlineDragWidth: 0,
            dragBackground: true,
            // Keep the menu anchor mounted when an empty run is created, so
            // inline naming survives. The onboarding footer opens this menu.
            child: IgnorePointer(
              ignoring: empty,
              child: Opacity(opacity: empty ? 0 : 1, child: stageHeader),
            ),
          );
          final wall = ExploreCandidateWall(
            onGenerate: _generationControls.generate,
            onOpenPrevious: _runMenu.open,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: empty ? 0 : 52,
                left: 0,
                right: 0,
                bottom: 0,
                child: wall,
              ),
              Positioned(top: 0, left: 0, right: 0, child: header),
            ],
          );
        },
        inspector: const ExploreInspector(),
        blockLibrary: layout.blockLibraryPanelExpanded
            ? const BlockLibraryPanelSlot(overlay: true)
            : null,
      ),
    );
  }

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
