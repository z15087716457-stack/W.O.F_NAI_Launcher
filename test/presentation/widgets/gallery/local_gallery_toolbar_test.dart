import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/utils/gallery_storage_layout.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_gallery_search.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_rag_query_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_rag_search_menu.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_filter_widgets.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/wiring/gallery_search_history.dart';
import '../../../helpers/studio_capture_fonts.dart';

/// 顶栏：范围面包屑与数量、搜索标签、排序菜单、视图切换、多选与详情开关。
void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'typing does not record; enter records; history selection cancels pending input',
    (tester) async {
      GallerySearchHistoryViewData? history;
      final notifier = await _pumpToolbar(
        tester,
        state: const LocalGalleryState(
          isInitialized: true,
          filterCriteria: FilterCriteria(naiOnly: true, selectedTags: ['solo']),
        ),
        onSearchHistoryChanged: (value) => history = value,
      );
      final field = find.byKey(const Key('gallery-search-field'));
      await tester.enterText(field, 'first');
      await tester.pump(const Duration(milliseconds: 310));
      expect(history!.items, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(history!.items, ['first']);
      await tester.enterText(field, 'pending');
      history!.select('chosen');
      await tester.pump();
      expect(notifier.current.filterCriteria.searchQuery, 'chosen');
      expect(tester.widget<TextField>(field).controller!.text, 'chosen');
      await tester.pump(const Duration(milliseconds: 310));
      expect(notifier.current.filterCriteria.searchQuery, 'chosen');
      expect(notifier.current.filterCriteria.naiOnly, isTrue);
      expect(notifier.current.filterCriteria.selectedTags, ['solo']);
      expect(history!.items, ['first']);
    },
  );

  group('search history popup', () {
    final twelve = [for (var i = 0; i < 12; i++) 'query $i'];

    testWidgets(
      'appears on focus with empty input; 5 rows visible, rest scroll',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.localGallerySearchHistory: twelve,
        });
        await _pumpToolbar(tester);
        expect(find.byKey(const Key('gallery-search-history')), findsNothing);
        await tester.tap(find.byKey(const Key('gallery-search-field')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('gallery-search-history')), findsOneWidget);
        final list = tester.getSize(
          find.byKey(const Key('gallery-search-history-list')),
        );
        expect(list.height, 32.0 * 5);
        expect(
          find.byKey(const Key('gallery-search-history-11')),
          findsNothing,
        );
        await tester.drag(
          find.byKey(const Key('gallery-search-history-list')),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('gallery-search-history-11')),
          findsOneWidget,
        );
        // 输入后收起，清空后回来。
        await tester.enterText(
          find.byKey(const Key('gallery-search-field')),
          'a',
        );
        await tester.pump();
        expect(find.byKey(const Key('gallery-search-history')), findsNothing);
        await tester.enterText(
          find.byKey(const Key('gallery-search-field')),
          '',
        );
        await tester.pump();
        expect(find.byKey(const Key('gallery-search-history')), findsOneWidget);
        // Esc 先关浮层，不失焦。
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(find.byKey(const Key('gallery-search-history')), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('gallery-search-field')))
              .focusNode!
              .hasFocus,
          isTrue,
        );
      },
    );

    testWidgets('select fills and searches; remove and clear update the list', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGallerySearchHistory: ['blue eyes', 'aokumo'],
      });
      final notifier = await _pumpToolbar(tester);
      await tester.tap(find.byKey(const Key('gallery-search-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gallery-search-history-1')));
      await tester.pumpAndSettle();
      expect(notifier.current.filterCriteria.searchQuery, 'aokumo');
      expect(find.byKey(const Key('gallery-search-history')), findsNothing);
      await tester.enterText(find.byKey(const Key('gallery-search-field')), '');
      await tester.pumpAndSettle();
      final row = find.byKey(const Key('gallery-search-history-0'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(row));
      addTearDown(mouse.removePointer);
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byKey(const Key('gallery-search-history-remove')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('blue eyes'), findsNothing);
      expect(find.text('aokumo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('gallery-search-history-clear')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gallery-search-history')), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList(StorageKeys.localGallerySearchHistory),
        isEmpty,
      );
    });

    testWidgets('history popup closes when Ctrl tag expansion opens', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.localGallerySearchHistory: ['blue eyes'],
      });
      await _pumpToolbar(tester, autocomplete: true);
      final field = find.byKey(const Key('gallery-search-field'));
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gallery-search-history')), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(field);
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(find.byKey(const Key('tag-expansion-search')), findsOneWidget);
      expect(find.byKey(const Key('gallery-search-history')), findsNothing);
    });
  });

  testWidgets(
    'history and Ctrl tag expansion are mutually exclusive through contract',
    (tester) async {
      GallerySearchHistoryViewData? history;
      await _pumpToolbar(
        tester,
        autocomplete: true,
        onSearchHistoryChanged: (value) => history = value,
      );
      history!.setPopupOpen(true);
      await tester.pump();
      final field = find.byKey(const Key('gallery-search-field'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(field);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(find.byKey(const Key('tag-expansion-search')), findsNothing);
      history!.setPopupOpen(false);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(field);
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(history!.tagExpansionActive, isTrue);
      expect(find.byKey(const Key('tag-expansion-search')), findsOneWidget);
    },
  );

  testWidgets('compact toolbar icons are centred inside their ink bounds', (
    tester,
  ) async {
    await _pumpToolbar(tester);
    final buttons = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .where((b) => b.style?.fixedSize?.resolve({}) == const Size(32, 32));
    expect(buttons, isNotEmpty);
    for (final button in buttons) {
      final host = find.byWidget(button);
      final icon = find.descendant(of: host, matching: find.byType(Icon));
      final ink = find.descendant(
        of: host,
        matching: find.byWidgetPredicate((w) => w is InkResponse),
      );
      expect(tester.getRect(icon).center, tester.getRect(ink).center);
    }
  });

  testWidgets(
    'default folder breadcrumb and search scope use its localized label',
    (tester) async {
      await _pumpToolbar(
        tester,
        state: const LocalGalleryState(
          isInitialized: true,
          filterCriteria: FilterCriteria(categoryId: 'uncategorized'),
        ),
      );
      expect(find.text('未分类文件夹'), findsOneWidget);
      expect(find.text(galleryUncategorizedFolderName), findsNothing);
      final field = tester.widget<TextField>(
        find.byKey(const Key('gallery-search-field')),
      );
      expect(field.decoration!.hintText, contains('未分类文件夹'));
    },
  );

  testWidgets(
    'query image remains retryable after an error and waits during GPU hold',
    (tester) async {
      await _pumpToolbar(tester, rag: true);
      final context = tester.element(find.byKey(const Key('gallery-rag-menu')));
      final container = ProviderScope.containerOf(context);
      final controller =
          container.read(ragControllerProvider.notifier) as _ToolbarRag;
      controller.changeStatus(error: true);
      await tester.pump();
      await tester.tap(find.byKey(const Key('gallery-rag-menu')));
      await tester.pumpAndSettle();
      final choose = find.widgetWithText(
        PopupMenuItem<String>,
        AppLocalizations.of(context)!.rag_galleryChooseImage,
      );
      expect(tester.widget<PopupMenuItem<String>>(choose).enabled, isTrue);
      await tester.tap(choose);
      await tester.pumpAndSettle();
      controller.changeStatus(hold: true);
      await tester.pump();
      await tester.tap(find.byKey(const Key('gallery-rag-menu')));
      await tester.pumpAndSettle();
      expect(tester.widget<PopupMenuItem<String>>(choose).enabled, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final width in [760.0, 1400.0]) {
        testWidgets(
          'gallery RAG menu ${locale.toLanguageTag()} dark=$dark width=$width',
          (tester) async {
            await _pumpToolbar(
              tester,
              rag: true,
              width: width,
              locale: locale,
              theme: AppTheme.getTheme(
                AppStyle.geist,
                dark ? Brightness.dark : Brightness.light,
                fontConfig: FontConfig.defaultFont,
              ),
            );
            expect(find.byKey(const Key('rag-badge-gallery')), findsOneWidget);
            Future<void> capture(String scene) async {
              await tester.runAsync(() async {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const Key('gallery-toolbar-capture')),
                );
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                final dir = Directory(
                  Platform.environment['GALLERY_RAG_MENU_CAPTURE_DIR'] ??
                      '.dart_tool/rag-gallery-20261015/captures',
                );
                await dir.create(recursive: true);
                await File(
                  '${dir.path}/toolbar-${locale.toLanguageTag()}-${dark ? 'dark' : 'light'}-${width.toInt()}-$scene.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
              });
            }

            await capture('ready');
            await tester.tap(find.byKey(const Key('gallery-rag-menu')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            void expectMenuBelowSearch() {
              final firstItem = find.byType(CheckedPopupMenuItem<String>).first;
              final menu = tester.getRect(
                find
                    .ancestor(
                      of: firstItem,
                      matching: find.byWidgetPredicate(
                        (w) => w is Material && w.type == MaterialType.card,
                      ),
                    )
                    .first,
              );
              final field = find.byKey(const Key('gallery-search-field'));
              final search = tester.getRect(
                find
                    .ancestor(
                      of: field,
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              );
              final trigger = tester.getRect(
                find.byKey(const Key('gallery-rag-menu')),
              );
              expect(menu.top, greaterThan(search.bottom));
              expect(menu.top, greaterThan(trigger.bottom));
              expect(menu.left, lessThanOrEqualTo(trigger.center.dx));
              expect(menu.right, greaterThanOrEqualTo(trigger.center.dx));
            }

            expectMenuBelowSearch();
            await capture('menu');
            final context = tester.element(
              find.byKey(const Key('gallery-rag-menu')),
            );
            final l = AppLocalizations.of(context)!;
            await tester.tap(
              find.widgetWithText(
                CheckedPopupMenuItem<String>,
                l.rag_galleryVisual,
              ),
            );
            await tester.pumpAndSettle();
            final container = ProviderScope.containerOf(context);
            expect(
              container.read(galleryRagQueryProvider).mode,
              RagGalleryMode.visual,
            );
            await tester.tap(find.byKey(const Key('gallery-rag-menu')));
            await tester.pumpAndSettle();
            expectMenuBelowSearch();
            await tester.tap(
              find.widgetWithText(
                PopupMenuItem<String>,
                l.rag_galleryChooseImage,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              container.read(galleryRagQueryProvider).image,
              'C:/query/original.png',
            );
            await capture('image');
            await tester.tap(find.byKey(const Key('gallery-rag-clear-image')));
            await tester.pumpAndSettle();
            expect(container.read(galleryRagQueryProvider).image, isEmpty);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }

  for (final locale in ['zh', 'zh-TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final width in [900.0, 1400.0]) {
        testWidgets('search contents centered $locale dark=$dark width=$width', (
          tester,
        ) async {
          await _pumpToolbar(
            tester,
            width: width,
            pixelRatio: width == 900 ? 1.25 : 1,
            locale: Locale.fromSubtags(
              languageCode: locale.split('-').first,
              countryCode: locale.contains('-') ? 'TW' : null,
            ),
            theme: AppTheme.getTheme(
              AppStyle.geist,
              dark ? Brightness.dark : Brightness.light,
              fontConfig: FontConfig.defaultFont,
            ),
          );
          final field = find.byKey(const Key('gallery-search-field'));
          final surface = find
              .ancestor(of: field, matching: find.byType(AnimatedContainer))
              .first;
          final center = tester.getCenter(surface).dy;
          expect(tester.getSize(surface).height, 34);
          final hint = tester.widget<TextField>(field).decoration!.hintText!;
          expect(
            tester.getCenter(find.text(hint)).dy,
            closeTo(center, 1),
            reason:
                'Hint must align to the outer 34px surface, not a shorter dense decorator.',
          );
          expect(
            tester.getCenter(find.byIcon(StudioIcons.gallerySearch)).dy,
            closeTo(center, 1),
          );
          expect(tester.getCenter(find.text('Ctrl F')).dy, closeTo(center, 1));
          await tester.tap(field);
          await tester.pumpAndSettle();
          expect(
            tester.getCenter(find.byIcon(StudioIcons.gallerySearch)).dy,
            closeTo(center, 1),
          );
          await tester.enterText(field, '测试 blue eyes');
          await tester.pumpAndSettle();
          expect(
            tester.getCenter(find.byType(EditableText)).dy,
            closeTo(center, 1),
          );
          expect(
            tester.getCenter(find.byIcon(StudioIcons.galleryClose)).dy,
            closeTo(center, 1),
          );
          await tester.tap(find.byIcon(StudioIcons.galleryClose));
          await tester.pumpAndSettle();
          tester.widget<TextField>(field).focusNode!.unfocus();
          await tester.pumpAndSettle();
          expect(
            tester.getCenter(find.byIcon(StudioIcons.gallerySearch)).dy,
            closeTo(center, 1),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  testWidgets('breadcrumb shows the folder path and the result count', (
    tester,
  ) async {
    await _pumpToolbar(
      tester,
      state: const LocalGalleryState(
        isInitialized: true,
        totalCount: 48809,
        filteredCount: 19832,
        filterCriteria: FilterCriteria(categoryId: 'normal'),
      ),
    );

    expect(find.text('01_图库'), findsOneWidget);
    expect(find.text('NAI 4.5'), findsOneWidget);
    expect(find.text('正常向'), findsOneWidget);
    expect(find.text('19,832 张'), findsOneWidget);
    expect(find.text('搜索：正常向'), findsOneWidget);
  });

  testWidgets('sort menu switches field and direction and persists it', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester);

    await tester.tap(find.byKey(const Key('gallery-toolbar-sort')));
    await tester.pumpAndSettle();
    final rows = find.byType(GalleryChoiceMenuItem<Object>);
    expect(rows, findsNWidgets(7));
    for (final row in rows.evaluate()) {
      expect(tester.getSize(find.byWidget(row.widget)).height, 34);
    }
    final nameLeft = tester.getTopLeft(find.text('文件名').last).dx;
    expect(tester.getTopLeft(find.text('修改时间').last).dx, nameLeft);
    expect(tester.getTopLeft(find.text('降序').last).dx, nameLeft);
    await tester.tap(find.text('文件名').last);
    await tester.pumpAndSettle();
    expect(notifier.sortCalls.last, (
      GallerySortField.fileName,
      GallerySort.defaultDirectionFor(GallerySortField.fileName),
    ));

    await tester.tap(find.byKey(const Key('gallery-toolbar-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('降序').last);
    await tester.pumpAndSettle();
    expect(notifier.sortCalls.last, (
      GallerySortField.fileName,
      GallerySortDirection.descending,
    ));
    expect(
      (await const GallerySortStore().load())?.direction,
      GallerySortDirection.descending,
    );
  });

  testWidgets('view segment switches the layout mode', (tester) async {
    final notifier = await _pumpToolbar(tester);
    await tester.tap(find.byKey(const ValueKey('gallery-view-masonry')));
    await tester.pump();
    expect(notifier.current.viewMode, GalleryViewMode.masonry);
  });

  testWidgets('multi-select toggles selection mode; inspector toggle obeys '
      'availability', (tester) async {
    var inspectorToggles = 0;
    await _pumpToolbar(
      tester,
      inspectorAvailable: false,
      onToggleInspector: () => inspectorToggles++,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LocalGalleryToolbar)),
    );

    await tester.tap(find.byKey(const Key('gallery-toolbar-multiselect')));
    await tester.pump();
    expect(
      container.read(localGallerySelectionNotifierProvider).isActive,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('gallery-toolbar-multiselect')));
    await tester.pump();
    expect(
      container.read(localGallerySelectionNotifierProvider).isActive,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('gallery-toolbar-inspector')));
    await tester.pump();
    expect(inspectorToggles, 0, reason: '窗口过窄时详情面板不可展开');
  });

  for (final width in [1500.0, 860.0]) {
    testWidgets('fits in one row without overflow at width $width', (
      tester,
    ) async {
      await _pumpToolbar(tester, width: width);
      expect(tester.takeException(), isNull);
      final toolbar = tester.getRect(find.byType(LocalGalleryToolbar));
      final more = tester.getRect(
        find.byKey(const Key('gallery-toolbar-more')),
      );
      expect(more.right, lessThanOrEqualTo(toolbar.right));
      expect(tester.getSize(find.byType(TextField)).width, greaterThan(140));
    });
  }

  testWidgets('view segment uses line icons; justified keeps view_day', (
    tester,
  ) async {
    await _pumpToolbar(tester);
    for (final (mode, icon) in [
      ('grid', StudioIcons.galleryViewGrid),
      ('masonry', StudioIcons.galleryViewMasonry),
      ('justified', Icons.view_day_outlined),
    ]) {
      final button = find.byKey(ValueKey('gallery-view-$mode'));
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: button, matching: find.byType(Icon)),
            )
            .icon,
        icon,
      );
    }
  });

  double searchGap(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('gallery-toolbar-sort'))).left -
      tester.getRect(find.byKey(const Key('gallery-search-field'))).right;

  testWidgets('search grows to fill the space between title and tools', (
    tester,
  ) async {
    await _pumpToolbar(tester, width: 1100);
    final search = tester.getSize(
      find.byKey(const Key('gallery-search-field')),
    );
    expect(search.width, greaterThan(420), reason: '搜索框应占满中间空白');
    expect(searchGap(tester), inInclusiveRange(24, 26.5));
  });

  testWidgets('search stops growing on very wide windows', (tester) async {
    await _pumpToolbar(tester, width: 2200);
    final search = tester.getSize(
      find.byKey(const Key('gallery-search-field')),
    );
    expect(search.width, inInclusiveRange(876, 880), reason: '超宽窗口不无限拉长');
    expect(searchGap(tester), greaterThan(200));
  });

  testWidgets('blank toolbar space drags the window; controls do not', (
    tester,
  ) async {
    final windowCalls = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (
      call,
    ) async {
      windowCalls.add(call.method);
      return call.method == 'isMaximized' || call.method == 'isFullScreen'
          ? false
          : null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        null,
      ),
    );
    await _pumpToolbar(tester, width: 2200, windowChrome: true);

    final search = tester.getRect(
      find.byKey(const Key('gallery-search-field')),
    );
    final sort = tester.getRect(find.byKey(const Key('gallery-toolbar-sort')));
    final count = tester.getRect(
      find.byKey(const Key('gallery-toolbar-count')),
    );
    for (final point in [
      Offset((search.right + sort.left) / 2, search.center.dy),
      count.center,
      Offset(search.center.dx, 4),
    ]) {
      await tester.dragFrom(point, const Offset(60, 20));
      await tester.pumpAndSettle();
      expect(windowCalls, contains('startDragging'), reason: '$point');
      windowCalls.clear();
    }

    await tester.dragFrom(search.center, const Offset(60, 0));
    await tester.tap(find.byKey(const Key('gallery-toolbar-multiselect')));
    await tester.pumpAndSettle();
    expect(windowCalls, isNot(contains('startDragging')));
  });

  testWidgets('Ctrl+click selects a local tag as a gallery filter chip', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester, autocomplete: true);
    final field = find.byType(TextField).first;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(field);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'blue',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(notifier.current.filterCriteria.selectedTags, ['blue_hair']);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
  });
}

Future<_FakeGalleryNotifier> _pumpToolbar(
  WidgetTester tester, {
  LocalGalleryState state = const LocalGalleryState(
    isInitialized: true,
    totalCount: 3,
  ),
  double width = 1400,
  double pixelRatio = 1,
  bool inspectorAvailable = true,
  VoidCallback? onToggleInspector,
  bool autocomplete = false,
  bool rag = false,
  bool windowChrome = false,
  ThemeData? theme,
  Locale locale = const Locale('zh'),
  ValueChanged<GallerySearchHistoryViewData>? onSearchHistoryChanged,
}) async {
  tester.view.physicalSize = Size(width * pixelRatio, 400 * pixelRatio);
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);

  final notifier = _FakeGalleryNotifier(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localGalleryNotifierProvider.overrideWith(() => notifier),
        ragSettingsProvider.overrideWith(() => _ToolbarRagSettings(rag)),
        ragControllerProvider.overrideWith(_ToolbarRag.new),
        galleryRagImagePickerProvider.overrideWithValue(
          () async => 'C:/query/original.png',
        ),
        galleryCategoryNotifierProvider.overrideWith(_FakeCategoryNotifier.new),
        shortcutConfigNotifierProvider.overrideWith(
          _FakeShortcutConfigNotifier.new,
        ),
        localTagExpansionServiceProvider.overrideWithValue(
          LocalTagExpansionService(
            catalog: const _BlueHairSource(),
            relatedTags: const _EmptySource(),
            substringSearch: (input, {limit = 20}) async => const [],
            popularSearch: ({limit = 12}) async => const [],
          ),
        ),
      ],
      child: RepaintBoundary(
        key: const Key('gallery-toolbar-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WindowChromeScope(
              enabled: windowChrome,
              child: Align(
                alignment: Alignment.topCenter,
                child: LocalGalleryToolbar(
                  searchFocusNode: focusNode,
                  inspectorVisible: true,
                  inspectorAvailable: inspectorAvailable,
                  onToggleInspector: onToggleInspector ?? () {},
                  onOpenFolder: () {},
                  onRefresh: () {},
                  showCategoryPanel: true,
                  onToggleCategoryPanel: () {},
                  enableSearchAutocomplete: autocomplete,
                  onSearchHistoryChanged: onSearchHistoryChanged,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

class _ToolbarRagSettings extends RagSettingsController {
  _ToolbarRagSettings(this.enabled);
  final bool enabled;
  @override
  RagSettings build() => RagSettings(
    enabled: enabled,
    tagsEnabled: false,
    galleryEnabled: enabled,
  );
}

class _ToolbarRag extends RagController {
  void changeStatus({bool error = false, bool hold = false}) {
    state = state.copyWith(
      suspended: hold,
      sources: {
        RagSource.gallery: state
            .forSource(RagSource.gallery)
            .copyWith(
              phase: error ? 'error' : 'partial',
              error: error ? 'rag_runtime_error' : null,
              clearError: !error,
            ),
      },
    );
  }

  @override
  RagStatus build() => const RagStatus(
    sources: {
      RagSource.gallery: RagStatus(
        phase: 'partial',
        indexed: 32,
        total: 40,
        partial: true,
        details: {'visual_indexed': 32},
      ),
    },
  );
}

class _FakeGalleryNotifier extends LocalGalleryNotifier {
  _FakeGalleryNotifier(this._initialState);

  final LocalGalleryState _initialState;
  final List<(GallerySortField, GallerySortDirection)> sortCalls = [];

  LocalGalleryState get current => state;

  @override
  LocalGalleryState build() => _initialState;

  @override
  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(searchQuery: query),
    );
  }

  @override
  Future<void> setSort(
    GallerySortField field,
    GallerySortDirection direction,
  ) async {
    sortCalls.add((field, direction));
    state = state.copyWith(sortField: field, sortDirection: direction);
  }

  @override
  Future<void> addSelectedTags(
    List<String> tags, {
    bool clearSearchQuery = false,
  }) async {
    state = state.copyWith(
      filterCriteria: state.filterCriteria.copyWith(
        selectedTags: [...state.filterCriteria.selectedTags, ...tags],
        searchQuery: clearSearchQuery ? '' : state.filterCriteria.searchQuery,
      ),
    );
  }
}

class _FakeCategoryNotifier extends GalleryCategoryNotifier {
  @override
  GalleryCategoryState build() {
    final now = DateTime(2026);
    GalleryCategory category(String id, String name, String? parent) =>
        GalleryCategory(
          id: id,
          name: name,
          folderPath: name,
          parentId: parent,
          createdAt: now,
          updatedAt: now,
        );
    return GalleryCategoryState(
      categories: [
        category('root', '01_图库', null),
        category('v45', 'NAI 4.5', 'root'),
        category('normal', '正常向', 'v45'),
        category('uncategorized', galleryUncategorizedFolderName, null),
      ],
    );
  }
}

class _BlueHairSource implements CompletionSource {
  const _BlueHairSource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => [
    const CompletionCandidate(
      canonicalTag: 'blue_hair',
      category: TagCategory.general,
      postCount: 100,
      matchKind: CompletionMatchKind.englishPrefix,
      sources: {CompletionSourceKind.base},
    ),
  ];
}

class _EmptySource implements CompletionSource {
  const _EmptySource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      const [];
}

class _FakeShortcutConfigNotifier extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}
