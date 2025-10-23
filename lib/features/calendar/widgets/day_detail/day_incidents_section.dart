import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iskra/features/calendar/models/incident_entry.dart';

class DayIncidentsSection extends StatefulWidget {
  const DayIncidentsSection({
    super.key,
    required this.day,
    required this.incidents,
    required this.onChanged,
  });

  final DateTime day;
  final List<IncidentEntry> incidents;
  final ValueChanged<List<IncidentEntry>> onChanged;

  @override
  State<DayIncidentsSection> createState() => _DayIncidentsSectionState();
}

class _DayIncidentsSectionState extends State<DayIncidentsSection> {
  late List<IncidentEntry> _sortedIncidents;
  final Set<String> _expandedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _sortedIncidents = _sorted(widget.incidents);
  }

  @override
  void didUpdateWidget(DayIncidentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sortedIncidents = _sorted(widget.incidents);
    _expandedIds.removeWhere(
      (id) => !_sortedIncidents.any((incident) => incident.id == id),
    );
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
              onPressed: _handleAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Dodaj zdarzenie'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_sortedIncidents.isEmpty)
          _buildEmptyState(theme)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sortedIncidents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final incident = _sortedIncidents[index];
              final isExpanded = _expandedIds.contains(incident.id);
              return IncidentListItem(
                incident: incident,
                isExpanded: isExpanded,
                onToggleExpanded: () => _toggleExpanded(incident.id),
                onEdit: () => _handleEdit(incident),
                onDelete: () => _handleDelete(incident),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 28,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text('Nie dodano żadnych zdarzeń dla tej służby.',
           style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  Future<void> _handleAdd() async {
    final result = await _showIncidentForm();
    if (result == null || !mounted) {
      return;
    }
    final incident = IncidentEntry(
      id: _generateIncidentId(),
      category: result.category,
      timestamp: result.timestamp,
      note: result.note,
    );
    final updated = List<IncidentEntry>.from(_sortedIncidents)..add(incident);
    _expandedIds.remove(incident.id);
    _updateIncidents(updated);
  }

  Future<void> _handleEdit(IncidentEntry incident) async {
    final result = await _showIncidentForm(initial: incident);
    if (result == null || !mounted) {
      return;
    }
    final updatedIncident = incident.copyWith(
      category: result.category,
      timestamp: result.timestamp,
      note: result.note,
    );
    final updated = _sortedIncidents
        .map((entry) => entry.id == incident.id ? updatedIncident : entry)
        .toList();
    _updateIncidents(updated);
  }

  Future<void> _handleDelete(IncidentEntry incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń zdarzenie'),
        content: const Text(
          'Na pewno chcesz usunąć to zdarzenie? Tej operacji nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final updated = List<IncidentEntry>.from(_sortedIncidents)
      ..removeWhere((entry) => entry.id == incident.id);
    _expandedIds.remove(incident.id);
    _updateIncidents(updated);
  }

  void _toggleExpanded(String incidentId) {
    setState(() {
      if (_expandedIds.contains(incidentId)) {
        _expandedIds.remove(incidentId);
      } else {
        _expandedIds.add(incidentId);
      }
    });
  }

  Future<_IncidentFormResult?> _showIncidentForm({IncidentEntry? initial}) {
    return showModalBottomSheet<_IncidentFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _IncidentFormSheet(serviceDay: widget.day, initialIncident: initial),
    );
  }

  void _updateIncidents(List<IncidentEntry> incidents) {
    final sorted = _sorted(incidents);
    setState(() {
      _sortedIncidents = sorted;
    });
    widget.onChanged(List<IncidentEntry>.from(sorted));
  }

  List<IncidentEntry> _sorted(List<IncidentEntry> incidents) {
    if (incidents.isEmpty) {
      return const <IncidentEntry>[];
    }
    final copy = List<IncidentEntry>.from(incidents)..sort(_compareIncidents);
    return copy;
  }

  String _generateIncidentId() {
    return 'incident_${DateTime.now().microsecondsSinceEpoch}';
  }

  int _compareIncidents(IncidentEntry a, IncidentEntry b) {
    final aTime = a.timestamp;
    final bTime = b.timestamp;
    if (aTime == null && bTime == null) {
      return 0;
    }
    if (aTime == null) {
      return 1;
    }
    if (bTime == null) {
      return -1;
    }
    return aTime.compareTo(bTime);
  }
}

class IncidentListItem extends StatelessWidget {
  const IncidentListItem({
    super.key,
    required this.incident,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.onDelete,
  });

  final IncidentEntry incident;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sanitizedNote = incident.note?.trim();
    final hasNote = sanitizedNote != null && sanitizedNote.isNotEmpty;
    final timeLabel = incident.timestamp != null
        ? DateFormat('HH:mm').format(incident.timestamp!)
        : null;
    final noteText = sanitizedNote ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(
              left: 12,
              right: 6,
              top: 4,
              bottom: 4,
            ),
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              _categoryIcon(incident.category),
              color: theme.colorScheme.primary,
            ),
            title: Text(
              _categoryLabel(incident.category),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: hasNote && !isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      noteText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timeLabel != null) ...[
                  Text(
                    timeLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                _CompactIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edytuj zdarzenie',
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                _CompactIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Usuń zdarzenie',
                  onPressed: onDelete,
                ),
              ],
            ),
            onTap: hasNote ? onToggleExpanded : null,
          ),
          if (hasNote)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(noteText, style: theme.textTheme.bodyMedium),
              ),
            ),
        ],
      ),
    );
  }

  IconData _categoryIcon(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.fire:
        return Icons.local_fire_department_rounded;
      case IncidentCategory.localHazard:
        return Icons.warning_amber_rounded;
      case IncidentCategory.falseAlarm:
        return Icons.notifications_off_rounded;
    }
  }

  String _categoryLabel(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.fire:
        return 'Pożar';
      case IncidentCategory.localHazard:
        return 'MZ';
      case IncidentCategory.falseAlarm:
        return 'AF';
    }
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _IncidentFormSheet extends StatefulWidget {
  const _IncidentFormSheet({required this.serviceDay, this.initialIncident});

  final DateTime serviceDay;
  final IncidentEntry? initialIncident;

  @override
  State<_IncidentFormSheet> createState() => _IncidentFormSheetState();
}

class _IncidentFormSheetState extends State<_IncidentFormSheet> {
  late IncidentCategory _category;
  TimeOfDay? _selectedTime;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final incident = widget.initialIncident;
    if (incident != null) {
      _category = incident.category;
      _selectedTime = incident.timestamp != null
          ? TimeOfDay.fromDateTime(incident.timestamp!)
          : null;
      _noteController = TextEditingController(text: incident.note ?? '');
    } else {
      _category = IncidentCategory.fire;
      _selectedTime = null;
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isEditing = widget.initialIncident != null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + viewInsets,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edytuj zdarzenie' : 'Dodaj zdarzenie',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CategoryChoiceChip(
                label: 'Pożar',
                icon: Icons.local_fire_department_rounded,
                selected: _category == IncidentCategory.fire,
                onTap: () => _selectCategory(IncidentCategory.fire),
              ),
              _CategoryChoiceChip(
                label: 'MZ',
                icon: Icons.warning_amber_rounded,
                selected: _category == IncidentCategory.localHazard,
                onTap: () => _selectCategory(IncidentCategory.localHazard),
              ),
              _CategoryChoiceChip(
                label: 'AF',
                icon: Icons.notifications_off_rounded,
                selected: _category == IncidentCategory.falseAlarm,
                onTap: () => _selectCategory(IncidentCategory.falseAlarm),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Godzina zdarzenia', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    _selectedTime == null
                        ? 'Dodaj godzinę'
                        : _formatTime(context, _selectedTime!),
                  ),
                ),
              ),
              if (_selectedTime != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Wyczyść godzinę',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _selectedTime = null;
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notatka (opcjonalnie)',
            ),
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 5,
            maxLength: 200,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Zapisz' : 'Dodaj'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final timestamp = _composeTimestamp();
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      _IncidentFormResult(
        category: _category,
        timestamp: timestamp,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  DateTime? _composeTimestamp() {
    final serviceDay = DateUtils.dateOnly(widget.serviceDay);
    if (_selectedTime == null) {
      return null;
    }
    return DateTime(
      serviceDay.year,
      serviceDay.month,
      serviceDay.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: true);
  }

  void _selectCategory(IncidentCategory category) {
    setState(() {
      _category = category;
    });
  }
}

class _IncidentFormResult {
  const _IncidentFormResult({
    required this.category,
    required this.timestamp,
    this.note,
  });

  final IncidentCategory category;
  final DateTime? timestamp;
  final String? note;
}

class _CategoryChoiceChip extends StatelessWidget {
  const _CategoryChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
