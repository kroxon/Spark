import 'package:flutter/material.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/vacation_models.dart';
import 'vacation_balance_display.dart';
import 'vacation_type_selector.dart';
import 'vacation_calendar_selector.dart';
import 'vacation_hours_calculator.dart';
import 'vacation_schedule_info.dart';

class VacationForm extends StatefulWidget {
  const VacationForm({
    super.key,
    required this.userProfile,
    required this.onVacationTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onHoursCalculated,
    required this.calculatePotentialHours,
  });

  final UserProfile userProfile;
  final ValueChanged<VacationType> onVacationTypeChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<double> onHoursCalculated;
  final Future<double> Function(DateTime?, DateTime?, UserProfile) calculatePotentialHours;

  @override
  State<VacationForm> createState() => _VacationFormState();
}

class _VacationFormState extends State<VacationForm> {
  DateTime? _startDate;
  DateTime? _endDate;
  VacationType _vacationType = VacationType.regular;
  double _potentialConsumedHours = 0;

  @override
  void didUpdateWidget(VacationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate hours when dates change
    if (_startDate != null && _endDate != null) {
      _calculatePotentialConsumedHours();
    }
  }

  Future<void> _calculatePotentialConsumedHours() async {
    if (_startDate != null && _endDate != null) {
      final hours = await widget.calculatePotentialHours(_startDate, _endDate, widget.userProfile);
      setState(() => _potentialConsumedHours = hours);
      widget.onHoursCalculated(hours);
    } else {
      setState(() => _potentialConsumedHours = 0);
      widget.onHoursCalculated(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vacation balance info
        VacationBalanceDisplay(profile: widget.userProfile),

        const SizedBox(height: 16),

        // Vacation type selection
        VacationTypeSelector(
          selectedType: _vacationType,
          onTypeChanged: (type) {
            setState(() => _vacationType = type);
            widget.onVacationTypeChanged(type);
          },
        ),

        const SizedBox(height: 16),

        // Date selection
        VacationCalendarSelector(
          userProfile: widget.userProfile,
          startDate: _startDate,
          endDate: _endDate,
          potentialConsumedHours: _potentialConsumedHours,
          onRangeSelected: (start, end, focusedDay) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
            widget.onStartDateChanged(start);
            widget.onEndDateChanged(end);
          },
        ),

        const SizedBox(height: 16),

        // Hours calculation
        if (_startDate != null && _endDate != null)
          VacationHoursCalculator(
            days: _calculateVacationDays(),
            hours: _potentialConsumedHours,
          ),

        const SizedBox(height: 16),

        // Schedule info
        const VacationScheduleInfo(),
      ],
    );
  }

  int _calculateVacationDays() {
    if (_startDate == null || _endDate == null) return 0;

    final difference = _endDate!.difference(_startDate!).inDays;
    return difference + 1; // +1 bo włączamy dzień końcowy
  }
}