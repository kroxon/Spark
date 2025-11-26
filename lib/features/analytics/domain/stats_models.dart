import 'package:flutter/material.dart';

@immutable
class VacationBalance {
  const VacationBalance({required this.standardHours, required this.additionalHours});

  final double standardHours; // Urlop wypoczynkowy
  final double additionalHours; // Urlop dodatkowy

  double get totalHours => standardHours + additionalHours;
}

@immutable
class IncidentYearStats {
  const IncidentYearStats({
    required this.year,
    required this.fires,
    required this.localHazards,
    required this.falseAlarms,
    required this.callDays,
    required this.monthlyStats,
  });

  final int year;
  final int fires; // P
  final int localHazards; // MZ
  final int falseAlarms; // AF
  final int callDays; // dni z co najmniej jednym P lub MZ
  final List<MonthlyIncidentStats> monthlyStats; // 12 elements, index 0 = Jan

  int get totalIncidents => fires + localHazards + falseAlarms;
}

@immutable
class MonthlyIncidentStats {
  const MonthlyIncidentStats({
    required this.month,
    required this.fires,
    required this.localHazards,
    required this.falseAlarms,
  });

  final int month; // 1-12
  final int fires;
  final int localHazards;
  final int falseAlarms;

  int get total => fires + localHazards + falseAlarms;
}

@immutable
class OvertimePeriodStats {
  const OvertimePeriodStats({
    required this.label,
    required this.start,
    required this.end,
    required this.workedHours,
    required this.takenOffHours,
    this.isCurrent = false,
  });

  final String label;
  final DateTime start;
  final DateTime end; // inclusive
  final double workedHours; // EventType.overtimeWorked
  final double takenOffHours; // EventType.overtimeTimeOff
  final bool isCurrent;

  double get balance => workedHours - takenOffHours;
}
