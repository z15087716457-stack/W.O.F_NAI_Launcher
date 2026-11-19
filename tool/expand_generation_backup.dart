// Print a standalone backup without modifying the source or the current draft.
// dart run tool/expand_generation_backup.dart path/to/before-generation-*.json
import 'dart:convert';
import 'dart:io';
import 'package:nai_launcher/core/storage/generation_draft_backup.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/expand_generation_backup.dart <backup.json>',
    );
    exitCode = 64;
    return;
  }
  stdout.add(
    utf8.encode(jsonEncode(GenerationDraftBackup.read(File(args.single)))),
  );
}
