import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Routes native Win+V pastes through the focused editor's existing actions.
class ClipboardHistoryPaste {
  static const channel = MethodChannel('com.nailauncher/clipboard_history');

  void register() => channel.setMethodCallHandler(_handle);

  void dispose() => channel.setMethodCallHandler(null);

  Future<void> _handle(MethodCall call) async {
    if (call.method != 'paste') throw MissingPluginException();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context != null) {
      Actions.maybeInvoke(
        context,
        const PasteTextIntent(SelectionChangedCause.keyboard),
      );
    }
  }
}
