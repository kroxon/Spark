import 'package:iskra/features/calendar/models/calendar_entry.dart';

/// Represents a validation conflict with suggestions for resolution
class ValidationConflict {
  const ValidationConflict({
    required this.message,
    required this.suggestions,
    this.conflictingTypes = const {},
    this.severity = ValidationSeverity.error,
  });

  final String message;
  final List<String> suggestions;
  final Set<EventType> conflictingTypes;
  final ValidationSeverity severity;
}

/// Severity levels for validation conflicts
enum ValidationSeverity {
  warning,
  error,
}

/// Comprehensive validator for quick status selections
class QuickStatusValidator {
  const QuickStatusValidator();

  /// Validates all quick status selections against business rules
  List<ValidationConflict> validateSelections({
    required Map<EventType, double> selections,
    required double? scheduledHours,
  }) {
    final conflicts = <ValidationConflict>[];

    // Rule 1: Overtime validation (only when scheduled hours < 24)
    conflicts.addAll(_validateOvertimeRules(selections, scheduledHours));

    // Rule 2: Overtime time-off validation
    conflicts.addAll(_validateOvertimeTimeOffRules(selections, scheduledHours));

    // Rule 3: Overtime and overtime time-off mutual exclusion
    conflicts.addAll(_validateOvertimeMutualExclusion(selections));

    // Rule 4: Vacation validation
    conflicts.addAll(_validateVacationRules(selections, scheduledHours));

    // Rule 4.1: Vacation hours limit validation
    conflicts.addAll(_validateVacationHoursLimit(selections, scheduledHours));

    // Rule 5: Paid absence validation
    conflicts.addAll(_validatePaidAbsenceRules(selections, scheduledHours));

    // Rule 6: Sick leave mutual exclusion
    conflicts.addAll(_validateSickLeaveExclusivity(selections));

    // Rule 7: Blood donation exclusivity
    conflicts.addAll(_validateBloodDonationExclusivity(selections));

    // Rule 8: Home duty compatibility
    conflicts.addAll(_validateHomeDutyRules(selections));

    // Rule 9: Delegation validation
    conflicts.addAll(_validateDelegationRules(selections, scheduledHours));

    // Rule 10: Total hours limit validation
    conflicts.addAll(_validateTotalHoursLimit(selections, scheduledHours));

    return conflicts;
  }

  /// Checks if selections are valid (no errors)
  bool isValid({
    required Map<EventType, double> selections,
    required double? scheduledHours,
  }) {
    final conflicts = validateSelections(
      selections: selections,
      scheduledHours: scheduledHours,
    );
    return conflicts.where((c) => c.severity == ValidationSeverity.error).isEmpty;
  }

  /// Gets suggestions for fixing conflicts
  List<String> getSuggestions({
    required Map<EventType, double> selections,
    required double? scheduledHours,
  }) {
    final conflicts = validateSelections(
      selections: selections,
      scheduledHours: scheduledHours,
    );
    return conflicts.expand((c) => c.suggestions).toList();
  }

  List<ValidationConflict> _validateOvertimeRules(
    Map<EventType, double> selections,
    double? scheduledHours,
  ) {
    final conflicts = <ValidationConflict>[];
    final overtimeHours = selections[EventType.overtimeWorked] ?? 0;

    if (overtimeHours == 0) return conflicts;

    if (scheduledHours != null && scheduledHours > 0) {
      final maxAllowed = 24 - scheduledHours;
      if (maxAllowed <= 0) {
        conflicts.add(ValidationConflict(
          message: 'Nie można ustawić nadgodzin gdy godziny harmonogramu wynoszą ${scheduledHours}h (maksymalnie 24h)',
          suggestions: [
            'Usuń nadgodziny',
            'Jeśli to konieczne, zmniejsz godziny harmonogramu',
          ],
          conflictingTypes: {EventType.overtimeWorked},
          severity: ValidationSeverity.error,
        ));
      } else if (overtimeHours > maxAllowed) {
        conflicts.add(ValidationConflict(
          message: 'Nadgodziny nie mogą przekraczać ${maxAllowed}h (24h - ${scheduledHours}h harmonogramu)',
          suggestions: [
            'Zmniejsz nadgodziny do maksymalnie ${maxAllowed}h',
            'Zwiększ godziny harmonogramu jeśli to uzasadnione',
          ],
          conflictingTypes: {EventType.overtimeWorked},
          severity: ValidationSeverity.error,
        ));
      }
    }

    return conflicts;
  }

  List<ValidationConflict> _validateOvertimeTimeOffRules(
    Map<EventType, double> selections,
    double? scheduledHours,
  ) {
    final conflicts = <ValidationConflict>[];
    final timeOffHours = selections[EventType.overtimeTimeOff] ?? 0;

    if (timeOffHours == 0) return conflicts;

    // Overtime time-off requires scheduled hours to be deducted from
    if (scheduledHours == null || scheduledHours <= 0) {
      conflicts.add(ValidationConflict(
        message: 'Odbiór nadgodzin wymaga zaplanowanych godzin w harmonogramie',
        suggestions: [
          'Dodaj godziny harmonogramu aby móc korzystać z odbioru nadgodzin',
          'Usuń odbiór nadgodzin - nie jest dostępny bez harmonogramu',
        ],
        conflictingTypes: {EventType.overtimeTimeOff},
        severity: ValidationSeverity.error,
      ));
      return conflicts;
    }

    if (timeOffHours > scheduledHours) {
      conflicts.add(ValidationConflict(
        message: 'Odbiór nadgodzin nie może przekraczać godzin harmonogramu (${scheduledHours}h)',
        suggestions: [
          'Zmniejsz odbiór nadgodzin do maksymalnie ${scheduledHours}h',
          'Zwiększ godziny harmonogramu jeśli masz więcej nadgodzin do odbioru',
        ],
        conflictingTypes: {EventType.overtimeTimeOff},
        severity: ValidationSeverity.error,
      ));
    }

    return conflicts;
  }

  List<ValidationConflict> _validateOvertimeMutualExclusion(
    Map<EventType, double> selections,
  ) {
    final conflicts = <ValidationConflict>[];
    final hasOvertimeWorked = selections.containsKey(EventType.overtimeWorked);
    final hasOvertimeTimeOff = selections.containsKey(EventType.overtimeTimeOff);

    if (!hasOvertimeWorked || !hasOvertimeTimeOff) return conflicts;

    // Cannot have both overtime worked and overtime time-off on the same day
    conflicts.add(ValidationConflict(
      message: 'Nie można jednocześnie zaznaczyć nadgodzin i odbioru nadgodzin',
      suggestions: [
        'Zostaw tylko nadgodziny jeśli pracowałeś dodatkowo',
        'Zostaw tylko odbiór nadgodzin jeśli wykorzystujesz czas wolny',
        'Usuń jeden z tych statusów',
      ],
      conflictingTypes: {EventType.overtimeWorked, EventType.overtimeTimeOff},
      severity: ValidationSeverity.error,
    ));

    return conflicts;
  }

  List<ValidationConflict> _validateVacationRules(
    Map<EventType, double> selections,
    double? scheduledHours,
  ) {
    final conflicts = <ValidationConflict>[];
    final vacationTypes = {EventType.vacationRegular, EventType.vacationAdditional};
    final selectedVacations = selections.keys.where(vacationTypes.contains).toList();

    if (selectedVacations.isEmpty) return conflicts;

    // Vacations require scheduled hours to be deducted properly
    if (scheduledHours == null || scheduledHours <= 0) {
      conflicts.add(ValidationConflict(
        message: 'Urlopy wymagają zaplanowanych godzin w harmonogramie do prawidłowego odliczenia',
        suggestions: [
          'Dodaj godziny harmonogramu aby urlopy były odliczane od puli',
          'Urlopy bez harmonogramu są traktowane jako niepłatne nieobecności',
        ],
        severity: ValidationSeverity.warning,
      ));
    }

    return conflicts;
  }

  List<ValidationConflict> _validateVacationHoursLimit(
    Map<EventType, double> selections,
    double? scheduledHours,
  ) {
    final conflicts = <ValidationConflict>[];
    final vacationTypes = {EventType.vacationRegular, EventType.vacationAdditional};

    // Calculate total vacation hours
    final totalVacationHours = selections.entries
        .where((entry) => vacationTypes.contains(entry.key))
        .fold<double>(0, (sum, entry) => sum + entry.value);

    if (totalVacationHours == 0) return conflicts;

    // Total vacation hours cannot exceed scheduled hours
    if (scheduledHours != null && scheduledHours > 0 && totalVacationHours > scheduledHours) {
      final conflictingTypes = selections.keys.where(vacationTypes.contains).toSet();
      conflicts.add(ValidationConflict(
        message: 'Łączne godziny urlopów (${totalVacationHours}h) nie mogą przekraczać godzin harmonogramu (${scheduledHours}h)',
        suggestions: [
          'Zmniejsz godziny urlopów łącznie do maksymalnie ${scheduledHours}h',
          'Zwiększ godziny harmonogramu jeśli urlopy mają obejmować więcej godzin',
          'Rozłóż urlopy na kilka dni',
        ],
        conflictingTypes: conflictingTypes,
        severity: ValidationSeverity.error,
      ));
    }

    return conflicts;
  }

  List<ValidationConflict> _validatePaidAbsenceRules(
    Map<EventType, double> selections,
    double? scheduledHours,
  ) {
    final conflicts = <ValidationConflict>[];
    final hasPaidAbsence = selections.containsKey(EventType.paidAbsence);

    if (!hasPaidAbsence) return conflicts;

    // Paid absence requires scheduled hours to be deducted properly
    if (scheduledHours == null || scheduledHours <= 0) {
      conflicts.add(ValidationConflict(
        message: 'Płatne nieobecności wymagają zaplanowanych godzin w harmonogramie',
        suggestions: [
          'Dodaj godziny harmonogramu aby płatne nieobecności były prawidłowo odliczane',
          'Usuń płatne nieobecności - nie są dostępne bez harmonogramu',
        ],
        conflictingTypes: {EventType.paidAbsence},
        severity: ValidationSeverity.error,
      ));
    }

    return conflicts;
  }

  List<ValidationConflict> _validateSickLeaveExclusivity(
    Map<EventType, double> selections,
  ) {
    final conflicts = <ValidationConflict>[];
    final sickLeaveTypes = {EventType.sickLeave80, EventType.sickLeave100};
    final selectedSickLeaves = selections.keys.where(sickLeaveTypes.contains).toList();

    if (selectedSickLeaves.length <= 1) return conflicts;

    // Only one sick leave type can be selected at a time
    final typeLabels = selectedSickLeaves.map(_getEventTypeLabel).join(', ');
    conflicts.add(ValidationConflict(
      message: 'Można zaznaczyć tylko jeden typ zwolnienia lekarskiego: $typeLabels',
      suggestions: [
        'Zostaw tylko jeden typ zwolnienia lekarskiego',
        'Usuń wszystkie oprócz najważniejszego',
      ],
      conflictingTypes: selectedSickLeaves.toSet(),
      severity: ValidationSeverity.error,
    ));

    return conflicts;
  }

  List<ValidationConflict> _validateDelegationRules(
    Map<EventType, double> selections,
    double? scheduledHours,
  ) {
    final conflicts = <ValidationConflict>[];
    final hasDelegation = selections.containsKey(EventType.delegation);

    if (!hasDelegation) return conflicts;

    // Delegation can be combined with other statuses but has fixed 8 hours
    // No specific validation rules for delegation beyond the total hours limit
    return conflicts;
  }

  List<ValidationConflict> _validateBloodDonationExclusivity(
    Map<EventType, double> selections,
  ) {
    final conflicts = <ValidationConflict>[];
    final hasBloodDonation = selections.containsKey(EventType.bloodDonation);

    if (!hasBloodDonation) return conflicts;

    // Blood donation cannot be combined with ANY other status
    final otherSelectedTypes = selections.keys
        .where((type) => type != EventType.bloodDonation)
        .toList();

    if (otherSelectedTypes.isNotEmpty) {
      final conflictLabels = otherSelectedTypes.map(_getEventTypeLabel).join(', ');
      conflicts.add(ValidationConflict(
        message: 'Krwiodawstwo nie może być łączone z innymi statusami',
        suggestions: [
          'Usuń krwiodawstwo lub odznacz inne statusy: $conflictLabels',
          'Krwiodawstwo musi być jedynym zaznaczonym statusem',
        ],
        conflictingTypes: {EventType.bloodDonation, ...otherSelectedTypes},
        severity: ValidationSeverity.error,
      ));
    }

    return conflicts;
  }

  List<ValidationConflict> _validateHomeDutyRules(
    Map<EventType, double> selections,
  ) {
    final conflicts = <ValidationConflict>[];
    final hasHomeDuty = selections.containsKey(EventType.homeDuty);

    if (!hasHomeDuty) return conflicts;

    final allowedWithHomeDuty = {
      EventType.vacationRegular,
      EventType.vacationAdditional,
      EventType.overtimeTimeOff,
    };

    final conflictingTypes = selections.keys
        .where((type) => type != EventType.homeDuty && !allowedWithHomeDuty.contains(type))
        .toList();

    if (conflictingTypes.isNotEmpty) {
      final conflictLabels = conflictingTypes.map(_getEventTypeLabel).join(', ');
      conflicts.add(ValidationConflict(
        message: 'Dyżur domowy można łączyć tylko z urlopami, odbiorem nadgodzin i niepłatnymi nieobecnościami',
        suggestions: [
          'Usuń konflikujące statusy: $conflictLabels',
          'Zostaw tylko dyżur domowy z dozwolonymi statusami',
        ],
        conflictingTypes: {EventType.homeDuty, ...conflictingTypes},
        severity: ValidationSeverity.error,
      ));
    }

    return conflicts;
  }

  List<ValidationConflict> _validateTotalHoursLimit(
    Map<EventType, double> selections,
    double? scheduledHours,
  ) {
    final conflicts = <ValidationConflict>[];

    // Calculate total hours of all statuses (except fixed hour ones like home duty)
    final variableHourTypes = {
      EventType.vacationRegular,
      EventType.vacationAdditional,
      EventType.overtimeTimeOff,
      EventType.paidAbsence,
      EventType.delegation,
      EventType.overtimeWorked,
    };

    final totalHours = selections.entries
        .where((entry) => variableHourTypes.contains(entry.key))
        .fold<double>(0, (sum, entry) => sum + entry.value);

    // Total cannot exceed 24 hours
    if (totalHours > 24) {
      final excess = totalHours - 24;
      conflicts.add(ValidationConflict(
        message: 'Łączna suma godzin wszystkich statusów (${totalHours}h) przekracza 24h o ${excess}h',
        suggestions: [
          'Zmniejsz godziny poszczególnych statusów',
          'Rozłóż nadwyżki na inne dni',
          'Usuń niektóre statusy aby zmniejszyć łączną sumę',
        ],
        conflictingTypes: selections.keys.where(variableHourTypes.contains).toSet(),
        severity: ValidationSeverity.error,
      ));
    }

    return conflicts;
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.overtimeWorked:
        return 'Nadgodziny';
      case EventType.delegation:
        return 'Delegacja';
      case EventType.bloodDonation:
        return 'Krwiodawstwo';
      case EventType.vacationRegular:
        return 'Urlop wypoczynkowy';
      case EventType.vacationAdditional:
        return 'Urlop dodatkowy';
      case EventType.sickLeave80:
        return 'Zwolnienie lekarskie 80%';
      case EventType.sickLeave100:
        return 'Zwolnienie lekarskie 100%';
      case EventType.paidAbsence:
        return 'Inna płatna nieobecność';
      case EventType.overtimeTimeOff:
        return 'Odbiór nadgodzin';
      case EventType.homeDuty:
        return 'Dyżur domowy';
    }
  }
}