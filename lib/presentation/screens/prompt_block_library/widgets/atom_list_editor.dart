import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/common/inset_shadow_container.dart';

/// 块内原子编辑器（FEAT-79）。
///
/// 段列表 `Atom|Raw` 顺序即原子顺序：原子渲染为整行堆叠的描边框
/// （无填充、描边跟主题色）；未提交文本渲染为内嵌文本行。
/// - 回车 = 聚焦的整段文本变成一个原子（不做光标处切分；拍板①）；
/// - 点击原子 = 原位还原成可编辑文本，再敲回车还原回块；
/// - 粘贴含 `\n` 切成多个原子 + 余段留作新文本行（逗号不切——
///   想批量成块就用换行列表）；
/// - 底部恒空一行输入行；
/// - 保存时调用方读 [AtomListEditorController.atoms]：剩余文本行
///   按顺序转成原子（空白行丢弃）。
///
/// v1 不做拖拽重排（拍板③）。
class AtomListEditor extends StatefulWidget {
  const AtomListEditor({
    super.key,
    required this.controller,
    this.height = 260,
  });

  final AtomListEditorController controller;

  /// 编辑区固定高度；内部行超出滚动。
  final double height;

  @override
  State<AtomListEditor> createState() => _AtomListEditorState();
}

class _AtomListEditorState extends State<AtomListEditor> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: widget.height,
      child: InsetShadowContainer(
        borderRadius: 8,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: widget.controller.segmentCount,
              itemBuilder: (context, index) {
                final seg = widget.controller.segmentAt(index);
                final isLast = index == widget.controller.segmentCount - 1;
                return Padding(
                  key: ObjectKey(seg),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: seg is _AtomSeg
                      ? _buildAtomRow(theme, seg, index)
                      : _buildRawRow(theme, seg as _RawSeg, index, isLast),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 原子行：整行描边框（无填充），点击原位还原成文本行。
  Widget _buildAtomRow(ThemeData theme, _AtomSeg seg, int index) {
    return Tooltip(
      message: context.l10n.promptBlockLibrary_atomRestoreHint,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        key: Key('atom-editor-atom-$index'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.controller.unAtom(index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(seg.text, style: theme.textTheme.bodyMedium),
        ),
      ),
    );
  }

  /// 未提交文本行：无边框内嵌字段；回车成块（经焦点节点 onKeyEvent
  /// 抢在 EditableText 之前拦截），粘贴 \n 由 onChanged 切成原子。
  Widget _buildRawRow(
    ThemeData theme,
    _RawSeg seg,
    int index,
    bool isLast,
  ) {
    return TextField(
      key: Key('atom-editor-raw-$index'),
      controller: seg.controller,
      focusNode: seg.focusNode,
      maxLines: null,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: isLast ? context.l10n.promptBlockLibrary_atomInputHint : null,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
      ),
      onChanged: (value) {
        if (value.contains('\n')) widget.controller.splitRawAtNewlines(index);
      },
    );
  }
}

/// 编辑器控制器：持有段列表与各文本行的 controller/focus。
/// [initialAtoms] 即初始段（旧块 = atomsOrSplit 预切结果），
/// 尾部自动补一个空文本行，保证「底部恒空一行」不变量。
class AtomListEditorController extends ChangeNotifier {
  AtomListEditorController(List<String> initialAtoms)
    : _segments = [
        for (final atom in initialAtoms)
          if (atom.trim().isNotEmpty) _AtomSeg(atom.trim()),
        _RawSeg.fresh(),
      ] {
    _bindLastFocus();
  }

  final List<Object> _segments;

  int get segmentCount => _segments.length;

  Object segmentAt(int index) => _segments[index];

  /// 测试用：当前各段的文本快照（原子/文本行混排）。
  List<String> get segmentTexts => [
        for (final seg in _segments)
          seg is _AtomSeg ? seg.text : (seg as _RawSeg).controller.text,
      ];

  /// 保存口径：所有段按序转原子，空白行丢弃（永不产出空原子）。
  List<String> get atoms => [
        for (final seg in _segments)
          if ((seg is _AtomSeg
                  ? seg.text
                  : (seg as _RawSeg).controller.text)
              .trim()
              .isNotEmpty)
            (seg is _AtomSeg
                    ? seg.text
                    : (seg as _RawSeg).controller.text)
                .trim(),
      ];

  /// 文本行回车：整段转原子（拍板①）。尾行转原子后追新空行并聚焦；
  /// 中间行转原子后焦点移回尾部空行。空段：尾行忽略、中间行删除。
  void commitRaw(int index) {
    final seg = _segments[index];
    if (seg is! _RawSeg) return;
    final text = seg.controller.text.trim();
    if (text.isEmpty) {
      if (index != _segments.length - 1) {
        _disposeSeg(seg);
        _segments.removeAt(index);
        notifyListeners();
      }
      return;
    }
    final isLast = index == _segments.length - 1;
    _disposeSeg(seg);
    _segments[index] = _AtomSeg(text);
    if (isLast) {
      final tail = _RawSeg.fresh();
      _segments.add(tail);
      _bindNewlineFocus(tail);
      _focusTailAfterFrame(tail);
    } else {
      _focusTailAfterFrame(null);
    }
    notifyListeners();
  }

  /// 点击原子：原位还原成文本行并聚焦到行尾。
  void unAtom(int index) {
    final seg = _segments[index];
    if (seg is! _AtomSeg) return;
    final raw = _RawSeg.fresh(seg.text);
    _bindNewlineFocus(raw);
    _segments[index] = raw;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      raw.focusNode.requestFocus();
      raw.controller.selection = TextSelection.collapsed(
        offset: raw.controller.text.length,
      );
    });
  }

  /// 文本行内容含换行（粘贴多行）：按 \n 切分——非末行各成一个原子，
  /// 末行留在原位继续当文本行（可为空，保存时丢弃）。焦点挪到最后
  /// 一个文本段（本行或尾部空行）。
  void splitRawAtNewlines(int index) {
    final seg = _segments[index];
    if (seg is! _RawSeg) return;
    final text = seg.controller.text;
    if (!text.contains('\n')) return;
    final parts = text.split('\n');
    final tail = parts.last;
    final committed = [
      for (final part in parts.sublist(0, parts.length - 1))
        if (part.trim().isNotEmpty) _AtomSeg(part.trim()),
    ];
    _disposeSeg(seg);
    _segments.replaceRange(index, index + 1, [
      ...committed,
      _RawSeg.fresh(tail),
    ]);
    final newRaw = _segments[index + committed.length] as _RawSeg;
    _bindNewlineFocus(newRaw);
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newRaw.focusNode.requestFocus();
      newRaw.controller.selection = TextSelection.collapsed(
        offset: newRaw.controller.text.length,
      );
    });
  }

  void _bindLastFocus() {
    final last = _segments.last;
    if (last is _RawSeg) _bindNewlineFocus(last);
  }

  /// 文本行的回车拦截挂在自己的 FocusNode.onKeyEvent 上——先于
  /// EditableText 内部的换行处理，把回车翻译成「整段成块」。
  void _bindNewlineFocus(_RawSeg seg) {
    seg.focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
        final index = _segments.indexOf(seg);
        if (index >= 0) commitRaw(index);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  void _focusTailAfterFrame(_RawSeg? preferred) {
    final tail = preferred ?? _segments.last;
    if (tail is! _RawSeg) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tail.focusNode.requestFocus();
      tail.controller.selection = TextSelection.collapsed(
        offset: tail.controller.text.length,
      );
    });
  }

  void _disposeSeg(_RawSeg seg) {
    seg.focusNode.dispose();
    seg.controller.dispose();
  }

  @override
  void dispose() {
    for (final seg in _segments) {
      if (seg is _RawSeg) _disposeSeg(seg);
    }
    super.dispose();
  }
}

sealed class _Seg {
  const _Seg();
}

class _AtomSeg extends _Seg {
  const _AtomSeg(this.text);
  final String text;
}

class _RawSeg extends _Seg {
  _RawSeg.fresh([String text = ''])
    : controller = TextEditingController(text: text),
      focusNode = FocusNode();

  final TextEditingController controller;
  final FocusNode focusNode;
}
