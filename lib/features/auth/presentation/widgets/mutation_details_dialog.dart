import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/failure_copy.dart';
import '../../business_logic/cubit/mutation_feedback_cubit.dart';
import '../../business_logic/cubit/mutation_feedback_state.dart';
import 'mutation_copy.dart';

class MutationDetailsDialog extends StatelessWidget {
  const MutationDetailsDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('حالة التغييرات'),
    content: SizedBox(
      width: 440,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: BlocBuilder<MutationFeedbackCubit, MutationFeedbackState>(
          builder: (context, state) => ListView(
            shrinkWrap: true,
            children: [
              const Text('دي حالة التغييرات اللي التطبيق متابعها دلوقتي.'),
              for (final notice in state.rejected)
                ListTile(
                  title: Text(MutationCopy.action(notice)),
                  subtitle: Text(
                    notice.failure == null
                        ? MutationCopy.status(notice)
                        : FailureCopy.message(notice.failure!),
                  ),
                  trailing: IconButton(
                    tooltip: 'إخفاء الرسالة',
                    onPressed: () => context
                        .read<MutationFeedbackCubit>()
                        .dismiss(notice.id),
                    icon: const Icon(Icons.close),
                  ),
                ),
              for (final notice in state.pending)
                ListTile(
                  title: Text(MutationCopy.action(notice)),
                  subtitle: Text(MutationCopy.status(notice)),
                ),
              if (state.failure case final failure?)
                Text(FailureCopy.message(failure)),
              if (state.pending.isEmpty &&
                  state.rejected.isEmpty &&
                  state.failure == null)
                const Text('مفيش تغييرات معلقة متابَعة دلوقتي.'),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('إغلاق'),
      ),
    ],
  );
}
