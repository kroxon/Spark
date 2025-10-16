import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/day_detail_dialog.dart';
import 'package:iskra/features/calendar/widgets/shift_month_calendar.dart';
import 'package:iskra/features/home/application/home_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ShiftCycleCalculator _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = ShiftCycleCalculator();
  }

  void _handleMonthChanged(DateTime month) {
    ref.read(homeControllerProvider.notifier).setVisibleMonth(month);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final homeState = ref.watch(homeControllerProvider);
    final visibleMonth = homeState.visibleMonth;

    final profileAsync = ref.watch(
      userProfileProvider(
        UserProfileRequest(uid: user.uid, email: user.email),
      ),
    );

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
      body: profileAsync.when(
        data: (profile) => _buildCalendarView(
          context,
          user,
          profile,
          visibleMonth,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: 'Nie udało się załadować profilu użytkownika.',
          detailed: error.toString(),
        ),
      ),
    );
  }

  Widget _buildCalendarView(
    BuildContext context,
    User user,
    UserProfile profile,
    DateTime visibleMonth,
  ) {
    final entriesAsync = ref.watch(
      calendarEntriesStreamProvider(
        CalendarEntriesRequest(userId: user.uid, month: visibleMonth),
      ),
    );

    return entriesAsync.when(
      data: (entries) => _CalendarContent(
        month: visibleMonth,
        profile: profile,
        entries: entries,
        cycle: _cycle,
        onMonthChanged: _handleMonthChanged,
        onDayTap: (day) => _openDayDialog(context, user, profile, entries, day),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorView(
        message: 'Nie udało się załadować wpisów z Firestore.',
        detailed: error.toString(),
      ),
    );
  }

  void _openDayDialog(
    BuildContext context,
    User user,
    UserProfile profile,
    List<CalendarEntry> entries,
    DateTime selectedDay,
  ) {
    DayDetailDialog.show(
      context: context,
      day: selectedDay,
      userProfile: profile,
      shiftCycleCalculator: _cycle,
      allEntries: entries,
    ).then((note) async {
      final trimmed = note?.trim();
      if (trimmed == null) {
        return;
      }

      final controller = ref.read(homeControllerProvider.notifier);
      try {
        await controller.saveDayNote(
          userId: user.uid,
          day: selectedDay,
          note: trimmed,
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notatka zapisana.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się zapisać notatki: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}

class _CalendarContent extends StatelessWidget {
  const _CalendarContent({
    required this.month,
    required this.profile,
    required this.entries,
    required this.cycle,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  final DateTime month;
  final UserProfile profile;
  final List<CalendarEntry> entries;
  final ShiftCycleCalculator cycle;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                initialMonth: month,
                userProfile: profile,
                entries: entries,
                shiftCycleCalculator: cycle,
                onDaySelected: onDayTap,
                onMonthChanged: onMonthChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.detailed});

  final String message;
  final String detailed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              detailed,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}