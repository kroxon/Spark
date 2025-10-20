import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/calendar/data/calendar_entry_dto.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

class CalendarEntriesRequest {
  CalendarEntriesRequest({
    required this.userId,
    required DateTime month,
  }) : month = DateTime(month.year, month.month);

  final String userId;
  final DateTime month;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CalendarEntriesRequest &&
            other.userId == userId &&
            other.month.year == month.year &&
            other.month.month == month.month;
  }

  @override
  int get hashCode => Object.hash(userId, month.year, month.month);
}

class CalendarEntryRepository {
  CalendarEntryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userEntriesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('calendarEntries');
  }

  Query<Map<String, dynamic>> _monthQuery(String userId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _userEntriesCollection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end));
  }

  Stream<List<CalendarEntry>> watchEntries(CalendarEntriesRequest request) {
    return _monthQuery(request.userId, request.month)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEntryDto.fromFirestore(doc).toDomain())
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)));
  }

  Future<void> upsertEntries(String userId, List<CalendarEntry> entries) async {
    if (entries.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    final collection = _userEntriesCollection(userId);
    for (final entry in entries) {
      final dto = CalendarEntryDto.fromDomain(entry);
      batch.set(
        collection.doc(entry.id),
        dto.toFirestore(includeSentinels: true),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> replaceEntriesForMonth({
    required String userId,
    required DateTime month,
    required List<CalendarEntry> entries,
  }) async {
    final collection = _userEntriesCollection(userId);
    final existing = await _monthQuery(userId, month).get();
    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final entry in entries) {
      final dto = CalendarEntryDto.fromDomain(entry);
      batch.set(
        collection.doc(entry.id),
        dto.toFirestore(includeSentinels: false),
      );
    }
    await batch.commit();
  }

  Future<void> assignScheduledService({
    required String userId,
    required DateTime day,
    double scheduledHours = 24,
  }) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final next = normalized.add(const Duration(days: 1));
    final collection = _userEntriesCollection(userId);
    final query = await collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(normalized))
        .where('date', isLessThan: Timestamp.fromDate(next))
        .get();

    final batch = _firestore.batch();
    DocumentReference<Map<String, dynamic>>? scheduledRef;

    for (final doc in query.docs) {
      final entry = CalendarEntryDto.fromFirestore(doc).toDomain();
      if (_requiresScheduleHoursUpdate(entry)) {
        batch.update(doc.reference, <String, Object?>{
          'scheduledHours': scheduledHours,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (entry.entryType == EntryType.scheduledService) {
        scheduledRef = doc.reference;
      }
    }

    if (scheduledRef != null) {
      batch.set(
        scheduledRef,
        <String, Object?>{
          'entryType': EntryType.scheduledService.name,
          'scheduledHours': scheduledHours,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      final scheduledEntry = CalendarEntry(
        id: _scheduledEntryId(normalized),
        date: normalized,
        entryType: EntryType.scheduledService,
        scheduledHours: scheduledHours,
      );
      batch.set(
        collection.doc(scheduledEntry.id),
        CalendarEntryDto.fromDomain(scheduledEntry).toFirestore(includeSentinels: false),
      );
    }

    await batch.commit();
  }

  Future<void> updateDayNote({
    required String userId,
    required DateTime day,
    required String note,
  }) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final next = normalized.add(const Duration(days: 1));
    final collection = _userEntriesCollection(userId);
    final query = await collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(normalized))
        .where('date', isLessThan: Timestamp.fromDate(next))
        .get();

    final trimmedNote = note.trim();

    if (query.docs.isEmpty) {
      if (trimmedNote.isEmpty) {
        return;
      }
      final entry = CalendarEntry(
        id: _noteEntryId(normalized),
        date: normalized,
        entryType: EntryType.custom,
        scheduledHours: 0,
        notes: trimmedNote,
      );
      await collection.doc(entry.id).set(
        CalendarEntryDto.fromDomain(entry).toFirestore(includeSentinels: false),
      );
      return;
    }

    final batch = _firestore.batch();
    final updateData = <String, Object?>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (trimmedNote.isEmpty) 'notes': FieldValue.delete() else 'notes': trimmedNote,
    };

    for (final doc in query.docs) {
      batch.update(doc.reference, updateData);
    }
    await batch.commit();
  }

  String _noteEntryId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day-note';
  }

  String _scheduledEntryId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day-scheduled';
  }

  bool _requiresScheduleHoursUpdate(CalendarEntry entry) {
    switch (entry.entryType) {
      case EntryType.scheduledService:
      case EntryType.worked:
      case EntryType.vacationStandard:
      case EntryType.vacationAdditional:
      case EntryType.sickLeave80:
      case EntryType.sickLeave100:
      case EntryType.delegation:
      case EntryType.bloodDonation:
      case EntryType.dayOff:
        return true;
      case EntryType.custom:
        return entry.customDetails != null || entry.scheduledHours > 0;
      case EntryType.overtimeOffDay:
        return false;
    }
  }
}

final calendarEntryRepositoryProvider = Provider<CalendarEntryRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return CalendarEntryRepository(firestore);
});

final calendarEntriesStreamProvider =
    StreamProvider.family<List<CalendarEntry>, CalendarEntriesRequest>((ref, request) {
  final repository = ref.watch(calendarEntryRepositoryProvider);
  return repository.watchEntries(request);
});
