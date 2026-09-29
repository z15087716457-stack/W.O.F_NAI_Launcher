import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/router/app_branch.dart';
import 'package:nai_launcher/presentation/widgets/navigation/main_nav_rail.dart';
import 'package:nai_launcher/presentation/widgets/auth/account_avatar.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

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

void main() {
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

    final brandTile = find.byKey(const Key('main-nav-brand-tile'));
    expect(tester.getTopLeft(brandTile), Offset.zero);
    expect(tester.getSize(brandTile).height, 60);
    expect(tester.widget<Container>(brandTile).color, kAvatarBackground);

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
      (dividers.at(1), destinations[6].$1, destinations[7].$1),
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
    expect(tester.getTopLeft(addAccount).dy, lessThan(150));
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
}
