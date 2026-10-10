import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/tips_provider.dart';

/// 空状态欢迎页：品牌 Logo + 一条小贴士，每次露面取下一条，停留期间不换。
///
/// Logo 的大小和位置不随文字长短变化：短句时与旧版居中位置一致，
/// 长段落往下排进空白区；窗口太矮时整页滚动，不再整体缩小。
class TipWelcome extends ConsumerStatefulWidget {
  const TipWelcome({
    super.key,
    required this.surface,
    required this.logoAspectRatio,
    required this.logoWidthFor,
    required this.logoBuilder,
  });

  final TipSurface surface;

  /// Logo 宽 / 高。
  final double logoAspectRatio;

  /// 按内容列宽（≤ 400）给出 Logo 宽度。
  final double Function(double columnWidth) logoWidthFor;

  final Widget Function(double width) logoBuilder;

  @override
  ConsumerState<TipWelcome> createState() => _TipWelcomeState();
}

class _TipWelcomeState extends ConsumerState<TipWelcome> {
  late final Tip _tip = ref.read(tipDeckProvider).draw(widget.surface);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(0.0, constraints.maxWidth - 48);
        final column = math.min(400.0, available);
        final logoWidth = widget.logoWidthFor(column);
        final logoHeight = logoWidth / widget.logoAspectRatio;
        // 旧版把「Logo + 标签 + 一行贴士」整体放在 Alignment(0, -.08)；
        // 这里按同样的短内容高度算出 Logo 顶边，之后只往下长。
        final top = constraints.hasBoundedHeight
            ? math.max(
                24.0,
                24 + (constraints.maxHeight - 48 - logoHeight - 76) * .46,
              )
            : 24.0;
        final page = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, top, 24, 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.logoBuilder(logoWidth),
                const SizedBox(height: 32),
                Text(
                  _tip.label(l10n).toUpperCase(),
                  key: const Key('tip-welcome-label'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: .32),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.min(440.0, available),
                  ),
                  child: Text(
                    _tip.text(l10n),
                    key: const Key('tip-welcome-text'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: scheme.onSurface.withValues(alpha: .48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        // 宽松约束（如 Row 内）下也铺满可用高度，Logo 才能停在算好的位置
        return constraints.hasBoundedHeight
            ? SizedBox(height: constraints.maxHeight, child: page)
            : page;
      },
    );
  }
}
