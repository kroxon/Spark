import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iskra/features/auth/screens/login_page.dart';
import 'package:iskra/features/auth/screens/verify_email_page.dart';
import 'package:iskra/features/home/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Użytkownik NIE jest zalogowany, pokaż ekran logowania
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final user = snapshot.data!;
        final providers = user.providerData.map((info) => info.providerId).toSet();
        final requiresEmailVerification = providers.contains('password') || providers.contains('emailLink');

        if (requiresEmailVerification && !user.emailVerified) {
          return const VerifyEmailPage();
        }

        // Użytkownik JEST zalogowany, pokaż ekran główny
        return const HomePage();
      },
    );
  }
}
