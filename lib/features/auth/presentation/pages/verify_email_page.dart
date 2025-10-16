import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iskra/common_widgets/app_outlined_button.dart';
import 'package:iskra/common_widgets/app_primary_button.dart';
import 'package:iskra/core/theme/app_colors.dart';
import 'package:iskra/core/theme/app_decorations.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isChecking = false;
  bool _isResending = false;

  String? get _email => FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    final email = _email ?? 'twój adres e-mail';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _signOut();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('Potwierdź adres e-mail'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _signOut,
            tooltip: 'Wróć do logowania',
          ),
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
                        Container(
                          height: 80,
                          width: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Na adres $email wysłaliśmy link weryfikacyjny.',
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kliknij link w wiadomości, aby aktywować konto. Jeśli nie widzisz maila, sprawdź folder spam.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black.withValues(alpha: 0.72),
                              ),
                        ),
                        const SizedBox(height: 32),
                        AppPrimaryButton(
                          label: 'Sprawdź ponownie',
                          onPressed: _checkStatus,
                          isLoading: _isChecking,
                        ),
                        const SizedBox(height: 16),
                        AppOutlinedButton(
                          label: 'Wyślij ponownie link',
                          onPressed: _resendEmail,
                          isLoading: _isResending,
                          icon: const Icon(Icons.refresh, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _signOut,
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          child: const Text('Wyloguj się'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (!mounted) return;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adres e-mail potwierdzony!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jeszcze nie widzimy potwierdzenia. Spróbuj za chwilę.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await FirebaseAuth.instance.setLanguageCode('pl');
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wysłaliśmy nowy link weryfikacyjny.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  String _mapAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'too-many-requests':
        return 'Za dużo próśb o wysyłkę. Spróbuj ponownie później.';
      case 'network-request-failed':
        return 'Brak połączenia z siecią.';
      default:
        return 'Nie udało się wysłać maila. Spróbuj ponownie.';
    }
  }
}
