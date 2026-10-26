import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/autocomplete/prompt_autocomplete_controller.dart';

/// Optional presentation hook. Implementations listen to controller.value and
/// render a non-focusable overlay; child is the original prompt editor.
typedef PromptAutocompleteBuilder =
    Widget Function(
      BuildContext context,
      PromptAutocompleteController controller,
      ValueChanged<int> accept,
      Widget child,
    );

final promptAutocompleteBuilderProvider = Provider<PromptAutocompleteBuilder?>(
  (ref) => null,
);

/// Lifecycle/keyboard adapter only; no popup, visuals or focus transfer.
class PromptAutocompleteBinding extends StatefulWidget {
  const PromptAutocompleteBinding({
    super.key,
    required this.autocomplete,
    required this.controller,
    required this.focusNode,
    required this.locale,
    required this.autoInsertComma,
    required this.onAccept,
    this.builder,
    required this.child,
  });
  final PromptAutocompleteController? autocomplete;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String locale;
  final bool autoInsertComma;
  final ValueChanged<TextEditingValue> onAccept;
  final PromptAutocompleteBuilder? builder;
  final Widget child;

  @override
  State<PromptAutocompleteBinding> createState() =>
      _PromptAutocompleteBindingState();
}

class _PromptAutocompleteBindingState extends State<PromptAutocompleteBinding> {
  bool _accepting = false;

  void _accept(TextEditingValue value) {
    _accepting = true;
    try {
      widget.onAccept(value);
    } finally {
      _accepting = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    if (widget.autocomplete == null) return;
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_focusChanged);
  }

  void _detach(PromptAutocompleteBinding binding) {
    if (binding.autocomplete == null) return;
    binding.controller.removeListener(_changed);
    binding.focusNode.removeListener(_focusChanged);
    binding.autocomplete!.dismiss();
  }

  @override
  void deactivate() {
    widget.autocomplete?.dismiss();
    super.deactivate();
  }

  @override
  void didUpdateWidget(PromptAutocompleteBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autocomplete != widget.autocomplete ||
        oldWidget.controller != widget.controller ||
        oldWidget.focusNode != widget.focusNode) {
      _detach(oldWidget);
      _attach();
    } else if (oldWidget.locale != widget.locale) {
      widget.autocomplete?.dismiss();
    }
  }

  void _changed() {
    if (_accepting || !widget.focusNode.hasPrimaryFocus) return;
    widget.autocomplete?.update(widget.controller.value, locale: widget.locale);
  }

  void _focusChanged() {
    if (!widget.focusNode.hasPrimaryFocus) widget.autocomplete?.dismiss();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) =>
      widget.focusNode.hasPrimaryFocus &&
          widget.autocomplete?.handleKeyEvent(
                event,
                onAccept: _accept,
                autoInsertComma: widget.autoInsertComma,
              ) ==
              true
      ? KeyEventResult.handled
      : KeyEventResult.ignored;

  @override
  void dispose() {
    _detach(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: widget.autocomplete == null ? null : _key,
      child: widget.child,
    );
    return widget.autocomplete != null && widget.builder != null
        ? widget.builder!(context, widget.autocomplete!, (index) {
            final value = widget.autocomplete!.accept(
              index,
              widget.autoInsertComma,
            );
            if (value != null) _accept(value);
          }, child)
        : child;
  }
}
