import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';

/// 工具栏一行布局回归测试
///
/// 需求：搜索框弹性占满中间空间随窗口伸缩；右侧控件簇收缩到按钮自然
/// 宽度并贴到工具栏右端；窗口过窄时控件簇横向滚动兜底而不是溢出。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('wide window: search field stretches, button cluster hugs right', (
    tester,
  ) async {
    await _pumpToolbar(tester, width: 2400);

    final toolbar = tester.getRect(find.byType(LocalGalleryToolbar));
    final searchField = tester.getRect(find.byType(TextField));

    // 搜索框吃到 300px 上限以上的宽度（旧实现锁死 maxWidth:300）
    expect(searchField.width, greaterThan(400));

    // 最右按钮（删除池，图标+标签形态）贴近工具栏右缘（padding 16）
    final trash = tester.getRect(find.byTooltip('删除池'));
    expect(toolbar.right - trash.right, lessThan(40));

    // 按钮簇右端与工具栏右缘对齐（右端不再有残空）
    final scroll = tester.getRect(find.byType(SingleChildScrollView));
    expect(toolbar.right - scroll.right, lessThan(24));
  });

  testWidgets(
    'narrow window: search keeps min width, cluster scrolls instead of overflow',
    (tester) async {
      await _pumpToolbar(tester, width: 900);

      final toolbar = tester.getRect(find.byType(LocalGalleryToolbar));
      final searchField = tester.getRect(find.byType(TextField));
      final scroll = tester.getRect(find.byType(SingleChildScrollView));

      // 搜索框被压缩但仍可用（≥ 最小宽度），且不超过分配区
      expect(searchField.width, greaterThanOrEqualTo(140));
      // 控件簇仍贴着工具栏右端排布
      expect(toolbar.right - scroll.right, lessThan(24));
      // 无横向溢出：控件簇左缘不越过搜索框右缘
      expect(scroll.left, greaterThanOrEqualTo(searchField.right - 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search field width tracks window width', (tester) async {
    await _pumpToolbar(tester, width: 2400);
    final wide = tester.getSize(find.byType(TextField)).width;

    await _pumpToolbar(tester, width: 1400);
    final narrow = tester.getSize(find.byType(TextField)).width;

    expect(narrow, lessThan(wide));
    expect(wide - narrow, greaterThan(300)); // 弹性伸缩，不是固定宽度
  });
}

Future<void> _pumpToolbar(WidgetTester tester, {required double width}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final notifier = _FakeGalleryNotifier(
    LocalGalleryState(
      currentImages: [_record(r'C:\gallery\page-1.png')],
      filteredCount: 1,
      totalCount: 1,
      totalPages: 1,
      isInitialized: true,
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
}

LocalImageRecord _record(String path) {
  return LocalImageRecord(path: path, size: 1, modifiedAt: DateTime(2026));
}

class _FakeGalleryNotifier extends LocalGalleryNotifier {
  _FakeGalleryNotifier(this._initialState);

  final LocalGalleryState _initialState;

  @override
  LocalGalleryState build() => _initialState;
}

class _InactiveSelectionNotifier extends LocalGallerySelectionNotifier {
  @override
  SelectionModeState build() => const SelectionModeState();
}

class _FakeShortcutConfigNotifier extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}
