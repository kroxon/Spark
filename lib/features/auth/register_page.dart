import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iskra/common_widgets/app_primary_button.dart';
import 'package:iskra/common_widgets/app_text_field.dart';
import 'package:iskra/core/theme/app_colors.dart';
import 'package:iskra/core/theme/app_decorations.dart';
import 'package:iskra/core/services/auth_email_localization.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        try {
          await AuthEmailLocalization.ensurePolish();
          await user.sendEmailVerification();
        } on FirebaseAuthException catch (e) {
          _showMessage(_mapAuthError(e));
        }
      }

      await _showVerificationDialog(email);
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapAuthError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showVerificationDialog(String email) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: AppDecorations.dialogShape(),
          title: const Text('Potwierdź adres e-mail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wysłaliśmy wiadomość z potwierdzeniem na $email.'),
              const SizedBox(height: 12),
              const Text('Otwórz mail, kliknij w przycisk aktywacyjny i dopiero potem zaloguj się w aplikacji.'),
              const SizedBox(height: 12),
              const Text('Jeśli nie widzisz wiadomości, sprawdź folder spam lub użyj opcji „Wyślij ponownie” podczas logowania.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Rozumiem'),
            ),
          ],
        );
      },
    );
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
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Hasło nie może być puste.';
    }
    if (password.length < 6) {
      return 'Hasło musi mieć min. 6 znaków.';
    }
    return null;
  }

  String? _validateRepeatPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Powtórz hasło.';
    }
    if (value != _passwordController.text) {
      return 'Hasła muszą być takie same.';
    }
    return null;
  }

  String _mapAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'email-already-in-use':
        return 'Ten e-mail jest już zajęty.';
      case 'invalid-email':
        return 'E-mail ma nieprawidłowy format.';
      case 'operation-not-allowed':
        return 'Rejestracja e-mailowa jest wyłączona.';
      case 'weak-password':
        return 'Hasło jest zbyt słabe.';
      case 'too-many-requests':
        return 'Za dużo prób. Odczekaj chwilę i spróbuj ponownie.';
      default:
        return 'Rejestracja nie powiodła się. Spróbuj ponownie.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Rejestracja'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: AppDecorations.elevatedSurface(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Dołącz do Iskry',
                        textAlign: TextAlign.left,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Podaj dane logowania, aby utworzyć konto.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.black.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(height: 32),
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
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 20),
                            AppTextField(
                              label: 'Powtórz hasło',
                              controller: _repeatPasswordController,
                              obscureText: true,
                              validator: _validateRepeatPassword,
                              prefixIcon: Icons.lock_reset,
                              autocorrect: false,
                              enableSuggestions: false,
                              enableObscureToggle: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppPrimaryButton(
                        label: 'Utwórz konto',
                        onPressed: _register,
                        isLoading: _isLoading,
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
