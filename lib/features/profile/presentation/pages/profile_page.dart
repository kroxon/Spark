import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Keep the Google logo consistent with the login button by reusing the
// asset from flutter_signin_button without pulling in its widget.
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/profile/application/account_service.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      final auth = ref.read(firebaseAuthProvider);
      final firestore = ref.read(firebaseFirestoreProvider);
      await AccountService(auth, firestore).signOut();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wylogować: $error')),
      );
    }
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firebaseFirestoreProvider);
    final user = auth.currentUser;
    if (user == null) return;

    final confirmOk = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        final confirmController = TextEditingController();
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doDelete() async {
              if (isDeleting) return;
              if (!formKey.currentState!.validate()) return;
              setState(() => isDeleting = true);
              try {
                await AccountService(auth, firestore).deleteAccount();
                if (!context.mounted) return;
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konto usunięte'),
                    content: const Text('Twoje konto i wszystkie dane zostały całkowicie usunięte z Iskry. Zostałeś wylogowany.'),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                // Now sign out after dialog
                await AccountService(auth, firestore).signOut();
                Navigator.of(context).pop(true);
              } on FirebaseAuthException catch (e) {
                if (e.code == 'partial-delete') {
                  // Data deleted, account may remain; sign out anyway.
                  await AccountService(auth, firestore).signOut();
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Dane usunięte'),
                      content: Text(e.message ?? 'Twoje dane zostały usunięte, ale konto wymaga świeżego logowania. Zostałeś wylogowany.'),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                } else {
                  final msg = _mapDeleteError(e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nie udało się usunąć konta: $e')),
                  );
                }
              } finally {
                if (context.mounted) setState(() => isDeleting = false);
              }
            }

            return AlertDialog(
              title: const Text('Usuń konto'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ta operacja jest nieodwracalna. Usuniemy wszystkie Twoje dane i konto w Iskrze.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Wpisz: USUŃ',
                        prefixIcon: Icon(Icons.delete_forever_outlined),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().toUpperCase() != 'USUŃ') {
                          return 'Aby kontynuować wpisz dokładnie: USUŃ';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Anuluj'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: isDeleting ? null : doDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: isDeleting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Usuń konto'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmOk == true && context.mounted) {
      // After deletion, navigate out
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmAndDeleteDataOnly(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firebaseFirestoreProvider);
    final user = auth.currentUser;
    if (user == null) return;

    final confirmOk = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        final confirmController = TextEditingController();
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doDelete() async {
              if (isDeleting) return;
              if (!formKey.currentState!.validate()) return;
              setState(() => isDeleting = true);
              try {
                await AccountService(auth, firestore).deleteUserDataOnly();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Twoje dane zostały usunięte. Konto pozostało nienaruszone.')),
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nie udało się usunąć danych: $e')),
                  );
                }
              } finally {
                if (context.mounted) setState(() => isDeleting = false);
              }
            }

            return AlertDialog(
              title: const Text('Usuń wpisy kalendarza'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usuniemy wszystkie Twoje wpisy z kalendarza. ' 
                        'Twoje konto i profil pozostaną bez zmian.'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Wpisz: USUŃ WPISY',
                        prefixIcon: Icon(Icons.delete_sweep_outlined),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().toUpperCase() != 'USUŃ WPISY') {
                          return 'Aby kontynuować wpisz dokładnie: USUŃ WPISY';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Anuluj'),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  onPressed: isDeleting ? null : doDelete,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: isDeleting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Usuń wpisy'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmOk == true && context.mounted) {
      // Stay on profile; optionally refresh state
    }
  }

  String _mapDeleteError(FirebaseAuthException e) {
    switch (e.code) {
      case 'requires-recent-login':
        return 'Dla bezpieczeństwa zaloguj się ponownie i spróbuj jeszcze raz.';
      case 'user-mismatch':
      case 'user-not-found':
        return 'Nie znaleziono konta lub nie jesteś zalogowany.';
      case 'invalid-credential':
      case 'invalid-password':
        return 'Nieprawidłowe dane logowania.';
      default:
        return 'Nie udało się usunąć konta. Spróbuj ponownie.';
    }
  }

  Future<void> _sendPasswordReset(BuildContext context, WidgetRef ref) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null || user.email == null) return;
    try {
      await FirebaseAuth.instance.setLanguageCode('pl');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wysłaliśmy link do zmiany hasła na Twój e-mail.')),
      );
    } on FirebaseAuthException catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się wysłać linku resetującego.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil użytkownika'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildHeader(context, user),
            ),
            const SizedBox(height: 24),

            // Konto
            _buildSectionTitle(context, 'Zarządzanie kontem'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Wyloguj się'),
              onTap: () => _signOut(context, ref),
            ),
            if (user?.providerData.any((p) => p.providerId == 'password') ?? false)
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: const Text('Zmień hasło'),
                subtitle: const Text('Otrzymasz link resetujący na e‑mail'),
                onTap: () => _sendPasswordReset(context, ref),
              ),

            const Divider(indent: 16, endIndent: 16, height: 24),

            // Strefa Niebezpieczna
            _buildSectionTitle(context, 'Strefa Niebezpieczna', color: theme.colorScheme.error),
            ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
              title: Text('Usuń wpisy kalendarza', style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Czyści wszystkie dane kalendarza, konto pozostaje.'),
              onTap: user == null ? null : () => _confirmAndDeleteDataOnly(context, ref),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
              title: Text('Usuń konto', style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Trwale usuwa konto i wszystkie dane.'),
              onTap: user == null ? null : () => _confirmAndDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // Small helper to keep section titles consistent with M3
  Widget _buildSectionTitle(BuildContext context, String title, {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color ?? theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final theme = Theme.of(context);
  final isGoogle = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  final title = (isGoogle && (user?.displayName?.isNotEmpty ?? false))
    ? user!.displayName!
    : (_primaryEmail(user) ?? 'Użytkownik Iskra');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              (user?.displayName?.isNotEmpty ?? false)
                  ? user!.displayName![0].toUpperCase()
                  : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U'),
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _primaryEmail(user) ?? 'Brak przypisanego e-maila',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String? _primaryEmail(User? user) {
    if (user == null) return null;
    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email;
    }
    for (final info in user.providerData) {
      final e = info.email;
      if (e != null && e.trim().isNotEmpty) {
        return e;
      }
    }
    return null;
  }
}
