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
          type == EventType.custom &&
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
  });

  final List<EditableDayEvent> events;
  final ValueChanged<List<EditableDayEvent>> onChanged;

  @override
  State<DayEventEditor> createState() => _DayEventEditorState();
}

class _DayEventEditorState extends State<DayEventEditor> {
  late final List<EditableDayEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = widget.events
        .map(
          (event) => EditableDayEvent(
            type: event.type,
            hours: event.hours,
            note: event.note,
            customName: event.customName,
            customPayout: event.customPayout,
          ),
        )
        .toList();
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
            Text('Zdarzenia', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Dodaj zdarzenie'),
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
              'Brak zdarzeń. Dodaj służbę, urlop lub inne zdarzenie aby wypełnić raport.',
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
      _events.add(EditableDayEvent(type: EventType.worked, hours: 24));
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
}

class _EventCard extends StatefulWidget {
  const _EventCard({
    required this.event,
    required this.onChanged,
    required this.onRemove,
  });

  final EditableDayEvent event;
  final ValueChanged<EditableDayEvent> onChanged;
  final VoidCallback onRemove;

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
    _hoursController = TextEditingController(
      text: _event.hours.toStringAsFixed(
        _event.hours.truncateToDouble() == _event.hours ? 0 : 1,
      ),
    );
    _noteController = TextEditingController(text: _event.note ?? '');
    _customNameController = TextEditingController(
      text: _event.customName ?? '',
    );
    _customPayoutController = TextEditingController(
      text: _event.customPayout?.toString() ?? '',
    );
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
                    labelText: 'Rodzaj zdarzenia',
                  ),
                  items: EventType.values
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
                      if (value != EventType.custom) {
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
                tooltip: 'Usuń zdarzenie',
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
                      _event.hours = parsed.clamp(0, 48).toDouble();
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
          if (_event.type == EventType.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa zdarzenia',
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

  String _eventTypeLabel(EventType type) {
    switch (type) {
      case EventType.worked:
        return 'Przepracowana służba';
      case EventType.delegation:
        return 'Delegacja';
      case EventType.bloodDonation:
        return 'Oddanie krwi';
      case EventType.vacationStandard:
        return 'Urlop wypoczynkowy';
      case EventType.vacationAdditional:
        return 'Urlop dodatkowy';
      case EventType.sickLeave80:
        return 'Zwolnienie lekarskie 80%';
      case EventType.sickLeave100:
        return 'Zwolnienie lekarskie 100%';
      case EventType.dayOff:
        return 'Dzień wolny za służbę';
      case EventType.custom:
        return 'Zdarzenie niestandardowe';
      case EventType.overtimeOffDay:
        return 'Praca w dniu wolnym';
    }
  }
}
