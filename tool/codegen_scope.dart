import 'dart:io';

import 'package:path/path.dart' as p;

Future<List<String>> discoverInputs(
  List<String> roots,
  List<String> excluded, {
  String directory = '.',
}) async {
  final inputs = <String>[];
  final annotation = RegExp(
    r'^\s*@(riverpod|Riverpod|freezed|Freezed|JsonSerializable|HiveType)\b',
    multiLine: true,
  );
  final part = RegExp(
    r'''^\s*part\s+['"][^'"]+\.(?:g|freezed)\.dart['"]\s*;''',
    multiLine: true,
  );
  for (final root in roots) {
    final folder = Directory(p.join(directory, root));
    if (!await folder.exists()) continue;
    await for (final entity in folder.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = p
          .relative(entity.path, from: directory)
          .replaceAll('\\', '/');
      if (excluded.any(path.startsWith) ||
          path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart')) {
        continue;
      }
      final text = await entity.readAsString();
      if (part.hasMatch(text)) {
        inputs.add(path);
      } else if (annotation.hasMatch(text)) {
        throw StateError('Annotated source has no generated part: $path');
      }
    }
  }
  inputs.sort();
  if (inputs.isEmpty) throw StateError('No code-generation inputs found');
  return inputs;
}
