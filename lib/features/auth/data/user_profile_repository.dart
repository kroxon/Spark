import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/shift_color_palette.dart';

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
    case ThemeMode.light:
      return 'light';
  }
}

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
    default:
      return ThemeMode.light;
  }
}

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<void> ensureProfileExists({required String uid, String? email}) async {
    final docRef = _doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      return;
    }

    final defaultProfile = UserProfile(
      uid: uid,
      email: email ?? '',
      subscriptionPlan: 'free',
      shiftHistory: [
        ShiftAssignment(shiftId: 2, startDate: DateTime(2024, 1, 1)),
      ],
      standardVacationHours: 208,
      additionalVacationHours: 104,
      themeMode: ThemeMode.light,
      overtimeIndicatorThresholdHours:
          UserProfile.defaultOvertimeIndicatorThresholdHours,
    );

    await docRef.set(_UserProfileDto.fromDomain(defaultProfile).toFirestore());
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return _UserProfileDto.fromFirestore(snapshot).toDomain(uid);
    });
  }

  Future<void> updateThemeMode({
    required String uid,
    required ThemeMode themeMode,
  }) {
    return _doc(uid).set({
      'themeMode': _themeModeToString(themeMode),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateOvertimeIndicatorThreshold({
    required String uid,
    required double hours,
  }) {
    return _doc(uid).set({
      'overtimeIndicatorThresholdHours': hours,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return UserProfileRepository(firestore);
});

final userProfileProvider =
    StreamProvider.family<UserProfile, UserProfileRequest>((
      ref,
      request,
    ) async* {
      final repository = ref.watch(userProfileRepositoryProvider);
      await repository.ensureProfileExists(
        uid: request.uid,
        email: request.email,
      );
      await for (final profile in repository.watchProfile(request.uid)) {
        if (profile != null) {
          yield profile;
        }
      }
    });

@immutable
class UserProfileRequest {
  const UserProfileRequest({required this.uid, this.email});

  final String uid;
  final String? email;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfileRequest && other.uid == uid && other.email == email;
  }

  @override
  int get hashCode => Object.hash(uid, email);
}

class _UserProfileDto {
  _UserProfileDto({
    required this.email,
    required this.subscriptionPlan,
    required this.shiftHistory,
    required this.standardVacationHours,
    required this.additionalVacationHours,
    required this.shiftColorPalette,
    required this.themeMode,
    required this.overtimeIndicatorThresholdHours,
  });

  final String email;
  final String subscriptionPlan;
  final List<ShiftAssignment> shiftHistory;
  final double standardVacationHours;
  final double additionalVacationHours;
  final ShiftColorPalette shiftColorPalette;
  final ThemeMode themeMode;
  final double overtimeIndicatorThresholdHours;

  factory _UserProfileDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('User profile document ${snapshot.id} has no data');
    }

    final history = <ShiftAssignment>[];
    final historyData = data['shiftHistory'] as List<dynamic>?;
    if (historyData != null) {
      for (final item in historyData) {
        if (item is Map<String, dynamic>) {
          final shiftId = item['shiftId'] as int?;
          final start = item['startDate'] as Timestamp?;
          if (shiftId != null && start != null) {
            history.add(
              ShiftAssignment(shiftId: shiftId, startDate: start.toDate()),
            );
          }
        }
      }
    }

    final paletteData = data['shiftColorPalette'] as Map<String, dynamic>?;
    final palette = paletteData == null
        ? ShiftColorPalette.defaults
        : ShiftColorPalette(
            shift1: Color(
              (paletteData['shift1'] as int?) ??
                  ShiftColorPalette.defaults.shift1.toARGB32(),
            ),
            shift2: Color(
              (paletteData['shift2'] as int?) ??
                  ShiftColorPalette.defaults.shift2.toARGB32(),
            ),
            shift3: Color(
              (paletteData['shift3'] as int?) ??
                  ShiftColorPalette.defaults.shift3.toARGB32(),
            ),
          );

    return _UserProfileDto(
      email: (data['email'] as String?) ?? '',
      subscriptionPlan: (data['subscriptionPlan'] as String?) ?? 'free',
      shiftHistory: history,
      standardVacationHours:
          (data['standardVacationHours'] as num?)?.toDouble() ?? 0,
      additionalVacationHours:
          (data['additionalVacationHours'] as num?)?.toDouble() ?? 0,
      shiftColorPalette: palette,
      themeMode: _themeModeFromString(data['themeMode'] as String?),
      overtimeIndicatorThresholdHours:
          (data['overtimeIndicatorThresholdHours'] as num?)?.toDouble() ??
          UserProfile.defaultOvertimeIndicatorThresholdHours,
    );
  }

  factory _UserProfileDto.fromDomain(UserProfile profile) {
    return _UserProfileDto(
      email: profile.email,
      subscriptionPlan: profile.subscriptionPlan,
      shiftHistory: profile.shiftHistory,
      standardVacationHours: profile.standardVacationHours,
      additionalVacationHours: profile.additionalVacationHours,
      shiftColorPalette: profile.shiftColorPalette,
      themeMode: profile.themeMode,
      overtimeIndicatorThresholdHours: profile.overtimeIndicatorThresholdHours,
    );
  }

  UserProfile toDomain(String uid) {
    return UserProfile(
      uid: uid,
      email: email,
      subscriptionPlan: subscriptionPlan,
      shiftHistory: shiftHistory,
      standardVacationHours: standardVacationHours,
      additionalVacationHours: additionalVacationHours,
      shiftColorPalette: shiftColorPalette,
      themeMode: themeMode,
      overtimeIndicatorThresholdHours: overtimeIndicatorThresholdHours,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'subscriptionPlan': subscriptionPlan,
      'standardVacationHours': standardVacationHours,
      'additionalVacationHours': additionalVacationHours,
      'shiftHistory': shiftHistory
          .map(
            (assignment) => {
              'shiftId': assignment.shiftId,
              'startDate': Timestamp.fromDate(assignment.startDate),
            },
          )
          .toList(),
      'shiftColorPalette': {
        'shift1': shiftColorPalette.shift1.toARGB32(),
        'shift2': shiftColorPalette.shift2.toARGB32(),
        'shift3': shiftColorPalette.shift3.toARGB32(),
      },
      'themeMode': _themeModeToString(themeMode),
      'overtimeIndicatorThresholdHours': overtimeIndicatorThresholdHours,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
