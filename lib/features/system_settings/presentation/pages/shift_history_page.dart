import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/system_settings/application/shift_history_controller.dart';

class ShiftHistoryPage extends ConsumerStatefulWidget {
  const ShiftHistoryPage({super.key});

  @override
  ConsumerState<ShiftHistoryPage> createState() => _ShiftHistoryPageState();
}

class _ShiftHistoryPageState extends ConsumerState<ShiftHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Brak zalogowanego użytkownika')));
    }

    final profileAsync = ref.watch(userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)));

    return profileAsync.when(
      data: (profile) => _buildScaffold(context, profile),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Błąd wczytywania profilu: $e'))),
    );
  }

  Widget _buildScaffold(BuildContext context, UserProfile profile) {
    final periods = _computePeriods(profile.shiftHistory);

    return Scaffold(
      appBar: AppBar(title: const Text('Historia przydziału do zmian')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final p = periods[index];
          final isCurrent = p.end == null;
          return Card(
            child: ListTile(
              title: Text('Zmiana ${p.shiftId}'),
              subtitle: Text('${_labelMonth(p.start)} – ${isCurrent ? 'teraz' : _labelMonth(p.end!)}'),
              trailing: isCurrent
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: _NowBadge(),
                    )
                  : null,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: periods.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPeriodSheet(context, profile),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj okres'),
      ),
    );
  }

  void _openAddPeriodSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddPeriodSheet(profile: profile),
    );
  }

  List<_Period> _computePeriods(List<ShiftAssignment> history) {
    if (history.isEmpty) return const <_Period>[];
    final sorted = List<ShiftAssignment>.from(history)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final periods = <_Period>[];
    for (var i = 0; i < sorted.length; i++) {
      final start = DateTime.utc(sorted[i].startDate.year, sorted[i].startDate.month, 1);
      final shiftId = sorted[i].shiftId;
      DateTime? end;
      if (i + 1 < sorted.length) {
        final nextStart = DateTime.utc(sorted[i + 1].startDate.year, sorted[i + 1].startDate.month, 1);
        end = DateTime.utc(nextStart.year, nextStart.month, 1).subtract(const Duration(days: 1));
      } else {
        end = null; // current until now
      }
      periods.add(_Period(shiftId: shiftId, start: start, end: end));
    }
    return periods;
  }

  String _labelMonth(DateTime date) {
    const months = <String>['styczeń','luty','marzec','kwiecień','maj','czerwiec','lipiec','sierpień','wrzesień','październik','listopad','grudzień'];
    final m = (date.month - 1).clamp(0, 11);
    return '${months[m]} ${date.year}';
  }
}

class _NowBadge extends StatelessWidget {
  const _NowBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('okres obecny', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _AddPeriodSheet extends ConsumerStatefulWidget {
  const _AddPeriodSheet({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_AddPeriodSheet> createState() => _AddPeriodSheetState();
}

class _AddPeriodSheetState extends ConsumerState<_AddPeriodSheet> {
  int _shiftId = 1;
  DateTime _start = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _end; // inclusive month; null => to now
  String? _error;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Dodaj okres zmian', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Zmiana'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                ],
                selected: {_shiftId},
                onSelectionChanged: (s) => setState(() => _shiftId = s.first),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _MonthPickerField(label: 'Początek', value: _start, onTap: () async {
                    final picked = await _pickMonth(context, initial: _start);
                    if (picked != null) setState(() => _start = picked);
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _MonthPickerField(label: 'Koniec', value: _end, hint: 'do teraz', onTap: () async {
                    final picked = await _pickMonth(context, initial: _end ?? _start);
                    setState(() => _end = picked);
                  })),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(value: _end == null, onChanged: (v) => setState(() => _end = v == true ? null : _start)),
                  const Text('Do teraz'),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : () => _submit(),
                  child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Zapisz okres'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { _error = null; _submitting = true; });
    try {
      if (_end != null) {
        final endExclusive = DateTime.utc(_end!.year, _end!.month + 1, 1);
        if (!endExclusive.isAfter(_start)) {
          throw StateError('Koniec okresu musi być po początku.');
        }
      }
      final uid = widget.profile.uid;
      final controller = ref.read(shiftHistoryControllerProvider.notifier);
      await controller.addOrReplacePeriod(
        uid: uid,
        current: widget.profile.shiftHistory,
        shiftId: _shiftId,
        startMonth: _start,
        endMonth: _end,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _submitting = false; });
    }
  }

  Future<DateTime?> _pickMonth(BuildContext context, {required DateTime initial}) async {
    final selected = await showDialog<_YearMonth>(
      context: context,
      builder: (_) => _MonthYearDialog(initial: _YearMonth(initial.year, initial.month)),
    );
    if (selected == null) return null;
    return DateTime.utc(selected.year, selected.month, 1);
  }
}

class _MonthPickerField extends StatelessWidget {
  const _MonthPickerField({required this.label, required this.value, required this.onTap, this.hint});
  final String label;
  final DateTime? value;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? (hint ?? '—') : _labelMonth(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(text),
          ],
        ),
      ),
    );
  }

  String _labelMonth(DateTime date) {
    const months = <String>['styczeń','luty','marzec','kwiecień','maj','czerwiec','lipiec','sierpień','wrzesień','październik','listopad','grudzień'];
    final m = (date.month - 1).clamp(0, 11);
    return '${months[m]} ${date.year}';
  }
}

class _MonthYearDialog extends StatefulWidget {
  const _MonthYearDialog({required this.initial});
  final _YearMonth initial;
  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wybierz miesiąc'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Center(child: Text('$_year', style: const TextStyle(fontWeight: FontWeight.w600))),
              ),
              IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (i) => i + 1).map((m) {
              final selected = m == _month;
              return ChoiceChip(
                label: Text(_monthName(m)),
                selected: selected,
                onSelected: (_) => setState(() => _month = m),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anuluj')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_YearMonth(_year, _month)), child: const Text('Wybierz')),
      ],
    );
  }

  String _monthName(int m) {
    const months = <String>['Styczeń','Luty','Marzec','Kwiecień','Maj','Czerwiec','Lipiec','Sierpień','Wrzesień','Październik','Listopad','Grudzień'];
    return months[(m - 1).clamp(0, 11)];
  }
}

class _YearMonth {
  final int year;
  final int month;
  const _YearMonth(this.year, this.month);
}

class _Period {
  final int shiftId;
  final DateTime start;
  final DateTime? end; // inclusive day; null => current
  const _Period({required this.shiftId, required this.start, required this.end});
}
