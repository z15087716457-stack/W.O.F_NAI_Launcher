import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/anlas_cost_badge.dart';

void main() {
  group('AnlasCostBadge', () {
    testWidgets('hides when generating', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFreeGenerationProvider.overrideWith((ref) => false),
            estimatedCostProvider.overrideWith((ref) => 10),
            isBalanceInsufficientProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnlasCostBadge(isGenerating: true)),
          ),
        ),
      );

      expect(find.byType(Container), findsNothing);
      expect(find.text('10'), findsNothing);
    });

    testWidgets('shows 0 when free', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFreeGenerationProvider.overrideWith((ref) => true),
            estimatedCostProvider.overrideWith((ref) => 0),
            isBalanceInsufficientProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnlasCostBadge(isGenerating: false)),
          ),
        ),
      );

      // 官网风格：消耗为 0 也照常显示深色小框
      expect(find.byType(Container), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows cost when not generating and not free', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFreeGenerationProvider.overrideWith((ref) => false),
            estimatedCostProvider.overrideWith((ref) => 10),
            isBalanceInsufficientProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnlasCostBadge(isGenerating: false)),
          ),
        ),
      );

      expect(find.byType(Container), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows error color when balance insufficient', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFreeGenerationProvider.overrideWith((ref) => false),
            estimatedCostProvider.overrideWith((ref) => 100),
            isBalanceInsufficientProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(error: Colors.red),
            ),
            home: const Scaffold(body: AnlasCostBadge(isGenerating: false)),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.red));
    });

    testWidgets('shows dark chip when balance sufficient', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFreeGenerationProvider.overrideWith((ref) => false),
            estimatedCostProvider.overrideWith((ref) => 5),
            isBalanceInsufficientProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                inverseSurface: Colors.black87,
              ),
            ),
            home: const Scaffold(body: AnlasCostBadge(isGenerating: false)),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.black87));
    });
  });
}
