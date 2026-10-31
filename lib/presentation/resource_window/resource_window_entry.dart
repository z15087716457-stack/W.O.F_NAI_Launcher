import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/resource_window_host.dart';
import '../../core/services/resource_window_protocol.dart';
import '../../core/services/resource_window_service.dart';
import '../../core/utils/localization_extension.dart';
import '../../l10n/app_localizations.dart';
import '../providers/font_provider.dart';
import '../themes/app_theme.dart';
import '../ui/kit/ui_resource_kind.dart';
import '../ui/resource_window/resource_window_page.dart';
import 'resource_window_controller.dart';
import 'resource_gallery_viewer.dart';
import 'resource_gallery_timeline.dart';
import '../widgets/gallery/local_gallery_filter_bar.dart';

/// No ProviderScope, data-directory resolution, Hive/SQLite, migration, logging,
/// Agent, RAG, Krita, tray or media setup. The page is owned by the front-end.
Future<void> runResourceWindow(
  WindowController window,
  ResourceWindowArguments arguments,
) async {
  const native = MethodChannel('com.nailauncher/resource_window_native');
  final localeParts = arguments.locale.replaceAll('-', '_').split('_');
  final locale = Locale(
    localeParts.first,
    localeParts.length > 1 ? localeParts.last : null,
  );
  setCurrentL10nLocale(locale);
  String title(FloatingResourceKind kind) => switch (kind) {
    FloatingResourceKind.gallery => currentL10n.localGallery_title,
    FloatingResourceKind.blocks => currentL10n.blocks_title,
    FloatingResourceKind.vibe => currentL10n.refs_vibeTitle,
    FloatingResourceKind.precise => currentL10n.refs_preciseTitle,
  };
  final controller = ResourceWindowController(
    windowId: window.windowId,
    kind: arguments.kind,
    alwaysOnTop: arguments.alwaysOnTop,
    onKindChanged: (kind) => native.invokeMethod<void>('setTitle', title(kind)),
  );
  await window.setWindowMethodHandler((call) async {
    switch (call.method) {
      case 'resource.close':
        return native.invokeMethod<void>('close');
      case 'resource.focus':
        return native.invokeMethod<void>('focus');
      case 'resource.setAlwaysOnTop':
        return native.invokeMethod<void>('setAlwaysOnTop', call.arguments);
      case 'resources.viewChanged':
        controller.viewChanged(resourceMap(call.arguments));
        return;
      case 'resources.changed':
        controller.changed(resourceMap(call.arguments));
        return;
      case 'resources.disconnected':
        controller.disconnected();
        return;
      default:
        throw MissingPluginException(
          'Unsupported resource method: ${call.method}',
        );
    }
  });
  native.setMethodCallHandler((call) async {
    if (call.method == 'layout') {
      controller.nativeLayout(resourceMap(call.arguments));
    } else if (call.method == 'maximizedChanged') {
      controller.maximized(call.arguments as bool);
    }
  });
  await native.invokeMethod<void>('configure', {
    'title': title(arguments.kind),
    'rect': arguments.rect,
    'alwaysOnTop': arguments.alwaysOnTop,
  });
  controller.maximized(await native.invokeMethod<bool>('isMaximized') ?? false);
  final response = resourceMap(
    await ResourceWindowService.hostChannel.invokeMethod<Object?>('ready', {
      'windowId': window.windowId,
      'kind': arguments.kind.name,
    }),
  );
  if (response['version'] != 1) resourceError('unsupported_version');
  runApp(
    ResourceWindowApp(
      controller: controller,
      arguments: arguments,
      locale: locale,
    ),
  );
  unawaited(controller.initialize());
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(window.show()));
}

class ResourceWindowApp extends StatefulWidget {
  const ResourceWindowApp({
    super.key,
    required this.controller,
    required this.arguments,
    required this.locale,
  });
  final ResourceWindowController controller;
  final ResourceWindowArguments arguments;
  final Locale locale;
  @override
  State<ResourceWindowApp> createState() => _ResourceWindowAppState();
}

class _ResourceWindowAppState extends State<ResourceWindowApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: widget.locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getTheme(
      AppStyle.values.byName(widget.arguments.style),
      widget.arguments.brightness == 'light'
          ? Brightness.light
          : Brightness.dark,
      fontConfig: FontConfig.fromKey(widget.arguments.fontKey),
    ),
    home: ListenableBuilder(
      listenable: widget.controller,
      builder: (_, _) {
        final controller = widget.controller;
        final data = controller.data;
        final criteria = controller.galleryCriteria;
        return ResourceWindowPage(
          data: data,
          actions: controller.actions,
          galleryBuilder: (scroll, cell) => ResourceGalleryTimeline(
            controller: controller,
            scroll: scroll,
            cell: cell,
          ),
          galleryFilters:
              data.kind != FloatingResourceKind.gallery ||
                  controller.galleryTrash
              ? null
              : GalleryFilterBar(
                  key: const Key('rw-gallery-filters'),
                  criteria: criteria,
                  showClearFilters:
                      criteria.filterModels.isNotEmpty ||
                      criteria.dateStart != null ||
                      criteria.dateEnd != null ||
                      data.query.isNotEmpty,
                  groupMode:
                      data.groupId != 'recent' &&
                          const [
                            'modifiedAt',
                            'createdAt',
                          ].contains(data.sortId)
                      ? controller.galleryGroupMode
                      : null,
                  onNaiOnly: (value) =>
                      controller.galleryFilters(naiOnly: value),
                  onModels: (models) =>
                      controller.galleryFilters(models: models),
                  onDateRange: (start, end) => controller.galleryFilters(
                    start: start,
                    end: end,
                    dates: true,
                  ),
                  onRemoveTag: (_) {},
                  onClear: () => controller.galleryFilters(clear: true),
                  onGroupMode: (mode) =>
                      unawaited(controller.preferences(groupMode: mode)),
                ),
          viewer: controller.viewerId == null
              ? null
              : ResourceGalleryViewer(
                  controller: controller,
                  initialId: controller.viewerId!,
                ),
        );
      },
    ),
  );
}
