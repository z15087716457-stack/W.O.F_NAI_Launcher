import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/statistics/statistics_provider.dart';
import 'package:nai_launcher/presentation/router/gallery_navigation_request.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';
import 'package:nai_launcher/presentation/wiring/statistics_wiring.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_local_gallery_service.dart';
import 'statistics_fakes.dart';

void main() {
  final today = DateTime(2026, 10, 11);
  setUpAll(() async {
    await AppLogger.initialize(isTestEnvironment: true);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'assembles every contract field without normalizing model or resolution',
    () {
      final repository = FakeStatisticsRepository();
      final data = statisticsViewData(
        StatisticsState(
          today: today,
          range: StatsRange.days30,
          naiOnly: true,
          sync: StatsSyncState.idle,
          updatedAt: today,
          countingImages: 10,
          dashboard: repository.dashboard,
          artists: repository.artists,
          dailyAnlas: repository.dailyAnlas,
        ),
      );
      expect(data.range, StatsRange.days30);
      expect(data.naiOnly, isTrue);
      expect(data.today, today);
      expect(data.updatedAt, today);
      expect(data.countingImages, 10);
      expect(data.sync, StatsSyncState.idle);
      expect(data.errorMessage, isNull);
      final snapshot = data.snapshot!;
      expect(snapshot.libraryTotal, 10);
      expect(snapshot.images, 3);
      expect(snapshot.favorites, 1);
      expect(snapshot.bytes, 2097152);
      expect(snapshot.withMetadata, 2);
      expect(snapshot.weekHour.length, 168);
      expect(snapshot.weekHour[10], 2);
      expect(snapshot.weekHour[154], 1);
      expect(snapshot.weekHour.fold<int>(0, (a, b) => a + b), 3);
      expect(snapshot.models.single.key, 'nai-diffusion-5-full');
      expect(snapshot.models.single.count, 2);
      expect(
        (
          snapshot.resolutions.first.width,
          snapshot.resolutions.first.height,
          snapshot.resolutions.first.count,
        ),
        (832, 1216, 2),
      );
      expect(snapshot.samplers.single.key, 'k_euler');
      expect(snapshot.steps.single.key, 28);
      expect(snapshot.cfg.single.key, 5.5);
      expect(snapshot.noiseSchedules.single.key, 'karras');
      expect(snapshot.sizeBuckets.length, 5);
      expect(snapshot.sizeBuckets.map((bucket) => bucket.count), [
        1,
        2,
        0,
        0,
        0,
      ]);
      expect(snapshot.sizeBuckets.map((bucket) => bucket.bytes), [
        100,
        2097052,
        0,
        0,
        0,
      ]);
      expect(snapshot.dailyImages, {
        DateTime(2026, 9, 1): 1,
        DateTime(2026, 10, 5): 2,
      });
      expect(snapshot.dailyModels.single.day, DateTime(2026, 10, 5));
      expect(snapshot.dailyModels.single.model, 'nai-diffusion-5-full');
      expect(snapshot.dailyModels.single.count, 2);
      expect(snapshot.monthlyBytes, {
        DateTime(2026, 9, 1): 100,
        DateTime(2026, 10, 1): 2097052,
      });
      expect(snapshot.dailyAnlas, {DateTime(2026, 10, 5): 42});
      expect(snapshot.artists!.top.single.key, 'example name');
      expect(snapshot.artists!.top.single.count, 2);
      expect(snapshot.artists!.imagesWithArtist, 2);
      expect(
        statisticsViewData(
          StatisticsState(today: today, error: 'failure'),
        ).snapshot,
        isNull,
      );
      expect(
        statisticsViewData(
          StatisticsState(today: today, error: 'failure'),
        ).errorMessage,
        'failure',
      );
      expect(
        statisticsViewData(
          StatisticsState(today: today, dashboard: repository.dashboard),
        ).snapshot!.artists,
        isNull,
      );
    },
  );

  final cases = <(StatsGalleryFilter, FilterCriteria)>[
    (
      StatsDateFilter(DateTime(2026, 9, 1), DateTime(2026, 9, 2)),
      FilterCriteria(
        dateStart: DateTime(2026, 9, 1),
        dateEnd: DateTime(2026, 9, 2),
      ),
    ),
    (
      const StatsModelFilter('nai-diffusion-5-full'),
      const FilterCriteria(filterModels: ['nai-diffusion-5-full']),
    ),
    (
      const StatsResolutionFilter(832, 1216),
      const FilterCriteria(filterResolutions: ['832x1216']),
    ),
    (
      const StatsOrientationFilter(StatsOrientation.portrait),
      const FilterCriteria(filterOrientation: 'portrait'),
    ),
    (
      const StatsSamplerFilter('k_euler'),
      const FilterCriteria(filterSamplers: ['k_euler']),
    ),
    (
      const StatsStepsFilter(28),
      const FilterCriteria(filterMinSteps: 28, filterMaxSteps: 28),
    ),
    (
      const StatsCfgFilter(5.5),
      const FilterCriteria(filterMinCfg: 5.5, filterMaxCfg: 5.5),
    ),
    (
      const StatsArtistFilter('example name'),
      const FilterCriteria(searchQuery: 'artist:example name'),
    ),
    (
      const StatsNoMetadataFilter(),
      const FilterCriteria(metadataStatuses: ['none'], hasMetadata: false),
    ),
    (
      const StatsMinFileSizeFilter(10485760),
      const FilterCriteria(minFileSize: 10485760),
    ),
  ];
  for (final (filter, expected) in cases) {
    test('translates $filter and preserves current date and NAI scope', () {
      final actual = statisticsGalleryFilter(
        filter,
        range: StatsRange.days7,
        naiOnly: true,
        today: today,
      );
      expect(
        actual,
        expected.copyWith(
          dateStart: filter is StatsDateFilter
              ? filter.start
              : DateTime(2026, 10, 5),
          dateEnd: filter is StatsDateFilter
              ? filter.end
              : DateTime(2026, 10, 12),
          naiOnly: true,
          indexedDate: true,
          dateEndExclusive: true,
        ),
      );
      expect(
        actual.displayDateEnd,
        filter is StatsDateFilter ? DateTime(2026, 9, 1) : today,
      );
    });
  }

  test(
    'gallery receives external criteria atomically and can clear every session filter',
    () async {
      final service = FakeLocalGalleryService([]);
      final container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(service),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setSelectedCollection('old-collection');
      for (final (filter, _) in cases) {
        final criteria = statisticsGalleryFilter(
          filter,
          range: StatsRange.days7,
          naiOnly: true,
          today: today,
        );
        final before = service.applyFilterCount;
        await notifier.applyExternalFilter(criteria);
        expect(service.applyFilterCount, before + 1);
        expect(
          container.read(localGalleryNotifierProvider).filterCriteria,
          criteria,
        );
        expect(
          container
              .read(localGalleryNotifierProvider)
              .filterCriteria
              .collectionId,
          isNull,
        );
        await notifier.clearAllFilters();
        final cleared = container
            .read(localGalleryNotifierProvider)
            .filterCriteria;
        expect(cleared.hasSessionFilters, isFalse);
        expect(cleared.indexedDate, isFalse);
        expect(cleared.dateEndExclusive, isFalse);
        expect(cleared.hasMetadata, isNull);
        expect(cleared.naiOnly, isTrue);
      }
      expect(
        (await SharedPreferences.getInstance()).getBool('statistics_nai_only'),
        isNull,
      );
    },
  );

  testWidgets(
    'wiring renders only the contracted page and connects state callbacks',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeStatisticsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statisticsRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
            statisticsClockProvider.overrideWithValue(() => today),
          ],
          child: MaterialApp(
            theme: GeistTheme.light,
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const Scaffold(body: StatisticsWiring()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsPage), findsOneWidget);
      var page = tester.widget<StatisticsPage>(find.byType(StatisticsPage));
      expect(page.data.snapshot!.images, 3);
      page.actions.onRangeChanged(StatsRange.days7);
      await tester.pumpAndSettle();
      expect(repository.range, 'days7');
      page = tester.widget<StatisticsPage>(find.byType(StatisticsPage));
      page.actions.onNaiOnlyChanged(true);
      await tester.pumpAndSettle();
      expect(repository.nai, isTrue);
      page = tester.widget<StatisticsPage>(find.byType(StatisticsPage));
      final before = repository.loads;
      page.actions.onRefresh();
      await tester.pumpAndSettle();
      expect(repository.loads, before + 1);
      expect(repository.clears, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'navigation sends gallery filters and repeatable folder requests',
    (tester) async {
      GalleryNavigationRequest? received;
      late BuildContext source;
      final router = GoRouter(
        initialLocation: '/statistics',
        routes: [
          GoRoute(
            path: '/statistics',
            builder: (context, state) {
              source = context;
              return const SizedBox();
            },
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Text('generate'),
          ),
          GoRoute(
            path: '/local-gallery',
            builder: (context, state) {
              received = state.extra as GalleryNavigationRequest;
              return const Text('gallery');
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      const navigation = StatisticsNavigation();
      final criteria = statisticsGalleryFilter(
        const StatsStepsFilter(28),
        range: StatsRange.all,
        naiOnly: false,
        today: today,
      );
      navigation.gallery(source, criteria);
      await tester.pumpAndSettle();
      expect(received!.criteria, criteria);
      expect(received!.addFolder, isFalse);
      router.go('/statistics');
      await tester.pumpAndSettle();
      navigation.addFolder(source);
      await tester.pumpAndSettle();
      final first = received;
      expect(first!.addFolder, isTrue);
      router.go('/statistics');
      await tester.pumpAndSettle();
      navigation.addFolder(source);
      await tester.pumpAndSettle();
      expect(identical(received, first), isFalse);
      router.go('/statistics');
      await tester.pumpAndSettle();
      navigation.generate(source);
      await tester.pumpAndSettle();
      expect(find.text('generate'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
