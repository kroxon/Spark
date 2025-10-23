import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

class DayQuickStatusSection extends StatefulWidget {
  const DayQuickStatusSection({
    super.key,
    required this.selections,
    required this.scheduledHours,
    required this.onChanged,
  });

  final Map<EventType, double> selections;
  final double? scheduledHours;
  final ValueChanged<Map<EventType, double>> onChanged;

  @override
  State<DayQuickStatusSection> createState() => _DayQuickStatusSectionState();
}

class _DayQuickStatusSectionState extends State<DayQuickStatusSection> {
  late Map<EventType, double> _selections;
  late final Map<EventType, TextEditingController> _controllers;
  Timer? _messageTimer;
  String? _blockedMessage;

  static const List<_QuickStatusOption> _options = <_QuickStatusOption>[
    _QuickStatusOption(
      type: EventType.delegation,
      label: 'Delegacja',
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.bloodDonation,
      label: 'Krwiodawstwo',
      isFixedHours: true,
    ),
    _QuickStatusOption(
      type: EventType.vacationRegular,
      label: 'Urlop wypoczynkowy',
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.vacationAdditional,
      label: 'Urlop dodatkowy',
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.sickLeave80,
      label: 'Zwolnienie lekarskie 80%',
      isFixedHours: true,
    ),
    _QuickStatusOption(
      type: EventType.sickLeave100,
      label: 'Zwolnienie lekarskie 100%',
      isFixedHours: true,
    ),
    _QuickStatusOption(
      type: EventType.overtimeTimeOff,
      label: 'Odbiór nadgodzin',
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.customAbsence,
      label: 'Inna nieobecność',
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.overtimeWorked,
      label: 'Nadgodziny',
      isFixedHours: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selections = Map<EventType, double>.from(widget.selections);
    _controllers = <EventType, TextEditingController>{
      for (final option in _options.where((option) => !option.isFixedHours))
        option.type: TextEditingController(
          text: _formatHours(_selections[option.type]),
        ),
    };
    _enforceScheduleConstraints(notifyParent: true);
  }

  @override
  void didUpdateWidget(DayQuickStatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(widget.selections, oldWidget.selections)) {
      _selections = Map<EventType, double>.from(widget.selections);
      for (final option in _options) {
        final controller = _controllers[option.type];
        if (controller != null) {
          controller.text = _formatHours(_selections[option.type]);
        }
      }
    }
    final sanitized = _enforceScheduleConstraints(notifyParent: true);
    if (sanitized && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleOptions = _visibleOptions();
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final isSingleColumn = constraints.maxWidth < 280;
        final columnsCount = isSingleColumn ? 1 : 2;
        final sliceSize = (visibleOptions.length / columnsCount).ceil();

        List<Widget> buildColumnSlice(int columnIndex) {
          final start = columnIndex * sliceSize;
          final end = math.min(start + sliceSize, visibleOptions.length);
          if (start >= end) {
            return const [];
          }
          final slice = visibleOptions.sublist(start, end);
          return [
            for (var i = 0; i < slice.length; i++) ...[
              _buildOption(slice[i]),
              if (i < slice.length - 1) const SizedBox(height: spacing),
            ],
          ];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Szybkie statusy', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _blockedMessage == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: const ValueKey('blocked-message'),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _blockedMessage!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (isSingleColumn)
              Column(children: buildColumnSlice(0))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: buildColumnSlice(0))),
                  const SizedBox(width: spacing),
                  Expanded(child: Column(children: buildColumnSlice(1))),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildOption(_QuickStatusOption option) {
    if (!_isOptionVisible(option.type)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final isSelected = _selections.containsKey(option.type);
    final controller = _controllers[option.type];
    final isInteractionBlocked = _isInteractionBlocked(option.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : isInteractionBlocked
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : isInteractionBlocked
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: isSelected,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => _handleOptionPressed(option.type),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleOptionPressed(option.type),
                  behavior: HitTestBehavior.translucent,
                  child: Text(
                    option.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isInteractionBlocked && !isSelected
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (isSelected && option.isFixedHours) ...[
            const SizedBox(height: 4),
            Text(
              'Godziny: ${_formatHours(_selections[option.type])} h',
              style: theme.textTheme.bodySmall,
            ),
          ] else if (isSelected && controller != null) ...[
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                labelText: 'Godziny',
                suffixText: 'h',
              ),
              onChanged: (value) => _updateHours(option.type, value),
            ),
          ],
        ],
      ),
    );
  }

  void _toggle(EventType type) {
    setState(() {
      if (!_isOptionVisible(type)) {
        return;
      }
      final isSickLeave = _isSickLeave(type);
      if (_selections.containsKey(type)) {
        _selections.remove(type);
        final controller = _controllers[type];
        if (controller != null) {
          controller.text = '';
        }
      } else {
        if (isSickLeave) {
          _clearSelections();
        }
        final defaultHours = _defaultHours(type);
        _selections[type] = defaultHours;
        final controller = _controllers[type];
        if (controller != null) {
          controller
            ..text = _formatHours(defaultHours)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
        }
      }
      _enforceScheduleConstraints();
      _notifyParent();
    });
  }

  void _updateHours(EventType type, String rawValue) {
    if (!_controllers.containsKey(type)) {
      return;
    }
    if (_shouldBlockSelection(type)) {
      _showSelectionBlockedMessage(type);
      final controller = _controllers[type];
      if (controller != null) {
        controller.text = _formatHours(_selections[type]);
      }
      return;
    }
    final parsed = _parseHours(rawValue);
    if (parsed == null) {
      return;
    }
    setState(() {
      var normalized = parsed;
      if (type == EventType.overtimeTimeOff) {
        final schedule = _normalizedSchedule();
        if (schedule > 0) {
          normalized = math.min(parsed, schedule);
        }
      }
      _selections[type] = normalized;
      _enforceScheduleConstraints();
      _notifyParent();
    });
  }

  void _notifyParent() {
    widget.onChanged(Map<EventType, double>.unmodifiable(_selections));
  }

  double _defaultHours(EventType type) {
    if (type == EventType.delegation) {
      return 8;
    }
    const base = 24.0;
    if (type == EventType.overtimeTimeOff) {
      final schedule = _normalizedSchedule();
      if (schedule > 0) {
        return math.min(base, schedule);
      }
    }
    return base;
  }

  String _formatHours(double? value) {
    if (value == null) {
      return '';
    }
    final hasDecimal = (value % 1) != 0;
    return hasDecimal ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
  }

  double? _parseHours(String input) {
    final sanitized = input.replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  bool _enforceScheduleConstraints({bool notifyParent = false}) {
    final schedule = _normalizedSchedule();
    final hasSchedule = schedule > 0;
    var changed = false;

    if (hasSchedule) {
      if (_selections.remove(EventType.overtimeWorked) != null) {
        _controllers[EventType.overtimeWorked]?.text = '';
        changed = true;
      }
      final currentTimeOff = _selections[EventType.overtimeTimeOff];
      if (currentTimeOff != null) {
        final clamped = math.min(currentTimeOff, schedule);
        if (clamped != currentTimeOff) {
          _selections[EventType.overtimeTimeOff] = clamped;
          _controllers[EventType.overtimeTimeOff]?.text = _formatHours(clamped);
          changed = true;
        }
      }
    } else {
      if (_selections.remove(EventType.overtimeTimeOff) != null) {
        _controllers[EventType.overtimeTimeOff]?.text = '';
        changed = true;
      }
    }

    if (_enforceSickExclusivity()) {
      changed = true;
    }

    if (changed && notifyParent) {
      _notifyParent();
    }
    return changed;
  }

  List<_QuickStatusOption> _visibleOptions() {
    return _options.where((option) => _isOptionVisible(option.type)).toList();
  }

  bool _isOptionVisible(EventType type) {
    final hasSchedule = _normalizedSchedule() > 0;
    if (type == EventType.overtimeWorked) {
      return !hasSchedule;
    }
    if (type == EventType.overtimeTimeOff) {
      return hasSchedule;
    }
    return true;
  }

  double _normalizedSchedule() {
    final schedule = widget.scheduledHours ?? 0;
    if (schedule.isNaN || schedule.isInfinite) {
      return 0;
    }
    return schedule.clamp(0, 48);
  }

  void _handleOptionPressed(EventType type) {
    if (_shouldBlockSelection(type)) {
      _showSelectionBlockedMessage(type);
      return;
    }
    _toggle(type);
  }

  bool _shouldBlockSelection(EventType type) {
    final activeSick = _activeSickLeaveType();
    if (activeSick == null) {
      return false;
    }
    final isSickLeave = _isSickLeave(type);
    final isSelected = _selections.containsKey(type);
    if (!isSickLeave && isSelected) {
      return false;
    }
    if (isSickLeave) {
      return !isSelected;
    }
    return true;
  }

  bool _isInteractionBlocked(EventType type) {
    final activeSick = _activeSickLeaveType();
    if (activeSick == null) {
      return false;
    }
    if (!_isSickLeave(type) && _selections.containsKey(type)) {
      return false;
    }
    if (_isSickLeave(type)) {
      return type != activeSick;
    }
    return true;
  }

  EventType? _activeSickLeaveType() {
    for (final type in _selections.keys) {
      if (_isSickLeave(type)) {
        return type;
      }
    }
    return null;
  }

  bool _isSickLeave(EventType type) {
    return type == EventType.sickLeave80 || type == EventType.sickLeave100;
  }

  void _clearSelections({EventType? except}) {
    final typesToRemove = _selections.keys
        .where((type) => except == null || type != except)
        .toList(growable: false);
    for (final type in typesToRemove) {
      _selections.remove(type);
      final controller = _controllers[type];
      if (controller != null) {
        controller.text = '';
      }
    }
  }

  bool _enforceSickExclusivity() {
    EventType? preservedSick;
    for (final type in _selections.keys) {
      if (_isSickLeave(type)) {
        preservedSick ??= type;
      }
    }
    if (preservedSick == null) {
      return false;
    }
    final typesToRemove = _selections.keys
        .where((type) => type != preservedSick)
        .toList(growable: false);
    if (typesToRemove.isEmpty) {
      return false;
    }
    for (final type in typesToRemove) {
      _selections.remove(type);
      final controller = _controllers[type];
      if (controller != null) {
        controller.text = '';
      }
    }
    return true;
  }

  void _showSelectionBlockedMessage(EventType attemptedType) {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
    final isSickAttempt = _isSickLeave(attemptedType);
    final message = isSickAttempt
        ? 'Możesz aktywować tylko jedno zwolnienie lekarskie naraz. Odznacz bieżące, aby kontynuować.'
        : 'Aktywne zwolnienie lekarskie blokuje inne statusy. Odznacz je, aby kontynuować.';
    _messageTimer?.cancel();
    setState(() {
      _blockedMessage = message;
    });
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _blockedMessage = null;
      });
    });
  }
}

class _QuickStatusOption {
  const _QuickStatusOption({
    required this.type,
    required this.label,
    this.isFixedHours = false,
  });

  final EventType type;
  final String label;
  final bool isFixedHours;
}
