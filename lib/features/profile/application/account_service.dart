import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Handles sign-out and full account deletion (Firestore + Auth).
class AccountService {
  AccountService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get _currentUser => _auth.currentUser;

  Future<void> signOut() async {
    final providers = _currentUser?.providerData.map((e) => e.providerId).toList() ?? const [];
    // Best-effort Google disconnect to avoid auto-login on next start
    if (providers.contains('google.com') && !kIsWeb) {
      try {
        final google = GoogleSignIn();
        await google.signOut();
        await google.disconnect();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// Deletes only calendar entries in Firestore, keeping the user profile
  /// document, Firebase Auth account and session intact.
  Future<void> deleteUserDataOnly() async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika');
    }

    // Delete only known calendar-related subcollections
    await _deleteUserSubcollections(user.uid);

    // Keep user profile document, account and session; caller may refresh UI/state.
  }

  /// Deletes Firestore data and Firebase Auth account.
  /// [emailPassword] is required for password-based accounts when reauth is needed.
  Future<void> deleteAccount({String? emailPassword}) async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika');
    }

    // Capture provider ids before deletion to properly sign out providers.
    final providerIds = user.providerData.map((e) => e.providerId).toList(growable: false);

    await _reauthenticateIfRequired(user, emailPassword: emailPassword);

    // 1) Delete user subcollections (calendarEntries)
    await _deleteUserSubcollections(user.uid);

    // 2) Delete user profile document
    await _firestore.collection('users').doc(user.uid).delete().catchError((_) async {
      // If doc doesn't exist it's fine
    });

    // 3) Delete auth user
    await user.delete();

    // 4) Proactively sign out from providers and Firebase to clear local session
    if (providerIds.contains('google.com') && !kIsWeb) {
      try {
        final google = GoogleSignIn();
        await google.signOut();
        await google.disconnect();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> _reauthenticateIfRequired(
    User user, {
    String? emailPassword,
  }) async {
    try {
      // Attempt a cheap reload; if recent sign-in is valid, this should pass further deletes.
      await user.reload();
      return;
    } catch (_) {
      // Proceed to explicit reauth below.
    }

    final providerIds = user.providerData.map((e) => e.providerId).toSet();

    if (providerIds.contains('password')) {
      final email = user.email;
      if (email == null || (emailPassword == null || emailPassword.isEmpty)) {
        // Surface a clear error to caller to ask for a password.
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Wymagane ponowne logowanie hasłem.',
        );
      }
      final cred = EmailAuthProvider.credential(email: email, password: emailPassword);
      await user.reauthenticateWithCredential(cred);
      return;
    }

    if (providerIds.contains('google.com')) {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await user.reauthenticateWithProvider(provider);
        return;
      }
      // Mobile/desktop: use google_sign_in to obtain tokens for credential.
      final google = GoogleSignIn(scopes: const ['email'], forceCodeForRefreshToken: true);
      // Ensure fresh session
      try {
        await google.signOut();
      } catch (_) {}
      final account = await google.signIn();
      if (account == null) {
        throw FirebaseAuthException(
          code: 'user-cancelled',
          message: 'Anulowano ponowne logowanie Google.',
        );
      }
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    // Fallback: try to delete and let backend enforce recent login if required.
  }

  Future<void> _deleteUserSubcollections(String uid) async {
    final entries = await _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarEntries')
        .get();
    if (entries.docs.isEmpty) return;

    // Firestore batch limit is 500 operations.
    const chunk = 450;
    var index = 0;
    while (index < entries.docs.length) {
      final batch = _firestore.batch();
      final end = (index + chunk).clamp(0, entries.docs.length);
      for (final doc in entries.docs.getRange(index, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      index = end;
    }
  }
}
