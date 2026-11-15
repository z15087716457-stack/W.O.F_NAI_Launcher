import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/database/dictionary_builder.dart';
import 'package:nai_launcher/core/database/dictionary_data_store.dart';

// Explicit local maintenance. No network, model calls or RAG synchronization.
Future<void> main(List<String> args) async {
  if (args.length != 3 || !{'stage', 'publish'}.contains(args[2])) {
    throw ArgumentError(
      'import.dart <user-data> <work-directory> stage|publish',
    );
  }
  final user = p.absolute(args[0]);
  final work = Directory(p.absolute(args[1]));
  await work.create(recursive: true);
  final store = DictionaryDataStore(
    Directory(p.join(user, 'dictionary_updates')),
  );
  final lock =
      jsonDecode(
            await File(
              'tool/dictionary_updates/source_lock.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  final planFile = File(p.join(work.path, 'plan.json'));
  final plan = args[2] == 'publish'
      ? jsonDecode(await planFile.readAsString()) as Map<String, dynamic>
      : <String, dynamic>{};
  for (final kind in DictionaryKind.values) {
    final seed = await store.resolve(
      kind,
      p.join(
        user,
        'asset_databases',
        kind == DictionaryKind.tags ? 'tag_catalog.db' : 'tag_wiki.db',
      ),
    );
    final seedHash = (await sha256.bind(File(seed).openRead()).first)
        .toString();
    if (args[2] == 'publish') {
      final item = plan[kind.name] as Map<String, dynamic>;
      if (item['seed'] != seed || item['seedHash'] != seedHash) {
        throw StateError('dictionary_changed_since_staging');
      }
      final output = File(item['output'] as String);
      if ((await sha256.bind(output.openRead()).first).toString() !=
          item['outputHash']) {
        throw StateError('staged_dictionary_changed');
      }
      await store.publish(
        kind,
        output,
        Map<String, dynamic>.from(item['metadata'] as Map),
        expectedPath: store.activePath(kind),
      );
      stdout.writeln(
        jsonEncode({
          'kind': kind.name,
          'published': true,
          'record': store.record(kind),
        }),
      );
      continue;
    }
    final source = lock['sources'][kind.name] as Map<String, dynamic>;
    final input = File(source['file'] as String);
    if (await input.length() != source['bytes'] ||
        (await sha256.bind(input.openRead()).first).toString() !=
            source['sha256']) {
      throw StateError('source_integrity');
    }
    final output = File(p.join(work.path, 'next-${kind.name}.db'));
    final port = ReceivePort();
    final listener = port.listen((_) {});
    late final Map<String, int> result;
    try {
      result = await buildDictionaryInBackground({
        'kind': kind.name,
        'seed': seed,
        'input': input.path,
        'output': output.path,
        'cancel': p.join(work.path, 'cancel'),
        'version': (source['sha256'] as String).substring(0, 12),
        'progress': port.sendPort,
      });
    } finally {
      await listener.cancel();
      port.close();
    }
    if (await validateDictionaryInBackground(output.path, kind) !=
        result['count']) {
      throw StateError('staged_dictionary_integrity');
    }
    plan[kind.name] = {
      'seed': seed,
      'seedHash': seedHash,
      'output': output.path,
      'outputHash': (await sha256.bind(output.openRead()).first).toString(),
      'metadata': {
        ...result,
        'mergeVersion': kind == DictionaryKind.wiki ? 2 : 1,
        'date': source['date'],
        'sourceHash': source['sha256'],
        'sourceName': source['name'],
        'sourceUrl': source['upstreamUrl'],
        'upstreamHash': source['upstreamSha256'],
        'method': 'local-verified-snapshot',
        'installedAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    stdout.writeln(jsonEncode({'kind': kind.name, ...result}));
  }
  if (args[2] == 'stage') {
    await planFile.writeAsString(jsonEncode(plan), flush: true);
  }
}
