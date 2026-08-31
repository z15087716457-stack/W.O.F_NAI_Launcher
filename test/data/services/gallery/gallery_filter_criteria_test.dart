import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';

/// FilterCriteria 多选字段与缓存键/旗标语义单元测试
void main() {
  group('FilterCriteria', () {
    test('defaults: no metadata filters', () {
      const criteria = FilterCriteria();

      expect(criteria.hasFilters, isFalse);
      expect(criteria.hasMetadataFilters, isFalse);
      expect(criteria.filterModels, isEmpty);
      expect(criteria.filterSamplers, isEmpty);
      expect(criteria.filterResolutions, isEmpty);
      expect(criteria.filterOrientation, isNull);
      expect(criteria.nsfwMode, isNull);
      expect(criteria.naiOnly, isFalse); // 默认 false，生效来源是持久化偏好
    });

    test('naiOnly participates in hasFilters and cacheKey', () {
      const criteria = FilterCriteria(naiOnly: true);

      expect(criteria.hasFilters, isTrue);
      expect(criteria.cacheKey, contains('nai:1'));
      expect(const FilterCriteria().cacheKey, isNot(criteria.cacheKey));
      // 只读 flag 语义：等于基于 cacheKey
      expect(const FilterCriteria(naiOnly: true), criteria);
    });

    test('copyWith toggles naiOnly both ways', () {
      const criteria = FilterCriteria();

      final on = criteria.copyWith(naiOnly: true);
      expect(on.naiOnly, isTrue);
      expect(on.hasFilters, isTrue);

      final off = on.copyWith(naiOnly: false);
      expect(off.naiOnly, isFalse);
      expect(off.hasFilters, isFalse);
    });

    test(
      'hasSessionFilters counts session filters only, not scope/naiOnly',
      () {
        // 范围字段与 naiOnly 都不算会话条件
        expect(const FilterCriteria(naiOnly: true).hasSessionFilters, isFalse);
        expect(
          const FilterCriteria(categoryId: 'cat-1').hasSessionFilters,
          isFalse,
        );
        expect(
          const FilterCriteria(
            categoryFolderPath: r'aaa\bbb',
          ).hasSessionFilters,
          isFalse,
        );
        expect(
          const FilterCriteria(collectionId: 'col-1').hasSessionFilters,
          isFalse,
        );
        expect(
          const FilterCriteria(showFavoritesOnly: true).hasSessionFilters,
          isFalse,
        );
        // 范围 + naiOnly 组合仍不算（用户只是浏览该范围，没施加条件）
        expect(
          const FilterCriteria(
            naiOnly: true,
            categoryId: 'cat-1',
            collectionId: 'col-1',
            showFavoritesOnly: true,
          ).hasSessionFilters,
          isFalse,
        );

        // 任意会话条件即算
        expect(
          const FilterCriteria(
            naiOnly: true,
            searchQuery: 'solo',
          ).hasSessionFilters,
          isTrue,
        );
        expect(
          const FilterCriteria(
            categoryId: 'cat-1',
            selectedTags: ['solo'],
          ).hasSessionFilters,
          isTrue,
        );
        expect(
          const FilterCriteria(
            collectionId: 'col-1',
            dateStart: null,
          ).hasSessionFilters,
          isFalse, // dateStart=null 不算
        );
        expect(
          const FilterCriteria(
            collectionId: 'col-1',
            filterModels: ['x'],
          ).hasSessionFilters,
          isTrue,
        );
        expect(
          const FilterCriteria(
            showFavoritesOnly: true,
            nsfwMode: 'nsfw',
          ).hasSessionFilters,
          isTrue,
        );
        expect(
          const FilterCriteria(
            showFavoritesOnly: true,
            minFileSize: 100,
          ).hasSessionFilters,
          isTrue,
        );

        // 完全无过滤
        expect(const FilterCriteria().hasSessionFilters, isFalse);
      },
    );

    test('hasMetadataFilters covers all new dimensions', () {
      expect(
        const FilterCriteria(filterModels: ['x']).hasMetadataFilters,
        isTrue,
      );
      expect(
        const FilterCriteria(filterSamplers: ['x']).hasMetadataFilters,
        isTrue,
      );
      expect(
        const FilterCriteria(
          filterResolutions: ['832x1216'],
        ).hasMetadataFilters,
        isTrue,
      );
      expect(
        const FilterCriteria(filterOrientation: 'landscape').hasMetadataFilters,
        isTrue,
      );
      expect(const FilterCriteria(nsfwMode: 'nsfw').hasMetadataFilters, isTrue);
      expect(
        const FilterCriteria(filterMinSteps: 10).hasMetadataFilters,
        isTrue,
      );
      expect(
        const FilterCriteria(filterMaxCfg: 8.0).hasMetadataFilters,
        isTrue,
      );
      expect(
        const FilterCriteria(selectedTags: ['solo']).hasMetadataFilters,
        isFalse,
      );
    });

    test('hasFilters covers new dimensions', () {
      expect(const FilterCriteria(filterModels: ['x']).hasFilters, isTrue);
      expect(const FilterCriteria(nsfwMode: 'sfw').hasFilters, isTrue);
      expect(
        const FilterCriteria(filterOrientation: 'square').hasFilters,
        isTrue,
      );
    });

    test('copyWith replaces list fields', () {
      const criteria = FilterCriteria();
      final updated = criteria.copyWith(
        filterModels: ['a', 'b'],
        filterSamplers: ['k_euler'],
        filterResolutions: ['1024x1024'],
        filterOrientation: 'portrait',
        nsfwMode: 'nsfw',
      );

      expect(updated.filterModels, ['a', 'b']);
      expect(updated.filterSamplers, ['k_euler']);
      expect(updated.filterResolutions, ['1024x1024']);
      expect(updated.filterOrientation, 'portrait');
      expect(updated.nsfwMode, 'nsfw');
      expect(updated.hasMetadataFilters, isTrue);
    });

    test('clear flags reset list fields to empty / scalars to null', () {
      const criteria = FilterCriteria(
        filterModels: ['a'],
        filterSamplers: ['b'],
        filterResolutions: ['c'],
        filterOrientation: 'landscape',
        nsfwMode: 'sfw',
      );

      final cleared = criteria.copyWith(
        clearFilterModels: true,
        clearFilterSamplers: true,
        clearFilterResolutions: true,
        clearFilterOrientation: true,
        clearNsfwMode: true,
      );

      expect(cleared.filterModels, isEmpty);
      expect(cleared.filterSamplers, isEmpty);
      expect(cleared.filterResolutions, isEmpty);
      expect(cleared.filterOrientation, isNull);
      expect(cleared.nsfwMode, isNull);
      expect(cleared.hasFilters, isFalse);
    });

    test('copyWith without clear keeps existing list values', () {
      const criteria = FilterCriteria(filterModels: ['a']);
      final updated = criteria.copyWith(filterOrientation: 'square');

      expect(updated.filterModels, ['a']);
      expect(updated.filterOrientation, 'square');
    });

    test('cacheKey reflects new dimensions and list order', () {
      const base = FilterCriteria();
      final models = base.copyWith(filterModels: ['b', 'a']);
      final samplers = models.copyWith(filterSamplers: ['k_euler']);
      final orientation = samplers.copyWith(filterOrientation: 'landscape');
      final nsfw = orientation.copyWith(nsfwMode: 'nsfw');

      expect(base.cacheKey, isNot(models.cacheKey));
      expect(models.cacheKey, isNot(samplers.cacheKey));
      expect(samplers.cacheKey, isNot(orientation.cacheKey));
      expect(orientation.cacheKey, isNot(nsfw.cacheKey));
      expect(nsfw.cacheKey, contains('models:b,a'));
      expect(nsfw.cacheKey, contains('samplers:k_euler'));
      expect(nsfw.cacheKey, contains('orient:landscape'));
      expect(nsfw.cacheKey, contains('nsfw:nsfw'));

      // 列表顺序敏感（join 顺序即缓存键的一部分）
      expect(
        base.copyWith(filterModels: ['a', 'b']).cacheKey,
        isNot(base.copyWith(filterModels: ['b', 'a']).cacheKey),
      );
    });

    test('equality is based on cacheKey', () {
      const a = FilterCriteria(filterModels: ['x']);
      const b = FilterCriteria(filterModels: ['x']);

      expect(a, b);
      expect(a.hashCode, b.hashCode);

      expect(a.copyWith(nsfwMode: 'nsfw'), isNot(a));
    });
  });
}
