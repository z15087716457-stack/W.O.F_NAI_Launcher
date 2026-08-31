import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/vibe_performance_diagnostics.dart';

void main() {
  group('VibePerformanceDiagnostics', () {
    test('shouldLog uses inclusive threshold comparison', () {
      const threshold = Duration(milliseconds: 16);

      expect(
        VibePerformanceDiagnostics.shouldLog(
          const Duration(milliseconds: 15),
          threshold,
        ),
        isFalse,
      );
      expect(
        VibePerformanceDiagnostics.shouldLog(threshold, threshold),
        isTrue,
      );
      expect(
        VibePerformanceDiagnostics.shouldLog(
          const Duration(milliseconds: 17),
          threshold,
        ),
        isTrue,
      );
    });

    test('severityFor classifies slow spans by user-visible impact', () {
      expect(
        VibePerformanceDiagnostics.severityFor(
          const Duration(milliseconds: 16),
        ),
        'frame',
      );
      expect(
        VibePerformanceDiagnostics.severityFor(
          const Duration(milliseconds: 50),
        ),
        'moderate',
      );
      expect(
        VibePerformanceDiagnostics.severityFor(
          const Duration(milliseconds: 100),
        ),
        'major',
      );
      expect(
        VibePerformanceDiagnostics.severityFor(
          const Duration(milliseconds: 500),
        ),
        'critical',
      );
    });

    test('formatDetails keeps metadata compact and omits null values', () {
      final longValue = 'x' * 140;

      final details = VibePerformanceDiagnostics.formatDetails({
        'entries': 42,
        'ids': ['a', 'b'],
        'duration': const Duration(milliseconds: 25),
        'missing': null,
        'long': longValue,
      });

      expect(details, contains('entries=42'));
      expect(details, contains('ids=2 items'));
      expect(details, contains('duration=25ms'));
      expect(details, isNot(contains('missing=')));
      expect(details, contains('long=${'x' * 117}...'));
    });

    test(
      'buildSlowSpanMessage includes operation, elapsed, severity, details',
      () {
        final message = VibePerformanceDiagnostics.buildSlowSpanMessage(
          'storage.getDisplayEntries',
          const Duration(milliseconds: 75),
          details: const {'cacheReady': true, 'entries': 12},
        );

        expect(message, contains('operation=storage.getDisplayEntries'));
        expect(message, contains('elapsed=75ms'));
        expect(message, contains('severity=moderate'));
        expect(message, contains('cacheReady=true'));
        expect(message, contains('entries=12'));
      },
    );

    test('measureSync returns the action result', () {
      final result = VibePerformanceDiagnostics.measureSync(
        'test.fast',
        () => 3,
        slowThreshold: const Duration(days: 1),
      );

      expect(result, 3);
    });
  });
}
