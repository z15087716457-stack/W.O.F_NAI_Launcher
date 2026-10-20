import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'settings_dialog_kit.dart';
import 'settings_format.dart';
import 'settings_kit.dart';

/// 只读长文本窗（最终提示词、内置提示词、SKILL.md）：标题 + 副标题，凹底等宽正文，
/// 底栏左侧字数 / token 估算，右侧附加按钮 + 复制。
class SettingsTextViewer extends StatelessWidget {
  const SettingsTextViewer({
    super.key,
    required this.title,
    required this.text,
    this.subtitle,
    this.notice,
    this.path,
    this.extraActions = const [],
    this.glyph = UiGlyphs.file,
  });

  final String title;
  final String text;
  final String? subtitle;

  /// 正文上方的一条淡色提示（例如“当前没有运行中的会话”）。
  final String? notice;

  /// 文件路径（等宽，可选中）。
  final String? path;
  final List<Widget> extraActions;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final chars = text.runes.length;
    return SettingsDialogFrame(
      key: const Key('settings-text-viewer'),
      width: 820,
      maxHeight: 760,
      glyph: glyph,
      title: title,
      subtitle: subtitle == null && path == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                if (subtitle != null) Text(subtitle!),
                if (path != null)
                  SelectableText(
                    path!,
                    style: UiText.mono(11, color: c.faint, height: 1.5),
                  ),
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (notice != null) SettingsHint.text(context, notice!),
          Flexible(child: SettingsCodeView(text: text)),
        ],
      ),
      footerLeading: Text(
        l.set_agPromptStats(
          SettingsFormat.count(chars),
          SettingsFormat.count((chars / 4).ceil()),
        ),
        style: UiText.mono(11.5, color: c.faint),
      ),
      actions: [
        ...extraActions,
        SettingsCopyButton(text: text),
      ],
    );
  }
}

/// 一行分段选项：标题 + 若干等宽按钮，选中卡片底。
class SettingsChoice<T> extends StatelessWidget {
  const SettingsChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.helpOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final String? Function(T)? helpOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final v in values)
          Expanded(
            child: UiPressable(
              onTap: () => onChanged(v),
              builder: (context, hover) {
                final on = v == selected;
                final help = helpOf?.call(v);
                return Container(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                  decoration: BoxDecoration(
                    color: on
                        ? Color.alphaBlend(
                            c.accent.withValues(alpha: .06),
                            c.card,
                          )
                        : hover
                        ? c.hover
                        : c.card,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: on ? c.accent : c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Row(
                        spacing: 7,
                        children: [
                          UiRadioDot(value: on),
                          Expanded(
                            child: Text(
                              labelOf(v),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(
                                12.5,
                                weight: on ? FontWeight.w600 : FontWeight.w500,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (help != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 21),
                          child: Text(
                            help,
                            style: UiText.sans(
                              11.5,
                              color: c.muted,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// 14px 单选圈（选项卡片里用）。
class UiRadioDot extends StatelessWidget {
  const UiRadioDot({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 14,
      height: 14,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: value ? c.accent : c.strong, width: 1.5),
      ),
      child: value
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// “添加 Skill 文件夹”：来源路径、放到哪里、调用方式、提醒。
class SettingsSkillImportDialog extends StatefulWidget {
  const SettingsSkillImportDialog({
    super.key,
    required this.folder,
    this.workspace,
  });

  final String folder;

  /// 当前工作区名；null = 只能放全局。
  final String? workspace;

  @override
  State<SettingsSkillImportDialog> createState() =>
      _SettingsSkillImportDialogState();
}

class _SettingsSkillImportDialogState extends State<SettingsSkillImportDialog> {
  var _toWorkspace = false, _manual = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SettingsDialogFrame(
      key: const Key('skill-import-dialog'),
      width: 520,
      glyph: UiGlyphs.folderPlus,
      title: l.set_agSkillAddTitle,
      subtitle: Text(l.set_agSkillCopyNote),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            SettingsPathBox(path: widget.folder),
            if (widget.workspace != null)
              SettingsField(
                label: l.set_agSkillPlace,
                child: SettingsChoice<bool>(
                  values: const [false, true],
                  selected: _toWorkspace,
                  labelOf: (v) => v
                      ? l.set_agSkillPlaceWorkspace(widget.workspace!)
                      : l.set_agSkillGlobal,
                  onChanged: (v) => setState(() => _toWorkspace = v),
                ),
              ),
            SettingsField(
              label: l.set_agSkillMode,
              child: SettingsChoice<bool>(
                values: const [false, true],
                selected: _manual,
                labelOf: (v) => v ? l.set_agSkillManual : l.set_agSkillAuto,
                helpOf: (v) =>
                    v ? l.set_agSkillManualTip : l.set_agSkillAutoTip,
                onChanged: (v) => setState(() => _manual = v),
              ),
            ),
            SettingsHint.text(
              context,
              l.set_agSkillTrust,
              glyph: UiGlyphs.alert,
            ),
          ],
        ),
      ),
      actions: [
        SettingsBtn(label: l.set_cancel, onTap: () => Navigator.pop(context)),
        SettingsBtn(
          key: const Key('skill-import-ok'),
          label: l.set_agSkillAddConfirm,
          tone: SettingsBtnTone.primary,
          onTap: () => Navigator.pop(context, (_toWorkspace, _manual)),
        ),
      ],
    );
  }
}

/// 回收区里的一项（界面用；文字已取好）。
@immutable
class SettingsTrashRow {
  const SettingsTrashRow({
    required this.id,
    required this.kind,
    required this.title,
    required this.at,
    required this.bytes,
    this.detail,
    this.blocked,
  });
  final String id;
  final SettingsTrashKind kind;
  final String title;
  final DateTime at;
  final int bytes;

  /// 所属工作区 / 来源等次要信息。
  final String? detail;

  /// 不能恢复的原因（例如所属工作区也在回收区）；null = 可以恢复。
  final String? blocked;
}

enum SettingsTrashKind { chat, workspace, skill }

/// 回收区管理窗：分类筛选、每行恢复 / 彻底删除、底栏清空。
/// 操作都交给回调；回调返回后由调用方刷新 [rows]（[load] 重新读取）。
class SettingsTrashDialog extends StatefulWidget {
  const SettingsTrashDialog({
    super.key,
    required this.load,
    required this.onRestore,
    required this.onPurge,
    required this.onEmpty,
    this.now,
  });

  final Future<List<SettingsTrashRow>> Function() load;

  /// 返回 null = 成功；否则是失败原因（就地显示）。
  final Future<String?> Function(SettingsTrashRow row) onRestore;
  final Future<bool> Function(SettingsTrashRow row) onPurge;
  final Future<bool> Function(int count) onEmpty;
  final DateTime? now;

  @override
  State<SettingsTrashDialog> createState() => _SettingsTrashDialogState();
}

class _SettingsTrashDialogState extends State<SettingsTrashDialog> {
  List<SettingsTrashRow>? _rows;
  SettingsTrashKind? _filter;
  final _busy = <String>{};
  final _errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final rows = await widget.load();
    if (mounted) setState(() => _rows = rows);
  }

  Future<void> _act(SettingsTrashRow row, Future<String?> Function() f) async {
    setState(() {
      _busy.add(row.id);
      _errors.remove(row.id);
    });
    final error = await f();
    if (!mounted) return;
    setState(() {
      _busy.remove(row.id);
      if (error != null) _errors[row.id] = error;
    });
    if (error == null) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final rows = _rows;
    final shown = rows == null
        ? const <SettingsTrashRow>[]
        : [
            for (final r in rows)
              if (_filter == null || r.kind == _filter) r,
          ];
    int count(SettingsTrashKind k) =>
        rows?.where((r) => r.kind == k).length ?? 0;
    final total = rows?.fold<int>(0, (s, r) => s + r.bytes) ?? 0;
    return SettingsDialogFrame(
      key: const Key('agent-trash-dialog'),
      width: 640,
      maxHeight: 640,
      glyph: UiGlyphs.archive,
      title: l.set_agTrash,
      subtitle: Text(l.set_agTrashSub),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              SettingsChip(
                key: const Key('trash-filter-all'),
                label: l.set_agTrashAll,
                count: rows?.length,
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final (k, label) in [
                (SettingsTrashKind.chat, l.set_agTrashChats),
                (SettingsTrashKind.workspace, l.set_agTrashWorkspaces),
                (SettingsTrashKind.skill, l.set_agTrashSkills),
              ])
                if (count(k) > 0)
                  SettingsChip(
                    key: Key('trash-filter-${k.name}'),
                    label: label,
                    count: count(k),
                    selected: _filter == k,
                    onTap: () => setState(() => _filter = k),
                  ),
            ],
          ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(minHeight: 160),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: rows == null
                  ? const SizedBox(height: 160)
                  : shown.isEmpty
                  ? SizedBox(
                      height: 160,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            UiGlyph(UiGlyphs.archive, size: 22, color: c.faint),
                            Text(
                              l.set_agTrashEmpty,
                              style: UiText.sans(12.5, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 50,
                        color: c.rowLine,
                      ),
                      itemBuilder: (context, i) => _row(shown[i]),
                    ),
            ),
          ),
        ],
      ),
      footerLeading: rows == null || rows.isEmpty
          ? null
          : Text(
              l.set_agTrashSummary(rows.length, SettingsFormat.bytes(total)),
            ),
      actions: [
        if (rows != null && rows.isNotEmpty)
          SettingsBtn(
            key: const Key('trash-empty'),
            label: l.set_agTrashPurgeAll,
            tone: SettingsBtnTone.danger,
            glyph: UiGlyphs.trash,
            onTap: () async {
              if (await widget.onEmpty(rows.length)) await _reload();
            },
          ),
        SettingsBtn(label: l.common_close, onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _row(SettingsTrashRow r) {
    final c = context.ui;
    final l = context.l10n;
    final busy = _busy.contains(r.id);
    final error = _errors[r.id] ?? r.blocked;
    final glyph = switch (r.kind) {
      SettingsTrashKind.chat => UiGlyphs.list,
      SettingsTrashKind.workspace => UiGlyphs.folder,
      SettingsTrashKind.skill => SettingsGlyphs.spark,
    };
    final kind = switch (r.kind) {
      SettingsTrashKind.chat => l.set_agTrashChats,
      SettingsTrashKind.workspace => l.set_agTrashWorkspaces,
      SettingsTrashKind.skill => l.set_agTrashSkills,
    };
    final meta = [
      kind,
      ?r.detail,
      SettingsFormat.ago(context, r.at, widget.now ?? DateTime.now()),
      SettingsFormat.bytes(r.bytes),
    ].join(' · ');
    return Padding(
      key: Key('trash-row-${r.id}'),
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.sunk,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.rowLine),
            ),
            child: UiGlyph(glyph, size: 14, color: c.muted),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  r.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
                ),
                Text(
                  error ?? meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    11.5,
                    color: error != null ? c.error : c.faint,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SettingsBtn(
            key: Key('trash-restore-${r.id}'),
            label: l.set_agTrashRestore,
            small: true,
            glyph: SettingsGlyphs.undo,
            onTap: busy || r.blocked != null
                ? null
                : () => _act(r, () => widget.onRestore(r)),
          ),
          SettingsIconBtn(
            key: Key('trash-purge-${r.id}'),
            glyph: UiGlyphs.trash,
            tooltip: l.set_agTrashPurge,
            onTap: busy
                ? null
                : () =>
                      _act(r, () async {
                        final ok = await widget.onPurge(r);
                        return ok ? null : '';
                      }).then((_) {
                        if (mounted && _errors[r.id] == '') {
                          setState(() => _errors.remove(r.id));
                        }
                      }),
          ),
        ],
      ),
    );
  }
}
