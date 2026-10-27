import 'package:flutter/material.dart';

import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/read_notice.dart';
import '../../../../core/ui/submission_feedback.dart';
import '../../business_logic/cubit/settings_state.dart';

class SettingsFields extends StatelessWidget {
  const SettingsFields({
    super.key,
    required this.state,
    required this.name,
    required this.subscriptionPrice,
    required this.dropinPrice,
    required this.onName,
    required this.onSubscription,
    required this.onDropin,
    required this.onSave,
    required this.onReload,
    required this.onRetry,
  });
  final SettingsState state;
  final TextEditingController name, subscriptionPrice, dropinPrice;
  final ValueChanged<String> onName, onSubscription, onDropin;
  final VoidCallback onSave, onReload, onRetry;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppTextField(label: 'اسم الجيم', controller: name, onChanged: onName),
      const SizedBox(height: 16),
      AppTextField(
        label: 'سعر الاشتراك الافتراضي بالجنيه',
        controller: subscriptionPrice,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.number,
        onChanged: onSubscription,
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'سعر الحصة الافتراضي بالجنيه',
        controller: dropinPrice,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.number,
        onChanged: onDropin,
      ),
      const SizedBox(height: 12),
      const Text(
        'الأسعار دي للنماذج الجديدة. السجلات القديمة والمبالغ اللي عدلتها في مسودة مش هتتغير. الصفر مسموح كسعر افتراضي، لكن الدفع لازم يكون مبلغ موجب.',
      ),
      ReadNotice(
        complete: state.complete,
        failure: state.readFailure,
        onRetry: onRetry,
      ),
      SubmissionFeedback(state: state.submission),
      if (state.submission.applied)
        const Text('التغيير اتطبق على الجهاز. تابع تأكيده في شريط التغييرات.'),
      const SizedBox(height: 16),
      AppButton(
        label: 'حفظ الإعدادات',
        busy: state.submission.busy,
        onPressed: state.ready && state.dirty ? onSave : null,
      ),
      if (state.dirty)
        TextButton(
          onPressed: state.submission.busy ? null : onReload,
          child: const Text('إلغاء المسودة وتحميل آخر إعدادات'),
        ),
    ],
  );
}
