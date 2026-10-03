import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/router/app_branch.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/navigation/main_nav_rail.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../helpers/studio_capture_fonts.dart';

class _MockNavigationShell extends Mock implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_MockNavigationShell';
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _FakeAccountManagerNotifier extends AccountManagerNotifier {
  @override
  AccountManagerState build() => const AccountManagerState();
}

class _FakeMainNavStorage extends LocalStorageService {
  bool isExpanded = false;

  @override
  bool getMainNavRailExpanded() => isExpanded;

  @override
  Future<void> setMainNavRailExpanded(bool expanded) async {
    isExpanded = expanded;
  }
}

class _CaptureAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    accountId: 'offline-rail-account',
  );
}

class _CaptureAccountNotifier extends AccountManagerNotifier {
  @override
  AccountManagerState build() => AccountManagerState(
    accounts: [
      SavedAccount(
        id: 'offline-rail-account',
        email: 'preview@example.test',
        nickname: 'PD',
        createdAt: DateTime(2026),
        subscriptionExpiresAt:
            DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
      ),
      SavedAccount(
        id: 'offline-secondary',
        email: 'second@example.test',
        nickname: '鳄鱼',
        createdAt: DateTime(2026),
        subscriptionExpiresAt:
            DateTime.now()
                .add(const Duration(days: 4))
                .millisecondsSinceEpoch ~/
            1000,
      ),
    ],
  );
}

class _FakeUpdateNotifier extends UpdateStateNotifier {
  @override
  UpdateState build() => const UpdateState(status: UpdateStatus.available);
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('.dart_tool/account-popover-captures/rail-$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _captureWikiMotion(
  WidgetTester tester,
  GlobalKey boundary,
  bool dark,
) async {
  if (Platform.environment['CAPTURE_WIKI_MOTION'] != '1') return;
  final icon = find.byWidgetPredicate(
    (w) => w is StudioAnimatedIcon && w.icon == StudioIcons.tagWiki,
  );
  final button = find.ancestor(of: icon, matching: find.byType(InkWell));
  final rect = tester.getRect(button);
  expect(rect.size, const Size(44, 44));
  final local = rect.topLeft - tester.getTopLeft(find.byKey(boundary));
  final folder = Directory('.dart_tool/wiki-motion-captures')
    ..createSync(recursive: true);
  Future<void> frame(int index) => tester
      .runAsync(() async {
        const ratio = 3.0;
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final full = await render.toImage(pixelRatio: ratio);
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawImageRect(
          full,
          Rect.fromLTWH(
            local.dx * ratio,
            local.dy * ratio,
            rect.width * ratio,
            rect.height * ratio,
          ),
          Rect.fromLTWH(0, 0, rect.width * ratio, rect.height * ratio),
          Paint(),
        );
        final picture = recorder.endRecording();
        final cropped = await picture.toImage(
          (rect.width * ratio).round(),
          (rect.height * ratio).round(),
        );
        final bytes = (await cropped.toByteData(
          format: ui.ImageByteFormat.png,
        ))!;
        File(
          '${folder.path}/nav-${dark ? 'dark' : 'light'}-${index.toString().padLeft(2, '0')}.png',
        ).writeAsBytesSync(bytes.buffer.asUint8List());
        cropped.dispose();
        picture.dispose();
        full.dispose();
      })
      .then((_) {});
  await frame(0);
  await tester.tap(button);
  await tester.pump();
  for (var i = 1; i <= 20; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      tester.getRect(button),
      rect,
      reason: 'Click motion must not move the target or surrounding layout.',
    );
    await frame(i);
  }
  expect(
    find.descendant(of: button, matching: find.byIcon(StudioIcons.tagWiki)),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    if (Platform.environment['CAPTURE_STUDIO_UI'] != '1' &&
        Platform.environment['CAPTURE_WIKI_MOTION'] != '1') {
      return;
    }
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('600px 高度下主导航可滚动且不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final navigationShell = _MockNavigationShell();
    final storage = _FakeMainNavStorage();
    when(
      () => navigationShell.currentIndex,
    ).thenReturn(AppBranch.styleExplore.index);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          accountManagerNotifierProvider.overrideWith(
            _FakeAccountManagerNotifier.new,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MainNavRail(navigationShell: navigationShell)),
        ),
      ),
    );
    await tester.pump();

    final avatar = find.byIcon(Icons.person);
    expect(tester.getCenter(avatar).dx, closeTo(24, 0.1));
    expect(tester.getTopLeft(avatar).dy, greaterThanOrEqualTo(8));
    expect(
      tester.getSize(find.byKey(const Key('main-nav-avatar'))),
      const Size(40, 40),
    );
    expect(tester.widget<Icon>(avatar).size, 24);

    expect(find.byKey(const Key('main-nav-primary-scroll')), findsOneWidget);
    expect(find.byIcon(StudioIcons.settings), findsOneWidget);
    // 画风探索使用遗传分支，块内遗传操作另用双螺旋。
    expect(find.byIcon(StudioIcons.styleExplore), findsOneWidget);
    expect(find.byIcon(Icons.biotech), findsNothing);
    final primary = Theme.of(
      tester.element(find.byIcon(StudioIcons.styleExplore)),
    ).colorScheme.primary;
    expect(
      tester.widget<Icon>(find.byIcon(StudioIcons.styleExplore)).color,
      primary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(StudioIcons.generation)).color,
      isNot(primary),
    );

    // 分组只改变显示顺序，不能改变对应的路由与选中态。
    final destinations = <(Finder, AppBranch)>[
      (find.byIcon(StudioIcons.generation), AppBranch.generation),
      (find.byIcon(StudioIcons.styleExplore), AppBranch.styleExplore),
      (find.byIcon(StudioIcons.localGallery), AppBranch.localGallery),
      (find.byIcon(StudioIcons.onlineGallery), AppBranch.onlineGallery),
      (find.byIcon(StudioIcons.promptBlocks), AppBranch.promptBlockLibrary),
      (find.byIcon(StudioIcons.vibeLibrary), AppBranch.vibeLibrary),
      (find.byIcon(StudioIcons.preciseReference), AppBranch.preciseRefLibrary),
      (find.byIcon(StudioIcons.tagWiki), AppBranch.tagWiki),
      (find.byIcon(StudioIcons.statistics), AppBranch.statistics),
    ];
    for (var i = 1; i < destinations.length; i++) {
      expect(
        tester.getCenter(destinations[i].$1).dy,
        greaterThan(tester.getCenter(destinations[i - 1].$1).dy),
      );
    }
    final dividers = find.descendant(
      of: find.byKey(const Key('main-nav-primary-scroll')),
      matching: find.byType(Divider),
    );
    expect(dividers, findsNWidgets(2));
    for (final (divider, before, after) in [
      (dividers.at(0), destinations[1].$1, destinations[2].$1),
      (dividers.at(1), destinations[7].$1, destinations[8].$1),
    ]) {
      expect(
        tester.getCenter(divider).dy,
        greaterThan(tester.getCenter(before).dy),
      );
      expect(
        tester.getCenter(divider).dy,
        lessThan(tester.getCenter(after).dy),
      );
    }
    expect(find.byIcon(Icons.keyboard_double_arrow_right), findsOneWidget);
    // 账户固定在顶部；底部保留收起钮和设置。
    expect(
      tester.getCenter(find.byIcon(Icons.person)).dy,
      lessThan(tester.getCenter(find.byIcon(StudioIcons.generation)).dy),
    );
    expect(
      tester.getCenter(find.byKey(const Key('main-nav-toggle'))).dy,
      lessThan(tester.getCenter(find.byIcon(StudioIcons.settings)).dy),
    );
    expect(
      tester.getSize(find.byKey(const Key('main-nav-rail'))).width,
      MainNavRail.collapsedWidth,
    );
    expect(find.text('画布'), findsNothing);

    final accountTop = tester.getTopLeft(find.byIcon(Icons.person)).dy;
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    final addAccount = find.text('添加账号');
    expect(addAccount, findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('account-popover'))).dy, 8);
    expect(
      tester.getTopLeft(addAccount).dx,
      greaterThan(MainNavRail.collapsedWidth),
    );
    await tester.tapAt(const Offset(700, 400));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('main-nav-toggle')));
    await tester.pumpAndSettle();

    expect(storage.isExpanded, isTrue);
    expect(tester.getTopLeft(find.byIcon(Icons.person)).dy, accountTop);
    expect(
      tester.getSize(find.byKey(const Key('main-nav-rail'))).width,
      MainNavRail.expandedWidth,
    );
    expect(find.text('画布'), findsOneWidget);
    expect(find.text('本地画廊'), findsOneWidget);
    expect(find.text('提示词块'), findsOneWidget);
    expect(find.byIcon(StudioIcons.promptBlocks), findsOneWidget);
    expect(find.text('GitHub 仓库'), findsNothing);
    expect(find.text('收起侧边栏'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_double_arrow_left), findsOneWidget);

    for (final (finder, branch) in [
      ...destinations,
      (find.byIcon(StudioIcons.settings), AppBranch.settings),
    ]) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      verify(() => navigationShell.goBranch(branch.index)).called(1);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is StudioIconPainter,
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    }

    expect(tester.getTopLeft(find.byIcon(Icons.person)).dy, accountTop);

    // Focus the actual settings button, then activate with the keyboard.
    Focus.of(tester.element(find.byIcon(StudioIcons.settings))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    verify(() => navigationShell.goBranch(AppBranch.settings.index)).called(1);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('main-nav-toggle')));
    await tester.pumpAndSettle();

    expect(storage.isExpanded, isFalse);
    expect(
      tester.getSize(find.byKey(const Key('main-nav-rail'))).width,
      MainNavRail.collapsedWidth,
    );
    expect(find.text('画布'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('紧凑导航：居中、边缘点击、悬停、短窗口和菜单；dark=$dark', (tester) async {
      final previousDisableShadows = debugDisableShadows;
      addTearDown(() => debugDisableShadows = previousDisableShadows);
      if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
        debugDisableShadows = false;
      }
      await tester.binding.setSurfaceSize(const Size(640, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final shell = _MockNavigationShell();
      when(() => shell.currentIndex).thenReturn(AppBranch.generation.index);
      final storage = _FakeMainNavStorage();
      final boundary = GlobalKey();
      final rootBoundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWith((ref) => storage),
            authNotifierProvider.overrideWith(_CaptureAuthNotifier.new),
            accountManagerNotifierProvider.overrideWith(
              _CaptureAccountNotifier.new,
            ),
            updateStateProvider.overrideWith(_FakeUpdateNotifier.new),
          ],
          child: MaterialApp(
            theme: dark ? GeistTheme.dark : GeistTheme.light,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                RepaintBoundary(key: rootBoundary, child: child!),
            home: Scaffold(
              body: Row(
                children: [
                  RepaintBoundary(
                    key: boundary,
                    child: MainNavRail(navigationShell: shell),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final generation = find.byIcon(StudioIcons.generation);
      final toggle = find.byKey(const Key('main-nav-toggle'));
      final settings = find.byIcon(StudioIcons.settings);
      for (final icon in [generation, settings, toggle]) {
        expect(tester.getCenter(icon).dx, 24);
      }
      expect(tester.getCenter(find.byKey(const Key('main-nav-avatar'))).dx, 24);
      final hitTarget = find.ancestor(
        of: generation,
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(hitTarget), const Size(44, 44));
      // 底板内留白也可以点击，不能只剩 20px 图标可以点。
      await tester.tapAt(tester.getTopLeft(hitTarget) + const Offset(1, 1));
      verify(() => shell.goBranch(AppBranch.generation.index)).called(1);
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNWidgets(10));
      expect(
        tester
            .widgetList<Badge>(find.byType(Badge))
            .where((b) => b.isLabelVisible),
        hasLength(1),
      );
      final mode = dark ? 'dark' : 'light';
      await _capture(tester, boundary, '$mode-collapsed');
      if (Platform.environment['CAPTURE_WIKI_MOTION'] == '1') {
        when(() => shell.currentIndex).thenReturn(AppBranch.tagWiki.index);
        tester.element(find.byType(MainNavRail)).markNeedsBuild();
        await tester.pumpAndSettle();
        await _captureWikiMotion(tester, boundary, dark);
        verify(() => shell.goBranch(AppBranch.tagWiki.index)).called(1);
        when(() => shell.currentIndex).thenReturn(AppBranch.generation.index);
        tester.element(find.byType(MainNavRail)).markNeedsBuild();
        await tester.pumpAndSettle();
      }

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(generation));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('画布'), findsOneWidget);
      await _capture(tester, rootBoundary, '$mode-tooltip');
      await mouse.removePointer();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('main-nav-avatar')));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('添加账号')).dx, greaterThan(48));
      await _capture(tester, rootBoundary, '$mode-account-menu');
      await tester.tapAt(const Offset(600, 650));
      await tester.pumpAndSettle();

      await tester.tap(toggle);
      await tester.pump();
      // 逐帧经过展开过程，避免只有最终宽度正常而动画中溢出。
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(tester.getCenter(generation).dx, 24);
      expect(tester.getCenter(settings).dx, 24);
      expect(find.text('画布'), findsOneWidget);
      await _capture(tester, boundary, '$mode-expanded');

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(640, 360));
      await tester.pumpAndSettle();
      expect(settings.hitTestable(), findsOneWidget);
      expect(toggle.hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('main-nav-avatar')).hitTestable(),
        findsOneWidget,
      );
      final statistics = find.byIcon(StudioIcons.statistics);
      await tester.ensureVisible(statistics);
      await tester.pumpAndSettle();
      await tester.tap(statistics);
      verify(() => shell.goBranch(AppBranch.statistics.index)).called(1);
      await tester.pumpAndSettle();
      Focus.of(tester.element(settings)).requestFocus();
      await tester.pumpAndSettle();
      await _capture(tester, boundary, '$mode-short-keyboard-focus');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      verify(() => shell.goBranch(AppBranch.settings.index)).called(1);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Flutter 在 test body 返回时先检查绘制变量，再运行 teardown。
      debugDisableShadows = previousDisableShadows;
    });
  }
}
