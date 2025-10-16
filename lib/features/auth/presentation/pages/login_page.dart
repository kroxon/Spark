import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iskra/common_widgets/app_primary_button.dart';
import 'package:iskra/common_widgets/app_text_field.dart';
import 'package:iskra/common_widgets/google_sign_in_button.dart';
import 'package:iskra/core/theme/app_colors.dart';
import 'package:iskra/core/theme/app_decorations.dart';
import 'package:iskra/features/auth/presentation/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await _handleUnverified(user);
        return;
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapAuthError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _navigateToRegister() async {
    if (_isLoading) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.setLanguageCode('pl');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sprawdź skrzynkę, wysłaliśmy link resetujący.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapAuthError(e))),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
        return;
      }

      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException (Google sign-in): ${e.code} ${e.message}');
      _showSnack(_mapAuthError(e));
    } on PlatformException catch (e, stack) {
      debugPrint('PlatformException (Google sign-in): ${e.code} ${e.message}');
      debugPrintStack(stackTrace: stack);
      _showSnack(_mapGooglePlatformError(e));
    } catch (error, stack) {
      debugPrint('Nieudane logowanie Google: $error');
      debugPrintStack(stackTrace: stack);
      _showSnack(_mapUnknownGoogleError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Wpisz adres e-mail.';
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Podaj poprawny adres e-mail.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hasło nie może być puste.';
    }
    if (value.length < 6) {
      return 'Hasło musi mieć min. 6 znaków.';
    }
    return null;
  }

  String _mapAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return 'Nie znaleziono konta o podanym e-mailu.';
      case 'wrong-password':
        return 'Hasło jest nieprawidłowe.';
      case 'invalid-email':
        return 'E-mail ma nieprawidłowy format.';
      case 'user-disabled':
        return 'To konto zostało zablokowane.';
      case 'too-many-requests':
        return 'Zbyt wiele prób. Spróbuj później.';
      default:
        return 'Logowanie nie powiodło się. Spróbuj ponownie.';
    }
  }

  String _mapGooglePlatformError(PlatformException exception) {
    switch (exception.code) {
      case GoogleSignIn.kNetworkError:
        return 'Nie udało się połączyć z Google. Sprawdź połączenie internetowe lub spróbuj ponownie za chwilę.';
      case GoogleSignIn.kSignInCanceledError:
        return 'Logowanie Google zostało anulowane.';
      case GoogleSignIn.kSignInFailedError:
        return 'Logowanie Google nie powiodło się. Spróbuj ponownie.';
      case GoogleSignIn.kSignInRequiredError:
        return 'Google wymaga ponownego logowania. Spróbuj ponownie.';
      default:
        return 'Wystąpił nieoczekiwany błąd podczas logowania Google. Spróbuj ponownie.';
    }
  }

  String _mapUnknownGoogleError(Object error) {
    return 'Nie udało się zalogować przez Google. Spróbuj ponownie.';
  }

  Future<void> _handleUnverified(User user) async {
    final email = user.email ?? 'twój adres e-mail';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (innerContext, setState) {
            return AlertDialog(
              title: const Text('Potwierdź adres e-mail'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Konto $email nie zostało jeszcze aktywowane.'),
                  const SizedBox(height: 12),
                  const Text('Otwórz mail z linkiem weryfikacyjnym, kliknij w przycisk, a następnie zaloguj się ponownie.'),
                  const SizedBox(height: 12),
                  const Text('Jeśli nie widzisz wiadomości, możesz wysłać ją jeszcze raz poniżej.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setState(() => isSending = true);
                          try {
                            await FirebaseAuth.instance.setLanguageCode('pl');
                            await user.sendEmailVerification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Wysłaliśmy ponownie link weryfikacyjny.')),
                              );
                            }
                          } on FirebaseAuthException {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nie udało się wysłać maila. Spróbuj ponownie.')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isSending = false);
                            }
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Wyślij ponownie'),
                ),
                FilledButton(
                  onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    await FirebaseAuth.instance.signOut();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: AppDecorations.elevatedSurface(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Icon(Icons.flash_on, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Witaj w Iskrze',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Zaloguj się, aby kontynuować',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.black.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            AppTextField(
                              label: 'E-mail',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              prefixIcon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 18),
                            AppTextField(
                              label: 'Hasło',
                              controller: _passwordController,
                              obscureText: true,
                              validator: _validatePassword,
                              prefixIcon: Icons.lock_outline,
                              autocorrect: false,
                              enableSuggestions: false,
                              enableObscureToggle: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            textStyle: theme.textTheme.labelLarge,
                          ),
                          child: const Text('Nie pamiętasz hasła?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppPrimaryButton(
                        label: 'Zaloguj się',
                        onPressed: _signIn,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.2))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'lub',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.2))),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GoogleSignInButton(
                        label: 'Kontynuuj z Google',
                        onPressed: _signInWithGoogle,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nie masz konta?',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black.withValues(alpha: 0.7)),
                          ),
                          TextButton(
                            onPressed: _navigateToRegister,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              textStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Zarejestruj się'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
