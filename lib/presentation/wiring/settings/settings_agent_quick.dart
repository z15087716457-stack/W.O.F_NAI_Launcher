import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/nai_agent/nai_agent_quick_messages.dart';
import '../../ui/agent/agent_glyphs.dart';
import '../../ui/kit/ui_colors.dart';
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
    final result = await showDialog<NaiAgentQuickMessage>(
      context: context,
      builder: (dialog) => _QuickEditor(
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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(l.set_agQuickIcon),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final key in agentQuickGlyphKeys)
                    InkWell(
                      key: Key('quick-icon-$key'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _icon = key),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _icon == key
                              ? c.accent.withValues(alpha: .14)
                              : c.control,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _icon == key ? c.accent : c.border,
                          ),
                        ),
                        child: AgentIcon(
                          agentQuickGlyph(key),
                          size: 16,
                          color: _icon == key ? c.accent : c.ink,
                        ),
                      ),
                    ),
                ],
              ),
              TextField(
                key: const Key('quick-title'),
                controller: _title,
                autofocus: true,
                decoration: InputDecoration(labelText: l.set_agQuickTitle),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                key: const Key('quick-hint'),
                controller: _hint,
                decoration: InputDecoration(labelText: l.set_agQuickHint),
              ),
              TextField(
                key: const Key('quick-prompt'),
                controller: _prompt,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l.set_agQuickPrompt,
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              CheckboxListTile(
                key: const Key('quick-send'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _send,
                title: Text(l.set_agQuickSend),
                onChanged: (v) => setState(() => _send = v ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.common_cancel),
        ),
        FilledButton(
          key: const Key('quick-save'),
          onPressed: valid
              ? () => Navigator.pop(
                  context,
                  widget.initial.copyWith(
                    icon: _icon,
                    title: _title.text.trim(),
                    hint: _hint.text.trim(),
                    prompt: _prompt.text.trim(),
                    send: _send,
                  ),
                )
              : null,
          child: Text(l.common_save),
        ),
      ],
    );
  }
}
