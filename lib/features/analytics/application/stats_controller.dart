import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/analytics/domain/stats_models.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/incident_entry.dart';

// Year is passed explicitly by the UI as a provider family parameter.

// Vacation balance based on user profile
final vacationBalanceProvider = FutureProvider<VacationBalance>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    return const VacationBalance(standardHours: 0, additionalHours: 0);
  }
  final repo = ref.read(userProfileRepositoryProvider);
  final profile = await repo.watchProfile(user.uid).first;
  if (profile == null) {
    return const VacationBalance(standardHours: 0, additionalHours: 0);
  }
  return VacationBalance(
    standardHours: profile.standardVacationHours,
    additionalHours: profile.additionalVacationHours,
  );
});

// Incident statistics for the selected year
final incidentStatsProvider = FutureProvider.family<IncidentYearStats, int>((ref, year) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    return IncidentYearStats(
      year: year,
      fires: 0,
      localHazards: 0,
      falseAlarms: 0,
      callDays: 0,
      monthlyStats: List.generate(
        12,
        (i) => MonthlyIncidentStats(
          month: i + 1,
          fires: 0,
          localHazards: 0,
          falseAlarms: 0,
        ),
      ),
    );
  }

  final repo = ref.read(calendarEntryRepositoryProvider);
  final start = DateTime.utc(year, 1, 1);
  final end = DateTime.utc(year, 12, 31);
  final entries = await repo.getEntriesInRange(userId: user.uid, start: start, end: end);

  var fires = 0;
  var mz = 0;
  var af = 0;
  final callDays = <DateTime>{};
  
  // [fires, mz, af] per month (0-11)
  final monthlyCounts = List.generate(12, (_) => [0, 0, 0]);

  for (final entry in entries) {
    if (entry.incidents.isEmpty) continue;
    var hasCallPOrMz = false;
    
    for (final inc in entry.incidents) {
      final monthIndex = entry.date.month - 1;
      if (monthIndex < 0 || monthIndex > 11) continue;

      switch (inc.category) {
        case IncidentCategory.fire:
          fires++;
          monthlyCounts[monthIndex][0]++;
          hasCallPOrMz = true;
          break;
        case IncidentCategory.localHazard:
          mz++;
          monthlyCounts[monthIndex][1]++;
          hasCallPOrMz = true;
          break;
        case IncidentCategory.falseAlarm:
          af++;
          monthlyCounts[monthIndex][2]++;
          break;
      }
    }
    if (hasCallPOrMz) {
      callDays.add(DateTime(entry.date.year, entry.date.month, entry.date.day));
    }
  }

  final monthlyStats = List.generate(12, (i) {
    return MonthlyIncidentStats(
      month: i + 1,
      fires: monthlyCounts[i][0],
      localHazards: monthlyCounts[i][1],
      falseAlarms: monthlyCounts[i][2],
    );
  });

  return IncidentYearStats(
    year: year,
    fires: fires,
    localHazards: mz,
    falseAlarms: af,
    callDays: callDays.length,
    monthlyStats: monthlyStats,
  );
});

class _PeriodPair {
  const _PeriodPair(this.current, this.previous);
  final (DateTime start, DateTime end) current;
  final (DateTime start, DateTime end) previous;
}

_PeriodPair _resolveOvertimePeriods(DateTime now) {
  final year = now.year;
  final firstStart = DateTime.utc(year, 1, 1);
  final firstEnd = DateTime.utc(year, 6, 30);
  final secondStart = DateTime.utc(year, 7, 1);
  final secondEnd = DateTime.utc(year, 12, 31);

  if (now.isBefore(secondStart)) {
    // We are in first period (Jan-Jun)
    final prevStart = DateTime.utc(year - 1, 7, 1);
    final prevEnd = DateTime.utc(year - 1, 12, 31);
    return _PeriodPair((firstStart, firstEnd), (prevStart, prevEnd));
  } else {
    // We are in second period (Jul-Dec)
    return _PeriodPair((secondStart, secondEnd), (firstStart, firstEnd));
  }
}

Future<OvertimePeriodStats> _computeOvertimeFor(
  CalendarEntryRepository repo,
  String userId,
  String label,
  DateTime start,
  DateTime end,
  bool isCurrent,
) async {
  final entries = await repo.getEntriesInRange(userId: userId, start: start, end: end);
  double worked = 0;
  double takenOff = 0;
  for (final e in entries) {
    for (final ev in e.events) {
      if (ev.type == EventType.overtimeWorked) {
        worked += ev.hours;
      } else if (ev.type == EventType.overtimeTimeOff) {
        takenOff += ev.hours;
      }
    }
  }
  return OvertimePeriodStats(
    label: label,
    start: start,
    end: end,
    workedHours: worked,
    takenOffHours: takenOff,
    isCurrent: isCurrent,
  );
}

// Overtime stats for current and previous period
final overtimeStatsProvider = FutureProvider<List<OvertimePeriodStats>>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) return const <OvertimePeriodStats>[];

  final repo = ref.read(calendarEntryRepositoryProvider);
  final now = DateTime.now().toUtc();
  final pair = _resolveOvertimePeriods(now);

  final current = await _computeOvertimeFor(
    repo,
    user.uid,
    'Bieżący okres',
    pair.current.$1,
    pair.current.$2,
    true,
  );
  final previous = await _computeOvertimeFor(
    repo,
    user.uid,
    'Poprzedni okres',
    pair.previous.$1,
    pair.previous.$2,
    false,
  );

  return [current, previous];
});
