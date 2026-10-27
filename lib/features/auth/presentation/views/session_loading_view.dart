import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_geometry.dart';
import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/app_loading_state.dart';
import '../../../../core/ui/failure_copy.dart';
import '../../business_logic/cubit/auth_cubit.dart';
import '../../business_logic/cubit/auth_state.dart';

class SessionLoadingView extends StatelessWidget {
  const SessionLoadingView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final failure = state.failure;
          if (failure == null) return const AppLoadingState();
          return Column(
            children: [
              Expanded(
                child: AppFeedback(
                  title: 'مش قادرين نحمّل الحساب',
                  message: FailureCopy.message(failure),
                  actionLabel: 'حاول تاني',
                  onAction: context.read<AuthCubit>().retrySession,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppGeometry.space16),
                child: AppButton(
                  label: 'تسجيل الخروج',
                  busy: state.signingOut,
                  variant: AppButtonVariant.secondary,
                  onPressed: state.signingOut
                      ? null
                      : context.read<AuthCubit>().signOut,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
