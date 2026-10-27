import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_date_field.dart';
import '../../../../core/ui/app_form_host.dart';
import '../../../../core/ui/app_formatters.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/submission_feedback.dart';
import '../../business_logic/cubit/subscription_form_cubit.dart';
import '../../business_logic/cubit/subscription_form_state.dart';
import '../../business_logic/policies/subscription_policy.dart';
import '../../data/models/subscription_record.dart';
import '../../../members/data/models/member.dart';

class SubscriptionForm extends StatefulWidget {
  const SubscriptionForm({super.key, required this.member});
  final Member member;
  static Future<void> show(
    BuildContext context,
    GymRepository repository,
    SubscriptionPolicy policy,
    Member member, {
    SubscriptionRecord? record,
  }) => AppFormHost.show<void>(
    context,
    title: record == null ? 'جدّد الاشتراك' : 'تعديل الاشتراك',
    builder: (_) => BlocProvider(
      create: (_) => SubscriptionFormCubit(
        repository: repository,
        policy: policy,
        memberId: member.id,
        original: record,
      ),
      child: SubscriptionForm(member: member),
    ),
  );
  @override
  State<SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<SubscriptionForm> {
  late final TextEditingController _amount;
  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: context.read<SubscriptionFormCubit>().state.amount,
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<SubscriptionFormCubit, SubscriptionFormState>(
    listenWhen: (a, b) => !a.submission.applied && b.submission.applied,
    listener: (context, _) => Navigator.of(context).pop(),
    builder: (context, state) {
      final cubit = context.read<SubscriptionFormCubit>();
      final preview = state.preview;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.member.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'المبلغ بالجنيه',
            controller: _amount,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            onChanged: cubit.amountChanged,
          ),
          const SizedBox(height: 16),
          AppDateField(
            label: 'بداية الاشتراك',
            value: preview.period.start,
            lastDate: cubit.policy.clock.today(),
            onChanged: state.submission.busy ? null : cubit.startChanged,
          ),
          if (cubit.original == null)
            TextButton(
              onPressed: state.submission.busy ? null : cubit.automaticStart,
              child: const Text('استخدم البداية التلقائية'),
            ),
          Text('نهاية الشهر: ${AppFormatters.day(preview.period.end)}'),
          if (preview.currentExpiry case final expiry?)
            Text('الانتهاء الحالي: ${AppFormatters.day(expiry)}'),
          if (preview.resultingCurrentExpiry case final expiry?)
            Text('الانتهاء بعد الحفظ: ${AppFormatters.day(expiry)}'),
          const SizedBox(height: 8),
          const Text('شهر تقويمي واحد. تاريخ التحصيل هو يوم تسجيل الدفع.'),
          if (!(cubit.repository.currentSubscriptions?.isComplete ?? false))
            const Text('التغطية محسوبة من السجل المتاح وقد تكون غير كاملة.'),
          if (state.stale)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'التغطية أو اليوم اتغيروا. راجع التواريخ الجديدة واضغط حفظ للتأكيد.',
              ),
            ),
          SubmissionFeedback(state: state.submission),
          const SizedBox(height: 16),
          AppButton(
            label: state.stale ? 'تأكيد وحفظ' : 'حفظ الاشتراك',
            busy: state.submission.busy,
            onPressed: cubit.submit,
          ),
        ],
      );
    },
  );
}
