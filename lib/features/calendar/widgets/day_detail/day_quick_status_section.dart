import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/quick_status_validator.dart';

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
      icon: Icons.business_center,
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.bloodDonation,
      label: 'Krwiodawstwo',
      icon: Icons.bloodtype,
      isFixedHours: true,
    ),
    _QuickStatusOption(
      type: EventType.vacationRegular,
      label: 'Urlop wypoczynkowy',
      icon: Icons.beach_access,
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.vacationAdditional,
      label: 'Urlop dodatkowy',
      icon: Icons.wb_sunny,
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.sickLeave80,
      label: 'Zwolnienie lekarskie 80%',
      icon: Icons.local_hospital,
      isFixedHours: true,
    ),
    _QuickStatusOption(
      type: EventType.sickLeave100,
      label: 'Zwolnienie lekarskie 100%',
      icon: Icons.healing,
      isFixedHours: true,
    ),
    _QuickStatusOption(
      type: EventType.overtimeTimeOff,
      label: 'Odbiór nadgodzin',
      icon: Icons.access_time,
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.paidAbsence,
      label: 'Inna płatna nieobecność',
      icon: Icons.event_busy,
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.overtimeWorked,
      label: 'Nadgodziny',
      icon: Icons.work,
      isFixedHours: false,
    ),
    _QuickStatusOption(
      type: EventType.homeDuty,
      label: 'Dyżur domowy',
      icon: Icons.home,
      isFixedHours: true,
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
    _enforceScheduleConstraints(notifyParent: false);
    // Delay validation to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _validateAndShowConflicts();
      }
    });
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
        const spacing = 4.0;
        final columnsCount = 2;
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
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _blockedMessage == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: const ValueKey('blocked-message'),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
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
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
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
    final hasConflict = _hasConflict(option.type);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [theme.colorScheme.primary.withValues(alpha: 0.1), theme.colorScheme.primary.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isInteractionBlocked
                      ? [theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), theme.colorScheme.surface]
                      : [theme.colorScheme.surface, theme.colorScheme.surfaceContainerLowest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isInteractionBlocked
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isInteractionBlocked ? null : () => _handleOptionPressed(option.type),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: isInteractionBlocked ? null : () => _handleOptionPressed(option.type),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isInteractionBlocked ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            option.icon,
                            size: 16,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : (isInteractionBlocked ? theme.colorScheme.onSurface.withValues(alpha: 0.3) : theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: isInteractionBlocked ? null : () => _handleOptionPressed(option.type),
                          behavior: HitTestBehavior.translucent,
                          child: Text(
                            option.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isInteractionBlocked && !isSelected
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
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
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Godziny: ${_formatHours(_selections[option.type])} h',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ] else if (isSelected && controller != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120, // Wider input field to prevent text overflow
                          child: SizedBox(
                            height: 52, // Increased TextField height for better text accommodation
                            child: TextField(
                              controller: controller,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4, // Reduced vertical padding
                                ),
                                hintText: '0',
                                suffixText: 'h',
                                errorText: hasConflict ? ' ' : null, // Reserve space for error
                              ),
                              onChanged: (value) => _updateHours(option.type, value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(EventType type) {
    setState(() {
      if (!_isOptionVisible(type)) {
        return;
      }
      if (_selections.containsKey(type)) {
        _selections.remove(type);
        final controller = _controllers[type];
        if (controller != null) {
          controller.text = '';
        }
      } else {
        if (_isExclusiveStatus(type)) {
          _clearSelections(except: type);
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
    final parsed = _parseHours(rawValue);
    if (parsed == null) {
      return;
    }
    setState(() {
      var normalized = parsed;
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
    if (type == EventType.homeDuty) {
      return 24;
    }

    // For deducting types (vacations, overtime time-off, paid absence),
    // default hours should not exceed scheduled hours
    final deductingTypes = {
      EventType.vacationRegular,
      EventType.vacationAdditional,
      EventType.overtimeTimeOff,
      EventType.paidAbsence,
    };

    if (deductingTypes.contains(type) && widget.scheduledHours != null && widget.scheduledHours! > 0) {
      return math.min(widget.scheduledHours!, 24.0);
    }

    const base = 24.0;
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
    var changed = false;

    if (_enforceExclusiveStatusExclusivity()) {
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
    // Health statuses are always available
    final healthStatuses = {
      EventType.bloodDonation,
      EventType.sickLeave80,
      EventType.sickLeave100,
    };

    if (healthStatuses.contains(type)) {
      return true;
    }

    // For other statuses, availability depends on scheduled hours
    if (widget.scheduledHours == null || widget.scheduledHours == 0) {
      // No scheduled hours: all statuses except health and overtime time-off
      return type != EventType.overtimeTimeOff;
    } else if (widget.scheduledHours == 24) {
      // 24h scheduled: all statuses except health and overtime worked
      return type != EventType.overtimeWorked;
    } else {
      // 8h or 16h scheduled: all statuses except health
      return true;
    }
  }

  void _handleOptionPressed(EventType type) {
    if (_shouldBlockSelection(type)) {
      _showSelectionBlockedMessage(type);
      return;
    }

    // Allow toggling all available statuses - validation happens only on save
    _toggle(type);
  }

  bool _shouldBlockSelection(EventType type) {
    final activeExclusive = _activeExclusiveStatusType();
    if (activeExclusive == null) {
      return false;
    }
    final isExclusive = _isExclusiveStatus(type);
    final isSelected = _selections.containsKey(type);
    if (!isExclusive && isSelected) {
      return false;
    }
    if (isExclusive) {
      return !isSelected;
    }
    return true;
  }

  bool _isInteractionBlocked(EventType type) {
    // First check existing exclusive status logic
    final activeExclusive = _activeExclusiveStatusType();
    if (activeExclusive == null) {
      // For exclusive types, maintain exclusivity logic
      if (_isExclusiveStatus(type)) {
        return false; // Allow interaction with exclusive types
      }
      // For all other types, allow interaction - validation happens only on save
      return false;
    }
    if (!_isExclusiveStatus(type) && _selections.containsKey(type)) {
      return false;
    }
    if (_isExclusiveStatus(type)) {
      return type != activeExclusive;
    }
    return true;
  }

  bool _hasConflict(EventType type) {
    // Check if currently selected type causes conflicts
    if (!_selections.containsKey(type)) {
      return false;
    }

    final validator = QuickStatusValidator();
    final conflicts = validator.validateSelections(
      selections: _selections,
      scheduledHours: widget.scheduledHours,
    );

    // Check if this type is mentioned in any error conflicts
    return conflicts
        .where((c) => c.severity == ValidationSeverity.error)
        .any((c) => c.conflictingTypes.contains(type));
  }

  EventType? _activeExclusiveStatusType() {
    for (final type in _selections.keys) {
      if (_isExclusiveStatus(type)) {
        return type;
      }
    }
    return null;
  }

  bool _isSickLeave(EventType type) {
    return type == EventType.sickLeave80 || type == EventType.sickLeave100;
  }

  bool _isExclusiveStatus(EventType type) {
    return _isSickLeave(type) || type == EventType.bloodDonation;
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

  bool _enforceExclusiveStatusExclusivity() {
    EventType? preservedExclusive;
    for (final type in _selections.keys) {
      if (_isExclusiveStatus(type)) {
        preservedExclusive ??= type;
      }
    }
    if (preservedExclusive == null) {
      return false;
    }
    final typesToRemove = _selections.keys
        .where((type) => type != preservedExclusive)
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
    final isExclusiveAttempt = _isExclusiveStatus(attemptedType);
    final message = isExclusiveAttempt
        ? 'Możesz aktywować tylko jeden status zdrowotny naraz. Odznacz bieżący, aby kontynuować.'
        : 'Aktywny status zdrowotny blokuje inne statusy. Odznacz go, aby kontynuować.';
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

  void _validateAndShowConflicts() {
    final validator = QuickStatusValidator();
    final conflicts = validator.validateSelections(
      selections: _selections,
      scheduledHours: widget.scheduledHours,
    );

    if (conflicts.isEmpty) {
      _clearValidationMessage();
      return;
    }

    // Show the first error conflict as a message
    final errorConflict = conflicts.where((c) => c.severity == ValidationSeverity.error).firstOrNull;
    if (errorConflict != null) {
      _showValidationMessage(errorConflict.message);
    } else {
      // Show first warning if no errors
      final warningConflict = conflicts.first;
      _showValidationMessage(warningConflict.message);
    }
  }

  void _showValidationMessage(String message) {
    if (!mounted) return;

    _messageTimer?.cancel();
    setState(() {
      _blockedMessage = message;
    });
    _messageTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _blockedMessage = null;
      });
    });
  }

  void _clearValidationMessage() {
    if (!mounted) return;

    _messageTimer?.cancel();
    setState(() {
      _blockedMessage = null;
    });
  }
}

class _QuickStatusOption {
  const _QuickStatusOption({
    required this.type,
    required this.label,
    required this.icon,
    this.isFixedHours = false,
  });

  final EventType type;
  final String label;
  final IconData icon;
  final bool isFixedHours;
}
