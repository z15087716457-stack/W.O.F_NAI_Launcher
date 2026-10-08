import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_position_canvas_provider.dart';
import '../../providers/character_prompt_provider.dart';
import '../../providers/generation/generation_params_selectors.dart';
import '../../providers/generation/preview_selection_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../screens/generation/widgets/generation_sidebar_style.dart';
import '../../screens/generation/widgets/generation_module_card.dart';
import '../common/decoded_memory_image.dart';

/// 芯片显示信息：性别符号 + 显示名
typedef CharacterChipDisplay = ({IconData? genderIcon, String? label});

/// 名称只来自用户命名；未命名时显示编号和类型图标，不提取提示词。
CharacterChipDisplay resolveCharacterChipDisplay(CharacterPrompt character) {
  final genderIcon = switch (character.effectiveGender) {
    CharacterGender.female => Icons.female,
    CharacterGender.male => Icons.male,
    CharacterGender.other => Icons.circle_outlined,
  };
  final name = character.customName;
  return (genderIcon: genderIcon, label: name.isEmpty ? null : name);
}

/// 角色位置画布
///
/// 占据图像预览区：在当前预览图（或按生成参数宽高比的空底）上
/// 直接拖动角色锚点设置构图位置。坐标连续生效（0-1 百分比），
/// 拖到哪 API 就收到哪，无格线、无量化。
///
/// - 顶部选择角色，右下角完成退出
/// - 芯片条：每个角色一个切换芯片，点击选中（与角色卡编辑态联动）
/// - AI 选择模式：锚点隐藏，位置数据保留，切回自定义原样恢复
class CharacterPositionCanvasView extends ConsumerStatefulWidget {
  const CharacterPositionCanvasView({super.key});

  @override
  ConsumerState<CharacterPositionCanvasView> createState() =>
      _CharacterPositionCanvasViewState();
}

class _CharacterPositionCanvasViewState
    extends ConsumerState<CharacterPositionCanvasView> {
  /// 拖动中的角色与本地坐标（松手才写入 provider，避免高频写盘）
  String? _draggingId;
  double _dragRow = 0.5;
  double _dragColumn = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(characterPromptNotifierProvider);
    final characters = config.characters;
    final selectedId = ref.watch(selectedCharacterIdProvider);

    return Column(
      children: [
        if (characters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: _ChipBar(characters: characters, selectedId: selectedId),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Center(child: _buildCanvas(context, theme, l10n, config)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  config.globalAiChoice
                      ? l10n.characterCanvas_aiHint
                      : l10n.characterCanvas_dragHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const ValueKey('finish-character-positions'),
                onPressed: () =>
                    ref.read(characterPositionCanvasProvider.notifier).close(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: Text(l10n.characterCanvas_finishEditing),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 画布 ====================

  Widget _buildCanvas(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    CharacterPromptConfig config,
  ) {
    final colorScheme = theme.colorScheme;
    final generationState = ref.watch(imageGenerationNotifierProvider);
    final previewDimensions = ref.watch(
      generationParamsNotifierProvider.select(selectPreviewDimensionsViewData),
    );

    final selectedImageId = ref.watch(generationPreviewSelectionProvider);
    final backgroundImage =
        generationState.findImageById(selectedImageId) ??
        generationState.displayImages.firstOrNull;
    final aspectRatio =
        backgroundImage?.aspectRatio ??
        previewDimensions.width / previewDimensions.height;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        key: const ValueKey('character-position-surface'),
        borderRadius: BorderRadius.circular(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (backgroundImage != null) ...[
                  DecodedMemoryImage(
                    bytes: backgroundImage.bytes,
                    fit: BoxFit.cover,
                    maxLogicalWidth: size.width,
                    maxLogicalHeight: size.height,
                    gaplessPlayback: true,
                  ),
                  // 只压暗定位背景；编号锚点在遮罩上方保持明亮。
                  const ColoredBox(
                    key: ValueKey('character-position-dim'),
                    color: Color(0xA6000000),
                  ),
                ] else
                  Container(
                    decoration: BoxDecoration(
                      color: GenSidebarStyle.promptSurface(theme),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                if (config.globalAiChoice)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.characterCanvas_aiHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else ...[
                  for (var i = 0; i < config.characters.length; i++)
                    _buildAnchor(
                      context,
                      config,
                      config.characters[i],
                      i,
                      size,
                    ),
                  // 浮签独立成层且始终位于列表尾部：拖动开始时插入它
                  // 不会挤动锚点的 Element 位置（锚点手势不被打断）
                  if (_draggingId != null) _buildDragLabel(size),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// 锚点显示坐标：拖动中用本地值，否则使用与请求层一致的有效位置。
  ({double row, double column}) _anchorPosition(
    CharacterPromptConfig config,
    CharacterPrompt character,
  ) {
    if (_draggingId == character.id) {
      return (row: _dragRow, column: _dragColumn);
    }
    final position = config.resolvePosition(character);
    return (row: position.row, column: position.column);
  }

  /// 拖动中的坐标浮签（独立于锚点渲染，避免打断手势）
  Widget _buildDragLabel(Size canvasSize) {
    final centerX = _dragColumn * canvasSize.width;
    final centerY = _dragRow * canvasSize.height;

    return Positioned(
      key: const ValueKey('canvas-drag-label'),
      left: (centerX - 40).clamp(0.0, math.max(0.0, canvasSize.width - 80)),
      top: (centerY - 50).clamp(0.0, math.max(0.0, canvasSize.height - 22)),
      child: IgnorePointer(
        child: Container(
          width: 80,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(_dragColumn * 100).round()}% , '
            '${(_dragRow * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildAnchor(
    BuildContext context,
    CharacterPromptConfig config,
    CharacterPrompt character,
    int index,
    Size canvasSize,
  ) {
    final selectedId = ref.watch(selectedCharacterIdProvider);
    final isSelected = selectedId == character.id;
    final isDragging = _draggingId == character.id;
    final position = _anchorPosition(config, character);
    const diameter = 28.0;
    final centerX = position.column * canvasSize.width;
    final centerY = position.row * canvasSize.height;

    // 稳定 key：选中/拖动引发的重建不丢失 Element，
    // 进行中的 pan 手势识别器得以存活，按下即可直接拖动
    return Positioned(
      key: ValueKey('canvas-anchor-${character.id}'),
      left: centerX - diameter / 2,
      top: centerY - diameter / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            ref.read(selectedCharacterIdProvider.notifier).select(character.id),
        onPanStart: (_) {
          ref.read(selectedCharacterIdProvider.notifier).select(character.id);
          setState(() {
            _draggingId = character.id;
            _dragRow = position.row;
            _dragColumn = position.column;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _dragColumn = (_dragColumn + details.delta.dx / canvasSize.width)
                .clamp(0.0, 1.0);
            _dragRow = (_dragRow + details.delta.dy / canvasSize.height).clamp(
              0.0,
              1.0,
            );
          });
        },
        onPanEnd: (_) => _commitDrag(character),
        onPanCancel: () => _commitDrag(character),
        child: _AnchorDot(
          character: character,
          index: index,
          diameter: diameter,
          emphasized: isSelected || isDragging,
        ),
      ),
    );
  }

  void _commitDrag(CharacterPrompt character) {
    if (_draggingId != character.id) return;
    // A prompt/name may have changed while dragging; commit only coordinates
    // against the current character rather than restoring a stale snapshot.
    final current = ref
        .read(characterPromptNotifierProvider)
        .characters
        .where((item) => item.id == character.id)
        .firstOrNull;
    if (current == null) {
      setState(() => _draggingId = null);
      return;
    }
    ref
        .read(characterPromptNotifierProvider.notifier)
        .updateCharacter(
          current.copyWith(
            positionMode: CharacterPositionMode.custom,
            customPosition: CharacterPosition(
              mode: CharacterPositionMode.custom,
              row: _dragRow,
              column: _dragColumn,
            ),
          ),
        );
    setState(() => _draggingId = null);
  }
}

/// 位置模式分段（AI 选择 / 自定义 / 画布入口）
///
/// 绑定全局 globalAiChoice，常驻在角色模块头部。
/// 「自定义」右侧的图标是位置画布的唯一入口（官网同款布局）。
class CharacterPositionModeSegments extends ConsumerWidget {
  const CharacterPositionModeSegments({
    super.key,
    this.expanded = false,
    this.moduleHeader = false,
  });
  final bool expanded;
  final bool moduleHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final globalAiChoice = ref.watch(
      characterPromptNotifierProvider.select((c) => c.globalAiChoice),
    );
    final canvasOpen = ref.watch(characterPositionCanvasProvider);
    final canvasAvailable = ref.watch(characterPositionCanvasAvailableProvider);

    if (moduleHeader) {
      final track = SidebarSegmentTrack<bool>(
        key: const ValueKey('character-position-segments'),
        dense: true,
        expand: expanded,
        selected: globalAiChoice,
        onSelected: (value) => ref
            .read(characterPromptNotifierProvider.notifier)
            .setGlobalAiChoice(value),
        segments: [
          SidebarSegment(
            value: true,
            child: Text(
              l10n.characterCanvas_aiChoice,
              key: const ValueKey('character-position-ai'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SidebarSegment(
            value: false,
            child: Text(
              l10n.characterCanvas_custom,
              key: const ValueKey('character-position-custom'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
      return Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (expanded) Expanded(child: track) else track,
          const SizedBox(width: 6),
          ModuleHeaderIconButton(
            key: const ValueKey('character-position-toggle'),
            icon: Icons.grid_view_outlined,
            tooltip: l10n.characterCanvas_title,
            onPressed: canvasAvailable
                ? () => ref
                      .read(characterPositionCanvasProvider.notifier)
                      .toggle()
                : null,
          ),
        ],
      );
    }
    Widget segment(Widget child) => expanded ? Expanded(child: child) : child;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('character-position-segments'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            SidebarSegmentButton(
              key: const ValueKey('character-position-ai'),
              selected: globalAiChoice,
              onPressed: () => ref
                  .read(characterPromptNotifierProvider.notifier)
                  .setGlobalAiChoice(true),
              child: Text(
                l10n.characterCanvas_aiChoice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _segmentTextStyle(context, globalAiChoice),
              ),
            ),
          ),
          const SizedBox(width: 3),
          segment(
            Material(
              key: const ValueKey('character-position-custom-group'),
              color: !globalAiChoice
                  ? GenSidebarStyle.selectedSurface(Theme.of(context))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              clipBehavior: Clip.antiAlias,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  segment(
                    SidebarSegmentButton(
                      key: const ValueKey('character-position-custom'),
                      selected: !globalAiChoice,
                      backgroundColor: Colors.transparent,
                      onPressed: () => ref
                          .read(characterPromptNotifierProvider.notifier)
                          .setGlobalAiChoice(false),
                      child: Text(
                        l10n.characterCanvas_custom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _segmentTextStyle(context, !globalAiChoice),
                      ),
                    ),
                  ),
                  Container(
                    key: const ValueKey('character-position-divider'),
                    width: 1,
                    height: 22,
                    color: colorScheme.outline.withValues(alpha: .25),
                  ),
                  Tooltip(
                    message: l10n.characterCanvas_title,
                    waitDuration: const Duration(milliseconds: 500),
                    child: SidebarSegmentButton(
                      key: const ValueKey('character-position-toggle'),
                      selected: canvasOpen && !globalAiChoice,
                      backgroundColor: canvasOpen && !globalAiChoice
                          ? Color.alphaBlend(
                              colorScheme.onSurface.withValues(alpha: .1),
                              GenSidebarStyle.selectedSurface(
                                Theme.of(context),
                              ),
                            )
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      onPressed: canvasAvailable
                          ? () => ref
                                .read(characterPositionCanvasProvider.notifier)
                                .toggle()
                          : null,
                      child: SvgPicture.asset(
                        'assets/icons/nai-icon-characterpositions.svg',
                        width: 15,
                        height: 15,
                        colorFilter: ColorFilter.mode(
                          colorScheme.onSurface.withValues(
                            alpha: !canvasAvailable
                                ? .3
                                : (!globalAiChoice ? 1 : .65),
                          ),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle? _segmentTextStyle(BuildContext context, bool selected) {
    final theme = Theme.of(context);
    return theme.textTheme.labelMedium?.copyWith(
      color: selected
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurfaceVariant,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    );
  }
}

/// 角色切换芯片条
class _ChipBar extends ConsumerWidget {
  final List<CharacterPrompt> characters;
  final String? selectedId;

  const _ChipBar({required this.characters, required this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 38,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < characters.length; i++) ...[
                _CharacterChip(
                  character: characters[i],
                  index: i,
                  selected: characters[i].id == selectedId,
                  onTap: () => ref
                      .read(selectedCharacterIdProvider.notifier)
                      .select(characters[i].id),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 单个角色切换芯片：序号 + 性别符号（依提示词首 tag）+ 显示名
class _CharacterChip extends StatelessWidget {
  final CharacterPrompt character;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _CharacterChip({
    required this.character,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final display = resolveCharacterChipDisplay(character);
    final foreground = selected
        ? colorScheme.surface
        : colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? colorScheme.onSurface
          : GenSidebarStyle.panelSurface(theme),
      borderRadius: BorderRadius.circular(3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        hoverColor: foreground.withValues(alpha: .1),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (display.genderIcon != null) ...[
                const SizedBox(width: 3),
                Icon(display.genderIcon, size: 14, color: foreground),
              ],
              if (display.label != null) ...[
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    display.label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Neutral numbered markers match the role chips without covering the image.
class _AnchorDot extends StatelessWidget {
  final CharacterPrompt character;
  final int index;
  final double diameter;
  final bool emphasized;

  const _AnchorDot({
    required this.character,
    required this.index,
    required this.diameter,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final anchor = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: const Color(0xfffafafa),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: emphasized ? 2.5 : 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: const Color(0xff202020),
            fontSize: diameter * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return Tooltip(
      message: character.customName.isEmpty
          ? AppLocalizations.of(context)!.character_number(index + 1)
          : character.customName,
      waitDuration: const Duration(milliseconds: 600),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: character.enabled ? 1.0 : 0.45,
        child: anchor,
      ),
    );
  }
}
