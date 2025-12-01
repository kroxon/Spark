import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/core/navigation/app_router.dart';
import 'package:iskra/core/theme/app_theme_type.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  const fallback = ThemeMode.light;
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return fallback;
      }

      final profileAsync = ref.watch(
        userProfileProvider(
          UserProfileRequest(uid: user.uid, email: user.email),
        ),
      );

      return profileAsync.maybeWhen(
        data: (profile) => profile.themeMode,
        orElse: () => fallback,
      );
    },
    loading: () => fallback,
    error: (_, __) => fallback,
  );
});

final appThemeProvider = Provider<AppThemeType>((ref) {
  const fallback = AppThemeType.defaultRed;
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return fallback;
      }

      final profileAsync = ref.watch(
        userProfileProvider(
          UserProfileRequest(uid: user.uid, email: user.email),
        ),
      );

      return profileAsync.maybeWhen(
        data: (profile) => profile.appTheme,
        orElse: () => fallback,
      );
    },
    loading: () => fallback,
    error: (_, __) => fallback,
  );
});

final themePreferencesControllerProvider = Provider<ThemePreferencesController>(
  (ref) {
    return ThemePreferencesController(ref);
  },
);

class ThemePreferencesController {
  ThemePreferencesController(this._ref);

  final Ref _ref;

  Future<void> setThemeMode(ThemeMode mode) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika.');
    }

    final repository = _ref.read(userProfileRepositoryProvider);
    await repository.updateThemeMode(uid: user.uid, themeMode: mode);
  }

  Future<void> setAppTheme(AppThemeType theme) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika.');
    }

    final repository = _ref.read(userProfileRepositoryProvider);
    await repository.updateAppTheme(uid: user.uid, appTheme: theme);
  }

  Future<void> toggleThemeMode() async {
    final currentMode = _ref.read(themeModeProvider);
    final nextMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}
