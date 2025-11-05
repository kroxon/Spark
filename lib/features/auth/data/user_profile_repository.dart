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
      onDutyIndicatorColor: Colors.yellow.shade400,
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

  Future<void> updateOnDutyIndicatorColor({
    required String uid,
    required int color,
  }) {
    return _doc(uid).set({
      'onDutyIndicatorColor': color,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateVacationHours({
    required String uid,
    required double standardVacationHours,
    required double additionalVacationHours,
  }) {
    return _doc(uid).set({
      'standardVacationHours': standardVacationHours,
      'additionalVacationHours': additionalVacationHours,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateShiftColorPalette({
    required String uid,
    int? shift1,
    int? shift2,
    int? shift3,
  }) async {
    final update = <String, dynamic>{};
    final colors = <String, dynamic>{};
    if (shift1 != null) colors['shift1'] = shift1;
    if (shift2 != null) colors['shift2'] = shift2;
    if (shift3 != null) colors['shift3'] = shift3;
    if (colors.isNotEmpty) update['shiftColorPalette'] = colors;
    update['updatedAt'] = FieldValue.serverTimestamp();
    if (colors.isEmpty) return; // nothing to update
    await _doc(uid).set(update, SetOptions(merge: true));
  }

  Future<void> resetShiftColorPalette({required String uid}) {
    return _doc(uid).set({
      'shiftColorPalette': {
        'shift1': ShiftColorPalette.defaults.shift1.value,
        'shift2': ShiftColorPalette.defaults.shift2.value,
        'shift3': ShiftColorPalette.defaults.shift3.value,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateShiftHistory({
    required String uid,
    required List<ShiftAssignment> assignments,
  }) async {
    // Ensure normalized month-only UTC dates
    final payload = assignments
        .map((a) => {
              'shiftId': a.shiftId,
              'startDate': Timestamp.fromDate(
                DateTime.utc(a.startDate.year, a.startDate.month, 1),
              ),
            })
        .toList()
      ..sort((a, b) => (a['startDate'] as Timestamp)
          .toDate()
          .compareTo((b['startDate'] as Timestamp).toDate()));

    await _doc(uid).set({
      'shiftHistory': payload,
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
    required this.onDutyIndicatorColor,
  });

  final String email;
  final String subscriptionPlan;
  final List<ShiftAssignment> shiftHistory;
  final double standardVacationHours;
  final double additionalVacationHours;
  final ShiftColorPalette shiftColorPalette;
  final ThemeMode themeMode;
  final double overtimeIndicatorThresholdHours;
  final Color onDutyIndicatorColor;

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
          // Be tolerant to Firestore numeric type (num) and cast safely
          final raw = item['shiftId'];
          int? shiftId;
          if (raw is num) shiftId = raw.toInt();
          final startDate = _parseShiftStart(item);
          if (shiftId != null && startDate != null) {
            history.add(ShiftAssignment(shiftId: shiftId, startDate: startDate));
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
      onDutyIndicatorColor: Color(
        (data['onDutyIndicatorColor'] as int?) ?? Colors.yellow.shade400.value,
      ),
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
      onDutyIndicatorColor: profile.onDutyIndicatorColor,
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
      onDutyIndicatorColor: onDutyIndicatorColor,
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
      'onDutyIndicatorColor': onDutyIndicatorColor.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

DateTime? _parseShiftStart(Map<String, dynamic> item) {
  // Preferred: Firestore Timestamp under 'startDate'
  final ts = item['startDate'];
  if (ts is Timestamp) {
    final d = ts.toDate();
    return DateTime(d.year, d.month, 1);
  }

  // Fallback: String year-month under 'startYearMonth' or 'start'
  String? ym = item['startYearMonth'] as String? ?? item['start'] as String?;
  if (ym != null) {
    ym = ym.trim().toLowerCase();
    // Try formats: YYYY-MM or YYYY/MM
    final m1 = RegExp(r'^(\d{4})[-/](\d{1,2})$').firstMatch(ym);
    if (m1 != null) {
      final year = int.tryParse(m1.group(1)!);
      final month = int.tryParse(m1.group(2)!);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return DateTime(year, month, 1);
      }
    }
    // Try Polish month name formats: "styczeń 2024" or "styczen 2024"
    final nameToMonth = {
      'styczen': 1, 'styczeń': 1,
      'luty': 2,
      'marzec': 3,
      'kwiecien': 4, 'kwiecień': 4,
      'maj': 5,
      'czerwiec': 6,
      'lipiec': 7,
      'sierpien': 8, 'sierpień': 8,
      'wrzesien': 9, 'wrzesień': 9,
      'pazdziernik': 10, 'październik': 10,
      'listopad': 11,
      'grudzien': 12, 'grudzień': 12,
    };
    // Normalize diacritics by replacing common Polish letters
    String norm(String s) => s
        .replaceAll('ą', 'a')
        .replaceAll('ć', 'c')
        .replaceAll('ę', 'e')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ś', 's')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z');

    final parts = ym.split(RegExp(r'[\s-_/]+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 2) {
      final a = parts[0];
      final b = parts[1];
      // Try "monthName year"
      final monthByName = nameToMonth[a] ?? nameToMonth[norm(a)];
      final year = int.tryParse(b);
      if (monthByName != null && year != null) {
        return DateTime(year, monthByName, 1);
      }
      // Try "year monthName"
      final year2 = int.tryParse(a);
      final monthByName2 = nameToMonth[b] ?? nameToMonth[norm(b)];
      if (year2 != null && monthByName2 != null) {
        return DateTime(year2, monthByName2, 1);
      }
    }
  }

  return null;
}
