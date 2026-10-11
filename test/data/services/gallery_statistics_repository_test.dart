import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/data/services/gallery_statistics_repository.dart';
import 'package:nai_launcher/data/services/statistics_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Source extends Mock implements GalleryDataSource {}

class _Cache extends Mock implements StatisticsCacheService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'local_gallery_nai_only': true});
  });

  test(
    'artist counts are per image and normalize case, underscores and weights',
    () {
      final result = countStatisticsArtists([
        '1.5::artist:Example_Name::, {{artist:example name}}, artist:SECOND',
        'artist:EXAMPLE_NAME, artist:second',
        'notartist:wrong, artist:   , landscape',
        'artist:name_(artist)',
        'landscape',
      ]);
      expect(result.counts, {
        'example name': 2,
        'second': 2,
        'name (artist)': 1,
      });
      expect(result.imagesWithArtist, 3);
    },
  );

  test(
    'statistics preferences default independently and serialize latest choices',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final source = _Source();
      when(
        () => source.getStatisticsSignature(),
      ).thenAnswer((_) async => 'test:10');
      final repository = GalleryStatisticsRepository(
        readDataSource: () async => source,
        cache: _Cache(),
        preferences: preferences,
        readAnlas: () async => [],
      );
      expect(repository.savedRange, isNull);
      expect(repository.savedNaiOnly, isFalse);
      final oldSignature = await repository.readSignature();
      when(
        () => source.getStatisticsSignature(),
      ).thenAnswer((_) async => 'test:11');
      expect(await repository.readSignature(), isNot(oldSignature));
      await Future.wait([
        repository.saveSelection('days7', true),
        repository.saveSelection('days30', false),
      ]);
      expect(repository.savedRange, 'days30');
      expect(repository.savedNaiOnly, isFalse);
      expect(preferences.getBool('local_gallery_nai_only'), isTrue);
    },
  );
}
