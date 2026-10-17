import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/widgets/anlas/opus_usage_chip.dart';

void main() {
  Future<Color?> boltColor(
    WidgetTester tester,
    ThemeData theme, {
    required double percent,
    double purchasedPercent = 0,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generationParamsNotifierProvider.overrideWith(_V5Params.new),
          subscriptionNotifierProvider.overrideWith(
            () => _UsageSubscription(percent, purchasedPercent),
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

    testWidgets('quota bolt turns yellow before the red threshold ($name)', (
      tester,
    ) async {
      expect(
        await boltColor(tester, theme, percent: 10),
        UiColors.fromTheme(theme).warn,
      );
    });

    testWidgets(
      'backup quota is purple and displays its own remainder ($name)',
      (tester) async {
        expect(
          await boltColor(tester, theme, percent: 0, purchasedPercent: 200.5),
          UiColors.fromTheme(theme).quotaReserve,
        );
        expect(find.text('200.5%'), findsOneWidget);
        expect(find.text('0%'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('regular quota stays first while backup is available ($name)', (
      tester,
    ) async {
      expect(
        await boltColor(tester, theme, percent: 2, purchasedPercent: 200),
        theme.colorScheme.error,
      );
      expect(find.text('2%'), findsOneWidget);
    });

    testWidgets(
      'backup bar stays still while regular quota recharges ($name)',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            generationParamsNotifierProvider.overrideWith(_V5Params.new),
            subscriptionNotifierProvider.overrideWith(
              () => _UsageSubscription(0, 150),
            ),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(subscriptionNotifierProvider.notifier);
        void publish(double regular) {
          notifier.state = SubscriptionState.loaded(
            UserSubscription(
              tier: 3,
              active: true,
              usage: OpusUsage(
                percent: regular,
                purchasedPercent: 150,
                timeUntilNextPercent: 90,
              ),
            ),
          );
        }

        publish(0);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme,
              home: const Scaffold(body: OpusUsageChip()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('150%'), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
        publish(1);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('1%'), findsOneWidget);
        expect(tester.hasRunningAnimations, isTrue);
        publish(0);
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.text('150%'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

class _V5Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(model: ImageModels.animeDiffusionV5Full);
}

class _UsageSubscription extends SubscriptionNotifier {
  _UsageSubscription(this.percent, this.purchasedPercent);
  final double percent;
  final double purchasedPercent;

  @override
  SubscriptionState build() => SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      usage: OpusUsage(percent: percent, purchasedPercent: purchasedPercent),
    ),
  );
}
