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
      ShortcutIds.navigateToTagLibrary: AppBranch.tagLibrary,
      ShortcutIds.navigateToVibeLibrary: AppBranch.vibeLibrary,
    });
  });

  test('prompt block branch keeps its ordinal after random config removal', () {
    // 旧随机配置 Branch 删除后，块库 ordinal 从 9 收缩到 8；
    // 侧栏显示顺序与 enum 无关（MainNavRail._railBranches 自行排列）。
    expect(AppBranch.promptBlockLibrary.index, 8);
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
