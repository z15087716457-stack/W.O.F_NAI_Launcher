import 'package:flutter/material.dart';
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
import 'package:nai_launcher/presentation/widgets/prompt/pills/dna_icon.dart';

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

    expect(find.byKey(const Key('main-nav-primary-scroll')), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    // BUG-6：画风探索入口为自绘 DNA 双螺旋（Icons.biotech 是显微镜字形）。
    expect(find.byType(DnaIcon), findsOneWidget);
    expect(find.byIcon(Icons.biotech), findsNothing);
    final primary = Theme.of(
      tester.element(find.byType(DnaIcon)),
    ).colorScheme.primary;
    expect(tester.widget<DnaIcon>(find.byType(DnaIcon)).color, primary);
    expect(tester.widget<Icon>(find.byIcon(Icons.brush)).color, isNot(primary));

    // 分组只改变显示顺序，不能改变对应的路由与选中态。
    final destinations = <(Finder, AppBranch)>[
      (find.byIcon(Icons.brush), AppBranch.generation),
      (find.byType(DnaIcon), AppBranch.styleExplore),
      (find.byIcon(Icons.folder), AppBranch.localGallery),
      (find.byIcon(Icons.photo_library), AppBranch.onlineGallery),
      (find.byIcon(Icons.view_module_outlined), AppBranch.promptBlockLibrary),
      (find.byIcon(Icons.auto_awesome), AppBranch.vibeLibrary),
      (find.byIcon(Icons.center_focus_strong), AppBranch.preciseRefLibrary),
      (find.byIcon(Icons.bar_chart), AppBranch.statistics),
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
    // d28096d0 后展开/收起钮在底部簇顶端（GitHub、设置之上）
    expect(
      tester.getCenter(find.byKey(const Key('main-nav-toggle'))).dy,
      lessThan(tester.getCenter(find.byIcon(Icons.settings)).dy),
    );
    expect(
      tester.getSize(find.byKey(const Key('main-nav-rail'))).width,
      MainNavRail.collapsedWidth,
    );
    expect(find.text('画布'), findsNothing);

    await tester.tap(find.byKey(const Key('main-nav-toggle')));
    await tester.pumpAndSettle();

    expect(storage.isExpanded, isTrue);
    expect(
      tester.getSize(find.byKey(const Key('main-nav-rail'))).width,
      MainNavRail.expandedWidth,
    );
    expect(find.text('画布'), findsOneWidget);
    expect(find.text('本地画廊'), findsOneWidget);
    expect(find.text('提示词块'), findsOneWidget);
    expect(find.byIcon(Icons.view_module_outlined), findsOneWidget);
    expect(find.text('GitHub 仓库'), findsOneWidget);
    expect(find.text('收起侧边栏'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_double_arrow_left), findsOneWidget);

    for (final (finder, branch) in destinations) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      verify(() => navigationShell.goBranch(branch.index)).called(1);
    }

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
