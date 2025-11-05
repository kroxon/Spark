import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/system_settings/application/shift_history_controller.dart';
import 'package:iskra/features/calendar/models/shift_color_palette.dart';

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
      appBar: AppBar(
        title: const Text('Historia przydziału do zmian'),
        actions: [
          IconButton(
            tooltip: 'Dodaj okres',
            icon: const Icon(Icons.add),
            onPressed: () => _openUpsertPeriodSheet(context, profile),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final p = periods[index];
          final isCurrent = p.end == null;
          final color = profile.shiftColorPalette.colorForShift(p.shiftId);
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(width: 6, height: double.infinity, color: color),
                Expanded(
                  child: ListTile(
                    onTap: () => _openUpsertPeriodSheet(context, profile, initial: p),
                    title: Text('Zmiana ${p.shiftId}'),
                    subtitle: Text('${_labelMonth(p.start)} – ${isCurrent ? 'teraz' : _labelMonth(p.end!)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent) const _NowBadge(),
                        PopupMenuButton<String>(
                          tooltip: 'Więcej',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openUpsertPeriodSheet(context, profile, initial: p);
                            } else if (value == 'delete') {
                              _confirmDelete(context, profile, p);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                            PopupMenuItem(value: 'delete', child: Text('Usuń')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: periods.length,
      ),
    );
  }

  void _openUpsertPeriodSheet(BuildContext context, UserProfile profile, { _Period? initial }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _UpsertPeriodSheet(profile: profile, initial: initial),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserProfile profile, _Period p) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć okres?'),
        content: Text('Zmiana ${p.shiftId}: ${_labelMonth(p.start)} – ${p.end == null ? 'teraz' : _labelMonth(p.end!)}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final controller = ref.read(shiftHistoryControllerProvider.notifier);
      await controller.deletePeriod(uid: profile.uid, current: profile.shiftHistory, startMonth: p.start);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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

class _UpsertPeriodSheet extends ConsumerStatefulWidget {
  const _UpsertPeriodSheet({required this.profile, this.initial});
  final UserProfile profile;
  final _Period? initial;

  @override
  ConsumerState<_UpsertPeriodSheet> createState() => _UpsertPeriodSheetState();
}

class _UpsertPeriodSheetState extends ConsumerState<_UpsertPeriodSheet> {
  late int _shiftId;
  late DateTime _start;
  DateTime? _end; // inclusive month; null => to now
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _shiftId = widget.initial?.shiftId ?? 1;
    _start = widget.initial?.start ?? DateTime.utc(DateTime.now().year, DateTime.now().month, 1);
    _end = widget.initial?.end == null ? null : DateTime.utc(widget.initial!.end!.year, widget.initial!.end!.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initial == null ? 'Dodaj okres zmian' : 'Edytuj okres zmian',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zmiana', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _ShiftSelector(
                      selected: _shiftId,
                      palette: widget.profile.shiftColorPalette,
                      onSelected: (id) => setState(() => _shiftId = id),
                    ),
                    const SizedBox(height: 16),
                    Text('Zakres miesięcy', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _RangeField(
                      start: _start,
                      end: _end,
                      onTap: () async {
                        final result = await showDialog<_MonthRangeResult>(
                          context: context,
                          builder: (_) => _MonthRangeDialog(
                            initialStart: _start,
                            initialEnd: _end,
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _start = result.start;
                            _end = result.end;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(children: [Checkbox(value: _end == null, onChanged: (v) => setState(() => _end = v == true ? null : _start)), const Text('Do teraz')]),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting ? null : () => _submit(),
                            child: _submitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(widget.initial == null ? 'Zapisz okres' : 'Zapisz zmiany'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        );

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: insets),
            child: content,
          ),
        );
      },
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

}
 
class _ShiftSelector extends StatelessWidget {
  const _ShiftSelector({required this.selected, required this.palette, required this.onSelected});
  final int selected;
  final ShiftColorPalette palette;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [1, 2, 3];
    return Row(
      children: items.map((id) {
        final color = palette.colorForShift(id);
        final sel = id == selected;
        final bg = sel ? color : color.withOpacity(0.18);
        final border = color.withOpacity(0.64);
        final textColor = _bestOnColor(color, sel);
        final radius = BorderRadius.horizontal(
          left: id == 1 ? const Radius.circular(12) : Radius.zero,
          right: id == 3 ? const Radius.circular(12) : Radius.zero,
        );
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: bg,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: border, width: sel ? 2 : 1),
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: () => onSelected(id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text('$id', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _bestOnColor(Color base, bool selected) {
    // If selected, ensure strong contrast; otherwise use onSurface
    if (!selected) return Colors.black87;
    return base.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

class _RangeField extends StatelessWidget {
  const _RangeField({required this.start, required this.end, required this.onTap});
  final DateTime start;
  final DateTime? end;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${_labelMonth(start)} – ${end == null ? 'teraz' : _labelMonth(end!)}'),
            ),
            const Icon(Icons.edit_calendar_outlined, size: 20),
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

class _MonthRangeResult {
  final DateTime start;
  final DateTime? end;
  const _MonthRangeResult(this.start, this.end);
}

class _MonthRangeDialog extends StatefulWidget {
  const _MonthRangeDialog({required this.initialStart, required this.initialEnd});
  final DateTime initialStart;
  final DateTime? initialEnd;
  @override
  State<_MonthRangeDialog> createState() => _MonthRangeDialogState();
}

class _MonthRangeDialogState extends State<_MonthRangeDialog> {
  late int _startYear;
  late int _startMonth;
  late int _endYear;
  late int _endMonth;
  bool _toNow = false;

  @override
  void initState() {
    super.initState();
    _startYear = widget.initialStart.year;
    _startMonth = widget.initialStart.month;
    _toNow = widget.initialEnd == null;
    final end = widget.initialEnd ?? DateTime.now().toUtc();
    _endYear = end.year;
    _endMonth = end.month;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 560;
    return AlertDialog(
      title: const Text('Wybierz zakres miesięcy'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _monthPanel(context, 'Początek', _startYear, _startMonth, onYear: (y) => setState(() => _startYear = y), onMonth: (m) => setState(() => _startMonth = m))),
                  const SizedBox(width: 16),
                  Expanded(child: Opacity(
                    opacity: _toNow ? 0.5 : 1,
                    child: IgnorePointer(
                      ignoring: _toNow,
                      child: _monthPanel(context, 'Koniec', _endYear, _endMonth, onYear: (y) => setState(() => _endYear = y), onMonth: (m) => setState(() => _endMonth = m)),
                    ),
                  )),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _monthPanel(context, 'Początek', _startYear, _startMonth, onYear: (y) => setState(() => _startYear = y), onMonth: (m) => setState(() => _startMonth = m)),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: _toNow ? 0.5 : 1,
                    child: IgnorePointer(
                      ignoring: _toNow,
                      child: _monthPanel(context, 'Koniec', _endYear, _endMonth, onYear: (y) => setState(() => _endYear = y), onMonth: (m) => setState(() => _endMonth = m)),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        Row(
          children: [
            Checkbox(value: _toNow, onChanged: (v) => setState(() => _toNow = v ?? false)),
            const Text('Do teraz'),
            const Spacer(),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Anuluj')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSubmit() ? _submit : null,
              child: const Text('Wybierz'),
            ),
          ],
        ),
      ],
    );
  }

  bool _canSubmit() {
    if (_toNow) return true;
    final start = DateTime.utc(_startYear, _startMonth, 1);
    final endExclusive = DateTime.utc(_endYear, _endMonth + 1, 1);
    return endExclusive.isAfter(start);
  }

  void _submit() {
    final start = DateTime.utc(_startYear, _startMonth, 1);
    final DateTime? end = _toNow ? null : DateTime.utc(_endYear, _endMonth, 1);
    Navigator.of(context).pop(_MonthRangeResult(start, end));
  }

  Widget _monthPanel(
    BuildContext context,
    String title,
    int year,
    int month, {
    required ValueChanged<int> onYear,
    required ValueChanged<int> onMonth,
  }) {
    final months = const <String>['Stycz', 'Luty', 'Mar', 'Kwie', 'Maj', 'Czer', 'Lip', 'Sier', 'Wrze', 'Paź', 'List', 'Grud'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            IconButton(onPressed: () => onYear(year - 1), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Center(child: Text('$year', style: const TextStyle(fontWeight: FontWeight.w600)))),
            IconButton(onPressed: () => onYear(year + 1), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (i) => i + 1).map((m) {
            final selected = m == month;
            return ChoiceChip(
              label: Text(months[m - 1]),
              selected: selected,
              onSelected: (_) => onMonth(m),
            );
          }).toList(),
        ),
      ],
    );
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
