enum EntryType {
  dayOff,
  overtime,
  sickLeave80,
  sickLeave100,
  delegation,
  bloodDonation,
  vacationStandard,
  vacationAdditional,
  custom,
}

//This class will hold copied data from the custom type.
// Even if the user changes the definition of "Paternity Leave"
// in the future, historical entries will remain unchanged.
class CustomAbsenceDetails {
  final String name;
  final int payoutPercentage;

  CustomAbsenceDetails({required this.name, required this.payoutPercentage});
}

class CalendarEntry {
  final String id;
  final DateTime date;
  final EntryType entryType;
  final bool isScheduledDay;
  final double? hours;
  final String? notes;
  final CustomAbsenceDetails? customDetails;

  CalendarEntry({
    required this.id,
    required this.date,
    required this.entryType,
    required this.isScheduledDay,
    this.hours,
    this.notes,
    this.customDetails,
  });

  CalendarEntry copyWith({
    String? id,
    DateTime? date,
    EntryType? entryType,
    bool? isScheduledDay,
    double? hours,
    String? notes,
    CustomAbsenceDetails? customDetails,
  }) {
    return CalendarEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      entryType: entryType ?? this.entryType,
      isScheduledDay: isScheduledDay ?? this.isScheduledDay,
      hours: hours ?? this.hours,
      notes: notes ?? this.notes,
      customDetails: customDetails ?? this.customDetails,
    );
  }
}