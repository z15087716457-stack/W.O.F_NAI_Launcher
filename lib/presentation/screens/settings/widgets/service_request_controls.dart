import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../themes/studio_typography.dart';

const serviceControlRadius = BorderRadius.all(Radius.circular(6));

class ServiceRequestStepper extends StatefulWidget {
  const ServiceRequestStepper({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.unit,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    this.step = 1,
    this.enabled = true,
  });

  final String fieldKey, label, unit;
  final int value, minimum, maximum, step;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  State<ServiceRequestStepper> createState() => _ServiceRequestStepperState();
}

class _ServiceRequestStepperState extends State<ServiceRequestStepper> {
  late final _controller = TextEditingController(
    text: widget.value < 0 ? '' : '${widget.value}',
  );

  @override
  void didUpdateWidget(ServiceRequestStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        (int.tryParse(_controller.text) ?? -1) != widget.value) {
      final text = widget.value < 0 ? '' : '${widget.value}';
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adjust(int direction) {
    final value = widget.value;
    final next = value < widget.minimum || value > widget.maximum
        ? value.clamp(widget.minimum, widget.maximum)
        : (value + direction * widget.step).clamp(
            widget.minimum,
            widget.maximum,
          );
    _controller.value = TextEditingValue(
      text: '$next',
      selection: TextSelection.collapsed(offset: '$next'.length),
    );
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final height = 36 + (scale - 1).clamp(0.0, 10.0) * 18;
    final invalid =
        widget.value < widget.minimum || widget.value > widget.maximum;
    final border = OutlineInputBorder(
      borderRadius: serviceControlRadius,
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    Widget button(int direction) {
      final enabled =
          widget.enabled &&
          (invalid ||
              (direction < 0
                  ? widget.value > widget.minimum
                  : widget.value < widget.maximum));
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: serviceControlRadius,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: .04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : const [],
        ),
        child: IconButton(
          key: Key(
            '${widget.fieldKey}-${direction < 0 ? 'decrease' : 'increase'}',
          ),
          tooltip:
              '${direction < 0 ? '减少' : '增加'}${widget.label}（${widget.step} ${widget.unit}）',
          onPressed: enabled ? () => _adjust(direction) : null,
          style: IconButton.styleFrom(
            fixedSize: Size.square(height),
            minimumSize: Size.square(height),
            padding: EdgeInsets.zero,
            foregroundColor: colors.onSurfaceVariant,
            backgroundColor: colors.onSurface.withValues(alpha: .045),
            disabledForegroundColor: colors.onSurface.withValues(alpha: .25),
            disabledBackgroundColor: colors.onSurface.withValues(alpha: .025),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            shape: RoundedRectangleBorder(
              borderRadius: serviceControlRadius,
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
          icon: Icon(direction < 0 ? Icons.remove : Icons.add, size: 17),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 204 * scale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                button(-1),
                const SizedBox(width: 7),
                Expanded(
                  child: SizedBox(
                    height: height,
                    child: TextFormField(
                      key: Key(widget.fieldKey),
                      controller: _controller,
                      enabled: widget.enabled,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: theme.textTheme.bodyMedium?.merge(
                        StudioTypography.data,
                      ),
                      decoration: InputDecoration(
                        constraints: BoxConstraints.tightFor(height: height),
                        isDense: true,
                        filled: true,
                        fillColor: colors.onSurface.withValues(alpha: .025),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        border: border,
                        disabledBorder: border.copyWith(
                          borderSide: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: .5),
                          ),
                        ),
                        enabledBorder: invalid
                            ? border.copyWith(
                                borderSide: BorderSide(color: colors.error),
                              )
                            : border,
                        focusedBorder: border.copyWith(
                          borderSide: BorderSide(
                            color: invalid ? colors.error : colors.primary,
                          ),
                        ),
                      ),
                      onChanged: (text) =>
                          widget.onChanged(int.tryParse(text) ?? -1),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                button(1),
                const SizedBox(width: 8),
                SizedBox(
                  key: Key('${widget.fieldKey}-unit'),
                  width: 20 * scale,
                  height: height,
                  child: Center(
                    child: Text(
                      widget.unit,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (invalid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${widget.minimum}–${widget.maximum} ${widget.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ServiceRetrySegments extends StatelessWidget {
  const ServiceRetrySegments({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: .045),
        borderRadius: serviceControlRadius,
      ),
      child: Row(
        children: [
          for (var i = 0; i <= 3; i++)
            Expanded(
              child: Semantics(
                selected: value == i,
                child: TextButton(
                  key: ValueKey('service-retry-$i'),
                  onPressed: enabled ? () => onChanged(i) : null,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    foregroundColor: value == i
                        ? colors.surface
                        : colors.onSurfaceVariant,
                    backgroundColor: value == i
                        ? colors.onSurface
                        : Colors.transparent,
                    disabledBackgroundColor: value == i
                        ? colors.onSurface.withValues(alpha: .12)
                        : Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: serviceControlRadius,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.standard,
                    textStyle: theme.textTheme.bodyMedium,
                  ),
                  child: Text(i == 0 ? '关闭' : '$i 次'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
