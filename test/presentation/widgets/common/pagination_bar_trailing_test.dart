import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/pagination_bar.dart';

void main() {
  Widget buildSubject({required bool compact}) {
    final pagination = PaginationBar(
      currentPage: 0,
      totalPages: 2,
      totalItems: 20,
      compact: compact,
      trailing: const Text('quality-control'),
      onPageChanged: (_) {},
    );
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: compact ? SizedBox(width: 320, child: pagination) : pagination,
      ),
    );
  }

  testWidgets('full layout renders trailing content', (tester) async {
    await tester.pumpWidget(buildSubject(compact: false));

    expect(find.text('quality-control'), findsOneWidget);
  });

  testWidgets('compact layout renders trailing content', (tester) async {
    await tester.pumpWidget(buildSubject(compact: true));

    expect(find.text('quality-control'), findsOneWidget);
  });
}
