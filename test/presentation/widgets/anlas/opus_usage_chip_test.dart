import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/anlas/opus_usage_chip.dart';

void main() {
  Future<Color?> boltColor(
    WidgetTester tester,
    ThemeData theme, {
    required double percent,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generationParamsNotifierProvider.overrideWith(_V5Params.new),
          subscriptionNotifierProvider.overrideWith(
            () => _UsageSubscription(percent),
          ),
        ],
        child: MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: OpusUsageChip(compact: true, inline: true),
          ),
        ),
      ),
    );
    return tester.widget<Icon>(find.byIcon(Icons.bolt_outlined)).color;
  }

  for (final dark in [false, true]) {
    final theme = dark ? GeistTheme.dark : GeistTheme.light;
    final name = dark ? 'dark' : 'light';

    testWidgets('quota bolt uses primary blue ($name)', (tester) async {
      expect(
        await boltColor(tester, theme, percent: 60),
        theme.colorScheme.primary,
      );
    });

    testWidgets('quota bolt turns error when low ($name)', (tester) async {
      expect(
        await boltColor(tester, theme, percent: 2),
        theme.colorScheme.error,
      );
    });
  }
}

class _V5Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(model: ImageModels.animeDiffusionV5Full);
}

class _UsageSubscription extends SubscriptionNotifier {
  _UsageSubscription(this.percent);
  final double percent;

  @override
  SubscriptionState build() => SubscriptionState.loaded(
    UserSubscription(tier: 3, active: true, usage: OpusUsage(percent: percent)),
  );
}
