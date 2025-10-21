import 'package:flutter/material.dart';

class DayScheduleHoursPicker extends StatefulWidget {
  const DayScheduleHoursPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = const [24, 16, 8, 0],
  });

  final double value;
  final ValueChanged<double> onChanged;
  final List<double> options;

  @override
  State<DayScheduleHoursPicker> createState() => _DayScheduleHoursPickerState();
}

class _DayScheduleHoursPickerState extends State<DayScheduleHoursPicker> {
  bool _isExpanded = false;
  int _visibleOptionCount = 0;
  int _animationGeneration = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final displayValue = _formatValue(widget.value);
    final options = _sortedOptions();
    final visibleOptions = options.take(_visibleOptionCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Godziny z harmonogramu półrocznego/rocznego',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SchedulePill(
                label: displayValue,
                isActive: false,
                onTap: options.isEmpty ? null : _toggle,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                child: (_isExpanded || visibleOptions.isNotEmpty)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 12),
                          ...visibleOptions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final option = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? 0 : 8,
                              ),
                              child: _SchedulePill(
                                label: _formatValue(option),
                                isActive: option == widget.value,
                                onTap: () => _select(option),
                              ),
                            );
                          }),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggle() {
    final options = _sortedOptions();
    if (options.isEmpty) {
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
      _animationGeneration++;
      if (!_isExpanded) {
        _visibleOptionCount = 0;
      }
    });

    if (_isExpanded) {
      final generation = _animationGeneration;
      for (var i = 0; i < options.length; i++) {
        Future.delayed(Duration(milliseconds: 80 * (i + 1)), () {
          if (!mounted) return;
          if (!_isExpanded || _animationGeneration != generation) return;
          setState(() {
            _visibleOptionCount = i + 1;
          });
        });
      }
    }
  }

  void _select(double value) {
    widget.onChanged(value);
    setState(() {
      _isExpanded = false;
      _visibleOptionCount = 0;
      _animationGeneration++;
    });
  }

  List<double> _sortedOptions() {
    return widget.options.toSet().toList()..sort((a, b) => b.compareTo(a));
  }

  String _formatValue(double value) {
    if (value <= 0) {
      return '0';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }
}

class _SchedulePill extends StatelessWidget {
  const _SchedulePill({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = isActive ? colors.onPrimary : colors.onSurface;
    final background = isActive
        ? colors.primary
        : colors.surfaceContainerHighest;
    final borderColor = isActive
        ? colors.primary
        : colors.outlineVariant.withValues(alpha: 0.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
