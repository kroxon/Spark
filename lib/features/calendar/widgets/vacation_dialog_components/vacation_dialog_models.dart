import 'package:iskra/features/calendar/models/calendar_entry.dart';

enum VacationType { regular, additional }

class _ConflictDay {
  const _ConflictDay(this.date, this.events);

  final DateTime date;
  final List<DayEvent> events;

  String get formattedDate => '${date.day}.${date.month}.${date.year}';
}