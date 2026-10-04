import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const bridgeHelp = '''W.O.F NAI Studio local bridge
  studio-bridge.exe status --name Codex
  studio-bridge.exe get --name Codex --out current.json
  studio-bridge.exe set steps=28 --base current.json --name Codex
  studio-bridge.exe set-json changes.json --base current.json --name Codex
  studio-bridge.exe quote [changes.json] --out quote.json --name Codex
  studio-bridge.exe gen --quote quote.json --authorized --name Codex
  studio-bridge.exe cancel REQUEST_ID --name Codex
Options: --timeout SECONDS (default 30, generation 180), --discovery FILE
Writes require the snapshot used to plan the edit. Generation requires an
explicit user instruction and a prior quote; report its price and balance first.
Only one image is generated. status/get/quote never generate or edit a draft.
''';

Future<void> main(List<String> args) async {
  stdout.encoding = utf8;
  stderr.encoding = utf8;
  exitCode = await studioBridgeMain(args);
}

Future<int> studioBridgeMain(
  List<String> args, {
  void Function(String)? output,
  void Function(String)? errorOutput,
}) async {
  final out = output ?? print;
  final err = errorOutput ?? stderr.writeln;
  if (args.isEmpty || args.contains('--help') || args.first == 'help') {
    out(bridgeHelp);
    return 0;
  }
  _Bridge? bridge;
  StreamSubscription<ProcessSignal>? interrupt;
  try {
    final options = <String, String>{};
    final positional = <String>[];
    var authorized = false;
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == '--authorized') {
        authorized = true;
        continue;
      }
      if (a.startsWith('--')) {
        if (!const {
              '--name',
              '--out',
              '--base',
              '--quote',
              '--timeout',
              '--discovery',
            }.contains(a) ||
            i + 1 == args.length) {
          throw const FormatException('Invalid option; use --help.');
        }
        options[a] = args[++i];
      } else {
        positional.add(a);
      }
    }
    if (positional.isEmpty) throw const FormatException('Missing command.');
    final command = positional.first;
    if (!const {
      'status',
      'get',
      'set',
      'set-json',
      'quote',
      'gen',
      'ui-gen',
      'cancel',
    }.contains(command)) {
      throw const FormatException('Unknown command; use --help.');
    }
    final isGenerate = command == 'gen' || command == 'ui-gen';
    if (isGenerate && (!authorized || options['--quote'] == null)) {
      throw const FormatException(
        'Generation requires --authorized and --quote FILE.',
      );
    }
    if ((command == 'set' || command == 'set-json') &&
        options['--base'] == null) {
      throw const FormatException(
        'Write requires --base FILE from the previous get.',
      );
    }
    final seconds = options['--timeout'] == null
        ? (isGenerate ? 180 : 30)
        : int.tryParse(options['--timeout']!) ?? 0;
    if (seconds < 1 || seconds > 600) {
      throw const FormatException('Timeout must be 1..600 seconds.');
    }
    final timeout = Duration(seconds: seconds);
    final name = options['--name'] ?? 'External Agent';
    if (name.trim().isEmpty ||
        name.length > 64 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
      throw const FormatException('Invalid client name.');
    }
    final path = options['--discovery'] ?? _discoveryPath();
    final info =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    final port = info['port'];
    if (port is! int || port < 1 || port > 65535 || info['secret'] is! String) {
      throw const FormatException('Invalid discovery file.');
    }
    bridge = await _Bridge.connect(
      port,
      info['secret'] as String,
      name,
      timeout,
    );
    if (command == 'status') {
      out(
        jsonEncode({
          'type': 'connected',
          'client': name,
          'capabilities': bridge.capabilities,
        }),
      );
      return 0;
    }
    final Map<String, dynamic> response;
    if (command == 'get') {
      response = await bridge.rpc('get_params');
    } else if (command == 'set' || command == 'set-json') {
      final base = await _jsonFile(options['--base']!);
      final draft = base['_draft'];
      if (draft is! Map || draft['field_versions'] is! Map) {
        throw const FormatException(
          'Base file is not a protected Studio snapshot.',
        );
      }
      final patch = command == 'set-json'
          ? await _jsonArgument(_requiredArg(positional))
          : _keyValues(positional.skip(1));
      if (patch.isEmpty || patch.keys.any((k) => k.startsWith('_'))) {
        throw const FormatException('Provide editable fields only.');
      }
      final written = await bridge.rpc(
        'set_params',
        payload: {...patch, '_expected': draft['field_versions']},
      );
      _throwOnError(written);
      final readback = await bridge.rpc('get_params');
      _throwOnError(readback);
      response = {...written, 'readback': readback};
    } else if (command == 'quote') {
      final patch = positional.length > 1
          ? await _jsonArgument(positional[1])
          : <String, dynamic>{};
      response = await bridge.rpc('quote', payload: patch);
    } else if (command == 'cancel') {
      response = await bridge.rpc('cancel', id: _requiredArg(positional));
    } else {
      final quote = await _jsonFile(options['--quote']!);
      if (quote['type'] != 'quote' ||
          quote['payload'] is! Map ||
          quote['field_versions'] is! Map ||
          quote['quote_id'] is! String ||
          quote['billing'] is! Map) {
        throw const FormatException('Invalid quote file.');
      }
      final billing = quote['billing'] as Map;
      if (billing['estimated_anlas'] is! num ||
          (billing['estimated_anlas'] as num) < 0 ||
          billing['balance_anlas'] == null) {
        throw const FormatException(
          'Price or balance is unavailable. Quote again after account state loads.',
        );
      }
      final requestId = _requestId('generate');
      // The request ID is a cancellation handle, never a session credential.
      err(jsonEncode({'request_id': requestId, 'billing': billing}));
      final activeBridge = bridge;
      interrupt = ProcessSignal.sigint.watch().listen((_) {
        activeBridge.send('cancel', const {}, requestId);
      });
      final result = await bridge.rpc(
        'generate',
        payload: {
          ...Map<String, dynamic>.from(quote['payload'] as Map),
          '_expected': quote['field_versions'],
          '_quote_id': quote['quote_id'],
          '_authorized': true,
        },
        id: requestId,
      );
      _throwOnError(result);
      if (result['type'] == 'result' && result['image'] is String) {
        final destination =
            options['--out'] ??
            'bridge-result-${DateTime.now().microsecondsSinceEpoch}.png';
        await File(
          destination,
        ).writeAsBytes(base64Decode(result['image'] as String), flush: true);
        response = {...result, 'local_copy': File(destination).absolute.path}
          ..remove('image');
      } else {
        response = result;
      }
    }
    _throwOnError(response);
    if (!isGenerate && options['--out'] != null) {
      await File(options['--out']!).writeAsString(
        const JsonEncoder.withIndent('  ').convert(response),
        flush: true,
      );
    }
    out(const JsonEncoder.withIndent('  ').convert(response));
    return 0;
  } on _BridgeError catch (e) {
    err(jsonEncode({'type': 'error', 'code': e.code, 'message': e.message}));
    return 2;
  } on TimeoutException {
    err(
      jsonEncode({
        'type': 'error',
        'code': 'timeout',
        'message': 'Studio operation timed out.',
      }),
    );
    return 2;
  } on FormatException catch (e) {
    err(
      jsonEncode({
        'type': 'error',
        'code': 'invalid_request',
        'message': e.message,
      }),
    );
    return 2;
  } on FileSystemException {
    err(
      jsonEncode({
        'type': 'error',
        'code': 'file_unavailable',
        'message':
            'Open Studio, enable local bridge, and check the input/output file paths.',
      }),
    );
    return 2;
  } catch (_) {
    err(
      jsonEncode({
        'type': 'error',
        'code': 'connection_failed',
        'message':
            'Cannot communicate with Studio. Check local bridge and retry.',
      }),
    );
    return 2;
  } finally {
    await interrupt?.cancel();
    await bridge?.close();
  }
}

class _BridgeError implements Exception {
  _BridgeError(this.code, this.message);
  final String code, message;
}

void _throwOnError(Map<String, dynamic> message) {
  if (message['type'] == 'error') {
    throw _BridgeError(
      message['code']?.toString() ?? 'server_error',
      message['message']?.toString() ?? 'Studio rejected this operation.',
    );
  }
}

class _Bridge {
  _Bridge(this.socket, this.events, this.timeout, this.capabilities);
  final WebSocket socket;
  final StreamIterator<dynamic> events;
  final Duration timeout;
  final List<dynamic> capabilities;
  static Future<_Bridge> connect(
    int port,
    String secret,
    String name,
    Duration timeout,
  ) async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:$port/krita',
    ).timeout(timeout);
    final events = StreamIterator<dynamic>(socket);
    try {
      socket.add(
        jsonEncode({
          'type': 'ping',
          'version': 1,
          'secret': secret,
          'client': {'kind': 'agent', 'name': name},
        }),
      );
      if (!await events.moveNext().timeout(timeout)) throw StateError('Closed');
      final pong = jsonDecode(events.current as String) as Map<String, dynamic>;
      _throwOnError(pong);
      final capabilities = pong['capabilities'];
      if (pong['type'] != 'pong' ||
          capabilities is! List ||
          !capabilities.contains('guarded_set') ||
          !capabilities.contains('multi_client')) {
        throw _BridgeError(
          'incompatible_bridge',
          'Update Studio to a version with protected Agent bridge.',
        );
      }
      return _Bridge(socket, events, timeout, capabilities);
    } catch (_) {
      await socket.close();
      await events.cancel();
      rethrow;
    }
  }

  void send(String type, Map<String, dynamic> payload, String id) =>
      socket.add(jsonEncode({'type': type, 'id': id, 'payload': payload}));
  Future<Map<String, dynamic>> rpc(
    String type, {
    Map<String, dynamic> payload = const {},
    String? id,
  }) async {
    final requestId = id ?? _requestId(type);
    send(type, payload, requestId);
    return (() async {
      while (await events.moveNext()) {
        final response =
            jsonDecode(events.current as String) as Map<String, dynamic>;
        if (response['id'] != requestId || response['type'] == 'progress') {
          continue;
        }
        return response;
      }
      throw StateError('Connection closed');
    })().timeout(timeout);
  }

  Future<void> close() async {
    await socket.close();
    await events.cancel();
  }
}

String _discoveryPath() {
  final root = Platform.environment['APPDATA'];
  if (root != null) return '$root/nai-launcher/krita-bridge.json';
  return '${Platform.environment['HOME'] ?? Directory.current.path}/.nai-launcher/krita-bridge.json';
}

String _requestId(String type) =>
    '$type-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
String _requiredArg(List<String> args) {
  if (args.length < 2) throw const FormatException('Missing command argument.');
  return args[1];
}

Future<Map<String, dynamic>> _jsonFile(String path) async =>
    _jsonMap(await File(path).readAsString());
Future<Map<String, dynamic>> _jsonArgument(String arg) async =>
    arg.trimLeft().startsWith('{') ? _jsonMap(arg) : _jsonFile(arg);
Map<String, dynamic> _jsonMap(String text) {
  final object = jsonDecode(text);
  if (object is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object.');
  }
  return object;
}

Map<String, dynamic> _keyValues(Iterable<String> args) {
  final patch = <String, dynamic>{};
  for (final a in args) {
    final separator = a.indexOf('=');
    if (separator <= 0) {
      throw const FormatException('Use field=value for each edit.');
    }
    final key = a.substring(0, separator);
    if (patch.containsKey(key)) {
      throw const FormatException('Duplicate edit field.');
    }
    patch[key] = _value(a.substring(separator + 1));
  }
  if (patch.isEmpty) {
    throw const FormatException('Provide at least one edit field.');
  }
  return patch;
}

dynamic _value(String text) {
  try {
    return jsonDecode(text);
  } catch (_) {
    return text;
  }
}
