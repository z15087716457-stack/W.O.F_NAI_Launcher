import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import '../../data/models/resources/floating_window_data.dart';
import 'resource_window_host.dart';
import 'resource_window_protocol.dart';

/// Process-wide primary-engine registry. Child engines only use hostChannel.
class ResourceWindowService {
  static final instance = ResourceWindowService();
  static const _native = MethodChannel(
    'com.nailauncher/resource_window_native',
  );
  static const hostChannel = WindowMethodChannel(
    'com.nailauncher/resources/host/v1',
    mode: ChannelMode.unidirectional,
  );
  final host = ResourceWindowHost();
  final _windows =
      <String, ({WindowController controller, FloatingResourceKind kind})>{};
  final _opening = <FloatingResourceKind, Future<WindowController>>{};
  final _creating = <Future<WindowController>>{};
  final _ready = <String>{};
  final _readyWaiters = <String, Completer<void>>{};
  bool _closing = false;
  StreamSubscription<void>? _subscription;

  void _forget(String id) {
    _windows.remove(id);
    _ready.remove(id);
    host.closed(id);
    onClosed?.call(id);
    _readyWaiters
        .remove(id)
        ?.completeError(PlatformException(code: 'cancelled'));
  }

  Future<ResourceWindowArguments> Function(FloatingResourceKind)? argumentsFor;
  Future<void> Function()? onAllClosed;
  void Function(String, FloatingResourceKind)? onKind;
  void Function(String)? onClosed;

  Map<String, FloatingResourceKind> get windows => {
    for (final entry in _windows.entries) entry.key: entry.value.kind,
  };

  Future<void> initialize() async {
    await hostChannel.setMethodCallHandler(handle);
    _subscription ??= onWindowsChanged.listen((_) => unawaited(_reconcile()));
  }

  Future<void> _reconcile() async {
    final active = (await WindowController.getAll())
        .map((w) => w.windowId)
        .toSet();
    var removed = false;
    for (final id in _windows.keys.toList()) {
      if (!active.contains(id)) {
        _forget(id);
        removed = true;
      }
    }
    if (removed && _windows.isEmpty && _creating.isEmpty) {
      await onAllClosed?.call();
    }
  }

  Future<Object?> handle(MethodCall call) async {
    final args = resourceMap(call.arguments);
    if (args['version'] != null && args['version'] != 1) {
      resourceError('unsupported_version');
    }
    if (call.method == 'ready') {
      final response = await host.handle(call);
      final id = resourceString(args, 'windowId');
      _ready.add(id);
      _readyWaiters.remove(id)?.complete();
      return response;
    }
    if (call.method == 'resources.closed') {
      final id = resourceString(resourceMap(call.arguments), 'windowId');
      _forget(id);
      if (_windows.isEmpty) await onAllClosed?.call();
      return null;
    }
    if (call.method == 'resources.newWindow') {
      final kind = resourceKind(resourceMap(call.arguments));
      await openKind(kind, newWindow: true);
      return null;
    }
    if (call.method == 'resources.kind') {
      final args = resourceMap(call.arguments);
      final id = resourceString(args, 'windowId');
      final window = _windows[id];
      if (window == null) resourceError('not_found');
      _windows[id] = (controller: window.controller, kind: resourceKind(args));
      onKind?.call(id, resourceKind(args));
      return null;
    }
    return host.handle(call);
  }

  Future<WindowController> openKind(
    FloatingResourceKind kind, {
    bool newWindow = false,
  }) async {
    final factory = argumentsFor;
    if (factory == null) resourceError('not_ready');
    return open(await factory(kind), newWindow: newWindow);
  }

  Future<WindowController> open(
    ResourceWindowArguments arguments, {
    bool newWindow = false,
  }) async {
    if (_closing) resourceError('cancelled');
    if (!newWindow) {
      final existing = _windows.values
          .where((w) => w.kind == arguments.kind)
          .firstOrNull;
      if (existing != null) {
        if (!_ready.contains(existing.controller.windowId)) {
          await (_readyWaiters.putIfAbsent(
            existing.controller.windowId,
            Completer<void>.new,
          )).future;
        }
        await existing.controller.invokeMethod<void>('resource.focus');
        return existing.controller;
      }
      final opening = _opening[arguments.kind];
      if (opening != null) return opening;
    }
    final pending = _create(arguments);
    _creating.add(pending);
    if (!newWindow) _opening[arguments.kind] = pending;
    try {
      return await pending;
    } finally {
      _creating.remove(pending);
      if (identical(_opening[arguments.kind], pending)) {
        _opening.remove(arguments.kind);
      }
    }
  }

  Future<WindowController> _create(ResourceWindowArguments arguments) async {
    final window = await WindowController.create(
      WindowConfiguration(hiddenAtLaunch: true, arguments: arguments.encode()),
    );
    _windows[window.windowId] = (controller: window, kind: arguments.kind);
    onKind?.call(window.windowId, arguments.kind);
    return window;
  }

  Future<void> viewChanged(
    FloatingResourceKind kind,
    String layout, {
    String? groupMode,
  }) async {
    for (final window in _windows.values.where((w) => w.kind == kind)) {
      try {
        await window.controller.invokeMethod<void>('resources.viewChanged', {
          'kind': kind.name,
          'layout': layout,
          if (groupMode != null) 'groupMode': groupMode,
        });
      } on WindowChannelException catch (error) {
        if (!const [
          'CHANNEL_NOT_FOUND',
          'CHANNEL_UNREGISTERED',
        ].contains(error.code)) {
          rethrow;
        }
      }
    }
  }

  Future<void> changed(FloatingResourceKind kind) async {
    host.changed(kind);
    await Future.wait([
      for (final window in _windows.values) _notify(window.controller, kind),
    ]);
  }

  Future<void> _notify(
    WindowController window,
    FloatingResourceKind kind,
  ) async {
    try {
      await window.invokeMethod<void>('resources.changed', {
        'kind': kind.name,
        'revision': host.revisions[kind],
      });
    } on WindowChannelException catch (error) {
      // A destroyed engine has no handler. Its registry is removed by the
      // native windows-changed event; do not turn library failures into success.
      if (!const [
        'CHANNEL_NOT_FOUND',
        'CHANNEL_UNREGISTERED',
      ].contains(error.code)) {
        rethrow;
      }
    }
  }

  Future<void> closeAll() async {
    _closing = true;
    try {
      // Creating an HWND finishes before the child ready handshake. Wait for
      // in-flight creates, including explicit new windows, then close natively.
      await Future.wait([
        for (final pending in _creating.toList())
          pending.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
      ]);
      await _native.invokeMethod<void>('closeAll');
      for (final id in _windows.keys.toList()) {
        _forget(id);
      }
      await onAllClosed?.call();
    } finally {
      _closing = false;
    }
  }

  Future<void> close(WindowController window) =>
      window.invokeMethod<void>('resource.close');
  Future<void> setAlwaysOnTop(WindowController window, bool enabled) =>
      window.invokeMethod<void>('resource.setAlwaysOnTop', enabled);
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await hostChannel.setMethodCallHandler(null);
  }
}
