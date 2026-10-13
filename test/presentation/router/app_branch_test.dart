import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/presentation/router/app_branch.dart';

void main() {
  test('global navigation shortcuts map to their actual shell branches', () {
    expect(globalNavigationShortcutBranches, {
      ShortcutIds.navigateToGeneration: AppBranch.generation,
      ShortcutIds.navigateToLocalGallery: AppBranch.localGallery,
      ShortcutIds.navigateToOnlineGallery: AppBranch.onlineGallery,
      ShortcutIds.navigateToSettings: AppBranch.settings,
      ShortcutIds.navigateToStatistics: AppBranch.statistics,
      ShortcutIds.navigateToTagLibrary: AppBranch.promptBlockLibrary,
      ShortcutIds.navigateToVibeLibrary: AppBranch.vibeLibrary,
      ShortcutIds.navigateToStyleExplore: AppBranch.styleExplore,
      ShortcutIds.navigateToPreciseRefLibrary: AppBranch.preciseRefLibrary,
      ShortcutIds.navigateToTagWiki: AppBranch.tagWiki,
    });
  });

  test('prompt block branch keeps its ordinal after tag library removal', () {
    // 旧词库页 Branch 删除后，块库 ordinal 从 8 收缩到 7；
    // 侧栏按功能分组显示，以 AppBranch 判断选中态，不依赖 enum 顺序。
    expect(AppBranch.promptBlockLibrary.index, 7);
    expect(mobileNavigationBranches, const [
      AppBranch.generation,
      AppBranch.localGallery,
      AppBranch.settings,
    ]);
    expect(
      mobileNavigationIndexForBranch(AppBranch.promptBlockLibrary.index),
      mobileNavigationBranches.indexOf(AppBranch.generation),
    );
  });

  test('mobile navigation maps settings and gallery branches correctly', () {
    expect(
      mobileNavigationIndexForBranch(AppBranch.generation.index),
      mobileNavigationBranches.indexOf(AppBranch.generation),
    );
    expect(
      mobileNavigationIndexForBranch(AppBranch.localGallery.index),
      mobileNavigationBranches.indexOf(AppBranch.localGallery),
    );
    expect(
      mobileNavigationIndexForBranch(AppBranch.onlineGallery.index),
      mobileNavigationBranches.indexOf(AppBranch.localGallery),
    );
    expect(
      mobileNavigationIndexForBranch(AppBranch.settings.index),
      mobileNavigationBranches.indexOf(AppBranch.settings),
    );
  });
}
