import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/screens/image_comparison_screen.dart';
import 'package:nai_launcher/presentation/screens/slideshow_screen.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';

class _OfflineAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  testWidgets(
    'gallery routes forward selections and allow opening a bare link',
    (tester) async {
      final container = ProviderContainer(
        overrides: [authNotifierProvider.overrideWith(_OfflineAuth.new)],
      );
      final router = container.read(appRouterProvider);
      addTearDown(() {
        router.dispose();
        container.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final config = router.configuration;
      final selection = [
        LocalImageRecord(path: 'a.png', size: 1, modifiedAt: DateTime(2026)),
        LocalImageRecord(path: 'b.png', size: 1, modifiedAt: DateTime(2026)),
      ];
      for (final extra in [selection, null]) {
        for (final route in [AppRoutes.slideshow, AppRoutes.comparison]) {
          final matches = config.findMatch(
            Uri.parse('/local-gallery$route?initialIndex=1'),
            extra: extra,
          );
          expect(matches.isError, isFalse);
          final match = matches.last;
          final state = match.buildState(config, matches);
          final page = match.route.pageBuilder!(context, state) as MaterialPage;
          final child = (page.child as WindowChromePage).child;
          if (child is SlideshowScreen) {
            expect(route, AppRoutes.slideshow);
            expect(child.initialIndex, 1);
            expect(child.images, extra ?? isEmpty);
          } else {
            expect(route, AppRoutes.comparison);
            expect((child as ImageComparisonScreen).images, extra ?? isEmpty);
          }
        }
      }
    },
  );
}
