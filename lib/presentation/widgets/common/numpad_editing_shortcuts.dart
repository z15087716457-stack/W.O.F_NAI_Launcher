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
      SingleActivator(
        LogicalKeyboardKey.numpad4,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionByCharacterIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad6,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionByCharacterIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad8,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionVerticallyToAdjacentLineIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad2,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionVerticallyToAdjacentLineIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad7,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToLineBreakIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad1,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToLineBreakIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad7,
        control: true,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToDocumentBoundaryIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad1,
        control: true,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToDocumentBoundaryIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad9,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionVerticallyToAdjacentPageIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad3,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionVerticallyToAdjacentPageIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad4,
        control: true,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToNextWordBoundaryIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad6,
        control: true,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToNextWordBoundaryIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad8,
        control: true,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToNextParagraphBoundaryIntent(
        forward: false,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpad2,
        control: true,
        shift: shift,
        numLock: LockState.unlocked,
      ): ExtendSelectionToNextParagraphBoundaryIntent(
        forward: true,
        collapseSelection: !shift,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpadDecimal,
        shift: shift,
        numLock: LockState.unlocked,
      ): const DeleteCharacterIntent(
        forward: true,
      ),
      SingleActivator(
        LogicalKeyboardKey.numpadDecimal,
        control: true,
        shift: shift,
        numLock: LockState.unlocked,
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
