import 'package:flutter/material.dart';

import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_date_field.dart';
import '../../../../core/ui/app_formatters.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/submission_feedback.dart';
import '../../../../core/ui/failure_copy.dart';
import '../../../../core/time/date_only.dart';
import '../../business_logic/cubit/dropin_form_state.dart';

class DropinFields extends StatelessWidget {
  const DropinFields({
    super.key,
    required this.state,
    required this.name,
    required this.amount,
    required this.onName,
    required this.onAmount,
    required this.onSave,
    this.onDate,
    this.readOnly = false,
  });
  final DropinFormState state;
  final TextEditingController name, amount;
  final ValueChanged<String> onName, onAmount;
  final ValueChanged<DateOnly>? onDate;
  final VoidCallback onSave;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        onDate == null
            ? 'حصة جديدة لليوم: ${AppFormatters.day(state.date)}'
            : 'تعديل الحصة',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (onDate == null)
        const Text('التسجيل الجديد دايمًا لليوم، حتى لو بتعرض حصص يوم سابق.'),
      const SizedBox(height: 16),
      AppTextField(
        label: 'الاسم (اختياري)',
        controller: name,
        onChanged: onName,
        readOnly: readOnly,
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'المبلغ بالجنيه',
        controller: amount,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.number,
        onChanged: onAmount,
        readOnly: readOnly,
      ),
      if (onDate != null)
        AppDateField(
          label: 'يوم الحصة',
          value: state.date,
          lastDate: DateOnly(9999, 12, 31),
          onChanged: readOnly ? null : onDate,
        ),
      if (state.staleDate)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('اليوم اتغير. راجع تاريخ التسجيل واضغط حفظ للتأكيد.'),
        ),
      SubmissionFeedback(state: state.submission),
      if (state.defaultsFailure != null)
        Text(FailureCopy.message(state.defaultsFailure!)),
      const SizedBox(height: 16),
      AppButton(
        label: onDate == null ? 'سجّل حصة' : 'حفظ الحصة',
        busy: state.submission.busy,
        onPressed: onSave,
      ),
    ],
  );
}
