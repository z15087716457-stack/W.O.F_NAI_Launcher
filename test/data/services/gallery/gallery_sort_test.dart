import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';

void main() {
  group('GallerySort sqlColumn whitelist', () {
    test('maps enum fields to fixed SQL columns', () {
      const modified = GallerySort(
        field: GallerySortField.modifiedAt,
        direction: GallerySortDirection.descending,
      );
      const name = GallerySort(
        field: GallerySortField.fileName,
        direction: GallerySortDirection.ascending,
      );
      const size = GallerySort(
        field: GallerySortField.fileSize,
        direction: GallerySortDirection.descending,
      );

      expect(modified.sqlColumn, 'modified_at');
      expect(name.sqlColumn, 'file_name');
      expect(size.sqlColumn, 'file_size');
    });

    test('default sort is modifiedAt descending (newest first)', () {
      const sort = GallerySort.modifiedAtDesc();
      expect(sort.field, GallerySortField.modifiedAt);
      expect(sort.direction, GallerySortDirection.descending);
      expect(sort.sqlColumn, 'modified_at');
    });

    test('createdAt maps to created_at whitelist column', () {
      const sort = GallerySort(
        field: GallerySortField.createdAt,
        direction: GallerySortDirection.descending,
      );
      expect(sort.sqlColumn, 'created_at');
    });

    test(
      'imageDimensions maps to image_area token (expression expanded in SQL layer)',
      () {
        const sort = GallerySort(
          field: GallerySortField.imageDimensions,
          direction: GallerySortDirection.descending,
        );
        expect(sort.sqlColumn, 'image_area');
      },
    );

    test('defaultDirectionFor: times/size/dimensions desc, name asc', () {
      expect(
        GallerySort.defaultDirectionFor(GallerySortField.modifiedAt),
        GallerySortDirection.descending,
      );
      expect(
        GallerySort.defaultDirectionFor(GallerySortField.createdAt),
        GallerySortDirection.descending,
      );
      expect(
        GallerySort.defaultDirectionFor(GallerySortField.fileSize),
        GallerySortDirection.descending,
      );
      expect(
        GallerySort.defaultDirectionFor(GallerySortField.imageDimensions),
        GallerySortDirection.descending,
      );
      expect(
        GallerySort.defaultDirectionFor(GallerySortField.fileName),
        GallerySortDirection.ascending,
      );
    });

    test('withDefaultDirection builds sort with the field default', () {
      final byName = GallerySort.withDefaultDirection(
        GallerySortField.fileName,
      );
      expect(byName.field, GallerySortField.fileName);
      expect(byName.direction, GallerySortDirection.ascending);

      final byCreated = GallerySort.withDefaultDirection(
        GallerySortField.createdAt,
      );
      expect(byCreated.direction, GallerySortDirection.descending);
    });

    test('cacheKey distinguishes field and direction', () {
      expect(
        const GallerySort(
          field: GallerySortField.fileName,
          direction: GallerySortDirection.ascending,
        ).cacheKey,
        'fileName:ascending',
      );
      expect(
        const GallerySort(
          field: GallerySortField.fileName,
          direction: GallerySortDirection.descending,
        ).cacheKey,
        'fileName:descending',
      );
    });
  });

  group('GallerySort compareFiles', () {
    DateTime dt(int day) => DateTime(2026, 8, day);

    const byName = GallerySort(
      field: GallerySortField.fileName,
      direction: GallerySortDirection.ascending,
    );
    const bySize = GallerySort(
      field: GallerySortField.fileSize,
      direction: GallerySortDirection.descending,
    );

    int compare(
      GallerySort sort, {
      DateTime? modifiedA,
      DateTime? modifiedB,
      int? sizeA,
      int? sizeB,
      String? nameA,
      String? nameB,
      DateTime? createdA,
      DateTime? createdB,
      int? areaA,
      int? areaB,
    }) {
      return sort.compareFiles(
        modifiedAtA: modifiedA ?? dt(1),
        modifiedAtB: modifiedB ?? dt(1),
        fileSizeA: sizeA ?? 100,
        fileSizeB: sizeB ?? 100,
        fileNameA: nameA ?? 'a.png',
        fileNameB: nameB ?? 'b.png',
        createdAtA: createdA,
        createdAtB: createdB,
        imageAreaA: areaA,
        imageAreaB: areaB,
      );
    }

    test('modifiedAt descending puts newer first', () {
      const sort = GallerySort.modifiedAtDesc();
      expect(compare(sort, modifiedA: dt(2), modifiedB: dt(1)), isNegative);
      expect(compare(sort, modifiedA: dt(1), modifiedB: dt(2)), isPositive);
      expect(
        compare(
          sort,
          modifiedA: dt(1),
          modifiedB: dt(1),
          nameA: 'a.png',
          nameB: 'a.png',
        ),
        0,
      );
    });

    test('modifiedAt ascending puts older first', () {
      const sort = GallerySort(
        field: GallerySortField.modifiedAt,
        direction: GallerySortDirection.ascending,
      );
      expect(compare(sort, modifiedA: dt(1), modifiedB: dt(2)), isNegative);
    });

    test('fileName ascending ignores case', () {
      expect(compare(byName, nameA: 'b.png', nameB: 'A.png'), isPositive);
      expect(compare(byName, nameA: 'a.png', nameB: 'B.png'), isNegative);
    });

    test('fileName descending reverses order', () {
      const sort = GallerySort(
        field: GallerySortField.fileName,
        direction: GallerySortDirection.descending,
      );
      expect(compare(sort, nameA: 'a.png', nameB: 'b.png'), isPositive);
    });

    test('fileSize descending puts largest first', () {
      expect(compare(bySize, sizeA: 200, sizeB: 100), isNegative);
      expect(compare(bySize, sizeA: 100, sizeB: 200), isPositive);
    });

    test('fileSize ascending puts smallest first', () {
      const sort = GallerySort(
        field: GallerySortField.fileSize,
        direction: GallerySortDirection.ascending,
      );
      expect(compare(sort, sizeA: 100, sizeB: 200), isNegative);
    });

    test('tie on primary field falls back to case-insensitive file name', () {
      // 主字段（大小）相同 → 按文件名升序兜底，保证顺序可复现
      expect(
        compare(bySize, sizeA: 100, sizeB: 100, nameA: 'b.png', nameB: 'a.png'),
        isPositive,
      );
      expect(
        compare(bySize, sizeA: 100, sizeB: 100, nameA: 'A.png', nameB: 'a.png'),
        0,
      );
    });

    test('createdAt descending puts newer creation first', () {
      const sort = GallerySort(
        field: GallerySortField.createdAt,
        direction: GallerySortDirection.descending,
      );
      expect(compare(sort, createdA: dt(3), createdB: dt(1)), isNegative);
      expect(compare(sort, createdA: dt(1), createdB: dt(3)), isPositive);
    });

    test('createdAt ascending puts older creation first', () {
      const sort = GallerySort(
        field: GallerySortField.createdAt,
        direction: GallerySortDirection.ascending,
      );
      expect(compare(sort, createdA: dt(1), createdB: dt(2)), isNegative);
    });

    test('createdAt missing values sort as oldest', () {
      const sort = GallerySort(
        field: GallerySortField.createdAt,
        direction: GallerySortDirection.descending,
      );
      expect(
        compare(sort, createdA: null, createdB: dt(2)),
        isPositive, // null（按 DateTime(0)）在降序下排最后
      );
    });

    test('imageDimensions descending puts largest area first', () {
      const sort = GallerySort(
        field: GallerySortField.imageDimensions,
        direction: GallerySortDirection.descending,
      );
      // 1024×1024 = 1048576 > 832×1216 = 1011712
      expect(compare(sort, areaA: 1024 * 1024, areaB: 832 * 1216), isNegative);
      expect(compare(sort, areaA: 512 * 512, areaB: 832 * 1216), isPositive);
    });

    test('imageDimensions ascending puts smallest area first', () {
      const sort = GallerySort(
        field: GallerySortField.imageDimensions,
        direction: GallerySortDirection.ascending,
      );
      expect(compare(sort, areaA: 512 * 512, areaB: 832 * 1216), isNegative);
    });

    test('imageDimensions missing values sort as zero area', () {
      const sort = GallerySort(
        field: GallerySortField.imageDimensions,
        direction: GallerySortDirection.descending,
      );
      expect(compare(sort, areaA: null, areaB: 1024), isPositive);
    });

    test('compareFiles stays stable across identical keys', () {
      const sort = GallerySort.modifiedAtDesc();
      expect(compare(sort, nameA: 'a.png', nameB: 'a.png'), 0);
    });
  });
}
