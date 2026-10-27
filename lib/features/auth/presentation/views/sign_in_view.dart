import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/adaptive/app_adaptive_layout.dart';
import '../../business_logic/cubit/auth_cubit.dart';
import '../../business_logic/cubit/auth_state.dart';
import '../layouts/sign_in_mobile_layout.dart';
import '../layouts/sign_in_tablet_layout.dart';
import '../widgets/sign_in_form.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final form = SignInForm(
            busy: state.signingIn,
            failure: state.failure,
            onSignIn: context.read<AuthCubit>().signIn,
          );
          return AppAdaptiveLayout(
            mobileBuilder: (_) => SignInMobileLayout(form: form),
            tabletBuilder: (_) => SignInTabletLayout(form: form),
          );
        },
      ),
    ),
  );
}
