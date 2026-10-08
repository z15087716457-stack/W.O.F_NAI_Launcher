import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_filter_widgets.dart';
import '../library/library_test_helpers.dart';

void main() {
  testWidgets('counted chip and optional version menu remain interactive', (
    tester,
  ) async {
    var taps = 0;
    await pumpLibrary(
      tester,
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GalleryFilterChip(
              label: '全部',
              tooltip: '全部',
              active: true,
              count: 128,
              onTap: () => taps++,
            ),
            GalleryVersionSegment(
              active: (version: 'V4.5', variant: null),
              tooltip: '版本',
              allLabel: '全部',
              allVariantsLabel: '全部变体',
              showVariantMenu: false,
              onSelectAll: () => taps++,
              onSelectVersion: (v, f) => taps++,
            ),
          ],
        ),
      ),
    );
    expect(find.text('128'), findsOneWidget);
    await tester.tap(find.text('全部').first);
    expect(taps, 1);
    expect(find.byType(PopupMenuButton<String?>), findsNothing);
    await tester.tap(find.text('V5'));
    expect(taps, 2);
  });
}
