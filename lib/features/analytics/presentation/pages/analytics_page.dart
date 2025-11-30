import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iskra/core/navigation/app_shell.dart';
import 'package:iskra/core/navigation/nav_destinations.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/analytics/application/stats_controller.dart';
import 'package:iskra/features/analytics/domain/stats_models.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  late int _year;
  int _animationKey = 0;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  void _changeYear(int increment) {
    HapticFeedback.selectionClick();
    setState(() => _year = _year + increment);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    // Invalidate providers to force re-fetch
    ref.invalidate(vacationBalanceProvider);
    ref.invalidate(incidentStatsProvider(_year));
    ref.invalidate(overtimeStatsProvider);
    // Wait a bit to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final theme = Theme.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final profileAsync = ref.watch(
      userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)),
    );

    return profileAsync.when(
      data: (profile) {
        if (profile == null || !profile.isOnboardingComplete) {
          return const _OnboardingPrompt();
        }
        return _buildAnalyticsView(context, ref, theme);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Błąd ładowania profilu: $error'),
      ),
    );
  }

  Widget _buildAnalyticsView(BuildContext context, WidgetRef ref, ThemeData theme) {
    // Listen to tab changes to trigger animation replay
    ref.listen(currentNavIndexProvider, (previous, next) {
      if (next == AppSections.statistics.branchIndex) {
        setState(() => _animationKey++);
      }
    });

    final vacation = ref.watch(vacationBalanceProvider);
    final incidents = ref.watch(incidentStatsProvider(_year));
    final overtime = ref.watch(overtimeStatsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          displacement: 20,
          edgeOffset: 0,
          child: KeyedSubtree(
            key: ValueKey(_animationKey),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Vacation Section
                      vacation.when(
                        loading: () => const _ShimmerSkeleton(height: 180),
                        error: (e, _) => _ErrorCard(message: 'Nie udało się pobrać salda urlopów'),
                        data: (data) => _ModernVacationCard(balance: data),
                      ),

                      const SizedBox(height: 40),

                      // Incidents Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionHeader(title: 'Wyjazdy', icon: Icons.local_fire_department_rounded),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => _changeYear(-1),
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  tooltip: 'Poprzedni rok',
                                  visualDensity: VisualDensity.compact,
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) => FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(scale: animation, child: child),
                                  ),
                                  child: Text(
                                    '$_year',
                                    key: ValueKey(_year),
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _changeYear(1),
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  tooltip: 'Następny rok',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      incidents.when(
                        loading: () => const _ShimmerSkeleton(height: 160),
                        error: (e, _) => _ErrorCard(message: 'Błąd statystyk wyjazdów'),
                        data: (s) => Column(
                          children: [
                            _CompactStatsGrid(stats: s),
                            const SizedBox(height: 24),
                            _IncidentsChart(stats: s),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Overtime Section
                      _SectionHeader(title: 'Nadgodziny', icon: Icons.access_time_filled_rounded),
                      const SizedBox(height: 16),
                      overtime.when(
                        loading: () => const _ShimmerSkeleton(height: 160),
                        error: (e, _) => _ErrorCard(message: 'Błąd statystyk nadgodzin'),
                        data: (periods) => Column(
                          children: periods
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _ModernOvertimeCard(period: p),
                                  ))
                              .toList(),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IncidentsChart extends StatelessWidget {
  const _IncidentsChart({required this.stats});
  final IncidentYearStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Find max value for Y axis scaling (sum of all categories)
    int maxY = 0;
    for (final m in stats.monthlyStats) {
      final total = m.total;
      if (total > maxY) maxY = total;
    }
    // Add some padding to top
    maxY = (maxY * 1.2).ceil();
    if (maxY < 5) maxY = 5;

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY.toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => const Color(0xFF263238),
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final monthStat = stats.monthlyStats[group.x.toInt()];
                      final monthName = _getMonthName(monthStat.month);
                      return BarTooltipItem(
                        '$monthName\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '🔥 Pożary: ${monthStat.fires}\n',
                            style: const TextStyle(
                              color: Color(0xFFFF5252),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '⚠️ MZ: ${monthStat.localHazards}\n',
                            style: const TextStyle(
                              color: Color(0xFF448AFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '🚫 AF: ${monthStat.falseAlarms}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 12) return const SizedBox();
                        
                        final style = TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(_getMonthShortName(index + 1), style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (maxY / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).ceilToDouble(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: stats.monthlyStats.asMap().entries.map((e) {
                  final index = e.key;
                  final stat = e.value;
                  final total = stat.total;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: total.toDouble(),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        rodStackItems: [
                          BarChartRodStackItem(0, stat.falseAlarms.toDouble(), Colors.grey),
                          BarChartRodStackItem(
                            stat.falseAlarms.toDouble(), 
                            (stat.falseAlarms + stat.localHazards).toDouble(), 
                            const Color(0xFF448AFF),
                          ),
                          BarChartRodStackItem(
                            (stat.falseAlarms + stat.localHazards).toDouble(), 
                            total.toDouble(), 
                            const Color(0xFFFF5252),
                          ),
                        ],
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY.toDouble(),
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 600),
              swapAnimationCurve: Curves.easeOutQuart,
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendItem(color: const Color(0xFFFF5252), label: 'Pożar'),
              const SizedBox(width: 16),
              _ChartLegendItem(color: const Color(0xFF448AFF), label: 'MZ'),
              const SizedBox(width: 16),
              _ChartLegendItem(color: Colors.grey, label: 'AF'),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthShortName(int month) {
    const months = [
      'Sty', 'Lut', 'Mar', 'Kwi', 'Maj', 'Cze',
      'Lip', 'Sie', 'Wrz', 'Paź', 'Lis', 'Gru'
    ];
    return months[month - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
      'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
    ];
    return months[month - 1];
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}



class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _ModernVacationCard extends StatelessWidget {
  const _ModernVacationCard({required this.balance});
  final VacationBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF000000)]
              : [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF4facfe)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dostępny Urlop',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _AnimatedCount(
                          value: balance.totalHours,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                          suffix: ' h',
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.luggage_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _VacationProgressBar(
                  label: 'Wypoczynkowy',
                  value: balance.standardHours,
                  total: balance.totalHours > 0 ? balance.totalHours : 1,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                _VacationProgressBar(
                  label: 'Dodatkowy',
                  value: balance.additionalHours,
                  total: balance.totalHours > 0 ? balance.totalHours : 1,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VacationProgressBar extends StatelessWidget {
  const _VacationProgressBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final double value;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '${value.toStringAsFixed(0)} h',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (value / total).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutExpo,
            builder: (context, val, _) {
              return LinearProgressIndicator(
                value: val,
                backgroundColor: Colors.black.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactStatsGrid extends StatelessWidget {
  const _CompactStatsGrid({required this.stats});
  final IncidentYearStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactStatItem(
                  label: 'Pożary',
                  value: stats.fires,
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF5252),
                  delay: 0,
                ),
              ),
              Container(width: 1, height: 60, color: theme.dividerColor.withOpacity(0.1)),
              Expanded(
                child: _CompactStatItem(
                  label: 'Miejscowe',
                  value: stats.localHazards,
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFFB74D),
                  delay: 100,
                ),
              ),
            ],
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          Row(
            children: [
              Expanded(
                child: _CompactStatItem(
                  label: 'Alarmy Fałszywe',
                  value: stats.falseAlarms,
                  icon: Icons.notifications_off_rounded,
                  color: const Color(0xFF90A4AE),
                  delay: 200,
                ),
              ),
              Container(width: 1, height: 60, color: theme.dividerColor.withOpacity(0.1)),
              Expanded(
                child: _CompactStatItem(
                  label: 'Dni Wyjazdowe',
                  value: stats.callDays,
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF4DB6AC),
                  delay: 300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  const _CompactStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - anim)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AnimatedCount(
                    value: value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _ModernOvertimeCard extends StatelessWidget {
  const _ModernOvertimeCard({required this.period});
  final OvertimePeriodStats period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('d MMM', 'pl');
    final balance = period.balance;
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    final totalScale = (period.workedHours + period.takenOffHours).clamp(1, double.infinity);
    final workedPct = (period.workedHours / totalScale).clamp(0.0, 1.0);
    final offPct = (period.takenOffHours / totalScale).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: period.isCurrent ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.date_range_rounded,
                  color: period.isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.label,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${df.format(period.start)} - ${df.format(period.end)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: balanceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 14,
                      color: balanceColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${balance.abs().toStringAsFixed(1)} h',
                      style: TextStyle(
                        color: balanceColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (workedPct * 100).round(),
                    child: Container(color: const Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (offPct * 100).round(),
                    child: Container(color: const Color(0xFFFF9800)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(
                color: const Color(0xFF4CAF50),
                label: 'Praca',
                value: period.workedHours,
              ),
              _LegendItem(
                color: const Color(0xFFFF9800),
                label: 'Odbiór',
                value: period.takenOffHours,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          '${value.toStringAsFixed(1)}h',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({
    required this.value,
    this.style,
    this.suffix = '',
  });

  final num value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutQuart,
      builder: (context, val, child) {
        return Text(
          '${val.toInt()}$suffix',
          style: style,
        );
      },
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  const _ShimmerSkeleton({this.height = 120});
  final double height;

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                Color.alphaBlend(
                  theme.colorScheme.onSurface.withOpacity(0.1),
                  theme.colorScheme.surfaceContainerHighest,
                ),
                theme.colorScheme.surfaceContainerHighest,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + (_controller.value * 3), -0.3),
              end: Alignment(1.0 + (_controller.value * 3), 0.3),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
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
                Icons.analytics,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Statystyki niedostępne',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Aby zobaczyć statystyki, musisz najpierw skonfigurować swoje podstawowe dane.',
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
