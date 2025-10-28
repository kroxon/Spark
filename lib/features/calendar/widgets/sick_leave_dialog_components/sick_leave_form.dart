import 'package:flutter/material.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/controllers/sick_leave_controller.dart';
import 'package:iskra/features/calendar/models/sick_leave_models.dart';
import 'sick_leave_type_selector.dart';
import 'sick_leave_calendar_selector.dart';
import 'sick_leave_hours_calculator.dart';

class SickLeaveForm extends StatefulWidget {
  const SickLeaveForm({
    super.key,
    required this.userProfile,
    required this.controller,
    required this.onSickLeaveTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onHoursCalculated,
  });

  final UserProfile userProfile;
  final SickLeaveController controller;
  final ValueChanged<SickLeaveType> onSickLeaveTypeChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<double> onHoursCalculated;

  @override
  State<SickLeaveForm> createState() => _SickLeaveFormState();
}

class _SickLeaveFormState extends State<SickLeaveForm> {
  DateTime? _startDate;
  DateTime? _endDate;
  SickLeaveType _sickLeaveType = SickLeaveType.eightyPercent;
  double _calculatedHours = 0;
  int _calculatedDays = 0;

  @override
  void didUpdateWidget(SickLeaveForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate when dates change
    if (_startDate != null && _endDate != null) {
      _calculateSickLeaveDetails();
    }
  }

  Future<void> _calculateSickLeaveDetails() async {
    if (_startDate != null && _endDate != null) {
      final hours = await widget.controller.calculateSickLeaveHours(
        startDate: _startDate!,
        endDate: _endDate!,
        sickLeaveType: _sickLeaveType,
      );
      final days = await widget.controller.calculateSickLeaveDays(_startDate!, _endDate!);

      setState(() {
        _calculatedHours = hours;
        _calculatedDays = days;
      });
      widget.onHoursCalculated(hours);
    } else {
      setState(() {
        _calculatedHours = 0;
        _calculatedDays = 0;
      });
      widget.onHoursCalculated(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sick leave type selection
        SickLeaveTypeSelector(
          selectedType: _sickLeaveType,
          onTypeChanged: (type) {
            setState(() => _sickLeaveType = type);
            widget.onSickLeaveTypeChanged(type);
            if (_startDate != null && _endDate != null) {
              _calculateSickLeaveDetails();
            }
          },
        ),

        const SizedBox(height: 16),

        // Date selection
        SickLeaveCalendarSelector(
          startDate: _startDate,
          endDate: _endDate,
          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
            widget.onStartDateChanged(start);
            widget.onEndDateChanged(end);
            _calculateSickLeaveDetails();
          },
        ),

        const SizedBox(height: 16),

        // Hours calculation
        if (_startDate != null && _endDate != null)
          SickLeaveHoursCalculator(
            days: _calculatedDays,
            hours: _calculatedHours,
          ),

        const SizedBox(height: 16),

        // Info
        _buildInfo(),
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
}