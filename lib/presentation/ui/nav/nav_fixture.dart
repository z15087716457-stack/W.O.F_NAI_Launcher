import 'package:flutter/widgets.dart';

import 'nav_contract.dart';

/// 预览和基准截图用的假数据（和 HTML 原型同一套示例：鹈鹕 / 备用号、Anlas 9,866、2 / 4 张）。
abstract final class NavFixture {
  static const shortcuts = <NavPage, List<String>>{
    NavPage.generation: ['Ctrl', '1'],
    NavPage.styleExplore: ['Ctrl', '2'],
    NavPage.localGallery: ['Ctrl', '3'],
    NavPage.onlineGallery: ['Ctrl', '4'],
    NavPage.promptBlocks: ['Ctrl', '5'],
    NavPage.vibeLibrary: ['Ctrl', '6'],
    NavPage.preciseRef: ['Ctrl', '7'],
    NavPage.tagWiki: ['Ctrl', '8'],
    NavPage.statistics: ['Ctrl', '9'],
    NavPage.settings: ['Ctrl', ','],
  };

  static final account = NavAccountData(
    current: NavAccount(
      id: 'main',
      name: '鹈鹕',
      subscription: NavSubscription(
        expiresAt: DateTime(2026, 10, 12),
        daysLeft: 5,
        state: NavSubscriptionState.expiringSoon,
      ),
    ),
    others: const [NavAccount(id: 'alt', name: '备用号')],
    anlas: 9866,
    plan: 'Opus',
  );

  static const running = NavGeneration(
    state: NavGenerationState.running,
    current: 2,
    total: 4,
    progress: .63,
  );

  static const tasks = [
    NavTask(
      id: 'upscale',
      kind: NavTaskKind.localUpscale,
      fraction: .42,
      phase: '放大中',
      action: NavTaskAction.cancel,
    ),
    NavTask(id: 'export', kind: NavTaskKind.bulkExport, done: 120, total: 300),
    NavTask(
      id: 'trash',
      kind: NavTaskKind.bulkDelete,
      done: 12,
      total: 12,
      finished: true,
      action: NavTaskAction.undo,
    ),
  ];

  static NavViewData view({
    NavPage current = NavPage.localGallery,
    NavGeneration generation = const NavGeneration.idle(),
    List<NavTask> tasks = const [],
    Set<NavPage> hidden = const {},
    bool pinned = false,
    bool ctrlHintSeen = true,
    bool updateAvailable = false,
    NavAccountData? account,
    ImageProvider? preview,
  }) => NavViewData(
    current: current,
    shortcuts: shortcuts,
    hidden: hidden,
    pinned: pinned,
    ctrlHintSeen: ctrlHintSeen,
    updateAvailable: updateAvailable,
    account: account ?? NavFixture.account,
    generation: preview == null
        ? generation
        : NavGeneration(
            state: generation.state,
            current: generation.current,
            total: generation.total,
            progress: generation.progress,
            preview: preview,
            error: generation.error,
          ),
    tasks: tasks,
  );
}
