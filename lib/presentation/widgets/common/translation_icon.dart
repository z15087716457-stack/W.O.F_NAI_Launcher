import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../themes/studio_typography.dart';
import 'uiux_prototype_icon.dart';

enum TranslationIconStyle { prototype, pill }

/// Translation artwork from the selected prototypes. The prototypes define no
/// busy artwork, so activity only pulses the same glyph's opacity; hosts still
/// own tooltips and disabled states.
class TranslationIcon extends StatefulWidget {
  const TranslationIcon({
    super.key,
    this.size,
    this.color,
    this.busy = false,
    this.style = TranslationIconStyle.prototype,
  });

  final double? size;
  final Color? color;
  final bool busy;
  final TranslationIconStyle style;

  @override
  State<TranslationIcon> createState() => _TranslationIconState();
}

class _TranslationIconState extends State<TranslationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: .35,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  void _syncPulse() {
    final run =
        widget.busy &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (run) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(TranslationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy) _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = widget.size ?? theme.size ?? 24;
    final ink =
        widget.color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    final Widget glyph = widget.style == TranslationIconStyle.pill
        // The HTML slot is as wide as the 10px glyph, not a square icon box.
        ? SizedBox(
            height: dimension,
            child: Center(
              widthFactor: 1,
              child: RichText(
                textScaler: TextScaler.noScaling,
                text: TextSpan(
                  // The prototype uses this glyph as artwork, not a label.
                  text: '译',
                  style: TextStyle(
                    fontFamily: StudioTypography.cjk,
                    fontSize: dimension * 10 / 12,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: ink.withValues(alpha: ink.a * (theme.opacity ?? 1)),
                  ),
                ),
              ),
            ),
          )
        : SizedBox.square(
            dimension: dimension,
            child: Center(
              child: UiuxPrototypeIcon(
                Icons.translate,
                size: dimension,
                color: widget.color,
              ),
            ),
          );
    return ExcludeSemantics(
      child: FadeTransition(opacity: _opacity, child: glyph),
    );
  }
}
