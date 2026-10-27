import 'package:flutter/material.dart';

import '../../../../core/ui/app_formatters.dart';
import '../../data/models/dropin.dart';

class DropinRow extends StatelessWidget {
  const DropinRow({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });
  final Dropin record;
  final VoidCallback? onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          record.name ?? 'بدون اسم',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(AppFormatters.money(record.amount)),
        Wrap(
          spacing: 8,
          children: [
            TextButton(onPressed: onEdit, child: const Text('تعديل الحصة')),
            TextButton(onPressed: onDelete, child: const Text('حذف الحصة')),
          ],
        ),
      ],
    ),
  );
}
