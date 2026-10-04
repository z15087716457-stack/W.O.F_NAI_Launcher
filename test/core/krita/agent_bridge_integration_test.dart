import 'package:nai_launcher/core/krita/krita_bridge_models.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/krita/krita_bridge_server.dart';
import 'package:nai_launcher/core/krita/bridge_session.dart';
import 'package:nai_launcher/core/models/image_generation_artifact.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_service.dart';
import '../../../tool/studio_bridge.dart' as cli;

class Peer {
  Peer(this.socket, this.events);
  final WebSocket socket;
  final StreamIterator<dynamic> events;
  static int next = 0;
  Future<Map<String, dynamic>> rpc(
    String type, {
    Map<String, dynamic> payload = const {},
    String? id,
  }) async {
    final key = id ?? 'test-${++next}';
    socket.add(jsonEncode({'type': type, 'id': key, 'payload': payload}));
    while (await events.moveNext().timeout(const Duration(seconds: 3))) {
      final value =
          jsonDecode(events.current as String) as Map<String, dynamic>;
      if (value['id'] == key && value['type'] != 'progress') return value;
    }
    throw StateError('Peer closed');
  }

  Future<void> close() async {
    await socket.close();
    await events.cancel();
  }
}

class Fixture {
  late Directory dir;
  late KritaBridgeNotifier notifier;
  late KritaBridgeService service;
  ImageParams params = const ImageParams(prompt: 'original', steps: 28);
  final peers = <Peer>[];
  final backups = <String>[];
  final generated = <ImageParams>[];
  int cancelled = 0;
  bool uiBusy = false, alive = true, holdImage = false;
  String account = 'fake-account';
  String preset = '';
  DateTime now = DateTime.utc(2026, 10, 4);
  Completer<void>? backupGate;
  final imageEntered = Completer<void>();
  final imageGate = Completer<ImageGenerationArtifact>();
  final image = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aJZkAAAAASUVORK5CYII=',
    ),
  );
  BridgeDraftSnapshot draft() => BridgeDraftSnapshot(
    fields: {
      'prompt': params.prompt,
      'steps': params.steps,
      'seed': params.seed,
      'characters': const [],
    },
  );
  Future<void> start() async {
    dir = await Directory.systemTemp.createTemp('agent-bridge-offline-');
    notifier = KritaBridgeNotifier(
      serverFactory: () => KritaBridgeServer(
        discoveryDirectory: dir,
        secretGenerator: () => 'isolated-secret',
      ),
      serviceFactory: (server) => service = KritaBridgeService(
        readBaseParams: () => params,
        acknowledgeDraft: server.acknowledgeDraft,
        prepareParams: (p, _) => p.copyWith(prompt: p.prompt + preset),
        send: server.send,
        isUiGenerating: () => uiBusy,
        isAgentRequest: () => server.currentClient?.isAgent ?? false,
        requesterName: () => server.currentClient?.name ?? '',
        readAccountIdentity: () => account,
        isRequestAlive: () =>
            alive &&
            server.session.clients.any((c) => c.id == server.currentClient?.id),
        readDraft: draft,
        readBilling: (p) => {
          'estimated_anlas': p.steps,
          'balance_anlas': 100,
          'samples': 1,
        },
        clock: () => now,
        backupDraft: (d) async {
          final path = await backupBridgeDraft(dir, d);
          backups.add(path);
          await backupGate?.future;
          return path;
        },
        writeParams: (p) {
          params = params.copyWith(
            prompt: p['prompt'] as String? ?? params.prompt,
            steps: p['steps'] as int? ?? params.steps,
            seed: p['seed'] as int? ?? params.seed,
          );
          return p.keys.toList();
        },
        generateStream: (request) {
          generated.add(request.params);
          if (!imageEntered.isCompleted) imageEntered.complete();
          return holdImage
              ? Stream.fromFuture(
                  imageGate.future.then(
                    (a) => ImageStreamChunk.complete(a.displayImageBytes),
                  ),
                )
              : Stream.value(ImageStreamChunk.complete(image));
        },
        generateFallback: (_) async => [
          ImageGenerationArtifact(displayImageBytes: image),
        ],
        registerExternalImage: (_, {required params, addToDisplay}) async =>
            'fake.png',
        cancelGeneration: () {
          cancelled++;
          if (!imageGate.isCompleted) {
            imageGate.complete(
              ImageGenerationArtifact(displayImageBytes: image),
            );
          }
        },
      ),
    );
    await notifier.enable(persist: false);
  }

  Future<Peer> connect(String name, {bool krita = false}) async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:${notifier.state.port}/krita',
    );
    final peer = Peer(socket, StreamIterator<dynamic>(socket));
    peers.add(peer);
    socket.add(
      jsonEncode({
        'type': 'ping',
        'version': 1,
        'secret': 'isolated-secret',
        'client': {'kind': krita ? 'krita' : 'agent', 'name': name},
      }),
    );
    expect(await peer.events.moveNext(), isTrue);
    expect(jsonDecode(peer.events.current as String)['type'], 'pong');
    return peer;
  }

  Future<void> close() async {
    if (backupGate?.isCompleted == false) backupGate!.complete();
    if (!imageGate.isCompleted) {
      imageGate.complete(ImageGenerationArtifact(displayImageBytes: image));
    }
    for (final peer in peers) {
      await peer.close();
    }
    await notifier.close();
    await dir.delete(recursive: true);
  }
}

void main() {
  test('文档变化、模型采样器联动与非法角色保护', () {
    final old = BridgeDraftSnapshot(
      fields: {
        'prompt': 'same',
        'model': 'old',
        'sampler': 'a',
        'characters': [],
      },
      documents: {
        'prompt': {'text': 'block-a'},
      },
    );
    final edited = BridgeDraftSnapshot(
      fields: old.fields,
      documents: {
        'prompt': {'text': 'block-b'},
      },
    );
    expect(edited.matches({'prompt': 'new'}, old.fieldVersions), isFalse);
    final sampler = BridgeDraftSnapshot(
      fields: {...old.fields, 'sampler': 'b'},
      documents: old.documents,
    );
    expect(sampler.matches({'model': 'new'}, old.fieldVersions), isFalse);
    for (final characters in [
      [
        {'id': 'same', 'prompt': 'a'},
        {'id': 'same', 'prompt': 'b'},
      ],
      [
        {'prompt': 'a', 'x': double.nan, 'y': 0.5},
      ],
      [
        {'prompt': 'a', 'x': 1.1, 'y': 0.5},
      ],
      [
        {'prompt': 'a', 'name_is_custom': 'yes'},
      ],
    ]) {
      expect(
        () => validateBridgePatch({'characters': characters}),
        throwsFormatException,
      );
    }
    final overlaid = applyKritaParamsOverlay(const ImageParams(), {
      'characters': [
        {'prompt': 'enabled'},
        {'prompt': 'disabled', 'enabled': false},
      ],
    });
    expect(overlaid.characters.map((c) => c.prompt), ['enabled']);
  });
  late Fixture f;
  setUp(() async {
    f = Fixture();
    await f.start();
  });
  tearDown(() async => f.close());

  test('Agent读写和报价确认精确快照；正常断连保留完成，错误不确认', () async {
    final peer = await f.connect('Codex');
    final read = await peer.rpc('get_params');
    await Future<void>.delayed(Duration.zero);
    expect(
      f.notifier.state.session.latestAgentOutcome!.confirmedDraftVersion,
      f.draft().acknowledgementVersion,
    );
    await peer.rpc(
      'set_params',
      payload: {'steps': 29, '_expected': read['_draft']['field_versions']},
    );
    await Future<void>.delayed(Duration.zero);
    expect(f.params.steps, 29);
    expect(
      f.notifier.state.session.latestAgentOutcome!.confirmedDraftVersion,
      f.draft().acknowledgementVersion,
    );
    await peer.rpc('quote');
    await Future<void>.delayed(Duration.zero);
    expect(f.notifier.state.session.latestAgentOutcome!.operation, 'quote');
    expect(
      f.notifier.state.session.latestAgentOutcome!.confirmedDraftVersion,
      f.draft().acknowledgementVersion,
    );
    await peer.rpc(
      'set_params',
      payload: {'steps': 30, '_expected': read['_draft']['field_versions']},
    );
    await Future<void>.delayed(Duration.zero);
    final failed = f.notifier.state.session.latestAgentOutcome!;
    expect(failed.status, BridgeActivityStatus.failed);
    expect(failed.confirmedDraftVersion, isNull);
    await peer.close();
    await Future<void>.delayed(Duration.zero);
    expect(f.notifier.state.session.latestAgentOutcome, same(failed));
  });

  test(
    'Krita and multiple Agents coexist; equal IDs get private replies',
    () async {
      final k = await f.connect('Krita', krita: true);
      final a = await f.connect('Codex');
      final b = await f.connect('Other Agent');
      final results = await Future.wait([
        k.rpc('get_params', id: 'same'),
        a.rpc('get_params', id: 'same'),
        b.rpc('get_params', id: 'same'),
      ]);
      expect(results.every((r) => r['type'] == 'params'), isTrue);
      expect(results[0].containsKey('_draft'), isFalse);
      expect(results[1]['_draft'], isA<Map>());
      expect(f.notifier.state.session.clients, hasLength(3));
      expect(f.notifier.state.connectedClientLabel, 'Krita');
      await a.close();
      expect((await k.rpc('get_params'))['type'], 'params');
      expect(f.cancelled, 0);
    },
  );
  test('image pushes never go to an Agent-only connection', () async {
    await f.connect('Codex');
    expect(f.notifier.sendImageToKrita(f.image, name: 'sample.png'), isFalse);
    expect(f.notifier.state.status, KritaBridgeStatus.listening);
  });
  test('guarded write creates a backup and touches only its patch', () async {
    final a = await f.connect('Codex');
    final before = await a.rpc('get_params');
    final result = await a.rpc(
      'set_params',
      payload: {
        'prompt': 'changed',
        '_expected': before['_draft']['field_versions'],
      },
    );
    expect(result['type'], 'params_set');
    expect(f.params.prompt, 'changed');
    expect(f.params.steps, 28);
    expect(f.backups, hasLength(1));
    final backup = jsonDecode(await File(f.backups.single).readAsString());
    expect(backup['fields']['prompt'], 'original');
    expect(result['backup_path'], f.backups.single);
  });
  test(
    'stale target is rejected, unrelated user edits are preserved',
    () async {
      final a = await f.connect('Codex');
      final before = await a.rpc('get_params');
      f.params = f.params.copyWith(steps: 40);
      final ok = await a.rpc(
        'set_params',
        payload: {
          'prompt': 'changed',
          '_expected': before['_draft']['field_versions'],
        },
      );
      expect(ok['type'], 'params_set');
      expect(f.params.steps, 40);
      final rejected = await a.rpc(
        'set_params',
        payload: {'steps': 32, '_expected': before['_draft']['field_versions']},
      );
      expect(rejected['code'], 'conflict');
      expect(f.params.steps, 40);
    },
  );
  test('edit during backup aborts the entire patch', () async {
    final a = await f.connect('Codex');
    final before = await a.rpc('get_params');
    f.backupGate = Completer<void>();
    final writing = a.rpc(
      'set_params',
      payload: {
        'prompt': 'old agent edit',
        'steps': 32,
        '_expected': before['_draft']['field_versions'],
      },
    );
    while (f.backups.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    f.params = f.params.copyWith(prompt: 'user typed now');
    f.backupGate!.complete();
    expect((await writing)['code'], 'conflict');
    expect(f.params.prompt, 'user typed now');
    expect(f.params.steps, 28);
  });
  test('disconnected Agent cannot finish a pending write', () async {
    final a = await f.connect('Codex');
    final before = await a.rpc('get_params');
    f.backupGate = Completer<void>();
    a.socket.add(
      jsonEncode({
        'type': 'set_params',
        'id': 'pending',
        'payload': {
          'prompt': 'late',
          '_expected': before['_draft']['field_versions'],
        },
      }),
    );
    while (f.backups.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await a.close();
    f.alive = false;
    f.backupGate!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(f.params.prompt, 'original');
  });
  test('invalid later field cannot partially update a prompt', () async {
    final a = await f.connect('Codex');
    final before = await a.rpc('get_params');
    final r = await a.rpc(
      'set_params',
      payload: {
        'prompt': 'partial',
        'quality_preset': 'invalid',
        '_expected': before['_draft']['field_versions'],
      },
    );
    expect(r['code'], 'invalid_request');
    expect(f.params.prompt, 'original');
    expect(f.backups, isEmpty);
  });
  test('write requires a base snapshot and respects UI generation', () async {
    final a = await f.connect('Codex');
    expect(
      (await a.rpc('set_params', payload: {'steps': 32}))['code'],
      'invalid_request',
    );
    f.uiBusy = true;
    expect(
      (await a.rpc(
        'set_params',
        payload: {'steps': 32, '_expected': f.draft().fieldVersions},
      ))['code'],
      'busy',
    );
    expect(f.params.steps, 28);
  });
  test(
    'quote is offline; authorization and quote are required to generate',
    () async {
      final a = await f.connect('Codex');
      final q = await a.rpc('quote');
      expect(q['billing']['estimated_anlas'], 28);
      expect(f.generated, isEmpty);
      expect((await a.rpc('generate'))['code'], 'invalid_request');
      expect(
        (await a.rpc('generate', payload: {'_authorized': true}))['code'],
        'conflict',
      );
      expect(f.generated, isEmpty);
    },
  );
  test(
    'generation uses the frozen quote; caller cannot alter its price',
    () async {
      final a = await f.connect('Codex');
      final q = await a.rpc('quote', payload: {'steps': 32});
      final r = await a.rpc(
        'generate',
        payload: {
          '_authorized': true,
          '_quote_id': q['quote_id'],
          'steps': 100,
        },
      );
      expect(r['type'], 'result');
      expect(f.generated.single.steps, 32);
      expect(f.params.steps, 28);
      expect(
        (await a.rpc(
          'generate',
          payload: {'_authorized': true, '_quote_id': q['quote_id']},
        ))['code'],
        'conflict',
      );
    },
  );
  test(
    'quote rejects changed effective presets while raw draft is unchanged',
    () async {
      final a = await f.connect('Codex');
      final q = await a.rpc('quote');
      f.preset = ', changed custom quality';
      final result = await a.rpc(
        'generate',
        payload: {'_authorized': true, '_quote_id': q['quote_id']},
      );
      expect(result['code'], 'conflict');
      expect(f.generated, isEmpty);
    },
  );
  for (final change in ['draft', 'account', 'expiry', 'client']) {
    test('quote rejects changed $change', () async {
      final a = await f.connect('Codex');
      final q = await a.rpc('quote');
      if (change == 'draft') {
        f.params = f.params.copyWith(prompt: 'user change');
      }
      if (change == 'account') f.account = 'other-account';
      if (change == 'expiry') f.now = f.now.add(const Duration(minutes: 6));
      final sender = change == 'client' ? await f.connect('Other Agent') : a;
      expect(
        (await sender.rpc(
          'generate',
          payload: {'_authorized': true, '_quote_id': q['quote_id']},
        ))['code'],
        'conflict',
      );
      expect(f.generated, isEmpty);
    });
  }
  test(
    'busy writes are rejected; another Agent disconnect does not cancel owner',
    () async {
      final a = await f.connect('Codex');
      final b = await f.connect('Other Agent');
      final k = await f.connect('Krita', krita: true);
      f.holdImage = true;
      final q = await a.rpc('quote');
      final generating = a.rpc(
        'generate',
        payload: {'_authorized': true, '_quote_id': q['quote_id']},
      );
      await f.imageEntered.future;
      expect(
        (await b.rpc(
          'set_params',
          payload: {'steps': 32, '_expected': f.draft().fieldVersions},
        ))['code'],
        'busy',
      );
      expect((await b.rpc('get_params'))['type'], 'params');
      for (var i = 0; i < 12; i++) {
        await b.rpc('get_params');
      }
      expect(f.notifier.state.session.activities, hasLength(8));
      expect(f.notifier.state.session.agentActivity?.operation, 'generate');
      await b.close();
      await k.close();
      expect(f.cancelled, 0);
      expect(f.service.isBridgeGenerating, isTrue);
      f.notifier.cancelActiveRequest();
      expect((await generating)['type'], 'cancelled');
      expect(f.cancelled, 1);
    },
  );
  test(
    'separate cancellation command checks Agent name and request ID',
    () async {
      final a = await f.connect('Codex');
      f.holdImage = true;
      final q = await a.rpc('quote');
      final generating = a.rpc(
        'generate',
        id: 'generation-handle',
        payload: {'_authorized': true, '_quote_id': q['quote_id']},
      );
      await f.imageEntered.future;
      final b = await f.connect('Other');
      expect((await b.rpc('cancel', id: 'generation-handle'))['code'], 'busy');
      final same = await f.connect('Codex');
      expect(
        (await same.rpc('cancel', id: 'generation-handle'))['type'],
        'cancelled',
      );
      expect((await generating)['type'], 'cancelled');
    },
  );
  test(
    'activity records never include prompts, patches, images or secrets',
    () async {
      final a = await f.connect('Codex');
      await a.rpc('get_params');
      final activity = f.notifier.state.session.activities.single;
      expect(activity.operation, 'get_params');
      expect(activity.status, BridgeActivityStatus.completed);
      expect(activity.client.name, 'Codex');
      expect(activity.toString(), isNot(contains('original')));
    },
  );
  test(
    'source CLI gets, protects writes, reads back and closes without Python',
    () async {
      final out = <String>[], errors = <String>[];
      final base = '${f.dir.path}/current.json';
      Future<int> run(List<String> args) => cli.studioBridgeMain(
        [
          ...args,
          '--name',
          'Codex',
          '--discovery',
          f.notifier.state.discoveryFilePath!,
        ],
        output: out.add,
        errorOutput: errors.add,
      );
      expect(await run(['get', '--out', base]), 0);
      expect(await run(['set', 'steps=32', '--base', base]), 0);
      expect(f.params.steps, 32);
      expect(jsonDecode(out.last)['readback']['steps'], 32);
      f.params = f.params.copyWith(steps: 40);
      expect(await run(['set', 'steps=31', '--base', base]), 2);
      expect(errors.last, contains('conflict'));
      expect(f.params.steps, 40);
      expect(out.join(), isNot(contains('isolated-secret')));
      expect(await run(['gen']), 2);
      expect(f.generated, isEmpty);
    },
  );
  if (Platform.environment['BRIDGE_CLIENT_EXE'] != null) {
    test('compiled Windows client performs an offline round trip', () async {
      f.params = f.params.copyWith(prompt: '中文提示词 · 模块复用');
      final executable = Platform.environment['BRIDGE_CLIENT_EXE']!;
      final base = '${f.dir.path}/exe-current.json';
      final result = await Process.run(
        executable,
        [
          'get',
          '--out',
          base,
          '--name',
          'Exe Agent',
          '--discovery',
          f.notifier.state.discoveryFilePath!,
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(
        jsonDecode(result.stdout as String)['_draft']['fields']['prompt'],
        '中文提示词 · 模块复用',
      );
      final written = await Process.run(executable, [
        'set',
        'steps=32',
        '--base',
        base,
        '--name',
        'Exe Agent',
        '--discovery',
        f.notifier.state.discoveryFilePath!,
      ]);
      expect(written.exitCode, 0, reason: written.stderr.toString());
      expect(f.params.steps, 32);
      expect((await Process.run(executable, ['gen'])).exitCode, isNot(0));
      expect(f.generated, isEmpty);
    });
  }
}
