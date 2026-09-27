import 'package:flutter/material.dart';

/// 紧凑数值控制：箭头微调、横向拖动快调、点击数值精确输入。
/// 空值表示块不覆盖当前参数。
class CompactParameterNumberField extends StatefulWidget {
  const CompactParameterNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.fallback,
    required this.min,
    required this.max,
    required this.step,
    this.decimals = 0,
  });

  final String label;
  final TextEditingController controller;
  final double fallback;
  final double min;
  final double max;
  final double step;
  final int decimals;

  @override
  State<CompactParameterNumberField> createState() =>
      _CompactParameterNumberFieldState();
}

class _CompactParameterNumberFieldState
    extends State<CompactParameterNumberField> {
  bool _editing = false;
  double _dragStartValue = 0;
  double _dragStartX = 0;

  String _format(double value) => widget.decimals == 0
      ? value.round().toString()
      : value.toStringAsFixed(widget.decimals);

  double get _value =>
      double.tryParse(widget.controller.text) ?? widget.fallback;

  void _setValue(double value) {
    final normalized = (value / widget.step).round() * widget.step;
    widget.controller.text = _format(normalized.clamp(widget.min, widget.max));
    setState(() {});
  }

  void _finishEditing() {
    if (!_editing) return;
    final raw = widget.controller.text.trim();
    if (raw.isNotEmpty) {
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed.isFinite) {
        widget.controller.text = _format(parsed.clamp(widget.min, widget.max));
      }
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            widget.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted,
              fontSize: 11,
            ),
          ),
        ),
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
          child: Row(
            children: [
              _arrow(context, Icons.chevron_left, -1),
              Expanded(
                child: _editing
                    ? TextField(
                        controller: widget.controller,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _finishEditing(),
                        onTapOutside: (_) => _finishEditing(),
                      )
                    : MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _editing = true),
                          onHorizontalDragDown: (details) {
                            _dragStartValue = _value;
                            _dragStartX = details.globalPosition.dx;
                          },
                          onHorizontalDragUpdate: (details) {
                            final dragDistance =
                                details.globalPosition.dx - _dragStartX;
                            _setValue(
                              _dragStartValue +
                                  (dragDistance / 10).round() * widget.step,
                            );
                          },
                          child: Center(
                            child: Text(
                              widget.controller.text.trim().isEmpty
                                  ? '—'
                                  : widget.controller.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: widget.controller.text.trim().isEmpty
                                    ? muted
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              if (widget.controller.text.trim().isNotEmpty && !_editing)
                InkWell(
                  key: Key('clear-${widget.label}'),
                  onTap: () => setState(() => widget.controller.clear()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.close, size: 12, color: muted),
                  ),
                ),
              _arrow(context, Icons.chevron_right, 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _arrow(BuildContext context, IconData icon, int direction) {
    return InkWell(
      onTap: () => _setValue(_value + direction * widget.step),
      child: SizedBox(
        width: 29,
        height: 32,
        child: Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
