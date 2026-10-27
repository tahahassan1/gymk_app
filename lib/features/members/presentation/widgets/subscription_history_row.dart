import 'package:flutter/material.dart';

import '../../../../core/ui/app_formatters.dart';
import '../../../subscriptions/data/models/subscription_record.dart';

class SubscriptionHistoryRow extends StatelessWidget {
  const SubscriptionHistoryRow({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });
  final SubscriptionRecord record;
  final VoidCallback? onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppFormatters.money(record.amount),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text('من ${AppFormatters.day(record.startDate)}'),
        Text('إلى ${AppFormatters.day(record.endDate)} (غير شامل)'),
        Text('التحصيل: ${AppFormatters.day(record.paidAt)}'),
        Wrap(
          spacing: 8,
          children: [
            TextButton(onPressed: onEdit, child: const Text('تعديل الاشتراك')),
            TextButton(onPressed: onDelete, child: const Text('حذف الاشتراك')),
          ],
        ),
      ],
    ),
  );
}
