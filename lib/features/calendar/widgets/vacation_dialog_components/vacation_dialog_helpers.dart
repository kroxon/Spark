import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

String getEventTypeDisplayName(EventType type) {
  switch (type) {
    case EventType.overtimeWorked:
      return 'Nadgodziny przepracowane';
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
      return 'Nieobecność płatna';
    case EventType.overtimeTimeOff:
      return 'Urlop za nadgodziny';
    case EventType.homeDuty:
      return 'Praca domowa';
  }
}

IconData getEventIcon(EventType type) {
  switch (type) {
    case EventType.overtimeWorked:
      return Icons.work;
    case EventType.delegation:
      return Icons.business_center;
    case EventType.bloodDonation:
      return Icons.favorite;
    case EventType.vacationRegular:
      return Icons.beach_access;
    case EventType.vacationAdditional:
      return Icons.star;
    case EventType.sickLeave80:
    case EventType.sickLeave100:
      return Icons.sick;
    case EventType.paidAbsence:
      return Icons.event_busy;
    case EventType.overtimeTimeOff:
      return Icons.free_cancellation;
    case EventType.homeDuty:
      return Icons.home;
  }
}