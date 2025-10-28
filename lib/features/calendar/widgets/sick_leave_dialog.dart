import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

enum SickLeaveType { eightyPercent, hundredPercent }

class SickLeaveDialog extends ConsumerStatefulWidget {
  const SickLeaveDialog({super.key});

  static Future<void> show({required BuildContext context}) {
    return showDialog(
      context: context,
      builder: (_) => const SickLeaveDialog(),
    );
  }

  @override
  ConsumerState<SickLeaveDialog> createState() => _SickLeaveDialogState();
}

class _SickLeaveDialogState extends ConsumerState<SickLeaveDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  SickLeaveType _sickLeaveType = SickLeaveType.eightyPercent;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Dodaj zwolnienie lekarskie',
        style: theme.textTheme.headlineSmall,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: _buildContent(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _isLoading || !_canSave ? null : _saveSickLeave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Zapisz'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    if (user == null) {
      return const Center(
        child: Text('Użytkownik nie jest zalogowany'),
      );
    }

    final userProfile = ref.watch(
      userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)),
    );

    return userProfile.when(
      data: (profile) => _buildSickLeaveForm(profile),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Błąd ładowania profilu: $error'),
      ),
    );
  }

  Widget _buildSickLeaveForm(UserProfile profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sick leave type selection
        _buildSickLeaveTypeSelection(),

        const SizedBox(height: 16),

        // Date selection
        _buildDateSelection(),

        const SizedBox(height: 16),

        // Hours calculation
        if (_startDate != null && _endDate != null)
          _buildHoursCalculation(),

        const SizedBox(height: 16),

        // Info
        _buildInfo(),
      ],
    );
  }

  Widget _buildSickLeaveTypeSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rodzaj zwolnienia',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<SickLeaveType>(
          segments: const [
            ButtonSegment(
              value: SickLeaveType.eightyPercent,
              label: Text('80%'),
              icon: Icon(Icons.medical_services),
            ),
            ButtonSegment(
              value: SickLeaveType.hundredPercent,
              label: Text('100%'),
              icon: Icon(Icons.local_hospital),
            ),
          ],
          selected: {_sickLeaveType},
          onSelectionChanged: (selection) {
            setState(() {
              _sickLeaveType = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Okres zwolnienia',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Od',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                'Do',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onChanged,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}.${date.month}.${date.year}'
                        : 'Wybierz datę',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoursCalculation() {
    final days = _calculateSickLeaveDays();
    final hours = _calculateSickLeaveHours();

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Podsumowanie zwolnienia',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Dni', days.toString()),
                ),
                Expanded(
                  child: _buildSummaryItem('Godziny', '${hours.toStringAsFixed(1)}h'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Zwolnienie lekarskie jest traktowane jako płatna nieobecność i nie wpływa na stan urlopów.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSickLeaveDays() {
    if (_startDate == null || _endDate == null) return 0;

    final difference = _endDate!.difference(_startDate!).inDays;
    return difference + 1; // +1 bo włączamy dzień końcowy
  }

  double _calculateSickLeaveHours() {
    final days = _calculateSickLeaveDays();
    final percentage = _sickLeaveType == SickLeaveType.eightyPercent ? 0.8 : 1.0;
    // Zakładamy 8 godzin pracy dziennie
    return days * 8.0 * percentage;
  }

  bool get _canSave {
    return _startDate != null &&
           _endDate != null &&
           _startDate!.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  Future<void> _saveSickLeave() async {
    if (!_canSave) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      final repository = ref.read(calendarEntryRepositoryProvider);

      // Create sick leave event
      final eventType = _sickLeaveType == SickLeaveType.eightyPercent
          ? EventType.sickLeave80
          : EventType.sickLeave100;

      final sickLeaveEvent = DayEvent(
        type: eventType,
        hours: _calculateSickLeaveHours() / _calculateSickLeaveDays(), // Hours per day
      );

      // Save sick leave for each day in the range
      final currentDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

      for (var date = currentDate;
          date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
          date = date.add(const Duration(days: 1))) {

        // Check if it's a weekend (Saturday = 6, Sunday = 7)
        if (date.weekday == 6 || date.weekday == 7) {
          continue; // Skip weekends for sick leave
        }

        await repository.saveDayDetails(
          userId: user.uid,
          day: date,
          events: [sickLeaveEvent],
          incidents: const [],
          note: '',
          scheduledHours: null, // Don't change scheduled hours
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zwolnienie lekarskie zostało dodane')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas zapisywania: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}