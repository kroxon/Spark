import 'package:flutter/material.dart';

class DayNoteSection extends StatelessWidget {
  const DayNoteSection({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notatka służbowa',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Zapisz decyzje dowódcy, przekazania służby lub inne ustalenia.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
