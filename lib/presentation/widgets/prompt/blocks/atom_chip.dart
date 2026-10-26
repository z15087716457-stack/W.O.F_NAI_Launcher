import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../common/dashed_rounded_border.dart';
import '../../common/workspace_text_scale_scope.dart';

/// 紧凑描边 chip：无图标、无内部填充色，描边跟主题色。
/// 编辑器内联使用；详情面板正文原子化渲染同件复用。
///
/// 折行语义（静拍板·多层换行）：长原子文本超过可用宽度时，
/// chip 内部按 [TextPainter] 预折行渲染成**一列逐行小框**——
/// 每行一个真 widget（自带描边），行间留白；行框开口处的蓝色
/// 虚线提示「这是一个换行过的块」。
/// 一个原子仍是一个 [WidgetSpan] 占位，编辑语义零改动。
class AtomChip extends StatelessWidget {
  const AtomChip({
    super.key,
    required this.text,
    required this.theme,
    this.borderColor,
    this.textStyle,
  });

  final String text;
  final ThemeData theme;
  final Color? borderColor;

  /// 缺省 = bodyMedium/1.35（编辑器内联度量）；展示场景可传更小样式。
  final TextStyle? textStyle;

  static const double _radius = 5;

  /// 行框之间保留空白，避免连接线看起来越过上下框边。
  static const double _seamGap = 6;
  static const EdgeInsets _pad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 2,
  );

  /// 行框给文字的富余宽：RenderParagraph 对行宽有 ceil 取整，
  /// 槽宽恰等于 advance 时会误判 hasVisualOverflow 把末字形
  /// overhang 啃掉；留 4px 槽余量 + overflow.visible 兜底。
  static const double _textSlack = 4;

  @override
  Widget build(BuildContext context) =>
      WorkspaceTextScaleScope(child: Builder(builder: _buildChip));

  Widget _buildChip(BuildContext context) {
    final style =
        textStyle ?? theme.textTheme.bodyMedium?.copyWith(height: 1.35);
    final color = borderColor ?? theme.colorScheme.outlineVariant;
    // 蓝色只标记折行产生的开口；显式错误描边（孤儿原子）仍保持红色。
    final breakColor =
        borderColor ?? theme.colorScheme.primary.withValues(alpha: 0.8);
    return LayoutBuilder(
      builder: (context, constraints) {
        // WidgetSpan 子树拿 BoxConstraints(maxWidth: 段落宽)、不限高：
        // maxWidth 即文本区可用宽，扣掉内边距就是折行宽。
        // 无界场景（理论上）退化为单行 chip。
        final maxW = constraints.maxWidth;
        final wrapWidth = maxW.isFinite
            ? maxW - _pad.horizontal - 4
            : double.infinity;
        final segs = _wrapSegments(context, style, wrapWidth);

        if (segs.length <= 1) {
          return _lineBox(
            context,
            style,
            color,
            segs.first,
            topRounded: true,
            bottomRounded: true,
            solidLeft: true,
            solidRight: true,
          );
        }
        // 逐行小框：横边恒实；首行左竖边实、末行右竖边实，
        // 其余竖边是蓝色虚线。行间只留空白，不再绘制额外连接线。
        final children = <Widget>[];
        for (var i = 0; i < segs.length; i++) {
          if (i > 0) {
            children.add(const SizedBox(height: _seamGap));
          }
          children.add(
            _lineBox(
              context,
              style,
              color,
              segs[i],
              breakColor: breakColor,
              topRounded: i == 0,
              bottomRounded: i == segs.length - 1,
              solidLeft: i == 0,
              solidRight: i == segs.length - 1,
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  /// 预折行：返回每视觉行的文本段与整行框宽（文本宽+水平内边距）。
  List<_Seg> _wrapSegments(
    BuildContext context,
    TextStyle? style,
    double wrapWidth,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: wrapWidth.isFinite ? wrapWidth : 1e9);

    final segs = <_Seg>[];
    var start = 0;
    while (start < text.length) {
      final range = tp.getLineBoundary(TextPosition(offset: start));
      var end = range.end;
      if (end <= start) end = start + 1; // 防死循环
      var segText = text.substring(start, end);
      // 行尾空白不渲染（折点空白吃掉，拼接不靠它）。
      segText = segText.trimRight();
      if (segText.isNotEmpty) {
        final w =
            _measure(context, style, segText) + _pad.horizontal + _textSlack;
        segs.add(_Seg(segText, w));
      }
      start = end;
    }
    if (segs.isEmpty) {
      segs.add(
        _Seg(
          text,
          _measure(context, style, text) + _pad.horizontal + _textSlack,
        ),
      );
    }
    return segs;
  }

  double _measure(BuildContext context, TextStyle? style, String s) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  /// 单行框：自绘描边（静拍板·实线只留首尾）。横边恒实线；
  /// 首行左竖边实、末行右竖边实（「起点/终点」），其余竖边
  /// 全虚线；四角在相邻两边都实时画圆弧，否则直角。border
  /// 画在文字上层，overhang 墨迹被描边遮住，视觉「线在字外」。
  Widget _lineBox(
    BuildContext context,
    TextStyle? style,
    Color color,
    _Seg seg, {
    Color? breakColor,
    required bool topRounded,
    required bool bottomRounded,
    required bool solidLeft,
    required bool solidRight,
  }) {
    const r = Radius.circular(_radius);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: seg.width,
      // CustomPaint 必须包在 Padding 外：描边按 child 尺寸画，
      // 放内层会把 padding 画到框外、文字贴边。
      child: CustomPaint(
        foregroundPainter: DashedRoundedBorderPainter(
          color: color,
          dashedColor: breakColor ?? color,
          radius: r,
          topRounded: topRounded,
          bottomRounded: bottomRounded,
          solidLeft: solidLeft,
          solidRight: solidRight,
        ),
        child: Padding(
          padding: _pad,
          child: Text(
            seg.text,
            style: style,
            softWrap: false,
            // 槽已留余量，溢出=墨迹 overhang 允许画到 padding 区。
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}

/// 一行文本段 + 它的行框宽。
class _Seg {
  const _Seg(this.text, this.width);
  final String text;
  final double width;
}
