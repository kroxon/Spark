import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

class CalendarEntryDto {
  CalendarEntryDto({
    required this.id,
    required this.date,
    required this.entryType,
    required this.isScheduledDay,
    this.hours,
    this.notes,
    this.customDetails,
  });

  final String id;
  final DateTime date;
  final EntryType entryType;
  final bool isScheduledDay;
  final double? hours;
  final String? notes;
  final CustomAbsenceDetails? customDetails;

  factory CalendarEntryDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Calendar entry document ${snapshot.id} has no data');
    }

    final timestamp = data['date'] as Timestamp?;
    if (timestamp == null) {
      throw StateError('Calendar entry ${snapshot.id} is missing "date"');
    }

    final entryTypeRaw = data['entryType'] as String?;
    final entryType = EntryType.values.firstWhere(
      (value) => value.name == entryTypeRaw,
      orElse: () => EntryType.custom,
    );

    final customData = data['customDetails'] as Map<String, dynamic>?;
    CustomAbsenceDetails? customDetails;
    if (customData != null) {
      final name = customData['name'] as String?;
      final payout = customData['payoutPercentage'] as num?;
      if (name != null && payout != null) {
        customDetails = CustomAbsenceDetails(
          name: name,
          payoutPercentage: payout.toInt(),
        );
      }
    }

    return CalendarEntryDto(
      id: snapshot.id,
      date: timestamp.toDate(),
      entryType: entryType,
      isScheduledDay: (data['isScheduledDay'] as bool?) ?? false,
      hours: (data['hours'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      customDetails: customDetails,
    );
  }

  factory CalendarEntryDto.fromDomain(CalendarEntry entry) {
    return CalendarEntryDto(
      id: entry.id,
      date: entry.date,
      entryType: entry.entryType,
      isScheduledDay: entry.isScheduledDay,
      hours: entry.hours,
      notes: entry.notes,
      customDetails: entry.customDetails,
    );
  }

  CalendarEntry toDomain() {
    return CalendarEntry(
      id: id,
      date: date,
      entryType: entryType,
      isScheduledDay: isScheduledDay,
      hours: hours,
      notes: notes,
      customDetails: customDetails,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'entryType': entryType.name,
      'isScheduledDay': isScheduledDay,
      if (hours != null) 'hours': hours,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (notes != null && notes!.isEmpty) 'notes': FieldValue.delete(),
      if (customDetails != null)
        'customDetails': {
          'name': customDetails!.name,
          'payoutPercentage': customDetails!.payoutPercentage,
        },
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
