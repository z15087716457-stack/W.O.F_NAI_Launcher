import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/krita_bridge_server.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';

import '../../../helpers/app_logger_test_isolation.dart';

class _ControlledServer extends KritaBridgeServer {
  _ControlledServer(
    Directory root,
    String secret, {
    this.holdStart = false,
    this.holdStop = false,
  }) : super(discoveryDirectory: root, secretGenerator: () => secret);
  final bool holdStart;
  final bool holdStop;
  final startGate = Completer<void>();
  final started = Completer<void>();
  final stopGate = Completer<void>();
  final stopping = Completer<void>();
  bool failStart = false;
  bool disposed = false;
  @override
  Future<void> start({int preferredPort = 0}) async {
    started.complete();
    if (holdStart) await startGate.future;
    if (failStart) throw StateError('injected old startup failure');
    await super.start(preferredPort: preferredPort);
  }

  @override
  Future<void> dispose() async {
    if (!stopping.isCompleted) stopping.complete();
    if (holdStop) await stopGate.future;
    if (disposed) return;
    disposed = true;
    await super.dispose();
  }

  void release() {
    if (!startGate.isCompleted) startGate.complete();
    if (!stopGate.isCompleted) stopGate.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory root;
  late KritaBridgeNotifier notifier;
  late List<_ControlledServer> servers;
  late List<bool> writes;
  late List<Future<void>> tasks;
  var notifierDisposed = false;
  var factoryCalls = 0;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('bridge_lifecycle_');
    servers = [];
    writes = [];
    tasks = [];
    factoryCalls = 0;
    notifierDisposed = false;
  });
  void create(List<_ControlledServer> sequence) {
    servers.addAll(sequence);
    notifier = KritaBridgeNotifier(
      serverFactory: () => sequence[factoryCalls++],
      persistEnabled: writes.add,
    );
  }

  Future<void> track(Future<void> task) {
    tasks.add(task);
    return task;
  }

  tearDown(() async {
    for (final server in servers) {
      server.release();
    }
    await Future.wait(tasks);
    if (!notifierDisposed) {
      await notifier.close();
      notifier.dispose();
    }
    for (final server in servers) {
      await server.dispose();
    }
    await root.delete(recursive: true);
  });
  for (final failure in [false, true]) {
    test(
      'startup restore cannot reenable a disabled bridge, failure=$failure',
      () async {
        final old = _ControlledServer(root, 'old-fixture', holdStart: true)
          ..failStart = failure;
        create([old]);
        final enabling = track(notifier.enable(persist: false));
        await old.started.future;
        expect(notifier.state.status, KritaBridgeStatus.starting);
        await notifier.disable();
        expect(notifier.state.enabled, isFalse);
        old.release();
        await enabling;
        expect(notifier.state.status, KritaBridgeStatus.disabled);
        expect(notifier.server, isNull);
        expect(old.disposed, isTrue);
        expect(old.port, isNull);
        expect(await old.discoveryFile.exists(), isFalse);
        expect(writes, [false]);
      },
    );
  }
  for (final failure in [false, true]) {
    test(
      'new start owns the discovery file after an older canceled start, failure=$failure',
      () async {
        final old = _ControlledServer(root, 'old-fixture', holdStart: true)
          ..failStart = failure;
        final current = _ControlledServer(root, 'new-fixture');
        create([old, current]);
        final first = track(notifier.enable(persist: false));
        await old.started.future;
        await notifier.disable();
        final second = track(notifier.enable());
        await Future<void>.delayed(Duration.zero);
        expect(factoryCalls, 1);
        old.release();
        await Future.wait([first, second]);
        expect(notifier.state.status, KritaBridgeStatus.listening);
        expect(notifier.server, same(current));
        expect(old.disposed, isTrue);
        final discovery =
            jsonDecode(await current.discoveryFile.readAsString()) as Map;
        expect(discovery['secret'], 'new-fixture');
        expect(discovery['port'], current.port);
        expect(writes, [false, true]);
      },
    );
  }
  test(
    'new start waits for shutdown and cannot be cleared by its completion',
    () async {
      final old = _ControlledServer(root, 'old-fixture', holdStop: true);
      final current = _ControlledServer(root, 'new-fixture');
      create([old, current]);
      await notifier.enable();
      final closing = track(notifier.disable());
      await old.stopping.future;
      final opening = track(notifier.enable());
      await Future<void>.delayed(Duration.zero);
      expect(factoryCalls, 1);
      old.release();
      await Future.wait([closing, opening]);
      expect(notifier.server, same(current));
      expect(notifier.state.enabled, isTrue);
      expect(
        (jsonDecode(await current.discoveryFile.readAsString())
            as Map)['secret'],
        'new-fixture',
      );
    },
  );
  test('explicit off during session regeneration prevents reopening', () async {
    final old = _ControlledServer(root, 'old-fixture', holdStop: true);
    final replacement = _ControlledServer(root, 'new-fixture');
    create([old, replacement]);
    await notifier.enable();
    final regeneration = track(notifier.regenerateSession());
    await old.stopping.future;
    await notifier.disable();
    old.release();
    await regeneration;
    expect(factoryCalls, 1);
    expect(notifier.state.enabled, isFalse);
    expect(notifier.server, isNull);
  });
  test(
    'dispose during startup releases the late server without publishing state',
    () async {
      final old = _ControlledServer(root, 'old-fixture', holdStart: true);
      create([old]);
      final enabling = track(notifier.enable(persist: false));
      await old.started.future;
      notifier.dispose();
      notifierDisposed = true;
      old.release();
      await enabling;
      expect(old.disposed, isTrue);
      expect(old.port, isNull);
      expect(await old.discoveryFile.exists(), isFalse);
    },
  );
}
