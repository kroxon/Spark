import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iskra/features/auth/register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Kontrolery do odczytywania tekstu z pól
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Zmienna do pokazywania kółka ładowania
  bool _isLoading = false;

  // Funkcja logowania
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
      // Logowanie za pomocą Firebase Auth
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
      // Wyświetlanie błędu, jeśli logowanie się nie powiedzie
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapAuthError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // Zawsze wyłączaj kółko ładowania na koniec
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
    } catch (error, stack) {
      debugPrint('Nieudane logowanie Google: $error');
      debugPrintStack(stackTrace: stack);
      final message = error is Exception ? error.toString() : 'Nie udało się zalogować przez Google. Spróbuj ponownie.';
      _showSnack(message);
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Tytuł
              Text(
                'Witaj w Iskrze',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Zaloguj się, aby kontynuować',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),

              // Pole na e-mail
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Hasło',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: _validatePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Nie pamiętasz hasła?'),
                ),
              ),

              // Przycisk logowania
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Zaloguj się'),
              ),
              const Spacer(),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'lub',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.login, color: Colors.redAccent),
                label: const Text('Kontynuuj z Google'),
              ),
              const SizedBox(height: 24),

              // Przycisk do przejścia na stronę rejestracji
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Nie masz konta?"),
                  TextButton(
              onPressed: _navigateToRegister,
                    child: const Text("Zarejestruj się"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}