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
import 'package:iskra/features/extras/presentation/pages/extras_page.dart';
import 'package:iskra/features/games/game_2048/presentation/pages/game_2048_page.dart';
import 'package:iskra/features/kpp/presentation/pages/kpp_menu_page.dart';
import 'package:iskra/features/kpp/presentation/pages/kpp_flashcards_page.dart';
import 'package:iskra/features/kpp/presentation/pages/kpp_exam_page.dart';
import 'package:iskra/features/fitness/presentation/pages/fitness_menu_page.dart';
import 'package:iskra/features/fitness/presentation/pages/fitness_test_page.dart';
import 'package:iskra/features/profile/presentation/pages/profile_page.dart';
import 'package:iskra/features/reports/presentation/pages/reports_page.dart';
import 'package:iskra/features/subscription/presentation/pages/subscription_page.dart';
import 'package:iskra/features/support/presentation/pages/help_center_page.dart';
import 'package:iskra/features/system_settings/presentation/pages/system_settings_page.dart';
import 'package:iskra/features/system_settings/presentation/pages/appearance_settings_page.dart';
import 'package:iskra/features/system_settings/presentation/pages/schedule_settings_page.dart';
import 'package:iskra/features/system_settings/presentation/pages/balances_settings_page.dart';
import 'package:iskra/features/onboarding/presentation/pages/onboarding_page.dart';

import 'package:iskra/features/auth/data/user_profile_repository.dart';

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
      GoRoute(
        path: AppRoutePath.onboarding,
        name: AppRouteName.onboarding,
        builder: (context, state) => const OnboardingPage(),
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
                path: AppRoutePath.extras,
                name: AppRouteName.extras,
                builder: (context, state) => const ExtrasPage(),
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
      // Full-screen settings hub (opened above the shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.settings,
        name: AppRouteName.settings,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SystemSettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final fade = Tween<double>(begin: 0, end: 1).animate(curve);
            final slide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curve);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      ),
      // Full-screen settings subpages (opened above the shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.settingsAppearance,
        name: AppRouteName.settingsAppearance,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const AppearanceSettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final fade = Tween<double>(begin: 0, end: 1).animate(curve);
            final slide = Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(curve);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.settingsSchedule,
        name: AppRouteName.settingsSchedule,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ScheduleSettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final fade = Tween<double>(begin: 0, end: 1).animate(curve);
            final slide = Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(curve);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.settingsBalances,
        name: AppRouteName.settingsBalances,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const BalancesSettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final fade = Tween<double>(begin: 0, end: 1).animate(curve);
            final slide = Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(curve);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.game2048,
        name: AppRouteName.game2048,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const Game2048Page(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.kppMenu,
        name: AppRouteName.kppMenu,
        builder: (context, state) => const KppMenuPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.kppFlashcards,
        name: AppRouteName.kppFlashcards,
        builder: (context, state) => const KppFlashcardsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.kppExam,
        name: AppRouteName.kppExam,
        builder: (context, state) => const KppExamPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutePath.fitnessMenu,
        name: AppRouteName.fitnessMenu,
        builder: (context, state) => const FitnessTestPage(),
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
      final isOnboardingRoute = location == AppRoutePath.onboarding;
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

      // Watch user profile
      final userProfileAsync = ref.watch(userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)));
      final userProfile = userProfileAsync.value;

      if (userProfileAsync.isLoading) {
        return null;
      }

      // Check if onboarding is needed
      if (userProfile != null && !userProfile.isOnboardingComplete && !isOnboardingRoute) {
        return AppRoutePath.onboarding;
      }

      if (isOnboardingRoute && userProfile != null && userProfile.isOnboardingComplete) {
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
