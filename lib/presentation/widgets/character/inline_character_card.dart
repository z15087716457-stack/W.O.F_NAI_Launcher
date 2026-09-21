import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_position_canvas_provider.dart';
import '../../providers/character_prompt_provider.dart';
import '../../screens/generation/widgets/generation_sidebar_style.dart';
import '../common/decoded_memory_image.dart';
import 'add_to_library_dialog.dart';
import 'inline_character_editor.dart';

/// 内联角色卡
///
/// [inlineEditor] 为 true（官网布局竖排）：编辑器常驻，没有折叠态，
/// 点击卡片任意处即可输入（选中只剩高亮边框语义，光标聚焦哪张卡
/// 哪张卡高亮）——对齐官网「每个角色一个常驻可编辑文本框」的形态。
///
/// [inlineEditor] 为 false（经典布局横排）：只读预览卡，选中仅高亮
/// 边框，编辑器由外部的全宽面板承载，保持网格排版整齐。
///
/// - 词库角色的缩略图作为头部条背景横向铺满
/// - [compact] 用于经典布局的横排行：更矮的头部、更少的预览行数
class InlineCharacterCard extends ConsumerStatefulWidget {
  final CharacterPrompt character;
  final int index;
  final int total;
  final bool compact;
  final bool inlineEditor;

  const InlineCharacterCard({
    super.key,
    required this.character,
    required this.index,
    required this.total,
    this.compact = false,
    this.inlineEditor = true,
  });

  @override
  ConsumerState<InlineCharacterCard> createState() =>
      _InlineCharacterCardState();
}

class _InlineCharacterCardState extends ConsumerState<InlineCharacterCard> {
  /// 选中切换的统一动画规格（与左栏参数抽屉的节奏一致）
  static const _animDuration = Duration(milliseconds: 180);
  static const _animCurve = Curves.easeOutCubic;

  /// 卡的焦点父节点：hasFocus 含后代（输入框）焦点，
  /// 用于区分「点击外部失焦」与「点击自动补全浮层但焦点仍在输入框」
  final FocusNode _cardFocusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  /// 模态对话框（位置/重命名/词库）打开期间抑制点外部收起
  bool _modalOpen = false;

  @override
  void initState() {
    super.initState();
    // 常驻模式：焦点（含编辑器输入框的后代焦点）落到哪张卡，
    // 哪张卡选中高亮——高亮跟随光标，无需用户先点头部条
    _cardFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _cardFocusNode.removeListener(_handleFocusChanged);
    _cardFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted || !widget.inlineEditor) return;
    if (_cardFocusNode.hasFocus &&
        ref.read(selectedCharacterIdProvider) != widget.character.id) {
      _enterEditing();
    }
  }

  bool get _isEditing =>
      ref.watch(selectedCharacterIdProvider) == widget.character.id;

  CharacterPromptNotifier get _notifier =>
      ref.read(characterPromptNotifierProvider.notifier);

  void _enterEditing() {
    ref.read(selectedCharacterIdProvider.notifier).select(widget.character.id);
  }

  void _toggleEditing() {
    // 常驻模式没有展开/收起语义，点击只是选中高亮
    if (widget.inlineEditor) {
      _enterEditing();
      return;
    }
    final selector = ref.read(selectedCharacterIdProvider.notifier);
    if (ref.read(selectedCharacterIdProvider) == widget.character.id) {
      selector.clear();
    } else {
      _enterEditing();
    }
  }

  /// 直接删除（不弹确认框）
  void _deleteCharacter() {
    final selector = ref.read(selectedCharacterIdProvider.notifier);
    if (ref.read(selectedCharacterIdProvider) == widget.character.id) {
      selector.clear();
    }
    _notifier.removeCharacter(widget.character.id);
  }

  Future<void> _openModal(Future<void> Function() open) async {
    _modalOpen = true;
    try {
      await open();
    } finally {
      _modalOpen = false;
    }
  }

  void _handleTapOutside() {
    // 经典布局下编辑器在外部全宽面板里，点面板不能算「卡外」，
    // 退出逻辑全权交给面板自己的 TapRegion
    if (!widget.inlineEditor) return;
    if (_modalOpen) return;
    // 位置画布打开时，点画布拖锚点是位置编辑的一部分，不退出编辑态
    if (ref.read(characterPositionCanvasProvider)) return;
    // 常驻模式点外部只取消高亮（编辑器恒在，无折叠可退）；
    // TapRegion 恒挂（结构稳定），非选中卡的外部点击直接忽略
    if (ref.read(selectedCharacterIdProvider) != widget.character.id) return;
    // TapRegion 回调发生在指针按下时，等本帧手势与焦点变化尘埃落定再判断
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 用户点了另一张卡：选中已切换，别把新选择清掉
      if (ref.read(selectedCharacterIdProvider) != widget.character.id) {
        return;
      }
      // 点击自动补全浮层的建议项时浮层在卡外，但输入框焦点保持，
      // 此时不应退出编辑
      if (_cardFocusNode.hasFocus) return;
      ref.read(selectedCharacterIdProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = _isEditing;
    final enabled = widget.character.enabled;
    // 常驻模式（官网布局）编辑器恒在；经典布局始终走只读预览，
    // 选中只负责边框高亮
    final showInlineEditor = widget.inlineEditor;

    // 边框恒宽只变色：宽度变化会挤动内容造成微抖，颜色用动画过渡
    final card = AnimatedContainer(
      duration: _animDuration,
      curve: _animCurve,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: GenSidebarStyle.promptSurface(theme),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEditing
              ? colorScheme.onSurface.withValues(alpha: 0.55)
              : GenSidebarStyle.border(theme),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, theme, showInlineEditor),
          // 常驻模式子树恒为编辑器（无切换动画）；经典布局恒为预览。
          // AnimatedSize/AnimatedSwitcher 保留：初挂即全高无动画，
          // 且结构稳定避免 Element 重建闪帧
          AnimatedSize(
            duration: _animDuration,
            curve: _animCurve,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              // AnimatedSwitcher 默认用居中 Stack 布局，子项会缩成内容宽，
              // 预览区点击热区随之变窄；强制占满卡宽让整个框内都可点中
              child: showInlineEditor
                  ? SizedBox(
                      key: const ValueKey('editor'),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                        child: CharacterPromptEditor(
                          character: widget.character,
                          compact: widget.compact,
                          // 多卡常驻不抢焦点，点击聚焦（见编辑器 doc）
                          autoFocus: false,
                        ),
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('preview'),
                      width: double.infinity,
                      child: _buildPreview(context, theme),
                    ),
            ),
          ),
        ],
      ),
    );

    // TapRegion/Focus 恒挂，保持子树结构稳定（条件包装会让 Element
    // 无法复用、整卡重建闪一帧）；是否响应由回调内部判断
    return AnimatedOpacity(
      duration: _animDuration,
      opacity: enabled ? 1.0 : 0.48,
      child: Focus(
        focusNode: _cardFocusNode,
        child: TapRegion(onTapOutside: (_) => _handleTapOutside(), child: card),
      ),
    );
  }

  // ==================== 头部条 ====================

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    bool editableName,
  ) {
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final character = widget.character;
    final hasThumbnail =
        character.thumbnailPath != null &&
        character.thumbnailPath!.isNotEmpty &&
        File(character.thumbnailPath!).existsSync();
    const headerHeight = 28.0;
    // 缩略图铺满头部时文字压图，统一转白色
    final onHeader = hasThumbnail ? Colors.white : colorScheme.onSurfaceVariant;

    return SizedBox(
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasThumbnail)
            _HeaderThumbnail(path: character.thumbnailPath!)
          else
            ColoredBox(color: colorScheme.surface),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleEditing,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    _genderIcon(character.effectiveGender, onHeader),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final nameStyle = theme.textTheme.labelMedium
                              ?.copyWith(
                                color: hasThumbnail
                                    ? Colors.white
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                shadows: hasThumbnail
                                    ? const [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              );
                          // 编辑态名字就地可改，无需弹窗
                          if (editableName) {
                            return CharacterNameField(
                              key: ValueKey('name-${character.id}'),
                              character: character,
                              style: nameStyle,
                            );
                          }
                          return Text(
                            character.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: nameStyle,
                          );
                        },
                      ),
                    ),
                    // 官网式动作列：▲ ▼ ✓ 🗑 ⋯ 紧凑单行纯图标；
                    // 名字用 Expanded 省略号吸收宽度。
                    ..._buildFullActions(context, ref, l10n, onHeader),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFullActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Color onHeader,
  ) {
    final character = widget.character;
    final canvasOpen = ref.watch(characterPositionCanvasProvider);
    // 官网式紧凑单行：主动作 ▲ ▼ ✓ 🗑 直出，
    // 低频动作（入库 / 位置画布）收进 ⋯ 菜单，不再一字排开加竖线
    return [
      _HeaderIconButton(
        asset: 'assets/icons/nai-icon-dir-arrow-up.svg',
        color: onHeader,
        tooltip: l10n.characterEditor_moveUp,
        enabled: widget.index > 0,
        onTap: () => _notifier.moveCharacterUp(widget.index),
      ),
      _HeaderIconButton(
        asset: 'assets/icons/nai-icon-dir-arrow-down.svg',
        color: onHeader,
        tooltip: l10n.characterEditor_moveDown,
        enabled: widget.index < widget.total - 1,
        onTap: () => _notifier.moveCharacterDown(widget.index),
      ),
      _HeaderIconButton(
        asset: 'assets/icons/nai-icon-check.svg',
        separated: true,
        color: onHeader,
        tooltip: l10n.characterEditor_enabled,
        onTap: () => _notifier.toggleCharacterEnabled(character.id),
      ),
      _HeaderIconButton(
        asset: 'assets/icons/nai-icon-trash.svg',
        separated: true,
        color: onHeader,
        tooltip: l10n.common_delete,
        onTap: _deleteCharacter,
      ),
      _HeaderOverflowMenu(
        color: onHeader,
        canvasOpen: canvasOpen,
        addToLibraryLabel: l10n.promptBlockLibrary_addToLibrary,
        canvasLabel: l10n.characterCanvas_title,
        onSelected: (action) {
          switch (action) {
            case _CharacterHeaderMenuAction.addToLibrary:
              _openModal(
                () => AddToLibraryDialog.show(
                  context,
                  name: widget.character.name,
                  content: widget.character.prompt,
                ),
              );
            case _CharacterHeaderMenuAction.positionCanvas:
              ref.read(characterPositionCanvasProvider.notifier).toggle();
          }
        },
      ),
    ];
  }

  /// 官网式性别符号图标（♀/♂/⚥），单色。
  static Widget _genderIcon(CharacterGender gender, Color onHeader) {
    if (gender == CharacterGender.other) {
      return Icon(Icons.circle_outlined, size: 11, color: onHeader);
    }
    final asset = switch (gender) {
      CharacterGender.female => 'assets/icons/nai-icon-gender-female.svg',
      CharacterGender.male => 'assets/icons/nai-icon-gender-male.svg',
      CharacterGender.other => 'assets/icons/nai-icon-gender-female.svg',
    };
    return SvgPicture.asset(
      asset,
      width: 13,
      height: 13,
      colorFilter: ColorFilter.mode(onHeader, BlendMode.srcIn),
    );
  }

  // ==================== 只读预览 ====================

  Widget _buildPreview(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final prompt = widget.character.prompt;
    final isEmpty = prompt.trim().isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // 与头部一致的开关语义：未选中点击进入编辑，已选中（经典布局
        // 编辑器在外部面板、预览区仍可见）再点收起
        onTap: _toggleEditing,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            isEmpty ? l10n.characterEditor_promptHint : prompt,
            maxLines: widget.compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isEmpty
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                  : theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// 头部条缩略图背景（横向铺满 + 暗遮罩保证文字可读）
class _HeaderThumbnail extends StatelessWidget {
  final String path;

  const _HeaderThumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cacheWidth = DecodedMemoryImage.resolveCacheDimension(
          logicalSize: width.isFinite ? math.min(width, 720.0) : 720.0,
          constrainedSize: null,
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.4),
              cacheWidth: cacheWidth,
              errorBuilder: (context, error, stack) => ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
            ),
            const ColoredBox(color: Color(0x66000000)),
          ],
        );
      },
    );
  }
}

/// 头部条小图标按钮（支持官方 SVG asset 或 Material IconData）
class _HeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final String? asset;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;
  final bool separated;

  const _HeaderIconButton({
    this.icon,
    this.asset,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
    this.separated = false,
  }) : assert(icon != null || asset != null, 'icon or asset required');

  @override
  Widget build(BuildContext context) {
    final tint = enabled ? color : color.withValues(alpha: 0.3);
    final glyph = asset != null
        ? SvgPicture.asset(
            asset!,
            width: asset!.contains('dir-arrow') ? 11 : 13,
            height: asset!.contains('dir-arrow') ? 7 : 13,
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          )
        : Icon(icon, size: 15, color: tint);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: separated
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: GenSidebarStyle.border(Theme.of(context)),
                    ),
                  ),
                )
              : null,
          child: glyph,
        ),
      ),
    );
  }
}

/// 角色卡头部 ⋯ 溢出菜单承载的低频动作
enum _CharacterHeaderMenuAction { addToLibrary, positionCanvas }

/// 头部条 ⋯ 溢出菜单（官网式：低频动作收进菜单，保持单行紧凑）
class _HeaderOverflowMenu extends StatelessWidget {
  final Color color;
  final bool canvasOpen;
  final String addToLibraryLabel;
  final String canvasLabel;
  final ValueChanged<_CharacterHeaderMenuAction> onSelected;

  const _HeaderOverflowMenu({
    required this.color,
    required this.canvasOpen,
    required this.addToLibraryLabel,
    required this.canvasLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemForeground = theme.colorScheme.onSurface.withValues(alpha: 0.8);
    return PopupMenuButton<_CharacterHeaderMenuAction>(
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        maximumSize: const Size(28, 28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(),
        side: BorderSide(color: GenSidebarStyle.border(theme)),
      ),
      iconSize: 16,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 4),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<_CharacterHeaderMenuAction>(
          value: _CharacterHeaderMenuAction.addToLibrary,
          height: 36,
          child: Row(
            children: [
              Icon(Icons.library_add_outlined, size: 15, color: itemForeground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  addToLibraryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<_CharacterHeaderMenuAction>(
          value: _CharacterHeaderMenuAction.positionCanvas,
          height: 36,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/nai-icon-characterpositions.svg',
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(itemForeground, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canvasLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canvasOpen)
                Icon(Icons.check, size: 15, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ],
      icon: Icon(Icons.more_horiz, size: 18, color: color),
    );
  }
}
