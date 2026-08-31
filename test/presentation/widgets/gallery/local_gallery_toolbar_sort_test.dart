import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';

/// 排序字段菜单 widget 测试
///
/// 回归：PopupMenuButton 的 child 是带 onPressed 的 OutlinedButton 时，
/// 内层按钮赢下手势竞技场，菜单永远打不开——child 必须包 IgnorePointer。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tapping the sort button opens the field menu', (tester) async {
    await _pumpToolbar(tester);

    // 默认字段 = 修改时间（按钮标签即当前字段名）
    expect(find.text('修改时间'), findsOneWidget);

    await tester.tap(find.byTooltip('排序'));
    await tester.pumpAndSettle();

    // 菜单打开：五个字段可见，当前字段带勾
    expect(find.text('创建时间'), findsOneWidget);
    expect(find.text('文件名'), findsOneWidget);
    expect(find.text('文件大小'), findsOneWidget);
    expect(find.text('图像尺寸'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('selecting a field updates the sort on the provider', (
    tester,
  ) async {
    final notifier = await _pumpToolbar(tester);

    await tester.tap(find.byTooltip('排序'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('文件名'));
    await tester.pumpAndSettle();

    // 菜单选择生效：字段 + 该字段默认方向（名称默认升序）
    expect(notifier.lastSortField, GallerySortField.fileName);
    expect(notifier.lastSortDirection, GallerySortDirection.ascending);

    // 按钮标签跟随当前字段
    expect(find.text('文件名'), findsWidgets);
  });
}

Future<_RecordingGalleryNotifier> _pumpToolbar(WidgetTester tester) async {
  // 放大窗口：工具条标签分支（showStateLabels >= 1170px）需要足够宽度
  tester.view.physicalSize = const Size(2400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final notifier = _RecordingGalleryNotifier(
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
  return notifier;
}

LocalImageRecord _record(String path) {
  return LocalImageRecord(path: path, size: 1, modifiedAt: DateTime(2026));
}

class _RecordingGalleryNotifier extends LocalGalleryNotifier {
  _RecordingGalleryNotifier(this._initialState);

  final LocalGalleryState _initialState;
  GallerySortField? lastSortField;
  GallerySortDirection? lastSortDirection;

  @override
  LocalGalleryState build() => _initialState;

  @override
  Future<void> setSort(
    GallerySortField field,
    GallerySortDirection direction,
  ) async {
    lastSortField = field;
    lastSortDirection = direction;
    // 同步 state，让按钮标签跟随（不依赖真实服务）
    state = state.copyWith(sortField: field, sortDirection: direction);
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
