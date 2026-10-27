import 'package:flutter/material.dart';

import '../time/date_only.dart';
import 'app_formatters.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.lastDate,
    required this.onChanged,
  });
  final String label;
  final DateOnly value;
  final DateOnly lastDate;
  final ValueChanged<DateOnly>? onChanged;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onChanged == null
        ? null
        : () async {
            final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
            final selected = DateTime(value.year, value.month, value.day);
            final date = await showDatePicker(
              context: context,
              initialDate: selected.isAfter(last) ? last : selected,
              firstDate: DateTime(1),
              lastDate: last,
            );
            if (date != null && context.mounted) {
              onChanged!(DateOnly.fromDateTime(date));
            }
          },
    icon: const Icon(Icons.calendar_month),
    label: Text('$label: ${AppFormatters.day(value)}'),
  );
}
