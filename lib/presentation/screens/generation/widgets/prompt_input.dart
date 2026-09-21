import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/autocomplete/autocomplete_settings.dart'
    as completion_settings;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/comfyui_prompt_parser/pipe_parser.dart';
import '../../../../core/utils/nai_prompt_formatter.dart';
import '../../../../core/utils/sd_to_nai_converter.dart';
import '../../../../data/models/character/character_prompt.dart';
import '../../../../data/models/prompt/prompt_preset_mode.dart';
import '../../../../data/services/alias_resolver_service.dart';
import '../../../providers/character_prompt_provider.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/prompt_maximize_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_regex_rules_provider.dart';
import '../../../providers/prompt_token_counter_provider.dart';
import '../../../providers/quality_preset_provider.dart';
import '../../../providers/tips_provider.dart';
import '../../../providers/uc_preset_provider.dart';
import '../../../widgets/autocomplete/autocomplete.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/prompt/pills/prompt_pill_editor.dart';
import '../../../widgets/prompt/unified/unified_prompt_config.dart';
import '../../../widgets/prompt/nai_syntax_controller.dart';
import '../../../widgets/prompt/prompt_token_count_bar.dart';
import '../../../widgets/prompt/quality_tags_selector.dart';
import '../../../widgets/prompt/transparent_background_chip.dart';
import '../../../widgets/prompt/regex_rules_dialog.dart';
import '../../../widgets/prompt/uc_preset_selector.dart';
import '../../../widgets/prompt/blocks/prompt_block_palette.dart';
import '../../../widgets/character/character_prompt_button.dart';
import '../../../providers/pending_prompt_provider.dart';
import 'generation_sidebar_style.dart';

bool usesRichPromptTypeTooltip(TargetPlatform platform) =>
    platform != TargetPlatform.windows;

/// Prompt 输入组件 (带自动补全)
class PromptInputWidget extends ConsumerStatefulWidget {
  final bool compact;
  final VoidCallback? onToggleMaximize;
  final bool isMaximized;
  final bool showMaximizeButton;
  final ValueNotifier<bool>? negativeModeNotifier;

  /// 是否允许正向药丸实例切换画风探索遗传开关。
  final bool allowEvolutionToggle;

  /// 编辑器随内容自增高（用于一体式滚动布局），
  /// 关闭时编辑器填充父级给定的高度并内部滚动。
  final bool autoGrow;

  /// 空态 hint 使用的 tip 模块池（FEAT-60）。
  final TipModule tipModule;

  const PromptInputWidget({
    super.key,
    this.compact = false,
    this.onToggleMaximize,
    this.isMaximized = false,
    this.showMaximizeButton = true,
    this.negativeModeNotifier,
    this.allowEvolutionToggle = false,
    this.autoGrow = false,
    this.tipModule = TipModule.gen,
  });

  @override
  ConsumerState<PromptInputWidget> createState() => _PromptInputWidgetState();
}

class _PromptInputWidgetState extends ConsumerState<PromptInputWidget> {
  late final NaiSyntaxController _promptController;
  late final NaiSyntaxController _negativeController;
  final _promptFocusNode = FocusNode();
  final _negativeFocusNode = FocusNode();

  // 正面/负面切换
  bool _isNegativeMode = false;

  // 块库/设置弹层开启态（官网 prompt-chunks 钮开合高亮）
  bool _chunksMenuOpen = false;

  @override
  void initState() {
    super.initState();
    final params = ref.read(generationParamsNotifierProvider);

    // 使用 NAI 语法高亮控制器作为兼容投影/工具栏读数。
    _promptController = NaiSyntaxController(text: params.prompt);
    _negativeController = NaiSyntaxController(text: params.negativePrompt);

    _promptFocusNode.addListener(_onPromptFocusChanged);
    _negativeFocusNode.addListener(_onNegativeFocusChanged);
    _promptController.addListener(_onPromptProxyChanged);
    _negativeController.addListener(_onNegativeProxyChanged);

    // 检查并消费待填充提示词（从画廊发送）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(generationParamsNotifierProvider);
      _bootstrapWorkspace(
        prompt: current.prompt,
        negativePrompt: current.negativePrompt,
      );
      _consumePendingPrompt();
    });

    _isNegativeMode = widget.negativeModeNotifier?.value ?? false;
    widget.negativeModeNotifier?.addListener(_onExternalNegativeModeChanged);
  }

  void _bootstrapWorkspace({
    required String prompt,
    required String negativePrompt,
  }) {
    // 药丸工作区（正向）恢复：仅在全新文档时用存储的提示词重建
    final pillState = ref.read(pillWorkspaceNotifierProvider);
    if (prompt.isNotEmpty &&
        pillState.document.text.isEmpty &&
        pillState.document.instances.isEmpty) {
      ref
          .read(pillWorkspaceNotifierProvider.notifier)
          .replaceWithPlainText(prompt);
    }
    // 负向 lane 对称播种（P3）
    final pillNegative = ref.read(pillWorkspaceProvider(PillScopes.negative));
    if (negativePrompt.isNotEmpty &&
        pillNegative.document.text.isEmpty &&
        pillNegative.document.instances.isEmpty) {
      ref
          .read(pillWorkspaceProvider(PillScopes.negative).notifier)
          .replaceWithPlainText(negativePrompt);
    }
  }

  /// 消费待填充提示词（从画廊或词库发送）
  void _consumePendingPrompt() {
    final pendingState = ref.read(pendingPromptNotifierProvider);
    if (pendingState.prompt == null && pendingState.negativePrompt == null) {
      return;
    }

    // 消费待填充提示词
    final consumed = ref.read(pendingPromptNotifierProvider.notifier).consume();

    // 根据目标类型分别处理
    final targetType = consumed.targetType;

    if (consumed.prompt != null && consumed.prompt!.isNotEmpty) {
      // 自动进行语法转换（SD→NAI + 格式化）
      var prompt = consumed.prompt!;
      prompt = SdToNaiConverter.convert(prompt);
      prompt = NaiPromptFormatter.format(prompt);

      switch (targetType) {
        case SendTargetType.smartDecompose:
          // 智能分解：解析竖线格式，分别发送到主提示词和角色
          _applySmartDecompose(prompt);
          break;
        case SendTargetType.replaceCharacter:
          // 替换角色提示词：清空现有角色，添加新角色
          _applyToCharacterPrompt(prompt, clearExisting: true);
          break;
        case SendTargetType.appendCharacter:
          // 追加角色提示词：保留现有角色，添加新角色
          _applyToCharacterPrompt(prompt, clearExisting: false);
          break;
        case SendTargetType.mainPrompt:
        default:
          // 发送到主提示词（默认行为）
          _applyToMainPrompt(prompt);
          break;
      }
    }

    // 填充负向提示词（仅发送到主提示词时）
    if (targetType == null || targetType == SendTargetType.mainPrompt) {
      if (consumed.negativePrompt != null &&
          consumed.negativePrompt!.isNotEmpty) {
        // 自动进行语法转换（SD→NAI + 格式化）
        var negativePrompt = consumed.negativePrompt!;
        negativePrompt = SdToNaiConverter.convert(negativePrompt);
        negativePrompt = NaiPromptFormatter.format(negativePrompt);

        _setProxyText(_negativeController, negativePrompt);
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updateNegativePrompt(negativePrompt);
      }
    }

    // 触发 UI 更新
    if (mounted) setState(() {});
  }

  /// 应用到主提示词
  void _applyToMainPrompt(String prompt) {
    _setProxyText(_promptController, prompt);
    ref.read(generationParamsNotifierProvider.notifier).updatePrompt(prompt);
  }

  void _setProxyText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// 应用到角色提示词
  void _applyToCharacterPrompt(String prompt, {required bool clearExisting}) {
    final characterNotifier = ref.read(
      characterPromptNotifierProvider.notifier,
    );

    // 如果需要清空现有角色
    if (clearExisting) {
      characterNotifier.clearAllCharacters();
    }

    // 检测是否为竖线格式
    if (PipeParser.isPipeFormat(prompt)) {
      // 解析竖线格式，分别添加每个角色
      final result = PipeParser.parse(prompt);
      // 添加主提示词中的内容作为第一个角色（如果存在）
      if (result.globalPrompt.isNotEmpty) {
        characterNotifier.addCharacter(
          _inferGender(result.globalPrompt),
          prompt: result.globalPrompt,
        );
      }
      // 添加解析出的角色
      for (final char in result.characters) {
        if (char.prompt.isNotEmpty) {
          characterNotifier.addCharacter(
            char.inferredGender ?? CharacterGender.other,
            prompt: char.prompt,
          );
        }
      }
    } else {
      // 非竖线格式，直接添加为单个角色
      characterNotifier.addCharacter(_inferGender(prompt), prompt: prompt);
    }

    // 显示提示
    if (mounted) {
      final message = clearExisting
          ? context.l10n.prompt_characterPromptReplaced
          : context.l10n.prompt_characterPromptAppended(
              ref.read(characterPromptNotifierProvider).characters.length,
            );
      AppToast.success(context, message);
    }
  }

  /// 推断提示词的性别
  CharacterGender _inferGender(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    if (lowerPrompt.contains('1boy') ||
        lowerPrompt.contains('2boys') ||
        lowerPrompt.contains('male')) {
      return CharacterGender.male;
    } else if (lowerPrompt.contains('1girl') ||
        lowerPrompt.contains('2girls') ||
        lowerPrompt.contains('female')) {
      return CharacterGender.female;
    }
    return CharacterGender.other;
  }

  /// 智能分解竖线格式并应用到对应位置
  void _applySmartDecompose(String prompt) {
    final characterNotifier = ref.read(
      characterPromptNotifierProvider.notifier,
    );

    // 解析竖线格式
    final result = PipeParser.parse(prompt);

    // 应用到主提示词
    if (result.globalPrompt.isNotEmpty) {
      _applyToMainPrompt(result.globalPrompt);
    }

    // 清空现有角色并添加解析出的角色
    characterNotifier.clearAllCharacters();
    for (final char in result.characters) {
      if (char.prompt.isNotEmpty) {
        characterNotifier.addCharacter(
          char.inferredGender ?? CharacterGender.other,
          prompt: char.prompt,
        );
      }
    }

    // 显示提示
    if (mounted) {
      final charCount = result.characters.length;
      final message = charCount > 0
          ? context.l10n.prompt_smartDecomposedWithCharacters(charCount)
          : context.l10n.prompt_appliedToMainPrompt;
      AppToast.success(context, message);
    }
  }

  @override
  void dispose() {
    widget.negativeModeNotifier?.removeListener(_onExternalNegativeModeChanged);
    _promptFocusNode.removeListener(_onPromptFocusChanged);
    _negativeFocusNode.removeListener(_onNegativeFocusChanged);
    _promptController.removeListener(_onPromptProxyChanged);
    _negativeController.removeListener(_onNegativeProxyChanged);
    _promptController.dispose();
    _negativeController.dispose();
    _promptFocusNode.dispose();
    _negativeFocusNode.dispose();
    super.dispose();
  }

  void _onPromptFocusChanged() {
    // Focus 状态变化时触发重建
    setState(() {});
  }

  void _onNegativeFocusChanged() {
    // Focus 状态变化时触发重建
    setState(() {});
  }

  void _onPromptProxyChanged() {
    if (mounted) setState(() {});
  }

  void _onNegativeProxyChanged() {
    if (mounted) setState(() {});
  }

  void _onExternalNegativeModeChanged() {
    final value = widget.negativeModeNotifier?.value ?? false;
    if (!mounted || value == _isNegativeMode) return;
    setState(() => _isNegativeMode = value);
  }

  void _setNegativeMode(bool value) {
    if (value == _isNegativeMode) return;
    setState(() => _isNegativeMode = value);
    widget.negativeModeNotifier?.value = value;
  }

  void _clearPrompt() {
    _setProxyText(_promptController, '');
    ref.read(generationParamsNotifierProvider.notifier).updatePrompt('');
    // 同时清空角色提示词
    ref.read(characterPromptNotifierProvider.notifier).clearAllCharacters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 监听 Provider 变化，同步代理控制器（工具栏计数 / tooltip / compact 清空按钮）。
    // 结构化工作区文档由 updatePrompt/updateNegativePrompt 内联协调，
    // 不再依赖本组件生命周期兜底压扁。
    ref.listen(
      generationParamsNotifierProvider.select(
        (params) =>
            (prompt: params.prompt, negativePrompt: params.negativePrompt),
      ),
      (previous, next) {
        if (previous?.prompt != next.prompt) {
          _setProxyText(_promptController, next.prompt);
        }
        if (previous?.negativePrompt != next.negativePrompt) {
          _setProxyText(_negativeController, next.negativePrompt);
        }
      },
    );

    // 监听待填充提示词变化（画廊发送等）
    ref.listen(hasPendingPromptProvider, (previous, next) {
      if (next == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _consumePendingPrompt();
        });
      }
    });

    // 监听高亮设置变化，更新控制器
    final highlightEnabled = ref.watch(highlightEmphasisSettingsProvider);
    final numericEmphasisEnabled = ImageModels.isV4Model(
      ref.watch(
        generationParamsNotifierProvider.select((params) => params.model),
      ),
    );
    _promptController.highlightEnabled = highlightEnabled;
    _negativeController.highlightEnabled = highlightEnabled;
    _promptController.numericEmphasisEnabled = numericEmphasisEnabled;
    _negativeController.numericEmphasisEnabled = numericEmphasisEnabled;

    if (widget.compact) {
      return _buildCompactLayout(theme, numericEmphasisEnabled);
    }

    return _buildFullLayout(theme, numericEmphasisEnabled);
  }

  Widget _buildFullLayout(ThemeData theme, bool numericEmphasisEnabled) {
    final model = ref.watch(
      generationParamsNotifierProvider.select((params) => params.model),
    );
    final editor = _isNegativeMode
        ? _buildTextNegativeInput(theme, numericEmphasisEnabled)
        : _buildTextPromptInput(theme, numericEmphasisEnabled);

    // 官网式单卡：页签+配件在框内头部，预设片在框内底行，
    // token 用量长条压在最底边。
    return Container(
      key: const ValueKey('main-prompt-card'),
      decoration: BoxDecoration(
        color: GenSidebarStyle.promptSurface(theme),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GenSidebarStyle.border(theme)),
      ),
      child: Column(
        mainAxisSize: widget.autoGrow ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(theme),

          // 提示词编辑区域（autoGrow 时随内容自增高，否则填充可用高度）
          if (widget.autoGrow) editor else Expanded(child: editor),

          // 框内底部条：左 透明通道片 ｜ 右 质量词/UC 预设片
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
            child: Row(
              children: [
                const TransparentBackgroundChip(),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _isNegativeMode
                        ? UcPresetSelector(model: model)
                        : QualityTagsSelector(model: model),
                  ),
                ),
              ],
            ),
          ),

          // 最底：token 用量长条
          _PromptTokenCountFooter(
            target: _isNegativeMode
                ? PromptTokenCountTarget.negative
                : PromptTokenCountTarget.positive,
            topPadding: 2,
          ),
        ],
      ),
    );
  }

  /// 卡内头部（官网式）：左 = 正面/负面页签，右 = 扩展槽 + 块库/设置 + 全屏。
  Widget _buildCardHeader(ThemeData theme) {
    return Padding(
      // Tabs and editor share the same inset inside one writing surface.
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
      child: Row(
        children: [
          Expanded(child: _buildPromptTypeSwitch(theme)),
          // 非 autoGrow 布局（移动端最大化/探索页）保留角色入口：
          // 一体式布局角色区常驻提示词下方，官网式头部不带角色钮
          if (!widget.autoGrow) ...[
            const CharacterPromptButton(),
            const SizedBox(width: 2),
          ],
          // 块库左侧预留扩展槽（翻译/Agent 动态提示扩展位）
          const PromptBlockPaletteButton(),
          _buildChunksMenuButton(theme),
          if (widget.showMaximizeButton)
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.toolbar_fullscreenEdit,
              onPressed:
                  widget.onToggleMaximize ??
                  () => ref
                      .read(promptMaximizeNotifierProvider.notifier)
                      .toggle(),
              icon: Icon(
                Icons.fullscreen,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  /// 块库/设置弹层钮（官网 prompt-chunks 钮）：官方 prompt_chunk 图标，
  /// 弹层首项 = 块库面板开关（勾选态随面板展开），其后为提示词设置项。
  Widget _buildChunksMenuButton(ThemeData theme) {
    final panelExpanded = ref.watch(
      layoutStateNotifierProvider.select((s) => s.blockLibraryPanelExpanded),
    );
    final enableAutocomplete = ref.watch(autocompleteSettingsProvider);
    final enableAutoFormat = ref.watch(autoFormatPromptSettingsProvider);
    final enableHighlight = ref.watch(highlightEmphasisSettingsProvider);
    final enableSdSyntaxAutoConvert = ref.watch(
      sdSyntaxAutoConvertSettingsProvider,
    );
    final enableResolveAliasOnCopy = ref.watch(
      resolveAliasOnCopySettingsProvider,
    );
    final enableCooccurrence = ref.watch(
      completion_settings.autocompleteSettingsProvider.select(
        (s) => s.relatedTagsEnabled,
      ),
    );
    final regexRuleCount = ref.watch(
      promptRegexRulesProvider.select((rules) => rules.length),
    );

    final highlighted = panelExpanded || _chunksMenuOpen;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        maximumSize: const Size(28, 28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: context.l10n.prompt_chunksMenu,
      iconSize: 18,
      offset: const Offset(0, 4),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onOpened: () => setState(() => _chunksMenuOpen = true),
      onCanceled: () => setState(() => _chunksMenuOpen = false),
      onSelected: (value) {
        setState(() => _chunksMenuOpen = false);
        _handleSettingsMenuResult(value);
      },
      itemBuilder: (context) => [
        _buildSettingsMenuItem(
          value: 'block_library',
          isEnabled: panelExpanded,
          title: context.l10n.promptBlockEditor_library,
          subtitle: '',
          theme: theme,
        ),
        const PopupMenuDivider(),
        _buildSettingsMenuItem(
          value: 'autocomplete',
          isEnabled: enableAutocomplete,
          title: context.l10n.prompt_smartAutocomplete,
          subtitle: context.l10n.prompt_smartAutocompleteSubtitle,
          theme: theme,
        ),
        _buildSettingsMenuItem(
          value: 'auto_format',
          isEnabled: enableAutoFormat,
          title: context.l10n.prompt_autoFormat,
          subtitle: context.l10n.prompt_autoFormatSubtitle,
          theme: theme,
        ),
        _buildSettingsMenuItem(
          value: 'highlight',
          isEnabled: enableHighlight,
          title: context.l10n.prompt_highlightEmphasis,
          subtitle: context.l10n.prompt_highlightEmphasisSubtitle,
          theme: theme,
        ),
        _buildSettingsMenuItem(
          value: 'sd_syntax_convert',
          isEnabled: enableSdSyntaxAutoConvert,
          title: context.l10n.prompt_sdSyntaxAutoConvert,
          subtitle: context.l10n.prompt_sdSyntaxAutoConvertSubtitle,
          theme: theme,
        ),
        _buildSettingsActionMenuItem(
          value: 'regex_rules',
          icon: Icons.find_replace,
          title: context.l10n.prompt_regexRulesManage,
          subtitle: context.l10n.prompt_regexRulesCount(regexRuleCount),
          theme: theme,
        ),
        _buildSettingsMenuItem(
          value: 'resolve_alias_on_copy',
          isEnabled: enableResolveAliasOnCopy,
          title: context.l10n.prompt_resolveAliasOnCopy,
          subtitle: context.l10n.prompt_resolveAliasOnCopySubtitle,
          theme: theme,
        ),
        _buildSettingsMenuItem(
          value: 'cooccurrence',
          isEnabled: enableCooccurrence,
          title: context.l10n.prompt_cooccurrenceRecommendation,
          subtitle: context.l10n.prompt_cooccurrenceRecommendationSubtitle,
          theme: theme,
        ),
      ],
      icon: SvgPicture.asset(
        'assets/icons/nai-icon-prompt-chunk.svg',
        width: 16,
        height: 16,
        colorFilter: ColorFilter.mode(
          highlighted
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildPromptTypeSwitch(ThemeData theme) {
    // 获取质量词数据
    final qualityState = ref.watch(qualityPresetNotifierProvider);
    final model = ref.watch(
      generationParamsNotifierProvider.select((params) => params.model),
    );
    final qualityContent = ref
        .watch(qualityPresetNotifierProvider.notifier)
        .getEffectiveContent(model);

    // 获取负面词预设数据
    ref.watch(ucPresetNotifierProvider);
    final ucPresetContent =
        ref
            .watch(ucPresetNotifierProvider.notifier)
            .getEffectiveContent(model) ??
        '';

    // 获取多角色数据
    final characterConfig = ref.watch(characterPromptNotifierProvider);

    // 预先获取别名解析器，避免在子组件 build 中访问 provider
    final aliasResolver = ref.read(aliasResolverServiceProvider.notifier);

    // 官网式：有角色提示词时首页签改名 Base Prompt
    final positiveLabel = characterConfig.characters.isNotEmpty
        ? context.l10n.prompt_baseTab
        : context.l10n.prompt_positive;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 正面提示词页签
        Flexible(
          child: _PromptTypeButton(
            label: positiveLabel,
            isSelected: !_isNegativeMode,
            onTap: () => _setNegativeMode(false),
            tooltipBuilder: (theme) => _PositivePromptTooltip(
              theme: theme,
              userPrompt: _promptController.text,
              qualityMode: qualityState.mode,
              qualityContent: qualityContent,
              characters: characterConfig.characters,
              globalAiChoice: characterConfig.globalAiChoice,
              l10n: context.l10n,
              aliasResolver: aliasResolver,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 负面提示词页签（官网 Undesired Content）
        Flexible(
          child: _PromptTypeButton(
            label: context.l10n.prompt_negativeTab,
            isSelected: _isNegativeMode,
            onTap: () => _setNegativeMode(true),
            tooltipBuilder: (theme) => _NegativePromptTooltip(
              theme: theme,
              userNegativePrompt: _negativeController.text,
              ucPresetContent: ucPresetContent,
              l10n: context.l10n,
              aliasResolver: aliasResolver,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextPromptInput(ThemeData theme, bool numericEmphasisEnabled) {
    final enableAutocomplete = ref.watch(autocompleteSettingsProvider);
    final enableAutoFormat = ref.watch(autoFormatPromptSettingsProvider);
    final enableHighlight = ref.watch(highlightEmphasisSettingsProvider);
    final enableSdSyntaxAutoConvert = ref.watch(
      sdSyntaxAutoConvertSettingsProvider,
    );
    return PromptPillEditor(
      key: const ValueKey('generation_prompt_positive_input'),
      compact: false,
      autoGrow: widget.autoGrow,
      minLines: widget.autoGrow ? 4 : null,
      allowEvolutionToggle: widget.allowEvolutionToggle,
      config: UnifiedPromptConfig(
        embedded: true,
        enableSyntaxHighlight: enableHighlight,
        numericEmphasisEnabled: numericEmphasisEnabled,
        enableAutocomplete: enableAutocomplete,
        enableAutoFormat: enableAutoFormat,
        enableSdSyntaxAutoConvert: enableSdSyntaxAutoConvert,
        enableComfyuiImport: true,
        autocompleteConfig: const AutocompleteConfig(
          showTranslation: true,
          showCategory: true,
          showCount: true,
          autoInsertComma: true,
        ),
        hintText: tipHint(
          context.l10n,
          widget.tipModule,
          epoch: watchTipEpoch(ref),
        ),
        // 官网式：框内右上小 ✕ 清空本文本（不再连带清角色卡）
        showClearButton: true,
      ),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.fromLTRB(10, 6, 26, 6),
      ),
      onComfyuiImport: (globalPrompt, characters) {
        // 清空现有角色并替换；块工作区由编辑器先切回纯文本。
        ref.read(characterPromptNotifierProvider.notifier).clearAll();
        ref
            .read(characterPromptNotifierProvider.notifier)
            .replaceAll(characters);
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updatePrompt(globalPrompt);
        AppToast.success(
          context,
          context.l10n.prompt_importedCharacters(characters.length),
        );
      },
      onChanged: (value) {
        _setProxyText(_promptController, value);
        ref.read(generationParamsNotifierProvider.notifier).updatePrompt(value);
      },
    );
  }

  PopupMenuItem<String> _buildSettingsMenuItem({
    required String value,
    required bool isEnabled,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: isEnabled ? theme.colorScheme.primary : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构造「点击后打开子界面」的菜单项（区别于勾选式开关项）
  PopupMenuItem<String> _buildSettingsActionMenuItem({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
        ],
      ),
    );
  }

  void _handleSettingsMenuResult(String? value) {
    switch (value) {
      case 'block_library':
        ref
            .read(layoutStateNotifierProvider.notifier)
            .toggleBlockLibraryPanel();
      case 'autocomplete':
        ref.read(autocompleteSettingsProvider.notifier).toggle();
      case 'auto_format':
        ref.read(autoFormatPromptSettingsProvider.notifier).toggle();
      case 'highlight':
        ref.read(highlightEmphasisSettingsProvider.notifier).toggle();
      case 'sd_syntax_convert':
        ref.read(sdSyntaxAutoConvertSettingsProvider.notifier).toggle();
      case 'regex_rules':
        // 菜单关闭后才回调到这里，需要重新确认 State 仍然挂载
        if (mounted) {
          RegexRulesDialog.show(context);
        }
      case 'resolve_alias_on_copy':
        ref.read(resolveAliasOnCopySettingsProvider.notifier).toggle();
      case 'cooccurrence':
        final provider = completion_settings.autocompleteSettingsProvider;
        final current = ref.read(provider).relatedTagsEnabled;
        ref.read(provider.notifier).setRelatedTagsEnabled(!current);
    }
  }

  Widget _buildTextNegativeInput(ThemeData theme, bool numericEmphasisEnabled) {
    final enableAutocomplete = ref.watch(autocompleteSettingsProvider);
    final enableAutoFormat = ref.watch(autoFormatPromptSettingsProvider);
    final enableHighlight = ref.watch(highlightEmphasisSettingsProvider);
    final enableSdSyntaxAutoConvert = ref.watch(
      sdSyntaxAutoConvertSettingsProvider,
    );
    // P3：负向框同换单框药丸编辑器（旧段式编辑器连 38px 侧图标条一并退场）
    return PromptPillEditor(
      key: const ValueKey('generation_prompt_negative_input'),
      pillScope: PillScopes.negative,
      initialPlainText: _negativeController.text,
      compact: false,
      autoGrow: widget.autoGrow,
      minLines: widget.autoGrow ? 4 : null,
      allowEvolutionToggle: false,
      config: UnifiedPromptConfig(
        embedded: true,
        enableSyntaxHighlight: enableHighlight,
        numericEmphasisEnabled: numericEmphasisEnabled,
        enableAutocomplete: enableAutocomplete,
        enableAutoFormat: enableAutoFormat,
        enableSdSyntaxAutoConvert: enableSdSyntaxAutoConvert,
        enableComfyuiImport: false,
        autocompleteConfig: const AutocompleteConfig(
          showTranslation: true,
          showCategory: false,
          autoInsertComma: true,
        ),
        hintText: context.l10n.prompt_unwantedContent,
        showClearButton: true,
      ),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.fromLTRB(10, 6, 26, 6),
      ),
      onChanged: (value) {
        _setProxyText(_negativeController, value);
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updateNegativePrompt(value);
      },
    );
  }

  Widget _buildCompactLayout(ThemeData theme, bool numericEmphasisEnabled) {
    final enableHighlight = ref.watch(highlightEmphasisSettingsProvider);
    final enableAutocomplete = ref.watch(autocompleteSettingsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 72,
          child: PromptPillEditor(
            key: const ValueKey('generation_prompt_positive_input'),
            compact: true,
            minLines: 1,
            allowEvolutionToggle: widget.allowEvolutionToggle,
            config: UnifiedPromptConfig(
              enableSyntaxHighlight: enableHighlight,
              numericEmphasisEnabled: numericEmphasisEnabled,
              enableAutocomplete: enableAutocomplete,
              enableComfyuiImport: true,
              autocompleteConfig: const AutocompleteConfig(
                showTranslation: true,
                autoInsertComma: true,
              ),
              hintText: tipHint(
                context.l10n,
                widget.tipModule,
                epoch: watchTipEpoch(ref),
              ),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showMaximizeButton)
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: context.l10n.tooltip_fullscreenEdit,
                      onPressed:
                          widget.onToggleMaximize ??
                          () => ref
                              .read(promptMaximizeNotifierProvider.notifier)
                              .toggle(),
                    ),
                  if (_promptController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearPrompt,
                    ),
                ],
              ),
            ),
            onComfyuiImport: (globalPrompt, characters) {
              ref.read(characterPromptNotifierProvider.notifier).clearAll();
              ref
                  .read(characterPromptNotifierProvider.notifier)
                  .replaceAll(characters);
              ref
                  .read(generationParamsNotifierProvider.notifier)
                  .updatePrompt(globalPrompt);
              AppToast.success(
                context,
                context.l10n.prompt_importedCharacters(characters.length),
              );
            },
            onChanged: (value) {
              _setProxyText(_promptController, value);
              ref
                  .read(generationParamsNotifierProvider.notifier)
                  .updatePrompt(value);
            },
          ),
        ),
        const _PromptTokenCountFooter(
          target: PromptTokenCountTarget.positive,
          topPadding: 4,
        ),
      ],
    );
  }
}

class _PromptTokenCountFooter extends ConsumerWidget {
  const _PromptTokenCountFooter({
    required this.target,
    required this.topPadding,
  });

  final PromptTokenCountTarget target;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenUsage = ref.watch(promptTokenUsageProvider(target));
    return Padding(
      padding: EdgeInsets.fromLTRB(10, topPadding, 10, 6),
      child: RepaintBoundary(
        child: PromptTokenCountAsyncBar(usage: tokenUsage),
      ),
    );
  }
}

/// 正面提示词悬浮提示内容
class _PositivePromptTooltip extends StatelessWidget {
  final ThemeData theme;
  final String userPrompt;
  final PromptPresetMode qualityMode;
  final String? qualityContent;
  final List<CharacterPrompt> characters;
  final bool globalAiChoice;
  final AppLocalizations l10n;
  final AliasResolverService aliasResolver;

  const _PositivePromptTooltip({
    required this.theme,
    required this.userPrompt,
    required this.qualityMode,
    required this.qualityContent,
    required this.characters,
    required this.globalAiChoice,
    required this.l10n,
    required this.aliasResolver,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final hasQuality = qualityContent != null && qualityContent!.isNotEmpty;
    final enabledCharacters = characters
        .where((c) => c.enabled && c.prompt.isNotEmpty)
        .toList();
    final hasCharacters = enabledCharacters.isNotEmpty;

    // 构建最终生效的完整提示词
    final effectivePrompt = _buildEffectivePrompt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部统计标题
        _buildHeader(isDark),

        const SizedBox(height: 10),

        // 用户输入 - 解析别名
        if (userPrompt.trim().isNotEmpty) ...[
          _buildSection(
            icon: Icons.edit_rounded,
            label: l10n.prompt_mainPositive,
            color: theme.colorScheme.secondary,
            content: aliasResolver.resolveAliases(userPrompt.trim()),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ],

        // 质量词
        if (hasQuality) ...[
          _buildSection(
            icon: Icons.star_rounded,
            label: l10n.qualityTags_positive,
            color: Colors.amber,
            content: qualityContent!,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ],

        // 多角色提示词
        if (hasCharacters) ...[
          _buildCharacterSection(enabledCharacters, isDark),
          const SizedBox(height: 8),
        ],

        // 分隔线
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // 最终生效提示词
        _buildFinalPromptSection(effectivePrompt, isDark),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            l10n.prompt_positivePrompt,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required Color color,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.4)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all(true),
                thickness: WidgetStateProperty.all(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPromptSection(String prompt, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(
              alpha: isDark ? 0.3 : 0.4,
            ),
            theme.colorScheme.secondaryContainer.withValues(
              alpha: isDark ? 0.2 : 0.3,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.output_rounded,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.prompt_finalPrompt,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              // 复制按钮
              _CopyIconButton(
                content: prompt,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all(true),
                thickness: WidgetStateProperty.all(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildEffectivePrompt() {
    final parts = <String>[];

    // 用户输入（解析别名）
    if (userPrompt.trim().isNotEmpty) {
      parts.add(aliasResolver.resolveAliases(userPrompt.trim()));
    }

    // 质量词
    if (qualityContent != null && qualityContent!.isNotEmpty) {
      parts.add(qualityContent!);
    }

    // 多角色提示词
    final enabledCharacters = characters.where(
      (c) => c.enabled && c.prompt.isNotEmpty,
    );
    for (final character in enabledCharacters) {
      parts.add(character.toNaiPrompt(useAiPosition: globalAiChoice));
    }

    return parts.join(', ');
  }

  Widget _buildCharacterSection(
    List<CharacterPrompt> enabledCharacters,
    bool isDark,
  ) {
    const color = Colors.teal;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.4)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.people_rounded, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                l10n.prompt_characterPrompts,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${enabledCharacters.length}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: enabledCharacters.map((character) {
                  final name = character.customName.isEmpty
                      ? l10n.character_number(characters.indexOf(character) + 1)
                      : character.customName;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          character.gender == CharacterGender.female
                              ? Icons.female
                              : character.gender == CharacterGender.male
                              ? Icons.male
                              : Icons.person,
                          size: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$name: ${character.toNaiPrompt(useAiPosition: globalAiChoice)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 负面提示词悬浮提示内容
class _NegativePromptTooltip extends StatelessWidget {
  final ThemeData theme;
  final String userNegativePrompt;
  final String ucPresetContent;
  final AppLocalizations l10n;
  final AliasResolverService aliasResolver;

  const _NegativePromptTooltip({
    required this.theme,
    required this.userNegativePrompt,
    required this.ucPresetContent,
    required this.l10n,
    required this.aliasResolver,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final hasUserInput = userNegativePrompt.trim().isNotEmpty;
    final hasPreset = ucPresetContent.isNotEmpty;

    // 构建最终生效的完整负面提示词
    final effectiveNegative = _buildEffectiveNegative();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部标题
        _buildHeader(isDark),

        const SizedBox(height: 10),

        // UC预设
        if (hasPreset) ...[
          _buildSection(
            icon: Icons.shield_rounded,
            label: l10n.qualityTags_negative,
            color: theme.colorScheme.error,
            content: ucPresetContent,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ],

        // 用户输入 - 解析别名
        if (hasUserInput) ...[
          _buildSection(
            icon: Icons.edit_rounded,
            label: l10n.prompt_mainNegative,
            color: theme.colorScheme.tertiary,
            content: aliasResolver.resolveAliases(userNegativePrompt.trim()),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ],

        // 分隔线
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // 最终生效负面提示词
        _buildFinalSection(effectiveNegative, isDark),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error.withValues(alpha: isDark ? 0.2 : 0.1),
            theme.colorScheme.error.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 14, color: theme.colorScheme.error),
          const SizedBox(width: 6),
          Text(
            l10n.prompt_negativePrompt,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required Color color,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.4)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all(true),
                thickness: WidgetStateProperty.all(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSection(String prompt, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.errorContainer.withValues(
              alpha: isDark ? 0.3 : 0.4,
            ),
            theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.2 : 0.3,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.output_rounded,
                size: 12,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.prompt_finalNegative,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
              const Spacer(),
              // 复制按钮
              if (prompt.isNotEmpty)
                _CopyIconButton(
                  content: prompt,
                  color: theme.colorScheme.error,
                ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbVisibility: WidgetStateProperty.all(true),
                thickness: WidgetStateProperty.all(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  prompt.isEmpty ? '-' : prompt,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildEffectiveNegative() {
    final parts = <String>[];

    // UC预设
    if (ucPresetContent.isNotEmpty) {
      parts.add(ucPresetContent);
    }

    if (userNegativePrompt.trim().isNotEmpty) {
      parts.add(aliasResolver.resolveAliases(userNegativePrompt.trim()));
    }

    return parts.join(', ');
  }
}

/// 提示词类型切换页签（官网式：中性色，选中项底色高亮，无主题色）
class _PromptTypeButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget Function(ThemeData theme)? tooltipBuilder;

  const _PromptTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.tooltipBuilder,
  });

  @override
  State<_PromptTypeButton> createState() => _PromptTypeButtonState();
}

class _PromptTypeButtonState extends State<_PromptTypeButton>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useRichTooltip = usesRichPromptTypeTooltip(theme.platform);

    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              // 官网式：选中项中性底色高亮，未选中悬停才出底
              color: widget.isSelected
                  ? GenSidebarStyle.selectedSurface(theme)
                  : (_isHovering
                        ? theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          )
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // 官网 Base/Undesired 页签档：13px、选中 600
              style: GenSidebarStyle.tabLabel(
                theme,
                selected: widget.isSelected,
              ),
            ),
          ),
        ),
      ),
    );

    // 如果有 tooltipBuilder，包裹 Tooltip
    if (widget.tooltipBuilder != null) {
      return Tooltip(
        message: useRichTooltip ? null : widget.label,
        richMessage: useRichTooltip
            ? WidgetSpan(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: widget.tooltipBuilder!(theme),
                ),
              )
            : null,
        preferBelow: true,
        verticalOffset: 20,
        waitDuration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: button,
      );
    }

    return button;
  }
}

/// 复制图标按钮
class _CopyIconButton extends StatefulWidget {
  final String content;
  final Color color;

  const _CopyIconButton({required this.content, required this.color});

  @override
  State<_CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<_CopyIconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.content));
          if (context.mounted) {
            AppToast.success(context, l10n.common_copied);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _isHovering
                ? widget.color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.copy_rounded,
            size: 14,
            color: _isHovering
                ? widget.color
                : widget.color.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
