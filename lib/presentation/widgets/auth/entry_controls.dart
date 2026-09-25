import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../themes/presets/geist_theme.dart';
import '../../themes/studio_typography.dart';

/// 登录 / 载入页共用的颜色：沿用 Geist 中性灰，只有操作用品牌蓝。
@immutable
class EntryPalette {
  const EntryPalette._({
    required this.dark,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.border,
    required this.borderStrong,
    required this.control,
    required this.hover,
    required this.card,
    required this.input,
    required this.segment,
    required this.error,
    required this.blueHover,
    required this.ring,
    required this.cardShadow,
    required this.segmentShadow,
  });

  factory EntryPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return EntryPalette._(
      dark: dark,
      ink: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      faint: dark ? const Color(0xFF6B6B6B) : const Color(0xFF8F8F8F),
      border: scheme.outlineVariant,
      borderStrong: dark ? const Color(0xFF3A3A3A) : const Color(0xFFD1D1D1),
      control: dark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2),
      hover: dark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.045),
      card: dark
          ? const Color(0xFF181818).withValues(alpha: 0.70)
          : Colors.white.withValues(alpha: 0.72),
      input: dark ? const Color(0xFF0C0C0C) : Colors.white,
      segment: dark ? const Color(0xFF2B2B2B) : Colors.white,
      error: scheme.error,
      blueHover: dark ? const Color(0xFF1F6FFF) : const Color(0xFF004BD1),
      ring: dark
          ? const Color(0xFF3D8BFF).withValues(alpha: 0.30)
          : GeistTheme.blue.withValues(alpha: 0.16),
      cardShadow: dark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 56,
                spreadRadius: -16,
                offset: const Offset(0, 24),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 44,
                spreadRadius: -14,
                offset: const Offset(0, 18),
              ),
            ],
      segmentShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.5 : 0.10),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          spreadRadius: 1,
        ),
      ],
    );
  }

  final bool dark;
  final Color ink, muted, faint, border, borderStrong, control, hover;
  final Color card, input, segment, error, blueHover, ring;
  final List<BoxShadow> cardShadow, segmentShadow;

  Color get blue => GeistTheme.blue;
}

/// 磨砂卡片：背后的字符场透过来被模糊，卡片本身只有一条细边和软阴影。
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final radius = BorderRadius.circular(12);
    return CustomPaint(
      painter: _OutsetShadowPainter(palette.cardShadow, 12),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: radius,
              border: Border.all(color: palette.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 只画在卡片外面的阴影：卡片是半透明的，BoxShadow 会连卡片底下一起
/// 压暗，所以先把卡片区域裁掉再画。
class _OutsetShadowPainter extends CustomPainter {
  const _OutsetShadowPainter(this.shadows, this.radius);
  final List<BoxShadow> shadows;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(box.outerRect.inflate(200))
        ..addRRect(box),
    );
    for (final shadow in shadows) {
      canvas.drawRRect(
        box.shift(shadow.offset).inflate(shadow.spreadRadius),
        shadow.toPaint(),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OutsetShadowPainter oldDelegate) =>
      oldDelegate.shadows != shadows || oldDelegate.radius != radius;
}

/// 标签在上、细边输入框在下；聚焦时蓝边加一圈淡蓝光环。
class EntryTextField extends StatefulWidget {
  const EntryTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.trailing = const [],
    this.labelAction,
    this.monospace = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  /// 校验读取的是 [controller] 的当前文本（粘贴按钮会直接改写它）。
  final FormFieldValidator<String>? validator;
  final List<Widget> trailing;

  /// 标签行右侧的小链接，例如“获取 Token”。
  final Widget? labelAction;
  final bool monospace;
  final bool enabled;

  @override
  State<EntryTextField> createState() => _EntryTextFieldState();
}

class _EntryTextFieldState extends State<EntryTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focused != _focus.hasFocus) {
        setState(() => _focused = _focus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final textStyle = widget.monospace
        ? StudioTypography.data.copyWith(
            fontSize: 12.5,
            letterSpacing: 0.25,
            color: palette.ink,
          )
        : TextStyle(fontSize: 13.5, color: palette.ink);
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (field) {
        final error = field.errorText;
        final accent = error != null ? palette.error : palette.blue;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: palette.muted,
                    ),
                  ),
                ),
                if (widget.labelAction != null) widget.labelAction!,
              ],
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              constraints: const BoxConstraints(minHeight: 38),
              decoration: BoxDecoration(
                color: palette.input,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: error != null
                      ? palette.error
                      : _focused
                      ? palette.blue
                      : palette.borderStrong,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: error != null
                              ? palette.error.withValues(alpha: 0.22)
                              : palette.ring,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focus,
                        enabled: widget.enabled,
                        obscureText: widget.obscureText,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        onSubmitted: widget.onFieldSubmitted,
                        onChanged: (value) {
                          field.didChange(value);
                          if (field.hasError) field.validate();
                        },
                        autocorrect: false,
                        enableSuggestions: false,
                        cursorColor: accent,
                        cursorWidth: 1.5,
                        style: textStyle,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          // 主题里的输入框内边距不能带进来，高度由外框控制
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: widget.hintText,
                          hintStyle: textStyle.copyWith(color: palette.faint),
                        ),
                      ),
                    ),
                  ),
                  ...widget.trailing,
                  if (widget.trailing.isNotEmpty) const SizedBox(width: 3),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.error_outline,
                        size: 13,
                        color: palette.error,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(fontSize: 12, color: palette.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 输入框内的小图标按钮（粘贴、显示 / 隐藏）。
class EntryFieldAction extends StatelessWidget {
  const EntryFieldAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        hoverColor: palette.hover,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 16, color: palette.muted),
        ),
      ),
    );
  }
}

/// 标签行右侧的蓝色小链接。
class EntryLink extends StatelessWidget {
  const EntryLink({
    super.key,
    required this.label,
    required this.onTap,
    this.external = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback onTap;
  final bool external;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final link = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: palette.blue)),
            if (external) ...[
              const SizedBox(width: 2),
              Icon(Icons.north_east, size: 11, color: palette.blue),
            ],
          ],
        ),
      ),
    );
    return tooltip == null ? link : Tooltip(message: tooltip!, child: link);
  }
}

/// 主操作按钮：品牌蓝，右侧淡淡提示回车；忙碌时保持蓝色、显示像素点。
class EntryPrimaryButton extends StatelessWidget {
  const EntryPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final enabled = onPressed != null && !busy;
    final background = busy || onPressed != null
        ? palette.blue
        : palette.control;
    final foreground = busy || onPressed != null ? Colors.white : palette.muted;
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) && enabled
                ? palette.blueHover
                : background,
          ),
          foregroundColor: WidgetStatePropertyAll(foreground),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStatePropertyAll(
            StudioTypography.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy) ...[
                  EntryBusyDots(color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    busy ? (busyLabel ?? label) : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (!busy && onPressed != null)
              Positioned(
                right: 0,
                child: ExcludeSemantics(
                  child: Text(
                    '↵',
                    style: StudioTypography.data.copyWith(
                      fontSize: 11,
                      color: foreground.withValues(alpha: 0.6),
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

/// 三个依次明灭的小方块：像素风的“进行中”。
class EntryBusyDots extends StatefulWidget {
  const EntryBusyDots({super.key, required this.color});
  final Color color;

  @override
  State<EntryBusyDots> createState() => _EntryBusyDotsState();
}

class _EntryBusyDotsState extends State<EntryBusyDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 960),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final step = (_controller.value * 6).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Container(
                width: 4,
                height: 4,
                color: widget.color.withValues(
                  alpha: _controller.isAnimating && (step - i) % 3 != 0
                      ? 0.3
                      : 1,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 卡片内的错误提示：标题、恢复建议和一个可选的文字操作。
class EntryAlert extends StatelessWidget {
  const EntryAlert({
    super.key,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.error.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: palette.error,
            ),
          ),
          if (hint != null && hint != title) ...[
            const SizedBox(height: 3),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: Color.lerp(palette.error, palette.muted, 0.35),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: palette.error,
                  decoration: TextDecoration.underline,
                  decorationColor: palette.error.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 游客入口：等宽字 SKIP 加箭头，悬停时箭头右移一点。
class EntrySkipButton extends StatefulWidget {
  const EntrySkipButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<EntrySkipButton> createState() => _EntrySkipButtonState();
}

class _EntrySkipButtonState extends State<EntrySkipButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final color = _hover ? palette.ink : palette.muted;
    return Tooltip(
      message: context.l10n.auth_guestEntry,
      child: Semantics(
        button: true,
        label: context.l10n.auth_guestEntry,
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.onPressed,
          onHover: (hover) => setState(() => _hover = hover),
          borderRadius: BorderRadius.circular(6),
          hoverColor: palette.hover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SKIP',
                  style: StudioTypography.data.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.7,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: Offset(_hover ? 0.25 : 0, 0),
                  child: Icon(Icons.arrow_forward, size: 13, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 次要文字按钮（添加账号、返回）：灰字，悬停变深并铺一层淡底。
class EntryGhostButton extends StatefulWidget {
  const EntryGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  State<EntryGhostButton> createState() => _EntryGhostButtonState();
}

class _EntryGhostButtonState extends State<EntryGhostButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final color = widget.onPressed == null
        ? palette.faint
        : _hover
        ? palette.ink
        : palette.muted;
    return InkWell(
      onTap: widget.onPressed,
      onHover: (hover) => setState(() => _hover = hover),
      borderRadius: BorderRadius.circular(6),
      hoverColor: palette.hover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 小方框勾选（自动登录）。
class EntryCheckbox extends StatelessWidget {
  const EntryCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: value ? palette.ink : palette.input,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: value ? palette.ink : palette.borderStrong,
                  ),
                ),
                child: value
                    ? Icon(
                        Icons.check,
                        size: 12,
                        color: Theme.of(context).colorScheme.surface,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12.5, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
