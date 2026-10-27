import 'package:flutter/material.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_geometry.dart';
import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/failure_copy.dart';

class SignInForm extends StatelessWidget {
  const SignInForm({
    super.key,
    required this.busy,
    required this.onSignIn,
    this.failure,
  });
  final bool busy;
  final VoidCallback onSignIn;
  final AppFailure? failure;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'اشتراكات الجيم وحساباته في مكان واحد',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppGeometry.space16),
      const Text(
        'أول تسجيل دخول محتاج إنترنت. بعد تحميل بياناتك تقدر تشتغل من غير اتصال.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppGeometry.space24),
      AppButton(
        label: 'تسجيل الدخول بحساب Google',
        busy: busy,
        onPressed: busy ? null : onSignIn,
      ),
      if (failure case final error?) ...[
        const SizedBox(height: AppGeometry.space16),
        Semantics(
          liveRegion: true,
          child: Text(
            FailureCopy.message(error),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ],
  );
}
