import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/anlas/anlas_balance_chip.dart';

void main() {
  Future<ColorFilter?> iconFilter(
    WidgetTester tester,
    ThemeData theme, {
    required int estimatedCost,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionNotifierProvider.overrideWith(
            _TestSubscriptionNotifier.new,
          ),
        ],
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: AnlasBalanceChip(
              compact: true,
              inline: true,
              estimatedCostOverride: estimatedCost,
            ),
          ),
        ),
      ),
    );
    return tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter;
  }

  for (final dark in [false, true]) {
    final theme = dark ? GeistTheme.dark : GeistTheme.light;
    final name = dark ? 'dark' : 'light';

    testWidgets('balance icon is black in light, white in dark ($name)', (
      tester,
    ) async {
      expect(
        await iconFilter(tester, theme, estimatedCost: 0),
        ColorFilter.mode(theme.colorScheme.onSurface, BlendMode.srcIn),
      );
    });

    testWidgets('balance icon turns error when insufficient ($name)', (
      tester,
    ) async {
      expect(
        await iconFilter(tester, theme, estimatedCost: 1),
        ColorFilter.mode(theme.colorScheme.error, BlendMode.srcIn),
      );
    });
  }
}

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  SubscriptionState build() {
    return const SubscriptionState.loaded(
      UserSubscription(tier: 1, active: true),
    );
  }
}
