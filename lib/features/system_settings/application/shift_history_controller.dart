import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';

class ShiftHistoryController extends AsyncNotifier<void> {
  late FirebaseFirestore _firestore;
  late UserProfileRepository _profileRepo;

  @override
  Future<void> build() async {
    _firestore = ref.read(firebaseFirestoreProvider);
    _profileRepo = ref.read(userProfileRepositoryProvider);
  }

  Future<void> addOrReplacePeriod({
    required String uid,
    required List<ShiftAssignment> current,
    required int shiftId,
    required DateTime startMonth, // normalized to UTC first day of month
    DateTime? endMonth, // inclusive; null => to now
  }) async {
    final start = DateTime.utc(startMonth.year, startMonth.month, 1);
    final now = DateTime.now().toUtc();
    final currentMonth = DateTime.utc(now.year, now.month, 1);
    final endExclusive = endMonth == null
        ? DateTime.utc(currentMonth.year, currentMonth.month + 1, 1)
        : DateTime.utc(endMonth.year, endMonth.month + 1, 1);

    // Validate month order
    if (endExclusive.isBefore(start) || endExclusive.isAtSameMomentAs(start)) {
      throw StateError('Nieprawidłowy zakres miesięcy (koniec przed lub równy początkowi).');
    }

    // 1) Block if there are calendar entries in the affected range [start .. endExclusive)
    final entriesCollision = await _hasCalendarEntriesInRange(uid, start, endExclusive);
    if (entriesCollision) {
      throw StateError('W wybranym okresie istnieją wpisy w kalendarzu. Usuń je najpierw i spróbuj ponownie.');
    }

    // 2) Build updated shiftHistory list by inserting the period and removing start markers inside the period
    final sorted = List<ShiftAssignment>.from(current)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Active shift at endExclusive (before change) to be used for revert after the period
    final revertShiftId = _activeShiftIdAt(sorted, DateTime.utc(endExclusive.year, endExclusive.month, endExclusive.day - 1));

    // Filter out assignments that start within [start .. endExclusive)
    final updated = <ShiftAssignment>[];
    for (final a in sorted) {
      final s = DateTime.utc(a.startDate.year, a.startDate.month, 1);
      final inRange = (s.isAfter(start) || s.isAtSameMomentAs(start)) && s.isBefore(endExclusive);
      if (!inRange) {
        updated.add(ShiftAssignment(shiftId: a.shiftId, startDate: s));
      }
    }

    // Insert start of the new period
    final existingAtStartIndex = updated.indexWhere((a) => a.startDate.isAtSameMomentAs(start));
    if (existingAtStartIndex >= 0) {
      updated[existingAtStartIndex] = ShiftAssignment(shiftId: shiftId, startDate: start);
    } else {
      updated.add(ShiftAssignment(shiftId: shiftId, startDate: start));
    }

    // Insert revert start if end provided and we have a revert shift to go back to
    if (endMonth != null && revertShiftId != null) {
      final revertStart = endExclusive; // first day after end month
      final existingAtRevertIndex = updated.indexWhere((a) => a.startDate.isAtSameMomentAs(revertStart));
      if (existingAtRevertIndex >= 0) {
        updated[existingAtRevertIndex] = ShiftAssignment(shiftId: revertShiftId, startDate: revertStart);
      } else {
        updated.add(ShiftAssignment(shiftId: revertShiftId, startDate: revertStart));
      }
    }

    updated.sort((a, b) => a.startDate.compareTo(b.startDate));

    // 3) Persist to Firestore via repository
    await _profileRepo.updateShiftHistory(uid: uid, assignments: updated);
  }

  Future<void> deletePeriod({
    required String uid,
    required List<ShiftAssignment> current,
    required DateTime startMonth,
  }) async {
    final start = DateTime.utc(startMonth.year, startMonth.month, 1);

    // Determine the endExclusive of this period (next start or now+1 month)
    final sorted = List<ShiftAssignment>.from(current)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final idx = sorted.indexWhere((a) =>
        DateTime.utc(a.startDate.year, a.startDate.month, 1)
            .isAtSameMomentAs(start));
    if (idx < 0) {
      throw StateError('Nie znaleziono okresu o wskazanym początku.');
    }

    DateTime endExclusive;
    if (idx + 1 < sorted.length) {
      final next = sorted[idx + 1].startDate;
      endExclusive = DateTime.utc(next.year, next.month, 1);
    } else {
      final now = DateTime.now().toUtc();
      final currentMonth = DateTime.utc(now.year, now.month, 1);
      endExclusive = DateTime.utc(currentMonth.year, currentMonth.month + 1, 1);
    }

    // Check calendar entries collision in [start .. endExclusive)
    final entriesCollision = await _hasCalendarEntriesInRange(uid, start, endExclusive);
    if (entriesCollision) {
      throw StateError('Nie można usunąć: w tym okresie są wpisy w kalendarzu. Usuń je najpierw.');
    }

    // Remove this start marker; previous assignment will extend to next start automatically
    final updated = <ShiftAssignment>[];
    for (var i = 0; i < sorted.length; i++) {
      final s = DateTime.utc(sorted[i].startDate.year, sorted[i].startDate.month, 1);
      if (i == idx && s.isAtSameMomentAs(start)) {
        continue; // skip deletion target
      }
      updated.add(ShiftAssignment(shiftId: sorted[i].shiftId, startDate: s));
    }
    await _profileRepo.updateShiftHistory(uid: uid, assignments: updated);
  }

  int? _activeShiftIdAt(List<ShiftAssignment> sorted, DateTime date) {
    int? result;
    for (final a in sorted) {
      final s = DateTime.utc(a.startDate.year, a.startDate.month, 1);
      if (s.isAfter(date)) break;
      result = a.shiftId;
    }
    return result;
  }

  Future<bool> _hasCalendarEntriesInRange(
    String uid,
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    // users/{uid}/calendarEntries with documentId between start and endExclusive
    String _docId(DateTime d) {
      final month = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '${d.year}-$month-$day';
    }

    final startId = _docId(startInclusive);
    final endId = _docId(endExclusive);

    final query = _firestore
        .collection('users')
        .doc(uid)
        .collection('calendarEntries')
        .orderBy(FieldPath.documentId)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
        .where(FieldPath.documentId, isLessThan: endId)
        .limit(1);

    final snap = await query.get();
    return snap.docs.isNotEmpty;
  }
}

final shiftHistoryControllerProvider = AsyncNotifierProvider<ShiftHistoryController, void>(() {
  return ShiftHistoryController();
});
