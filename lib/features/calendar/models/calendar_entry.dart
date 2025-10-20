enum EntryType {
  // 1. Typy definiujące harmonogram
  scheduledService,

  // 2. Typy zastępujące harmonogram (nieobecności)
  vacationStandard,
  vacationAdditional,
  sickLeave80,
  sickLeave100,
  delegation,
  bloodDonation,
  dayOff,
  custom,

  // 3. Typy modyfikujące harmonogram
  worked,

  // 4. Typy dodatkowe (w dni bez harmonogramu)
  overtimeOffDay,
}

// Snapshot danych dla wpisów niestandardowych.
class CustomAbsenceDetails {
  CustomAbsenceDetails({required this.name, required this.payoutPercentage});

  final String name;
  final int payoutPercentage;
}

class CalendarEntry {
  CalendarEntry({
    required this.id,
    required this.date,
    required this.entryType,
    required this.scheduledHours,
    this.actualHours,
    this.vacationHoursDeducted,
    this.customDetails,
    this.notes,
  }) : assert(scheduledHours >= 0, 'scheduledHours must be non-negative');

  static const Object _undefined = Object();

  final String id;
  final DateTime date;
  final EntryType entryType;

  /// Liczba godzin zaplanowanych na ten dzień.
  final double scheduledHours;

  /// Faktycznie przepracowane godziny (gdy wpis je raportuje).
  final double? actualHours;

  /// Godziny potrącane z puli urlopowej.
  final double? vacationHoursDeducted;

  final CustomAbsenceDetails? customDetails;
  final String? notes;

  CalendarEntry copyWith({
    String? id,
    DateTime? date,
    EntryType? entryType,
    double? scheduledHours,
    Object? actualHours = _undefined,
    Object? vacationHoursDeducted = _undefined,
    Object? customDetails = _undefined,
    Object? notes = _undefined,
  }) {
    return CalendarEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      entryType: entryType ?? this.entryType,
      scheduledHours: scheduledHours ?? this.scheduledHours,
      actualHours:
          actualHours == _undefined ? this.actualHours : actualHours as double?,
      vacationHoursDeducted: vacationHoursDeducted == _undefined
          ? this.vacationHoursDeducted
          : vacationHoursDeducted as double?,
      customDetails: customDetails == _undefined
          ? this.customDetails
          : customDetails as CustomAbsenceDetails?,
      notes: notes == _undefined ? this.notes : notes as String?,
    );
  }

  double get baseHoursWorked {
    switch (entryType) {
      case EntryType.scheduledService:
        return scheduledHours;
      case EntryType.worked:
        final actual = actualHours ?? 0;
        return actual > scheduledHours ? scheduledHours : actual;
      case EntryType.delegation:
      case EntryType.bloodDonation:
        return 8;
      default:
        return 0;
    }
  }

  double get overtimeHours {
    switch (entryType) {
      case EntryType.worked:
        final actual = actualHours ?? 0;
        return actual > scheduledHours ? actual - scheduledHours : 0;
      case EntryType.overtimeOffDay:
        return actualHours ?? 0;
      default:
        return 0;
    }
  }

  double get undertimeHours {
    switch (entryType) {
      case EntryType.delegation:
      case EntryType.bloodDonation:
        final deficit = scheduledHours - 8;
        return deficit > 0 ? deficit : 0;
      case EntryType.worked:
        final actual = actualHours ?? 0;
        return actual < scheduledHours ? scheduledHours - actual : 0;
      case EntryType.dayOff:
      case EntryType.sickLeave80:
      case EntryType.sickLeave100:
      case EntryType.vacationStandard:
      case EntryType.vacationAdditional:
      case EntryType.custom:
        return scheduledHours;
      default:
        return 0;
    }
  }
}