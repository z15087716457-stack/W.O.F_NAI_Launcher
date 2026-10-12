import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../gen/gen_parts.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'tools_contract.dart';
import 'tools_director_side.dart';
import 'tools_editor.dart' show toolsWorkColor;
import 'tools_format.dart';
import 'tools_parts.dart';

/// 导演工具页面级的界面状态：对比方式、滑动位置、适应 / 原始大小、弹层。
abstract class ToolsDirectorController {
  ToolsCompare get compare;
  void setCompare(ToolsCompare v);
  double get wipe;
  void setWipe(double v);
  bool get actual;
  void setActual(bool v);
  void openPopover(
    UiPopoverAnchor anchor,
    WidgetBuilder builder, {
    Object? tag,
  });
  void closePopover();
  Object? get popoverTag;
}

class ToolsDirectorScope extends InheritedWidget {
  const ToolsDirectorScope({
    super.key,
    required this.data,
    required this.actions,
    required this.slots,
    required this.controller,
    required this.compact,
    required super.child,
  });

  final ToolsDirectorData data;
  final ToolsDirectorActions actions;
  final ToolsDirectorSlots slots;
  final ToolsDirectorController controller;

  /// 窄窗：左栏工具清单收成只有图标的一列。
  final bool compact;

  static ToolsDirectorScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToolsDirectorScope>()!;

  @override
  bool updateShouldNotify(ToolsDirectorScope old) => true;
}

/// 导演工具（整窗，不带主导航）：顶栏 │ 左栏工具清单（4 组，每个一句说明 + 价格）│
/// 舞台（并排 / 滑动对比 / 只看结果，结果操作，输入队列）│ 右栏（当前工具、选项、运行、结果列表）。
class ToolsDirectorPage extends StatefulWidget {
  const ToolsDirectorPage({
    super.key,
    required this.data,
    required this.actions,
    this.slots = const ToolsDirectorSlots(),
  });

  final ToolsDirectorData data;
  final ToolsDirectorActions actions;
  final ToolsDirectorSlots slots;

  static const topHeight = 61.0;
  static const toolsWidth = 256.0;
  static const compactToolsWidth = 64.0;
  static const sideWidth = 320.0;
  static const compactWidth = 1240.0;

  @override
  State<ToolsDirectorPage> createState() => _ToolsDirectorPageState();
}

class _ToolsDirectorPageState extends State<ToolsDirectorPage>
    implements ToolsDirectorController {
  var _compare = ToolsCompare.side;
  var _wipe = .52;
  var _actual = false;
  UiPopoverAnchor? _anchor;
  WidgetBuilder? _popover;
  Object? _tag;

  @override
  ToolsCompare get compare => _compare;
  @override
  void setCompare(ToolsCompare v) => setState(() => _compare = v);
  @override
  double get wipe => _wipe;
  @override
  void setWipe(double v) => setState(() => _wipe = v.clamp(0.0, 1.0));
  @override
  bool get actual => _actual;
  @override
  void setActual(bool v) => setState(() => _actual = v);

  @override
  void openPopover(
    UiPopoverAnchor anchor,
    WidgetBuilder builder, {
    Object? tag,
  }) => setState(() {
    _anchor = anchor;
    _popover = builder;
    _tag = tag;
  });

  @override
  void closePopover() {
    if (_anchor == null) return;
    setState(() {
      _anchor = null;
      _popover = null;
      _tag = null;
    });
  }

  @override
  Object? get popoverTag => _tag;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final a = widget.actions;
    return LayoutBuilder(
      builder: (context, box) {
        Widget scoped(Widget child) => ToolsDirectorScope(
          data: widget.data,
          actions: widget.actions,
          slots: widget.slots,
          controller: this,
          compact: box.maxWidth < ToolsDirectorPage.compactWidth,
          child: child,
        );
        return scoped(
          UiPopover(
            anchor: _anchor,
            onDismiss: closePopover,
            builder: (ctx) => _popover == null
                ? const SizedBox.shrink()
                : scoped(Builder(builder: _popover!)),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): a.onBack,
                const SingleActivator(
                  LogicalKeyboardKey.enter,
                  control: true,
                ): () {
                  if (widget.data.canRun) a.onRun();
                },
                const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                    a.onPaste,
              },
              child: Focus(
                autofocus: true,
                child: ColoredBox(
                  key: const Key('tools-director'),
                  color: c.bg,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ToolList(),
                            Expanded(child: _Stage()),
                            ToolsDirectorSide(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 顶栏：← 生图 Esc │ 导演工具 …… Anlas 余额，右边让出窗口按钮。
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final chrome = WindowChromeScope.activeOf(context);
    return WindowHeader(
      key: const Key('tools-director-top'),
      minimumInlineWidth: 0,
      inlineDragWidth: 12,
      dragBackground: true,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Container(
        height: ToolsDirectorPage.topHeight - 1,
        padding: EdgeInsets.only(left: 10, right: chrome ? 0 : 12),
        child: Row(
          spacing: 10,
          children: [
            ToolsButton(
              key: const Key('tools-director-back'),
              tone: ToolsButtonTone.ghost,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onTap: scope.actions.onBack,
              children: [
                UiGlyph(ToolsGlyphs.back, size: 16, color: c.muted),
                Text(l.tools_backGen),
                const UiKeycap('Esc'),
              ],
            ),
            const ToolsVDiv(),
            Text(
              l.tools_director,
              key: const Key('tools-director-title'),
              style: UiText.sans(15, weight: FontWeight.w600, color: c.ink),
            ),
            const Spacer(),
            if (d.anlas != null)
              ToolsChip(
                key: const Key('tools-director-anlas'),
                height: 30,
                mono: true,
                children: [
                  GenNaiIcon('anlas', size: 13, color: c.ink),
                  Text(ToolsFormat.number(d.anlas!)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 左栏工具清单（256 宽）：清理 / 线条 / 上色与表情 / 像素四组；每个工具图标块 + 名字 + 价格 + 一句说明。
/// 底部写 Opus 免费规则。窄窗收成 64 宽的图标列（悬停看名字和价格）。
class _ToolList extends StatelessWidget {
  const _ToolList();

  static const groups = [
    [ToolsDirectorTool.removeBackground, ToolsDirectorTool.declutter],
    [ToolsDirectorTool.lineArt, ToolsDirectorTool.sketch],
    [ToolsDirectorTool.colorize, ToolsDirectorTool.emotion],
    [ToolsDirectorTool.pixelSnap],
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final names = [
      l.tools_dtGroupClean,
      l.tools_dtGroupLine,
      l.tools_dtGroupColor,
      l.tools_dtGroupPixel,
    ];
    final compact = scope.compact;
    return Container(
      key: const Key('tools-director-tools'),
      width: compact
          ? ToolsDirectorPage.compactToolsWidth
          : ToolsDirectorPage.toolsWidth,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: compact ? 8 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, g) in groups.indexed) ...[
              if (compact)
                if (i > 0)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    color: c.line,
                  )
                else
                  const SizedBox.shrink()
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: Text(
                    names[i],
                    style: UiText.sans(
                      11,
                      weight: FontWeight.w500,
                      color: c.faint,
                    ),
                  ),
                ),
              for (final t in g) _ToolItem(tool: t, compact: compact),
            ],
            if (!compact && d.opusFree)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                child: Text(
                  l.tools_dtOpusNote,
                  style: UiText.sans(11, color: c.faint, height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({required this.tool, required this.compact});
  final ToolsDirectorTool tool;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final on = d.tool == tool;
    final local = tool == ToolsDirectorTool.pixelSnap;
    final price = ToolsPrice(cost: d.costs[tool], local: local);
    final icon = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? c.accent : c.control,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ToolsIcon(
        ToolsFormat.toolIcon(tool),
        size: 17,
        color: on ? Colors.white : c.ink,
      ),
    );
    final item = UiPressable(
      key: Key('tools-dt-${tool.name}'),
      onTap: on || d.running ? null : () => scope.actions.onTool(tool),
      builder: (context, hover) => Container(
        padding: compact
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: on
              ? c.accent.withValues(alpha: .09)
              : (hover ? c.control.withValues(alpha: .6) : null),
          borderRadius: BorderRadius.circular(10),
        ),
        // 选中描边画在里面（原型 inset 阴影），不占位置。
        foregroundDecoration: on
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.accent.withValues(alpha: .45)),
              )
            : null,
        child: compact
            ? Center(child: icon)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  icon,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            Expanded(
                              child: Text(
                                ToolsFormat.toolName(l, tool),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(
                                  13,
                                  weight: FontWeight.w600,
                                  color: c.ink,
                                ),
                              ),
                            ),
                            price,
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          ToolsFormat.toolDesc(l, tool),
                          style: UiText.sans(11.5, color: c.muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
    if (!compact) return item;
    return Tooltip(
      richMessage: TextSpan(
        text: ToolsFormat.toolName(l, tool),
        style: const TextStyle(fontWeight: FontWeight.w600),
        children: [
          TextSpan(
            text: '\n${ToolsFormat.toolDesc(l, tool)}',
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
      child: item,
    );
  }
}

/// 舞台（面板底）：上条（输入 n / N │ 对比方式 │ 适应）│ 对比区（圆角 12、画布底）│ 结果操作 │ 输入队列。
class _Stage extends StatelessWidget {
  const _Stage();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ColoredBox(
      key: const Key('tools-director-stage'),
      color: c.panel,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StageBar(),
          Expanded(child: _CompareArea()),
          _ResultActions(),
          _Queue(),
        ],
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  const _StageBar();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final ctrl = scope.controller;
    final l = context.l10n;
    final index = d.inputs.indexWhere((i) => i.id == d.input);
    return SizedBox(
      key: const Key('tools-director-stagebar'),
      height: 46,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: '${l.tools_input} ',
                    children: [
                      TextSpan(
                        text: d.inputs.isEmpty
                            ? '—'
                            : '${index + 1} / ${d.inputs.length}',
                        style: UiText.mono(
                          12,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                  style: UiText.sans(12, color: c.muted),
                ),
              ),
            ),
            ToolsSeg<ToolsCompare>(
              key: const Key('tools-compare'),
              values: ToolsCompare.values,
              selected: ctrl.compare,
              keyOf: (v) => Key('tools-compare-${v.name}'),
              onChanged: ctrl.setCompare,
              label: (context, v, on) => Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  UiGlyph(
                    switch (v) {
                      ToolsCompare.side => ToolsGlyphs.side,
                      ToolsCompare.wipe => ToolsGlyphs.wipe,
                      ToolsCompare.result => ToolsGlyphs.one,
                    },
                    size: 14,
                    color: DefaultTextStyle.of(context).style.color,
                  ),
                  Text(switch (v) {
                    ToolsCompare.side => l.tools_compareSide,
                    ToolsCompare.wipe => l.tools_compareWipe,
                    ToolsCompare.result => l.tools_compareResult,
                  }),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (ctx) => ToolsChip(
                    key: const Key('tools-director-fit'),
                    mono: true,
                    onTap: () {
                      final box = ctx.findRenderObject()! as RenderBox;
                      ctrl.openPopover(
                        UiPopoverAnchor(
                          box.localToGlobal(
                            Offset(box.size.width, box.size.height + 6),
                          ),
                          alignRight: true,
                        ),
                        (_) => UiMenu(
                          width: 150,
                          onClose: ctrl.closePopover,
                          items: [
                            UiMenuItem(
                              label: l.tools_fit,
                              checked: !ctrl.actual,
                              onTap: () => ctrl.setActual(false),
                            ),
                            UiMenuItem(
                              key: const Key('tools-director-actual'),
                              label: l.tools_actualSize,
                              checked: ctrl.actual,
                              onTap: () => ctrl.setActual(true),
                            ),
                          ],
                        ),
                        tag: #fit,
                      );
                    },
                    children: [
                      Text(ctrl.actual ? '100%' : l.tools_fit),
                      UiGlyph(UiGlyphs.chevronDown, size: 12, color: c.ink),
                    ],
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

/// 对比区：并排两格 / 滑动对比一格 / 只看结果一格；运行前、运行中、失败时结果那格换成说明。
class _CompareArea extends StatelessWidget {
  const _CompareArea();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final ctrl = scope.controller;
    final l = context.l10n;
    final input = d.currentInput;
    final run = d.currentRun;
    final result = run == null || run.images.isEmpty
        ? null
        : run.images[d.variant.clamp(0, run.images.length - 1)];
    final toolName = ToolsFormat.toolName(l, run?.tool ?? d.tool);
    final resultLabel =
        run?.variants.length == run?.images.length &&
            (run?.images.length ?? 0) > 1
        ? '$toolName · ${run!.variants[d.variant.clamp(0, run.variants.length - 1)]}'
        : toolName;

    // 按数据里的像素尺寸排版（不等解码、不跳），比格子小的不放大；“100%”时按原尺寸、超出裁掉。
    Widget image(ImageProvider p, int w, int h) => LayoutBuilder(
      builder: (context, box) {
        final k = ctrl.actual
            ? 1.0
            : [
                1.0,
                box.maxWidth / w,
                box.maxHeight / h,
              ].reduce((a, b) => a < b ? a : b);
        return OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Container(
            width: w * k,
            height: h * k,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image(image: p, fit: BoxFit.fill, gaplessPlayback: true),
          ),
        );
      },
    );

    Widget pane({
      required Widget child,
      String? tag,
      EdgeInsets padding = const EdgeInsets.all(20),
      Key? key,
    }) => Stack(
      key: key,
      fit: StackFit.expand,
      children: [
        Padding(
          padding: padding,
          child: Center(child: child),
        ),
        if (tag != null)
          Positioned(left: 10, top: 10, child: ToolsPaneTag(tag)),
      ],
    );

    final Widget resultSide = d.error != null
        ? const _ErrorNote()
        : d.running
        ? const _RunningNote()
        : result == null
        ? const _EmptyNote()
        : image(result, run!.width, run.height);
    final size = run != null
        ? ' · ${ToolsFormat.size(run.width, run.height)}'
        : '';

    final Widget body;
    if (input == null) {
      body = const _NoInput();
    } else if (ctrl.compare == ToolsCompare.wipe && result != null) {
      body = _Wipe(
        before: input.thumb,
        after: result,
        ratio: input.width / input.height,
        beforeLabel: l.tools_original,
        afterLabel: resultLabel,
      );
    } else if (ctrl.compare == ToolsCompare.result) {
      body = pane(
        key: const Key('tools-pane-result'),
        tag: result == null ? null : '$resultLabel$size',
        child: resultSide,
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: pane(
              key: const Key('tools-pane-original'),
              padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
              tag:
                  '${l.tools_original} · ${ToolsFormat.size(input.width, input.height)}',
              child: image(input.thumb, input.width, input.height),
            ),
          ),
          Expanded(
            child: pane(
              key: const Key('tools-pane-result'),
              padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
              tag: result == null || d.running || d.error != null
                  ? null
                  : '$resultLabel$size',
              child: resultSide,
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        key: const Key('tools-director-area'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: toolsWorkColor(c),
          borderRadius: BorderRadius.circular(12),
        ),
        child: body,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.extra,
  });
  final Widget icon;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(14),
          ),
          child: icon,
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: UiText.sans(13, weight: FontWeight.w600, color: c.ink),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: UiText.sans(12, color: c.muted),
          ),
        ),
        ?extra,
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final d = ToolsDirectorScope.of(context).data;
    final l = context.l10n;
    return _Note(
      key: const Key('tools-result-empty'),
      icon: ToolsIcon(ToolsFormat.toolIcon(d.tool), size: 26, color: c.muted),
      title: d.tool == ToolsDirectorTool.emotion
          ? l.tools_emptyEmotion
          : l.tools_emptyRun,
      body: l.tools_emptyBody,
      extra: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: UiKeycaps(['Ctrl', '↵']),
      ),
    );
  }
}

class _RunningNote extends StatelessWidget {
  const _RunningNote();

  @override
  Widget build(BuildContext context) {
    final d = ToolsDirectorScope.of(context).data;
    final l = context.l10n;
    return _Note(
      key: const Key('tools-result-running'),
      icon: const UiSpinner(size: 24),
      title: l.tools_running(ToolsFormat.toolName(l, d.tool)),
      body: l.tools_runningBody,
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    return _Note(
      key: const Key('tools-result-error'),
      icon: UiGlyph(UiGlyphs.alert, size: 24, color: c.error),
      title: l.tools_runFailed,
      body: d.error!,
      extra: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          ToolsButton(
            key: const Key('tools-result-dismiss'),
            small: true,
            onTap: scope.actions.onDismissError,
            children: [Text(l.tools_close)],
          ),
          ToolsButton(
            key: const Key('tools-result-retry'),
            small: true,
            tone: ToolsButtonTone.primary,
            onTap: d.canRun ? scope.actions.onRun : null,
            children: [Text(l.tools_retry)],
          ),
        ],
      ),
    );
  }
}

/// 输入队列是空的：舞台中间一个投放说明。
class _NoInput extends StatelessWidget {
  const _NoInput();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final l = context.l10n;
    return Center(
      child: _Note(
        key: const Key('tools-no-input'),
        icon: UiGlyph(UiGlyphs.image, size: 26, color: c.muted),
        title: l.tools_noInput,
        body: l.tools_noInputBody,
        extra: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            ToolsButton(
              small: true,
              onTap: scope.actions.onImportFiles,
              children: [Text(l.tools_importFiles)],
            ),
            ToolsButton(
              small: true,
              onTap: scope.actions.onPickHistory,
              children: [Text(l.tools_fromHistory)],
            ),
          ],
        ),
      ),
    );
  }
}

/// 滑动对比：一张按输入比例的图，左边原图、右边结果，中间白线 + 圆手柄（拖动）。
class _Wipe extends StatelessWidget {
  const _Wipe({
    required this.before,
    required this.after,
    required this.ratio,
    required this.beforeLabel,
    required this.afterLabel,
  });
  final ImageProvider before;
  final ImageProvider after;
  final double ratio;
  final String beforeLabel;
  final String afterLabel;

  @override
  Widget build(BuildContext context) {
    final ctrl = ToolsDirectorScope.of(context).controller;
    return Padding(
      key: const Key('tools-pane-wipe'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio,
          child: LayoutBuilder(
            builder: (context, box) {
              final x = box.maxWidth * ctrl.wipe;
              void drag(Offset p) => ctrl.setWipe(p.dx / box.maxWidth);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (e) => drag(e.localPosition),
                onHorizontalDragUpdate: (e) => drag(e.localPosition),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image(image: before, fit: BoxFit.fill),
                      ),
                      ClipRect(
                        clipper: _LeftClip(x),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image(image: after, fit: BoxFit.fill),
                        ),
                      ),
                      Positioned(
                        left: x - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x80000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: x - 17,
                        top: box.maxHeight / 2 - 17,
                        child: Container(
                          key: const Key('tools-wipe-handle'),
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x59000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const UiGlyph(
                            ToolsGlyphs.swap,
                            size: 16,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: ToolsPaneTag(beforeLabel),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: ToolsPaneTag(afterLabel),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LeftClip extends CustomClipper<Rect> {
  const _LeftClip(this.x);
  final double x;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(x, 0, size.width, size.height);

  @override
  bool shouldReclip(_LeftClip old) => old.x != x;
}

/// 结果操作（56 高）：尺寸 + 一句来历（多张结果时换成分段切换）…… 继续处理、复制、存到图库、放大、用作图生图底图。
class _ResultActions extends StatelessWidget {
  const _ResultActions();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final run = d.currentRun;
    final ok = run != null && !d.running;
    final now = d.now ?? DateTime.now();
    Widget btn(String key, Widget icon, String label, VoidCallback onTap) =>
        ToolsButton(
          key: Key('tools-act-$key'),
          small: true,
          onTap: ok ? onTap : null,
          children: [icon, Text(label)],
        );
    return Container(
      key: const Key('tools-director-actions'),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        spacing: 8,
        children: [
          if (run == null)
            Expanded(
              child: Text(
                l.tools_noResult,
                style: UiText.sans(12, color: c.faint),
              ),
            )
          else ...[
            ToolsChip(
              mono: true,
              children: [Text(ToolsFormat.size(run.width, run.height))],
            ),
            if (run.images.length > 1 &&
                run.variants.length == run.images.length)
              ToolsSeg<int>(
                key: const Key('tools-variants'),
                height: 28,
                values: [for (var i = 0; i < run.images.length; i++) i],
                selected: d.variant,
                keyOf: (i) => Key('tools-variant-$i'),
                onChanged: a.onVariant,
                label: (context, i, on) => Text(run.variants[i]),
              ),
            Expanded(
              child: Text(
                '${ToolsFormat.toolName(l, run.tool)} · '
                '${ToolsFormat.ago(l, run.time, now)} · '
                '${run.cost == null || run.cost == 0 ? l.tools_free : l.tools_anlasN(run.cost!)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.faint),
              ),
            ),
          ],
          btn(
            'continue',
            UiGlyph(ToolsGlyphs.rotate, size: 14, color: c.ink),
            l.tools_continue,
            a.onContinue,
          ),
          btn(
            'copy',
            GenNaiIcon('copy', size: 14, color: c.ink),
            l.tools_copy,
            a.onCopy,
          ),
          btn(
            'save',
            GenNaiIcon('save', size: 14, color: c.ink),
            l.tools_saveGallery,
            a.onSave,
          ),
          btn(
            'upscale',
            GenNaiIcon('upscale', size: 14, color: c.ink),
            l.tools_upscale,
            a.onUpscale,
          ),
          ToolsButton(
            key: const Key('tools-act-init'),
            tone: ToolsButtonTone.primary,
            onTap: ok ? a.onUseAsInit : null,
            children: [Text(l.tools_useAsInit)],
          ),
        ],
      ),
    );
  }
}

/// 输入队列（92 高、上分隔线、页面底）：标题 + 张数 │ 缩略图 52 × 68（选中强调色 2px 框，悬停出 ×）│ 加号 │ 说明。
class _Queue extends StatelessWidget {
  const _Queue();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final queue = Container(
      key: const Key('tools-director-queue'),
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 8,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  l.tools_queue,
                  style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
                ),
                Text(
                  l.tools_queueCount(d.inputs.length),
                  style: UiText.sans(11, color: c.faint),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  for (final i in d.inputs)
                    _QueueThumb(
                      input: i,
                      on: i.id == d.input,
                      enabled: !d.running,
                    ),
                  Builder(
                    builder: (ctx) => UiPressable(
                      key: const Key('tools-queue-add'),
                      onTap: d.running
                          ? null
                          : () {
                              final box = ctx.findRenderObject()! as RenderBox;
                              scope.controller.openPopover(
                                UiPopoverAnchor(
                                  box.localToGlobal(const Offset(0, -6)),
                                  alignBottom: true,
                                ),
                                (_) => UiMenu(
                                  width: 200,
                                  onClose: scope.controller.closePopover,
                                  items: [
                                    UiMenuItem(
                                      key: const Key('tools-queue-import'),
                                      label: l.tools_importFiles,
                                      glyph: UiGlyphs.upload,
                                      onTap: a.onImportFiles,
                                    ),
                                    UiMenuItem(
                                      key: const Key('tools-queue-history'),
                                      label: l.tools_fromHistory,
                                      glyph: UiGlyphs.clock,
                                      onTap: a.onPickHistory,
                                    ),
                                    UiMenuItem(
                                      label: l.tools_paste,
                                      glyph: UiGlyphs.clipboard,
                                      trailing: 'Ctrl+V',
                                      onTap: a.onPaste,
                                    ),
                                  ],
                                ),
                                tag: #add,
                              );
                            },
                      builder: (context, hover) => SizedBox(
                        width: 52,
                        height: 68,
                        child: UiDashedBox(
                          radius: 7,
                          color: hover ? c.accent : c.strong,
                          child: Center(
                            child: UiGlyph(
                              UiGlyphs.plus,
                              size: 18,
                              color: hover ? c.accent : c.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              l.tools_queueHint,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
        ],
      ),
    );
    return scope.slots.drop?.call(context, queue) ?? queue;
  }
}

class _QueueThumb extends StatelessWidget {
  const _QueueThumb({
    required this.input,
    required this.on,
    required this.enabled,
  });
  final ToolsDirectorInput input;
  final bool on;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final l = context.l10n;
    return UiPressable(
      key: Key('tools-queue-${input.id}'),
      onTap: on || !enabled
          ? null
          : () => scope.actions.onSelectInput(input.id),
      builder: (context, hover) => SizedBox(
        width: 52,
        height: 68,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: on ? c.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image(image: input.thumb, fit: BoxFit.cover),
                ),
              ),
            ),
            if (hover && enabled)
              Positioned(
                right: 3,
                top: 3,
                child: Tooltip(
                  message: l.tools_removeInput,
                  child: UiPressable(
                    key: Key('tools-queue-remove-${input.id}'),
                    onTap: () => scope.actions.onRemoveInput(input.id),
                    builder: (context, h) => Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: h ? .8 : .6),
                        shape: BoxShape.circle,
                      ),
                      child: const UiGlyph(
                        UiGlyphs.close,
                        size: 10,
                        strokeWidth: 2.4,
                        color: Colors.white,
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
