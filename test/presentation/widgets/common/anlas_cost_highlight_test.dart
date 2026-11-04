import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/utils/asset_protection_guard.dart';
import 'package:nai_launcher/presentation/widgets/common/anlas_cost_badge.dart';
import 'package:nai_launcher/presentation/widgets/common/anlas_cost_dialog.dart';

class _Settings extends ShareImageSettingsNotifier {
  _Settings(this.enabled, [this.threshold = 50]);
  final int threshold;
  final bool enabled;
  @override
  ShareImageSettings build() => ShareImageSettings(
    warnHighAnlasCost: enabled,
    highAnlasCostThreshold: threshold,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final (cost, enabled, red) in [
    (49, true, false),
    (50, true, true),
    (90, true, true),
    (0, true, false),
    (90, false, false),
  ]) {
    testWidgets('cost $cost enabled=$enabled highlights high prices=$red', (
      t,
    ) async {
      final theme = ThemeData(colorScheme: const ColorScheme.light());
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            shareImageSettingsProvider.overrideWith(() => _Settings(enabled)),
            estimatedCostProvider.overrideWith((_) => cost),
            isBalanceInsufficientProvider.overrideWith((_) => false),
            anlasBalanceProvider.overrideWith((_) => 5000),
          ],
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(body: AnlasCostBadge(isGenerating: false)),
          ),
        ),
      );
      final box = t.widget<Container>(find.byType(Container));
      expect(
        (box.decoration! as BoxDecoration).color,
        red ? theme.colorScheme.error : theme.colorScheme.surface,
      );
      expect(find.text('$cost'), findsOneWidget);
    });
  }

  testWidgets('invalid cost is unavailable rather than a negative price', (
    t,
  ) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          shareImageSettingsProvider.overrideWith(() => _Settings(true)),
          estimatedCostProvider.overrideWith((_) => -3),
          isBalanceInsufficientProvider.overrideWith((_) => false),
          anlasBalanceProvider.overrideWith((_) => 5000),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AnlasCostBadge(isGenerating: false)),
        ),
      ),
    );
    expect(find.text('-3'), findsNothing);
    expect(find.text('—'), findsOneWidget);
  });

  for (final (cost, enabled, threshold, warns, canSend) in [
    (0, true, 50, false, true),
    (49, true, 50, false, true),
    (50, true, 50, true, true),
    (90, true, 50, true, true),
    (90, false, 50, false, true),
    (50, true, 75, false, true),
    (75, true, 75, true, true),
    (90, true, 0, false, true),
    (-3, false, 50, false, false),
  ]) {
    testWidgets('quote $cost, warning $enabled at $threshold', (t) async {
      int sends = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            shareImageSettingsProvider.overrideWith(
              () => _Settings(enabled, threshold),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () async {
                    if (await AssetProtectionGuard.validateAnlasCost(
                      context: context,
                      ref: ref,
                      cost: cost,
                    )) {
                      sends++;
                    }
                  },
                  child: const Text('Generate fixture'),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> tap(String label) async {
        await t.tap(find.text(label));
        await t.pumpAndSettle();
      }

      await tap('Generate fixture');
      final dialog = find.byType(AnlasCostDialog);
      if (warns) {
        expect(dialog, findsOneWidget);
        final warning = t.widget<AnlasCostDialog>(dialog);
        expect(warning.cost, cost);
        expect(warning.threshold, threshold);
        expect(sends, 0);
        await tap('Cancel');
        expect(sends, 0);
        expect(dialog, findsNothing);
        await tap('Generate fixture');
        await t.tapAt(const Offset(1, 1));
        await t.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(sends, 0);
        await tap('Generate fixture');
        await tap('Continue Generation');
      }
      expect(dialog, findsNothing);
      expect(sends, canSend ? 1 : 0);
    });
  }
}
