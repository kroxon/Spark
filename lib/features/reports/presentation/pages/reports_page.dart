import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final profileAsync = ref.watch(
      userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)),
    );

    return profileAsync.when(
      data: (profile) {
        if (profile == null || !profile.isOnboardingComplete) {
          return const _OnboardingPrompt();
        }
        return _buildReportsView(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Błąd ładowania profilu: $error'),
      ),
    );
  }

  Widget _buildReportsView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Raporty w przygotowaniu',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sekcja raportów operacyjnych będzie wkrótce dostępna.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPrompt extends StatelessWidget {
  const _OnboardingPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Raporty niedostępne',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Aby zobaczyć raporty, musisz najpierw skonfigurować swoje podstawowe dane.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutePath.onboarding),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Rozpocznij konfigurację'),
            ),
          ],
        ),
      ),
    );
  }
}
