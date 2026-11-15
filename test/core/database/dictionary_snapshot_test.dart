import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/dictionary_data_store.dart';
import 'package:nai_launcher/core/database/dictionary_downloader.dart';

void main() {
  for (final kind in DictionaryKind.values) {
    test(
      '${kind.name} snapshot matches its source lock and downloader',
      () async {
        final lock = jsonDecode(
          await File('tool/dictionary_updates/source_lock.json').readAsString(),
        );
        final entry = lock['sources'][kind.name];
        final file = File(entry['file'] as String);
        final source = dictionarySources[kind]!;
        expect(await file.length(), source.bytes);
        expect(entry['bytes'], source.bytes);
        expect(
          (await sha256.bind(file.openRead()).first).toString(),
          source.sha256,
        );
        expect(entry['sha256'], source.sha256);
        expect(entry['date'], source.date);
        if (source.gitBlobSha1.isNotEmpty) {
          final digest = await sha1
              .bind(
                Stream.fromIterable([
                  utf8.encode('blob ${source.bytes}\u0000'),
                  await file.readAsBytes(),
                ]),
              )
              .first;
          expect(digest.toString(), source.gitBlobSha1);
        }
      },
    );
  }
}
