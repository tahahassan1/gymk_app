import 'package:flutter/material.dart';

import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/failure_copy.dart';
import '../../../../core/errors/app_failure.dart';

class SignOutSection extends StatelessWidget {
  const SignOutSection({
    super.key,
    required this.busy,
    required this.onSignOut,
    this.failure,
  });
  final bool busy;
  final VoidCallback? onSignOut;
  final AppFailure? failure;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('الحساب', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (failure != null) Text(FailureCopy.message(failure!)),
      AppButton(
        label: 'تسجيل الخروج',
        variant: AppButtonVariant.secondary,
        busy: busy,
        onPressed: onSignOut,
      ),
    ],
  );
}
