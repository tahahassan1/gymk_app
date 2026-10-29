import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_geometry.dart';
import '../../business_logic/cubit/mutation_feedback_cubit.dart';
import '../../business_logic/cubit/mutation_feedback_state.dart';
import 'mutation_details_dialog.dart';

class SessionMutationBanner extends StatelessWidget {
  const SessionMutationBanner({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MutationFeedbackCubit, MutationFeedbackState>(
    builder: (context, state) {
      if (state.pending.isEmpty &&
          state.rejected.isEmpty &&
          state.failure == null) {
        return const SizedBox.shrink();
      }
      final rejected = state.rejected.isNotEmpty || state.failure != null;
      return Material(
        color: AppColors.surfaceMuted,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppGeometry.space16,
            end: AppGeometry.space8,
          ),
          child: Row(
            children: [
              Icon(
                rejected ? Icons.error_outline : Icons.cloud_upload_outlined,
                color: rejected ? AppColors.danger : AppColors.textSecondary,
              ),
              const SizedBox(width: AppGeometry.space8),
              Expanded(
                child: Text(
                  rejected
                      ? 'في تغييرات اترفضت وتحتاج مراجعة'
                      : 'تغييرات في انتظار التأكيد (${state.pending.length})',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'التفاصيل',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<MutationFeedbackCubit>(),
                    child: const MutationDetailsDialog(),
                  ),
                ),
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
        ),
      );
    },
  );
}
