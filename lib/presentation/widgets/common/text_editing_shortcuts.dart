import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A page shortcut must yield to both a TextField's focus node and any focus
/// nested inside EditableText (for example an inline source field).
bool get hasEditableTextFocus {
  final context = FocusManager.instance.primaryFocus?.context;
  return context != null &&
      (context.widget is EditableText ||
          context.findAncestorWidgetOfExactType<EditableText>() != null);
}

/// Marks an area with its own undo semantics; prompt fallback never enters it.
class PromptUndoBoundary extends InheritedWidget {
  const PromptUndoBoundary({super.key, required super.child});

  @override
  bool updateShouldNotify(PromptUndoBoundary oldWidget) => false;
}

/// Application-wide Ctrl+Y plus a deliberately narrow blurred-prompt fallback.
/// Focused text always uses its own Actions. Other page/route undo handlers run
/// first; canvas/editor areas opt out through [PromptUndoBoundary].
class TextEditingShortcuts extends StatefulWidget {
  const TextEditingShortcuts({super.key, required this.child});
  final Widget child;

  static TextEditingShortcutsState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<TextEditingShortcutsState>();

  @override
  State<TextEditingShortcuts> createState() => TextEditingShortcutsState();
}

class TextEditingShortcutsState extends State<TextEditingShortcuts> {
  BuildContext? _target;
  VoidCallback? _undo;
  VoidCallback? _redo;

  void rememberPrompt(
    BuildContext owner, {
    required VoidCallback undo,
    required VoidCallback redo,
  }) {
    _target = owner;
    _undo = undo;
    _redo = redo;
  }

  void forgetPrompt(BuildContext owner) {
    if (!identical(_target, owner)) return;
    _target = null;
    _undo = null;
    _redo = null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        !HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        hasEditableTextFocus) {
      return KeyEventResult.ignored;
    }
    final target = _target;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (target == null || !target.mounted || focused == null) {
      return KeyEventResult.ignored;
    }
    final route = ModalRoute.of(target);
    if (route == null ||
        !route.isCurrent ||
        ModalRoute.of(focused) != route ||
        focused.getInheritedWidgetOfExactType<PromptUndoBoundary>() != null) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyZ) {
      (HardwareKeyboard.instance.isShiftPressed ? _redo : _undo)?.call();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyY &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _redo?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: _onKey,
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoTextIntent(
          SelectionChangedCause.keyboard,
        ),
      },
      child: widget.child,
    ),
  );
}
