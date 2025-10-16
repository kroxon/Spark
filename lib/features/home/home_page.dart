import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iskra/features/auth/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/shift_month_calendar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cycle = ShiftCycleCalculator();
    final profile = _sampleProfile();
    final entries = _sampleEntries(cycle, profile);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekran Główny'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Zalogowano! Witaj w Iskrze!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ShiftMonthCalendar(
                  initialMonth: DateTime(now.year, now.month),
                  userProfile: profile,
                  entries: entries,
                  shiftCycleCalculator: cycle,
                  onDaySelected: (selectedDay) {
                    // TODO(pk): Hook up to detail view once implemented.
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

UserProfile _sampleProfile() {
  return UserProfile(
    uid: 'demo-user',
    email: 'demo@iskra.app',
    subscriptionPlan: 'free',
    shiftHistory: [
      ShiftAssignment(
        shiftId: 2,
        startDate: DateTime(2024, 1, 1),
      ),
    ],
    standardVacationHours: 208,
    additionalVacationHours: 104,
  );
}

List<CalendarEntry> _sampleEntries(ShiftCycleCalculator cycle, UserProfile profile) {
  final sortedHistory = List<ShiftAssignment>.from(profile.shiftHistory)
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  final today = DateUtils.dateOnly(DateTime.now());
  final currentMonth = DateTime(today.year, today.month, 1);
  final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);

  final dutyDays = <DateTime>[];
  for (DateTime day = currentMonth;
      !day.isAfter(monthEnd);
      day = day.add(const Duration(days: 1))) {
    if (cycle.isScheduledDayForUser(day, sortedHistory)) {
      dutyDays.add(day);
    }
  }

  if (dutyDays.isEmpty) {
    return const <CalendarEntry>[];
  }

  final sampleEntries = <CalendarEntry>[];
  final skipIndices = <int>{1, 4, 7};

  for (var i = 0; i < dutyDays.length; i++) {
    final day = dutyDays[i];
    if (skipIndices.contains(i)) {
      sampleEntries.add(
        CalendarEntry(
          id: _entryId(day),
          date: day,
          entryType: EntryType.dayOff,
          isScheduledDay: true,
          notes: 'Zmiana odpuszczona wg grafiku',
        ),
      );
    }
  }

  final vacationDay = dutyDays.elementAt(dutyDays.length > 3 ? 3 : 0);
  sampleEntries.add(
    CalendarEntry(
      id: _entryId(vacationDay),
      date: vacationDay,
      entryType: EntryType.vacationStandard,
      isScheduledDay: true,
      notes: 'Urlop etatowy',
    ),
  );

  final customDay = currentMonth.add(const Duration(days: 5));
  sampleEntries.add(
    CalendarEntry(
      id: _entryId(customDay),
      date: customDay,
      entryType: EntryType.custom,
      isScheduledDay: false,
      customDetails: CustomAbsenceDetails(
        name: 'Szkolenie',
        payoutPercentage: 100,
      ),
    ),
  );

  return sampleEntries;
}

String _entryId(DateTime date) {
  final normalized = DateUtils.dateOnly(date);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}