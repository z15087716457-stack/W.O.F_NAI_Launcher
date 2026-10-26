import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Windows reports numpad logical keys even when NumLock is off.
/// Keep NumLock-on events untouched so native text input can enter numbers.
class NumpadEditingShortcuts extends StatelessWidget {
  const NumpadEditingShortcuts({super.key, required this.child});

  final Widget child;

  // Based on DefaultTextEditingShortcuts._linuxNumpadShortcuts' unlocked
  // intents, plus Shift selection extension (collapseSelection: false).
  // numpad7/1 follow Windows Home/End (line start/end; Ctrl = document),
  // instead of the Linux table's adjacent-line mapping.
  static final _shortcuts = <ShortcutActivator, Intent>{
    for (final shift in [false, true]) ...{
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad4,
        shift: shift,
      ): ExtendSelectionByCharacterIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad6,
        shift: shift,
      ): ExtendSelectionByCharacterIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad8,
        shift: shift,
      ): ExtendSelectionVerticallyToAdjacentLineIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad2,
        shift: shift,
      ): ExtendSelectionVerticallyToAdjacentLineIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad7,
        shift: shift,
      ): ExtendSelectionToLineBreakIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad1,
        shift: shift,
      ): ExtendSelectionToLineBreakIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad7,
        control: true,
        shift: shift,
      ): ExtendSelectionToDocumentBoundaryIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad1,
        control: true,
        shift: shift,
      ): ExtendSelectionToDocumentBoundaryIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad9,
        shift: shift,
      ): ExtendSelectionVerticallyToAdjacentPageIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad3,
        shift: shift,
      ): ExtendSelectionVerticallyToAdjacentPageIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad4,
        control: true,
        shift: shift,
      ): ExtendSelectionToNextWordBoundaryIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad6,
        control: true,
        shift: shift,
      ): ExtendSelectionToNextWordBoundaryIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad8,
        control: true,
        shift: shift,
      ): ExtendSelectionToNextParagraphBoundaryIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpad2,
        control: true,
        shift: shift,
      ): ExtendSelectionToNextParagraphBoundaryIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      NumpadNavigationActivator(LogicalKeyboardKey.numpadDecimal, shift: shift):
          const DeleteCharacterIntent(forward: true),
      NumpadNavigationActivator(
        LogicalKeyboardKey.numpadDecimal,
        control: true,
        shift: shift,
      ): const DeleteToNextWordBoundaryIntent(
        forward: true,
      ),
    },
  };

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.windows) return child;
    return Shortcuts(shortcuts: _shortcuts, child: child);
  }
}

/// Windows can start with NumLock enabled before Flutter learns its lock state.
/// A character on this event is authoritative: leave it for native text input.
class NumpadNavigationActivator extends SingleActivator {
  const NumpadNavigationActivator(super.trigger, {super.control, super.shift});

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      event.character == null && super.accepts(event, state);
}
