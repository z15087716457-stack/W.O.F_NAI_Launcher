import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/legacy_preferences_import.dart';

void main() {
  test('copies the app values this version does not have yet', () async {
    final legacy = <String, Object?>{
      'flutter.gallery_sort': 'date',
      'flutter.auto_login': false,
      'flutter.anlas_total': 1200,
      'flutter.column_width': 236.5,
      'flutter.wiki_bookmarks': <Object?>['1girl', 'solo'],
      'flutter.gallery_delete_pool': <Object?>[],
      'flutter.already_here': 'old value',
      // Sign-in data stays behind; the user signs in again.
      'flutter.danbooru_credentials': '{"username":"u","apiKey":"k"}',
      // macOS and plugin keys in the same domain.
      'NSWindow Frame MainWindow': '0 0 800 600',
      'NSNavLastRootDirectory': '~/Documents',
      'flutter.mixed_list': <Object?>['a', 1],
      'flutter.null_value': null,
    };
    final current = {'flutter.already_here', 'flutter.unrelated'};
    final written = <String, Object>{};

    final copied = await LegacyPreferencesImport(
      readLegacy: () async => legacy,
      readCurrentKeys: () async => current,
      write: (key, value) async => written[key] = value,
    ).copyMissing();

    expect(written, {
      'flutter.gallery_sort': 'date',
      'flutter.auto_login': false,
      'flutter.anlas_total': 1200,
      'flutter.column_width': 236.5,
      'flutter.wiki_bookmarks': ['1girl', 'solo'],
      'flutter.gallery_delete_pool': <String>[],
    });
    expect(written['flutter.wiki_bookmarks'], isA<List<String>>());
    expect(copied, written.length);
  });
}
