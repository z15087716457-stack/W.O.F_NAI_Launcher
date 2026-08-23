import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/gallery/date_range_picker_dialog.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 8, day);

  group('DateRangeSelectionState state machine', () {
    test('empty → tap a day → single day', () {
      const state = DateRangeSelectionState();
      final result = state.tap(d(5));

      expect(result.hasSelection, isTrue);
      expect(result.isSingleDay, isTrue);
      expect(result.start, d(5));
      expect(result.end, d(5));
    });

    test('single day → tap another day → full range including both ends', () {
      final state = DateRangeSelectionState(start: d(5), end: d(5));

      final forward = state.tap(d(9));
      expect(forward.start, d(5));
      expect(forward.end, d(9));
      expect(forward.isRange, isTrue);

      // 反向选（后点更早的一天）同样成立
      final state2 = DateRangeSelectionState(start: d(9), end: d(9));
      final backward = state2.tap(d(3));
      expect(backward.start, d(3));
      expect(backward.end, d(9));
      expect(backward.isRange, isTrue);
    });

    test('single day → tap the same day → keeps the single day', () {
      final state = DateRangeSelectionState(start: d(5), end: d(5));
      final result = state.tap(d(5));

      expect(result.isSingleDay, isTrue);
      expect(result.start, d(5));
      expect(result.end, d(5));
    });

    test('full range → tap ANY day → clears everything', () {
      final state = DateRangeSelectionState(start: d(3), end: d(9));

      // 范围内、端点、范围外，任意一天都清空
      final inside = state.tap(d(6));
      expect(inside.hasSelection, isFalse);

      final endpoint = state.tap(d(3));
      expect(endpoint.hasSelection, isFalse);

      final outside = state.tap(d(20));
      expect(outside.hasSelection, isFalse);
    });

    test('cleared range can start a new single day selection', () {
      final state = DateRangeSelectionState(start: d(3), end: d(9));
      final cleared = state.tap(d(20));
      final restart = cleared.tap(d(12));

      expect(restart.isSingleDay, isTrue);
      expect(restart.start, d(12));
      expect(restart.end, d(12));
    });

    test('isInRange includes both endpoints', () {
      final state = DateRangeSelectionState(start: d(3), end: d(9));

      expect(state.isInRange(d(3)), isTrue);
      expect(state.isInRange(d(9)), isTrue);
      expect(state.isInRange(d(6)), isTrue);
      expect(state.isInRange(d(2)), isFalse);
      expect(state.isInRange(d(10)), isFalse);
    });

    test('isSelectedDay marks only the endpoints', () {
      final state = DateRangeSelectionState(start: d(3), end: d(9));

      expect(state.isSelectedDay(d(3)), isTrue);
      expect(state.isSelectedDay(d(9)), isTrue);
      expect(state.isSelectedDay(d(6)), isFalse);
    });

    test('empty state reports no selection and no range', () {
      const state = DateRangeSelectionState();

      expect(state.hasSelection, isFalse);
      expect(state.isSingleDay, isFalse);
      expect(state.isRange, isFalse);
      expect(state.isInRange(d(1)), isFalse);
    });
  });
}
