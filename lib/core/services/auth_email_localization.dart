import 'package:firebase_auth/firebase_auth.dart';

/// Ensures that Firebase Auth transactional e-mails are localized to Polish.
class AuthEmailLocalization {
  AuthEmailLocalization._();

  static String? _cachedLanguageCode;

  /// Sets Firebase Auth's e-mail language to Polish (pl) once per session.
  static Future<void> ensurePolish() async {
    if (_cachedLanguageCode == 'pl') {
      return;
    }
    await FirebaseAuth.instance.setLanguageCode('pl');
    _cachedLanguageCode = 'pl';
  }
}
