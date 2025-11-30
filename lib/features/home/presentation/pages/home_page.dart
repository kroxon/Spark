import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/day_detail_dialog.dart';
import 'package:iskra/features/calendar/widgets/schedule_fab.dart';
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
    final isEditingSchedule = homeState.isEditingSchedule;

    final profileAsync = ref.watch(
      userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)),
    );

    return profileAsync.when(
      data: (profile) {
        if (!profile.isOnboardingComplete) {
          return const _OnboardingPrompt();
        }
        return _buildCalendarView(
          context,
          user,
          profile,
          visibleMonth,
          isEditingSchedule,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorView(
        message: 'Nie udało się załadować profilu użytkownika.',
        detailed: error.toString(),
      ),
    );
  }

  Widget _buildCalendarView(
    BuildContext context,
    User user,
    UserProfile profile,
    DateTime visibleMonth,
    bool isEditingSchedule,
  ) {
    final entriesAsync = ref.watch(
      calendarEntriesStreamProvider(
        CalendarEntriesRequest(userId: user.uid, month: visibleMonth),
      ),
    );

    final controller = ref.read(homeControllerProvider.notifier);

    return entriesAsync.when(
      data: (entries) => _CalendarContent(
        month: visibleMonth,
        profile: profile,
        entries: entries,
        cycle: _cycle,
        isEditing: isEditingSchedule,
        onMonthChanged: _handleMonthChanged,
        onDayTap: (day) => _openDayDialog(context, user, profile, entries, day),
        onToggleEditing: controller.toggleScheduleEditing,
        onToggleScheduled: (day, assign) async {
          try {
            if (assign) {
              await controller.assignScheduledService(
                userId: user.uid,
                day: day,
              );
            } else {
              await controller.removeScheduledService(
                userId: user.uid,
                day: day,
              );
            }
            if (!context.mounted) {
              return;
            }
            final message = assign
                ? 'Dodano służbę 24h do harmonogramu.'
                : 'Usunięto służbę 24h z harmonogramu.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (error) {
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Nie udało się zaktualizować harmonogramu: $error',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
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
    ).then((result) async {
      if (result == null) {
        return;
      }

      final controller = ref.read(homeControllerProvider.notifier);
      try {
        await controller.saveDayDetails(
          userId: user.uid,
          day: selectedDay,
          events: result.events,
          incidents: result.incidents,
          generalNote: result.generalNote,
          scheduledHours: result.scheduledHours,
        );
        if (!context.mounted) {
          return;
        }
        final hasSchedule = result.scheduledHours != null;
    final hasData =
      result.events.isNotEmpty ||
      result.incidents.isNotEmpty ||
      result.generalNote.trim().isNotEmpty ||
      (hasSchedule && (result.scheduledHours ?? 0) > 0);
        final feedback = hasData
            ? 'Zapisano szczegóły dnia.'
            : 'Wyczyszczono dane dnia.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(feedback),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się zapisać dnia: $error'),
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
    required this.isEditing,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.onToggleEditing,
    required this.onToggleScheduled,
  });

  final DateTime month;
  final UserProfile profile;
  final List<CalendarEntry> entries;
  final ShiftCycleCalculator cycle;
  final bool isEditing;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onToggleEditing;
  final Future<void> Function(DateTime day, bool assign) onToggleScheduled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 24,
        );
        double cardHeight;
        if (constraints.maxHeight.isFinite &&
            constraints.maxHeight > padding.vertical) {
          cardHeight = constraints.maxHeight - padding.vertical;
        } else {
          final media =
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.vertical -
              padding.vertical;
          cardHeight = media.isFinite && media > 0 ? media : 600;
        }

        return Scaffold(
          body: Padding(
            padding: padding,
            child: SizedBox(
              height: cardHeight,
              child: ShiftMonthCalendar(
                initialMonth: month,
                userProfile: profile,
                entries: entries,
                shiftCycleCalculator: cycle,
                onDaySelected: onDayTap,
                onMonthChanged: onMonthChanged,
                isEditing: isEditing,
                onEditModeToggle: onToggleEditing,
                onToggleScheduledService: onToggleScheduled,
              ),
            ),
          ),
          floatingActionButton: ScheduleFab(
            onScheduleEditToggle: onToggleEditing,
            isEditing: isEditing,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

class _OnboardingPrompt extends StatelessWidget {
  const _OnboardingPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Witaj w aplikacji Iskra!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Aby korzystać z kalendarza i innych funkcji, musisz najpierw skonfigurować swoje podstawowe dane.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutePath.onboarding),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Rozpocznij konfigurację'),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              detailed,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
