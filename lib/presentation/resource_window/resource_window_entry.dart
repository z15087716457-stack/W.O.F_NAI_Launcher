import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/resource_window_protocol.dart';
import '../../core/services/resource_window_service.dart';
import '../../l10n/app_localizations.dart';

/// Intentionally no ProviderScope, data-directory resolution, Hive/SQLite,
/// migrations, logging files, bootstrap, Agent, RAG, Krita, tray or media setup.
Future<void> runResourceWindow(
  WindowController controller,
  ResourceWindowArguments arguments,
) async {
  const native = MethodChannel('com.nailauncher/resource_window_native');
  await controller.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'resource.close':
        return native.invokeMethod<void>('close');
      case 'resource.setAlwaysOnTop':
        return native.invokeMethod<void>('setAlwaysOnTop', call.arguments);
      default:
        throw MissingPluginException(
          'Unsupported resource method: ${call.method}',
        );
    }
  });
  await ResourceWindowService.hostChannel.invokeMethod<Object?>('ready', {
    'windowId': controller.windowId,
    'kind': arguments.kind.name,
  });
  runApp(const ResourceWindowPlaceholder());
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await controller.show();
  });
}

/// Only the task-authorized placeholder; the front-end owns the actual window.
class ResourceWindowPlaceholder extends StatelessWidget {
  const ResourceWindowPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Text(
        AppLocalizations.of(context)!.shortcut_action_open_resource_window,
      ),
    ),
  );
}
