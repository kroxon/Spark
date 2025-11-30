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

  /// Deletes Firestore data and attempts to delete Firebase Auth account.
  /// If account deletion requires recent login, data is still deleted and user is signed out.
  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Brak zalogowanego użytkownika');
    }

    // Capture provider ids before deletion to properly sign out providers.
    final providerIds = user.providerData.map((e) => e.providerId).toList(growable: false);

    // Always delete user data first
    await _deleteUserSubcollections(user.uid);
    await _firestore.collection('users').doc(user.uid).delete().catchError((_) async {
      // If doc doesn't exist it's fine
    });

    // Try to delete auth user; if it requires recent login, still sign out.
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Data deleted, but account remains; inform user.
        throw FirebaseAuthException(
          code: 'partial-delete',
          message: 'Dane zostały usunięte, ale konto wymaga świeżego logowania. Zostałeś wylogowany.',
        );
      } else {
        rethrow;
      }
    }

    // If account deletion succeeded, do not sign out here; caller will handle it after showing dialog.
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
