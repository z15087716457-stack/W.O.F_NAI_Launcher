import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/auth/subscription_expiry_text.dart';

void main() {
  Widget buildText(int expiresAt, {bool includeDate = true}) => MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SubscriptionExpiryText(
        expiresAt: expiresAt,
        includeDate: includeDate,
      ),
    ),
  );

  testWidgets('共享到期文本：临期带日期与剩余天数', (tester) async {
    final expiry =
        DateTime.now().add(const Duration(days: 5)).millisecondsSinceEpoch ~/
        1000;
    await tester.pumpWidget(buildText(expiry));
    await tester.pumpAndSettle();

    expect(find.textContaining('到期 '), findsOneWidget);
    expect(find.textContaining('剩 5 天'), findsOneWidget);
  });

  testWidgets('共享到期文本：已过期仍显示有效日期', (tester) async {
    final expiry = DateTime.now().subtract(const Duration(days: 2));
    await tester.pumpWidget(buildText(expiry.millisecondsSinceEpoch ~/ 1000));
    await tester.pumpAndSettle();

    expect(find.textContaining('到期 '), findsOneWidget);
    expect(find.textContaining('已过期'), findsOneWidget);
  });

  testWidgets('共享到期文本：服务端哨兵时间戳不显示 1-01-01', (tester) async {
    // 没有有效订阅的账号，服务端下发 -62135596800（0001-01-01T00:00:00Z）
    await tester.pumpWidget(buildText(-62135596800));
    await tester.pumpAndSettle();

    expect(find.text('已过期'), findsOneWidget);
    expect(find.textContaining('01-01'), findsNothing);
  });

  testWidgets('共享到期文本：includeDate=false 不带到期前缀', (tester) async {
    final expiry =
        DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
        1000;
    await tester.pumpWidget(buildText(expiry, includeDate: false));
    await tester.pumpAndSettle();

    expect(find.textContaining('到期 '), findsNothing);
    expect(find.textContaining('剩 30 天'), findsOneWidget);
  });
}
