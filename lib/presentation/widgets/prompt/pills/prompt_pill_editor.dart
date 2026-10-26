import '../comfyui_import_wrapper.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/prompt_input_normalization.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import '../../../screens/settings/sections/prompt_assistant_settings_section.dart';
import '../../../../data/models/character/character_prompt.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../common/text_editing_shortcuts.dart';
import '../../../providers/prompt_translation_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../blocks/prompt_block_colors.dart';
import '../blocks/prompt_block_drag_data.dart';
import '../unified/unified_prompt_config.dart';
import '../unified/unified_prompt_input.dart';
import '../../../ui/kit/ui_block_pill.dart';
import '../../../ui/kit/ui_popover.dart';
import '../../../wiring/blocks_instance_wiring.dart';
import '../../../wiring/blocks_mapping.dart';
import '../../../wiring/blocks_actions.dart';
import 'prompt_pill.dart';
import 'translation_pill_view.dart';

/// 药丸块编辑器：单个完整输入框 + 内联药丸。
///
/// 每个输入框绑定一个药丸工作区 lane（[PillScopes]）：生成页正向/负向/
/// 角色框、画风探索页正负 lane 均复用本组件。底层文本里块 = 1 个私有区
/// 标记字符，实例数据在 [pillWorkspaceProvider]，渲染钩子经
/// [UnifiedPromptConfig.pillBuilder] 注入 `NaiSyntaxController` 的 span
/// 构建链。
///
/// 块库入口不在本编辑器内（旧侧签/模态抽屉已拆除），由生成页页面级的
/// 块库面板承担；本编辑器只负责拖放落点与文内拖动排序。
class PromptPillEditor extends ConsumerStatefulWidget {
  final TextStyle? textStyle;
  const PromptPillEditor({
    super.key,
    this.textStyle,
    required this.config,
    this.pillScope = PillScopes.main,
    this.initialPlainText,
    this.decoration,
    this.compact = false,
    this.autoGrow = false,
    this.minLines,
    this.maxLines,
    this.allowEvolutionToggle = false,
    this.enableBlurredUndo = false,
    this.onChanged,
    this.onComfyuiImport,
    this.beginComfyuiImport,
  });

  final UnifiedPromptConfig config;

  /// 药丸工作区 lane（P3）：每个输入框一个独立 scope，
  /// 文档/实例/墓碑缓存按 scope 隔离并分键持久化。
  final String pillScope;

  /// 首次打开（lane 无存档）时用于播种重建的存量纯文本。
  ///
  /// 挂载/切换 scope 时若文档为空且本值非空，先用它重建文档再对外发射
  /// 投影——否则挂载期的空投影会经 onChanged 回写把外部存量文本抹掉
  /// （实测：build 期捕获的陈旧投影与播种赛跑，互相覆盖振荡）。
  final String? initialPlainText;
  final InputDecoration? decoration;
  final bool compact;
  final bool autoGrow;
  final int? minLines;

  /// 最大行数（角色框 3~12 自增高封顶用）；null = 随 compact 默认。
  final int? maxLines;

  /// 是否允许在实例卡中切换遗传开关（仅画风探索页开启）。
  final bool allowEvolutionToggle;

  /// Only generation-page editors register for application-level fallback.
  final bool enableBlurredUndo;

  /// 投影（块已展开的完整提示词）变化回调，接旧生成参数链路。
  final ValueChanged<String>? onChanged;
  final void Function(String globalPrompt, List<CharacterPrompt> characters)?
  onComfyuiImport;
  final ComfyuiImportBegin? beginComfyuiImport;

  @override
  ConsumerState<PromptPillEditor> createState() => _PromptPillEditorState();
}

class _PromptPillEditorState extends ConsumerState<PromptPillEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final GlobalKey _fieldAreaKey = GlobalKey();

  TextEditingShortcutsState? _undoRouter;
  bool _applyingExternal = false;
  int _lastValidOffset = 0;
  String? _lastEmittedProjection;

  /// 播种挂起中：文档尚未物化，禁止对外发射投影（防陈旧空串回写）。
  bool _pendingSeed = false;

  /// L1 实例卡浮层（P2.5）：同屏只开一张，编辑器卸载时必须带走。
  UiPopoverAnchor? _instanceCardAnchor;
  String? _instanceCardMarker;
  TranslationPillEditHandle? _translationEditor;

  @override
  void initState() {
    super.initState();
    final document = ref.read(_workspace).document;
    _controller = TextEditingController(text: document.text)
      ..addListener(_handleControllerChanged);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _lastValidOffset = document.text.length;
    _armSeedIfFresh(document);
    // 挂载即对齐一次投影（库内容可能在停机构间被编辑过）；
    // 有播种时先播种再发射，保证发射的是物化后的投影。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runPendingSeed();
      _emitProjectionIfChanged(ref.read(_workspace));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _undoRouter = TextEditingShortcuts.maybeOf(context);
  }

  void _restoreHistory({required bool redo}) {
    final notifier = ref.read(_workspace.notifier);
    if (redo) {
      notifier.redo();
    } else {
      notifier.undo();
    }
    final text = ref.read(_workspace).document.text;
    _applyingExternal = true;
    try {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: _lastValidOffset.clamp(0, text.length),
        ),
      );
    } finally {
      _applyingExternal = false;
    }
  }

  @override
  void didUpdateWidget(PromptPillEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // scope 切换（角色编辑面板 State 复用、切换编辑目标）：重绑文档
    if (oldWidget.enableBlurredUndo && !widget.enableBlurredUndo) {
      _undoRouter?.forgetPrompt(context);
    }
    if (oldWidget.pillScope != widget.pillScope) {
      ref
          .read(pillWorkspaceProvider(oldWidget.pillScope).notifier)
          .closeTypingGroup();
      _undoRouter?.forgetPrompt(context);
      _dismissInstanceCard(refresh: false);
      _translationEditor?.dismiss();
      _translationEditor = null;
      final workspace = ref.read(_workspace);
      _applyingExternal = true;
      _controller.value = TextEditingValue(
        text: workspace.document.text,
        selection: TextSelection.collapsed(
          offset: workspace.document.text.length,
        ),
      );
      _applyingExternal = false;
      _lastValidOffset = workspace.document.text.length;
      _lastEmittedProjection = null;
      _armSeedIfFresh(workspace.document);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _runPendingSeed();
        _emitProjectionIfChanged(ref.read(_workspace));
      });
    }
    if (_focusNode.hasPrimaryFocus && widget.enableBlurredUndo) {
      _rememberForBlurredUndo();
    }
  }

  /// 文档为空且有存量文本 → 进入播种挂起态，并预置已发射投影为存量文本
  /// （播种后的投影必等于它：全新文档无实例），挂载期不再发射任何值。
  void _armSeedIfFresh(PillDocument document) {
    final initial = widget.initialPlainText;
    if (initial == null ||
        initial.isEmpty ||
        document.text.isNotEmpty ||
        document.instances.isNotEmpty) {
      return;
    }
    _pendingSeed = true;
    _lastEmittedProjection = initial;
  }

  void _runPendingSeed() {
    if (!_pendingSeed) return;
    _pendingSeed = false;
    final initial = widget.initialPlainText;
    if (initial == null) return;
    ref.read(_workspace.notifier).replaceWithPlainText(initial);
  }

  @override
  void deactivate() {
    ref.read(_workspace.notifier).closeTypingGroup();
    super.deactivate();
  }

  @override
  void dispose() {
    _undoRouter?.forgetPrompt(context);
    _dismissInstanceCard(refresh: false);
    _translationEditor?.dismiss();
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      ref.read(_workspace.notifier).closeTypingGroup();
    }
    if (_focusNode.hasPrimaryFocus && widget.enableBlurredUndo) {
      _rememberForBlurredUndo();
    }
    if (mounted) setState(() {});
  }

  void _rememberForBlurredUndo() {
    _undoRouter?.rememberPrompt(
      context,
      undo: () => _restoreHistory(redo: false),
      redo: () => _restoreHistory(redo: true),
    );
  }

  // ==================== L1 实例卡 ====================

  /// 点药丸开 L1 实例卡（P2.5）：点击位置浮卡，点外/再点别处关闭。
  void _showInstanceCard(String marker, Offset globalPosition) {
    setState(() {
      _instanceCardMarker = marker;
      _instanceCardAnchor = UiPopoverAnchor(
        globalPosition + const Offset(-174, 8),
      );
    });
  }

  void _dismissInstanceCard({bool refresh = true}) {
    final hadMarker = _instanceCardMarker != null;
    _instanceCardMarker = null;
    _instanceCardAnchor = null;
    if (refresh && hadMarker && mounted) setState(() {});
  }

  /// 本编辑器绑定的药丸工作区（按 [pillScope] 取家族实例）。
  NotifierFamilyProvider<PillWorkspaceNotifier, PillWorkspaceState, String>
  get _workspace => pillWorkspaceProvider(widget.pillScope);

  @override
  Widget build(BuildContext context) {
    // 块库就绪/内容变化 → 重算投影（块内容经 resolver 实时解析进投影）
    ref.listen(promptBlockLibraryNotifierProvider, (_, __) {
      ref.read(_workspace.notifier).refreshProjection();
    });

    final workspace = ref.watch(_workspace);
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;

    // provider 驱动的文本变化（插入/移动/外部重建）回写 controller
    if (!_applyingExternal && _controller.text != workspace.document.text) {
      final oldSelection = _controller.selection;
      final offset = oldSelection.isValid
          ? oldSelection.extentOffset.clamp(0, workspace.document.text.length)
          : workspace.document.text.length;
      _applyingExternal = true;
      _controller.value = TextEditingValue(
        text: workspace.document.text,
        selection: TextSelection.collapsed(offset: offset),
      );
      _applyingExternal = false;
      _lastValidOffset = offset;
    }
    _emitProjectionIfChanged(workspace);

    final effectiveConfig = widget.config.copyWith(
      pillBuilder: _buildPillSpan,
      pillVisualsSignature: _pillSignature(workspace, library),
    );

    return UiPopover(
      anchor: _instanceCardAnchor,
      onDismiss: _dismissInstanceCard,
      builder: (_) => BlockInstanceWiring(
        scope: widget.pillScope,
        marker: _instanceCardMarker!,
        onDismiss: _dismissInstanceCard,
        allowEvolutionToggle: widget.allowEvolutionToggle,
      ),
      child: DragTarget<PromptBlockDragData>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) =>
            _handleDrop(details.data, details.offset),
        builder: (context, candidateData, rejectedData) {
          final highlighted = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: highlighted
                  ? Border.all(color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            child: KeyedSubtree(
              key: _fieldAreaKey,
              child: UnifiedPromptInput(
                textStyle: widget.textStyle,
                controller: _controller,
                pillScope: widget.pillScope,
                focusNode: _focusNode,
                onUserEdit: (value) => ref
                    .read(_workspace.notifier)
                    .setText(
                      value.text,
                      userEdit: true,
                      composing:
                          value.composing.isValid &&
                          !value.composing.isCollapsed,
                    ),
                onUndo: () => _restoreHistory(redo: false),
                onRedo: () => _restoreHistory(redo: true),
                // A source field inside a WidgetSpan owns its own caret.
                showCursor: _focusNode.hasPrimaryFocus ? null : false,
                config: effectiveConfig,
                decoration: widget.decoration,
                beginComfyuiImport: widget.beginComfyuiImport,
                onComfyuiImport: widget.onComfyuiImport == null
                    ? null
                    : _handleComfyuiImport,
                maxLines: widget.maxLines ?? (widget.compact ? 2 : null),
                minLines: widget.minLines ?? (widget.compact ? 1 : 2),
                expands: false,
                fitContent: true,
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== 药丸渲染 ====================

  /// 药丸视觉签名：实例启用态、锁定态、遗传态、页面操作权限与被引用块的
  /// 标题/颜色/存亡都参与，文本本身的变化由 controller 文本缓存键覆盖。
  int _pillSignature(
    PillWorkspaceState workspace,
    PromptBlockLibraryState? library,
  ) {
    final parts = <Object>[];
    workspace.document.instances.forEach((marker, instance) {
      final block = library?.blockById(instance.blockId);
      parts.add(
        Object.hash(
          marker,
          instance.enabled,
          instance.locked,
          instance.settings.hasRoll,
          instance.settings.mode,
          instance.evolutionEnabled,
          instance.useNegativeContent,
          instance.bundleId,
          widget.allowEvolutionToggle,
          block?.title ?? '',
          block?.color ?? '',
          block?.iconName ?? '',
          block?.appearance ?? '',
          instance.translation,
          block == null,
        ),
      );
    });
    parts.add(library == null);
    parts.add(_instanceCardMarker ?? '');
    return Object.hashAll(parts);
  }

  InlineSpan? _buildPillSpan(
    BuildContext context,
    String marker,
    int occurrence,
  ) {
    final workspace = ref.read(_workspace);
    final library = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    final instance = workspace.document.instances[marker];

    if (instance == null) {
      // 未知标记（外来粘贴的私用区字符）：点击清除
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _withPillGap(
          GestureDetector(
            onTap: () => ref.read(_workspace.notifier).removeMarker(marker),
            child: UiBlockPill(
              label: context.l10n.promptBlockPill_unknown,
              color: Theme.of(context).colorScheme.outline,
              status: UiBlockPillStatus.invalid,
            ),
          ),
        ),
      );
    }

    if (instance.translation case final translation?) {
      Widget draggable(Widget child) => Draggable<PromptBlockDragData>(
        data: PromptBlockDragData(
          blockId: '',
          translation: translation,
          instanceMarker: PillInstanceDragRef(
            marker: marker,
            occurrence: occurrence,
            scope: widget.pillScope,
          ),
        ),
        rootOverlay: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TranslationPillView(
              pill: translation,
              highlightEnabled: widget.config.enableSyntaxHighlight,
              numericEmphasisEnabled: widget.config.numericEmphasisEnabled,
              autoFormat: widget.config.enableAutoFormat,
              onToggle: () {},
              onEdit: (_) {},
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: .35, child: child),
        child: child,
      );
      final pill = TranslationPillView(
        key: ValueKey('translation-pill-$marker-$occurrence'),
        pill: translation,
        highlightEnabled: widget.config.enableSyntaxHighlight,
        numericEmphasisEnabled: widget.config.numericEmphasisEnabled,
        autoFormat: widget.config.enableAutoFormat,
        onToggle: () => ref
            .read(_workspace.notifier)
            .updateTranslation(
              marker,
              translation.copyWith(showOriginal: !translation.showOriginal),
            ),
        onEdit: (position) => _editTranslation(marker, translation, position),
        onSourceChanged: (source) {
          final current = ref
              .read(_workspace)
              .document
              .instances[marker]
              ?.translation;
          if (current == null || current.source == source) return;
          ref
              .read(_workspace.notifier)
              .updateTranslation(
                marker,
                current.copyWith(
                  source: source,
                  marks: const [],
                  needsReview: true,
                ),
              );
        },
        sourceHandleBuilder: (handle) => MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: draggable(handle),
        ),
      );
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _withPillGap(translation.showOriginal ? pill : draggable(pill)),
      );
    }

    final block = library?.blockById(instance.blockId);
    if (block == null) {
      if (library == null) {
        // 库未就绪：中性占位，库到达后签名变化自动重渲染
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _withPillGap(
            const UiBlockPill(
              label: '…',
              color: Colors.grey,
              status: UiBlockPillStatus.invalid,
            ),
          ),
        );
      }
      // 块已被从库中删除：红色警示，点击清除
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _withPillGap(
          GestureDetector(
            onTap: () => ref.read(_workspace.notifier).removeMarker(marker),
            child: UiBlockPill(
              label: context.l10n.promptBlockPill_missing,
              color: Theme.of(context).colorScheme.error,
              status: UiBlockPillStatus.missing,
            ),
          ),
        ),
      );
    }

    final title = block.title.trim().isEmpty
        ? context.l10n.promptBlockLibrary_unnamedBlock
        : block.title;
    final pill = UiBlockPill(
      label: title,
      color: promptBlockColorFromString(block.color),
      look: blockLook(block.appearance),
      disabled: !instance.enabled,
      icon: block.iconName,
      badge: widget.allowEvolutionToggle && instance.evolutionEnabled
          ? UiBlockBadge.evolution
          : instance.locked
          ? UiBlockBadge.locked
          : instance.settings.mode == PillRollMode.sequential
          ? UiBlockBadge.sequential
          : instance.settings.mode == PillRollMode.random
          ? UiBlockBadge.random
          : UiBlockBadge.none,
      paired: instance.bundleId != null,
      open: _instanceCardMarker == marker,
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      // 即按即拖（不用长按：长按手势不可发现，用户会以为不能拖）；
      // 立即拖拽与点击开关不冲突——快按快放归 tap，移动归 drag。
      // feedback 以指针为中心：默认 childDragAnchorStrategy 把 feedback
      // 左上角对准指针，用户以药丸视觉中心瞄准 → 落点系统性偏上一行。
      child: _withPillGap(
        Draggable<PromptBlockDragData>(
          data: PromptBlockDragData(
            blockId: block.id,
            instanceMarker: PillInstanceDragRef(
              marker: marker,
              occurrence: occurrence,
              scope: widget.pillScope,
            ),
          ),
          // feedback 必须有界宽（PromptPill 内 Row+Flexible 在 overlay 的
          // 无界约束下会直接布局异常），并投到根 overlay 避免被裁剪。
          rootOverlay: true,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: PromptPillDragFeedback(child: pill),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: pill),
          // P2.5：点击从「直接切启停」改为开 L1 实例卡（启停/删除/重 roll/
          // 高级选项都在卡里）；即按即拖与 tap 天然分流，不受影响。
          child: Builder(
            builder: (pillContext) => GestureDetector(
              onTapUp: (details) {
                final keyboard = HardwareKeyboard.instance;
                if (keyboard.isControlPressed || keyboard.isMetaPressed) return;
                final box = pillContext.findRenderObject() as RenderBox;
                _showInstanceCard(
                  marker,
                  box.localToGlobal(box.size.bottomCenter(Offset.zero)),
                );
              },
              child: pill,
            ),
          ),
        ),
      ),
    );
  }

  Widget _withPillGap(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: child);

  Future<void> _editTranslation(
    String marker,
    TranslationPill initial,
    Offset position,
  ) async {
    _dismissInstanceCard();
    _translationEditor?.dismiss();
    final coordinator = ref.read(promptTranslationCoordinatorProvider);
    final service = ref.read(promptAssistantServiceProvider);
    final editor = showTranslationPillEditor(
      context: context,
      initial: widget.config.enableAutoFormat
          ? initial.copyWith(
              source: PromptInputNormalization.normalize(
                initial.source,
                autoFormat: true,
                sdAutoConvert: false,
              ).text,
            )
          : initial,
      globalPosition: position,
      enableTagExpansion: true,
      highlightEnabled: widget.config.enableSyntaxHighlight,
      numericEmphasisEnabled: widget.config.numericEmphasisEnabled,
      annotations: ref.read(promptTranslationAnnotationProvider),
      converter: (request, sessionId) =>
          coordinator.convertDraft(request, sessionId: sessionId),
      cancelConversion: (sessionId) {
        coordinator.cancelDraft(sessionId);
        service.cancelCurrentTask(sessionId: sessionId);
      },
      isModelConfigured: () =>
          ref.read(promptAssistantConfigProvider).promptTranslationRoute !=
          null,
      onConfigure: () => showModelManagementDialog(context),
    );
    _translationEditor = editor;
    final result = await editor.result;
    if (identical(_translationEditor, editor)) _translationEditor = null;
    if (!mounted ||
        ref.read(_workspace).document.instances[marker]?.translation !=
            initial) {
      return;
    }
    if (result == 'delete') {
      ref.read(_workspace.notifier).removeMarker(marker);
    } else if (result is TranslationPillPlainText) {
      ref
          .read(_workspace.notifier)
          .unwrapTranslation(marker, source: result.source);
    } else if (result == 'retranslate') {
      try {
        final updated = await ref
            .read(promptTranslationCoordinatorProvider)
            .retranslateSingle(widget.pillScope, marker);
        if (mounted && !updated) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(context.l10n.promptTranslation_sourceChanged),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.promptTranslation_retranslateFailed('$error'),
              ),
            ),
          );
        }
      }
    } else if (result is TranslationPill) {
      ref.read(_workspace.notifier).updateTranslation(marker, result);
    }
  }

  // ==================== 拖放 ====================

  void _handleDrop(PromptBlockDragData data, Offset globalPosition) {
    final offset = _offsetForGlobalPosition(globalPosition);
    final dragRef = data.instanceMarker;
    final sameLane =
        dragRef != null &&
        (dragRef.scope == null || dragRef.scope == widget.pillScope);
    if (data.translation case final translation?) {
      if (sameLane &&
          ref.read(_workspace).document.instances.containsKey(dragRef.marker)) {
        ref
            .read(_workspace.notifier)
            .moveMarker(
              marker: dragRef.marker,
              occurrence: dragRef.occurrence,
              newOffset: offset,
            );
      } else {
        ref
            .read(_workspace.notifier)
            .insertTranslationAt(
              offset: offset,
              source: translation.source,
              zh: translation.zh,
              marks: translation.marks,
              needsReview: translation.needsReview,
              languageCode: translation.languageCode,
              translationEdited: translation.translationEdited,
            );
      }
      return;
    }
    if (!sameLane) {
      final scope = widget.pillScope;
      BlocksActions(
        ref,
        context,
        () => mounted && widget.pillScope == scope,
      ).insert(
        [data.blockId],
        at: (scope: scope, caret: offset),
        onInserted: _placeCaretAfter,
      );
    } else {
      ref
          .read(_workspace.notifier)
          .moveMarker(
            marker: dragRef.marker,
            occurrence: dragRef.occurrence,
            newOffset: offset,
          );
    }
  }

  /// 指针全局坐标 → 文本 offset。
  ///
  /// `getPositionForPoint` 收的是**全局坐标**（内部自行 globalToLocal +
  /// 滚动补偿），别再预先换算，否则双重减偏移、落点系统性偏上。
  /// 文本下方空白区落点 clamp 归末尾（可接受语义）。
  int _offsetForGlobalPosition(Offset global) {
    final editable = _findRenderEditable();
    if (editable == null) return _controller.text.length;
    final position = editable.getPositionForPoint(global);
    return position.offset.clamp(0, _controller.text.length);
  }

  RenderEditable? _findRenderEditable() {
    final root = _fieldAreaKey.currentContext?.findRenderObject();
    if (root == null) return null;
    RenderEditable? found;
    void visit(RenderObject object) {
      if (found != null) return;
      if (object is RenderEditable) {
        found = object;
        return;
      }
      object.visitChildren(visit);
    }

    visit(root);
    return found;
  }

  /// 插入后把光标放到新标记之后并聚焦，方便继续输入。
  void _placeCaretAfter(int offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      final clamped = offset.clamp(0, _controller.text.length);
      _controller.selection = TextSelection.collapsed(offset: clamped);
      _lastValidOffset = clamped;
      ref.read(pillActiveEditorTargetProvider.notifier).state = (
        scope: widget.pillScope,
        caret: clamped,
      );
    });
  }

  // ==================== 文本与投影同步 ====================

  void _handleControllerChanged() {
    final selection = _controller.selection;
    if (selection.isValid && selection.extentOffset >= 0) {
      _lastValidOffset = selection.extentOffset.clamp(
        0,
        _controller.text.length,
      );
      _syncCaretOffset(_lastValidOffset);
    }
    if (_applyingExternal) return;
    ref.read(_workspace.notifier).setText(_controller.text);
  }

  /// 把本框的 scope+最近光标位置同步为块库面板的点击插入目标。
  ///
  /// 本回调可能在 build 期间由 `_applyingExternal` 回写触发，
  /// 写 provider 必须延后到帧末。
  void _syncCaretOffset(int offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pillActiveEditorTargetProvider.notifier).state = (
        scope: widget.pillScope,
        caret: offset,
      );
    });
  }

  void _emitProjectionIfChanged(PillWorkspaceState workspace) {
    if (_pendingSeed) return; // 投影未物化，发射必是陈旧值
    if (_lastEmittedProjection == workspace.projection) return;
    _lastEmittedProjection = workspace.projection;
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    final capturedProjection = workspace.projection;
    final capturedScope = widget.pillScope;
    final capturedWorkspace = pillWorkspaceProvider(capturedScope);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.pillScope != capturedScope) return;
      if (ref.read(capturedWorkspace).projection != capturedProjection) return;
      onChanged(capturedProjection);
    });
  }

  void _handleComfyuiImport(String globalPrompt, List<CharacterPrompt> chars) {
    ref.read(_workspace.notifier).replaceWithPlainText(globalPrompt);
    widget.onComfyuiImport?.call(globalPrompt, chars);
  }
}
