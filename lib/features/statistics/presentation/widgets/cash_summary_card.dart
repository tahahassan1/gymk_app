import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_geometry.dart';
import '../../../../core/ui/app_formatters.dart';

class CashSummaryCard extends StatelessWidget {
  const CashSummaryCard({
    super.key,
    required this.title,
    required this.income,
    required this.complete,
    this.count,
    this.emphasized = false,
  });
  final String title;
  final BigInt income;
  final int? count;
  final bool complete, emphasized;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: emphasized ? AppColors.brandPrimary : AppColors.surface,
      border: Border.all(
        color: emphasized ? AppColors.ink : AppColors.divider,
        width: emphasized ? 2 : 1,
      ),
      borderRadius: AppGeometry.radius,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          AppFormatters.totalMoney(income),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (count != null) Text('عدد السجلات: $count'),
        if (!complete) const Text('من البيانات المتاحة فقط'),
      ],
    ),
  );
}
