import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';

void main() {
  group('LocalGallerySelectionNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'selectRange activates selection mode and selects range when anchor exists',
      () {
        final notifier = container.read(
          localGallerySelectionNotifierProvider.notifier,
        );

        // 先进入并选中第一项作为锚点，然后手动将 isActive 设为 false 以测试非多选态下的 Shift 选择
        notifier.enterAndSelect('img_2');
        container.read(localGallerySelectionNotifierProvider.notifier).exit();

        // 验证重置后
        expect(
          container.read(localGallerySelectionNotifierProvider).isActive,
          isFalse,
        );

        // 手动建立带 anchor 的非激活状态或先 enterAndSelect
        notifier.enterAndSelect('img_1');
        expect(
          container.read(localGallerySelectionNotifierProvider).lastSelectedId,
          'img_1',
        );

        final allIds = ['img_0', 'img_1', 'img_2', 'img_3', 'img_4'];
        notifier.selectRange('img_3', allIds);

        final state = container.read(localGallerySelectionNotifierProvider);
        expect(state.isActive, isTrue);
        expect(state.selectedIds, {'img_1', 'img_2', 'img_3'});
        expect(state.lastSelectedId, 'img_3');
      },
    );

    test(
      'selectRange activates selection mode even when no anchor exists (fallback)',
      () {
        final notifier = container.read(
          localGallerySelectionNotifierProvider.notifier,
        );

        final allIds = ['img_0', 'img_1', 'img_2'];
        expect(
          container.read(localGallerySelectionNotifierProvider).isActive,
          isFalse,
        );
        expect(
          container.read(localGallerySelectionNotifierProvider).lastSelectedId,
          isNull,
        );

        notifier.selectRange('img_1', allIds);

        final state = container.read(localGallerySelectionNotifierProvider);
        expect(state.isActive, isTrue);
        expect(state.selectedIds, {'img_1'});
        expect(state.lastSelectedId, 'img_1');
      },
    );

    test(
      'selectRange activates selection mode when anchor is not in visible list',
      () {
        final notifier = container.read(
          localGallerySelectionNotifierProvider.notifier,
        );

        notifier.enterAndSelect('offscreen_img');
        expect(
          container.read(localGallerySelectionNotifierProvider).lastSelectedId,
          'offscreen_img',
        );

        final visibleIds = ['img_0', 'img_1', 'img_2'];
        notifier.selectRange('img_2', visibleIds);

        final state = container.read(localGallerySelectionNotifierProvider);
        expect(state.isActive, isTrue);
        expect(state.selectedIds, contains('img_2'));
        expect(state.lastSelectedId, 'img_2');
      },
    );

    test('selectRange handles backward selection', () {
      final notifier = container.read(
        localGallerySelectionNotifierProvider.notifier,
      );

      notifier.enterAndSelect('img_4');
      final allIds = ['img_0', 'img_1', 'img_2', 'img_3', 'img_4'];
      notifier.selectRange('img_1', allIds);

      final state = container.read(localGallerySelectionNotifierProvider);
      expect(state.isActive, isTrue);
      expect(state.selectedIds, {'img_1', 'img_2', 'img_3', 'img_4'});
      expect(state.lastSelectedId, 'img_1');
    });
  });
}
