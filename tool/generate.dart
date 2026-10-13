import 'dart:convert';
import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart' as runner;
import 'package:build_runner_core/build_runner_core.dart';
import 'package:freezed/builder.dart' as freezed;
import 'package:hive_generator/hive_generator.dart' as hive;
import 'package:json_serializable/builder.dart' as json;
import 'package:path/path.dart' as p;
import 'package:riverpod_generator/builder.dart' as riverpod;
import 'package:source_gen/builder.dart' as source;

import 'codegen_scope.dart';

Future<void> main(List<String> args) async {
  final config =
      jsonDecode(await File('.devin/codegen.json').readAsString())
          as Map<String, dynamic>;
  final inputs = await discoverInputs(
    List<String>.from(config['sourceRoots'] as List),
    List<String>.from(config['excludedPrefixes'] as List),
  );
  final scope = InputSet(include: inputs);
  final status = await Process.run('git', ['status', '--porcelain', '-z']);
  if (status.exitCode != 0) {
    throw StateError('Cannot inspect generated-file state');
  }
  final protected = <String, List<int>>{};
  final backup = Directory(
    '.dart_tool/codegen-backup/${DateTime.now().microsecondsSinceEpoch}',
  );
  for (final entry in (status.stdout as String).split('\u0000')) {
    if (entry.length < 4) continue;
    final path = entry.substring(3).replaceAll('\\', '/');
    if (!path.endsWith('.g.dart') && !path.endsWith('.freezed.dart')) continue;
    final file = File(path);
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    protected[path] = bytes;
    final copy = File(p.join(backup.path, path));
    await copy.parent.create(recursive: true);
    await copy.writeAsBytes(bytes, flush: true);
  }
  stdout.writeln(
    'Generating ${inputs.length} business inputs; preserving ${protected.length} modified outputs.',
  );
  try {
    exitCode = await runner.run(
      ['build', '--delete-conflicting-outputs', ...args],
      [
        apply(
          'riverpod_generator:riverpod_generator',
          [riverpod.riverpodBuilder],
          toRoot(),
          defaultGenerateFor: scope,
          appliesBuilders: ['source_gen:combining_builder'],
        ),
        apply(
          'freezed:freezed',
          [freezed.freezed],
          toRoot(),
          hideOutput: false,
          defaultGenerateFor: scope,
        ),
        apply(
          'json_serializable:json_serializable',
          [json.jsonSerializable],
          toRoot(),
          defaultGenerateFor: scope,
          appliesBuilders: ['source_gen:combining_builder'],
        ),
        apply(
          'hive_generator:hive_generator',
          [hive.getBuilder],
          toRoot(),
          defaultGenerateFor: scope,
          appliesBuilders: ['source_gen:combining_builder'],
        ),
        apply(
          'source_gen:combining_builder',
          [source.combiningBuilder],
          toNoneByDefault(),
          hideOutput: false,
          defaultGenerateFor: scope,
          appliesBuilders: ['source_gen:part_cleanup'],
        ),
        applyPostProcess('source_gen:part_cleanup', source.partCleanup),
      ],
    );
  } finally {
    for (final entry in protected.entries) {
      final file = File(entry.key);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value, flush: true);
    }
  }
}
