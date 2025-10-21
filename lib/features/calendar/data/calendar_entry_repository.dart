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

  Query<Map<String, dynamic>> _dayQuery(String userId, DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final next = normalized.add(const Duration(days: 1));
    return _userEntriesCollection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(normalized))
        .where('date', isLessThan: Timestamp.fromDate(next));
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
    final query = await _dayQuery(userId, normalized).get();
    final collection = _userEntriesCollection(userId);
    final batch = _firestore.batch();

    if (query.docs.isEmpty) {
      final entry = CalendarEntry(
        id: _documentId(normalized),
        date: normalized,
        scheduledHours: scheduledHours,
      );
      batch.set(
        collection.doc(entry.id),
        CalendarEntryDto.fromDomain(entry).toFirestore(includeSentinels: false),
      );
    } else {
      for (final doc in query.docs) {
        batch.update(doc.reference, <String, Object?>{
          'scheduledHours': scheduledHours,
          'date': Timestamp.fromDate(normalized),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> removeScheduledService({
    required String userId,
    required DateTime day,
  }) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final query = await _dayQuery(userId, normalized).get();
    if (query.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in query.docs) {
      final entry = CalendarEntryDto.fromFirestore(doc).toDomain();
      final updated = entry.copyWith(scheduledHours: 0);
      if (_isEntryEmpty(updated)) {
        batch.delete(doc.reference);
      } else {
        batch.update(doc.reference, <String, Object?>{
          'scheduledHours': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> updateDayNote({
    required String userId,
    required DateTime day,
    required String note,
  }) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final collection = _userEntriesCollection(userId);
    final query = await _dayQuery(userId, normalized).get();

    final trimmedNote = note.trim();

    if (query.docs.isEmpty) {
      if (trimmedNote.isEmpty) {
        return;
      }
      final entry = CalendarEntry(
        id: _documentId(normalized),
        date: normalized,
        scheduledHours: 0,
        generalNote: trimmedNote,
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
      final entry = CalendarEntryDto.fromFirestore(doc).toDomain();
      if (trimmedNote.isEmpty && _isEntryEmpty(entry.copyWith(generalNote: null))) {
        batch.delete(doc.reference);
      } else {
        batch.update(doc.reference, updateData);
      }
    }
    await batch.commit();
  }

  String _documentId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool _isEntryEmpty(CalendarEntry entry) {
    final hasSchedule = entry.scheduledHours > 0;
    final hasEvents = entry.events.isNotEmpty;
    final hasIncidents = entry.incidents.isNotEmpty;
    final hasNote = entry.generalNote != null && entry.generalNote!.trim().isNotEmpty;
    return !hasSchedule && !hasEvents && !hasIncidents && !hasNote;
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
