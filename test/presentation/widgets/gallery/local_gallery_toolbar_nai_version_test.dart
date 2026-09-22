import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';

/// NAI 版本过滤胶囊的 Full/Curated 悬停子菜单测试。
///
/// 契约：版本行悬停 800ms 在右侧展开变体子菜单；点击行=全量、
/// 点击子项=变体子集写 filterModels；胶囊文案 Ver N / Ver NF / Ver NC；
/// NAI 3 无变体不挂子菜单。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openVersionMenu(WidgetTester tester) async {
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
  }

  TestGesture? mouseGesture;

  Future<TestGesture> mouse(WidgetTester tester) async {
    if (mouseGesture == null) {
      mouseGesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouseGesture!.addPointer(location: Offset.zero);
      addTearDown(() => mouseGesture?.removePointer());
    }
    return mouseGesture!;
  }

  Future<void> hover(WidgetTester tester, Finder target) async {
    final gesture = await mouse(tester);
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
  }

  testWidgets('version row click selects whole version (all variants)', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester);
    await openVersionMenu(tester);

    await tester.tap(find.text('NAI 4.5'));
    await tester.pumpAndSettle();

    expect(
      notifier.lastFilterModels,
      containsAll([
        ImageModels.animeDiffusionV45Full,
        ImageModels.animeDiffusionV45Curated,
        ImageModels.animeDiffusionV45FullInpainting,
        ImageModels.animeDiffusionV45CuratedInpainting,
      ]),
    );
    expect(notifier.lastFilterModels, hasLength(4));
  });

  testWidgets('hovering 800ms shows Full/Curated submenu; NAI 3 has none', (
    tester,
  ) async {
    await _pumpToolbar(tester);
    await openVersionMenu(tester);

    // 未到 800ms 不展开
    await hover(tester, find.text('NAI 4.5'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Full'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Full'), findsOneWidget);
    expect(find.text('Curated'), findsOneWidget);

    // 行尾悬停箭头出现
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // NAI 3 行悬停不出子菜单（先移开 4.5 触发收起，再悬停 3）
    await hover(tester, find.text('NAI 3'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Full'), findsNothing);
  });

  testWidgets('submenu Full writes full-variant subset and label Ver 4.5F', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester);
    await openVersionMenu(tester);
    await hover(tester, find.text('NAI 4.5'));
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text('Full'));
    await tester.pumpAndSettle();

    expect(
      notifier.lastFilterModels,
      containsAll([
        ImageModels.animeDiffusionV45Full,
        ImageModels.animeDiffusionV45FullInpainting,
      ]),
    );
    expect(notifier.lastFilterModels, hasLength(2));
    expect(notifier.lastNaiOnly, isTrue);

    // 胶囊文案 Ver 4.5F
    expect(find.text('Ver 4.5F'), findsOneWidget);
  });

  testWidgets('submenu Curated writes curated subset and label Ver 4.5C', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester);
    await openVersionMenu(tester);
    await hover(tester, find.text('NAI 5'));
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text('Curated'));
    await tester.pumpAndSettle();

    expect(
      notifier.lastFilterModels,
      containsAll([
        ImageModels.animeDiffusionV5Curated,
        ImageModels.animeDiffusionV5CuratedInpainting,
      ]),
    );
    expect(notifier.lastFilterModels, hasLength(2));
    expect(find.text('Ver 5C'), findsOneWidget);
  });
}

Future<_FakeGalleryNotifier> _pumpToolbar(
  WidgetTester tester, {
  List<String> initialModels = const [],
}) async {
  tester.view.physicalSize = const Size(2400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final notifier = _FakeGalleryNotifier(
    LocalGalleryState(
      currentImages: [_record(r'C:\gallery\page-1.png')],
      filteredCount: 1,
      totalCount: 1,
      totalPages: 1,
      isInitialized: true,
      filterCriteria: FilterCriteria(filterModels: initialModels),
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localGalleryNotifierProvider.overrideWith(() => notifier),
        localGallerySelectionNotifierProvider.overrideWith(
          () => _InactiveSelectionNotifier(),
        ),
        shortcutConfigNotifierProvider.overrideWith(
          _FakeShortcutConfigNotifier.new,
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LocalGalleryToolbar()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

LocalImageRecord _record(String path) {
  return LocalImageRecord(path: path, size: 1, modifiedAt: DateTime(2026));
}

class _FakeGalleryNotifier extends LocalGalleryNotifier {
  _FakeGalleryNotifier(this._initialState);

  final LocalGalleryState _initialState;

  List<String>? lastFilterModels;
  bool? lastNaiOnly;

  @override
  LocalGalleryState build() => _initialState;

  @override
  Future<void> setFilterModels(List<String> models) async {
    lastFilterModels = models;
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(
        filterModels: models,
        clearFilterModels: models.isEmpty,
      ),
    );
  }

  @override
  Future<void> setNaiOnly(bool value) async {
    lastNaiOnly = value;
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(naiOnly: value),
    );
  }
}

class _InactiveSelectionNotifier extends LocalGallerySelectionNotifier {
  @override
  SelectionModeState build() => const SelectionModeState();
}

class _FakeShortcutConfigNotifier extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}
