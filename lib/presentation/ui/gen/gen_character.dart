import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';
import 'gen_prompt.dart';

/// 角色模块（原型 `charModule`）：标题行放数量、定位切换、定位板、添加；下面每个角色一张卡，卡之间 1px 分隔。
class GenCharacterModule extends StatelessWidget {
  const GenCharacterModule({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final chars = scope.data.characters!;
    final l = context.l10n;
    final full = chars.list.length >= chars.max;
    final positioning = scope.data.canvas.positioning;
    return GenModule(
      key: const Key('gen-characters'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GenModuleHeader(
            children: [
              Expanded(
                child: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: l.gen_charactersTip,
                        child: Text(
                          l.gen_characters,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (chars.list.isNotEmpty) GenCount('${chars.list.length}'),
                  ],
                ),
              ),
              GenLabel(l.gen_position),
              GenTrack<bool>(
                key: const Key('gen-position-mode'),
                values: const [true, false],
                selected: chars.aiPosition,
                height: 22,
                keyOf: (v) => Key('gen-position-${v ? 'ai' : 'custom'}'),
                onChanged: scope.actions.onAiPositionChanged,
                itemBuilder: (context, v, on) => Text(
                  v ? l.gen_positionAi : l.gen_positionCustom,
                  style: UiText.sans(
                    12,
                    weight: v == chars.aiPosition
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: on ? c.ink : c.muted,
                  ),
                ),
              ),
              GenIb(
                key: const Key('gen-positioning'),
                glyph: UiGlyphs.grid,
                glyphSize: 14,
                active: positioning,
                tooltip: l.gen_positionBoard,
                onTap: chars.list.isEmpty
                    ? null
                    : () => scope.actions.onPositioningChanged(!positioning),
              ),
              Builder(
                builder: (context) => GenIb(
                  key: const Key('gen-add-character'),
                  glyph: UiGlyphs.plus,
                  glyphSize: 17,
                  strokeWidth: 2.1,
                  color: full ? c.faint : c.ink,
                  active: scope.controller.popoverTag == #addCharacter,
                  tooltip: full
                      ? l.gen_charactersFull(chars.max)
                      : l.gen_addCharacter,
                  onTap: () => scope.controller.openMenu(
                    genBelow(context, dy: 4, right: true),
                    [
                      for (final g in GenGender.values)
                        UiMenuItem(
                          key: Key('gen-add-${g.name}'),
                          label: l.gen_addAs(GenFormat.genderLabel(context, g)),
                          glyph: switch (g) {
                            GenGender.female => GenGlyphs.female,
                            GenGender.male => GenGlyphs.male,
                            GenGender.other => UiGlyphs.user,
                          },
                          enabled: !full,
                          onTap: () => scope.actions.onAddCharacter(g),
                        ),
                      UiMenuItem(
                        key: const Key('gen-clear-characters'),
                        label: l.gen_clearCharacters,
                        glyph: UiGlyphs.trash,
                        danger: true,
                        divider: true,
                        enabled: chars.list.isNotEmpty,
                        onTap: () => _confirmClear(context, scope),
                      ),
                    ],
                    tag: #addCharacter,
                    width: 200,
                  ),
                ),
              ),
            ],
          ),
          if (chars.list.isEmpty)
            Container(
              key: const Key('gen-characters-empty'),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Text(
                l.gen_charactersEmpty,
                style: UiText.sans(12, color: c.faint, height: 1.5),
              ),
            )
          else
            for (final (i, ch) in chars.list.indexed)
              GenCharacterCard(key: ValueKey(ch.id), index: i, character: ch),
        ],
      ),
    );
  }

  static void _confirmClear(BuildContext context, GenScope scope) {
    final l = context.l10n;
    scope.controller.openDialog(
      (_) => GenConfirmDialog(
        title: l.gen_clearCharactersTitle,
        body: l.gen_clearCharactersBody(scope.data.characters!.list.length),
        confirm: l.gen_clearConfirm,
        cancel: l.gen_cancel,
        onCancel: scope.controller.closeDialog,
        onConfirm: () {
          scope.controller.closeDialog();
          scope.actions.onClearCharacters();
        },
      ),
    );
  }
}

/// 一个角色（原型 `.chr` + `charBody`）：名字行（定位针、名字、上移、下移、启用、删除、更多）
/// │ 正面 / 负面页签 │ 编辑器 │ token 条。双击名字改名。停用时整张卡变淡。
class GenCharacterCard extends StatefulWidget {
  const GenCharacterCard({
    super.key,
    required this.index,
    required this.character,
  });
  final int index;
  final GenCharacter character;

  @override
  State<GenCharacterCard> createState() => _GenCharacterCardState();
}

class _GenCharacterCardState extends State<GenCharacterCard> {
  var _negative = false;
  TextEditingController? _rename;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _rename?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startRename(String current) {
    setState(
      () => _rename = TextEditingController(text: widget.character.name ?? '')
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: (widget.character.name ?? '').length,
        ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit({bool cancel = false}) {
    final e = _rename;
    if (e == null) return;
    setState(() => _rename = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => e.dispose());
    if (cancel) return;
    final v = e.text.trim();
    if (v != (widget.character.name ?? '')) {
      GenScope.of(context).actions.onRenameCharacter(widget.index, v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final l = context.l10n;
    final ch = widget.character;
    final i = widget.index;
    final chars = scope.data.characters!;
    final count = chars.list.length;
    final name = ch.name ?? l.gen_characterN(i + 1);
    final placed = !chars.aiPosition && ch.position != null;
    final target = GenEditorTarget.character(i, negative: _negative);
    return Container(
      key: Key('gen-character-$i'),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 0),
            child: Row(
              spacing: 2,
              children: [
                Expanded(
                  child: Row(
                    spacing: 6,
                    children: [
                      Tooltip(
                        message: chars.aiPosition
                            ? l.gen_positionAiTip
                            : placed
                            ? l.gen_positionAt(
                                chars.freeform
                                    ? '${(ch.position!.dx * 100).round()}%, ${(ch.position!.dy * 100).round()}%'
                                    : GenFormat.cell(ch.position!),
                              )
                            : l.gen_positionUnset,
                        child: UiPressable(
                          key: Key('gen-character-pin-$i'),
                          onTap: () => scope.actions.onPositioningChanged(true),
                          builder: (context, hover) => UiGlyph(
                            GenGlyphs.pinMap,
                            size: 14,
                            color: placed
                                ? c.accent
                                : (hover ? c.ink : c.muted),
                          ),
                        ),
                      ),
                      if (_rename != null)
                        Expanded(child: _renameField(c, l))
                      else
                        Flexible(
                          child: GestureDetector(
                            onDoubleTap: () => _startRename(name),
                            child: Tooltip(
                              message: l.gen_renameTip,
                              waitDuration: const Duration(milliseconds: 800),
                              child: Text(
                                name,
                                key: Key('gen-character-name-$i'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(
                                  13,
                                  weight: FontWeight.w600,
                                  color: ch.enabled ? c.ink : c.faint,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_rename == null && ch.gender != GenGender.other)
                        UiGlyph(
                          ch.gender == GenGender.female
                              ? GenGlyphs.female
                              : GenGlyphs.male,
                          size: 12,
                          color: c.faint,
                        ),
                    ],
                  ),
                ),
                GenIb(
                  key: Key('gen-character-up-$i'),
                  glyph: UiGlyphs.chevronUp,
                  dim: i == 0,
                  tooltip: l.gen_moveUp,
                  onTap: i == 0
                      ? null
                      : () => scope.actions.onMoveCharacter(i, -1),
                ),
                GenIb(
                  key: Key('gen-character-down-$i'),
                  glyph: UiGlyphs.chevronDown,
                  dim: i == count - 1,
                  tooltip: l.gen_moveDown,
                  onTap: i == count - 1
                      ? null
                      : () => scope.actions.onMoveCharacter(i, 1),
                ),
                GenIb(
                  key: Key('gen-character-enabled-$i'),
                  glyph: UiGlyphs.check,
                  glyphSize: 16,
                  strokeWidth: 2.4,
                  color: ch.enabled ? c.ink : c.faint,
                  tooltip: ch.enabled
                      ? l.gen_characterDisable
                      : l.gen_characterEnable,
                  onTap: () => scope.actions.onCharacterEnabled(i, !ch.enabled),
                ),
                GenIb(
                  key: Key('gen-character-delete-$i'),
                  glyph: UiGlyphs.trash,
                  tooltip: l.gen_delete,
                  onTap: () => scope.actions.onRemoveCharacter(i),
                ),
                Builder(
                  builder: (context) => GenIb(
                    key: Key('gen-character-more-$i'),
                    glyph: UiGlyphs.more,
                    glyphSize: 16,
                    strokeWidth: 3,
                    active: scope.controller.popoverTag == ('char', i),
                    tooltip: l.gen_more,
                    onTap: () => scope.controller.openMenu(
                      genBelow(context, dy: 4, right: true),
                      [
                        for (final g in GenGender.values)
                          UiMenuItem(
                            label: GenFormat.genderLabel(context, g),
                            glyph: switch (g) {
                              GenGender.female => GenGlyphs.female,
                              GenGender.male => GenGlyphs.male,
                              GenGender.other => UiGlyphs.user,
                            },
                            checked: ch.gender == g,
                            onTap: () => scope.actions.onCharacterGender(i, g),
                          ),
                        UiMenuItem(
                          label: l.gen_rename,
                          glyph: UiGlyphs.pencil,
                          divider: true,
                          onTap: () => _startRename(name),
                        ),
                        UiMenuItem(
                          label: l.gen_positionBoard,
                          glyph: UiGlyphs.grid,
                          onTap: () => scope.actions.onPositioningChanged(true),
                        ),
                        UiMenuItem(
                          label: l.gen_fullscreen,
                          glyph: UiGlyphs.expand,
                          onTap: () => scope.controller.openFullscreen(
                            GenEditorTarget.character(
                              i,
                              negative: _negative,
                              fullscreen: true,
                            ),
                          ),
                        ),
                        UiMenuItem(
                          key: Key('gen-character-library-$i'),
                          label: l.gen_saveAsBlock,
                          glyph: UiGlyphs.archive,
                          onTap: () => scope.actions.onCharacterToLibrary(i),
                        ),
                      ],
                      tag: ('char', i),
                      width: 200,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: ch.enabled ? 1 : .5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    spacing: 2,
                    children: [
                      GenTab(
                        key: Key('gen-character-tab-pos-$i'),
                        label: l.gen_charPositive,
                        selected: !_negative,
                        onTap: () => setState(() => _negative = false),
                      ),
                      GenTab(
                        key: Key('gen-character-tab-neg-$i'),
                        label: l.gen_charNegative,
                        selected: _negative,
                        onTap: () => setState(() => _negative = true),
                      ),
                    ],
                  ),
                ),
                GenEditorArea(target: target),
                GenTokenBar(
                  tokens: _negative ? ch.negativeTokens : ch.positiveTokens,
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renameField(UiColors c, AppLocalizations l) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: c.control,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: c.accent),
    ),
    alignment: Alignment.centerLeft,
    child: Focus(
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          _commit(cancel: true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        key: Key('gen-character-rename-${widget.index}'),
        controller: _rename,
        focusNode: _focus,
        maxLines: 1,
        style: UiText.sans(
          13,
          weight: FontWeight.w600,
          color: c.ink,
          height: 1.2,
        ),
        cursorColor: c.accent,
        decoration: uiBareDecoration(
          hintText: l.gen_characterN(widget.index + 1),
          hintStyle: UiText.sans(13, color: c.faint, height: 1.2),
        ),
        onSubmitted: (_) => _commit(),
      ),
    ),
  );
}
