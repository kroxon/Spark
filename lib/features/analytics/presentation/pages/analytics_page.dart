import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iskra/features/analytics/application/stats_controller.dart';
import 'package:iskra/features/analytics/domain/stats_models.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final theme = Theme.of(context);

    final vacation = ref.watch(vacationBalanceProvider);
    final incidents = ref.watch(incidentStatsProvider(_year));
    final overtime = ref.watch(overtimeStatsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statystyki', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Vacation balances
            vacation.when(
              loading: () => const _SkeletonCard(height: 96),
              error: (e, _) => _ErrorText('Nie udało się pobrać salda urlopów'),
              data: (data) => _VacationCard(balance: data),
            ),

            const SizedBox(height: 16),

            // Yearly incidents header with arrows
            Row(
              children: [
                IconButton(
                  tooltip: 'Poprzedni rok',
                  onPressed: () => setState(() => _year = _year - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text('Wyjazdy $_year', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                IconButton(
                  tooltip: 'Następny rok',
                  onPressed: () => setState(() => _year = _year + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            incidents.when(
              loading: () => const _SkeletonCard(height: 140),
              error: (e, _) => _ErrorText('Nie udało się obliczyć statystyk wyjazdów'),
              data: (s) => _IncidentStatsGrid(stats: s),
            ),

            const SizedBox(height: 16),
            Text('Nadgodziny', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            overtime.when(
              loading: () => const _SkeletonCard(height: 160),
              error: (e, _) => _ErrorText('Nie udało się pobrać statystyk nadgodzin'),
              data: (periods) => _OvertimeSection(periods: periods),
            ),
          ],
        ),
      ),
    );
  }
}

class _VacationCard extends StatelessWidget {
  const _VacationCard({required this.balance});
  final VacationBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = balance.totalHours;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _CircleBadge(icon: Icons.beach_access_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Urlop — stan bieżący', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _ChipStat(label: 'Wypoczynkowy', value: balance.standardHours),
                      _ChipStat(label: 'Dodatkowy', value: balance.additionalHours),
                      _ChipStat(label: 'Razem', value: total, highlighted: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentStatsGrid extends StatelessWidget {
  const _IncidentStatsGrid({required this.stats});
  final IncidentYearStats stats;

  @override
  Widget build(BuildContext context) {
    const callDaysLabel = 'Dni wyjazdowe';
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      children: [
        _KpiCard(title: 'Pożary', value: stats.fires, icon: Icons.local_fire_department_rounded, color: Colors.deepOrange),
        _KpiCard(title: 'Miejscowe zagrożenia', value: stats.localHazards, icon: Icons.warning_amber_rounded, color: Colors.amber),
        _KpiCard(title: 'Fałszywe alarmy', value: stats.falseAlarms, icon: Icons.report_gmailerrorred_rounded, color: Colors.blueGrey),
        _KpiCard(title: callDaysLabel, value: stats.callDays, icon: Icons.today_rounded, color: Colors.teal),
      ],
    );
  }
}

class _OvertimeSection extends StatelessWidget {
  const _OvertimeSection({required this.periods});
  final List<OvertimePeriodStats> periods;

  @override
  Widget build(BuildContext context) {
    final cards = periods
        .map((p) => _OvertimeCard(period: p))
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 720) {
          return Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ]);
        }
        return Column(children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
        ]);
      },
    );
  }
}

class _OvertimeCard extends StatelessWidget {
  const _OvertimeCard({required this.period});
  final OvertimePeriodStats period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('d.MM.yyyy');
    final balance = period.balance;
    final color = balance >= 0 ? Colors.green : theme.colorScheme.error;
    final range = '${df.format(period.start)} — ${df.format(period.end)}';

    final totalScale = (period.workedHours + period.takenOffHours).clamp(1, double.infinity);
    final workedPct = (period.workedHours / totalScale).clamp(0.0, 1.0);
    final offPct = (period.takenOffHours / totalScale).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              _CircleBadge(icon: Icons.trending_up_rounded, color: period.isCurrent ? theme.colorScheme.primary : theme.colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(period.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(range, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${balance.toStringAsFixed(1)} h', style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(workedPct: workedPct, offPct: offPct),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _LegendTile(color: Colors.green, label: 'Przepracowane', value: period.workedHours)),
            Expanded(child: _LegendTile(color: Colors.orange, label: 'Odebrane', value: period.takenOffHours)),
          ]),
        ]),
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
      Text('${value.toStringAsFixed(1)} h', style: theme.textTheme.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.workedPct, required this.offPct});
  final double workedPct;
  final double offPct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(flex: (workedPct * 1000).round(), child: Container(decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)))),
        Expanded(flex: (offPct * 1000).round(), child: Container(decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)))),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _CircleBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('$value', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
          ])),
        ]),
      ),
    );
  }
}

class _CircleBadge extends StatelessWidget {
  const _CircleBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [color.withOpacity(0.75), color]),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.label, required this.value, this.highlighted = false});
  final String label;
  final double value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlighted ? theme.colorScheme.primary.withOpacity(0.12) : theme.colorScheme.surfaceContainerHighest;
    final fg = highlighted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fg)),
        const SizedBox(width: 8),
        Text('${value.toStringAsFixed(0)} h', style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
}
