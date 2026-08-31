import 'package:flutter/material.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_prompt_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/pill_workspace_provider.dart';
import '../prompt/pills/prompt_pill_editor.dart';
import '../prompt/unified/unified.dart';

/// 角色提示词编辑器（正/负切换 + 药丸块编辑器）
///
/// 官网布局的卡内编辑与经典布局的全宽编辑面板共用。
/// P3 起两个 tab 均为单框药丸编辑器，lane 按 `char:<id>:pos/neg` 隔离；
/// 投影实时写回 provider（`updateCharacter`）。
///
/// [autoFocus] 控制挂载/切换角色时是否自动把光标送进输入框：
/// 经典布局面板（true）打开即聚焦省一次点击；官网布局常驻卡
/// （false）多卡同时在场，自动聚焦会互相抢焦点，改为点击聚焦。
class CharacterPromptEditor extends ConsumerStatefulWidget {
  final CharacterPrompt character;
  final bool compact;
  final bool autoFocus;

  const CharacterPromptEditor({
    super.key,
    required this.character,
    this.compact = false,
    this.autoFocus = true,
  });

  @override
  ConsumerState<CharacterPromptEditor> createState() =>
      _CharacterPromptEditorState();
}

class _CharacterPromptEditorState extends ConsumerState<CharacterPromptEditor> {
  /// 0 = 正向提示词，1 = 负向提示词
  int _tabIndex = 0;

  String get _posScope => PillScopes.charPos(widget.character.id);
  String get _negScope => PillScopes.charNeg(widget.character.id);

  @override
  void didUpdateWidget(CharacterPromptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换编辑目标：pill scope 随 character.id 变化，
    // PromptPillEditor.didUpdateWidget 自行重绑文档+按需播种，无需干预。
    if (oldWidget.character.id != widget.character.id) {
      return;
    }
    // 外部状态变化（随机生成、词库导入、桥接写入等）：投影不等时重建。
    // 本框自身 onChanged 回写时投影与文本相等 → syncFromPlainText 天然
    // no-op，不打断输入连接。
    // 注意 didUpdateWidget 处于构建期，写 provider 必须延后到帧末。
    final promptChanged =
        widget.character.prompt != oldWidget.character.prompt;
    final negativeChanged =
        widget.character.negativePrompt != oldWidget.character.negativePrompt;
    if (promptChanged || negativeChanged) {
      final posScope = _posScope;
      final negScope = _negScope;
      final prompt = widget.character.prompt;
      final negative = widget.character.negativePrompt;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (promptChanged) {
          ref
              .read(pillWorkspaceProvider(posScope).notifier)
              .syncFromPlainText(prompt);
        }
        if (negativeChanged) {
          ref
              .read(pillWorkspaceProvider(negScope).notifier)
              .syncFromPlainText(negative);
        }
      });
    }
  }

  void _updateCharacter(CharacterPrompt updated) {
    ref.read(characterPromptNotifierProvider.notifier).updateCharacter(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _EditorTab(
              label: l10n.prompt_positivePrompt,
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            const SizedBox(width: 6),
            _EditorTab(
              label: l10n.prompt_negativePrompt,
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_tabIndex == 0)
          _buildPillLaneEditor(
            scope: _posScope,
            initialText: widget.character.prompt,
            hintText: l10n.characterEditor_promptHint,
            onChanged: (value) =>
                _updateCharacter(widget.character.copyWith(prompt: value)),
          )
        else
          _buildPillLaneEditor(
            scope: _negScope,
            initialText: widget.character.negativePrompt,
            hintText: l10n.characterEditor_negativePromptHint,
            onChanged: (value) => _updateCharacter(
              widget.character.copyWith(negativePrompt: value),
            ),
          ),
      ],
    );
  }

  Widget _buildPillLaneEditor({
    required String scope,
    required String initialText,
    required String? hintText,
    required ValueChanged<String> onChanged,
  }) {
    final enableAutocomplete = ref.watch(autocompleteSettingsProvider);
    final enableAutoFormat = ref.watch(autoFormatPromptSettingsProvider);
    final enableHighlight = ref.watch(highlightEmphasisSettingsProvider);
    final enableSdSyntaxAutoConvert = ref.watch(
      sdSyntaxAutoConvertSettingsProvider,
    );

    return PromptPillEditor(
      // key 随 scope 走：tab 切换/换角色时 State 不串文档
      key: ValueKey('character-pill-$scope'),
      pillScope: scope,
      initialPlainText: initialText,
      compact: widget.compact,
      // 常驻卡（非 compact，官网布局）跟随内容自增高：3 行起步、12 行封顶，
      // 封顶后框内滚动；经典布局面板（compact）维持 1/4 紧凑规格
      minLines: widget.compact ? 1 : 3,
      maxLines: widget.compact ? 4 : 12,
      config: UnifiedPromptConfig.compactMode.copyWith(
        hintText: hintText,
        enableAutocomplete: enableAutocomplete,
        enableAutoFormat: enableAutoFormat,
        enableSyntaxHighlight: enableHighlight,
        enableSdSyntaxAutoConvert: enableSdSyntaxAutoConvert,
        // 清空由 UnifiedPromptInput 内部处理并回调 onChanged('')，无需重复
        showClearButton: true,
        clearNeedsConfirm: true,
      ),
      onChanged: onChanged,
    );
  }
}

/// 编辑态正/负切换小标签
class _EditorTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EditorTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// 清空全部角色（带确认框），官网布局区块头与经典布局角色行共用
Future<void> confirmClearAllCharacters(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.characterEditor_clearAllTitle),
      content: Text(l10n.characterEditor_clearAllConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.common_clear),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    ref.read(selectedCharacterIdProvider.notifier).clear();
    ref.read(characterPromptNotifierProvider.notifier).clearAllCharacters();
  }
}

/// 角色名称就地编辑框
///
/// 嵌在卡片/编辑面板头部的名字位置，点击即可直接改名，
/// 输入实时写回 provider（空白输入不生效，保留原名）。
class CharacterNameField extends ConsumerStatefulWidget {
  final CharacterPrompt character;
  final TextStyle? style;

  const CharacterNameField({super.key, required this.character, this.style});

  @override
  ConsumerState<CharacterNameField> createState() => _CharacterNameFieldState();
}

class _CharacterNameFieldState extends ConsumerState<CharacterNameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.character.name,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 失焦提交：输入过程完全本地，不触发 provider 更新与整卡重建，
    // 焦点和光标不会被打断
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty || trimmed == widget.character.name) return;
    ref
        .read(characterPromptNotifierProvider.notifier)
        .updateCharacter(widget.character.copyWith(name: trimmed));
  }

  @override
  void didUpdateWidget(CharacterNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _controller.text = widget.character.name;
      return;
    }
    // 外部改名（如词库导入覆盖）时同步；编辑中（持有焦点）不覆盖用户输入
    if (!_focusNode.hasFocus && widget.character.name != _controller.text) {
      _controller.text = widget.character.name;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLength: 50,
      maxLines: 1,
      style: widget.style,
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        counterText: '',
        border: InputBorder.none,
        hintText: l10n.characterEditor_nameHint,
        hintStyle: widget.style?.copyWith(
          color: widget.style?.color?.withValues(alpha: 0.5),
        ),
      ),
      onSubmitted: (_) => _commit(),
    );
  }
}
