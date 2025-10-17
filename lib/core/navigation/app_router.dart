import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/core/navigation/app_shell.dart';
import 'package:iskra/core/navigation/nav_destinations.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/analytics/presentation/pages/analytics_page.dart';
import 'package:iskra/features/auth/presentation/pages/login_page.dart';
import 'package:iskra/features/auth/presentation/pages/register_page.dart';
import 'package:iskra/features/auth/presentation/pages/verify_email_page.dart';
import 'package:iskra/features/home/presentation/pages/home_page.dart';
import 'package:iskra/features/notes/presentation/pages/notes_page.dart';
import 'package:iskra/features/profile/presentation/pages/profile_page.dart';
import 'package:iskra/features/reports/presentation/pages/reports_page.dart';
import 'package:iskra/features/subscription/presentation/pages/subscription_page.dart';
import 'package:iskra/features/support/presentation/pages/help_center_page.dart';
import 'package:iskra/features/system_settings/presentation/pages/system_settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.userChanges();
});

final routerRefreshProvider = Provider<_RouterRefreshStream>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final notifier = _RouterRefreshStream(auth.userChanges());
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final refreshListenable = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutePath.schedule,
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: AppRoutePath.authLogin,
        name: AppRouteName.authLogin,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePath.authRegister,
        name: AppRouteName.authRegister,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutePath.authVerify,
        name: AppRouteName.authVerify,
        builder: (context, state) => const VerifyEmailPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePath.schedule,
                name: AppRouteName.schedule,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePath.statistics,
                name: AppRouteName.statistics,
                builder: (context, state) => const AnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePath.notes,
                name: AppRouteName.notes,
                builder: (context, state) => const NotesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePath.settings,
                name: AppRouteName.settings,
                builder: (context, state) => const SystemSettingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePath.reports,
                name: AppRouteName.reports,
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePath.subscription,
                name: AppRouteName.subscription,
                builder: (context, state) => const SubscriptionPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePath.help,
                name: AppRouteName.help,
                builder: (context, state) => const HelpCenterPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.profile,
        name: AppRouteName.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final user = authState.value;

      if (authState.isLoading) {
        return null;
      }

      if (authState.hasError) {
        return AppRoutePath.authLogin;
      }

      if (user == null) {
        return isAuthRoute ? null : AppRoutePath.authLogin;
      }

      final providerIds = user.providerData.map((info) => info.providerId).toSet();
      final requiresVerification =
          (providerIds.contains('password') || providerIds.contains('emailLink')) && !user.emailVerified;

      if (requiresVerification) {
        return state.matchedLocation == AppRoutePath.authVerify ? null : AppRoutePath.authVerify;
      }

      if (isAuthRoute) {
        return AppSections.schedule.path;
      }

      return null;
    },
  );
});

class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
