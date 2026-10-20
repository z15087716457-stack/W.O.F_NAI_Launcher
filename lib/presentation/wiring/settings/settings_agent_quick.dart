import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/nai_agent/nai_agent_quick_messages.dart';
import '../../ui/agent/agent_glyphs.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_controls.dart';
import '../../ui/kit/ui_text.dart';
import '../../ui/settings/settings_dialog_kit.dart';
import '../../ui/settings/settings_kit.dart';
import '../../ui/settings/settings_contract.dart';
import '../nai_agent/agent_quick.dart';
import 'settings_dialogs.dart';

/// 设置页「快捷信息」一节的数据（文字按界面语言取好）。
(List<SettingsQuickMessage>, bool) settingsQuickData(
  WidgetRef ref,
  BuildContext context,
) {
  final messages = ref.watch(naiAgentQuickMessagesProvider).items;
  final l = context.l10n;
  return (
    [
      for (final m in messages)
        if (agentQuickText(l, m) case final t)
          SettingsQuickMessage(
            id: m.id,
            glyph: m.icon,
            title: t.title.trim().isEmpty ? t.prompt.trim() : t.title,
            hint: t.hint,
            prompt: t.prompt,
            send: m.send,
          ),
    ],
    const ListEquality<NaiAgentQuickMessage>().equals(
      messages,
      naiAgentQuickDefaults,
    ),
  );
}

class SettingsQuickActions {
  SettingsQuickActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  NaiAgentQuickMessages get _store => ref.read(naiAgentQuickMessagesProvider);

  Future<void> edit(String? id) async {
    final l = context.l10n;
    final current = id == null
        ? null
        : _store.items.where((m) => m.id == id).firstOrNull;
    if (id != null && current == null) return;
    final text = current == null ? null : agentQuickText(l, current);
    final result = await showSettingsDialog<NaiAgentQuickMessage>(
      context,
      (dialog) => _QuickEditor(
        title: current == null ? l.set_agQuickNew : l.set_agQuickEditTitle,
        initial:
            current?.copyWith(
              title: text!.title,
              hint: text.hint,
              prompt: text.prompt,
            ) ??
            NaiAgentQuickMessage(id: NaiAgentQuickMessages.newId()),
      ),
    );
    if (result == null) return;
    // 内置条目：内容和当前语言的默认文字完全一样就保持「跟随语言」。
    final unchanged =
        current != null &&
        current.localized &&
        result.title == text!.title &&
        result.hint == text.hint &&
        result.prompt == text.prompt;
    await _store.upsert(
      unchanged
          ? current.copyWith(icon: result.icon, send: result.send)
          : result,
    );
  }

  Future<void> remove(String id) async {
    final l = context.l10n;
    final item = _store.items.where((m) => m.id == id).firstOrNull;
    if (item == null) return;
    final title = agentQuickText(l, item).title;
    if (!await settingsConfirm(
      context,
      l.set_agQuickRemove,
      l.set_agQuickRemoveConfirm(title),
      confirm: l.set_delete,
      danger: true,
    )) {
      return;
    }
    await _store.remove(id);
  }

  Future<void> move(String id, int delta) async {
    final i = _store.items.indexWhere((m) => m.id == id);
    if (i < 0) return;
    await _store.move(id, i + delta);
  }

  Future<void> restore() async {
    final l = context.l10n;
    if (!await settingsConfirm(
      context,
      l.set_agQuickRestore,
      l.set_agQuickRestoreConfirm,
    )) {
      return;
    }
    await _store.restoreDefaults();
  }
}

class _QuickEditor extends StatefulWidget {
  const _QuickEditor({required this.title, required this.initial});
  final String title;
  final NaiAgentQuickMessage initial;

  @override
  State<_QuickEditor> createState() => _QuickEditorState();
}

class _QuickEditorState extends State<_QuickEditor> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _hint = TextEditingController(text: widget.initial.hint);
  late final _prompt = TextEditingController(text: widget.initial.prompt);
  late var _icon = widget.initial.icon;
  late var _send = widget.initial.send;

  @override
  void dispose() {
    _title.dispose();
    _hint.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final valid =
        _title.text.trim().isNotEmpty && _prompt.text.trim().isNotEmpty;
    void save() {
      if (!valid) return;
      Navigator.pop(
        context,
        widget.initial.copyWith(
          icon: _icon,
          title: _title.text.trim(),
          hint: _hint.text.trim(),
          prompt: _prompt.text.trim(),
          send: _send,
        ),
      );
    }

    return SettingsDialogFrame(
      key: const Key('quick-editor'),
      width: 560,
      title: widget.title,
      subtitle: Text(l.set_agQuickSub),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            // 预览：和欢迎页卡片同样的排版，边改边看。
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
              decoration: BoxDecoration(
                color: c.sunk,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.rowLine),
              ),
              child: Row(
                spacing: 11,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border),
                    ),
                    child: AgentIcon(
                      agentQuickGlyph(_icon),
                      size: 15,
                      color: c.ink,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          _title.text.trim().isEmpty
                              ? l.set_agQuickTitle
                              : _title.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            13,
                            weight: FontWeight.w600,
                            color: _title.text.trim().isEmpty ? c.faint : c.ink,
                          ),
                        ),
                        if (_hint.text.trim().isNotEmpty)
                          Text(
                            _hint.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(11.5, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  if (_send)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        l.set_agQuickSendBadge,
                        style: UiText.sans(
                          10.5,
                          weight: FontWeight.w600,
                          color: c.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SettingsField(
              label: l.set_agQuickIcon,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final key in agentQuickGlyphKeys)
                    UiPressable(
                      key: Key('quick-icon-$key'),
                      onTap: () => setState(() => _icon = key),
                      builder: (context, hover) {
                        final on = _icon == key;
                        return Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on
                                ? Color.alphaBlend(
                                    c.accent.withValues(alpha: .1),
                                    c.card,
                                  )
                                : hover
                                ? c.hover
                                : c.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: on ? c.accent : c.border),
                          ),
                          child: AgentIcon(
                            agentQuickGlyph(key),
                            size: 15,
                            color: on ? c.accent : c.muted,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(
                  child: SettingsField(
                    label: l.set_agQuickTitle,
                    child: SettingsTextArea(
                      key: const Key('quick-title'),
                      controller: _title,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                Expanded(
                  child: SettingsField(
                    label: l.set_agQuickHint,
                    child: SettingsTextArea(
                      key: const Key('quick-hint'),
                      controller: _hint,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
            SettingsField(
              label: l.set_agQuickPrompt,
              child: SettingsTextArea(
                key: const Key('quick-prompt'),
                controller: _prompt,
                minLines: 4,
                maxLines: 10,
                onChanged: (_) => setState(() {}),
              ),
            ),
            SettingsCheckRow(
              key: const Key('quick-send'),
              value: _send,
              label: l.set_agQuickSend,
              onChanged: (v) => setState(() => _send = v),
            ),
          ],
        ),
      ),
      actions: [
        SettingsBtn(label: l.set_cancel, onTap: () => Navigator.pop(context)),
        SettingsBtn(
          key: const Key('quick-save'),
          label: l.set_save,
          tone: SettingsBtnTone.primary,
          onTap: valid ? save : null,
        ),
      ],
    );
  }
}
