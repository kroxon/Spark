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

  static const List<_QuickStatusOption> _options = <_QuickStatusOption>[
    _QuickStatusOption(type: EventType.delegation, label: 'Delegacja'),
    _QuickStatusOption(type: EventType.bloodDonation, label: 'Krwiodawstwo'),
    _QuickStatusOption(
      type: EventType.vacationStandard,
      label: 'Urlop wypoczynkowy',
    ),
    _QuickStatusOption(
      type: EventType.vacationAdditional,
      label: 'Urlop dodatkowy',
    ),
    _QuickStatusOption(
      type: EventType.sickLeave80,
      label: 'Zwolnienie lekarskie 80%',
    ),
    _QuickStatusOption(
      type: EventType.sickLeave100,
      label: 'Zwolnienie lekarskie 100%',
    ),
    _QuickStatusOption(
      type: EventType.custom,
      label: 'Nieobecność niestandardowa',
    ),
    _QuickStatusOption(
      type: EventType.overtimeOffDay,
      label: 'Odbiór nadgodzin',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selections = Map<EventType, double>.from(widget.selections);
    _controllers = <EventType, TextEditingController>{
      for (final option in _options)
        option.type: TextEditingController(
          text: _formatHours(_selections[option.type]),
        ),
    };
  }

  @override
  void didUpdateWidget(DayQuickStatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(widget.selections, oldWidget.selections)) {
      _selections = Map<EventType, double>.from(widget.selections);
      for (final option in _options) {
        _controllers[option.type]!.text = _formatHours(
          _selections[option.type],
        );
      }
    }
    if (widget.scheduledHours != oldWidget.scheduledHours &&
        widget.scheduledHours != null) {
      final oldDefault = oldWidget.scheduledHours;
      final newDefault = widget.scheduledHours!;
      var updated = false;
      for (final entry in _selections.entries.toList()) {
        final current = entry.value;
        if (oldDefault != null && (current - oldDefault).abs() < 0.01) {
          _selections[entry.key] = newDefault;
          _controllers[entry.key]!.text = _formatHours(newDefault);
          updated = true;
        }
      }
      if (updated) {
        _notifyParent();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final isSingleColumn = constraints.maxWidth < 280;
        final columnsCount = isSingleColumn ? 1 : 2;
        final sliceSize = (_options.length / columnsCount).ceil();

        List<Widget> buildColumnSlice(int columnIndex) {
          final start = columnIndex * sliceSize;
          final end = math.min(start + sliceSize, _options.length);
          if (start >= end) {
            return const [];
          }
          final slice = _options.sublist(start, end);
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
    final theme = Theme.of(context);
    final isSelected = _selections.containsKey(option.type);
    final controller = _controllers[option.type]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
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
                onChanged: (_) => _toggle(option.type),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggle(option.type),
                  behavior: HitTestBehavior.translucent,
                  child: Text(
                    option.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Godziny',
                  suffixText: 'h',
                ),
                onChanged: (value) => _updateHours(option.type, value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggle(EventType type) {
    setState(() {
      if (_selections.containsKey(type)) {
        _selections.remove(type);
        _controllers[type]!.text = '';
      } else {
        final defaultHours = _defaultHours(type);
        _selections[type] = defaultHours;
        final controller = _controllers[type]!;
        controller
          ..text = _formatHours(defaultHours)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
      }
      _notifyParent();
    });
  }

  void _updateHours(EventType type, String rawValue) {
    final parsed = _parseHours(rawValue);
    if (parsed == null) {
      return;
    }
    setState(() {
      _selections[type] = parsed;
      _notifyParent();
    });
  }

  void _notifyParent() {
    widget.onChanged(Map<EventType, double>.unmodifiable(_selections));
  }

  double _defaultHours(EventType type) {
    if (widget.scheduledHours != null && widget.scheduledHours! > 0) {
      return widget.scheduledHours!;
    }
    if (type == EventType.overtimeOffDay) {
      return 4;
    }
    return 8;
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
}

class _QuickStatusOption {
  const _QuickStatusOption({required this.type, required this.label});

  final EventType type;
  final String label;
}
