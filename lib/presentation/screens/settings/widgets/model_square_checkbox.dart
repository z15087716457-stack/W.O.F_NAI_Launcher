import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';

/// Capability feedback stays inside the square; the hit area remains larger.
class ModelSquareCheckbox extends StatefulWidget {
  const ModelSquareCheckbox({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.onChanged,
  });
  final bool value;
  final String semanticLabel;
  final ValueChanged<bool>? onChanged;

  @override
  State<ModelSquareCheckbox> createState() => _ModelSquareCheckboxState();
}

class _ModelSquareCheckboxState extends State<ModelSquareCheckbox> {
  final _focus = FocusNode();
  bool _hovered = false, _pressed = false, _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    _focus.requestFocus();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = widget.onChanged != null;
    final highlighted = enabled && (_hovered || _pressed);
    final fill = widget.value
        ? colors.onSurface.withValues(
            alpha: enabled ? (highlighted ? .85 : 1) : .25,
          )
        : colors.onSurface.withValues(
            alpha: highlighted ? (_pressed ? .16 : .09) : 0,
          );
    return Semantics(
      checked: widget.value,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: enabled ? _toggle : null,
      child: FocusableActionDetector(
        focusNode: _focus,
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: enabled ? _toggle : null,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            child: SizedBox(
              width: 24,
              height: 28,
              child: Center(
                child: Container(
                  key: ValueKey('capability-box-${widget.semanticLabel}'),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: enabled && _focused
                          ? colors.primary
                          : widget.value
                          ? fill
                          : colors.onSurfaceVariant.withValues(
                              alpha: enabled ? .75 : .3,
                            ),
                      width: enabled && _focused ? 1.6 : 1.2,
                    ),
                  ),
                  child: widget.value
                      ? Icon(Icons.check, size: 14, color: colors.surface)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
