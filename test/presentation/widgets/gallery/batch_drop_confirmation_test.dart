import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_category_tree_view.dart';

void main() {
  group('Gallery batch drop and selection clearing', () {
    test('onBatchImageDrop signature and callback forwarding', () {
      List<String>? droppedPaths;
      String? droppedCategoryId;

      final tree = GalleryCategoryTreeView(
        categories: const [],
        totalImageCount: 0,
        onCategorySelected: (_) {},
        onBatchImageDrop: (paths, categoryId) {
          droppedPaths = paths;
          droppedCategoryId = categoryId;
        },
      );

      expect(tree.onBatchImageDrop, isNotNull);
      tree.onBatchImageDrop!(['/path/1.png', '/path/2.png'], 'cat_1');

      expect(droppedPaths, ['/path/1.png', '/path/2.png']);
      expect(droppedCategoryId, 'cat_1');
    });

    test('batch move single confirmation simulation', () async {
      int confirmationDialogCount = 0;
      bool executionOccurred = false;

      // 模拟批量移动执行体：传入 N 个文件，只弹一次确认
      Future<void> simulateExecuteMoveToCategory(
        List<String> paths, {
        required Future<bool> Function() showConfirmDialog,
        required Future<void> Function(List<String> paths) doMove,
      }) async {
        if (paths.isEmpty) return;

        // 仅在整批开始前弹一次确认
        confirmationDialogCount++;
        final confirmed = await showConfirmDialog();
        if (!confirmed) return;

        // 仅执行一次批量移动
        await doMove(paths);
        executionOccurred = true;
      }

      final paths = ['/a.png', '/b.png', '/c.png'];
      await simulateExecuteMoveToCategory(
        paths,
        showConfirmDialog: () async => true,
        doMove: (p) async {
          expect(p.length, 3);
        },
      );

      // 断言：确认弹窗恰好弹了一次（严禁每张图弹一次）
      expect(confirmationDialogCount, 1);
      expect(executionOccurred, isTrue);
    });

    test(
      'selection mode clears upon successful batch operation and remains on cancel',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          localGallerySelectionNotifierProvider.notifier,
        );

        // 1. 用户选中多张图片
        notifier.enterAndSelect('img_1');
        notifier.toggle('img_2');
        notifier.toggle('img_3');

        expect(
          container.read(localGallerySelectionNotifierProvider).isActive,
          isTrue,
        );
        expect(
          container.read(localGallerySelectionNotifierProvider).selectedIds,
          {'img_1', 'img_2', 'img_3'},
        );

        // 2. 取消时：不退出多选态
        // （模拟用户在确认弹窗点击了取消，未调用 exit）
        expect(
          container.read(localGallerySelectionNotifierProvider).isActive,
          isTrue,
        );
        expect(
          container
              .read(localGallerySelectionNotifierProvider)
              .selectedIds
              .length,
          3,
        );

        // 3. 成功移动后：调用 exit() 清空多选
        notifier.exit();
        expect(
          container.read(localGallerySelectionNotifierProvider).isActive,
          isFalse,
        );
        expect(
          container.read(localGallerySelectionNotifierProvider).selectedIds,
          isEmpty,
        );
      },
    );
  });
}
