import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

class EditableDayEvent {
  EditableDayEvent({
    required this.type,
    required this.hours,
    this.note,
    this.customName,
    this.customPayout,
  });

  factory EditableDayEvent.fromDomain(DayEvent event) {
    return EditableDayEvent(
      type: event.type,
      hours: event.hours,
      note: event.note,
      customName: event.customDetails?.name,
      customPayout: event.customDetails?.payoutPercentage,
    );
  }

  DayEvent toDomain() {
    return DayEvent(
      type: type,
      hours: hours,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      customDetails:
          type == EventType.customAbsence &&
              customName != null &&
              customName!.trim().isNotEmpty &&
              customPayout != null
          ? CustomAbsenceDetails(
              name: customName!.trim(),
              payoutPercentage: customPayout!.clamp(0, 200),
            )
          : null,
    );
  }

  EventType type;
  double hours;
  String? note;
  String? customName;
  int? customPayout;
}

class DayEventEditor extends StatefulWidget {
  const DayEventEditor({
    super.key,
    required this.events,
    required this.onChanged,
    this.scheduledHours,
  });

  final List<EditableDayEvent> events;
  final ValueChanged<List<EditableDayEvent>> onChanged;
  final double? scheduledHours;

  @override
  State<DayEventEditor> createState() => _DayEventEditorState();
}

class _DayEventEditorState extends State<DayEventEditor> {
  late List<EditableDayEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = widget.events.map(_cloneEvent).toList();
  }

  @override
  void didUpdateWidget(DayEventEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.events, oldWidget.events)) {
      _events = widget.events.map(_cloneEvent).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Aktywności', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Dodaj aktywność'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Brak aktywności. Dodaj służbę, urlop lub inną zmianę aby wypełnić raport.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Column(
            children: [
              for (var index = 0; index < _events.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _events.length - 1 ? 0 : 16,
                  ),
                  child: _EventCard(
                    event: _events[index],
                    scheduledHours: widget.scheduledHours,
                    onChanged: (updated) => _updateEvent(index, updated),
                    onRemove: () => _removeEvent(index),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _addEvent() {
    setState(() {
      final type = _defaultEventType();
      final hours = _defaultHours(type);
      _events.add(EditableDayEvent(type: type, hours: hours));
    });
    widget.onChanged(List<EditableDayEvent>.from(_events));
  }

  void _removeEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
    widget.onChanged(List<EditableDayEvent>.from(_events));
  }

  void _updateEvent(int index, EditableDayEvent updated) {
    setState(() {
      _events[index] = updated;
    });
    widget.onChanged(List<EditableDayEvent>.from(_events));
  }

  EditableDayEvent _cloneEvent(EditableDayEvent event) {
    return EditableDayEvent(
      type: event.type,
      hours: event.hours,
      note: event.note,
      customName: event.customName,
      customPayout: event.customPayout,
    );
  }

  EventType _defaultEventType() {
    return _hasSchedule ? EventType.overtimeTimeOff : EventType.overtimeWorked;
  }

  double _defaultHours(EventType type) {
    if (type == EventType.delegation) {
      return 8;
    }
    if (type == EventType.overtimeTimeOff && _hasSchedule) {
      return math.min(24, _normalizedSchedule());
    }
    return 24;
  }

  bool get _hasSchedule => _normalizedSchedule() > 0;

  double _normalizedSchedule() {
    final raw = widget.scheduledHours ?? 0;
    if (raw.isNaN || raw.isInfinite) {
      return 0;
    }
    return raw.clamp(0, 48);
  }
}

class _EventCard extends StatefulWidget {
  const _EventCard({
    required this.event,
    required this.onChanged,
    required this.onRemove,
    required this.scheduledHours,
  });

  final EditableDayEvent event;
  final ValueChanged<EditableDayEvent> onChanged;
  final VoidCallback onRemove;
  final double? scheduledHours;

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  late EditableDayEvent _event;
  late final TextEditingController _hoursController;
  late final TextEditingController _noteController;
  late final TextEditingController _customNameController;
  late final TextEditingController _customPayoutController;

  @override
  void initState() {
    super.initState();
    _event = EditableDayEvent(
      type: widget.event.type,
      hours: widget.event.hours,
      note: widget.event.note,
      customName: widget.event.customName,
      customPayout: widget.event.customPayout,
    );
    _hoursController = TextEditingController(text: _formatHours(_event.hours));
    _noteController = TextEditingController(text: _event.note ?? '');
    _customNameController = TextEditingController(
      text: _event.customName ?? '',
    );
    _customPayoutController = TextEditingController(
      text: _event.customPayout?.toString() ?? '',
    );
    _applyScheduleConstraints(updateHoursController: true);
  }

  @override
  void didUpdateWidget(_EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.event, oldWidget.event)) {
      _event = EditableDayEvent(
        type: widget.event.type,
        hours: widget.event.hours,
        note: widget.event.note,
        customName: widget.event.customName,
        customPayout: widget.event.customPayout,
      );
      _hoursController.text = _formatHours(_event.hours);
      _noteController.text = widget.event.note ?? '';
      _customNameController.text = widget.event.customName ?? '';
      _customPayoutController.text =
          widget.event.customPayout?.toString() ?? '';
    }
    if ((widget.scheduledHours ?? 0) != (oldWidget.scheduledHours ?? 0) ||
        !identical(widget.event, oldWidget.event)) {
      _applyScheduleConstraints(updateHoursController: true);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    _customNameController.dispose();
    _customPayoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allowedTypes = _allowedEventTypes();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<EventType>(
                  initialValue: _event.type,
                  decoration: const InputDecoration(
                    labelText: 'Rodzaj aktywności',
                  ),
                  items: allowedTypes
                      .map(
                        (type) => DropdownMenuItem<EventType>(
                          value: type,
                          child: Text(_eventTypeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _event.type = value;
                      _applyScheduleConstraints(updateHoursController: true);
                      if (value != EventType.customAbsence) {
                        _event.customName = null;
                        _event.customPayout = null;
                        _customNameController.clear();
                        _customPayoutController.clear();
                      }
                    });
                    _emitChange();
                  },
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Usuń aktywność',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(labelText: 'Liczba godzin'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed != null) {
                      var normalized = parsed.clamp(0, 48).toDouble();
                      final schedule = _normalizedSchedule();
                      if (_event.type == EventType.overtimeTimeOff &&
                          schedule > 0) {
                        normalized = math.min(normalized, schedule);
                      }
                      _event.hours = normalized;
                      final formatted = _formatHours(normalized);
                      if (_hoursController.text != formatted) {
                        _hoursController
                          ..text = formatted
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: formatted.length),
                          );
                      }
                      _emitChange();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Notatka'),
                  onChanged: (value) {
                    _event.note = value.trim().isEmpty ? null : value;
                    _emitChange();
                  },
                ),
              ),
            ],
          ),
          if (_event.type == EventType.customAbsence) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa aktywności',
                    ),
                    onChanged: (value) {
                      _event.customName = value.trim().isEmpty ? null : value;
                      _emitChange();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _customPayoutController,
                    decoration: const InputDecoration(
                      labelText: 'Płatność (%)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        _event.customPayout = parsed.clamp(0, 300);
                        _emitChange();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _emitChange() {
    widget.onChanged(
      EditableDayEvent(
        type: _event.type,
        hours: _event.hours,
        note: _event.note,
        customName: _event.customName,
        customPayout: _event.customPayout,
      ),
    );
  }

  List<EventType> _allowedEventTypes() {
    final schedule = _normalizedSchedule();
    final hasSchedule = schedule > 0;
    return EventType.values.where((type) {
      if (type == EventType.overtimeWorked) {
        return !hasSchedule;
      }
      if (type == EventType.overtimeTimeOff) {
        return hasSchedule;
      }
      return true;
    }).toList();
  }

  void _applyScheduleConstraints({required bool updateHoursController}) {
    final allowedTypes = _allowedEventTypes();
    if (!allowedTypes.contains(_event.type)) {
      _event.type = allowedTypes.first;
      if (_event.type != EventType.customAbsence) {
        _event.customName = null;
        _event.customPayout = null;
        if (updateHoursController) {
          _customNameController.clear();
          _customPayoutController.clear();
        }
      }
    }

    final schedule = _normalizedSchedule();
    if (_event.type == EventType.overtimeTimeOff && schedule > 0) {
      final clamped = math.min(_event.hours, schedule);
      if (clamped != _event.hours) {
        _event.hours = clamped;
      }
    }

    if (updateHoursController) {
      final formatted = _formatHours(_event.hours);
      _hoursController
        ..text = formatted
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        );
    }
  }

  double _normalizedSchedule() {
    final raw = widget.scheduledHours ?? 0;
    if (raw.isNaN || raw.isInfinite) {
      return 0;
    }
    return raw.clamp(0, 48);
  }

  String _formatHours(double value) {
    final isInt = value.truncateToDouble() == value;
    return isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String _eventTypeLabel(EventType type) {
    switch (type) {
      case EventType.overtimeWorked:
        return 'Nadgodziny';
      case EventType.delegation:
        return 'Delegacja';
      case EventType.bloodDonation:
        return 'Krwiodawstwo';
      case EventType.vacationRegular:
        return 'Urlop wypoczynkowy';
      case EventType.vacationAdditional:
        return 'Urlop dodatkowy';
      case EventType.sickLeave80:
        return 'Zwolnienie lekarskie 80%';
      case EventType.sickLeave100:
        return 'Zwolnienie lekarskie 100%';
      case EventType.otherAbsence:
        return 'Inna nieobecność';
      case EventType.customAbsence:
        return 'Zdarzenie niestandardowe';
      case EventType.overtimeTimeOff:
        return 'Odbiór nadgodzin';
    }
  }
}
