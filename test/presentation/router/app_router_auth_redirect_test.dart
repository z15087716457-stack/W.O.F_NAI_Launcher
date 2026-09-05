import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';

void main() {
  test('auth redirect waits while authentication is loading', () {
    expect(
      appAuthRedirect(
        authStatus: AuthStatus.loading,
        isAuthenticated: false,
        isGuest: false,
        matchedLocation: AppRoutes.home,
      ),
      isNull,
    );
  });

  test('auth redirect sends unauthenticated non-guests to login', () {
    expect(
      appAuthRedirect(
        authStatus: AuthStatus.unauthenticated,
        isAuthenticated: false,
        isGuest: false,
        matchedLocation: AppRoutes.home,
      ),
      AppRoutes.login,
    );
  });

  test('auth redirect lets guests use the app and keeps them out of login', () {
    expect(
      appAuthRedirect(
        authStatus: AuthStatus.unauthenticated,
        isAuthenticated: false,
        isGuest: true,
        matchedLocation: AppRoutes.home,
      ),
      isNull,
    );
    expect(
      appAuthRedirect(
        authStatus: AuthStatus.unauthenticated,
        isAuthenticated: false,
        isGuest: true,
        matchedLocation: AppRoutes.login,
      ),
      AppRoutes.home,
    );
  });

  test('authenticated users are redirected away from login', () {
    expect(
      appAuthRedirect(
        authStatus: AuthStatus.authenticated,
        isAuthenticated: true,
        isGuest: false,
        matchedLocation: AppRoutes.login,
      ),
      AppRoutes.home,
    );
  });
}
