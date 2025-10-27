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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sortedOptions = _sortedOptions();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Godziny z harmonogramu półrocznego/rocznego',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        if (_isExpanded) ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: sortedOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                  child: _SchedulePill(
                    label: _formatValue(option),
                    isActive: option == widget.value,
                    onTap: () => _select(option),
                  ),
                );
              }).toList(),
            ),
          ),
        ] else ...[
          _SchedulePill(
            label: _formatValue(widget.value),
            isActive: true,
            onTap: () => setState(() => _isExpanded = true),
          ),
        ],
      ],
    );
  }

  void _select(double value) {
    widget.onChanged(value);
    setState(() => _isExpanded = false);
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
