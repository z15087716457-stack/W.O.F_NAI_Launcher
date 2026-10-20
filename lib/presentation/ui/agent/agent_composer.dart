import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import '../kit/ui_tip.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_popovers.dart';
import 'agent_scope.dart';

/// 输入区：快捷任务 / 排队行 / 输入框（附件、`@` 引用、`/` 技能）/ 控制条。
class AgentComposer extends StatefulWidget {
  const AgentComposer({super.key, required this.chatId});

  /// 换聊天时整体重建输入框文字。
  final String chatId;

  @override
  State<AgentComposer> createState() => AgentComposerState();
}

class _PasteIntent extends Intent {
  const _PasteIntent();
}

class AgentComposerState extends State<AgentComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode(debugLabel: 'agent-composer');
  final _panelKey = GlobalKey();

  /// 积木分类下面板顶部的搜索框；与 `@查询` 同时生效。
  final _blockSearch = TextEditingController();
  final _blockSearchFocus = FocusNode(debugLabel: 'agent-block-search');

  /// 最近一次交给 [AgentActions.onComposerChanged] 的文字；外部改写（编辑消息、放回输入框）才同步回来。
  String? _sent;

  // `@` / `/` 候选
  ({int start, String query, bool slash})? _trigger;
  var _index = 0;
  AgentMentionKind? _category;

  UiPopoverAnchor? _attach, _model, _permission;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final external = AgentScope.of(context).data.composer.text;
    if (external != _sent) {
      _sent = external;
      if (external != _text.text) {
        _text.value = TextEditingValue(
          text: external,
          selection: TextSelection.collapsed(offset: external.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _blockSearch.dispose();
    _blockSearchFocus.dispose();
    super.dispose();
  }

  // ───────── 文字 ─────────

  void _changed(String value) {
    _sent = value;
    AgentScope.of(context).actions.onComposerChanged(value);
    _detect();
  }

  void _detect() {
    final v = _text.value;
    if (!v.selection.isValid || !v.selection.isCollapsed) {
      _closeMention();
      return;
    }
    final before = v.text.substring(0, v.selection.baseOffset);
    final at = RegExp(r'(?:^|\s)@([^\s@]*)$').firstMatch(before);
    final slash = RegExp(r'(?:^|\n)/([^\s/]*)$').firstMatch(before);
    final m = at ?? slash;
    if (m == null) {
      _closeMention();
      return;
    }
    final start = before.length - m.group(1)!.length - 1;
    final next = (start: start, query: m.group(1)!, slash: at == null);
    if (_trigger != next) {
      setState(() {
        if (_trigger?.query != next.query || _trigger?.slash != next.slash) {
          _index = 0;
        }
        _trigger = next;
      });
    }
  }

  /// @ 按钮再点一次：光标前正是刚插入、还没输入内容的 @，就删掉它（连同
  /// 按钮补的前导空格）并收起面板，而不是再叠一个。
  bool _toggleBareMention() {
    final t = _trigger;
    final v = _text.value;
    if (t == null || t.slash || t.query.isNotEmpty) return false;
    if (!v.selection.isValid || !v.selection.isCollapsed) return false;
    final caret = v.selection.baseOffset;
    if (caret != t.start + 1 || v.text[t.start] != '@') return false;
    var start = t.start;
    if (start > 0 &&
        v.text[start - 1] == ' ' &&
        (start == 1 || v.text[start - 2] != ' ')) {
      start--;
    }
    final next = v.text.replaceRange(start, caret, '');
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start),
    );
    _focus.requestFocus();
    _changed(next);
    return true;
  }

  void _closeMention() {
    if (_blockSearch.text.isNotEmpty) _blockSearch.clear();
    if (_blockSearchFocus.hasFocus) _focus.requestFocus();
    if (_trigger != null) setState(() => _trigger = null);
  }

  List<AgentMention> _mentions() {
    final t = _trigger!;
    return AgentMentionPanel.filter(
      AgentScope.of(context).data.mentions,
      t.query,
      _category,
      search: _category == AgentMentionKind.block ? _blockSearch.text : '',
    );
  }

  KeyEventResult _panelKeys(FocusNode node, KeyEvent event) {
    final n = _candidateCount();
    return agentPanelKeys(
      event,
      up: () => setState(() => _index = n == 0 ? 0 : (_index - 1) % n),
      down: () => setState(() => _index = n == 0 ? 0 : (_index + 1) % n),
      pick: n == 0 ? _closeMention : _pickIndex,
      tab: () {
        if (_trigger!.slash) {
          if (n > 0) _pickIndex();
          return;
        }
        const order = [
          null,
          AgentMentionKind.prompt,
          AgentMentionKind.image,
          AgentMentionKind.block,
        ];
        _setCategory(order[(order.indexOf(_category) + 1) % order.length]);
      },
      close: _closeMention,
    );
  }

  void _setCategory(AgentMentionKind? v) {
    setState(() {
      _category = v;
      _index = 0;
    });
    if (v != AgentMentionKind.block) {
      _blockSearch.clear();
      if (_blockSearchFocus.hasFocus) _focus.requestFocus();
    }
  }

  Widget _blockSearchBox(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: agentSunk(c),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: _blockSearchFocus.hasFocus ? c.accent : c.line,
          ),
        ),
        child: Row(
          spacing: 7,
          children: [
            AgentIcon(AgentGlyphs.search, size: 13, color: c.faint),
            Expanded(
              child: Focus(
                onKeyEvent: _panelKeys,
                onFocusChange: (_) => setState(() {}),
                child: TextField(
                  key: const Key('agent-block-search'),
                  controller: _blockSearch,
                  focusNode: _blockSearchFocus,
                  style: UiText.sans(12.5, color: c.ink, height: 1.3),
                  cursorColor: c.accent,
                  cursorWidth: 1.5,
                  onChanged: (_) => setState(() => _index = 0),
                  decoration: uiBareDecoration(
                    hintText: l.ag_mentionSearchBlocks,
                    hintStyle: UiText.sans(12.5, color: c.faint, height: 1.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 在光标处插入（[replace] = 换掉全部）。
  void insert(String text, {bool replace = false}) {
    final v = _text.value;
    final String next;
    final int caret;
    if (replace || v.text.trim().isEmpty) {
      next = text;
      caret = text.length;
    } else {
      final sel = v.selection.isValid
          ? v.selection
          : TextSelection.collapsed(offset: v.text.length);
      next = v.text.replaceRange(sel.start, sel.end, text);
      caret = sel.start + text.length;
    }
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret),
    );
    _focus.requestFocus();
    _changed(next);
  }

  void _pick(String insertText, String? imageId) {
    final t = _trigger;
    if (t == null) return;
    final v = _text.value;
    final end = v.selection.baseOffset;
    final next = v.text.replaceRange(t.start, end, insertText);
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: t.start + insertText.length),
    );
    _trigger = null;
    _changed(next);
    setState(() {});
    if (imageId != null) {
      final s = AgentScope.of(context);
      unawaited(s.run(() => s.actions.onAttachImage(imageId)));
    }
  }

  int _candidateCount() {
    final t = _trigger!;
    final d = AgentScope.of(context).data;
    return t.slash
        ? AgentMentionPanel.filterSkills(d.skills, t.query).length
        : _mentions().length;
  }

  void _pickIndex() {
    final t = _trigger!;
    final d = AgentScope.of(context).data;
    if (t.slash) {
      final list = AgentMentionPanel.filterSkills(d.skills, t.query);
      if (_index < list.length) _pick('/skill:${list[_index].name} ', null);
    } else {
      final list = _mentions();
      if (_index < list.length) {
        final m = list[_index];
        _pick('@${m.label} ', m.kind == AgentMentionKind.image ? m.id : null);
      }
    }
  }

  // ───────── 键盘 ─────────

  bool get _composing =>
      _text.value.composing.isValid && !_text.value.composing.isCollapsed;

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (_composing) return KeyEventResult.ignored;
    if (_trigger != null) return _panelKeys(node, event);
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    final k = HardwareKeyboard.instance;
    if (k.isShiftPressed || k.isAltPressed) return KeyEventResult.ignored;
    final enterSends = AgentScope.of(context).data.composer.enterSends;
    if (enterSends || k.isControlPressed || k.isMetaPressed) {
      _send(steer: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _send({required bool steer}) {
    final s = AgentScope.of(context);
    if (!s.data.composer.canSend || _composing) return;
    unawaited(s.run(() => s.actions.onSend(steer: steer)));
  }

  Future<void> _paste() async {
    final s = AgentScope.of(context);
    final text = await s.actions.onPaste();
    if (text != null && mounted) insert(text);
  }

  UiPopoverAnchor _above(BuildContext context, {bool right = false}) {
    final box = context.findRenderObject()! as RenderBox;
    final corner = right
        ? box.size.topRight(const Offset(0, -6))
        : box.size.topLeft(const Offset(0, -6));
    return UiPopoverAnchor(
      box.localToGlobal(corner),
      alignBottom: true,
      alignRight: right,
    );
  }

  // ───────── 构建 ─────────

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data;
    final comp = d.composer;
    final c = context.ui;
    final l = context.l10n;
    final focused = _focus.hasFocus;
    return Container(
      key: const Key('agent-composer'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (_trigger != null)
            AgentMentionPanel(
              key: _panelKey,
              query: _trigger!.query,
              slash: _trigger!.slash,
              index: _index,
              category: _category,
              onCategory: _setCategory,
              onPick: _pick,
              search: _category == AgentMentionKind.block
                  ? _blockSearchBox(context)
                  : null,
              searchText: _category == AgentMentionKind.block
                  ? _blockSearch.text
                  : '',
            ),
          if (d.notices.isNotEmpty) _Notices(lines: d.notices),
          for (final q in comp.queue) _QueueLine(item: q),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: focused ? c.accent : c.strong),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: .12),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (comp.attachments.isNotEmpty || comp.importing > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final a in comp.attachments)
                          _AttachmentChip(attachment: a),
                        if (comp.importing > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 6,
                            children: [
                              const AgentStepDot(kind: AgentDotKind.running),
                              Text(
                                l.ag_importing(comp.importing),
                                style: UiText.sans(11.5, color: c.muted),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                Shortcuts(
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.keyV, control: true):
                        _PasteIntent(),
                    SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                        _PasteIntent(),
                  },
                  child: Actions(
                    actions: {
                      _PasteIntent: CallbackAction<_PasteIntent>(
                        onInvoke: (_) {
                          unawaited(_paste());
                          return null;
                        },
                      ),
                      PasteTextIntent: CallbackAction<PasteTextIntent>(
                        onInvoke: (_) {
                          unawaited(_paste());
                          return null;
                        },
                      ),
                    },
                    child: Focus(
                      onKeyEvent: _key,
                      onFocusChange: (_) => setState(() {}),
                      child: TextField(
                        key: const Key('agent-input'),
                        controller: _text,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 8,
                        onChanged: _changed,
                        onTap: _detect,
                        style: UiText.sans(13.5, color: c.ink, height: 1.6),
                        cursorColor: c.accent,
                        cursorWidth: 1.5,
                        contextMenuBuilder: (context, editable) =>
                            AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: editable.contextMenuAnchors,
                              buttonItems: [
                                for (final item
                                    in editable.contextMenuButtonItems)
                                  if (item.type == ContextMenuButtonType.paste)
                                    ContextMenuButtonItem(
                                      type: ContextMenuButtonType.paste,
                                      onPressed: () {
                                        ContextMenuController.removeAny();
                                        unawaited(_paste());
                                      },
                                    )
                                  else
                                    item,
                              ],
                            ),
                        decoration: agentBareInput(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                          constraints: const BoxConstraints(minHeight: 44),
                          hint: l.ag_placeholder,
                          hintMaxLines: 1,
                          hintStyle: UiText.sans(
                            13.5,
                            color: c.faint,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (comp.blocked == AgentSendBlock.noModel)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
                    child: Text(
                      l.ag_noModel,
                      style: UiText.sans(11.5, color: c.warn),
                    ),
                  ),
                _bar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context) {
    final s = AgentScope.of(context);
    final d = s.data;
    final comp = d.composer;
    final c = context.ui;
    final l = context.l10n;
    final running = d.status != AgentRunStatus.idle;
    final model = d.models.where((m) => m.selected).firstOrNull;
    final thinking = d.thinking.followsModel
        ? null
        : d.thinking.options
              .where((o) => o.$1 == d.thinking.selected)
              .firstOrNull
              ?.$2;
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 400;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
          child: Row(
            spacing: 4,
            children: [
              UiPopover(
                anchor: _attach,
                onDismiss: () => setState(() => _attach = null),
                builder: (_) => _attachMenu(context),
                child: Builder(
                  builder: (context) => AgentIconButton(
                    key: const Key('agent-attach'),
                    small: true,
                    glyph: AgentGlyphs.clip,
                    tooltip: l.ag_attach,
                    active: _attach != null,
                    onPressed: () => setState(() => _attach = _above(context)),
                  ),
                ),
              ),
              AgentIconButton(
                key: const Key('agent-mention'),
                small: true,
                glyph: AgentGlyphs.at,
                tooltip: l.ag_mention,
                onPressed: () {
                  if (_toggleBareMention()) return;
                  final v = _text.value;
                  final before = v.selection.isValid
                      ? v.text.substring(0, v.selection.start)
                      : v.text;
                  insert(
                    before.isEmpty ||
                            before.endsWith(' ') ||
                            before.endsWith('\n')
                        ? '@'
                        : ' @',
                  );
                  _detect();
                },
              ),
              const SizedBox(width: 2),
              UiPopover(
                anchor: _permission,
                onDismiss: () => setState(() => _permission = null),
                builder: (_) => AgentPermissionPopover(
                  onClose: () => setState(() => _permission = null),
                ),
                child: Builder(
                  builder: (context) => _Pill(
                    key: const Key('agent-permission'),
                    open: _permission != null,
                    warn: d.permission == AgentPermissionMode.bypass,
                    tooltip: agentPermissionHint(context, d.permission),
                    onTap: () => setState(() => _permission = _above(context)),
                    children: [
                      AgentIcon(
                        agentPermissionGlyph(d.permission),
                        size: 12,
                        color: d.permission == AgentPermissionMode.bypass
                            ? c.error
                            : c.ink,
                      ),
                      Text(
                        agentPermissionLabel(context, d.permission),
                        style: UiText.sans(
                          11.5,
                          weight: FontWeight.w500,
                          color: d.permission == AgentPermissionMode.bypass
                              ? c.error
                              : c.ink,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: UiPopover(
                    anchor: _model,
                    onDismiss: () => setState(() => _model = null),
                    builder: (_) => AgentModelPopover(
                      onClose: () => setState(() => _model = null),
                    ),
                    child: Builder(
                      builder: (context) => _Pill(
                        key: const Key('agent-model'),
                        open: _model != null,
                        tooltip: l.ag_modelPicker,
                        onTap: () => setState(
                          () => _model = _above(context, right: true),
                        ),
                        children: [
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: narrow ? 64 : 120,
                              ),
                              child: Text(
                                model?.label ?? l.ag_modelNone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(
                                  11.5,
                                  weight: FontWeight.w500,
                                  color: model == null ? c.warn : c.ink,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          if (thinking != null)
                            Text(
                              thinking,
                              style: UiText.sans(
                                11.5,
                                color: c.faint,
                                height: 1.2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              if (running &&
                  _text.text.trim().isEmpty &&
                  comp.attachments.isEmpty)
                AgentButton(
                  key: const Key('agent-stop'),
                  label: l.ag_stop,
                  glyph: AgentGlyphs.stop,
                  style: AgentButtonStyle.danger,
                  height: 28,
                  onPressed: () => s.run(s.actions.onStop),
                )
              else if (running) ...[
                AgentIconButton(
                  key: const Key('agent-stop'),
                  glyph: AgentGlyphs.stop,
                  tooltip: l.ag_stop,
                  color: c.error,
                  onPressed: () => s.run(s.actions.onStop),
                ),
                _QueueSend(
                  enabled: comp.canSend,
                  onSend: (steer) => _send(steer: steer),
                ),
              ] else
                AgentButton(
                  key: const Key('agent-send'),
                  label: l.ag_send,
                  style: AgentButtonStyle.primary,
                  height: 28,
                  onPressed: comp.canSend ? () => _send(steer: false) : null,
                  trailing: Text(
                    comp.enterSends ? '↵' : 'Ctrl ↵',
                    style: UiText.mono(
                      11,
                      color: (comp.canSend ? c.bg : c.faint).withValues(
                        alpha: .6,
                      ),
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachMenu(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    void close() => setState(() => _attach = null);
    Widget row(
      Key key,
      String glyph,
      String label,
      VoidCallback? onTap,
    ) => AgentPopRow(
      key: key,
      onTap: onTap == null
          ? null
          : () {
              close();
              onTap();
            },
      child: Row(
        spacing: 9,
        children: [
          AgentIcon(glyph, size: 14, color: onTap == null ? c.faint : c.muted),
          Text(
            label,
            style: UiText.sans(12.5, color: onTap == null ? c.faint : c.ink),
          ),
        ],
      ),
    );
    return UiPopoverSurface(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(
              const Key('agent-attach-file'),
              AgentGlyphs.folder,
              l.ag_attachFile,
              () => s.run(s.actions.onPickImages),
            ),
            row(
              const Key('agent-attach-canvas'),
              AgentGlyphs.image,
              l.ag_attachCanvas,
              s.data.composer.canAttachCanvas
                  ? () => s.run(s.actions.onAttachCanvas)
                  : null,
            ),
            row(
              const Key('agent-attach-paste'),
              AgentGlyphs.copy,
              l.ag_attachPaste,
              () => unawaited(_paste()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatefulWidget {
  const _Pill({
    super.key,
    required this.children,
    required this.onTap,
    this.open = false,
    this.warn = false,
    this.tooltip,
  });
  final List<Widget> children;
  final VoidCallback onTap;
  final bool open;

  /// 警示色（完全权限）。
  final bool warn;
  final String? tooltip;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget pill = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 26,
          padding: const EdgeInsets.only(left: 8, right: 6),
          decoration: BoxDecoration(
            color: widget.warn
                ? c.error.withValues(alpha: widget.open || _hover ? .16 : .1)
                : widget.open || _hover
                ? c.hover
                : c.control,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              ...widget.children,
              AgentIcon(AgentGlyphs.chevron, size: 12, color: c.faint),
            ],
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      pill = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: pill,
      );
    }
    return pill;
  }
}

/// 运行中有文字：排队发送 + 下拉「作为引导插入」。
class _QueueSend extends StatefulWidget {
  const _QueueSend({required this.enabled, required this.onSend});
  final bool enabled;
  final ValueChanged<bool> onSend;

  @override
  State<_QueueSend> createState() => _QueueSendState();
}

class _QueueSendState extends State<_QueueSend> {
  UiPopoverAnchor? _menu;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    Widget row(Key key, String glyph, String title, String hint, bool steer) =>
        AgentPopRow(
          key: key,
          height: 46,
          onTap: () {
            setState(() => _menu = null);
            widget.onSend(steer);
          },
          child: Row(
            spacing: 9,
            children: [
              AgentIcon(glyph, size: 14, color: c.muted),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UiText.sans(
                        12.5,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    Text(hint, style: UiText.sans(11, color: c.faint)),
                  ],
                ),
              ),
            ],
          ),
        );
    return UiPopover(
      anchor: _menu,
      onDismiss: () => setState(() => _menu = null),
      builder: (_) => UiPopoverSurface(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(
                const Key('agent-send-queue'),
                AgentGlyphs.clock,
                l.ag_sendQueue,
                l.ag_sendQueueHint,
                false,
              ),
              row(
                const Key('agent-send-steer'),
                AgentGlyphs.steer,
                l.ag_sendSteer,
                l.ag_sendSteerHint,
                true,
              ),
            ],
          ),
        ),
      ),
      child: Builder(
        builder: (context) => AgentButton(
          key: const Key('agent-send'),
          label: l.ag_sendQueue,
          style: AgentButtonStyle.primary,
          height: 28,
          onPressed: widget.enabled ? () => widget.onSend(false) : null,
          trailing: GestureDetector(
            key: const Key('agent-send-more'),
            onTap: widget.enabled
                ? () {
                    final box = context.findRenderObject()! as RenderBox;
                    setState(
                      () => _menu = UiPopoverAnchor(
                        box.localToGlobal(
                          box.size.topRight(const Offset(0, -6)),
                        ),
                        alignBottom: true,
                        alignRight: true,
                      ),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: AgentIcon(
                AgentGlyphs.chevron,
                size: 12,
                color: widget.enabled ? c.bg : c.faint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueLine extends StatelessWidget {
  const _QueueLine({required this.item});
  final AgentQueued item;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    final recovered = item.kind == AgentQueueKind.recovered;
    return Container(
      key: Key('agent-queue-${item.id}'),
      height: 34,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: agentSunk(c),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recovered ? c.warn.withValues(alpha: .5) : c.border,
        ),
      ),
      child: Row(
        spacing: 8,
        children: [
          AgentIcon(
            switch (item.kind) {
              AgentQueueKind.queued => AgentGlyphs.clock,
              AgentQueueKind.steer => AgentGlyphs.steer,
              AgentQueueKind.recovered => AgentGlyphs.undo,
            },
            size: 14,
            color: recovered ? c.warn : c.faint,
          ),
          Text(switch (item.kind) {
            AgentQueueKind.queued => l.ag_queued,
            AgentQueueKind.steer => l.ag_steering,
            AgentQueueKind.recovered => l.ag_recovered,
          }, style: UiText.sans(12, color: recovered ? c.warn : c.faint)),
          Expanded(
            child: Text(
              item.text.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.ink),
            ),
          ),
          if (recovered)
            AgentButton(
              label: l.ag_queueRestore,
              style: AgentButtonStyle.ghost,
              height: 24,
              onPressed: () => s.run(() => s.actions.onRestoreQueued(item.id)),
            )
          else ...[
            if (item.kind == AgentQueueKind.queued)
              AgentButton(
                key: Key('agent-queue-steer-${item.id}'),
                label: l.ag_queueSteer,
                style: AgentButtonStyle.ghost,
                height: 24,
                onPressed: () => s.run(() => s.actions.onSteerQueued(item.id)),
              ),
            AgentIconButton(
              small: true,
              glyph: AgentGlyphs.pen,
              tooltip: l.ag_queueEdit,
              onPressed: () => s.rename(
                title: l.ag_queueEdit,
                value: item.text,
                save: (v) => s.actions.onEditQueued(item.id, v),
              ),
            ),
          ],
          AgentIconButton(
            key: Key('agent-queue-withdraw-${item.id}'),
            small: true,
            glyph: AgentGlyphs.close,
            tooltip: l.ag_queueWithdraw,
            onPressed: () => s.run(() => s.actions.onWithdrawQueued(item.id)),
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatefulWidget {
  const _AttachmentChip({required this.attachment});
  final AgentAttachment attachment;

  @override
  State<_AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<_AttachmentChip> {
  var _hover = false;

  /// 鼠标在缩略图上 / 在信息卡里；两处都离开一小会儿才收起，
  /// 免得从缩略图移到卡片中途经过空隙时闪掉。
  var _onChip = false, _onCard = false;
  Timer? _leave;

  void _track({bool? chip, bool? card}) {
    _onChip = chip ?? _onChip;
    _onCard = card ?? _onCard;
    _leave?.cancel();
    if (_onChip || _onCard) {
      if (!_hover) setState(() => _hover = true);
      return;
    }
    _leave = Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_onChip && !_onCard) setState(() => _hover = false);
    });
  }

  @override
  void dispose() {
    _leave?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    final a = widget.attachment;
    final size = a.width != null && a.height != null
        ? '${a.width}×${a.height}'
        : null;
    return UiTipHost(
      tip: _hover
          ? UiTip(
              anchor: const Offset(0, -8),
              followerAnchor: Alignment.bottomLeft,
              width: 300,
              interactive: a.metadata != null,
              onHover: (inside) => _track(card: inside),
              child: _AttachmentInfo(attachment: a, size: size),
            )
          : null,
      child: MouseRegion(
        onEnter: (_) => _track(chip: true),
        onExit: (_) => _track(chip: false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              key: Key('agent-attachment-${a.id}'),
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: a.image == null
                  ? Center(
                      child: AgentIcon(
                        AgentGlyphs.alert,
                        size: 16,
                        color: c.faint,
                      ),
                    )
                  : Image(
                      image: a.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: AgentIcon(
                          AgentGlyphs.alert,
                          size: 16,
                          color: c.faint,
                        ),
                      ),
                    ),
            ),
            if (a.metadata != null)
              Positioned(
                left: 3,
                bottom: 3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const AgentIcon(
                    AgentGlyphs.info,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            if (_hover)
              Positioned(
                right: -5,
                top: -5,
                child: GestureDetector(
                  key: Key('agent-attachment-remove-${a.id}'),
                  onTap: () => s.run(() => s.actions.onRemoveAttachment(a.id)),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Tooltip(
                      message: l.ag_attachmentRemove,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: c.ink,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.card, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: AgentIcon(
                          AgentGlyphs.close,
                          size: 10,
                          color: c.bg,
                          stroke: 2.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 附件悬停卡：文件名、尺寸和图片自带的生成信息。内容多时卡内滚动（最高 360），
/// 文字可选中复制；不整段贴元数据 JSON。
class _AttachmentInfo extends StatefulWidget {
  const _AttachmentInfo({required this.attachment, required this.size});
  final AgentAttachment attachment;
  final String? size;

  @override
  State<_AttachmentInfo> createState() => _AttachmentInfoState();
}

class _AttachmentInfoState extends State<_AttachmentInfo> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = widget.attachment;
    final m = a.metadata;
    final sub = UiTipStyle.secondary(context);
    final ink = context.ui.tipInk;
    final mono = UiText.mono(
      11,
      color: ink.withValues(alpha: .82),
      height: 1.45,
    );
    final label = UiText.sans(
      11,
      weight: FontWeight.w600,
      color: ink.withValues(alpha: .62),
    );
    final params = [
      if (m?.steps != null) l.ag_imageInfoSteps(m!.steps!),
      if (m?.scale != null) 'CFG ${_trim(m!.scale!)}',
      if (m?.cfgRescale != null && m!.cfgRescale! > 0)
        l.ag_imageInfoRescale(_trim(m.cfgRescale!)),
      ?m?.sampler,
    ];
    final extra = [?m?.noiseSchedule, ?m?.smea];
    Widget block(String title, String body) => Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 1,
        children: [
          Text(title, style: label),
          Text(body, style: mono),
        ],
      ),
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Text(
          a.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiTipStyle.strong(context),
        ),
        if (a.image == null)
          Text(l.ag_attachmentBroken, style: sub)
        else if (widget.size != null || m?.model != null)
          Text([?m?.model, ?widget.size].join(' · '), style: sub),
        if (params.isNotEmpty) Text(params.join(' · '), style: sub),
        if (extra.isNotEmpty) Text(extra.join(' · '), style: sub),
        if (m?.seed != null)
          Text(l.ag_imageInfoSeed(m!.seed!.toString()), style: sub),
        if (m != null && m.characters > 0)
          Text(l.ag_imageInfoCharacters(m.characters), style: sub),
        if (m?.prompt != null) block(l.ag_field_prompt, m!.prompt!),
        if (m?.negative != null) block(l.ag_field_negative, m!.negative!),
        if (m != null)
          for (final (i, ch) in m.characterPrompts.indexed) ...[
            if (ch.prompt.isNotEmpty) block(l.gen_characterN(i + 1), ch.prompt),
            if (ch.negative != null)
              block(
                '${l.gen_characterN(i + 1)} · ${l.ag_field_characterNegative}',
                ch.negative!,
              ),
          ],
      ],
    );
    if (m == null) {
      return KeyedSubtree(
        key: Key('agent-attachment-info-${a.id}'),
        child: content,
      );
    }
    return ConstrainedBox(
      key: Key('agent-attachment-info-${a.id}'),
      constraints: const BoxConstraints(maxHeight: 360),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: RawScrollbar(
          controller: _scroll,
          thumbVisibility: true,
          thickness: 4,
          radius: const Radius.circular(2),
          thumbColor: ink.withValues(alpha: .28),
          padding: const EdgeInsets.only(right: -8),
          child: SingleChildScrollView(
            key: Key('agent-attachment-info-scroll-${a.id}'),
            controller: _scroll,
            child: SelectionArea(child: content),
          ),
        ),
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
}

class _Notices extends StatelessWidget {
  const _Notices({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('agent-notices'),
      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.accent.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AgentIcon(AgentGlyphs.info, size: 14, color: c.accent),
          ),
          Expanded(
            child: Text(
              lines.join('\n'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.ink, height: 1.5),
            ),
          ),
          AgentButton(
            label: l.ag_dismiss,
            style: AgentButtonStyle.ghost,
            height: 22,
            onPressed: s.actions.onDismissNotices,
          ),
        ],
      ),
    );
  }
}
