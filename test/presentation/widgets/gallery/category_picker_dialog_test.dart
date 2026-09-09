import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/category_picker_dialog.dart';

class _MockCategoryNotifier extends GalleryCategoryNotifier {
  final List<GalleryCategory> _categories;

  _MockCategoryNotifier(this._categories);

  @override
  GalleryCategoryState build() => GalleryCategoryState(categories: _categories);
}

void main() {
  final now = DateTime.now();
  final List<GalleryCategory> testCategories = [
    GalleryCategory(
      id: 'cat-1',
      name: '2026-09-09',
      folderPath: '2026-09-09',
      sortOrder: 0,
      imageCount: 5,
      createdAt: now,
      updatedAt: now,
    ),
    GalleryCategory(
      id: 'cat-sub-1',
      parentId: 'cat-1',
      name: 'Drafts',
      folderPath: '2026-09-09/Drafts',
      sortOrder: 0,
      imageCount: 2,
      createdAt: now,
      updatedAt: now,
    ),
    GalleryCategory(
      id: 'cat-ext-1',
      name: 'External Source',
      folderPath: r'D:\External\Photos',
      sortOrder: 1,
      imageCount: 10,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  setUp(() {
    CategoryPickerDialog.debugClearSessionExpandedIds();
  });

  Widget buildTestWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        galleryCategoryNotifierProvider.overrideWith(
          () => _MockCategoryNotifier(testCategories),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'renders collapsed by default: root categories visible, children hidden',
    (tester) async {
      await tester.pumpWidget(
        buildTestWidget(child: const CategoryPickerDialog(title: '移动到…')),
      );
      await tester.pumpAndSettle();

      // 标题
      expect(find.text('移动到…'), findsOneWidget);
      // 未分类（图库根）
      expect(find.text('未分类（图库根）'), findsOneWidget);
      // 根分类可见
      expect(find.text('2026-09-09'), findsOneWidget);
      // 子分类默认收起不可见
      expect(find.text('Drafts'), findsNothing);
      // 外部分类与外部徽章
      expect(find.text('External Source'), findsOneWidget);
      expect(find.text('外部'), findsOneWidget);
    },
  );

  testWidgets('expanding a category reveals children, tapping again collapses', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(child: const CategoryPickerDialog(title: '移动到…')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Drafts'), findsNothing);

    // 点展开箭头 → 子分类出现
    await tester.tap(
      find.byKey(const ValueKey('category_picker_expand_cat-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Drafts'), findsOneWidget);

    // 再点 → 收起
    await tester.tap(
      find.byKey(const ValueKey('category_picker_expand_cat-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Drafts'), findsNothing);
  });

  testWidgets('search filters categories by displayName', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(child: const CategoryPickerDialog(title: '移动到…')),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Drafts');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category_picker_item_cat-sub-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category_picker_item_cat-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category_picker_item_cat-ext-1')),
      findsNothing,
    );
  });

  testWidgets('three-state return: cancel returns null', (tester) async {
    CategoryPickResult? result;
    var completed = false;

    await tester.pumpWidget(
      buildTestWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await CategoryPickerDialog.show(context, title: '选择分类');
              completed = true;
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 点击取消按钮
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('three-state return: root item returns category null', (
    tester,
  ) async {
    CategoryPickResult? result;
    var completed = false;

    await tester.pumpWidget(
      buildTestWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await CategoryPickerDialog.show(context, title: '选择分类');
              completed = true;
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 点击未分类（图库根）
    await tester.tap(find.byKey(const ValueKey('category_picker_root_item')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNotNull);
    expect(result!.category, isNull);
  });

  testWidgets(
    'three-state return: selecting category returns selected category',
    (tester) async {
      CategoryPickResult? result;
      var completed = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await CategoryPickerDialog.show(
                  context,
                  title: '选择分类',
                );
                completed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 点击外部分类
      await tester.tap(
        find.byKey(const ValueKey('category_picker_item_cat-ext-1')),
      );
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(result, isNotNull);
      expect(result!.category, isNotNull);
      expect(result!.category!.id, 'cat-ext-1');
      expect(result!.category!.isExternal, isTrue);
    },
  );

  testWidgets('session memory: expansion persists across reopen within run', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              CategoryPickerDialog.show(context, title: '移动到…');
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 第一次打开：默认收起
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Drafts'), findsNothing);

    // 展开 cat-1 → 取消
    await tester.tap(
      find.byKey(const ValueKey('category_picker_expand_cat-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Drafts'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 再次打开：保持展开（会话记忆）
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Drafts'), findsOneWidget);
  });
}
